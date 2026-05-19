# Tasks: p1-material-crystal-w2-multislip

> **Phase**: DRAFT

## 0. 闸门

- [x] W1b #13 on `main`
- [ ] 双滑移参考算例 / 预期 \(\gamma^{(\alpha)}\) 就绪
- [ ] `change-package validate --strict`

## 1. 合同

- [ ] 1.1 CONTRACT：W2a `props`/`statev` 表；W1b 为 N=1 退化
- [ ] 1.2 （可选）Registry 266 `nprops`/`nstatev` 收紧

## 2. W2a 实现

- [ ] 2.1 多系 Schmid 算子 + \(\tau_c(\gamma)\) 潜硬化
- [ ] 2.2 耦合返回映射（N=2）
- [ ] 2.3 `nprops`/`nstatev` 校验与错误信息
- [ ] 2.4 单系 `props` 退化 W1b 回归

## 3. 质量

- [ ] 3.1 guardian P0=0
- [ ] 3.2 最小算例 / harness（若可行）
- [ ] 3.3 GAP 快照更新

## 4. 交付

- [ ] PR → `main`；归档 `plan/tasks/p1-material-crystal-w2-multislip/`
