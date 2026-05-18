## ExternalLibs 域级合同卡（L2_NM）

- **层级**：L2_NM
- **域名**：ExternalLibs / 外部数值库封装
- **缩写**：NM_ExtLib (`NM_ExtLib_*`)
- **职责**：封装 LAPACK/BLAS/ARPACK/MUMPS 等外部数值库；提供统一 Fortran 接口；处理链接与调用约定。
- **四型配置**：
  - **Desc**：外部库句柄 TYPE、错误码映射表。
  - **State**：库初始化标志、工作数组缓存。
  - **Ctx**：无。
  - **Algo**：无自主算法，仅转发调用。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| BLAS | DDOT, DAXPY, DGEMM | Level 1/2/3 BLAS |
| LAPACK | DGETRF, DGETRS, DSYTRD | 稠密矩阵分解 |
| ARPACK | sNaupd, seupd, dNaupd | 特征值求解 |
| MUMPS | mumps_init, mumps_call | 大规模稀疏求解 |

- **依赖**：IF_Precision（数据类型）、IF_Error（错误转换）。
- **热路径**：**是** — BLAS/LAPACK 在矩阵运算中频繁调用。
- **实现锚点**：
  - `NM_ExtLib_BLAS.f90` — BLAS 接口
    ```fortran
    INTERFACE
      FUNCTION DDOT(n, dx, incx, dy, incy) RESULT(dot)
        INTEGER(i4), INTENT(IN) :: n, incx, incy
        REAL(8), INTENT(IN) :: dx(*), dy(*)
        REAL(8) :: dot
        ! 伪代码：dot = SUM(dx(1:n:incx) * dy(1:n:incy))
        ! 优化：使用 SIMD 指令集加速点积
      END FUNCTION DDOT
      
      SUBROUTINE DGEMM(transa, transb, m, n, k, alpha, a, lda, b, ldb, beta, c, ldc)
        CHARACTER, INTENT(IN) :: transa, transb
        INTEGER(i4), INTENT(IN) :: m, n, k, lda, ldb, ldc
        REAL(8), INTENT(IN) :: alpha, beta
        REAL(8), INTENT(IN) :: a(lda,*), b(ldb,*)
        REAL(8), INTENT(INOUT) :: c(ldc,*)
        ! 伪代码：C = alpha*op(A)*op(B) + beta*C
        ! 分块优化：使用 cache blocking 提高命中率
      END SUBROUTINE DGEMM
    END INTERFACE
    ```
  - `NM_ExtLib_LAPACK.f90` — LAPACK 接口
  - `NM_ExtLib_ARPACK.f90` — ARPACK 接口
  - `NM_ExtLib_MUMPS.f90` — MUMPS 接口

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L2_EXTLIB_xxx`（20300–20399） |
| 严重级 | WARNING（库不可用降级）/ ERROR（LAPACK info≠0） |
| 传播规则 | 外部库返回的 `info` / 错误码映射为 UFC `status`；通过 `L1_IF/Error` 统一返回 |
| 恢复策略 | LAPACK `info>0` 返回错误码（奇异/非正定）；`info<0` 为参数错误，返回 ERROR；不 `STOP` |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | External BLAS | E | `DDOT`, `DAXPY`, `DGEMM` 等 Level 1/2/3 接口 |
| 2 | External LAPACK | E | `DGETRF`, `DGETRS`, `DSYTRD` 等稠密分解 |
| 3 | External ARPACK | E | 特征值求解 |
| 4 | External MUMPS | E | 大规模稀疏直接求解 |
| 5 | L2_NM/Solver | S(被消费) | Solver 域调用 LAPACK/BLAS 封装 |
| 6 | L2_NM/Matrix | S(被消费) | Matrix 域调用 BLAS（DGEMM 等） |
| 7 | L1_IF/Precision | U | 精度定义 `wp`, `i4` |
| 8 | L1_IF/Error | U | 错误类型 ErrorStatusType |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 外部库接口严格遵循官方 API 签名 | 硬 | 编译 | P0 |
| 不在封装层添加业务逻辑 | 硬 | Code Review | P0 |
| `USE IF_Prec_Core` 精度统一 | 硬 | 编译 | P0 |
| 链接约定与工具链一致 | 硬 | 构建测试 | P0 |
| ARPACK 特征值为可选依赖 | 软 | `#ifdef` 保护 | P1 |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Contract | 本文 `CONTRACT.md` | Active |
| 2 | Definition/Schema | BLAS/LAPACK 官方 `INTERFACE` 块 | 外部库接口声明 |
| 3 | Desc | 外部库句柄 TYPE、错误码映射表 | 冷路径描述 |
| 4 | State | 库初始化标志、工作数组缓存 | MUMPS 等有状态库 |
| 5 | Algo | — | 无自主算法，仅转发调用 |
| 6 | Ctx | — | 无上下文 |
| 7 | Kernel | `NM_ExtLib_BLAS.f90`, `NM_ExtLib_LAPACK.f90`, `NM_ExtLib_ARPACK.f90`, `NM_ExtLib_MUMPS.f90` | 封装核心 |
| 8 | Bridge | — | 本域为最底层封装 |
| 9 | Proc | — | 无 `_Proc` 入口 |
| 10 | Registry | — | 无注册 |
| 11 | Populate | 库初始化检测 | MUMPS `mumps_init` |
| 12 | Diagnostics | `info` 返回值映射 | LAPACK/BLAS 错误码 |
| 13 | Test | `L2_NM/Tests/` | Deferred |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | BLAS/LAPACK 标准数值库接口：线性代数核心运算的工业标准实现 |
| 逻辑链 | `NM_Solver` / `NM_Matrix` → `NM_ExtLib_*` 封装 → 外部 BLAS/LAPACK/MUMPS 二进制 |
| 计算链 | 热路径（DGEMM/DDOT 在内层循环）；LAPACK 工作区查询最优 `lwork` |
| 数据链 | Desc(冷,句柄/标志) → State(库初始化) → 调用时传入/传出数组指针 |

