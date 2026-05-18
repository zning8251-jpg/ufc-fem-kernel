!===============================================================================
! MODULE: PH_Elem_Coupler
! LAYER:  L4_PH
! DOMAIN: Element/Special
! ROLE:   Brg
! BRIEF:  Coupler element for kinematic coupling between reference and
!===============================================================================
MODULE PH_Elem_Coupler
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID

  IMPLICIT NONE
  PRIVATE

  !===========================================================================
  ! PARAMETERS
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_COUPLER_MAX_NDOF = 12_i4  ! 2-node coupler: 6+6
  REAL(wp),    PARAMETER :: DEFAULT_PENALTY = 1.0E+10_wp

  !===========================================================================
  ! PUBLIC INTERFACES — Standard 6-subroutine set
  !===========================================================================
  PUBLIC :: PH_Elem_Coupler_Init
  PUBLIC :: PH_Elem_Coupler_Compute_Stiffness
  PUBLIC :: PH_Elem_Coupler_Compute_Mass
  PUBLIC :: PH_Elem_Coupler_Compute_InternalForce
  PUBLIC :: PH_Elem_Coupler_Update_State
  PUBLIC :: PH_Elem_Coupler_Finalize

  !===========================================================================
  ! TYPE: PH_Coupler_Desc — Coupler descriptor
  !===========================================================================
  TYPE, PUBLIC :: PH_Coupler_Desc
    INTEGER(i4) :: n_nodes      = 2_i4      ! Reference + coupling node
    INTEGER(i4) :: n_dof        = 12_i4     ! 6 DOF per node × 2
    INTEGER(i4) :: coupling_type = 1_i4     ! 1=kinematic, 2=distributing
    REAL(wp)    :: penalty      = DEFAULT_PENALTY  ! Penalty stiffness
    REAL(wp)    :: weights(6)   = 1.0_wp    ! DOF weights (u,v,w,rx,ry,rz)
  END TYPE PH_Coupler_Desc

  !===========================================================================
  ! TYPE: PH_Coupler_Ctx — Coupler runtime context
  !===========================================================================
  TYPE, PUBLIC :: PH_Coupler_Ctx
    LOGICAL     :: initialized = .FALSE.
    REAL(wp)    :: u_local(12)  = 0.0_wp    ! Local displacement vector
    REAL(wp)    :: f_int(12)    = 0.0_wp    ! Internal force vector
  END TYPE PH_Coupler_Ctx

