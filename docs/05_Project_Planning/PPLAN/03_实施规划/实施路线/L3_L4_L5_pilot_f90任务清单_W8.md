# L3/L4/L5 — pilot 任务清单（W8 筛选）

> **生成日期**：2026-04-30  
> **来源**：[`UFC/tools/gen_l3l4l5_f90_inventory.py`](../../../../tools/gen_l3l4l5_f90_inventory.py)  
> **总清单**：[`L3_L4_L5_pilot_f90任务清单.md`](L3_L4_L5_pilot_f90任务清单.md) — **Txxxx 与总清单一致**

> **波次**：W8（内置前缀；W7/W8 与邻波重叠边界以合同及 EXEC §5–§6 为准） **S5 Mesh**：与 **W2** `L3_MD/Mesh/` 可能重叠；以 Mesh 合同划定Populate/单元分界，避免双真源。

## 本波次文件（勾选覆盖）

- [ ] **T0079** `L3_MD/KeyWord/MD_Inp_Parse.f90` （约 33 个子程序）
- [ ] **T0080** `L3_MD/KeyWord/MD_KW.f90` （约 48 个子程序）
- [ ] **T0081** `L3_MD/KeyWord/MD_KWAP_Brg.f90` （约 0 个子程序）
- [ ] **T0082** `L3_MD/KeyWord/MD_KW_Abaqus.f90` （约 6 个子程序）
- [ ] **T0083** `L3_MD/KeyWord/MD_KW_Core.f90` （约 9 个子程序）
- [ ] **T0084** `L3_MD/KeyWord/MD_KW_Def.f90` （约 6 个子程序）
- [ ] **T0085** `L3_MD/KeyWord/MD_KW_Dispatch.f90` （约 4 个子程序）
- [ ] **T0086** `L3_MD/KeyWord/MD_KW_Lexer.f90` （约 13 个子程序）
- [ ] **T0087** `L3_MD/KeyWord/MD_KW_Mapper.f90` （约 246 个子程序）
- [ ] **T0088** `L3_MD/KeyWord/MD_KW_MemPool.f90` （约 11 个子程序）
- [ ] **T0089** `L3_MD/KeyWord/MD_KW_Parser.f90` （约 22 个子程序）
- [ ] **T0090** `L3_MD/KeyWord/MD_KW_Reg.f90` （约 60 个子程序）
- [x] **T0091** ~~`L3_MD/KeyWord/MD_KeyWord.f90`~~ **已删除**：薄再导出并入 `MD_KW.f90` 末尾 `MODULE MD_KW`（避免重复 `MODULE MD_KW` 编译单元）
- [ ] **T0092** `L3_MD/KeyWord/MD_KeyWordParser_Def.f90` （约 3 个子程序）
- [ ] **T0093** `L3_MD/KeyWord/MD_KeyWord_Def.f90` （约 0 个子程序）
- [ ] **T0094** `L3_MD/KeyWord/MD_KeyWord_Domain.f90` （约 10 个子程序）
- [ ] **T0095** `L3_MD/KeyWord/MD_KeyWord_ParserRecursive.f90` （约 33 个子程序）
- [ ] **T0096** `L3_MD/KeyWord/MD_KeyWord_Validator.f90` （约 4 个子程序）
- [ ] **T0366** `L3_MD/Model/MD_BaseTypes.f90` （约 2 个子程序）
- [ ] **T0367** `L3_MD/Model/MD_Base_DataModMgr.f90` （约 52 个子程序）
- [ ] **T0368** `L3_MD/Model/MD_Base_Def.f90` （约 3 个子程序）
- [ ] **T0369** `L3_MD/Model/MD_Base_ElemLib.f90` （约 3 个子程序）
- [ ] **T0370** `L3_MD/Model/MD_Base_Enums.f90` （约 1 个子程序）
- [ ] **T0371** `L3_MD/Model/MD_Base_FieldVarMgr.f90` （约 27 个子程序）
- [ ] **T0372** `L3_MD/Model/MD_Base_IOSerialMgr.f90` （约 0 个子程序）
- [ ] **T0373** `L3_MD/Model/MD_Base_MathUtils.f90` （约 129 个子程序）
- [ ] **T0374** `L3_MD/Model/MD_Base_ObjModel.f90` （约 254 个子程序）
- [ ] **T0375** `L3_MD/Model/MD_Base_TreeIndex.f90` （约 0 个子程序）
- [ ] **T0376** `L3_MD/Model/MD_Kinematics_Def.f90` （约 0 个子程序）
- [ ] **T0377** `L3_MD/Model/MD_Model_Access.f90` （约 4 个子程序）
- [ ] **T0378** `L3_MD/Model/MD_Model_Builder.f90` （约 2 个子程序）
- [ ] **T0379** `L3_MD/Model/MD_Model_CoordSys.f90` （约 53 个子程序）
- [ ] **T0380** `L3_MD/Model/MD_Model_Core.f90` （约 10 个子程序）
- [ ] **T0381** `L3_MD/Model/MD_Model_Data.f90` （约 70 个子程序）
- [ ] **T0382** `L3_MD/Model/MD_Model_Def.f90` （约 0 个子程序）
- [ ] **T0383** `L3_MD/Model/MD_Model_DomBrg.f90` （约 0 个子程序）
- [ ] **T0384** `L3_MD/Model/MD_Model_Domain.f90` （约 27 个子程序）
- [ ] **T0385** `L3_MD/Model/MD_Model_Lib.f90` （约 86 个子程序）
- [ ] **T0386** `L3_MD/Model/MD_Model_Mgr.f90` （约 27 个子程序）
- [ ] **T0387** `L3_MD/Model/MD_Model_Tree.f90` （约 13 个子程序）
- [ ] **T0388** `L3_MD/Model/MD_Model_Types.f90` （约 0 个子程序）
- [ ] **T0404** `L3_MD/Part/MD_Geom_Def.f90` （约 1 个子程序）
- [ ] **T0405** `L3_MD/Part/MD_Part_Brg.f90` （约 2 个子程序）
- [ ] **T0406** `L3_MD/Part/MD_Part_Core.f90` （约 9 个子程序）
- [ ] **T0407** `L3_MD/Part/MD_Part_Def.f90` （约 3 个子程序）
- [ ] **T0408** `L3_MD/Part/MD_Part_Mgr.f90` （约 2 个子程序）
- [ ] **T0409** `L3_MD/Part/MD_Part_Sync.f90` （约 4 个子程序）
- [ ] **T0410** `L3_MD/Part/MD_Sets_Def.f90` （约 0 个子程序）
- [ ] **T0411** `L3_MD/Part/MD_Sets_Mgr.f90` （约 10 个子程序）
- [ ] **T0412** `L3_MD/Section/MD_Sect_Brg.f90` （约 1 个子程序）
- [ ] **T0413** `L3_MD/Section/MD_Sect_Compat.f90` （约 4 个子程序）
- [ ] **T0414** `L3_MD/Section/MD_Sect_Core.f90` （约 8 个子程序）
- [ ] **T0415** `L3_MD/Section/MD_Sect_Def.f90` （约 23 个子程序）
- [ ] **T0416** `L3_MD/Section/MD_Sect_Domain.f90` （约 0 个子程序）
- [ ] **T0417** `L3_MD/Section/MD_Sect_Lib.f90` （约 19 个子程序）
- [ ] **T0418** `L3_MD/Section/MD_Sect_Mgr.f90` （约 101 个子程序）
- [ ] **T0419** `L3_MD/Section/MD_Sect_PropMass.f90` （约 19 个子程序）
- [ ] **T0420** `L3_MD/Section/MD_Sect_PropNonStructMass.f90` （约 17 个子程序）
- [ ] **T0421** `L3_MD/Section/MD_Sect_PropPtMass.f90` （约 19 个子程序）
- [ ] **T0422** `L3_MD/Section/MD_Sect_PropRotInertia.f90` （约 21 个子程序）
- [ ] **T0423** `L3_MD/Section/MD_Sect_ionSync.f90` （约 4 个子程序）
- [ ] **T0813** `L5_RT/Logging/RT_Log_Brg.f90` （约 4 个子程序）
- [ ] **T0814** `L5_RT/Logging/RT_Log_Core.f90` （约 8 个子程序）
- [ ] **T0815** `L5_RT/Logging/RT_Log_Def.f90` （约 0 个子程序）
- [ ] **T0816** `L5_RT/Logging/RT_Log_Sys.f90` （约 10 个子程序）

**合计**：65 个 `.f90`，约 1560 个子程序。
