# 全栈跨域数据流图

> **版本**: v1.1 | **日期**: 2026-04-26
>
> **定位**: 追踪全部跨域生产/消费关系，验证端到端数据闭合。
>
> **v1.1 变更**: 新增三级存储层数据流 (§六)；更新温度梯度图 (§三) 增加池归属；更新闭合矩阵。
>
> **关联**: [ALGORITHM_STEP_PROTOCOL.md](../../templates/ALGORITHM_STEP_PROTOCOL.md) · 三个黄金样板
>
> **存储层详细**: [ASP_STORAGE_CROSS_CUT.md](ASP_STORAGE_CROSS_CUT.md) | [THREE_TIER_STORAGE.md](THREE_TIER_STORAGE.md)

---

## 一、主数据流：L6 → L3 → L4 → L5 → L3 (回写)

### Phase 1: Config（冷路径）

```
用户/INP 文件
    │
    ▼
┌──────────┐
│ L6_AP    │ AP_Input_Read_File
│ Input    │ AP_Input_Process_Keywords
│ Config   │ AP_Config_Parse_CommandLine
└────┬─────┘
     │ Bridge(Populate)
     ▼
┌──────────────────────────────────────────────────────────┐
│ L3_MD 模型树 (唯一真相源)                                │
│                                                          │
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌─────────┐ ┌────────┐│
│ │ Model  │ │ Mesh   │ │Material│ │ Section │ │ Part   ││
│ │(n_dim, │ │(nodes, │ │(E,nu,  │ │(thick,  │ │(id,    ││
│ │ name)  │ │ conn)  │ │ rho)   │ │ mat_id) │ │ sec_id)││
│ └────────┘ └────────┘ └────────┘ └─────────┘ └────────┘│
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌─────────┐ ┌────────┐│
│ │Assembly│ │Boundary│ │Constrt │ │ KeyWord │ │Analysis││
│ │(inst)  │ │(BC,    │ │(MPC,   │ │(parser) │ │(steps, ││
│ │        │ │ loads) │ │ tie)   │ │         │ │ ampl)  ││
│ └────────┘ └────────┘ └────────┘ └─────────┘ └────────┘│
│ ┌────────┐ ┌────────┐ ┌────────┐                       │
│ │ Field  │ │Output  │ │Interact│                       │
│ │(fields)│ │(req)   │ │(pairs) │                       │
│ └────────┘ └────────┘ └────────┘                       │
└──────────────────────┬───────────────────────────────────┘
                       │ Validate_All (闸门)
                       ▼
```

### Phase 2: Populate（冷路径，单向 L3→L4/L5）

```
L3_MD/Material ──────→ L4_PH/Material/Elas.Desc (E, nu → G, lambda)
L3_MD/Material ──────→ L4_PH/Material/Plast.Desc (yield_stress, ...)
L3_MD/Section  ──────→ L4_PH/Element.Desc (thickness, integration_order)
L3_MD/Mesh     ──────→ L4_PH/Element.Desc (n_nodes, coords)
L3_MD/Boundary ──────→ L4_PH/LoadBC.Desc (load_cache, bc_cache)
L3_MD/Constraint ────→ L4_PH/Constraint.Desc (mpc_type, coeffs)
L3_MD/Interaction ───→ L4_PH/Contact.Desc (surface_pairs, friction)
L3_MD/Analysis ──────→ L5_RT/StepDriver.Desc (time_start/end, dt)
L3_MD/Assembly ──────→ L5_RT/Assembly.Desc (dof_map, neq)
L3_MD/Output   ──────→ L5_RT/Output.Desc (field_requests)
```

### Phase 3: Step → Increment → Iteration → Local（热路径）

