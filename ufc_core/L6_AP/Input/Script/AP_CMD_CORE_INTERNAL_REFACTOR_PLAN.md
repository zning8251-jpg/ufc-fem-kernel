# AP_Cmd_Core 内部功能模块重组计划

> **目标**: 将 4070 行单体模块按职责拆分为多个子模块，实现功能内聚、接口清晰  
> **日期**: 2026-03-10  
> **依据**: L6_AP_DOMAIN_REDESIGN_PLAN、单职责原则

---

## 一、现状分析

### 1.1 AP_Cmd_Core 合并的功能块（模块头注释）

```
Merged: Parser, Registry, Executor, ParamSubst, Validator,
        History, Help, Debug, Logger, Alias, Label, Procedure
```

### 1.2 功能块与子程序映射

| 功能块 | 类型/子程序 | 行数估计 | 依赖 |
|--------|-------------|----------|------|
| **Logger** | CmdLogger, Log_Init, Log_Log, Log_LogError, Log_SetLevel, Cmd_Log*, g_logger | ~120 | IF_Prec_Core, IF_Err |
| **Debug** | CmdDebugger, Debug_Init, Debug_SetBreakpoint, Debug_CheckBreakpoint, Cmd_Debug* | ~80 | IF_Prec_Core, IF_Err |
| **History** | CmdHistory, Hist_Init, Hist_Add, Hist_Get, Hist_Clear, Cmd_History* | ~150 | Cmd, HistoryEntry |
| **Alias** | CmdAliasMgr, Alias_Init, Alias_Define, Alias_Resolve, Cmd_Alias* | ~180 | Cmd |
| **Label** | CmdLabelMgr, Label_Init, Label_Reg, Label_Resolve, Cmd_Label* | ~150 | Cmd, CmdList |
| **Procedure** | CmdProcMgr, Proc_Init, Proc_Define, Proc_Load, Proc_Save, Proc_Exec | ~250 | Cmd, CmdList |
| **Help** | Cmd_HelpShow, Cmd_HelpSearch | ~50 | g_cmd_domain |
| **Validator** | Cmd_Valid, Cmd_FormatError | ~50 | Cmd |
| **Parser** | Cmd_ParseLine, Cmd_ParseFile, Cmd_ParseString, Cmd_ExpandMacros | ~250 | Cmd, CmdList |
| **Registry** | CmdReg, Reg_Init, Reg_Reg, Reg_Find, Reg_Exec | ~150 | Cmd, CmdHandler |
| **Executor** | CmdExec, Exec_Exec, Exec_ExecList, Cmd_ExecList, EvaluateCondition | ~450 | CmdReg, CmdHistory, CmdLogger... |
| **ParamSubst** | Cmd_Subst, Cmd_SetVar, Cmd_GetVar | ~250 | Cmd, CmdCtx |

### 1.3 依赖关系（简化）

```
AP_Cmd_Type (Cmd, CmdCtx, CmdList, CmdHandler, HistoryEntry)
     ↑
AP_Cmd_Domain_Core (AP_Cmd_Domain)
     ↑
AP_Cmd_Logger ←── 独立，仅 IF_Prec_Core, IF_Err
AP_Cmd_Debug  ←── 独立
AP_Cmd_History ←── 依赖 Cmd, HistoryEntry
AP_Cmd_Alias   ←── 依赖 Cmd
AP_Cmd_Label   ←── 依赖 Cmd, CmdList
AP_Cmd_Proc    ←── 依赖 Cmd, CmdList
AP_Cmd_Help    ←── 依赖 CmdReg (g_cmd_domain)
AP_Cmd_Valid   ←── 依赖 Cmd
AP_Cmd_Parser  ←── 依赖 Cmd, CmdList
AP_Cmd_Registry←── 依赖 Cmd, CmdHandler
AP_Cmd_Subst   ←── 依赖 Cmd, CmdCtx
AP_Cmd_Executor←── 依赖 上述多数
     ↑
AP_Cmd_Core (Facade: 保留公开接口，内部委托)
```

---

## 二、拆分策略

### 2.1 原则

1. **自底向上**：先提取无/少依赖模块（Logger, Debug），再提取有依赖模块
2. **保持接口**：AP_Cmd_Core 保留 public 子程序名，内部改为调用新模块
3. **全局变量**：g_logger, g_debugger 等迁至各自模块，AP_Cmd_Core 重导出

