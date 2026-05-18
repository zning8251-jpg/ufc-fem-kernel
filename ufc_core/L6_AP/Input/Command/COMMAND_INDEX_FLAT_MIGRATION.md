# Command 域「索引树 + 扁平域」迁移方案

> **目标**：按统一域核心（Types/Core/Mgr/Brg/API/Parse）与「索引树 + 扁平域」方案，迁移重构 Command 域，消除双轨制。
> **依据**：INPUT_INDEX_FLAT_MIGRATION.md、WRITEBACK_INDEX_FLAT_MIGRATION.md、OUTPUT_INDEX_FLAT_MIGRATION.md。

---

## 〇、统一域核心结构（目标）

| 后缀 | 职责 | 文件 |
|------|------|------|
| **_Types** | 类型定义（Cmd、CmdCtx、CmdHandler、HistoryEntry） | AP_Cmd_Type |
| **_Domain_Core** | 数据结构与操作（扁平存储 commands、handlers、history） | AP_Cmd_Domain_Core |
| **_Mgr** | 集合管理、查询、校验（委托 Domain） | AP_Cmd_Mgr |
| **_Brg** | 桥接（MD_Brg/PH_Brg/RT_Brg/AP_Brg） | AP_Cmd_KW_Brg |
| **_API** | 类型接口 | AP_Cmd_API |
| **_Parse** | 命令解析/校验 | AP_Cmd_Core 内 Cmd_ParseLine |

---

## 〇、双轨制现状

### 0.1 存储双轨

| 路径 | 存储 | 用途 |
|------|------|------|
| **g_reg** (CmdReg) | handlers(:) | 命令注册表（name→handler） |
| **g_history** (CmdHistory) | entries(:) | 命令执行历史 |
| **CmdList** | cmds(:) | 解析后的命令队列（按会话传递） |
| **AP_Input_Domain** | parsed_commands(:) | 解析命令（与 CmdList 重叠） |
| **g_alias_mgr** | aliases(:) | 别名定义 |
| **g_label_mgr** | labels(:) | 标签索引 |
| **g_proc_mgr** | procs(:) | 过程定义 |

### 0.2 桥接双轨

| 接口 | 数据源 | 调用方 |
|------|--------|--------|
| Cmd_Reg / Cmd_Find | g_reg | AP_Cmd_Core |
| Cmd_HistoryAdd / Cmd_HistoryGet | g_history | AP_Cmd_Core |
| CmdList%cmds | 调用方分配 | Cmd_ParseFile、Cmd_ExecList |
| AP_Input_Domain%AddParsedCommand | AP_Input_Domain | 解析流水线（待打通） |

### 0.3 问题

- 命令队列双份：CmdList%cmds 与 AP_Input_Domain%parsed_commands 并存
- 全局单例：g_reg、g_history 等分散，无统一 Domain 容器
- 无索引树：cmd_id、handler_id 未建立 (domain_id, entity_idx) 映射
- CmdList 按值传递，非 Domain 单源

---

## 一、索引树 + 扁平域（目标架构）

