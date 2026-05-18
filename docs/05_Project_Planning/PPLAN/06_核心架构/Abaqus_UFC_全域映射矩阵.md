# UFC 架构 × Abaqus 子程序全域映射矩阵

## 核心设计决策总览

### 问题 1: L3 层是 Mesh，L4/5 则对应 Element？

**答案**：✅ 正确

```
L3_MD/Mesh (网格域)
  ↓ 
L4_PH/Element (单元计算域)
  ↓
L5_RT/Element_Ctx (单元运行时上下文)
```

**映射逻辑**：
- **L3_MD/Mesh**: 节点坐标、单元连接、网格质量（数据描述）
- **L4_PH/Element**: UEL/VUEL 刚度矩阵组装、内力计算（物理计算）
- **L5_RT/Element_Ctx**: 单元编号、积分点信息、求解器绑定（运行时上下文）

---

### 问题 2: L3 对应 Interaction，L4/5 对应 Contact？

**答案**：✅ 正确

```
L3_MD/Interaction (接触对定义)
  ↓
L4_PH/Contact (接触计算域)
  ↓
L5_RT/Contact_Ctx (接触运行时上下文)
```

**映射逻辑**：
- **L3_MD/Interaction**: 主从面定义、接触参数、摩擦系数（数据描述）
- **L4_PH/Contact**: UINTER/VUINTER 法向压力、切向滑移计算（物理计算）
- **L5_RT/Contact_Ctx**: 接触对 ID、滑移量历史变量（运行时上下文）

---

### 问题 3: L3 对应 Step，L5 对应 Analysis？

**答案**：⚠️ 部分正确，需要修正

```
L3_MD/Step (分析步定义)
  ↓
L4_PH: ❌ (无独立计算域)
  ↓
L5_RT/Analysis_Ctx (分析控制上下文)
```

**映射逻辑**：
- **L3_MD/Step**: 分析步类型、时间增量、求解器参数（数据描述）
- **L4_PH**: 不直接对应计算域，通过 Material/Element/Contact 等间接参与
- **L5_RT/Analysis_Ctx**: 时间步进、收敛控制、UEXTERNALDB 调用（运行时上下文）

**修正说明**：Step 在 L4 没有独立的计算域，而是通过分析步配置驱动其他域的计算

---

### 问题 4: Output 域的处理方式？

**答案**：Output 不在 L4 独立成域，直接由 L4 传递到 L5

```
L3_MD/Output (输出请求定义)
  ↓
L4_PH: ❌ (无独立计算域)
  ↓
L5_RT/Output_Ctx (结果采集与传递)
```

**设计理由**：
1. **Output 的本质**：结果采集和传递，不是物理计算
2. **数据流向**：
   ```
   L4_PH/UMAT (应力更新) → L5_RT/Output_Ctx → 求解器
   L4_PH/UEL (刚度组装) → L5_RT/Output_Ctx → 求解器
   L4_PH/Contact (接触力) → L5_RT/Output_Ctx → 求解器
   ```
3. **职责分离**：L4 专注计算，L5 负责结果管理

---

### 问题 5: Amplitude 单独成域还是归入 Analysis？

**答案**：UFC 采用**独立成域**方案

#### 方案对比

| 维度 | Abaqus 方案（归入 Analysis） | UFC 方案（独立成域） |
|------|---------------------------|-------------------|
| **分类依据** | 按用途（载荷/边界时间控制） | 按数据对象本质 |
| **优点** | 直观，符合用户习惯 | 数据与计算分离，复用性强 |
| **缺点** | 幅值曲线被局限在 Analysis | 需要额外说明设计意图 |
| **UFC 选择** | ❌ | ✅ |

#### UFC 的 Amplitude 独立成域理由

```
L3_MD/Amplitude (幅值曲线定义)
  ↓
L4_PH/Amplitude (幅值插值算法)
  ↓
L5_RT/Amplitude_Ctx (幅值运行时上下文)
```

**核心理由**：
1. **独立性**：Amplitude 是独立的数据对象（时间 - 幅值曲线表）
2. **共享性**：被多个域引用
   - Load 域：DLOAD(time) = magnitude × A(t)
   - BC 域：DISP(time) = disp_magnitude × A(t)
   - Analysis 域：分析步时间控制
3. **符合 UFC 原则**：数据（L3）与计算（L4/L5）分离

---

## 完整正交矩阵（14 L3 域 × 8 Abaqus 子程序域）

