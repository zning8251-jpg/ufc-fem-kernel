#!/usr/bin/env python3
"""分析断开链接问题类型"""
import sys
sys.path.append('.')
from cross_ref_validator import CrossRefValidator

validator = CrossRefValidator(r'd:\TEST7\UFC\PLAN')
result = validator.validate_all()

anchors = 0
broken_files = 0
broken_refs = 0

for issue in result['issues']:
    if issue['type'] == 'broken_link':
        if issue['link'].startswith('#'):
            anchors += 1
        else:
            broken_files += 1
    elif issue['type'] == 'broken_ref':
        broken_refs += 1

print('=== 问题分类 ===')
print('锚点链接(#xxx):', anchors)
print('文件链接失效:', broken_files)
print('@引用失效:', broken_refs)
print('总计:', result['total_issues'])
