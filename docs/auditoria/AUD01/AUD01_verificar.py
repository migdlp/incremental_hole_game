#!/usr/bin/env python3
"""AUD01: extracción estática de solo lectura; no ejecuta ni modifica el juego."""
import collections
import csv
import hashlib
import json
import math
import pathlib
import re
import sys

out = pathlib.Path(__file__).resolve().parent
root = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else out.parents[2]
checks = 0

def check(condition, label):
    global checks
    if not condition:
        raise AssertionError(label)
    checks += 1
    print('OK:', label)

rows = list(csv.DictReader((root / 'docs/balance.csv').open()))
text = (root / 'lib/features/upgrades/domain/catalog.dart').read_text()
labels = re.findall(r"'([^']+)': \['([^']+)', '([^']+)'\]", text)
families = collections.defaultdict(list)
for r in rows:
    if r['kind'] == 'upgrade':
        families[r['id']].append(r)
check(set(families) == {r[0] for r in labels}, 'CSV y labels contienen las mismas 22 familias')
check(len(families) == 22, '22 familias activas')
nodes = {}
edges = set()
for family, levels in families.items():
    for i, row in enumerate(levels):
        check(int(row['level']) == i + 1, 'nivel consecutivo: ' + family + ':' + row['level'])
        req = set(filter(None, row['requires'].split('&')))
        old = set(filter(None, levels[i - 1]['requires'].split('&'))) if i else set()
        parents = req - old
        if i:
            parents.add(f'{family}:{i}')
        node = f'{family}:{i + 1}'
        check(node not in nodes, 'ID único: ' + node)
        nodes[node] = (row, parents, req)
        edges.update((p, node) for p in parents)
check(len(nodes) == 55 and len(edges) == 57, '55 nodos y 57 aristas dibujadas distintas')
check(all(a in nodes and b in nodes for a, b in edges), 'ninguna referencia de arista rota')
check(all(r in nodes for _, _, req in nodes.values() for r in req), 'ningún requisito inexistente')
adj = {n: set() for n in nodes}
for a, b in edges:
    adj[a].add(b)
    adj[b].add(a)
over = {n: sorted(v) for n, v in adj.items() if len(v) > 4}
check(over == {'hand:1': ['bat:1', 'combo:1', 'generator:1', 'hand:2', 'reward:1', 'walls:1']}, 'infracción de máximo4 documentada exactamente: hand:1 tiene6')
check(not any(not v for v in adj.values()), 'sin nodos aislados')
visited = set()
stack = ['hand:1']
while stack:
    n = stack.pop()
    if n not in visited:
        visited.add(n)
        stack.extend(adj[n] - visited)
check(visited == set(nodes), 'una componente conectada de55 nodos')
reached = set()
while True:
    new = {n for n, (_, p, req) in nodes.items() if p | req <= reached}
    if new <= reached:
        break
    reached |= new
check(reached == set(nodes), 'requisitos alcanzables sin ciclos con recursos ilimitados')
records = list(csv.DictReader((out / 'AUD01_nodos.csv').open()))
active = {r['id']: r for r in records if r['estado'] == 'IMPLEMENTADO'}
check(set(active) == set(nodes), 'CSV de entrega incluye exactamente todos los nodos activos')
check(len(records) == 70 and len(records) == len({r['id'] for r in records}), '70 IDs únicos incluyendo15 niveles obsoletos')
for n, (row, _, _) in nodes.items():
    r = active[n]
    check(int(r['coste_monedas']) == int(row['cost']) and float(r['valor_efecto']) == float(row['effect_value']) and set(filter(None, r['vecinos_distintos'].split(';'))) == adj[n] and int(r['numero_vecinos']) == len(adj[n]), 'precio/efecto/vecinos fieles al código: ' + n)
layout = (root / 'lib/features/upgrades/domain/skill_tree.dart').read_text()
route_text = layout.split('final routes = {')[1].split('\n    };')[0]
positions = {}
for family, expr in re.findall(r"'([^']+)': (.*),", route_text):
    points = [(48, 48)] if family == 'prestige' else []
    for raw in re.findall(r'line\(([^)]+)\)', expr):
        x, y, dx, dy, count = map(int, raw.split(','))
        points.extend((48 + (x + dx * i + 2) * 64, 48 + (y + dy * i + 2) * 64) for i in range(count))
    for i, point in enumerate(points, 1):
        positions[f'{family}:{i}'] = point
check(set(positions) == set(nodes), 'rutas definen una posición para cada nodo actual')
check(all((float(active[n]['x']), float(active[n]['y'])) == point for n, point in positions.items()), 'posicionesCSV coinciden con rutasDart y spacing64')
check(len(set(positions.values())) == len(nodes), 'centros sin posiciones duplicadas')
connections = list(csv.DictReader((out / 'AUD01_conexiones.csv').open()))
check({(r['origen'], r['destino']) for r in connections if r['naturaleza'].startswith('arista')} == edges, 'CSV de aristas coincide con reconstrucción')
check(sum(int(row['cost']) for row, _, _ in nodes.values()) == 19493, 'coste total19493, sin prestigio9493')
check(sum(int(r['cost']) for k in ['hand', 'generator', 'reward', 'duration', 'prestige'] for r in (families[k][:1] if k == 'hand' else families[k])) == 12603, 'camino de requisitos de prestigio12603')
check(34 // 10 == 3 and 34 % 10 == 4 and 3 * 10 + 4 == 34, 'ejemplo aritmético34=3x10+4x1 (no testDart)')
for k in range(1, 8):
    check(sum(100 * 10 ** i for i in range(k)) == 100 * (10 ** k - 1) // 9, 'suma ideal de cuotas hasta ' + str(k))
check(math.isclose((22 * math.sqrt(1.16)) ** 2 / 22 ** 2, 1.16), 'crecimiento16% de área equivale a radioxsqrt(1.16)')
manifest = list(csv.DictReader((out / 'AUD01_fuentes_sha256.csv').open()))
check(bool(manifest), 'manifest de evidencias no vacío')
check(all(hashlib.sha256((root / r['ruta']).read_bytes()).hexdigest() == r['sha256'] for r in manifest), 'hashes de todas las fuentes siguen intactos')
print(f'\n{checks} comprobaciones de extracción/consistencia correctas.')
print('Regla de diseño 0–4: INCUMPLIDA por hand:1; auditoría la detecta, no la corrige.')
print('No ejecutado: Flutter/Dart, juego Android, tasas humanas de captura o benchmark nuevo.')