### Layer × Domain × Role 立方体

```
                         UFC L3_MD 模型域 (14 domains)
      Model | Part | Asmb | Mesh | Sect | Mat  | Amp  | LoadBC | Intc | Cons | Step | Out  | Brg  | Wbck
    ───────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────
L3_MD│ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc │ Desc
     │ 模型 │ 部件 │ 装配 │ 网格 │ 截面 │ 材料 │ 幅值 │ 载边 │ 接触 │ 约束 │ 分析步│ 输出 │ 桥接 │ 写回 │
     ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────
L4_PH│  ❌  │  ❌ │  ❌  │ Elem │ Sect │全功能│ Amp  │全功能│ Cont │ Cons │  ❌  │  ❌  │ Brg  │  ❌
     │      │      │      │ 单元 │ 截面 │ 材料 │ 幅值 │ 载边 │ 接触 │ 约束 │      │      │ 桥接 │      │
     ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────
L5_RT│ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx  │ Ctx
     │ 模型 │ 部件 │ 装配 │ 单元 │ 截面 │ 材料 │ 幅值 │ 载边 │ 接触 │ 约束 │ 分析 │ 输出 │ 桥接 │ 写回 │
     │ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│ 上下文│
    └──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────
                          ↓        ↓        ↓        ↓        ↓        ↓       ↓        ↓
                        UEL    UMAT    DLOAD   DISP   UINTER   MPC   USDFLD  UAMP
                        
图例：
- Desc: 参数定义（L3 主责）—— 回答"是什么"（What）
- 全功能：State + Algo + Ctx（L4 主责）—— 回答"怎么算"（How）
- Ctx: 运行时上下文（L5 主责）—— 回答"何时何地"（When & Where）
- ❌: 不直接参与物理计算，通过其他域间接参与
```

---

## L3→L4→L5 完整映射链示例

### 示例 1: Material 域（材料本构）

```
L3_MD/Material
  TYPE MD_Mat_Desc
    REAL(wp) :: young_modulus
    REAL(wp) :: poisson_ratio
    INTEGER  :: material_model  ! 1=线弹性，2=塑性，...
  END TYPE
  → 回答"是什么"（材料参数）

L4_PH/Material (UMAT)
  SUBROUTINE PH_XXX_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, ...)
    ! 基于 MD_Mat_Desc%young_modulus 计算应力
    stress = C_elastic * strain
    IF (material_model == 2) THEN
      CALL Plasticity_Update(...)  ! 塑性本构
    END IF
  END SUBROUTINE
  → 回答"怎么算"（应力更新）

L5_RT/Material
  TYPE RT_Mat_Ctx
    REAL(wp) :: hist_vars(:,:)  ! 历史变量（塑性应变、损伤等）
    INTEGER  :: mat_point_id
  END TYPE
  INTERFACE
    CALL abq_umats(nblock, stress, statev, ...)
  END INTERFACE
  → 回答"何时何地"（求解器调用时机）
```

---

### 示例 2: LoadBC 域的拆分（Load vs BC）

```
L3_MD/LoadBC
  TYPE MD_LoadBC_Desc
    INTEGER  :: load_type  ! 1=压力，2=体力，3=位移边界
    REAL(wp) :: magnitude
    INTEGER  :: amplitude_id
  END TYPE
  → 统一存储载荷和边界条件参数
  
       ↓ 拆分为两个 L4 域

L4_PH/Load (DLOAD)
  SUBROUTINE PH_XXX_DLOAD_API(...)
    ! 计算分布载荷：p = magnitude × A(t) × f(x,y,z)
    load_value = MD_Load_Desc%magnitude * amp_value * spatial_func
  END SUBROUTINE
  → 空间分布载荷计算

L4_PH/BC (DISP)
  SUBROUTINE PH_XXX_DISP_API(...)
    ! 计算位移边界：u = magnitude × A(t)
    disp_value = MD_BC_Desc%magnitude * amp_value
  END SUBROUTINE
  → 位移边界计算
```

**为什么拆分？**
- Load 依赖**空间坐标**（积分点位置）
- BC 依赖**节点自由度**（位移/速度/加速度）
- 计算逻辑不同，必须分离

---

### 示例 3: Output 域的特殊处理

