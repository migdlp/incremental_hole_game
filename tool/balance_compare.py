#!/usr/bin/env python3
"""Local BAL-TOOLS validator/comparator. Python stdlib, exact integer aggregates."""
import argparse
import csv
import json
from decimal import Decimal, localcontext
from pathlib import Path

SCHEMA = 'bal_metrics/1.0.0'


def integer(value):
    if not isinstance(value, str) or not value.isdecimal():
        raise ValueError(f'expected nonnegative decimal string, got {value!r}')
    return int(value)


def validate(session):
    if session.get('schema_version') != SCHEMA:
        raise ValueError('incompatible metrics schema')
    issues, seen = [], set()
    for day in session['days']:
        if day['id'] in seen:
            issues.append(f"duplicate day {day['id']}")
        seen.add(day['id'])
        b = day['board']; c = b['counts']
        n = lambda key: integer(c.get(key, '0'))
        if not b['partial'] and integer(b['initial']) + n('emitted') + n('debug_injected') != n('captured') + integer(b['live']):
            issues.append(f"{day['id']}: ball conservation")
        if n('captured') != n('captured_ordinary') + n('captured_instant'):
            issues.append(f"{day['id']}: capture split")
        emitted_sources = sum(integer(v) for k, v in c.items() if k.startswith('emitted.'))
        captured_sources = sum(integer(v) for k, v in c.items() if k.startswith('captured.'))
        if emitted_sources != n('emitted') or captured_sources != n('captured'):
            issues.append(f"{day['id']}: source totals")
        for key in c:
            if key.startswith('attempts.'):
                source = key.split('.', 1)[1]
                blocked = sum(integer(v) for k, v in c.items() if k.startswith(f'blocked.{source}.'))
                if integer(c[key]) != n(f'successful.{source}') + blocked:
                    issues.append(f"{day['id']}: attempts {source}")
        earned, collected, pending = (integer(day[k]) for k in ['coins_earned', 'coins_collected', 'coins_pending'])
        if earned != collected + pending:
            issues.append(f"{day['id']}: coins outstanding")
        issues.extend(f"{day['id']}: {x}" for x in b.get('validation', []))
    for event in session.get('events', []):
        if event['type'] == 'normal_purchase':
            if integer(event['balance_before']) - integer(event['cost']) != integer(event['balance_after']):
                issues.append('purchase wallet equation')
    return sorted(set(issues))


def load(path):
    path = Path(path)
    paths = sorted(path.glob('*.json')) if path.is_dir() else [path]
    sessions = []
    for item in paths:
        data = json.loads(item.read_text(encoding='utf-8'))
        problems = validate(data)
        if problems:
            raise ValueError(f'{item}: {problems}')
        sessions.append(data)
    if not sessions:
        raise ValueError('no session exports')
    return sessions


def decimal(value):
    if value is None:
        return None
    if isinstance(value, Decimal):
        return format(value, 'f')
    return str(value)


def aggregate(sessions):
    days = [day for s in sessions for day in s['days']]
    total = lambda key: sum(integer(d['board']['counts'].get(key, '0')) for d in days)
    observed = [d for d in days if not d['board']['partial'] and d['board']['initial'] == '0'
                and d['board']['counts'].get('debug_injected', '0') == '0']
    observed_emitted = sum(integer(d['board']['counts'].get('emitted', '0')) for d in observed)
    observed_captured = sum(integer(d['board']['counts'].get('captured', '0')) for d in observed)
    frames = [d['performance'] for d in days if d.get('performance', {}).get('frames', 0) > 0]
    result = {'sessions': len(sessions), 'days': len(days), 'emitted': total('emitted'),
              'captured': total('captured'), 'ordinary': total('captured_ordinary'), 'instant': total('captured_instant'),
              'coins_earned': sum(integer(d['coins_earned']) for d in days),
              'coins_collected': sum(integer(d['coins_collected']) for d in days),
              'quotas_completed': sum(integer(d['quota_completed']) for d in days),
              'quota_defeats': sum(d['end_reason'] == 'quota_defeat' for d in days),
              'peak_population': max((integer(d['board']['peak']) for d in days), default=None),
              'stars_redeemed': sum(integer(e['paid']) for s in sessions for e in s.get('events', []) if e['type'] == 'stars_transaction'),
              'capture_rate_covered': Decimal(observed_captured) / observed_emitted if observed_emitted else None,
              'capture_rate_days_covered': len(observed),
              'frames': sum(f['frames'] for f in frames) if frames else None,
              'slow_frames': sum(f['slow_frames_gt16667us'] for f in frames) if frames else None}
    per_session = [sum(integer(d['board']['counts'].get('captured', '0')) for d in s['days']) for s in sessions]
    if per_session:
        mean = Decimal(sum(per_session)) / len(per_session)
        result['captured_per_session_mean'] = mean
        result['captured_per_session_std_population'] = (sum((Decimal(x) - mean)**2 for x in per_session) / len(per_session)).sqrt()
    return result


