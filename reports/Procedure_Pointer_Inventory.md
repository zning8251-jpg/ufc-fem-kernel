# 过程指针（Procedure Pointer）全景清单

**文档性质**：与八域合订本 + `Procedure_Algorithm_L3L4L5_synthesis.md` 并列的 **可替换算法入口全景表**；列出 UFC 六层架构中所有通过 `ABSTRACT INTERFACE` + `PROCEDURE(...), POINTER` 机制实现算法可替换的入口点。**不覆盖** 枚举驱动（LoadBC/Output/WriteBack/Analysis/Amp/Solver 的枚举分派）—— 后者在 `*_Procedure_Algorithm.md` §3 注明。

**报告 ID**：`REP-PTR-INVENTORY`。
**版本**：v1.0（2026-05-05）。

---

## 1. 全景表

| 域柱 | 指针名 | 抽象接口 | 声明位置 | 绑定实现 | 消费过程 | Pipeline 阶段 | 绑定策略 | 备注 |
|------|--------|---------|----------|---------|---------|-------------|----------|------|
| **P1 Material** | `constitutive` | `PH_Mat_Constitutive_Ifc` | `PH_Mat_Def.f90` (或独立 `PH_Mat_Constitutive_Ifc.f90`) | 族级配方：`PH_Mat_Elas_Execute`, `PH_Mat_Plast_Execute`, `PH_Mat_Hyper_Execute`, `PH_Mat_Damage_Execute`, `PH_Mat_Viscoelas_Execute` 等 | `PH_Mat_Execute_Flow` → S3_StressUpdate | S3 (应力更新) | L4 域级 Algo 挂载 | 11 族各有独立执行入口；材料域最完备的 PTR 用例 |
| **P1 Material** | `tangent` | `PH_Mat_Tangent_Ifc` | `PH_Mat_Def.f90` | 族级配方：`PH_Mat_Elas_Tangent`, `PH_Mat_Plast_Tangent` 等 | `PH_Mat_Execute_Flow` → S4_Tangent | S4 (切线模量) | L4 域级 Algo 挂载 | 与 `constitutive` PTR 成对出现 |
| **P2 Element** | `integrator` | `PH_Elem_Integrator_Ifc` | `PH_Elem_Def.f90` | 族级配方：`PH_Elem_Solid3D_Integrate`, `PH_Elem_Shell_Integrate`, `PH_Elem_Beam_Integrate` 等 | `RT_Elem_Dispatcher` → `PH_Elem_*_Core`(Ke/Re) | 热路径 (Ke/Re 计算) | L4 族级 Algo 挂载 | 22 族各有 integrator；Element 最大域柱 |
| **P3 Contact** | `search_strategy` | `ContactSearchStrategy_Ifc` | `PH_Cont_Def.f90` (或 `PH_Cont_Search.f90`) | BVH / Hash / CCD 算法实现 | `PH_Cont_AlgorithmFramework` → Search 阶段 | Search (接触对搜索) | L4 域级 Algo 挂载（Procedure-as-Parameter） | Procedure-as-Parameter 模式 —— `search_strategy` 在运行时选择算法 |
| *P4 LoadBC* | (无) | — | — | — | — | — | 枚举驱动 | LoadBC 载荷/BC 类型有限，枚举分派代替 PTR |
| *P5 Output* | (无) | — | — | — | — | — | 枚举驱动 | Output 变量/触发策略由枚举控制 |
| *P6 WriteBack* | (无) | — | — | — | — | — | 枚举驱动 | WB_DOMAIN_* 11 域常量硬编码分派 |
| *H1 Analysis* | (无) | — | — | — | — | — | 枚举驱动 | Solver NR 策略/Factorization 方法枚举控制 |
| *H2 Section* | (无) | — | — | — | — | — | 无 PTR | Section 正交维只读消费，无需算法可替换性 |

---

## 2. 抽象接口签名速查

### 2.1 `PH_Mat_Constitutive_Ifc`

