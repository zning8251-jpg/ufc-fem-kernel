# UFC 文档月度清理 - Windows 任务计划程序配置指南

## 📋 配置步骤

### 方法 1: 使用 PowerShell 命令快速创建

以**管理员身份**运行 PowerShell，执行以下命令：

```powershell
# 获取脚本路径
$scriptPath = "D:\TEST7\UFC\scripts\cleanup_docs_monthly.ps1"

# 创建任务操作
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# 创建触发器（每月最后一个周五 09:00）
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -WeeksInterval 1
$trigger.EndBoundary = (Get-Date).AddYears(1).ToString("yyyyMMddTHHmmss")

# 创建主体（使用当前用户）
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U -RunLevel Highest

# 注册任务
Register-ScheduledTask -TaskName "UFC 文档月度清理" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Description "每月最后一个周五自动执行文档健康检查和归档" `
    -Force
```

### 方法 2: 使用图形界面手动创建

1. **打开任务计划程序**
  - Win + R → 输入 `taskschd.msc` → 回车
2. **创建基本任务**
  - 右侧点击「创建基本任务」
  - 名称：`UFC 文档月度清理`
  - 描述：`每月最后一个周五自动执行文档健康检查和归档`
3. **设置触发器**
  - 触发器类型：**每周**
  - 开始时间：`09:00:00`
  - 勾选：`星期五`
  - 高级设置 → 勾选「高级设置」
  - 月份选择：全选（1-12 月）
  - 周数：第 4 周和第 5 周（覆盖所有月末周五）
4. **设置操作**
  - 操作类型：「启动程序」
  - 程序或脚本：`PowerShell.exe`
  - 添加参数：
    ```
    -NoProfile -ExecutionPolicy Bypass -File "D:\TEST7\UFC\scripts\cleanup_docs_monthly.ps1"
    ```
5. **完成配置**
  - 勾选「当单击完成时打开此任务属性的对话框」
  - 点击「完成」
6. **高级设置（可选）**
  - 在属性对话框中：
    - ✅ 使用最高权限运行
    - ✅ 不管用户是否登录都要运行
    - 停止任务：超时设置为 1 小时
    - 重试间隔：5 分钟（如果失败）

## 🔧 测试任务

### 手动运行一次验证配置

```powershell
# 立即运行任务
Start-ScheduledTask -TaskName "UFC 文档月度清理"

# 查看任务状态
Get-ScheduledTask -TaskName "UFC 文档月度清理" | Select-Object TaskName, State, LastRunTime, NextRunTime
```

### 查看任务历史日志

```powershell
# 查看最近一次运行结果
Get-ScheduledTaskInfo -TaskName "UFC 文档月度清理"

# 查看任务事件日志（需要启用日志）
Get-WinEvent -FilterHashtable @{
    LogName='Microsoft-Windows-TaskScheduler/Operational'
    Id=100,102,110,111,119,129,130,131,132,133,134,135,136,137,140,141
} | Where-Object {$_.Message -like "*UFC 文档月度清理*"} | Select-Object -First 20
```

## 📊 预期输出

任务执行后将在以下位置生成报告：

1. **健康检查报告**：控制台输出（记录到事件日志）
2. **清理报告**：`D:\TEST7\UFC\docs\清理报告_YYYY-MM-DD.md`
3. **重复文档清单**：`D:\TEST7\UFC\docs\重复文档清单_YYYY-MM-DD.txt`（如有）
4. **归档文档**：`D:\TEST7\UFC\docs\archive\PLAN_History\99_归档库\04_实施报告\`

## ⚙️ 维护与调整

### 修改触发时间

```powershell
# 更新为每月第一个周五 09:00
$task = Get-ScheduledTask -TaskName "UFC 文档月度清理"
$task.Triggers[0].WeeksInterval = 4
Set-ScheduledTask -Task $task
```

### 禁用任务

```powershell
Disable-ScheduledTask -TaskName "UFC 文档月度清理"
```

### 启用任务

```powershell
Enable-ScheduledTask -TaskName "UFC 文档月度清理"
```

### 删除任务

```powershell
Unregister-ScheduledTask -TaskName "UFC 文档月度清理" -Confirm:$false
```

## 🛡️ 安全注意事项

1. **执行策略**：脚本使用 `-ExecutionPolicy Bypass` 绕过执行策略，确保来源可信
2. **权限控制**：使用 `-RunLevel Highest` 以管理员权限运行（如需访问受限目录）
3. **审计日志**：建议启用任务计划程序的详细日志功能
4. **定期审查**：每季度检查一次任务运行记录和生成的报告

## 📞 故障排查

### 问题 1: 任务状态显示「准备就绪」但不运行

**解决方案**：

- 检查账户权限：确保有「登录批处理作业」权限
- 检查密码是否过期：如使用域账户，密码过期会导致任务失败
- 手动运行测试：`Start-ScheduledTask`

### 问题 2: PowerShell 脚本报错

**解决方案**：

- 检查脚本路径是否正确
- 检查 Python 是否已安装并加入 PATH
- 查看事件查看器中的详细错误信息

### 问题 3: 归档文件冲突

**解决方案**：

- 脚本已使用 `-Force` 参数覆盖同名文件
- 如需保留历史版本，可修改脚本添加时间戳后缀

## 📚 相关文档

- [README_文档中心.md](../../README_文档中心.md) - 文档治理总纲
- [check_docs_health.py](../../../tools/check_docs_health.py) - 健康检查引擎
- [cleanup_docs_monthly.ps1](../../../scripts/cleanup_docs_monthly.ps1) - 月度清理脚本

---

**最后更新**: 2026-03-29  
**维护者**: UFC Architecture Team