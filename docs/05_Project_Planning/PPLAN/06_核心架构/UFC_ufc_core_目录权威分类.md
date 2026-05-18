# UFC `ufc_core` 目录 / 子目录权威分类

> **真源**：本表以仓库内 **`UFC/ufc_core/`** 实际目录为准（**非**推断草图）。  
> **用途**：层级—域级—子域导航、与 [Domain Procedure Registry `generated/`](../../03_Domain_Pillars/DomainProcedureRegistry/generated/) 的 **域级桶**（`<层>/<域级>/` 之首段目录名）对齐、与 [`design/.../manifest.json`](../../03_Domain_Pillars/DomainProcedureRegistry/design/manifest.schema.json) 对账。  
> **维护**：目录树变更时，请同步更新本文；可用下方「附录」命令重新枚举校验。  
> **最终目录基线（工程约定）**：自 **2026-04-22** 起，在未通过 **PPLAN/变更记录** 批准的物理搬迁前，**`ufc_core` 的层级—域桶—子域** 以本文 **§2 全图** 与 **§3～§8 分节表** 为 **UFC 内核唯一目录基线**；改动须同步 **CMake / `design/manifest.json` / Registry 扫描结果**，并复核 [ABAQUS 核心子集 ↔ UFC 映射骨架](UFC_ABAQUS核心子集_UFC层域映射骨架.md) 中的域桶列。

**文档日期**：2026-04-22

---

## 1. 术语

| 术语 | 含义 |
|------|------|
| **层** | `L1_IF` … `L6_AP`，对应 `ufc_core/<Layer>/`。 |
| **域级（域桶）** | 层之下的 **第一级子目录**（如 `L2_NM/Matrix/` 之 `Matrix`）。Registry `generated/<Layer>/<域级>/` 与之对齐。 |
| **子域** | 域级目录下的 **子目录**；再下层级在表中继续缩进列出。 |
| **叶目录** | 表中记为 `*(仅文件，无子目录)*` 表示该域桶下当前无子目录（`.f90` 等直接置于该级）。 |

---

## 2. `ufc_core` 目录 / 子目录全图

> **仅列目录**（不含 `*.f90` 等文件名）。已跳过 `build/`、`__pycache__/`、`CMakeFiles/`。若与工作区不一致，以 **`UFC/ufc_core/`** 为准，并同步更新本图与后续分节表（可结合 §10 校验命令）。