```
┌─────────────────────── L5_RT 编排层 ──────────────────────┐
│                                                            │
│  StepDriver.Run_Step                                       │
│    ├─ Begin_Step                                           │
│    └─ INC LOOP:                                            │
│        ├─ Begin_Increment                                  │
│        ├─ NR_Increment (ITER LOOP):                        │
│        │   ├─ RT_Element.Loop_Ke ──→ L4_PH/Element:        │
│        │   │   └─ per elem:                                │
│        │   │       ├─ Shape functions (N, dN)               │
│        │   │       ├─ Jacobian (J, detJ)                    │
│        │   │       ├─ B-matrix = dN * J^-1                  │
│        │   │       └─ GP LOOP:                              │
│        │   │           ├─ strain = B * u                    │
│        │   │           ├─ L4/Material.Compute_Stress(strain)│
│        │   │           │   ←→ stress, tangent               │
│        │   │           └─ Ke += w*B^T*C_tan*B*detJ          │
│        │   │                                                │
│        │   ├─ RT_Element.Loop_Fe ──→ L4_PH/Element:        │
│        │   │   └─ per elem:                                │
│        │   │       └─ GP LOOP:                              │
│        │   │           └─ Fe += w*B^T*sigma*detJ            │
│        │   │                                                │
│        │   ├─ RT_LoadBC.Assemble_Loads → L4/LoadBC:        │
│        │   │   └─ F_ext = concentrated + distributed + ...  │
│        │   │                                                │
│        │   ├─ RT_Assembly.Assemble_K (K_global scatter)     │
│        │   ├─ RT_Assembly.Assemble_F (F_global scatter)     │
│        │   ├─ RT_Assembly.Apply_BC (Dirichlet)              │
│        │   ├─ RT_Assembly.Apply_Constraints (MPC)           │
│        │   ├─ RT_Assembly.Compute_Residual (R = F - K*u)    │
│        │   │                                                │
│        │   ├─ RT_Solver.Solve_Linear ──→ L2_NM/Solver:    │
│        │   │   └─ CG/PCG/Direct(K, R) → du                 │
│        │   │                                                │
│        │   ├─ u = u + du                                    │
│        │   └─ RT_Solver.Check_Convergence (||R|| < tol?)    │
│        │                                                    │
│        ├─ End_Increment                                    │
│        │   ├─ converged → Advance_Time                     │
│        │   │   └─ RT_Material.Save_State (commit SDV)      │
│        │   └─ not converged → Cutback                      │
│        │       └─ RT_Material.Restore_State (revert SDV)   │
│        └─ Check_Step_Complete?                             │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### Phase 4: Post-Step（冷路径，L5→L3 回写）

```
L5_RT/WriteBack ──────→ L3_MD/WriteBack
   ├─ Displacements (u) ──→ L3_MD/Field.values
   ├─ Stresses (sigma)  ──→ L3_MD/Field.values
   ├─ SDVs              ──→ L3_MD/Material.state_vars
   └─ Reactions          ──→ L3_MD/Boundary.reactions

L5_RT/Output ──────→ 文件系统
   ├─ Write_Frame ──→ ODB/HDF5
   ├─ Write_Field ──→ VTK
   └─ Write_History ──→ CSV/DAT