```fortran
ABSTRACT INTERFACE
  SUBROUTINE PH_Mat_Constitutive_Ifc(desc, state, algo, ctx, args)
    USE IF_Prec, ONLY: wp
    IMPORT :: PH_Mat_Desc, PH_Mat_State, PH_Mat_Algo, PH_Mat_Ctx, PH_Mat_Update_Arg
    TYPE(PH_Mat_Desc),    INTENT(IN)    :: desc
    TYPE(PH_Mat_State),   INTENT(INOUT) :: state
    TYPE(PH_Mat_Algo),    INTENT(IN)    :: algo
    TYPE(PH_Mat_Ctx),     INTENT(IN)    :: ctx
    TYPE(PH_Mat_Update_Arg), INTENT(INOUT) :: args  ! [IN]: dstrain, temperature; [OUT]: stress, C_tan
  END SUBROUTINE
END INTERFACE
```

### 2.2 `PH_Elem_Integrator_Ifc`

```fortran
ABSTRACT INTERFACE
  SUBROUTINE PH_Elem_Integrator_Ifc(desc, state, algo, ctx, args)
    USE IF_Prec, ONLY: wp
    IMPORT :: PH_Elem_Desc, PH_Elem_State, PH_Elem_Algo, PH_Elem_Ctx, PH_Elem_Core_Arg
    TYPE(PH_Elem_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Elem_State),  INTENT(INOUT) :: state
    TYPE(PH_Elem_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Elem_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Core_Arg), INTENT(INOUT) :: args  ! [IN]: u/du; [OUT]: Ke, Re
  END SUBROUTINE
END INTERFACE
```

### 2.3 `ContactSearchStrategy_Ifc`

```fortran
ABSTRACT INTERFACE
  SUBROUTINE ContactSearchStrategy_Ifc(desc, state, algo, ctx, args)
    IMPORT :: PH_Cont_Desc, PH_Cont_State, PH_Cont_Algo, PH_Cont_Ctx, PH_Cont_Search_Arg
    TYPE(PH_Cont_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Cont_State),  INTENT(INOUT) :: state
    TYPE(PH_Cont_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Cont_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Cont_Search_Arg), INTENT(INOUT) :: args  ! [IN]: surface geometry; [OUT]: contact pair candidates
  END SUBROUTINE
END INTERFACE
```

---

## 3. 如何新增一个 Procedure Pointer

1. **接口声明**：在域 `*_Def.f90` 中定义 `ABSTRACT INTERFACE`
2. **Algo 型绑定**：在域 `*_Algo` TYPE 中增加 `PROCEDURE(XXX_Ifc), POINTER :: ptr => NULL()`
3. **实现绑定**：在族级 `*_<Fam>_Core.f90` 中实现具体过程，在族注册阶段将 `algo%ptr => FamilyExecute`
4. **消费调用**：在 Pipeline 入口过程（如 `PH_Mat_Execute_Flow`）中 `CALL algo%ptr(desc, state, algo, ctx, args)`

---

## 4. 枚举驱动 vs PTR 策略决策树

| 条件 | 推荐 | 理由 |
|------|------|------|
| 可选算法 ≤ 5 种且稳定 | 枚举驱动 | 编译器优化、无运行时间接调用开销 |
| 可选算法 > 5 种或需频繁扩展 | Procedure Pointer | 注册模式 · 插件化（UEL/UMAT） |
| 用户自定义扩展（UEL/UMAT） | Procedure Pointer | 运行期动态加载 · 用户提供实现 |
| 域内算法选择由输入决定 | 枚举驱动 | 解析时确定，步内不变 |
| 算法选择由运行状态决定 | Procedure Pointer | 可自适应切换 |

---

## 5. 交叉引用

- `Procedure_Algorithm_L3L4L5_synthesis.md` §A（Procedure Pointer 三层模式）+ §E（八域引用关系）
- `Material_Procedure_Algorithm.md` §3（`constitutive` PTR 开发步骤）
- `Element_Procedure_Algorithm.md` §3（`integrator` PTR 抽象接口+绑定）
- `Contact_Procedure_Algorithm.md` §3（`search_strategy` Procedure-as-Parameter）
- `FourKind_MasterAux_Nesting_Design_Spec.md` R-12（Algo TYPE 双重语义）、R-13（Procedure Pointer 显式声明）

