# Tasks: p1-material-crystal-w2-multislip

> **Phase**: **IMPLEMENT**（W2a PR）

## 0. 闸门

- [x] W1b #13 on `main`
- [x] 双滑移参考算例 **W2-REF-01**（`design.md` §6）
- [x] `change-package validate --strict`

## 1. 合同

- [x] 1.1 CONTRACT：W2a `props`/`statev` 表；W1b 为 `nprops<19` 退化
- [ ] 1.2 （可选）Registry 266 `nprops`/`nstatev` 收紧

## 2. W2a 实现

- [x] 2.1 多系 Schmid 算子 + \(\tau_c(\gamma)\) 潜硬化
- [x] 2.2 耦合返回映射（N=2，Gauss–Seidel）
- [x] 2.3 `nprops`/`nstatev` 校验与错误信息
- [x] 2.4 单系 `nprops<19` 退化 W1b 回归

## 3. 质量

- [ ] 3.1 guardian P0=0
- [ ] 3.2 最小算例 / harness（若可行）
- [ ] 3.3 GAP 快照更新

## 4. 交付

- [ ] PR → `main`；归档 `plan/tasks/p1-material-crystal-w2-multislip/`