CONTAINS

  !===========================================================================
  ! Subroutine: PH_Elem_Coupler_Init
  ! Purpose:    Initialize coupler element context
  !===========================================================================
  SUBROUTINE PH_Elem_Coupler_Init(elem_desc, elem_ctx, ierr)
    TYPE(PH_Coupler_Desc), INTENT(IN)    :: elem_desc  ! [IN]  Coupler descriptor
    TYPE(PH_Coupler_Ctx),  INTENT(OUT)   :: elem_ctx   ! [OUT] Initialized context
    INTEGER(i4),           INTENT(OUT)   :: ierr        ! [OUT] Error code (0=OK)

    ierr = 0_i4
    elem_ctx%initialized = .TRUE.
    elem_ctx%u_local     = 0.0_wp
    elem_ctx%f_int       = 0.0_wp

  END SUBROUTINE PH_Elem_Coupler_Init

  !===========================================================================
  ! Subroutine: PH_Elem_Coupler_Compute_Stiffness
  ! Purpose:    Compute coupler stiffness matrix Ke
  !             Ke = penalty * [W -W; -W W]  (12×12)
  !             W = diag(weights) for DOF selection
  !===========================================================================
  SUBROUTINE PH_Elem_Coupler_Compute_Stiffness(elem_desc, elem_ctx, Ke, ierr)
    TYPE(PH_Coupler_Desc), INTENT(IN)    :: elem_desc  ! [IN]  Descriptor
    TYPE(PH_Coupler_Ctx),  INTENT(IN)    :: elem_ctx   ! [IN]  Context
    REAL(wp),              INTENT(OUT)   :: Ke(:,:)    ! [OUT] Stiffness [ndof,ndof]
    INTEGER(i4),           INTENT(OUT)   :: ierr        ! [OUT] Error code

    INTEGER(i4) :: i, ndof
    REAL(wp) :: pen, w

    ierr = 0_i4
    ndof = elem_desc%pop%n_dof
    pen  = elem_desc%penalty

    IF (SIZE(Ke,1) < ndof .OR. SIZE(Ke,2) < ndof) THEN
      ierr = -1_i4
      RETURN
    END IF

    Ke = 0.0_wp

    ! Build penalty coupling: K = pen * [W -W; -W W]
    ! W is diagonal with per-DOF weights
    DO i = 1, 6
      w = elem_desc%weights(i) * pen
      ! Upper-left block (ref-ref): +W
      Ke(i, i)       = Ke(i, i)       + w
      ! Upper-right block (ref-coupling): -W
      Ke(i, i + 6)   = Ke(i, i + 6)   - w
      ! Lower-left block (coupling-ref): -W
      Ke(i + 6, i)   = Ke(i + 6, i)   - w
      ! Lower-right block (coupling-coupling): +W
      Ke(i + 6, i + 6) = Ke(i + 6, i + 6) + w
    END DO

  END SUBROUTINE PH_Elem_Coupler_Compute_Stiffness

  !===========================================================================
  ! Subroutine: PH_Elem_Coupler_Compute_Mass
  ! Purpose:    Compute coupler mass matrix (zero — massless coupling)
  !===========================================================================
  SUBROUTINE PH_Elem_Coupler_Compute_Mass(elem_desc, elem_ctx, Me, ierr)
    TYPE(PH_Coupler_Desc), INTENT(IN)    :: elem_desc  ! [IN]  Descriptor
    TYPE(PH_Coupler_Ctx),  INTENT(IN)    :: elem_ctx   ! [IN]  Context
    REAL(wp),              INTENT(OUT)   :: Me(:,:)    ! [OUT] Mass matrix
    INTEGER(i4),           INTENT(OUT)   :: ierr        ! [OUT] Error code

    ierr = 0_i4
    Me = 0.0_wp  ! Coupler is massless

  END SUBROUTINE PH_Elem_Coupler_Compute_Mass

  !===========================================================================
  ! Subroutine: PH_Elem_Coupler_Compute_InternalForce
  ! Purpose:    Compute internal force f_int = Ke * u_local
  !===========================================================================
  SUBROUTINE PH_Elem_Coupler_Compute_InternalForce(elem_desc, elem_ctx, fe, ierr)
    TYPE(PH_Coupler_Desc), INTENT(IN)    :: elem_desc  ! [IN]  Descriptor
    TYPE(PH_Coupler_Ctx),  INTENT(INOUT) :: elem_ctx   ! [INOUT] Context (reads u_local)
    REAL(wp),              INTENT(OUT)   :: fe(:)      ! [OUT] Internal force [ndof]
    INTEGER(i4),           INTENT(OUT)   :: ierr        ! [OUT] Error code

    INTEGER(i4) :: i
    REAL(wp) :: pen, w, du

    ierr = 0_i4
    fe = 0.0_wp
    pen = elem_desc%penalty

    ! f_int = Ke * u_local  (Ke is the penalty coupling matrix)
    DO i = 1, 6
      w = elem_desc%weights(i) * pen
      du = elem_ctx%u_local(i) - elem_ctx%u_local(i + 6)  ! u_ref - u_coupling
      fe(i)     =  w * du
      fe(i + 6) = -w * du
    END DO

    elem_ctx%f_int = fe(1:12)

  END SUBROUTINE PH_Elem_Coupler_Compute_InternalForce

  !===========================================================================
  ! Subroutine: PH_Elem_Coupler_Update_State
  ! Purpose:    Update coupler state with new displacement
  !===========================================================================
  SUBROUTINE PH_Elem_Coupler_Update_State(elem_desc, elem_ctx, u_local, ierr)
    TYPE(PH_Coupler_Desc), INTENT(IN)    :: elem_desc  ! [IN]  Descriptor
    TYPE(PH_Coupler_Ctx),  INTENT(INOUT) :: elem_ctx   ! [INOUT] Context
    REAL(wp),              INTENT(IN)    :: u_local(:)  ! [IN]  Local displacements
    INTEGER(i4),           INTENT(OUT)   :: ierr        ! [OUT] Error code

    INTEGER(i4) :: ndof

    ierr = 0_i4
    ndof = MIN(elem_desc%pop%n_dof, 12)

    elem_ctx%u_local(1:ndof) = u_local(1:ndof)

  END SUBROUTINE PH_Elem_Coupler_Update_State

  !===========================================================================
  ! Subroutine: PH_Elem_Coupler_Finalize
  ! Purpose:    Finalize coupler element context (cleanup)
  !===========================================================================
  SUBROUTINE PH_Elem_Coupler_Finalize(elem_ctx, ierr)
    TYPE(PH_Coupler_Ctx), INTENT(INOUT) :: elem_ctx  ! [INOUT] Context
    INTEGER(i4),          INTENT(OUT)   :: ierr       ! [OUT] Error code

    ierr = 0_i4
    elem_ctx%initialized = .FALSE.
    elem_ctx%u_local     = 0.0_wp
    elem_ctx%f_int       = 0.0_wp

  END SUBROUTINE PH_Elem_Coupler_Finalize

END MODULE PH_Elem_Coupler