```
L3_MD/Output
  TYPE MD_Output_Desc
    CHARACTER(LEN=64) :: output_vars  ! "S,E,PEEQ,..."
    REAL(wp) :: output_interval
    INTEGER  :: output_format  ! 1=ODB, 2=TXT
  END TYPE
  → 定义输出请求

L4_PH: ❌ 无独立 Output 计算域
  → 计算结果通过 State 变量直接传递

L5_RT/Output
  TYPE RT_Output_Ctx
    REAL(wp), ALLOCATABLE :: results(:,:,:)
    INTEGER  :: current_step
  END TYPE
  SUBROUTINE RT_Output_Collect()
    ! 从 L4 收集结果
    DO each_material_point
      results(:, :, i) = PH_Mat_State%stress
    END DO
    ! 传递给求解器
    CALL abq_write_output(results)
  END SUBROUTINE
  → 结果采集和传递
```

---

## 映射规则总结表

| L3_MD 域 | L4_PH 域 | L5_RT 域 | Abaqus 子程序 | 映射类型 |
|---------|---------|---------|--------------|---------|
| Mesh | Element | Element_Ctx | UEL/VUEL | 直接映射 |
| Material | Material | Material_Ctx | UMAT/VUMAT | 直接映射 |
| LoadBC | Load | Load_Ctx | DLOAD/VDLOAD | 拆分映射 |
| LoadBC | BC | BC_Ctx | DISP/VDISP | 拆分映射 |
| Interaction | Contact | Contact_Ctx | UINTER/VUINTER | 直接映射 |
| Constraint | Constraint | Constraint_Ctx | MPC/UMESHMOTION | 直接映射 |
| - | Field | Field_Ctx | USDFLD/VUSDFLD | L4 特有域 |
| Amplitude | Amplitude | Amplitude_Ctx | UAMP/VUAMP | 独立成域 |
| Step | ❌ | Analysis_Ctx | UEXTERNALDB | 跨层映射 |
| Output | ❌ | Output_Ctx | UVARM | 结果传递 |
| Part/Assembly | ❌ | Part_Ctx/Asmb_Ctx | - | 数据传递 |
| Section | Section | Section_Ctx | - | 桥接映射 |

**映射类型说明**：
- **直接映射**: L3 域直接对应 L4 计算域
- **拆分映射**: L3 一个域拆分为 L4 两个域（如 LoadBC → Load+BC）
- **跨层映射**: L3 域跳过 L4，直接映射到 L5（如 Step → Analysis_Ctx）
- **结果传递**: L4 计算结果直接传递给 L5，无独立 L4 域
- **L4 特有域**: Field 域在 L3 无对应，是 USDFLD/VUSDFLD专属
- **桥接映射**: Section 作为 L3→L4 数据传递的中间枢纽

---

## 设计验证清单

### ✅ 已验证的设计特性

1. **正交性**：Layer × Domain 形成完整矩阵，无缺失单元格
2. **可追溯性**：每个域在三层均有明确对应，便于调试和维护
3. **扩展性**：新增域时自动覆盖三层，避免技术债务
4. **对称性**：符合数学上的张量积结构，便于形式化验证

### ⚠️ 特殊设计决策

1. **Output 域不在 L4 独立**：结果是"采集和传递"，不是"物理计算"
2. **Amplitude 独立成域**：数据对象独立，被多域共享引用
3. **Step 跨层映射**：L3 分析步配置 → L5 分析控制（跳过 L4）
4. **Field 域 L4 特有**：USDFLD/VUSDFLD专属，L3 无对应

---

## 下一步行动建议

### 高优先级（Phase 3 核心任务）

1. **实现 L3→L4 数据桥接机制**
   - MD_Bridge_Domain → PH_*_API 的路由逻辑
   - 截面中心化架构的材料路由

2. **开发 Load/BC 域模板**
   - PH_XXX_Load.f90（替代 DLOAD/VDLOAD/CLOAD）
   - PH_XXX_BC.f90（替代 DISP/VDISP）
   - PH_XXX_Contact.f90（替代 UINTER/VUINTER）

3. **完善 RT 层上下文管理**
   - RT_Output_Ctx 结果采集机制
   - RT_Analysis_Ctx 时间步进控制

### 中优先级（架构完善）

4. **Field 域设计讨论**
   - 为什么 L3 没有 Field 域？
   - USDFLD/VUSDFLD 的特殊性分析

5. **Bridge 域详细设计**
   - L3→L4 数据传递的具体实现
   - 截面号枢纽机制

---

**文档版本**：v1.0  
**最后更新**：2026-03-28  
**维护者**：UFC 架构团队
