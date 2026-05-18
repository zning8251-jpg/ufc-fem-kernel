# Phase 3 Stage 1: Damage & Visco 材料族推广验证报告

## 1. 推广目标
根据 Phase 3 的计划，验证 Creep 族的模板有效性之后，需立即将三级嵌套、密度支持、温度场依赖（`constants(:,:)` 及 `dependencies`）、及统一注册（`MD_Mat_Registry`）的改造标准推广至 `Damage` 和 `Viscoelas`（粘弹性）材料族。

## 2. 推广路径及改造内容

### 2.1 L3_MD Def 描述符层 (四类统一)
**涉及文件：** 
- `MD_Mat_Damage_Def.f90`
- `MD_Mat_Visco_Def.f90`

**核心动作：**
- 全面引入 `MD_Mat_Base_Desc` 继承关系（扩展自 `MD_Mat_Desc` L1层大管家）。
- 实现 `Desc/State/Algo/Ctx` 四类型拆分。
- 取代旧有单薄描述符结构，增加了 `family_type`、`sub_type`、`property_flags` 的三层标准嵌套。
- 引入了 `num_constants` 和 `dependencies` 管理，并将 `constants` 改为二维 Allocatable 数组。
- 扩展了 `density` (密度) 字段，满足 Week 3 需求。

### 2.2 L3_MD Core 核心业务层 (SIO 及 Populator 统一)
**涉及文件：**
- `MD_Mat_Damage_Core.f90`
- `MD_Mat_Visco_Core.f90`

**核心动作：**
- 实现 `Create_From_Props`：统一对 `props` 的接管与 `desc` 对象的初始化，自动判定并分配温度/场相关的 `constants` 大小。
- 实现 `Parse_ABAQUS_Keyword`：完成对 Abaqus 标准关键字树到内部 `sub_type` 枚举的路由。例如将 `"DUCTILE"`, `"SHEAR"` 映射为 `MD_MAT_DMG_SUB_DUCTILE` 等；将 `"PRONY"`, `"KELVIN"` 映射至粘弹族枚举。
- 实现 `Register`：与 Creep 同步修复了向统一注册表传递 `mat_id` 时的 `INTENT(IN)` 向下传递约定。

### 2.3 L3_MD Brg 路由桥接层
**涉及文件：**
- `MD_Mat_Damage_Brg.f90`
- `MD_Mat_Visco_Brg.f90`

**核心动作：**
- 清理掉原始硬编码的数字如 `701_i4`，全面采用 `MD_Mat_Family_Def.f90` 统一定义的枚举宏（如 `MD_MAT_DMG_SUB_DUCTILE` / `MD_MAT_VE_SUB_PRONY_DEV` 等）实现 L4 降维分发。
- `desc` 和 `status` 的输入输出严格符合 SIO 传参和错误追踪标准。

## 3. 验证结果
- **类型冲突清理**：通过全局检索确认 `Damage` 与 `Visco` 的子类库未存在冲突的老旧同名描述符，无需像 `Creep` 族一样去改子模块类型名。
- **标准合规**：新文件架构（Def、Core、Brg）全方面契合 Phase 3 的“三层贯通”、“五参 SIO”、“极简命名” 策略。

## 4. 下一步行动 (Phase 3 阶段 2)
目前的高优先级族（Creep, Damage, Visco）已全面打通。下一步将针对剩余中低优先级材料族（Therm, Comp, Acou, Geo, User）开展阶段 2 的流水线推广作业。
