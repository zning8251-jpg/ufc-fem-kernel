# -*- coding: utf-8 -*-
DOC_PATH = 'd:/TEST7/docs/05_Project_Planning/PPLAN/03_实施规划/单元域改造/材料域 L3-L4-L5 三层架构设计方案.md'
with open(DOC_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

checks = [
    ('MOVE_ALLOC', 'MOVE_ALLOC 指针交换'),
    ('RT_Mat_CommitState', 'CommitState 函数'),
    ('RT_Mat_RevertState', 'RevertState 函数'),
    ('step_init', '三级冷路径 step_init'),
    ('incr_init', '三级冷路径 incr_init'),
    ('iter_init', '三级冷路径 iter_init'),
    ('I01_MatState_GetStress', '接口 I-01'),
    ('I03_MatParam_GetThermal', '接口 I-03'),
    ('15-20%', '性能提升 15-20%'),
    ('350s', '350s 基准算例'),
    ('5GB', '5GB 内存评估'),
    ('28 种分析类型', '28种分析类型表'),
    ('MD_Mat_StateInit_Type', 'StateInit Type'),
    ('SDV 初值标准表', 'SDV 初值标准表'),
    ('## 11. 跨域接口规范', '第11章'),
    ('## 12. 缓存同步与性能分析', '第12章'),
    ('## 13. 分析类型支持矩阵', '第13章'),
    ('4.2.1', '4.2.1 三级冷路径'),
    ('4.2.2', '4.2.2 Commit/Rollback'),
]

print('关键内容验证:')
ok_count = 0
for marker, desc in checks:
    found = marker in content
    status = 'OK  ' if found else 'MISS'
    if found:
        ok_count += 1
    print('  %s: %s' % (status, desc))

print('\n%d/%d 检查通过' % (ok_count, len(checks)))
print('文件总行数: %d' % content.count('\n'))
print('文件总字符: %d' % len(content))