```text
ufc_core/
├── L1_IF/
│   ├── Base/
│   │   ├── AI/
│   │   ├── Parallel/
│   │   └── Symbol/
│   ├── Error/
│   ├── IO/
│   │   └── Checkpoint/
│   ├── Log/
│   ├── Memory/
│   ├── Monitor/
│   ├── Precision/
│   └── Registry/
├── L2_NM/
│   ├── Base/
│   │   └── BVH/
│   ├── Bridge/
│   ├── ExternalLibs/
│   ├── Matrix/
│   ├── Solver/
│   │   ├── AI/
│   │   ├── Conv/
│   │   ├── Coupling/
│   │   ├── LinSolv/
│   │   ├── NonlinSolv/
│   │   └── Parallel/
│   └── TimeInt/
├── L3_MD/
│   ├── Analysis/
│   │   ├── Amplitude/
│   │   ├── Solver/
│   │   └── Step/
│   ├── Assembly/
│   ├── Boundary/
│   ├── Bridge/
│   │   ├── Bridge_L4/
│   │   └── Bridge_L5/
│   ├── Constraint/
│   ├── contracts/
│   ├── Field/
│   ├── Interaction/
│   ├── KeyWord/
│   ├── Material/
│   │   ├── Acoustic/
│   │   ├── Base/
│   │   ├── Bridge/
│   │   ├── Composite/
│   │   ├── Contract/
│   │   ├── Creep/
│   │   ├── Damage/
│   │   ├── Dispatch/
│   │   ├── Domain/
│   │   ├── Elas/
│   │   ├── Geo/
│   │   ├── HyperElas/
│   │   ├── Plast/
│   │   ├── Registry/
│   │   ├── Shared/
│   │   ├── Thermal/
│   │   ├── User/
│   │   └── Viscoelas/
│   ├── Mesh/
│   │   └── Element/
│   │       ├── Acoustic/
│   │       ├── Beam/
│   │       ├── Cohesive/
│   │       ├── Dashpot/
│   │       ├── Gasket/
│   │       ├── Infinite/
│   │       ├── Mass/
│   │       ├── Membrane/
│   │       ├── Pipe/
│   │       ├── Porous/
│   │       ├── Shell/
│   │       ├── Solid2D/
│   │       ├── Solid2Dt/
│   │       ├── Solid3D/
│   │       ├── Solid3Dt/
│   │       ├── Special/
│   │       ├── Spring/
│   │       ├── Surface/
│   │       ├── Thermal/
│   │       ├── Truss/
│   │       └── User/
│   ├── Model/
│   ├── Output/
│   ├── Part/
│   ├── Section/
│   └── WriteBack/
├── L4_PH/
│   ├── Bridge/
│   │   ├── Output/
│   │   └── WriteBack/
│   ├── Constraint/
│   ├── Contact/
│   │   ├── AI/
│   │   ├── Core/
│   │   ├── Domain/
│   │   ├── Explicit/
│   │   ├── Friction/
│   │   ├── Search/
│   │   ├── Self/
│   │   ├── Thermal/
│   │   ├── Types/
│   │   └── Wear/
│   ├── Element/
│   │   ├── Acoustic/
│   │   ├── Beam/
│   │   ├── Cohesive/
│   │   ├── Dashpot/
│   │   ├── Gasket/
│   │   ├── Infinite/
│   │   ├── Mass/
│   │   ├── Membrane/
│   │   ├── Pipe/
│   │   ├── Porous/
│   │   ├── Shared/
│   │   ├── Shell/
│   │   ├── Solid2D/
│   │   ├── Solid2Dt/
│   │   ├── Solid3D/
│   │   ├── Solid3Dt/
│   │   ├── Special/
│   │   ├── Spring/
│   │   ├── Surface/
│   │   ├── Thermal/
│   │   ├── Truss/
│   │   └── User/
│   ├── Field/
│   ├── LoadBC/
│   └── Material/
│       ├── Acoustic/
│       ├── Base/
│       ├── Bridge/
│       ├── Composite/
│       ├── Contract/
│       ├── Creep/
│       ├── Damage/
│       ├── Dispatch/
│       ├── Domain/
│       ├── Elas/
│       ├── Geo/
│       ├── HyperElas/
│       ├── Plast/
│       ├── Registry/
│       ├── Shared/
│       ├── Thermal/
│       ├── User/
│       └── Viscoelas/
├── L5_RT/
│   ├── Assembly/
│   ├── Bridge/
│   │   └── Shared/
│   ├── Contact/
│   ├── Element/
│   │   └── Mesh/
│   ├── LoadBC/
│   ├── Logging/
│   ├── Material/
│   ├── Output/
│   ├── Solver/
│   │   └── Coupling/
│   ├── StepDriver/
│   └── WriteBack/
└── L6_AP/
    ├── Bridge/
    ├── Config/
    ├── Input/
    │   ├── Command/
    │   ├── Parser/
    │   └── Script/
    ├── Job/
    ├── Output/
    ├── Registry/
    ├── Solver/
    └── UI/
```

---

## 3. L1_IF — 基础设施层

**域级目录**（`ufc_core/L1_IF/<域>/`）：

| 域级 | 子域（若有） |
|------|----------------|
| **Base** | `AI/`、`Parallel/`、`Symbol/` |
| **Error** | *(仅文件，无子目录)* |
| **IO** | `Checkpoint/` |
| **Log** | *(仅文件，无子目录)* |
| **Memory** | *(仅文件，无子目录)* |
| **Monitor** | *(仅文件，无子目录)* |
| **Precision** | *(仅文件，无子目录)* |
| **Registry** | *(仅文件，无子目录)* |

**说明**：`AI`、`Parallel`、`Symbol` 位于 **`Base/` 下**，与顶层 `Error`、`IO` 等并列，均为 L1 域桶。

---

## 4. L2_NM — 数值方法层

| 域级 | 子域（若有） |
|------|----------------|
| **Base** | `BVH/` |
| **Bridge** | *(仅文件，无子目录)* |
| **ExternalLibs** | *(第三方封装聚合；`*.f90` 多直接置于该域桶；**不参与** Registry 逐文件扫描，见 CONVENTIONS)* |
| **Matrix** | *(仅文件，无子目录)* |
| **Solver** | `AI/`、`Conv/`、`Coupling/`、`LinSolv/`、`NonlinSolv/`、`Parallel/` |
| **TimeInt** | *(仅文件，无子目录)* |

**说明**：层容器等 **L2 总入口** 以 `ufc_core/L2_NM/` 下 `NM_L2Layer*.f90` 等源码文件形式存在，**不**单独占用 `LayerContainer/` 目录名。

---

## 5. L3_MD — 模型数据层