```

---

## 二、跨域生产/消费闭合矩阵

| 数据项 | 生产者(层.域.过程) | 消费者(层.域.过程) | Phase | 闭合? |
|--------|-------------------|-------------------|-------|-------|
| E, nu (材料参数) | L6→L3_MD/Material.Add | L4_PH/Mat_Elas.Brg (Populate) | Config→Populate | ✓ |
| G, lambda (派生) | L4_PH/Mat_Elas.Init_From_Props | L4_PH/Mat_Elas.Build_D_el | Config | ✓ |
| D_el(6,6) | L4_PH/Mat_Elas.Build_D_el | L4_PH/Mat_Elas.Compute_Stress/Tangent | Local | ✓ |
| strain(6) | L4_PH/Element.Compute_Ke (B*u) | L4_PH/Material.Compute_Stress | Local | ✓ |
| stress(6) | L4_PH/Material.Compute_Stress | L4_PH/Element.Compute_Fe/Fint | Local | ✓ |
| tangent(6,6) | L4_PH/Material.Compute_Tangent | L4_PH/Element.Compute_Ke | Local | ✓ |
| Ke(ndof,ndof) | L4_PH/Element.Compute_Ke | L5_RT/Assembly.Scatter_Ke | Local→Iter | ✓ |
| Fe(ndof) | L4_PH/Element.Compute_Fe | L5_RT/Assembly.Scatter_Fe | Local→Iter | ✓ |
| K_global (CSR) | L5_RT/Assembly.Assemble_K | L5_RT/Solver.Solve_Linear | Iteration | ✓ |
| F_global | L5_RT/Assembly.Assemble_F | L5_RT/Solver.Solve_Linear | Iteration | ✓ |
| R (residual) | L5_RT/Assembly.Compute_Residual | L5_RT/Solver.Check_Convergence | Iteration | ✓ |
| du | L5_RT/Solver.Solve_Linear (via L2) | L5_RT/StepDriver.NR_Increment | Iteration | ✓ |
| u (updated) | L5_RT/StepDriver.NR_Increment | L5_RT/WriteBack / L5_RT/Output | Iter→Step | ✓ |
| F_ext | L4_PH/LoadBC.Concentrated_Force+… | L5_RT/Assembly.Assemble_F | Iteration | ✓ |
| T_mpc | L4_PH/Constraint.Build_MPC_Transform | L5_RT/Assembly.Apply_Constraints | Iteration | ✓ |
| time_current | L5_RT/StepDriver.Advance_Time | L4_PH/LoadBC (幅值求值) | Increment | ✓ |
| dt | L5_RT/StepDriver.Begin_Increment | L2_NM/TimeInt (若动力学) | Increment | ✓ |
| converged | L5_RT/Solver.Check_Convergence | L5_RT/StepDriver.End_Increment | Iteration | ✓ |
| SDV (commit) | L5_RT/Material.Save_State | L5_RT/Material (下一增量) | Increment | ✓ |
| SDV (revert) | L5_RT/Material.Restore_State | L5_RT/Material (重试) | Increment | ✓ |

**结论**: 20 项核心跨域数据全部闭合，无悬空。

### 三级存储相关闭合项 (新增)

| 数据项 | 生产者(层.域.过程) | 消费者(层.域.过程) | Phase | 闭合? |
|--------|-------------------|-------------------|-------|-------|
| PoolConfig(10) | L1/StorageMgr.Init + Configure | L1/StorageMgr.Alloc/Free/Spill 全部 | Config | ✓ |
| 池内存指针 (ptr) | L1/StorageMgr.Alloc | L2-L6 全部域 (替代 ALLOCATE) | (any) | ✓ |
| SpillRecord | L1/StorageMgr.Spill_Execute | L1/StorageMgr.Reload, IO.SpillFile_Read | Inc | ✓ |
| SpillFile 块数据 | L1/IO.SpillFile_WriteBlock | L1/IO.SpillFile_ReadBlock | Inc→(any) | ✓ |
| PoolStats | L1/StorageMgr.Alloc/Free/Spill (更新) | L1/StorageMgr.Spill_Check, Print_Report | (any) | ✓ |
| SP3 IO_BUFFER 数据 | L5_RT/Output.Write_Frame | L1/IO.IOBuf_Flush → ODB/VTK | Step | ✓ |
| Checkpoint 文件 | L1/IO.IncrCP_Write (P3+P7 dump) | L1/IO.Read_Checkpoint (Restart) | Step | ✓ |
| SpillFile 句柄 | L1/IO.SpillFile_Open | L1/StorageMgr.Spill/Reload, IO.SpillFile_Close | Config→Finalize | ✓ |

**结论**: 20 + 8 = 28 项跨域数据全部闭合。

---

## 三、温度梯度图 (含三级存储池归属)

```
     COLD                WARM                  HOT
  ┌──────────┐     ┌──────────────┐     ┌──────────────────┐
  │ L6_AP    │     │ L5_RT/       │     │ L4_PH/           │
  │ Config   │     │ StepDriver   │     │ Element.Compute_Ke│
  │ L3_MD    │     │ state.*      │     │ Material.Compute_σ│
  │ all CRUD │     │ ctx.*        │     │ L2_NM/Solver.CG  │
  │ Populate │     │ RT_Assembly  │     │ RT_Asm.Scatter_Ke │
  │ Validate │     │ RT_Output    │     │ RT_Asm.Compute_R  │
  └──────────┘     └──────────────┘     └──────────────────┘
   池: P1, P2        池: P3, P4, P7       池: P5, P6
   可溢出→Tier 3     可溢出→Tier 3        禁止溢出
                                           ↑ O(n_elem * n_gp * n_iter)
    O(1)             O(n_inc)               每次迭代执行
    启动一次          每步 ~数十次            每次迭代 ~数万次

  专用池: SP1(AI推理) | SP2(线程工作区) | SP3(IO双缓冲→ODB/VTK)
