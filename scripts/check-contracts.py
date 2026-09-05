#!/usr/bin/env python3
"""Repository-only contracts: no Fx checkout, runtimes, builds, or fixtures."""
import json
from pathlib import Path
import re

def require(condition, message):
    if not condition:
        raise ValueError(message)


def check(root):
    spec = (root / 'MAINTAIN.md').read_text()
    for section in ('Purpose', 'Upstream', 'Branch model', 'Features', 'Gate', 'Consumer', 'Notify', 'Style guide'):
        require(f'\n## {section}\n' in spec, f'MAINTAIN.md is missing section: {section}')
    for text in ('scripts/replay-carries.sh', '--carried-only'):
        require(text in spec, f'MAINTAIN.md does not name {text}')
    features = spec.split('\n## Features\n', 1)[1].split('\n## ', 1)[0]
    carries = re.findall('^\\| `carry/([^`]+)` \\|', features, re.M)
    require(len(carries) == len(set(carries)), 'Features maps a carry more than once')
    graph = {}
    for line in (root / 'scripts/carry-graph.tsv').read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        (name, deps) = line.split('\t')
        require(re.fullmatch('[a-z0-9][a-z0-9-]*', name), f'invalid carry: {name}')
        require(name not in graph, f'duplicate carry: {name}')
        require(deps, f'missing dependencies: {name}')
        if deps == 'upstream':
            graph[name] = []
        elif deps.startswith('='):
            graph[name] = [deps[1:]]
        else:
            graph[name] = ['hosted-full-ci'] + ([] if deps == '-' else deps.split(','))
    require(set(graph) == set(carries), 'carry graph and Features inventory differ')
    require(graph.get('hosted-full-ci') == [], 'hosted-full-ci must depend on upstream')
    for (name, deps) in graph.items():
        require(name == 'hosted-full-ci' or deps, f'only hosted-full-ci may depend on upstream: {name}')
        require(set(deps) <= set(graph), f'undeclared dependency of {name}')
    pending = dict(graph)
    while pending:
        ready = [name for (name, deps) in pending.items() if not set(deps) & pending.keys()]
        require(ready, 'carry graph has a cycle')
        for name in ready:
            del pending[name]
    require((root / 'CLAUDE.md').readlink() == Path('AGENTS.md'), 'CLAUDE.md must link to AGENTS.md')
    tokens = json.loads((root / 'style/tokens.json').read_text())
    require(tokens['roles']['divider']['dark']['fg']['hex'] and tokens['retint_map'], 'invalid style tokens')
    for script in list((root / 'scripts').glob('*.sh')) + list((root / 'tests').glob('*.sh')):
        require(script.stat().st_mode & 0o111, f'{script} must be executable')
if __name__ == '__main__':
    try:
        check(Path(__file__).resolve().parent.parent)
    except (KeyError, OSError, ValueError) as error:
        raise SystemExit(f'static contracts: {error}')