---

**版本**：v1.0  
**最后更新**：2026-03-23  
**状态**：✅ 已补全


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `ModuleBlas.f90` | `ModuleBlas` | — | `addblk` (SUB,PUB,—); `amask` (SUB,PUB,—); `amub` (SUB,PUB,—); `amubdg` (SUB,PUB,—); `amudia` (SUB,PUB,—); `amux` (SUB,PUB,—); `amuxd` (SUB,PUB,—); `amuxe` (SUB,PUB,—); `amuxj` (SUB,PUB,—); `amuxms` (SUB,PUB,—); `ansym` (SUB,PUB,—); `aplb` (SUB,PUB,—); `aplb1` (SUB,PUB,—); `aplbdg` (SUB,PUB,—); `apldia` (SUB,PUB,—); `aplsb` (SUB,PUB,—); `aplsb1` (SUB,PUB,—); `aplsbt` (SUB,PUB,—); `aplsca` (SUB,PUB,—); `apmbt` (SUB,PUB,—); `atmux` (SUB,PUB,—); `atmuxr` (SUB,PUB,—); `avnz_col` (SUB,PUB,—); `bandpart` (SUB,PUB,—); `bandwidth` (SUB,PUB,—); `blkchk` (SUB,PUB,—); `blkfnd` (SUB,PUB,—); `bndcsr` (SUB,PUB,—); `bsrcsr` (SUB,PUB,—); `clncsr` (SUB,PUB,—); `cnrms` (SUB,PUB,—); `coicsr` (SUB,PUB,—); `coocsr` (SUB,PUB,—); `cooell` (SUB,PUB,—); `copmat` (SUB,PUB,—); `coscal` (SUB,PUB,—); `cperm` (SUB,PUB,—); `csort` (SUB,PUB,—); `csorted` (SUB,PUB,—); `csrbnd` (SUB,PUB,—); `csrbsr` (SUB,PUB,—); `csrcoo` (SUB,PUB,—); `csrcsc` (SUB,PUB,—); `csrcsc2` (SUB,PUB,—); `csrdia` (SUB,PUB,—); `csrdns` (SUB,PUB,—); `csrell` (SUB,PUB,—); `csrjad` (SUB,PUB,—); `csrkvstc` (SUB,PUB,—); `csrkvstr` (SUB,PUB,—); `csrlnk` (SUB,PUB,—); `csrmsr` (SUB,PUB,—); `csrssk` (SUB,PUB,—); `csrssr` (SUB,PUB,—); `csrsss` (SUB,PUB,—); `csruss` (SUB,PUB,—); `csrvbr` (SUB,PUB,—); `daxpy` (SUB,PUB,—); `dcopy` (SUB,PUB,—); `ddot` (FN,PUB,—); `dnrm2` (FN,PUB,—); `dasum` (FN,PUB,—); `idamax` (FN,PUB,—); `dcsort` (SUB,PUB,—); `DGBMV` (SUB,PUB,—); `DGEMM` (SUB,PUB,—); `DGEMV` (SUB,PUB,—); `DGER` (SUB,PUB,—); `diacsr` (SUB,PUB,—); `diag_domi` (SUB,PUB,—); `diamua` (SUB,PUB,—); `diapos` (SUB,PUB,—); `dinfo1` (SUB,PUB,—); `distaij` (SUB,PUB,—); `distdiag` (SUB,PUB,—); `distdot` (FN,PUB,—); `dmperm` (SUB,PUB,—); `dnscsr` (SUB,PUB,—); `dperm` (SUB,PUB,—); `dperm1` (SUB,PUB,—); `dperm2` (SUB,PUB,—); `drot` (SUB,PUB,—); `drotg` (SUB,PUB,—); `dscal` (SUB,PUB,—); `dscaldg` (SUB,PUB,—); `dswap` (SUB,PUB,—); `DSYMV` (SUB,PUB,—); `DSYR` (SUB,PUB,—); `DSYR2` (SUB,PUB,—); `DSYRK` (SUB,PUB,—); `DTBSV` (SUB,PUB,—); `DTRMM` (SUB,PUB,—); `DTRMV` (SUB,PUB,—); `DTRSM` (SUB,PUB,—); `DTRSV` (SUB,PUB,—); `dump` (SUB,PUB,—); `dvperm` (SUB,PUB,—); `ellcsr` (SUB,PUB,—); `extbdg` (SUB,PUB,—); `filter` (SUB,PUB,—); `filterm` (SUB,PUB,—); `frobnorm` (SUB,PUB,—); `get1up` (SUB,PUB,—); `getbwd` (SUB,PUB,—); `getdia` (SUB,PUB,—); `getl` (SUB,PUB,—); `getu` (SUB,PUB,—); `infdia` (SUB,PUB,—); `ivperm` (SUB,PUB,—); `jadcsr` (SUB,PUB,—); `kvstmerge` (SUB,PUB,—); `ldsol` (SUB,PUB,—); `ldsolc` (SUB,PUB,—); `ldsoll` (SUB,PUB,—); `levels` (SUB,PUB,—); `lnkcsr` (SUB,PUB,—); `lsol` (SUB,PUB,—); `lsolc` (SUB,PUB,—); `msrcop` (SUB,PUB,—); `msrcsr` (SUB,PUB,—); `n_imp_diag` (SUB,PUB,—); `nonz` (SUB,PUB,—); `nonz_lud` (SUB,PUB,—); `pltmt` (SUB,PUB,—); `prtmt` (SUB,PUB,—); `prtunf` (SUB,PUB,—); `pspltm` (SUB,PUB,—); `readmt` (SUB,PUB,—); `readsk` (SUB,PUB,—); `readsm` (SUB,PUB,—); `readunf` (SUB,PUB,—); `retmx` (SUB,PUB,—); `rnrms` (SUB,PUB,—); `roscal` (SUB,PUB,—); `rperm` (SUB,PUB,—); `skit` (SUB,PUB,—); `skyline` (SUB,PUB,—); `smms` (SUB,PUB,—); `sskssr` (SUB,PUB,—); `ssrcsr` (SUB,PUB,—); `ssscsr` (SUB,PUB,—); `submat` (SUB,PUB,—); `timestamp` (SUB,PUB,—); `transp` (SUB,PUB,—); `udsol` (SUB,PUB,—); `udsolc` (SUB,PUB,—); `usol` (SUB,PUB,—); `usolc` (SUB,PUB,—); `usscsr` (SUB,PUB,—); `vbrcsr` (SUB,PUB,—); `vbrinfo` (SUB,PUB,—); `vbrmv` (SUB,PUB,—); `xcooell` (SUB,PUB,—); `xssrcsr` (SUB,PUB,—); `xtrows` (SUB,PUB,—) |
| `ModuleIters.f90` | `ModuleIters` | — | `bcg` (SUB,PUB,—); `bcgstab` (SUB,PUB,—); `bisinit` (SUB,PUB,—); `cg` (SUB,PUB,—); `cgnr` (SUB,PUB,—); `dbcg` (SUB,PUB,—); `dqgmres` (SUB,PUB,—); `fgmres` (SUB,PUB,—); `fom` (SUB,PUB,—); `givens` (SUB,PUB,—); `gmres` (SUB,PUB,—); `implu` (SUB,PUB,—); `mgsro` (SUB,PUB,—); `pgmres` (SUB,PUB,—); `SLVRC` (SUB,PUB,—); `tfqmr` (SUB,PUB,—); `tidycg` (SUB,PUB,—); `uppdir` (SUB,PUB,—) |
| `ModuleItsol.f90` | `ModuleItsol` | — | `ilu0` (SUB,PUB,—); `ilud` (SUB,PUB,—); `iludp` (SUB,PUB,—); `iluk` (SUB,PUB,—); `ilut` (SUB,PUB,—); `ilutp` (SUB,PUB,—); `lusol` (SUB,PUB,—); `lutsol` (SUB,PUB,—); `milu0` (SUB,PUB,—); `qsplit` (SUB,PUB,—) |
| `ModuleLapack.f90` | `ModuleLapack` | — | `DGBSV` (SUB,PUB,—); `DGBTF2` (SUB,PUB,—); `DGBTRF` (SUB,PUB,—); `DGBTRS` (SUB,PUB,—); `DGEBAK` (SUB,PUB,—); `DGEBAL` (SUB,PUB,—); `DGEEV` (SUB,PUB,—); `DGEHD2` (SUB,PUB,—); `DGEHRD` (SUB,PUB,—); `DGELQ2` (SUB,PUB,—); `DGELQF` (SUB,PUB,—); `DGELS` (SUB,PUB,—); `DGEQR2` (SUB,PUB,—); `DGEQRF` (SUB,PUB,—); `DGESV` (SUB,PUB,—); `DGETF2` (SUB,PUB,—); `DGETRF` (SUB,PUB,—); `DGETRI` (SUB,PUB,—); `DGETRS` (SUB,PUB,—); `DGGBAK` (SUB,PUB,—); `DGGBAL` (SUB,PUB,—); `DGGEV` (SUB,PUB,—); `DGGHRD` (SUB,PUB,—); `DGTTRF` (SUB,PUB,—); `DGTTRS` (SUB,PUB,—); `DHGEQZ` (SUB,PUB,—); `DHSEQR` (SUB,PUB,—); `DLABAD` (SUB,PUB,—); `DLACON` (SUB,PUB,—); `DLACPY` (SUB,PUB,—); `DLADIV` (SUB,PUB,—); `DLAE2` (SUB,PUB,—); `DLAEBZ` (SUB,PUB,—); `DLAEV2` (SUB,PUB,—); `DLAEXC` (SUB,PUB,—); `DLAG2` (SUB,PUB,—); `DLAGTF` (SUB,PUB,—); `DLAGTM` (SUB,PUB,—); `DLAGTS` (SUB,PUB,—); `DLAHQR` (SUB,PUB,—); `DLAHRD` (SUB,PUB,—); `DLALN2` (SUB,PUB,—); `DLAMCH` (FN,PUB,—); `DLAMC1` (SUB,PUB,—); `DLAMC2` (SUB,PUB,—); `DLAMC3` (FN,PUB,—); `DLAMC4` (SUB,PUB,—); `DLAMC5` (SUB,PUB,—); `DLANGE` (FN,PUB,—); `DLANHS` (FN,PUB,—); `DLANSB` (FN,PUB,—); `DLANST` (FN,PUB,—); `DLANV2` (SUB,PUB,—); `DLAPTM` (SUB,PUB,—); `DLAPY2` (FN,PUB,—); `DLAPY3` (FN,PUB,—); `DLAR2V` (SUB,PUB,—); `DLARAN` (FN,PUB,—); `DLARF` (SUB,PUB,—); `DLARFB` (SUB,PUB,—); `DLARFG` (SUB,PUB,—); `DLARFT` (SUB,PUB,—); `DLARFX` (SUB,PUB,—); `DLARGV` (SUB,PUB,—); `DLARND` (FN,PUB,—); `DLARNV` (SUB,PUB,—); `DLARTG` (SUB,PUB,—); `DLARTV` (SUB,PUB,—); `DLARUV` (SUB,PUB,—); `DLASCL` (SUB,PUB,—); `DLASET` (SUB,PUB,—); `DLASR` (SUB,PUB,—); `DLASRT` (SUB,PUB,—); `DLASSQ` (SUB,PUB,—); `DLASV2` (SUB,PUB,—); `DLASWP` (SUB,PUB,—); `DLASY2` (SUB,PUB,—); `DORG2R` (SUB,PUB,—); `DORGHR` (SUB,PUB,—); `DORGQR` (SUB,PUB,—); `DORM2R` (SUB,PUB,—); `DORML2` (SUB,PUB,—); `DORMLQ` (SUB,PUB,—); `DORMQR` (SUB,PUB,—); `DPBSV` (SUB,PUB,—); `DPBTF2` (SUB,PUB,—); `DPBTRF` (SUB,PUB,—); `DPBTRS` (SUB,PUB,—); `DPOTF2` (SUB,PUB,—); `DPOTRF` (SUB,PUB,—); `DPOTRS` (SUB,PUB,—); `DPTTRF` (SUB,PUB,—); `DPTTRS` (SUB,PUB,—); `DSBEVX` (SUB,PUB,—); `DSBTRD` (SUB,PUB,—); `DSTEBZ` (SUB,PUB,—); `DSTEIN` (SUB,PUB,—); `DSTEQR` (SUB,PUB,—); `DSTERF` (SUB,PUB,—); `DTGEVC` (SUB,PUB,—); `DTPSV` (SUB,PUB,—); `DTPTRS` (SUB,PUB,—); `DTREVC` (SUB,PUB,—); `DTREXC` (SUB,PUB,—); `DTRSEN` (SUB,PUB,—); `DTRSYL` (SUB,PUB,—); `DTRTI2` (SUB,PUB,—); `DTRTRI` (SUB,PUB,—); `DTRTRS` (SUB,PUB,—); `DZSUM1` (FN,PUB,—); `ICMAX1` (FN,PUB,—); `IEEECK` (FN,PUB,—); `ILAENV` (FN,PUB,—); `IZMAX1` (FN,PUB,—); `LSAME` (FN,PUB,—); `LSAMEN` (FN,PUB,—); `XERBLA` (SUB,PUB,—); `XLAENV` (SUB,PUB,—) |
| `SparsePakModule.f90` | `SparsePakModule` | `SparsePakType` | `init` (TBP,PRV,—); `finalize` (TBP,PRV,—); `addcom` (TBP,PRV,—); `adj_env_size` (TBP,PRV,—); `block_shuffle` (TBP,PRV,—); `fnlvls` (TBP,PRV,—); `gennd` (TBP,PRV,—); `rcm` (TBP,PRV,—); `gs_factor` (TBP,PRV,—); `gs_solve` (TBP,PRV,Compute); `qmdmrg` (TBP,PRV,—); `i4_swap` (TBP,PRV,—); `i4vec_reverse` (TBP,PRV,—); `perm_inverse` (TBP,PRV,—); `degree` (TBP,PRV,—); `sparsepak_init` (SUB,PRV,Init); `deallocate_dynamic` (SUB,PRV,—); `sparsepak_finalize` (SUB,PRV,Finalize); `addcom` (SUB,PRV,—); `addrcm` (SUB,PRV,—); `addrhs` (SUB,PRV,—); `addrqt` (SUB,PRV,—); `adj_env_size` (SUB,PRV,—); `adj_print` (SUB,PRV,IO); `adj_set` (SUB,PRV,Mutate); `adj_show` (SUB,PRV,—); `block_shuffle` (SUB,PRV,—); `fnbenv` (SUB,PRV,—); `fntenv` (SUB,PRV,—); `fntadj` (SUB,PRV,—); `fnenv` (SUB,PRV,—); `fnlvls` (SUB,PRV,—); `fndsep` (SUB,PRV,—); `fn1wd` (SUB,PRV,—); `level_set` (SUB,PRV,Mutate); `root_find` (SUB,PRV,Query); `gennd` (SUB,PRV,—); `genqmd` (SUB,PRV,—); `genrcm` (SUB,PRV,—); `genrqt` (SUB,PRV,—); `gen1wd` (SUB,PRV,—); `rcm` (SUB,PRV,—); `rcm_sub` (SUB,PRV,—); `rqtree` (SUB,PRV,—); `gs_factor` (SUB,PRV,—); `es_factor` (SUB,PRV,—); `smb_factor` (SUB,PRV,—); `ts_factor` (SUB,PRV,—); `gs_solve` (SUB,PRV,Compute); `el_solve` (SUB,PRV,Compute); `eu_solve` (SUB,PRV,Compute); `ts_solve` (SUB,PRV,Compute); `qmdmrg` (SUB,PRV,—); `qmdqt` (SUB,PRV,—); `qmdrch` (SUB,PRV,—); `qmdupd` (SUB,PRV,—); `degree` (SUB,PRV,—); `fnofnz` (SUB,PRV,—); `fnspan` (SUB,PRV,—); `reach` (SUB,PRV,—); `i4_swap` (SUB,PRV,—); `i4vec_copy` (SUB,PRV,—); `i4vec_indicator` (SUB,PRV,—); `i4vec_reverse` (SUB,PRV,—); `i4vec_sort_insert_a` (SUB,PRV,Mutate); `perm_inverse` (SUB,PRV,—); `perm_rv` (SUB,PRV,—); `timestamp` (SUB,PRV,—); `str` (FN,PRV,—) |
| `agmg_01_common90.f90` | `hsl_zb01_integer` | `zb01_info` | `delete_files` (SUB,PRV,—); `find_units` (SUB,PRV,—); `read_from_file` (SUB,PRV,—); `write_to_file` (SUB,PRV,—); `zb01_resize1_integer` (SUB,PRV,—); `zb01_resize2_integer` (SUB,PRV,—) |
| `agmg_02_ddeps.f90` | — | — | — |
| `agmg_03_ddeps90.f90` | `HSL_ZD11_double` | `ZD11_type` | `ZD11_put` (SUB,PUB,—); `ZD11_get` (FN,PUB,Query) |
| `agmg_03_ddeps90.f90` | `hsl_zb01_double` | `zb01_info` | `zb01_resize1_double` (SUB,PRV,—); `zb01_resize2_double` (SUB,PRV,—); `write_to_file` (SUB,PRV,—); `find_units` (SUB,PRV,—); `read_from_file` (SUB,PRV,—); `delete_files` (SUB,PRV,—) |
| `agmg_03_ddeps90.f90` | `HSL_MC65_double` | — | `csr_print_message` (SUB,PRV,IO); `csr_matrix_construct` (SUB,PRV,—); `csr_matrix_destruct` (SUB,PRV,—); `csr_matrix_reallocate` (SUB,PRV,—); `csr_matrix_transpose` (SUB,PRV,—); `csr_matrix_transpose_rowsz` (SUB,PRV,—); `csr_matrix_transpose_values` (SUB,PRV,—); `csr_matrix_transpose_pattern` (SUB,PRV,—); `csr_matrix_copy` (SUB,PRV,—); `csr_matrix_clean` (SUB,PRV,—); `csr_matrix_clean_private` (SUB,PRV,—); `csr_matrix_sort` (SUB,PRV,—); `csr_matrix_sum` (SUB,PRV,—); `csr_matrix_sum_getnz` (SUB,PRV,Query); `csr_matrix_sum_values` (SUB,PRV,—); `csr_matrix_sum_graph` (SUB,PRV,—); `csr_matrix_sum_pattern` (SUB,PRV,—); `csr_matrix_symmetrize` (SUB,PRV,—); `csr_matrix_getrow` (SUB,PRV,Query); `csr_matrix_getrowval` (SUB,PRV,Query); `csr_matrix_is_symmetric` (SUB,PRV,Query); `csr_matrix_is_same_pattern` (FN,PRV,Query); `csr_matrix_is_same_values` (FN,PRV,Query); `csr_matrix_diff` (SUB,PRV,—); `csr_matrix_diff_values` (FN,PRV,—); `csr_matrix_multiply` (SUB,PRV,—); `matmul_size` (SUB,PRV,—); `matmul_normal` (SUB,PRV,—); `matmul_noval` (SUB,PRV,—); `csr_matrix_multiply_graph` (SUB,PRV,—); `matmul_size_graph` (SUB,PRV,—); `matmul_graph` (SUB,PRV,—); `matmul_wgraph` (SUB,PRV,—); `csr_matrix_multiply_rvector` (SUB,PRV,—); `csr_matrix_multiply_ivector` (SUB,PRV,—); `csr_to_csr_matrix` (SUB,PRV,—); `coo_to_csr_format` (SUB,PRV,—); `coo_to_csr_private` (SUB,PRV,—); `csr_matrix_to_coo` (SUB,PRV,—); `csr_matrix_to_coo_private` (SUB,PRV,—); `csr_matrix_remove_diagonal` (SUB,PRV,Mutate); `csr_matrix_remove_diag_private` (SUB,PRV,Mutate); `csr_matrix_diagonal_first` (SUB,PRV,—); `csr_matrix_diagonal_first_priv` (SUB,PRV,—); `csr_matrix_write` (SUB,PRV,IO); `CSR_MATRIX_WRITE_ija` (SUB,PRV,IO); `csr_matrix_write_unformatted` (SUB,PRV,IO); `csr_matrix_write_gnuplot` (SUB,PRV,IO); `csr_matrix_write_hypergraph` (SUB,PRV,IO); `csr_matrix_read` (SUB,PRV,Parse); `csr_matrix_condense` (SUB,PRV,—); `csr_matrix_is_pattern` (FN,PRV,Query); `vacant_unit` (FN,PRV,—); `expand1` (SUB,PRV,—); `iexpand1` (SUB,PRV,—); `int2str` (FN,PRV,—); `digit` (FN,PRV,—) |
| `agmg_03_ddeps90.f90` | `hsl_mc69_double` | `dup_list` | `mc69_verify_double` (SUB,PRV,Validate); `mc69_print_double` (SUB,PRV,IO); `digit_format` (FN,PRV,—); `mc69_cscl_clean_double` (SUB,PRV,—); `mc69_cscl_convert_double` (SUB,PRV,Bridge); `mc69_cscl_convert_main` (SUB,PRV,Bridge); `mc69_cscu_convert_double` (SUB,PRV,Bridge); `mc69_csclu_convert_double` (SUB,PRV,Bridge); `mc69_csclu_convert_main` (SUB,PRV,Bridge); `mc69_csrl_convert_double` (SUB,PRV,Bridge); `mc69_csrl_convert_main` (SUB,PRV,Bridge); `mc69_csru_convert_double` (SUB,PRV,Bridge); `mc69_csrlu_convert_double` (SUB,PRV,Bridge); `mc69_coord_convert_double` (SUB,PRV,Bridge); `mc69_set_values_double` (SUB,PRV,Mutate); `mc69_print_flag` (SUB,PRV,IO); `sort` (SUB,PRV,—); `pushdown` (SUB,PRV,—); `cleanup_dup` (SUB,PRV,—) |
| `agmg_03_ddeps90.f90` | `hsl_ma48_ma50_internal_double` | — | `ma50ad` (SUB,PUB,—); `ma50bd` (SUB,PUB,—); `ma50cd` (SUB,PUB,—); `ma50dd` (SUB,PUB,—); `ma50ed` (SUB,PUB,—); `ma50fd` (SUB,PUB,—); `ma50gd` (SUB,PUB,—); `ma50hd` (SUB,PUB,—); `ma50id` (SUB,PUB,—) |
| `agmg_03_ddeps90.f90` | `hsl_ma48_ma48_internal_double` | — | `ma48ad` (SUB,PUB,—); `ma48bd` (SUB,PUB,—); `ma48cd` (SUB,PUB,—); `ma48dd` (SUB,PRV,—); `ma48id` (SUB,PRV,—); `mc21ad` (SUB,PRV,—); `mc21bd` (SUB,PRV,—); `mc13dd` (SUB,PRV,—); `mc13ed` (SUB,PRV,—) |
| `agmg_03_ddeps90.f90` | `hsl_ma48_ma51_internal_double` | — | `ma51ad` (SUB,PUB,—); `ma51bd` (SUB,PUB,—); `ma51cd` (SUB,PUB,—); `ma51dd` (SUB,PRV,—); `ma51xd` (SUB,PRV,—); `ma51yd` (SUB,PRV,—); `ma51zd` (SUB,PRV,—) |
| `agmg_03_ddeps90.f90` | `hsl_ma48_double` | `ma48_factors`, `ma48_control`, `ma48_ainfo`, `ma48_finfo`, `ma48_sinfo` | `ma48_initialize_double` (SUB,PRV,Init); `ma48_analyse_double` (SUB,PRV,—); `ma48_get_perm_double` (SUB,PRV,Query); `ma48_factorize_double` (SUB,PRV,—); `ma48_solve_double` (SUB,PRV,Compute); `ma48_finalize_double` (SUB,PRV,Finalize); `nonzer` (SUB,PRV,—); `ma48_special_rows_and_cols_double` (SUB,PRV,—); `ma48_determinant_double` (SUB,PRV,—) |
| `agmg_03_ddeps90.f90` | `HSL_MI32_DOUBLE` | `MI32_CONTROL`, `MI32_INFO`, `MI32_KEEP` | `MI32_MINRES` (SUB,PUB,—); `MI32_FINALIZE` (SUB,PUB,Finalize) |
| `agmg_04_hsl_mi20d.f90` | — | — | — |
| `agmg_05_hsl_mi20d_ciface.f90` | `hsl_mi20_double_ciface` | `ciface_keep_type` | `copy_control_in` (SUB,PUB,—); `copy_info_out` (SUB,PUB,—); `copy_solve_control_in` (SUB,PUB,Compute); `mi20_default_control_d` (SUB,PUB,—); `mi20_default_solve_control_d` (SUB,PUB,Compute); `mi20_finalize_d` (SUB,PUB,Finalize); `mi20_precondition_d` (SUB,PUB,—); `mi20_setup_coord_d` (SUB,PUB,Init); `mi20_setup_csc_d` (SUB,PUB,Init); `mi20_setup_csr_d` (SUB,PUB,Init); `mi20_setup_d` (SUB,PUB,Init); `mi20_setup_csr_d` (SUB,PUB,Init); `mi20_solve_d` (SUB,PUB,Compute) |
