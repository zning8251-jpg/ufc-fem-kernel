!===============================================================================
! Module: MD_MatCMPLaminate
! Layer:  L3_MD - Model Description Layer
! Domain: Material - CMP (Classical Lamination Theory, mat_id=112)
! Purpose: Descriptor type and input validation for laminate elastic material.
!
! Props layout (props(1..8+n_plies)):
!   props(1) = E1    : longitudinal Young's modulus
!   props(2) = E2    : transverse Young's modulus
!   props(3) = nu12  : major Poisson's ratio
!   props(4) = G12   : in-plane shear modulus
!   props(5) = G13   : out-of-plane shear modulus 13
!   props(6) = G23   : out-of-plane shear modulus 23
!   props(7) = n_ply : number of plies (cast to INTEGER)
!   props(8) = t_ply : single ply thickness (m)
!   props(9..8+n_ply) = ply_angle(k) in degrees (optional, default 0 deg)
!
! nProps_min = 8
! **W1**：**Laminate_MatDesc** 扩展 **MD_Mat_Desc**；**props** 与 **Populate** / **`desc%props`** 金线一致（**112**）。
!===============================================================================
MODULE MD_Mat_Composite_Laminate
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MD_MAT_ID_112
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: Laminate_MatDesc
  PUBLIC :: UF_Laminate_L3_ValidateProps
  PUBLIC :: UF_Laminate_L3_InitFromProps

  INTEGER(i4), PARAMETER :: MD_MAT_NPROPS_MIN_LAMINATE = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LEAF_112 = MD_MAT_ID_112

  !> L3 descriptor for classical lamination theory (CLT) material
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Laminate_MatDesc
    REAL(wp) :: E1    = 0.0_wp       ! Fiber-direction Young's modulus
    REAL(wp) :: E2    = 0.0_wp       ! Transverse Young's modulus
    REAL(wp) :: nu12  = 0.0_wp       ! Major Poisson's ratio
    REAL(wp) :: G12   = 0.0_wp       ! In-plane shear modulus
    REAL(wp) :: G13   = 0.0_wp       ! Interlaminar shear modulus 13
    REAL(wp) :: G23   = 0.0_wp       ! Interlaminar shear modulus 23
    INTEGER(i4) :: n_ply = 1_i4      ! Number of plies
    REAL(wp)    :: t_ply = 1.0e-3_wp ! Single ply thickness (m)
    REAL(wp), ALLOCATABLE :: ply_angles(:) ! Ply fibre angles (degrees)
    LOGICAL :: is_initialized = .FALSE.
  END TYPE Laminate_MatDesc

CONTAINS

  !----------------------------------------------------------------------------
  ! UF_Laminate_L3_ValidateProps
  !   Validates flat props array before constructing a Laminate_MatDesc.
  !   props(1)=E1, (2)=E2, (3)=nu12, (4)=G12, (5)=G13, (6)=G23,
  !   (7)=n_ply, (8)=t_ply, (9..8+n_ply)=angles (optional).
  !----------------------------------------------------------------------------
  SUBROUTINE UF_Laminate_L3_ValidateProps(nprops, props, st)
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    INTEGER(i4) :: n_ply
    CALL init_error_status(st)
    IF (nprops < MD_MAT_NPROPS_MIN_LAMINATE) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: need >=8 props (E1,E2,nu12,G12,G13,G23,n_ply,t_ply)"
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: E1 must be > 0"
      RETURN
    END IF
    IF (props(2) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: E2 must be > 0"
      RETURN
    END IF
    IF (props(3) <= -1.0_wp .OR. props(3) >= 1.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: nu12 must be in (-1,1)"
      RETURN
    END IF
    IF (props(4) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: G12 must be > 0"
      RETURN
    END IF
    IF (props(5) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: G13 must be > 0"
      RETURN
    END IF
    IF (props(6) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: G23 must be > 0"
      RETURN
    END IF
    n_ply = INT(props(7))
    IF (n_ply <= 0) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: n_ply must be >= 1"
      RETURN
    END IF
    IF (props(8) <= 0.0_wp) THEN
      st%status_code = MD_MAT_STATUS_INVALID
      st%message = "Laminate: t_ply must be > 0"
      RETURN
    END IF
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Laminate_L3_ValidateProps

  !----------------------------------------------------------------------------
  ! UF_Laminate_L3_InitFromProps
  !   Unpacks flat props array into a Laminate_MatDesc instance.
  !----------------------------------------------------------------------------
  SUBROUTINE UF_Laminate_L3_InitFromProps(desc, nprops, props, st)
    TYPE(Laminate_MatDesc), INTENT(OUT) :: desc
    INTEGER(i4), INTENT(IN)  :: nprops
    REAL(wp),    INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    INTEGER(i4) :: k, n_ply
    CALL UF_Laminate_L3_ValidateProps(nprops, props, st)
    IF (st%status_code /= MD_MAT_STATUS_OK) RETURN
    desc%E1    = props(1)
    desc%E2    = props(2)
    desc%nu12  = props(3)
    desc%G12   = props(4)
    desc%G13   = props(5)
    desc%G23   = props(6)
    n_ply      = INT(props(7))
    desc%n_ply = n_ply
    desc%t_ply = props(8)
    IF (ALLOCATED(desc%ply_angles)) DEALLOCATE(desc%ply_angles)
    ALLOCATE(desc%ply_angles(n_ply))
    desc%ply_angles = 0.0_wp
    DO k = 1, n_ply
      IF (8 + k <= nprops) desc%ply_angles(k) = props(8 + k)
    END DO
    desc%pop%nProps = nprops
    desc%pop%nProps = nprops
    desc%is_initialized = .TRUE.
    st%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Laminate_L3_InitFromProps

END MODULE MD_Mat_Composite_Laminate

