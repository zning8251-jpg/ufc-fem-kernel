# 第 14 件：Extension (第三方沙盒屏障件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/02_第14件_Extension_沙盒屏障件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 14 件  
> **目标**：为 UMAT、VUMAT、UEL 等不可控的第三方/用户自定义子程序提供安全隔离沙盒。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **阻断错误污染**：第三方代码可能存在数组越界、除零异常或未初始化内存。沙盒必须在调用前后执行检验，保护 UFC 核心刚度矩阵和残差力免受 `NaN` 或 `Infinity` 污染。
2. **标准降维适配**：将 UFC 高度结构化的 `_Desc`、`_State` 类型，平整化（Flatten）降维为传统的 ABAQUS 一维数组签名（如 `PROPS`, `STATEV`, `DDSDDE`）。

### 1.2 架构红线 (Red Lines)
- **绝对隔离**：核心物理计算模块（如 `L4_PH`）内部绝对禁止出现 `CALL UMAT`。调用必须发生在独立的 `_Ext.f90` 中。
- **NaN 熔断机制**：从扩展模块返回的每一次数据（应力、雅可比），必须通过 `IEEE_IS_NAN` 检疫，发现异常必须转换为标准错误码 `status /= 0`，向上冒泡。

---

## 2. 核心架构时序与机制

1. **[L4_PH 准备]**：抽取当前积分点的应变增量（`DSTRAN`）、前序应力（`STRESS`）、状态变量（`STATEV`）。
2. **[Ext_Enter]**：进入 `_Ext.f90`，将内部结构体翻译为外部参数列表。
3. **[Ext_Invoke]**：调用第三方 `UMAT/UEL`，此时 UFC 失去控制权。
4. **[Ext_Check]**：第三方返回控制权。`_Ext.f90` 立即对返回的 `STRESS` 和 `DDSDDE` 遍历检查 `NaN` 或超大浮点数。
5. **[Ext_Exit]**：若检查通过，打包写回 `_State`；若不通过，丢弃脏数据，设置 `status = UMAT_NAN_ERROR` 并返回。

---

## 3. 伪代码模板与合同定义

```fortran
!=============================================================================
! MODULE: MD_MatUser_Ext
! 描述: 材料域用户子程序 (UMAT) 沙盒隔离屏障
!=============================================================================
MODULE MD_MatUser_Ext
    USE IEEE_ARITHMETIC, ONLY: IEEE_IS_NAN
    ! USE MD_Mat_Def (引用材料四型定义)
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: MD_Mat_UMAT_Sandbox

    ! 外部 UMAT 签名接口
    INTERFACE
        SUBROUTINE UMAT(STRESS, STATEV, DDSDDE, SSE, SPD, SCD, &
                        RPL, DDSDDT, DRPLDE, DRPLDT, &
                        STRAN, DSTRAN, TIME, DTIME, TEMP, DTEMP, &
                        PREDEF, DPRED, CMNAME, NDI, NSHR, NTENS, &
                        NSTATV, PROPS, NPROPS, COORDS, DROT, PNEWDT, &
                        CELENT, DFGRD0, DFGRD1, NOEL, NPT, LAYER, &
                        KSPT, KSTEP, KINC)
            ! ... 传统参数声明 ...
        END SUBROUTINE UMAT
    END INTERFACE

CONTAINS

    !> 包装并隔离 UMAT 的沙盒接口
    SUBROUTINE MD_Mat_UMAT_Sandbox(desc, state, algo, ctx, args, status)
        ! 传入标准的 UFC 五参/六参
        ! ...
        INTEGER, INTENT(OUT) :: status
        
        ! 本地适配变量 (用于向 UMAT 降维)
        REAL*8 :: STRESS(6), STATEV(100), DDSDDE(6,6), STRAN(6), DSTRAN(6), PROPS(50)
        ! ... 其他变量映射 ...
        INTEGER :: i, j

        ! 1. 进站准备 (Pack)
        ! 将 desc%props 拷贝至 PROPS，state%stress 拷贝至 STRESS...
        STRESS = state%stress_vector
        STRAN  = state%strain_vector
        ! ...

        ! 2. 移交控制权 (Invoke)
        CALL UMAT(STRESS, STATEV, DDSDDE, ...)
        
        ! 3. 检疫阶段 (Check & Quarantine) - 红线强制要求
        DO i = 1, 6
            IF (IEEE_IS_NAN(STRESS(i))) THEN
                status = 901 ! ERROR_CODE: UMAT_STRESS_NAN
                RETURN       ! 立即熔断，丢弃结果
            END IF
            DO j = 1, 6
                IF (IEEE_IS_NAN(DDSDDE(i, j))) THEN
                    status = 902 ! ERROR_CODE: UMAT_JACOBIAN_NAN
                    RETURN
                END IF
            END DO
        END DO

        ! 4. 出站写回 (Unpack)
        state%stress_vector = STRESS
        ctx%jacobian_matrix = DDSDDE
        ! ...

        status = 0
    END SUBROUTINE MD_Mat_UMAT_Sandbox

END MODULE MD_MatUser_Ext
```

---

## 4. 合同检验点 (Checklist)
1. 检查调用第三方程序的模块，是否带有 `_Ext` 或 `_User` 后缀，且没有混在主核计算中。
2. 检查 `IEEE_IS_NAN` 是否覆盖了**所有**第三方传出的浮点数矩阵与向量。
3. 检查当发现 NaN 或错误时，程序是否使用了 `RETURN` 将控制权和错误码交还，而不是直接使用 `STOP` 杀死进程（不允许第三方破坏 L5 的步长折半自适应能力）。
