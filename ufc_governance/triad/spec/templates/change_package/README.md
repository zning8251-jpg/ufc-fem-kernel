# 变更包模板（最小集）

将下列文件复制到 `UFC/plan/changes/<change_id>/` 后按需填写：


| 模板文件                                           | 目标文件名                        |
| ---------------------------------------------- | ---------------------------- |
| `[proposal.template.md](proposal.template.md)` | `proposal.md`                |
| `[design.template.md](design.template.md)`     | `design.md`                  |
| `[tasks.template.md](tasks.template.md)`       | `tasks.md`                   |
| `[spec.template.md](spec.template.md)`         | `specs/<capability>/spec.md` |


填写后运行：

```text
python UFC/ufc_harness/run_harness.py change-package validate --change-id <change_id>
```

