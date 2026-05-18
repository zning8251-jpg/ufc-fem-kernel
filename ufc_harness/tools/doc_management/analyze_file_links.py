#!/usr/bin/env python3
"""分析文件链接问题"""
import sys
sys.path.append('.')
from cross_ref_validator import CrossRefValidator

validator = CrossRefValidator(r'd:\TEST7\UFC\PLAN')
result = validator.validate_all()

# 统计文件链接问题 (非锚点)
file_issues = [i for i in result['issues'] if i['type']=='broken_link' and not i['link'].startswith('#')]

# 按文件分组
from collections import Counter
file_counts = Counter()
for issue in file_issues:
    file_counts[issue['file']] += 1

print('=== 文件链接问题分布 (前15) ===')
for f, c in file_counts.most_common(15):
    print(f'{c}: {f}')

print()
print('=== 文件链接目标示例 (前20) ===')
for issue in file_issues[:20]:
    print(f'{issue["link"]} <- {issue["file"]}')