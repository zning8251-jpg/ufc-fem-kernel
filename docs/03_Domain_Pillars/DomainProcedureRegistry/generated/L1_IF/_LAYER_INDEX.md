# 层级索引：`L1_IF`（Registry）

- **`.f90` 文件数**: 71

> **命名 / 布局**：`generated/<层>/…/<stem>.md` — **目录树镜像** `ufc_core/<层>/…/*.f90`（仅扩展名改为 `.md`）；按 **域桶**（层下首段目录名）分组索引。**stem**=源码文件名；三段式/四段式见各篇首节。**源码路径**见各篇 `Source`。权威约定见 [CONVENTIONS.md](../CONVENTIONS.md) §0、[UFC_命名与数据结构规范.md](../../UFC_命名与数据结构规范.md) §3。

## 域级 `Base`（`ufc_core/L1_IF/Base/…` 一级子目录）

- [IF_AI_Brg.md](Base/AI/IF_AI_Brg.md)
- [IF_AI_Def.md](Base/AI/IF_AI_Def.md)
- [IF_AI_Mgr.md](Base/AI/IF_AI_Mgr.md)
- [IF_AI_ModelLoader.md](Base/AI/IF_AI_ModelLoader.md)
- [IF_AI_Preprocess.md](Base/AI/IF_AI_Preprocess.md)
- [IF_AI_Runtime.md](Base/AI/IF_AI_Runtime.md)
- [IF_AI_TensorOps.md](Base/AI/IF_AI_TensorOps.md)
- [IF_Base_Core.md](Base/IF_Base_Core.md)
- [IF_Base_DP.md](Base/IF_Base_DP.md)
- [IF_Base_Def.md](Base/IF_Base_Def.md)
- [IF_Base_Mgr.md](Base/IF_Base_Mgr.md)
- [IF_Base_StructMeta_Def.md](Base/IF_Base_StructMeta_Def.md)
- [IF_Base_SymTbl.md](Base/IF_Base_SymTbl.md)
- [IF_Base_UnstructMeta_Def.md](Base/IF_Base_UnstructMeta_Def.md)
- [IF_Device_Mgr.md](Base/IF_Device_Mgr.md)
- [IF_Mat_Dispatch_Def.md](Base/IF_Mat_Dispatch_Def.md)
- [IF_Math_Util.md](Base/IF_Math_Util.md)
- [IF_Step_Def.md](Base/IF_Step_Def.md)
- [IF_ThreadWS_Brg.md](Base/Parallel/IF_ThreadWS_Brg.md)
- [IF_ThreadWS_Def.md](Base/Parallel/IF_ThreadWS_Def.md)
- [IF_ThreadWS_Mgr.md](Base/Parallel/IF_ThreadWS_Mgr.md)
- [RT_SolverType_Def.md](Base/RT_SolverType_Def.md)
- [IF_Sym_Brg.md](Base/Symbol/IF_Sym_Brg.md)
- [IF_Sym_Def.md](Base/Symbol/IF_Sym_Def.md)
- [IF_Sym_Mgr.md](Base/Symbol/IF_Sym_Mgr.md)
- [IF_Sym_Stiffness.md](Base/Symbol/IF_Sym_Stiffness.md)
- [IF_Sym_Strain.md](Base/Symbol/IF_Sym_Strain.md)
- [IF_Sym_Stress.md](Base/Symbol/IF_Sym_Stress.md)

## 域级 `Error`（`ufc_core/L1_IF/Error/…` 一级子目录）

- [IF_Err_Brg.md](Error/IF_Err_Brg.md)
- [IF_Err_Chain.md](Error/IF_Err_Chain.md)
- [IF_Err_Core.md](Error/IF_Err_Core.md)
- [IF_Err_Def.md](Error/IF_Err_Def.md)
- [IF_Err_Mgr.md](Error/IF_Err_Mgr.md)
- [IF_Err_Reg.md](Error/IF_Err_Reg.md)

## 域级 `IO`（`ufc_core/L1_IF/IO/…` 一级子目录）

- [IF_IO_Backup.md](IO/Checkpoint/IF_IO_Backup.md)
- [IF_IO_Persist.md](IO/Checkpoint/IF_IO_Persist.md)
- [IF_IO_StructFile.md](IO/Checkpoint/IF_IO_StructFile.md)
- [IF_StructFormat_API.md](IO/Checkpoint/IF_StructFormat_API.md)
- [IF_UnstructFile_Mgr.md](IO/Checkpoint/IF_UnstructFile_Mgr.md)
- [IF_UnstructFormat_API.md](IO/Checkpoint/IF_UnstructFormat_API.md)
- [IF_IO_Core.md](IO/IF_IO_Core.md)
- [IF_IO_Def.md](IO/IF_IO_Def.md)
- [IF_IO_File.md](IO/IF_IO_File.md)
- [IF_IO_Filters.md](IO/IF_IO_Filters.md)
- [IF_IO_Log.md](IO/IF_IO_Log.md)
- [IF_IO_Mgr.md](IO/IF_IO_Mgr.md)
- [IF_IO_Parser.md](IO/IF_IO_Parser.md)
- [IF_IO_Writer.md](IO/IF_IO_Writer.md)

## 域级 `Log`（`ufc_core/L1_IF/Log/…` 一级子目录）

- [IF_Log_Core.md](Log/IF_Log_Core.md)
- [IF_Log_Def.md](Log/IF_Log_Def.md)
- [IF_Log_Logger.md](Log/IF_Log_Logger.md)

## 域级 `Memory`（`ufc_core/L1_IF/Memory/…` 一级子目录）

- [IF_Mem_AI_Pool.md](Memory/IF_Mem_AI_Pool.md)
- [IF_Mem_Chunk.md](Memory/IF_Mem_Chunk.md)
- [IF_Mem_Core.md](Memory/IF_Mem_Core.md)
- [IF_Mem_Def.md](Memory/IF_Mem_Def.md)
- [IF_Mem_Mgr.md](Memory/IF_Mem_Mgr.md)
- [IF_Mem_Serial.md](Memory/IF_Mem_Serial.md)
- [IF_Mem_StructPool.md](Memory/IF_Mem_StructPool.md)
- [IF_Mem_ThreadSlab.md](Memory/IF_Mem_ThreadSlab.md)
- [IF_Mem_UnStructPool.md](Memory/IF_Mem_UnStructPool.md)
- [IF_Mem_WS.md](Memory/IF_Mem_WS.md)

## 域级 `Monitor`（`ufc_core/L1_IF/Monitor/…` 一级子目录）

- [IF_Mon_Core.md](Monitor/IF_Mon_Core.md)
- [IF_Mon_Def.md](Monitor/IF_Mon_Def.md)
- [IF_Mon_Mgr.md](Monitor/IF_Mon_Mgr.md)

## 域级 `Precision`（`ufc_core/L1_IF/Precision/…` 一级子目录）

- [IF_Base_Def.md](Precision/IF_Base_Def.md)
- [IF_Prec_Core.md](Precision/IF_Prec_Core.md)
- [IF_Prec_Def.md](Precision/IF_Prec_Def.md)

## 域级 `Registry`（`ufc_core/L1_IF/Registry/…` 一级子目录）

- [IF_Reg_Core.md](Registry/IF_Reg_Core.md)
- [IF_Reg_Def.md](Registry/IF_Reg_Def.md)
- [IF_Reg_Ops.md](Registry/IF_Reg_Ops.md)

## 域级 `_root`（`ufc_core/L1_IF/_root/…` 一级子目录）

- [IF_L1_Layer.md](_root/IF_L1_Layer.md)
