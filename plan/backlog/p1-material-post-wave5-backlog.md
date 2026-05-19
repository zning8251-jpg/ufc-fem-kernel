# P1 Material — post wave3–5 merge order & housekeeping

> **Status (2026-05-19)**：#1–#3、#5–#6 **MERGED**；原 #4 因 base 分支删除已 **CLOSED**，Crystal 由 [#6](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/6) 入主。`plan/tasks/` wave3–5 四包已迁入 `plan/archive/`（见 §3.2）。

---

## 1. 建议合并顺序

| 顺序 | PR | 分支 | change_id | 说明 |
|------|-----|------|-----------|------|
| 1a / 1b（可并行） | [#1](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/1) | `feat/p1-material-wave3-plast-loc` | `p1-material-wave3-plast-loc` | Plast J2 spine（DEP-001 + `PH_J2_ComputeStress_Arg`） |
| | [#2](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/2) | `feat/p1-material-wave4-dispatch-flow` | `p1-material-wave4-dispatch-flow` | Dispatch Eval+UMAT Arg（FLOW-003） |
| 2 | [#3](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/3) | `feat/p1-material-wave5-plast-nonj2-pra` | `p1-material-wave5-plast-nonj2` | Hill + Barlat SIO（PR-A） |
| 3 | [#6](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/6) | `feat/p1-material-wave5-plast-nonj2-prb` | 同上 | Crystal Arg（PR-B）；替代已关闭的 #4 |
| 4 | [#5](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/5) | `feat/p1-material-wave5-mateval-arg` | `p1-material-wave5-mateval-arg` | `PH_MatEval` 合同/文档；**无新 Arg 类型** |

---

## 2. 刻意 out of scope（后续新 change_id）

| 条目 | 跟踪方式 |
|------|----------|
| **C2** 按族吸收 `PH_MatEval` → `Elas/` / `Plast/` / `Hyper/` / … | 新 change_id；CONTRACT「Legacy PH_MatEval aggregate」已写 C2 指针 |
| `PH_Mat_ElasticOrthotropic_Eval` 多余 dummy 声明 | 独立小修 PR，不并入 mateval 文档包 |
| Chaboche + 全 `Plast/` guardian 清扫 | 独立清债 wave |

---

## 3. `plan/tasks/` 归档（合并后执行）

**规则**（`plan/archive/README.md`）：自 `plan/tasks/<task_id>/` **整包**迁入 `plan/archive/<task_id>/`；禁止在 `archive/` 内继续改 `ufc_core`。

**触发**：对应 PR **merged to `main`** 后，在 `main` 上执行（可逐个 PR 合并后归档，也可 #1–#5 全部合并后一次性执行）。

| PR | task_id（`plan/tasks/`） | 归档目标 |
|----|--------------------------|----------|
| #1 | `p1-material-wave3-plast-loc` | `plan/archive/p1-material-wave3-plast-loc/` |
| #2 | `p1-material-wave4-dispatch-flow` | `plan/archive/p1-material-wave4-dispatch-flow/` |
| #3/#4 | `p1-material-wave5-plast-nonj2` | `plan/archive/p1-material-wave5-plast-nonj2/` |
| #5 | `p1-material-wave5-mateval-arg` | `plan/archive/p1-material-wave5-mateval-arg/` |

可选：`plan/changes/<change_id>/` → `plan/changes/archive/<YYYY-MM-DD>-<change_id>/`（见 `plan/changes/README.md`）。

### 3.1 一次性归档脚本（`main` 上、仓库根目录）

```powershell
cd D:\TEST8\UFC_git   # 或你的 clone 根
git checkout main
git pull origin main

$ids = @(
  'p1-material-wave3-plast-loc',
  'p1-material-wave4-dispatch-flow',
  'p1-material-wave5-plast-nonj2',
  'p1-material-wave5-mateval-arg'
)

foreach ($id in $ids) {
  $src = "plan/tasks/$id"
  $dst = "plan/archive/$id"
  if (Test-Path $src) {
    if (Test-Path $dst) { Write-Warning "skip $id : archive already exists" }
    else { Move-Item $src $dst; Write-Host "archived $id" }
  } else {
    Write-Host "skip $id : no plan/tasks folder on main (may only exist on feature branch)"
  }
}
```

合并后提交示例：

```powershell
git add plan/archive plan/tasks plan/backlog/p1-material-post-wave5-backlog.md
git commit -m "chore(plan): archive P1 material wave3-5 task runs after PR merge"
git push origin main
```

### 3.2 执行记录

| task_id | PR | 归档日期 | 执行人 / 备注 |
|---------|-----|----------|----------------|
| `p1-material-wave3-plast-loc` | #1 | 2026-05-19 | → `plan/archive/p1-material-wave3-plast-loc/` |
| `p1-material-wave4-dispatch-flow` | #2 | 2026-05-19 | → `plan/archive/p1-material-wave4-dispatch-flow/` |
| `p1-material-wave5-plast-nonj2` | #3 + #6 | 2026-05-19 | → `plan/archive/p1-material-wave5-plast-nonj2/`（#4 未合并） |
| `p1-material-wave5-mateval-arg` | #5 | 2026-05-19 | → `plan/archive/p1-material-wave5-mateval-arg/` |

---

## 4. 下一波 change_id（立项顺序）

| 顺序 | 建议 change_id | 范围 |
|------|----------------|------|
| 1 | `p1-material-plast-guardian-debt` | Chaboche + Plast **P0/P1** — PR [#7](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/7) |
| 2 | `p1-material-orthotropic-eval-fix` | `PH_Mat_ElasticOrthotropic_Eval` dummy 小修 |
| 3 | `p1-material-c2-mateval-split` | C2：按族吸收 `PH_MatEval` |
| 4 | `p1-material-crystal-impl` | Crystal `STATUS_UNSUPPORTED` → 实装 |

每项：`agent-task init` → `plan/changes/<id>/` → 单 PR → 合并后归档。

## 5. 相关链接

- 变更包：`plan/changes/p1-material-wave3-plast-loc/` … `p1-material-wave5-mateval-arg/`
- GAP 快照：`plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md`
