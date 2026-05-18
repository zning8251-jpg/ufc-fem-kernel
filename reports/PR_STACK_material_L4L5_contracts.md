# PR 栈说明：Material 合同 + IF_AI 修复 + 07 勾选 + Guardian 试点

> **用途**：复制下面 **「PR 描述（粘贴用）」** 到 GitHub PR；按 **「配置 remote 并推送」** 在本地执行（需自行替换 `<ORG>/<REPO>`）。  
> **分支**：`feat/pr01-p1-p2-asm-golden-seam`  
> **仓库根**：`D:\TEST7`（`UFC/` 为子目录；`.github/workflows/ufc-ci.yml` 在 `TEST7` 根）

---

## 本栈包含的 commit

| Hash | 摘要 |
|------|------|
| `e062b0ff` | docs+fix: Material L4/L5 contracts, 07 milestones, IF_AI nested Init, guardian pilot |
| `42fc0b85` | docs(07): mark L4_PH/Material and L5_RT/Material contract-complete (2026-05-14) |
| `d807dcd5` | docs(REPORTS): PR stack template + 后续小编辑（`PR_STACK_material_L4L5_contracts.md`） |

**说明**：自 `d807dcd5` 起为同一 PR 说明文件的迭代；**当前分支 tip** 以 `git rev-parse HEAD` 为准。合并时可将这些 doc commit **squash** 为一条。

---

## PR 描述（粘贴用）

### Summary

- 补全并对齐 **`UFC/ufc_core/L4_PH/Material/CONTRACT.md`**（v1.1）与 **`UFC/ufc_core/L5_RT/Material/CONTRACT.md`**（v1.0）；修正 **`L4_PH/Element/CONTRACT.md`** 指向材料合同的链接。
- 修复 **`IF_AI_Def.f90`** 中 **`IF_AI_Model_Desc_Init` / `IF_AI_Infer_State_Init`** 与嵌套四型 TYPE 不一致导致的编译错误；**`L1_IF/Base/AI/CONTRACT.md`** 升至 v1.1 并注明嵌套布局。
- **`07_L3L4L5_二元结构合同完备里程碑.md`**：将 **`L4_PH/Material`**、**`L5_RT/Material`** 标为已完成（相对 `06` A+ 合同审查口径）。
- 新增 **`UFC/REPORTS/guardian_wave1_material_pilot_2026-05-14.md`**：对 **`ufc_core/L4_PH/Material`** 与 **`ufc_core/L5_RT/Material`** 运行 **Guardian `DEP-001` + `GLB-001`** 试点扫描结果。

### Commits

- `e062b0ff` — Material 合同 + Element 链 + IF_AI 嵌套初始化 + L1 AI 合同 + Guardian 试点报告  
- `42fc0b85` — `07` 里程碑勾选 `L4_PH/Material`、`L5_RT/Material`  
- `d807dcd5` … **`git rev-parse HEAD`** — `PR_STACK_material_L4L5_contracts.md` 模板与迭代（可 squash 为一条 doc commit）

### Evidence / reports

- [`UFC/REPORTS/guardian_wave1_material_pilot_2026-05-14.md`](./guardian_wave1_material_pilot_2026-05-14.md)  
- [`UFC/REPORTS/PR_STACK_material_L4L5_contracts.md`](./PR_STACK_material_L4L5_contracts.md)（remote 命令 + 本 PR 正文可复制版）

### Follow-up（不在本 PR 销项）

- **`L4_PH/Material` subtree** 在 **`DEP-001`** 下仍有 **2×P0**：`Damage/PH_Mat_Damage_Gurson_Core.f90`、`Plast/PH_Mat_Plast_J2_UMAT_Core.f90` **L4 USE L5** 依赖反转。需 **单独 MR** 按 Bridge/SIO 闭包重构，并与合同 **A8** 对账。

### Verification（本地 / CI）

- `python UFC/ufc_harness/run_harness.py plan-checks`（在 `UFC/` 下）应通过。  
- 全量编译：本机 MinGW 可能在 **`IF_Mem_Chunk.f90`** 等其它文件继续失败；以 **GitHub Actions `ufc-ci.yml`** 本次 PR run 为准。

---

## 配置 remote 并推送

在 **PowerShell** 中（将 URL 换成你的真实仓库；若已有 `origin` 则用 `set-url`）：

```powershell
cd D:\TEST7

# 若尚未配置 origin：
git remote add origin https://github.com/<ORG>/<REPO>.git

# 若已存在 origin 但 URL 不对：
# git remote set-url origin https://github.com/<ORG>/<REPO>.git

git push -u origin feat/pr01-p1-p2-asm-golden-seam
```

推送后在 GitHub 上 **Compare & pull request**，把上文 **「PR 描述（粘贴用）」** 整块贴进 PR 正文即可。

---

## 可选：用环境变量一行设置 remote（避免手改命令）

```powershell
$env:UFC_GITHUB_URL = "https://github.com/<ORG>/<REPO>.git"
cd D:\TEST7
if (-not (git remote)) { git remote add origin $env:UFC_GITHUB_URL } else { git remote set-url origin $env:UFC_GITHUB_URL }
git push -u origin feat/pr01-p1-p2-asm-golden-seam
```
