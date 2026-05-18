# Symbol域合同卡

**Layer**: L1_IF (基础设施层)  
**Domain**: Symbol (符号常量)  
**Version**: v1.0  
**Created**: 2026-04-17  
**Status**: ✅ 已补全

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 一、职责边界

### 核心职责
- **定位**: UFC六层架构全栈符号常量的权威定义中心
- **职责**: 统一应力/应变/刚度/BC/DOF/Contact/Load等符号常量定义
- **边界**: 纯编译时常量(PARAMETER),零运行时开销
- **不负责**: 符号计算逻辑(由L2_NM负责)

### 设计原则
1. **单一数据源**: 消除跨层符号冲突(如MD_BC vs RT_BC)
2. **编译时解析**: 所有常量为PARAMETER,零运行时开销
3. **层前缀隔离**: MD_/RT_/PH_/NM_/IF_/UFC_前缀防止命名碰撞
4. **向后兼容**: 提供遗留别名,平滑迁移

---

## 二、四类TYPE映射

| Type种类 | 文件 | TYPE名称 | 核心职责 |
|----------|------|----------|----------|
| **Desc** | IF_Sym_Types.f90 | IF_Sym_Table_Desc | 符号表配置(只读) |
| **Desc** | IF_Sym_Types.f90 | IF_Sym_UnitSystem_Desc | 单位系统定义(只读) |
| **Desc** | IF_Sym_Types.f90 | IF_Sym_Dimension_Desc | 量纲定义(只读) |
| **State** | IF_Sym_Types.f90 | IF_Sym_Query_State | 符号查询状态(读写) |

---

## 三、文件清单

### 核心符号族
| 文件 | 职责 | 状态 |
|------|------|------|
| IF_Sym_Core.f90 | BC/DOF/Load/Contact符号常量 | ✅ 已有 |
| IF_Sym_Stress.f90 | 应力符号族(分量/不变量/应力率) | ✅ 新增 |
| IF_Sym_Strain.f90 | 应变符号族(分量/不变量/应变度量) | ✅ 新增 |
| IF_Sym_Stiffness.f90 | 刚度符号族(本构矩阵/切线刚度) | ✅ 新增 |

### API与TYPE
| 文件 | 职责 | 状态 |
|------|------|------|
| IF_Sym_API.f90 | 统一API接口(查询/转换/验证) | ✅ 新增 |
| IF_Sym_Types.f90 | 四类TYPE定义(Desc/State) | ✅ 新增 |

**总计**: 6个文件 (4已有 + 6新增 = 6个)

---

## 四、四链映射

| 链 | 映射说明 |
|---|----------|
| **理论链** | 应力不变量理论→Voigt记号→编译时常量 |
| **逻辑链** | Symbol↔L3_MD(本构)/L4_PH(单元)/L5_RT(求解器)符号引用闭环 |
| **计算链** | 无(纯编译时常量,零运行时开销) |
| **数据链** | 符号常量全局共享→编译时解析→无运行时数据生命周期 |

---

## 五、对外API接口

### IF_Sym_API.f90 - 8个API接口
| 接口名称 | 功能 | 参数 |
|----------|------|------|
| IF_Sym_API_Init | 初始化Symbol域 | status |
| IF_Sym_API_GetStressComponentName | 获取应力分量名称 | idx, name, status |
| IF_Sym_API_GetStrainComponentName | 获取应变分量名称 | idx, name, status |
| IF_Sym_API_GetMaterialParamName | 获取材料参数名称 | idx, name, status |
| IF_Sym_API_ConvertStressUnit | 应力单位转换 | value, from_unit, to_unit, result, status |
| IF_Sym_API_ConvertStrainUnit | 应变单位转换 | value, from_unit, to_unit, result, status |
| IF_Sym_API_ValidateStressIndex | 验证应力索引 | idx, ndim, is_valid, status |
| IF_Sym_API_ValidateStrainIndex | 验证应变索引 | idx, ndim, is_valid, status |

---

## 六、依赖关系

### 向上依赖(被谁使用)
- L3_MD: 本构矩阵类型/应力应变索引
- L4_PH: 单元刚度矩阵索引/应力率类型
- L5_RT: BC约束类型/DOF索引/接触状态

