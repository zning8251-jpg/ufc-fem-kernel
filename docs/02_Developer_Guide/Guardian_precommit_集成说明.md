# UFC Guardian pre-commit 集成说明

> 更新日期：2026-03-15  
> 参考：UFC_Agentic_Engineering_方案.md §4 Agent-03

---

## 一、方式一：pre-commit 框架（推荐）

### 安装

```bash
pip install pre-commit
cd UFC
pre-commit install
```

### 行为

- 当 `git commit` 包含 `.f90` 文件时自动触发
- 运行 `arch_guardian.py ufc_core --fail-on-p0 --p0-only`
- 若存在 P0 违规，提交被拒绝（exit 1）

### 手动运行

```bash
pre-commit run ufc-guardian-p0 --all-files
```

---

## 二、方式二：手动安装 Git hook

适用于未安装 pre-commit 框架的环境：

```powershell
cd UFC
.\scripts\setup_guardian_precommit.ps1
```

或手动将 `scripts/setup_guardian_precommit.ps1` 生成的 hook 内容复制到 `.git/hooks/pre-commit`。

---

## 三、CI 集成示例

### GitHub Actions

```yaml
- name: UFC Guardian (P0)
  run: |
    cd ufc_core
    python scripts/arch_guardian.py . --fail-on-p0 --p0-only
```

### 通用 CI

```bash
python ufc_core/scripts/arch_guardian.py ufc_core --fail-on-p0
# exit code 1 = 存在 P0 违规，CI 失败
```

---

## 四、跳过检查（慎用）

临时跳过（不推荐）：

```bash
git commit --no-verify -m "..."
```

仅当紧急修复且已确认无 P0 违规时使用。
