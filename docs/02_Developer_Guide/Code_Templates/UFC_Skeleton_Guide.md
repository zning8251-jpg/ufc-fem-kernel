# UFC 标准 .f90 骨架模板使用指南

## 概述

三种标准骨架模板对应十件套中的三种核心模块角色：

| 骨架 | 文件 | 角色 | 十件套映射 |
|------|------|------|-----------|
| `_Def` | `UFC_Skeleton_Def.f90` | 类型定义 / 合同 | Definition/Schema, Desc/State/Algo/Ctx |
| `_Core` | `UFC_Skeleton_Core.f90` | 域逻辑实现 | Kernel, 功能集 (Init/Query/Compute...) |
| `_Brg` | `UFC_Skeleton_Brg.f90` | 桥接 / API 门面 | Bridge, Populate, WriteBack |

## 文件组织

```
{Layer}_{Domain}/
├── {Layer}_{Domain}_Def.f90      ← 四型 TYPE + 常量 + Arg
├── {Layer}_{Domain}_Core.f90     ← Init/Finalize/Query/Compute
├── Bridge/
│   └── {Layer}_{Domain}_Brg.f90  ← re-export + cross-layer
└── CONTRACT.md                   ← 域级合同卡
```

## 功能集 → 文件映射

| 功能集 | 归属文件 |
|--------|---------|
| Init, Finalize | `_Core.f90` |
| Query (只读访问) | `_Core.f90` |
| Mutate (可变操作) | `_Core.f90` |
| Compute (热路径) | `_Core.f90` (或独立 `_Ops.f90`) |
| Valid (校验) | `_Core.f90` |
| Brg (跨层桥接) | `_Brg.f90` |
| Parse (解析) | `_Core.f90` 或独立 `_Parse.f90` |
| Algo (算法选择) | 体现为 `_Algo` TYPE 在 `_Def.f90` 中 |

## 四型裁剪决策

```
需要 Desc?
  └─ YES → 总是保留（模型描述符是必须的）

需要 State?
  ├─ 有跨步/增量演化的数据 → 保留
  └─ 纯只读 → 省略 (合并到 Desc)

需要 Algo?
  ├─ 有算法选择/控制参数 → 保留
  └─ 固定算法，无可配置项 → 省略

需要 Ctx?
  ├─ 有跨层数据传递 (Bridge) → 保留
  ├─ 有热路径临时工作数组 → 保留
  └─ 无临时数据需求 → 省略
```

## 占位符替换清单

| 占位符 | 示例 (L3 Material) | 说明 |
|--------|-------------------|------|
| `{Layer}` | `MD` | 层前缀 (IF/NM/MD/PH/RT/AP) |
| `{LayerFullName}` | `Model Data Layer` | 层全称 |
| `{Domain}` | `Mat` | 域名 (压缩词根) |
| `{DomainDescription}` | `Material definitions` | 域描述 |
| `{Feature}` | `Elastic` | 功能子集 (可选) |
| `{DOMAIN}` | `MAT` | 域名大写 (用于常量) |
| `{Verb}` | `GetSummary` | 操作动词 |
| `{SourceLayer}` | `MD` | 桥接源层 |
| `{TargetLayer}` | `PH` | 桥接目标层 |
| `{OtherLayer}` | `PH` | 相邻层 |

## USE 顺序规范

```fortran
! 1. 精度 (必须)
USE IF_Prec,    ONLY: wp, i4

! 2. 错误处理 (必须)
USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, ...

! 3. 本域定义 (_Core 和 _Brg 中)
USE {Layer}_{Domain}_Def, ONLY: ...

! 4. 同层其他域 (按需)
USE {Layer}_{OtherDomain}_Def, ONLY: ...

! 5. 跨层模块 (仅 _Brg 中，DEP-001 豁免)
USE {OtherLayer}_{Domain}_Def, ONLY: ...
```

## 错误处理模式

```fortran
SUBROUTINE Example_Proc(input, output, status)
  ! ... declarations ...
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  TYPE(ErrorStatusType) :: local_status

  CALL init_error_status(status)

  ! 调用子步骤
  CALL sub_step(input, local_status)
  IF (local_status%status_code /= IF_STATUS_OK) THEN
    status = local_status
    status%source = "Example_Proc"
    RETURN
  END IF

  status%status_code = IF_STATUS_OK
END SUBROUTINE Example_Proc
```
