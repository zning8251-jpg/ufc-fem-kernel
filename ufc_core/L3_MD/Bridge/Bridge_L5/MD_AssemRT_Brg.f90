!===============================================================================
! MODULE: MD_AssemRT_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — **Sparse linear algebra** re-export (L3_MD → L5 RT_Solv_Sparse)
! BRIEF:  **不是** L3 `MD_Assembly_Domain`（部件实例/集合/面）到 L5 的装配体金线。
!         本模块仅转发 **RT_TripletList / RT_CSRMatrix** 的 Init/Add/Free/FromTriplet/SpMV，
!         供需在 L3 侧组稀疏试算、又避免在 MD 层直接广域 USE L5 的场合。
! 数据链（真实 H3 闭环，勿与本文件混淆）：
!   1) **L3 实例域**：`UF_AssemblyDef` → **`MD_Assembly_SyncFromLegacy`** →
!      `g_ufc_global%md_layer%assembly`（`MD_Asm_Mgr` / `MD_Assembly_Domain`）。金线序见
!      `MD_Model_Brg`（`MD_Assembly_SyncFromLegacy` 在 LoadBC 之后、Constraint 之前）。
!   2) **L4 Populate**：`PH_L4_Populate_*` 不经过本文件；接触/面名等经 L3 assembly API
!      与 `MD_Assembly_Get*ByName_Idx` 等对拍（见 `PH_L4_Populate_Contact` 等）。
!   3) **L5 全局 K/F 装配**：**`RT_Asm_Solv`**（hub）、**`RT_Asm_Brg`**（Desc/DOF/桥接 ctx）、
!      **`g_ufc_global%rt_layer%assembly`**（`RT_Asm_Domain` CSR 状态）；与 **`RT_Asm_Def`**
!      四型对齐 pilot。
! Pilot:   ufc-layer-l3-l4-l5-pilot.md — 本文件不负责辅 TYPE 嵌套，仅 **薄转发** 避免重复
!          实现；L5 热路径仍走 `RT_Solv_Sparse` 本主实现。
!===============================================================================

MODULE MD_AssemRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Solv_Sparse, ONLY: RT_TripletList, RT_Triplet_Init, RT_Triplet_Add, &
                                  RT_Triplet_Free, RT_CSR_FromTriplet, RT_CSR_SpMV
  USE RT_Solv_Def, ONLY: RT_CSRMatrix, RT_CSR_Free
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! Export RT layer types for L3_MD use (type aliases)
  !=============================================================================
  
  !> @brief TripletList and CSRMatrix type aliases (re-exported from RT layer)
  ! Bridge module exports RT layer types directly for L3_MD use
  ! This avoids wrapper overhead while maintaining dependency isolation
  PUBLIC :: RT_TripletList, RT_CSRMatrix
  
  !=============================================================================
  ! Bridge function interfaces (maintain same signature as RT layer)
  !=============================================================================
  
  PUBLIC :: MD_RT_Assem_CSRFree
  PUBLIC :: MD_RT_Assem_CSRFromTriplet
  PUBLIC :: MD_RT_Assem_CSRSpMV
  PUBLIC :: MD_RT_Assem_TripletAdd
  PUBLIC :: MD_RT_Assem_TripletFree
  PUBLIC :: MD_RT_Assem_TripletInit

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Assem_CSRFree
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Free CSR matrix (bridge to L5_RT)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Assem_CSRFree(csr_matrix)
    TYPE(RT_CSRMatrix), INTENT(INOUT) :: csr_matrix

    ! Bridge: Direct call to L5_RT function (same signature)
    CALL RT_CSR_Free(csr_matrix)

  END SUBROUTINE MD_RT_Assem_CSRFree

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Assem_CSRFromTriplet
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Convert triplet to CSR format (bridge to L5_RT)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Assem_CSRFromTriplet(triplets, nrows, ncols, csr_matrix)
    TYPE(RT_TripletList), INTENT(IN) :: triplets
    INTEGER(i4), INTENT(IN) :: nrows, ncols
    TYPE(RT_CSRMatrix), INTENT(OUT) :: csr_matrix

    ! Bridge: Direct call to L5_RT function (same signature)
    CALL RT_CSR_FromTriplet(triplets, nrows, ncols, csr_matrix)

  END SUBROUTINE MD_RT_Assem_CSRFromTriplet

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Assem_CSRSpMV
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Sparse matrix-vector multiply (bridge to L5_RT)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Assem_CSRSpMV(csr_matrix, x, y)
    TYPE(RT_CSRMatrix), INTENT(IN) :: csr_matrix
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)

    ! Bridge: Direct call to L5_RT function (same signature)
    CALL RT_CSR_SpMV(csr_matrix, x, y)

  END SUBROUTINE MD_RT_Assem_CSRSpMV

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Assem_TripletAdd
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Add triplet to sparse matrix (bridge to L5_RT)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Assem_TripletAdd(triplets, row, col, val)
    TYPE(RT_TripletList), INTENT(INOUT) :: triplets
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: val

    ! Bridge: Direct call to L5_RT function (same signature)
    CALL RT_Triplet_Add(triplets, row, col, val)

  END SUBROUTINE MD_RT_Assem_TripletAdd

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Assem_TripletFree
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Free triplet list (bridge to L5_RT)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Assem_TripletFree(triplets)
    TYPE(RT_TripletList), INTENT(INOUT) :: triplets

    ! Bridge: Direct call to L5_RT function (same signature)
    CALL RT_Triplet_Free(triplets)

  END SUBROUTINE MD_RT_Assem_TripletFree

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Assem_TripletInit
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Initialize triplet list (bridge to L5_RT)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Assem_TripletInit(triplets, estimated_nnz)
    TYPE(RT_TripletList), INTENT(OUT) :: triplets
    INTEGER(i4), INTENT(IN), OPTIONAL :: estimated_nnz

    ! Bridge: Direct call to L5_RT function (same signature)
    IF (PRESENT(estimated_nnz)) THEN
      CALL RT_Triplet_Init(triplets, estimated_nnz)
    ELSE
      CALL RT_Triplet_Init(triplets)
    END IF

  END SUBROUTINE MD_RT_Assem_TripletInit

END MODULE MD_AssemRT_Brg
