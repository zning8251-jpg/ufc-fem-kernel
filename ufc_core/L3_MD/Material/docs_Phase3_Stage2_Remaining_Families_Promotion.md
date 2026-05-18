# Phase 3 Stage 2: Therm, Comp, Acou, Geo, User 材料族推广验证报告

## 1. 推广目标
紧接 Phase 3 Stage 1 (Creep, Damage, Visco) 的成功推广，我们将相同的流水线标准应用到剩余的 5 个中低优先级材料族：`Thermal` (热学), `Composite` (复合材料), `Acoustic` (声学), `Geo` (岩土/地质), 以及 `User` (用户自定义)。
主要目标是将这些族的架构向三级嵌套、四类型分离 (Desc/State/Algo/Ctx)、密度参数、以及温度场依赖完全对齐，并实现统一的 SIO 接口和注册机制。

## 2. 推广执行内容

### 2.1 统一的描述符层 (L3_MD Def)
针对以下 5 个文件进行了彻底重构：
- `MD_Mat_Therm_Def.f90` (Thermal)
- `MD_Mat_Comp_Def.f90` (Composite)
- `MD_Mat_Acou_Def.f90` (Acoustic)
- `MD_Mat_Geo_Def.f90` (Geotechnical)
- `MD_Mat_User_Def.f90` (User-defined)

**核心特性对齐：**
- **三层分类**：全部接入 `family_type`, `sub_type`, `property_flags` 分类树。
- **状态分离**：分离出 `_Desc`, `_State`, `_Algo`, `_Ctx` 4种数据类型。
- **温度/场依赖**：统一采用 `dependencies` 和 `constants(:,:)` 二维可分配数组来支持多温度和多场插值。
- **物理扩展**：统一加上了 `density` 密度参数占位。

### 2.2 核心解析与业务层 (L3_MD Core)
涉及文件：
- `MD_Mat_Therm_Core.f90`
- `MD_Mat_Comp_Core.f90`
- `MD_Mat_Acou_Core.f90`
- `MD_Mat_Geo_Core.f90`
- `MD_Mat_User_Core.f90`

**重构细节：**
- 提供一致的 `Create_From_Props` 方法。
- 重写 `Parse_ABAQUS_Keyword` 方法：实现了各自材料域关键字到系统 `sub_type` 枚举的路由。如 `"LAMINATE"` -> `MD_MAT_COMP_SUB_CLT`，`"MOHR COULOMB"` -> `MD_MAT_GEO_SUB_MC` 等。
- 提供 `Register` 接口：向下对接统一注册表 (`MD_Mat_Registry`)，严格使用 `mat_id` 为 `INTENT(IN)` 的规范。

### 2.3 降维路由分发层 (L3_MD Brg)
涉及文件：
- `MD_Mat_Therm_Brg.f90`
- `MD_Mat_Comp_Brg.f90`
- `MD_Mat_Acou_Brg.f90`
- `MD_Mat_Geo_Brg.f90`
- `MD_Mat_User_Brg.f90`

**实施策略：**
- 使用 `MD_Mat_Family_Def.f90` 的规范枚举值实现路由分发 (`Route_L4`)，弃用了老旧架构中的数字硬编码。
- 使用标准的错误传递模式 (`ErrorStatusType`) 进行错误跟踪。

## 3. 验证与总结
至此，**Abaqus 全部 11 个主要材料族**（Elastic, Plastic, Hyperelastic 加上 Phase 3 的 8 个族）已经在 L3 层级全面完成了：
1. **降维重构**（消除了独立的离散材料类，归拢于 11 个统管的大族）。
2. **SIO 四类型化**。
3. **支持温度/场动态拓展**。
4. **对接统一 Registry 注册表**。

Phase 3 的前两个阶段已圆满结束，架构的规范性与统一性达到了 UFC 预期的究极形态！可平稳进入接下来的质量审查及进一步性能调优阶段（如优化查找性能，补充详细注释等）。