| 域级 | 子域（若有） |
|------|----------------|
| **Analysis** | `Amplitude/`、`Solver/`、`Step/` |
| **Assembly** | *(仅文件，无子目录)* |
| **Boundary** | *(仅文件，无子目录)* |
| **Bridge** | `Bridge_L4/`、`Bridge_L5/` |
| **Constraint** | *(仅文件，无子目录)* |
| **contracts** | *(层内合同聚合目录，非业务域桶)* |
| **Field** | *(仅文件，无子目录)* |
| **Interaction** | *(仅文件，无子目录)* |
| **KeyWord** | *(仅文件，无子目录)* |
| **Material** | `Acoustic/`、`Base/`、`Bridge/`、`Composite/`、`Contract/`、`Creep/`、`Damage/`、`Dispatch/`、`Domain/`、`Elas/`、`Geo/`、`HyperElas/`、`Plast/`、`Registry/`、`Shared/`、`Thermal/`、`User/`、`Viscoelas/` |
| **Mesh** | `Element/`（其下再分单元族子域，见下表） |
| **Model** | *(仅文件，无子目录)* |
| **Output** | *(仅文件，无子目录)* |
| **Part** | *(仅文件，无子目录)* |
| **Section** | *(仅文件，无子目录)* |
| **WriteBack** | *(仅文件，无子目录)* |

### 5.1 `Elem/` — 模型侧单元族子域

`ufc_core/L3_MD/Elem/<族>/`

| 子域 |
|------|
| `Acoustic`、`Beam`、`Cohesive`、`Dashpot`、`Gasket`、`Infinite`、`Mass`、`Membrane`、`Pipe`、`Porous`、`Shell`、`Solid2D`、`Solid2Dt`、`Solid3D`、`Solid3Dt`、`Special`、`Spring`、`Surface`、`Thermal`、`Truss`、`User` |

（`Elem/` 根目录另有跨族 `*.f90`，表中不拆文件名。）

---

## 6. L4_PH — 物理计算层

| 域级 | 子域（若有） |
|------|----------------|
| **Bridge** | `Output/`、`WriteBack/` |
| **Constraint** | *(仅文件，无子目录)* |
| **Contact** | `AI/`、`Core/`、`Domain/`、`Explicit/`、`Friction/`、`Search/`、`Self/`、`Thermal/`、`Types/`、`Wear/` |
| **Element** | `Acoustic`、`Beam`、`Cohesive`、`Dashpot`、`Gasket`、`Infinite`、`Mass`、`Membrane`、`Pipe`、`Porous`、`Shared`、`Shell`、`Solid2D`、`Solid2Dt`、`Solid3D`、`Solid3Dt`、`Special`、`Spring`、`Surface`、`Thermal`、`Truss`、`User`（均为 **子目录**） |
| **Field** | *(仅文件，无子目录)* |
| **LoadBC** | *(仅文件，无子目录)* |
| **Material** | 与 L3 `Material` 子域名集合 **对齐**（`Acoustic` … `Viscoelas` 等，同上表风格，均为子目录） |

---

## 7. L5_RT — 运行时协调层

| 域级 | 子域（若有） |
|------|----------------|
| **Assembly** | *(仅文件，无子目录)* |
| **Bridge** | `Shared/` |
| **Contact** | *(仅文件，无子目录)* |
| **Element** | `Mesh/` |
| **LoadBC** | *(仅文件，无子目录)* |
| **Logging** | *(仅文件，无子目录)* |
| **Material** | *(仅文件，无子目录)* |
| **Output** | *(仅文件，无子目录)* |
| **Solver** | `Coupling/` |
| **StepDriver** | *(仅文件，无子目录)* |
| **WriteBack** | *(仅文件，无子目录)* |

---

## 8. L6_AP — 应用层

| 域级 | 子域（若有） |
|------|----------------|
| **Bridge** | *(仅文件，无子目录)* |
| **Config** | *(仅文件，无子目录)* |
| **Input** | `Command/`、`Parser/`、`Script/` |
| **Job** | *(仅文件，无子目录)* |
| **Output** | *(仅文件，无子目录)* |
| **Registry** | *(仅文件，无子目录)* |
| **Solver** | *(仅文件，无子目录)* |
| **UI** | *(仅文件，无子目录)* |

---

## 9. 与 Registry / `design` 的对应关系

- **`generated/<Layer>/…/<stem>.md`**：`python UFC/tools/domain_procedure_registry_scan.py` 输出 **完整镜像** `ufc_core/<Layer>/…/<stem>.f90` 的相对路径（仅后缀改为 `.md`），**不再**压平到「仅首段域桶」单文件夹；与本文 **§2 全图 / §5.1 子域** 一致。层内索引 `_LAYER_INDEX.md` 仍按 **域桶**（路径在 `<Layer>/` 下的首段目录名）分组列出条目。  
- **`design/<Layer>/<域级>/manifest.json`** 中的 **`domain_bucket`** 仍指 **域级桶**（层下首段目录，如 `Matrix`、`Mesh`）；`modules[].source_rel` 可指向该桶下任意子路径；对齐工具按 **完整镜像路径** 查找 `generated/` 下对应 `.md`。参见 [DomainProcedureRegistry/design/README.md](../../03_Domain_Pillars/DomainProcedureRegistry/design/README.md)。  
- **`ExternalLibs/`**（L2）：保留为封装域；**Registry 扫描默认跳过**（见 [`CONVENTIONS.md`](../../03_Domain_Pillars/DomainProcedureRegistry/CONVENTIONS.md)）。  
- **`contracts/`**（L3）：合同与元数据，**不等同**于业务域桶；manifest 通常不强制覆盖，除非团队约定纳入对账。