def compare(before, after, allow_config_change=False, grouped=True):
    kinds = lambda ss: {d['test_kind'] for s in ss for d in s['days']}
    if kinds(before) != kinds(after):
        raise ValueError('incompatible test kinds: humans, DEBUG and bots must be compared separately')
    scenarios = lambda ss: sorted(json.dumps(s.get('metadata', {}).get('scenario', {}), sort_keys=True) for s in ss)
    seeds = lambda ss: sorted(str(s.get('metadata', {}).get('seed', 'unknown')) for s in ss)
    warnings = []
    if scenarios(before) != scenarios(after) or seeds(before) != seeds(after):
        if not allow_config_change:
            raise ValueError('scenario/seed mismatch; use --allow-config-change for an explicit experiment')
        warnings.append('Intentional experiment: scenario or seeds changed; not a strict regression comparison.')
    configs = lambda ss: sorted(d['configuration_sha256'] for s in ss for d in s['days'])
    if configs(before) != configs(after):
        warnings.append('Effective configurations or reached horizons differ; inspect per-day snapshots.')
    for label, ss in [('before', before), ('after', after)]:
        for s in ss:
            meta = s.get('metadata', {})
            if meta.get('source_commit', 'unknown') == 'unknown': warnings.append(f'{label}: source commit unknown')
            if s.get('dropped_events', 0) or s.get('dropped_days', 0): warnings.append(f'{label}: truncated history; totals cover retained records only')
            if any(d['board']['partial'] for d in s['days']): warnings.append(f'{label}: partial coverage; inspect baselines')
    a, b = aggregate(before), aggregate(after)
    differences = {}
    for key in a.keys() | b.keys():
        x, y = a.get(key), b.get(key)
        delta = y - x if x is not None and y is not None else None
        percent = Decimal(delta) * 100 / Decimal(x) if delta is not None and x != 0 else None
        differences[key] = {'before': decimal(x), 'after': decimal(y), 'absolute': decimal(delta), 'percent': decimal(percent)}
    per_scenario = {}
    if grouped:
        ids = lambda ss: {s.get('metadata', {}).get('scenario', {}).get('id', 'unlabelled') for s in ss}
        for name in sorted(ids(before) & ids(after)):
            select = lambda ss: [s for s in ss if s.get('metadata', {}).get('scenario', {}).get('id', 'unlabelled') == name]
            per_scenario[name] = compare(select(before), select(after), allow_config_change, grouped=False)
    return {'schema_version': 'bal_comparison/1.0.0', 'warnings': sorted(set(warnings)),
            'by_scenario': per_scenario,
            'interpretation': 'Observed differences; no automatic approval or gameplay changes.',
            'before_commits': sorted({s.get('metadata', {}).get('source_commit', 'unknown') for s in before}),
            'after_commits': sorted({s.get('metadata', {}).get('source_commit', 'unknown') for s in after}),
            'metrics': differences}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before'); parser.add_argument('after', nargs='?')
    parser.add_argument('--allow-config-change', action='store_true')
    parser.add_argument('--out', default='/tmp/feed-the-hole-comparison')
    args = parser.parse_args()
    try:
        with localcontext() as ctx:
            ctx.prec = 80
            before = load(args.before)
            if not args.after:
                print(json.dumps({'valid': True, 'sessions': len(before), 'aggregate': {k: decimal(v) for k, v in aggregate(before).items()}}, indent=2))
                return
            report = compare(before, load(args.after), args.allow_config_change)
        directory = Path(args.out); directory.mkdir(parents=True, exist_ok=True)
        (directory / 'comparison.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        with (directory / 'comparison.csv').open('w', encoding='utf-8', newline='') as handle:
            writer = csv.writer(handle); writer.writerow(['metric', 'before', 'after', 'absolute', 'percent'])
            for key, values in sorted(report['metrics'].items()): writer.writerow([key, *values.values()])
        text = '\n'.join([*report['warnings'], '', '| Métrica | Antes | Después | Diferencia | % |', '|---|---:|---:|---:|---:|',
          *(f"| {key} | {v['before']} | {v['after']} | {v['absolute']} | {v['percent']} |" for key, v in sorted(report['metrics'].items()))])
        (directory / 'comparison.md').write_text(text, encoding='utf-8')
        print(directory / 'comparison.md')
    except (ValueError, KeyError, TypeError) as error:
        parser.exit(2, f'Invalid balance data: {error}\n')

if __name__ == '__main__':
    main()
