!===============================================================================
! MODULE: MD_Int_ContactArgs
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Contact argument bundles
! BRIEF:  Arg-bundle TYPEs for MD_Int contact entry points (DEP-001 exemption).
!===============================================================================

MODULE MD_Int_ContactArgs
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Model_Lib_Core, ONLY: UF_Model
  USE RT_Solv_Def, ONLY: RT_Sol_DofMap
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_IC_ContactAddK_Arg
  PUBLIC :: MD_IC_ContactAddForce_Arg
  PUBLIC :: MD_IC_ContactAssemTriplets_Arg
  PUBLIC :: MD_IC_ContactInit_Arg
  PUBLIC :: MD_IC_ContactUpdateGeom_Arg
  PUBLIC :: MD_IC_ContactEvalFace_Arg

  !---------------------------------------------------------------------------
  ! TYPE: MD_IC_ContactAddK_Arg
  ! KIND: Arg
  ! DESC: Equation IDs, penalty/scale, and normal for contact stiffness.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_IC_ContactAddK_Arg
    INTEGER(i4) :: eqRow(3), eqCol(3)
    REAL(wp)    :: penalty, scale
    REAL(wp)    :: nrm(3)
  END TYPE MD_IC_ContactAddK_Arg

  !---------------------------------------------------------------------------
  ! TYPE: MD_IC_ContactAddForce_Arg
  ! KIND: Arg
  ! DESC: Equation IDs and force vector for contact force contribution.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_IC_ContactAddForce_Arg
    INTEGER(i4) :: eq(3)
    REAL(wp)    :: f(3)
  END TYPE MD_IC_ContactAddForce_Arg

  !---------------------------------------------------------------------------
  ! TYPE: MD_IC_ContactAssemTriplets_Arg
  ! KIND: Arg
  ! DESC: Model + DOF-map pointers for contact triplet assembly.
  !---------------------------------------------------------------------------
  ! Pointers: caller must keep model/dofMap targets alive for wrapper duration
  TYPE, PUBLIC :: MD_IC_ContactAssemTriplets_Arg
    TYPE(UF_Model), POINTER :: model => NULL()
    TYPE(RT_Sol_DofMap), POINTER :: dofMap => NULL()
  END TYPE MD_IC_ContactAssemTriplets_Arg

  !---------------------------------------------------------------------------
  ! TYPE: MD_IC_ContactInit_Arg
  ! KIND: Arg
  ! DESC: Master/slave IDs, contact type, dimension, tolerance.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_IC_ContactInit_Arg
    INTEGER(i4) :: master_id = 0_i4
    INTEGER(i4) :: slave_id  = 0_i4
    INTEGER(i4) :: contact_type = 1_i4   !! CONTACT_NODE_TO (see MD_Int)
    INTEGER(i4) :: dimension  = 3_i4
    REAL(wp)    :: tol         = 1.0E-6_wp
    !! search_tol < 0: contact_init uses 0.1*tol (same as omitting search_tol)
    REAL(wp)    :: search_tol  = -1.0_wp
  END TYPE MD_IC_ContactInit_Arg

  !---------------------------------------------------------------------------
  ! TYPE: MD_IC_ContactUpdateGeom_Arg
  ! KIND: Arg
  ! DESC: DOF count for geometry update wrapper.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_IC_ContactUpdateGeom_Arg
    INTEGER(i4) :: ndof = 0_i4  !! if <=0, wrapper uses SIZE(disp)
  END TYPE MD_IC_ContactUpdateGeom_Arg

  !---------------------------------------------------------------------------
  ! TYPE: MD_IC_ContactEvalFace_Arg
  ! KIND: Arg
  ! DESC: Face evaluation inputs/outputs (slave point, best gap/normal).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_IC_ContactEvalFace_Arg
    INTEGER(i4) :: elemId = 0_i4
    INTEGER(i4) :: faceId = 0_i4
    REAL(wp)    :: xSlave(3) = 0.0_wp
    REAL(wp)    :: bestGap = 0.0_wp
    INTEGER(i4) :: bestElemId = 0_i4
    INTEGER(i4) :: bestFaceId = 0_i4
    REAL(wp)    :: bestNrm(3) = 0.0_wp
    REAL(wp)    :: bestX0(3) = 0.0_wp
  END TYPE MD_IC_ContactEvalFace_Arg

END MODULE MD_Int_ContactArgs
