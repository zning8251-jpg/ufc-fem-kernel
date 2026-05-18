# 纪律环（Discipline）

## `manifest.v1.json`

- **when_globs**：Unix 风格 glob，相对 **UFC 仓库根**。
- **harness_commands.argv**：传给 `python UFC/ufc_harness/run_harness.py` 的参数向量（不含脚本名）。
- **required**：`true` 表示团队期望在合入前必须跑通（CI 应配置等价步骤）；`discipline verify` 在 `--strict` 下可对匹配规则检查是否已满足（v1 仅打印义务清单，不探测历史 shell）。

## `discipline verify`

```text
python UFC/ufc_harness/run_harness.py discipline verify [--touch-path REL/...] [--strict]
```

无 `--touch-path` 时：打印全部规则与示例命令（退出码 0）。  
有 `--touch-path` 时：按路径匹配 glob，聚合应运行的 `argv` 列表；`--strict` 时若 manifest 损坏或路径非法则非零退出。

## 与 Agent Skills 7 生命周期

对照表见 `[../CROSSWALK.md](../CROSSWALK.md)` §4。