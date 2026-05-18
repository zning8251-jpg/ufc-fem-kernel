# Fortran编码规范

> **文档位置**：`六层架构拆分/05-工程规范/06-01-Fortran编码规范.md`  
> **来源章节**：原文档第43章43.1节  
> **最后更新**：2026-02-17  
> **相关文档**：[测试策略](06-02-测试策略.md)、[性能优化](06-03-性能优化.md)

---

## 文件组织与命名策略

### 模块组织结构

- MODULE/: XX_Core.f90(核心库), XX_Types.f90(类型), XX_Impl.f90(实现)
- TEST/: test_XX_unit.f90(单元测试), test_data/(测试数据)
- DOC/: design.md(设计), api.md(API)
- CMAKE/: CMakeLists.txt(编译配置)

### 命名规范

- 类型: TYPE :: MD_Material_VonMises (前缀_主题_特征)
- 子程序: SUBROUTINE MD_VonMises_Update_Stress(...)
- 变量: REAL(8) :: sigma_voigt(6) ! Voigt形式
- 不用i,j,k作循环变量, 每个INTENT需明确

## 缩进、注释、风格

- 缩进: 2空格(不用Tab)
- 行长: 120字符
- 注释: "为什么"解释每行目的
- IMPLICIT NONE强制, PRIVATE默认私有

---

## 相关文档

- [测试策略](06-02-测试策略.md)
- [性能优化](06-03-性能优化.md)
- [质量检查清单](06-05-质量检查清单.md)