```

---

## 四、数据温度与 TYPE 对应

| 温度 | INTENT | TYPE 载体 | 典型数据 | 频率 |
|------|--------|-----------|---------|------|
| 冷 (COLD) | IN | Desc | E, nu, n_nodes, time_end | 启动一次 |
| 温 (WARM) | INOUT | State | time_current, dt, stress_n | 每增量更新 |
| 热 (HOT) | INOUT | Ctx | B_matrix, D_el, Ke_local | 每迭代/每GP |

---

## 六、三级存储层数据流

### 存储层纵向数据流 (Tier 1 ↔ Tier 2 ↔ Tier 3)

```
┌─── 上层域 (L2-L6) ─────────────────────────────────────────┐
│                                                              │
│  L6/Config ──→ IF_StorageMgr.Init (创建 10 池)               │
│  L3/Model  ──→ IF_StorageMgr.Configure (自适应池容量)         │
│                                                              │
│  L3/Mesh, Material, ... ──→ StorageMgr.Alloc(P1/P2) ──→ ptr │
│  L5/State vectors        ──→ StorageMgr.Alloc(P3/P7) ──→ ptr│
│  L4/Ctx, L2/Solver       ──→ StorageMgr.Alloc(P5/P6) ──→ ptr│
│  L5/Output               ──→ IO.IOBuf_Write(SP3)     ──→ buf│
│                                                              │
└──────────────────────┬───────────────────────────────────────┘
                       │
      ┌────────────────┴───────────────────────────────┐
      │         Tier 2: IF_StorageMgr (内存池)          │
      │                                                 │
      │  分配: Alloc(pool_id, nbytes) → ptr, block_id   │
      │  释放: Free(pool_id, block_id)                   │
      │  重置: Reset_Pool(P5/P6) — 每迭代               │
      │  监控: Spill_Check — utilization > threshold?    │
      │                                                 │
      └──────────┬──────────────────┬───────────────────┘
                 │ Spill ↓          │ ↑ Reload
      ┌──────────┴──────────────────┴───────────────────┐
      │         Tier 3: External Storage (磁盘)         │
      │                                                  │
      │  SpillFile: 块级 append-only, LRU 淘汰           │
      │  Checkpoint: WARM 池 snapshot, 增量写入            │
      │  Output: ODB/VTK/HDF5 via SP3 双缓冲              │
      │                                                  │
      └──────────────────────────────────────────────────┘
```

### 存储层横向数据流 (跨 Phase)

```
Config Phase:
  StorageMgr.Init ──→ 10 池创建
  SpillFile.Open  ──→ Tier 3 通道建立
  COLD 池分配     ──→ P1/P2 (Desc 数据)