### 2.2 新模块清单

| 新模块 | 路径 | 职责 |
|--------|------|------|
| AP_Cmd_Logger | Input/Script/AP_Cmd_Logger.f90 | 命令日志 |
| AP_Cmd_Debug | Input/Script/AP_Cmd_Debug.f90 | 命令调试 |
| AP_Cmd_History | Input/Script/AP_Cmd_History.f90 | 命令历史 |
| AP_Cmd_Alias | Input/Script/AP_Cmd_Alias.f90 | 命令别名 |
| AP_Cmd_Label | Input/Script/AP_Cmd_Label.f90 | 标签管理 |
| AP_Cmd_Proc | Input/Script/AP_Cmd_Proc.f90 | 过程定义 |
| AP_Cmd_Help | Input/Script/AP_Cmd_Help.f90 | 帮助 |
| AP_Cmd_Valid | Input/Script/AP_Cmd_Valid.f90 | 校验 |
| AP_Cmd_Parser | Input/Script/AP_Cmd_Parser.f90 | 解析 |
| AP_Cmd_Registry | Input/Script/AP_Cmd_Registry.f90 | 注册表 |
| AP_Cmd_Subst | Input/Script/AP_Cmd_Subst.f90 | 参数替换 |
| AP_Cmd_Executor | Input/Script/AP_Cmd_Executor.f90 | 执行器 |

### 2.3 AP_Cmd_Core 最终形态

- 保留：公开接口声明、Structured I/O 类型、Facade 实现
- 删除：各功能块内部实现
- 依赖：USE 上述 12 个新模块 + AP_Cmd_Type, AP_Cmd_Domain_Core

---

## 三、实施阶段

### Phase 1: Logger 提取 ✅ 已完成
- 创建 AP_Cmd_Logger.f90
- 迁移 CmdLogger, g_logger, Log_*, Cmd_Log*, 相关 In/Out 类型
- AP_Cmd_Core: USE AP_Cmd_Logger, 删除 Logger 代码
- AP_Cmd_API: USE AP_Cmd_Logger, ONLY: g_logger

### Phase 2: Debug 提取 ✅ 已完成
- 创建 AP_Cmd_Debug.f90
- 迁移 CmdDebugger, g_debugger, Debug_*, Cmd_Debug*

### Phase 3: History 提取 ✅ 已完成
- 创建 AP_Cmd_History.f90
- 迁移 CmdHistory, g_cmd_history, Hist_*, Cmd_History*

### Phase 4: Alias 提取 ✅ 已完成
- 创建 AP_Cmd_Alias.f90

### Phase 5: Label 提取 ✅ 已完成
- 创建 AP_Cmd_Label.f90
- Label_Reg 通过 procedure pointer (get_cmd) 接收 CmdList_GetCmd，避免循环依赖

### Phase 6: Procedure 提取 ✅ 已完成
- 创建 AP_Cmd_Proc.f90
- Proc_Define 通过 procedure pointer (get_cmd) 接收 CmdList_GetCmd
- Proc_Load、Proc_Exec 依赖 AP_Cmd_Core (Cmd_ParseLine, g_cmd_domain, Cmd_Exec, Cmd_Subst)
- AP_Cmd_Proc USE AP_Cmd_Core，无循环依赖

### Phase 7: Help, Validator 提取
- 创建 AP_Cmd_Help.f90, AP_Cmd_Valid.f90

### Phase 8: Parser, Registry, Subst, Executor 提取
- 创建剩余 4 个模块

---

## 四、迁移执行记录（2026-03-10）

### 已完成

| Phase | 模块 | 状态 |
|-------|------|------|
| 1 | AP_Cmd_Logger | ✅ |
| 2 | AP_Cmd_Debug | ✅ |
| 3 | AP_Cmd_History | ✅ |
| 4 | AP_Cmd_Alias | ✅ |
| 5 | AP_Cmd_Label | ✅ |
| 6 | AP_Cmd_Proc | ✅ |

### 待执行

| Phase | 模块 |
|-------|------|
| 7 | AP_Cmd_Help, AP_Cmd_Valid |
| 8 | AP_Cmd_Parser, AP_Cmd_Registry, AP_Cmd_Subst, AP_Cmd_Executor |

---

*文档版本：1.1 | 日期：2026-03-10*