### 9.1 全六层：MODULE ``*_Algo.f90`` 收敛与 `generated/`（规划）

- **能扩展到全六层吗？** **能**，但必须 **按域桶 / 子树分批**（多 PR），并与 **`design/` + CONTRACT** 对齐；**禁止**单次无清单的全仓库盲改。  
- **与「域拆分 / 目录搬迁」的关系**：**不同工作项**。后者改变 **§2 物理树**，须 PPLAN 批准并同步 CMake、manifest、映射骨架文档（见本文 **§1 最终目录基线**）；前者主要是 **编译单元角色后缀**（``_Algo``→``_Ops``）与 ``USE`` 面修补。  
- **工具**：[`UFC/tools/migrate_ufc_module_algo_to_ops.py`](../../../tools/migrate_ufc_module_algo_to_ops.py) 支持 ``--under ufc_core/相对子路径``（可重复）、可选 ``--stem-prefix``（例如仅在 ``L4_PH/`` 子树下处理 ``PH_`` 前缀，避免误迁异前缀文件）、``--apply``。L4 Element 的固定入口仍见 [`migrate_l4_ph_element_algo_to_ops.py`](../../../tools/migrate_l4_ph_element_algo_to_ops.py)。  
- **`generated/`**：源码改名后 **只依赖重新 scan** 刷新镜像；**不**在 `generated/` 上手改与源码文件名脱节的 `.md`。  
- **命名真源**：过程体 MODULE 与 **四型 TYPE `*_Algo`** 的区分以 [CONVENTIONS.md §1.2–§2](../../03_Domain_Pillars/DomainProcedureRegistry/CONVENTIONS.md) 与 [UFC_命名与数据结构规范.md](../../UFC_命名与数据结构规范.md) §3.2 为准。

---

## 10. 维护与校验

1. **目录变更**（新增域桶或子域）：更新 **§2 全图**、**§3～§8** 分节表，以及相关 `design/manifest.json`。  
2. **机械复核**（可选）：在仓库根执行：

```bash
python -c "from pathlib import Path
root = Path('UFC/ufc_core')
for L in ['L1_IF','L2_NM','L3_MD','L4_PH','L5_RT','L6_AP']:
    p = root/L
    if not p.is_dir(): continue
    print('===', L, '===')
    for d in sorted(p.iterdir()):
        if d.is_dir() and d.name not in ('build','__pycache__'):
            subs = sorted(x.name for x in d.iterdir() if x.is_dir())
            print(f'  {d.name}/  subdirs={subs}')
"
```

将输出与本文 diff；若有差异，以 **`ufc_core` 实际结果** 为准修订本文。

3. **Registry 域桶 INTENT + manifest 批量补齐**（与 `align` 对账）：在仓库根执行 `python UFC/tools/bootstrap_design_domain_intents.py`，再 `python UFC/tools/domain_procedure_registry_scan.py` → `python UFC/tools/domain_procedure_registry_align.py`（exit code 0 即无漂移）。**PR 建议**：单域桶或单子树 + 构建通过；**物理拆域** 单独 PPLAN，与 `_Ops` 收敛交叉时先定目录再迁模块名（§9.1）。

---

## 11. 参考链接

| 文档 | 路径 |
|------|------|
| Registry 约定 | [`UFC/docs/DomainProcedureRegistry/CONVENTIONS.md`](../../03_Domain_Pillars/DomainProcedureRegistry/CONVENTIONS.md) |
| 命名总规范 | [`UFC/docs/UFC_命名与数据结构规范.md`](../../UFC_命名与数据结构规范.md) |
| 推断清单（叙述密度参考，**非**磁盘真源） | [`UFC_层级域级f90文件推断清单_v2.0.md`](UFC_层级域级f90文件推断清单_v2.0.md) |
| design 真源与对齐 | [`UFC/docs/DomainProcedureRegistry/design/README.md`](../../03_Domain_Pillars/DomainProcedureRegistry/design/README.md) |
| ABAQUS 核心子集 ↔ UFC 映射（骨架） | [`UFC_ABAQUS核心子集_UFC层域映射骨架.md`](UFC_ABAQUS核心子集_UFC层域映射骨架.md) |
