import json
data = json.load(open(r'd:\TEST7\UFC\tools\two_seg_inventory.json', encoding='utf-8'))
print('Total two-segment files:', len(data))
from collections import Counter
layers = Counter()
for d in data:
    layer = d['dir'].split('/')[0] if '/' in d['dir'] else d['dir']
    layers[layer] += 1
for k, v in sorted(layers.items()):
    print('  %s: %d' % (k, v))
print()
for d in data[:30]:
    print('  %-40s MOD=%-40s DIR=%s' % (d['stem'], d['mod'], d['dir']))
