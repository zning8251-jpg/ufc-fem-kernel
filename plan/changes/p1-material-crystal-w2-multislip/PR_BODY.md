## Summary

- **W2a**：mat_id 266 双滑移（`nprops≥19`），2×2 潜硬化 + Gauss–Seidel 返回；`nprops<19` 保持 W1b。
- **W2-REF-01** 参考算例锁定（`design.md` §6）。
- **CONTRACT**：Crystal UMAT W1b/W2a `props`/`statev` 表。

## Test plan

- [x] `guardian PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0`
- [x] `change-package validate --change-id p1-material-crystal-w2-multislip --strict`
- [ ] 单点驱动 W2-REF-01 数值回归（follow-up harness）

## Notes

- W2a 一致切线为弹性 `D`；塑性切线 → 后续 PR。