Populate Phase:
  COLD 池填充     ──→ P1/P2 写入 (coords, conn, props)
  WARM 池分配     ──→ P3/P7 (State 数据初始化为零)

Step Phase:
  HOT 池 Reset    ──→ P5/P6 bump 指针归零
  迭代向量分配    ──→ P5 (r, p, Ap, du)
  K_global 分配   ──→ P6 (CSR)

Iteration Phase (热路径):
  P5/P6 直接读写  ──→ 无额外开销
  (罕见) Reload   ──→ 已溢出块从 Tier 3 回载

Increment End:
  State 演化      ──→ P5→P3 (stress→stress_n)
  Spill 检查      ──→ COLD/WARM 池 LRU 溢出
  Checkpoint      ──→ P3+P7 → Tier 3

Step End:
  Output 刷出     ──→ SP3 → ODB/VTK
  预取            ──→ 下一步 COLD 块回载

Finalize:
  全池释放        ──→ P1-P7, SP1-SP3
  SpillFile 清理  ──→ 删除临时文件
```

---

## 五、层间 Bridge 模块清单

| Bridge 模块 | 源域 | 目标域 | 搬运数据 | Phase |
|-------------|------|--------|---------|-------|
| MD_MatLibPH_Brg | L3/Material | L4/Material.Desc | props, mat_type | Populate |
| MD_ElemPH_Brg | L3/Mesh+Section | L4/Element.Desc | n_nodes, coords, thickness | Populate |
| MD_ContPH_Brg | L3/Boundary | L4/LoadBC.Desc | load_cache, bc_cache | Populate |
| MD_ConstraintPH_Brg | L3/Constraint | L4/Constraint.Desc | mpc_type, coeffs | Populate |
| PH_Mat_Elas_Brg_FromL3Desc | L3/Material | L4/Mat/Elas.Desc | E, nu | Populate |
| MD_Model_Brg | L3/Model | L5/StepDriver | n_dim | Populate |
| MD_Mesh_Brg | L3/Mesh | L5/Assembly | node_coords, connectivity | Populate |
| MD_KWRT_Brg | L3/KeyWord | L5/RT 配置 | 关键字参数 | Populate |
| AP_BrgL3 | L6/Input | L3/Model+Mesh+... | INP 解析结果 | Config |
| AP_BrgL5 | L6/Solver | L5/StepDriver | 求解器配置 | Config |
| RT_WriteBack_* | L5/WriteBack | L3/WriteBack | u, sigma, SDV, reactions | Step(Post) |
| **StorageMgr_Spill_Brg** | **L1/StorageMgr** | **L1/IO (SpillFile)** | **溢出块数据 (serialize→disk)** | **Inc (auto)** |
| **StorageMgr_Reload_Brg** | **L1/IO (SpillFile)** | **L1/StorageMgr** | **回载块数据 (disk→deserialize)** | **(any, on-demand)** |
| **StorageMgr_Checkpoint_Brg** | **L1/StorageMgr (P3+P7)** | **L1/IO (Persist)** | **WARM 池 snapshot** | **Step (conditional)** |
| **StorageMgr_Output_Brg** | **L5/Output** | **L1/IO (SP3 IOBuf)** | **Field/History → 双缓冲** | **Step** |

---

## 七、DP/SymTbl 数据流与错误链 (v1.2 新增)

详细设计见 [L1_IF_INTEGRATION.md](L1_IF_INTEGRATION.md) 第五、六、十一章。

Checkpoint/Restart 统一流程见 [CHECKPOINT_UNIFIED_FLOW.md](CHECKPOINT_UNIFIED_FLOW.md)。

| Bridge 模块 | 源域 | 目标域 | 搬运数据 | Phase |
|-------------|------|--------|---------|-------|
| **AP_StorageCfg_Brg** | **L6/Config** | **L1/StorageMgr** | **pool_size_mb, spill_threshold** | **Config** |