### 向下依赖(依赖谁)
- L1_IF/IF_Prec_Core: 精度定义(wp/i4)
- L1_IF/IF_Err_API: 错误状态管理

---

## 七、命名规范验证

### 模块前缀
✅ `IF_Sym_` - 符合L1_IF层命名规范

### 常量命名
✅ `STRESS_XX`, `STRAIN_XX`, `CONSTITUTIVE_ELASTIC` - 全大写+下划线
✅ `MD_BC_FIELD_DISP`, `RT_BC_CONSTRAIN_FIXED` - 层前缀+域+功能

### 过程命名
✅ `IF_Sym_API_Init`, `IF_Sym_API_ConvertStressUnit` - 模块前缀+功能描述

---

## 八、测试策略

### 编译时验证
- 常量值正确性(手动审查)
- 层前缀隔离(无命名冲突)
- 映射数组边界检查

### 运行时验证
- 单位转换准确性(测试用例)
- 符号查询正确性(边界值测试)
- 索引验证逻辑(越界检测)

---

## 九、符号常量分类统计

### 应力符号族
- 应力分量索引: 6个(σ_xx~τ_xz)
- 应力不变量: 4个(I1/J2/J3/Lode角)
- 主应力: 3个(S1/S2/S3)
- 应力率类型: 6个(Cauchy~Truesdell)
- 屈服准则: 6个(Von Mises~Barlat)
- **小计**: 25个常量

### 应变符号族
- 应变分量索引: 6个(ε_xx~γ_xz)
- 应变不变量: 3个(体积应变/等效应变/最大剪应变)
- 主应变: 3个(E1/E2/E3)
- 应变度量: 5个(工程~Biot)
- 应变率类型: 3个
- **小计**: 20个常量

### 刚度符号族
- 本构矩阵类型: 6个
- 切线刚度类型: 5个
- 存储格式: 4个
- 材料参数: 6个(E/G/K/ν/λ/μ)
- 装配模式: 4个
- **小计**: 25个常量

### 基础符号(Core)
- BC常量: 11个(MD_/RT_各5个+映射)
- DOF索引: 7个(UX~RZ+TEMP)
- Load类型: 4个
- Amplitude插值: 4个
- Contact常量: 8个
- Ctx预分配: 5个
- **小计**: 39个常量

**总计**: 约109个编译时常量

---

## 十、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 2026-04-17 | 初始版本,补全6个文件 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_Sym.f90` | `IF_Sym` | — | `IF_Sym_Init` (SUB,PUB,Init) |
| `IF_Sym_Brg.f90` | `IF_Sym_Brg` | — | `IF_Sym_API_Init` (SUB,PUB,Init); `IF_Sym_API_GetStressComponentName` (SUB,PUB,Query); `IF_Sym_API_GetStrainComponentName` (SUB,PUB,Query); `IF_Sym_API_GetMaterialParamName` (SUB,PUB,Query); `IF_Sym_API_ConvertStressUnit` (SUB,PUB,Bridge); `IF_Sym_API_ConvertStrainUnit` (SUB,PUB,Bridge); `IF_Sym_API_ValidateStressIndex` (SUB,PUB,Validate); `IF_Sym_API_ValidateStrainIndex` (SUB,PUB,Validate) |
| `IF_Sym_Def.f90` | `IF_Sym_Def` | `IF_Sym_Table_Desc`, `IF_Sym_UnitSystem_Desc`, `IF_Sym_Dimension_Desc`, `IF_Sym_Query_State` | `IF_Sym_Types_Init` (SUB,PUB,Init) |
| `IF_Sym_Stiffness.f90` | `IF_Sym_Stiffness` | — | `IF_Sym_Stiffness_Init` (SUB,PUB,Init) |
| `IF_Sym_Strain.f90` | `IF_Sym_Strain` | — | `IF_Sym_Strain_Init` (SUB,PUB,Init) |
| `IF_Sym_Stress.f90` | `IF_Sym_Stress` | — | `IF_Sym_Stress_Init` (SUB,PUB,Init) |
