import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('balance_compare', Path(__file__).parents[2] / 'tool/balance_compare.py')
bal = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bal)


def session():
    return {'schema_version': bal.SCHEMA, 'events': [], 'metadata': {}, 'days': [
        {'id': '1', 'test_kind': 'automated_physics', 'configuration_sha256': 'config',
         'coins_earned': '5', 'coins_collected': '5', 'coins_pending': '0', 'quota_completed': '0',
         'end_reason': 'day_complete', 'board': {'partial': False, 'initial': '0', 'live': '5', 'peak': '10',
           'validation': [], 'counts': {'emitted': '10', 'emitted.main': '10', 'captured': '5',
           'captured.main': '5', 'captured_ordinary': '5', 'attempts.main': '10', 'successful.main': '10'}}}]}


class ComparisonTests(unittest.TestCase):
    def test_conservation_rejects_broken_data(self):
        data = session(); self.assertEqual(bal.validate(data), [])
        data['days'][0]['board']['live'] = '6'
        self.assertIn('1: ball conservation', bal.validate(data))

    def test_exact_huge_money_and_zero_denominator(self):
        a, b = session(), session()
        a['days'][0]['coins_earned'] = str(10**150)
        b['days'][0]['coins_earned'] = str(10**150 + 7)
        result = bal.compare([a], [b])
        self.assertEqual(result['metrics']['coins_earned']['absolute'], '7')
        self.assertIsNone(result['metrics']['quotas_completed']['percent'])

    def test_does_not_mix_humans_and_bots(self):
        a, b = session(), session(); b['days'][0]['test_kind'] = 'human_normal'
        with self.assertRaises(ValueError): bal.compare([a], [b])

    def test_partial_rate_is_unavailable(self):
        data = session(); data['days'][0]['board']['partial'] = True
        self.assertIsNone(bal.aggregate([data])['capture_rate_covered'])

    def test_changes_require_explicit_experiment(self):
        a, b = session(), session(); b['metadata']['seed'] = 42
        with self.assertRaises(ValueError): bal.compare([a], [b])
        self.assertTrue(bal.compare([a], [b], True)['warnings'])

    def test_duplicate_star_payment_and_events_are_detected(self):
        data = session()
        before = {'quota': 1, 'nextId': 2, 'pending': [{'id': 1, 'value': 1}]}
        after = {'quota': 1, 'nextId': 2, 'pending': []}
        event = {'seq': 1, 'type': 'stars_transaction', 'run_id': '1', 'paid': '1', 'before': before, 'after': after}
        data['events'] = [event, dict(event, seq=2)]
        self.assertIn('stars transaction chain', bal.validate(data))
        data['events'] = [event, event]
        self.assertIn('duplicate event sequence', bal.validate(data))

    def test_missing_fields_not_silently_zero(self):
        data = session(); del data['days'][0]['coins_earned']
        with self.assertRaises(KeyError): bal.validate(data)


if __name__ == '__main__': unittest.main()
