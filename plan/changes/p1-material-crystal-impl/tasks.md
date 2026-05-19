# Tasks: p1-material-crystal-impl

> **Phase**: DRAFT — 代码任务在 #7–#10 合并后勾选。

## 0. 闸门

- [ ] #7 merged
- [ ] #8 merged
- [ ] #9 + #10 merged；C2 task 归档
- [ ] `git checkout main && git pull`；`change-package validate --strict`

## 1. 合同与类型

- [ ] 1.1 `CONTRACT.md`：mat_id 266、`props`/`statev` 表（对齐 `design.md`）
- [ ] 1.2 `UF_CrystalPlasticity_ValidateProps`（或 `CrystalPlast_MatDesc` 方法）
- [ ] 1.3 扩展 `CrystalPlast_MatDesc` 字段（若 W1 不用裸 `props`）

## 2. W1a iso-surrogate（#12 merged）

- [x] 2.1 J2 等效径向返回（**deprecated**）

## 2b. W1b Schmid（本 PR）

- [ ] 2b.1 Schmid \(\tau\)、滑移返回、`props(5:9)` s/m
- [ ] 2b.2 CONTRACT：W1a deprecated，W1b 真源
- [ ] 2.2 填充 `ddsdde`、能量项、`statev` 更新
- [ ] 2.3 错误路径：`IF_STATUS_INVALID` / message（替换 `STATUS_UNSUPPORTED`）
- [ ] 2.4 （可选）`PH_Mat_Plast_Crystal_Kernel.f90` 拆分

## 3. 质量

- [ ] 3.1 guardian P0=0（Crystal_Core；若拆 Kernel 则一并）
- [ ] 3.2 INTF-001 / MOD-001 在 touched 文件
- [ ] 3.3 discipline verify touch-path
- [ ] 3.4 更新 `P1_MATERIAL_GAP_SNAPSHOT.md` §2.1 Crystal 行

## 4. 交付

- [ ] 4.1 单 PR → `main`（`feat/p1-material-crystal-impl`）
- [ ] 4.2 合并后：`plan/tasks/p1-material-crystal-impl/` → `plan/archive/`