```
┌─────────────────────────────────────────────────────────────┐
│  Model（结构层，只存索引）                                    │
│  - cmd_queue_ids(:)  ← 命令队列索引，指向 Domain              │
│  - handler_ids(:)    ← 注册表索引                            │
│  - history_ids(:)    ← 历史条目索引                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 通过 index 查找
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  AP_Cmd_Domain（存储层，扁平）                                │
│  - commands(:)   ← 命令队列，按 id 索引，单份                │
│  - handlers(:)   ← 注册表，按 id 索引                        │
│  - history(:)    ← 历史条目，按 id 索引                      │
│  - n_commands, n_handlers, n_history                        │
│  - 单份数据，O(1) 查询                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 二、迁移执行清单

### Phase A：索引树 ✓

- [x] AP_Cmd_Domain_Core 定义 AP_Cmd_Domain（commands(:)、handlers(:)、history(:)）
- [x] AP_Cmd_Domain_Core 增加 AddCommand、AddHandler、AddHistory、GetCommandById、GetHandlerById、GetHandlerByName、GetHistoryById
- [x] cmd_id、handler_id 作为 Domain 内 slot 索引

### Phase B：扁平域单源 ✓

- [x] AP_Cmd_Domain_Core 作为 L6 唯一命令队列/注册表/历史存储
- [x] AP_Cmd_Mgr：Init、Finalize、AddCommand、AddHandler、AddHistory、GetCommand、GetHandler、GetHandlerByName、GetHistory（委托 Domain）
- [x] CmdList 改为 Domain 的视图：CmdList 仅存 cmd_ids(:)，通过 CmdList_GetCmd 按需取 Cmd

### Phase C：消除双轨 ✓

- [x] g_reg 迁移至 g_cmd_domain（AP_Cmd_Domain）
- [x] g_history 迁移至 g_cmd_domain%history(:)
- [x] CmdList%cmds 废弃，改为 CmdList%cmd_ids(:) + CmdList_GetCmd
- [x] AP_Input_Domain parsed_commands 与 AP_Cmd_Domain commands 统一：AP_Input_Mgr_AddCommand 先写入 g_cmd_domain，再写入 Input domain（cmd_id 由 Command 分配）

### Phase D：Types 统一

- [x] Cmd 与 ParsedCommandEntry 字段对齐（ParsedCommandEntry 新增 id/line 规范字段，保留 cmd_id/line_number 作为 @deprecated 别名）
- [x] CommandDesc 与 CmdMetadata 合并（CommandDesc 吸收 parameters/examples 字段，成为超集；CmdMetadata 标记 @deprecated）

---

## 三、调用链（目标）

```
L6_AP 启动
  → AP_Cmd_Mgr%Init(domain)
  → domain%Init → 分配 commands(:)、handlers(:)、history(:)

L6_AP 注册命令
  → AP_Cmd_Mgr%Register(domain, name, handler, desc)
  → domain%AddHandler(...)

L6_AP 解析/执行
  → Cmd_ParseLine → Cmd
  → AP_Cmd_Mgr%AddCommand(domain, cmd)  → domain%commands(n)
  → Cmd_Exec → Mgr%GetCommand(domain, cmd_id) → 执行
  → AP_Cmd_Mgr%AddHistory(domain, cmd, source)

L6_AP 历史查询
  → AP_Cmd_Mgr%GetHistory(domain, idx) → domain%history(idx)
```

---

## 四、依赖关系与文件布局

| 模块 | 文件 | 依赖 |
|------|------|------|
| AP_Cmd_Type | L6_AP/Input/Command/AP_Cmd_Type.f90 | IF_Prec_Core, IF_Err_API |
| AP_Cmd_Domain_Core | L6_AP/Input/Command/AP_Cmd_Domain_Core.f90 | AP_Cmd_Type |
| AP_Cmd_Mgr | L6_AP/Input/Command/AP_Cmd_Mgr.f90 | AP_Cmd_Domain_Core |
| AP_Cmd_Core | L6_AP/Input/Script/AP_Cmd_Core.f90 | AP_Cmd_Type, AP_Cmd_Domain_Core（迁移后） |
| AP_Cmd_KW_Brg | L6_AP/Input/Parser/AP_Cmd_KW_Brg.f90 | AP_Cmd_Type, AP_Brg_L3 |

---

## 五、与 Input 域关系

| 域 | 职责 |
|----|------|
| **Input** | 解析状态、关键字队列（parsed_keywords、parsed_commands 轻量） |
| **Command** | 命令注册表、命令队列（Cmd 完整）、执行历史 |

- **统一策略**：AP_Input_Domain parsed_commands 与 AP_Cmd_Domain commands 可共享：解析阶段写入 Input，执行阶段 Command Domain 为权威。或 Input 仅存 keyword 级，Command 存 Cmd 级。
- **推荐**：Command Domain 为命令队列单源；Input Domain parsed_commands 可废弃或作为 Command 的轻量索引。

---

*文档版本：1.0 | 日期：2026-03-09*
