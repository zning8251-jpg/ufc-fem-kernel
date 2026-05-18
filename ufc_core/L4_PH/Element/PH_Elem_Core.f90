!===============================================================================
! MODULE: PH_Elem_Core
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Core
! BRIEF:  Core Ke/Me/Fe computation entry — hot-path element kernels.
!         [SIO Phase 3C] Signatures use Arg TYPEs from PH_Elem_Def.
! **W2**：**Ke/Me/Fe** 热路径；形函数/Gauss 自 **`PH_Elem_Desc`/槽** 真源；签名统一 **`PH_Elem_Def`** SIO **Arg**。
!===============================================================================
MODULE PH_Elem_Core
  USE IF_Prec_Core,           ONLY: wp, i4
  USE IF_Err_Brg,        ONLY: ErrorStatusType, init_error_status, &
                               IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Elem_Def,       ONLY: PH_Elem_Desc, PH_Elem_State, PH_Elem_Ctx, &
                               PH_Elem_Algo, &
                               PH_Elem_Core_Ke_Arg, PH_Elem_Core_Fe_Arg, &
                               PH_Elem_Core_Fint_Arg, PH_Elem_Core_Mass_Arg
  USE PH_Elem_ShapeFunc,   ONLY: PH_Elem_ShapeFunc_Ctx, ComputeShapeFunc, &
                               ComputeJacobian, ComputeStrainDisplacementMatrix
  USE PH_Elem_GaussInt,    ONLY: PH_Elem_GaussInt_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Elem_Core_Init
  PUBLIC :: PH_Elem_Core_Compute_Ke
  PUBLIC :: PH_Elem_Core_Compute_Fe
  PUBLIC :: PH_Elem_Core_Compute_Fint
  PUBLIC :: PH_Elem_Core_Compute_Mass
  PUBLIC :: PH_Elem_Core_Finalize
  PUBLIC :: PH_Elem_Core_Get_NDof
  PUBLIC :: PH_Elem_Core_Get_NNodes

  !--- SECTION 2: MODULE CONSTANTS ---
  INTEGER(i4), PARAMETER :: PH_ELEM_NSTRS_3D = 6_i4
  INTEGER(i4), PARAMETER :: PH_ELEM_NSTRS_2D = 3_i4

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Core_Init
  ! PHASE:      P0
  ! PURPOSE:    Allocate element context workspace from config.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Core_Init(config, state, ctx, status)
    TYPE(PH_Elem_Desc),   INTENT(IN)    :: config
    TYPE(PH_Elem_State),   INTENT(OUT)   :: state
    TYPE(PH_Elem_Ctx),  INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: ndof

    CALL init_error_status(status)

    ndof = config%pop%n_dof
    IF (ndof <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Elem_Core_Init]: n_dof must be > 0"
      RETURN
    END IF

    IF (ASSOCIATED(ctx%lcl%u_elem))  DEALLOCATE(ctx%lcl%u_elem)
    IF (ASSOCIATED(ctx%lcl%du_elem)) DEALLOCATE(ctx%lcl%du_elem)
    IF (ASSOCIATED(ctx%evo%Ke))      DEALLOCATE(ctx%evo%Ke)
    IF (ASSOCIATED(ctx%evo%R_int))   DEALLOCATE(ctx%evo%R_int)
    IF (ASSOCIATED(ctx%lcl%dN_dX))   DEALLOCATE(ctx%lcl%dN_dX)
    IF (ASSOCIATED(ctx%lcl%J_mat))   DEALLOCATE(ctx%lcl%J_mat)

    ALLOCATE(ctx%lcl%u_elem(ndof))
    ALLOCATE(ctx%lcl%du_elem(ndof))
    ALLOCATE(ctx%evo%Ke(ndof, ndof))
    ALLOCATE(ctx%evo%R_int(ndof))
    ALLOCATE(ctx%lcl%dN_dX(config%cfg%ndim, config%pop%n_nodes))
    ALLOCATE(ctx%lcl%J_mat(config%cfg%ndim, config%cfg%ndim))

    ctx%lcl%u_elem  = 0.0_wp
    ctx%lcl%du_elem = 0.0_wp
    ctx%evo%Ke      = 0.0_wp
    ctx%evo%R_int   = 0.0_wp
    ctx%lcl%dN_dX   = 0.0_wp
    ctx%lcl%J_mat   = 0.0_wp

    state%initialized     = .TRUE.
    state%stiffness_built = .FALSE.
    state%current_step    = 0

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Core_Init

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Core_Compute_Ke
  ! PHASE:      P2
  ! PURPOSE:    Stiffness Ke = SUM_gp [ w * det(J) * B^T * D * B ].
  ! SIO:        (config, ctx, arg, status) — arg = PH_Elem_Core_Ke_Arg
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Core_Compute_Ke(config, ctx, arg, status)
    TYPE(PH_Elem_Desc),        INTENT(IN)    :: config
    TYPE(PH_Elem_Ctx),         INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Core_Ke_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    TYPE(PH_Elem_GaussInt_Desc)      :: gauss
    TYPE(PH_Elem_ShapeFunc_Ctx) :: sf
    INTEGER(i4) :: igp, i, j, k, ndof, nstrs, int_order
    REAL(wp)    :: wdetJ
    REAL(wp), ALLOCATABLE :: B(:,:), DB(:,:)

    CALL init_error_status(status)

    ndof = config%pop%n_dof
    ! Allocate output if needed
    IF (.NOT. ALLOCATED(arg%Ke)) ALLOCATE(arg%Ke(ndof, ndof))
    arg%Ke = 0.0_wp

    IF (config%cfg%ndim == 3) THEN
      nstrs = PH_ELEM_NSTRS_3D
    ELSE
      nstrs = PH_ELEM_NSTRS_2D
    END IF

    int_order = PH_Elem_Core_GaussOrder(config%cfg%family_id)

    SELECT CASE(config%cfg%ndim)
      CASE(3)
        CALL gauss%Init3D(int_order)
      CASE(2)
        CALL gauss%Init2D(int_order)
      CASE DEFAULT
        status%status_code = IF_STATUS_INVALID
        status%message = "[PH_Elem_Core_Compute_Ke]: unsupported ndim"
        RETURN
    END SELECT

    ALLOCATE(B(nstrs, ndof), DB(nstrs, ndof))

    DO igp = 1, gauss%n_points
      CALL ComputeShapeFunc(config%cfg%family_id, gauss%xi(igp,:), sf)
      CALL ComputeJacobian(sf, arg%coords)

      wdetJ = gauss%w(igp) * sf%detJ

      CALL ComputeStrainDisplacementMatrix(sf, ndof, B)

      DO j = 1, ndof
        DO i = 1, nstrs
          DB(i,j) = 0.0_wp
          DO k = 1, nstrs
            DB(i,j) = DB(i,j) + arg%D_mat(i,k) * B(k,j)
          END DO
        END DO
      END DO

      DO j = 1, ndof
        DO i = 1, ndof
          DO k = 1, nstrs
            arg%Ke(i,j) = arg%Ke(i,j) + wdetJ * B(k,i) * DB(k,j)
          END DO
        END DO
      END DO
    END DO

    DEALLOCATE(B, DB)
    IF (ALLOCATED(gauss%xi)) DEALLOCATE(gauss%xi)
    IF (ALLOCATED(gauss%w))  DEALLOCATE(gauss%w)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Core_Compute_Ke

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Core_Compute_Fe
  ! PHASE:      P2
  ! PURPOSE:    Body force Fe = SUM_gp [ w * det(J) * N^T * b ].
  ! SIO:        (config, ctx, arg, status) — arg = PH_Elem_Core_Fe_Arg
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Core_Compute_Fe(config, ctx, arg, status)
    TYPE(PH_Elem_Desc),        INTENT(IN)    :: config
    TYPE(PH_Elem_Ctx),         INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Core_Fe_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),      INTENT(OUT)   :: status

    TYPE(PH_Elem_GaussInt_Desc)      :: gauss
    TYPE(PH_Elem_ShapeFunc_Ctx) :: sf
    INTEGER(i4) :: igp, inode, idof, ndim, int_order
    REAL(wp)    :: wdetJ

    CALL init_error_status(status)

    ndim = config%cfg%ndim
    ! Allocate output if needed
    IF (.NOT. ALLOCATED(arg%Fe)) ALLOCATE(arg%Fe(config%pop%n_dof))
    arg%Fe = 0.0_wp

    int_order = PH_Elem_Core_GaussOrder(config%cfg%family_id)

    SELECT CASE(ndim)
      CASE(3)
        CALL gauss%Init3D(int_order)
      CASE(2)
        CALL gauss%Init2D(int_order)
      CASE DEFAULT
        status%status_code = IF_STATUS_INVALID
        status%message = "[PH_Elem_Core_Compute_Fe]: unsupported ndim"
        RETURN
    END SELECT

    DO igp = 1, gauss%n_points
      CALL ComputeShapeFunc(config%cfg%family_id, gauss%xi(igp,:), sf)
      CALL ComputeJacobian(sf, arg%coords)

      wdetJ = gauss%w(igp) * sf%detJ

      DO inode = 1, config%pop%n_nodes
        DO idof = 1, ndim
          arg%Fe((inode-1)*ndim + idof) = arg%Fe((inode-1)*ndim + idof) &
            + wdetJ * sf%N(inode) * arg%body_force(idof)
        END DO
      END DO
    END DO

    IF (ALLOCATED(gauss%xi)) DEALLOCATE(gauss%xi)
    IF (ALLOCATED(gauss%w))  DEALLOCATE(gauss%w)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Core_Compute_Fe

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Core_Compute_Fint
  ! PHASE:      P2
  ! PURPOSE:    Internal force Fint = SUM_gp [ w * det(J) * B^T * sigma ].
  ! SIO:        (config, ctx, arg, status) — arg = PH_Elem_Core_Fint_Arg
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Core_Compute_Fint(config, ctx, arg, status)
    TYPE(PH_Elem_Desc),          INTENT(IN)    :: config
    TYPE(PH_Elem_Ctx),           INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Core_Fint_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    TYPE(PH_Elem_GaussInt_Desc)      :: gauss
    TYPE(PH_Elem_ShapeFunc_Ctx) :: sf
    INTEGER(i4) :: igp, i, k, ndof, nstrs, int_order
    REAL(wp)    :: wdetJ
    REAL(wp), ALLOCATABLE :: B(:,:)

    CALL init_error_status(status)

    ndof = config%pop%n_dof
    ! Allocate output if needed
    IF (.NOT. ALLOCATED(arg%Fint)) ALLOCATE(arg%Fint(ndof))
    arg%Fint = 0.0_wp

    IF (config%cfg%ndim == 3) THEN
      nstrs = PH_ELEM_NSTRS_3D
    ELSE
      nstrs = PH_ELEM_NSTRS_2D
    END IF

    int_order = PH_Elem_Core_GaussOrder(config%cfg%family_id)

    SELECT CASE(config%cfg%ndim)
      CASE(3)
        CALL gauss%Init3D(int_order)
      CASE(2)
        CALL gauss%Init2D(int_order)
      CASE DEFAULT
        status%status_code = IF_STATUS_INVALID
        status%message = "[PH_Elem_Core_Compute_Fint]: unsupported ndim"
        RETURN
    END SELECT

    ALLOCATE(B(nstrs, ndof))

    DO igp = 1, gauss%n_points
      CALL ComputeShapeFunc(config%cfg%family_id, gauss%xi(igp,:), sf)
      CALL ComputeJacobian(sf, arg%coords)

      wdetJ = gauss%w(igp) * sf%detJ

      CALL ComputeStrainDisplacementMatrix(sf, ndof, B)

      DO i = 1, ndof
        DO k = 1, nstrs
          arg%Fint(i) = arg%Fint(i) + wdetJ * B(k,i) * arg%stress_gp(igp,k)
        END DO
      END DO
    END DO

    DEALLOCATE(B)
    IF (ALLOCATED(gauss%xi)) DEALLOCATE(gauss%xi)
    IF (ALLOCATED(gauss%w))  DEALLOCATE(gauss%w)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Core_Compute_Fint

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Core_Compute_Mass
  ! PHASE:      P2
  ! PURPOSE:    Mass Me = SUM_gp [ w * det(J) * rho * N^T * N ].
  ! SIO:        (config, ctx, arg, status) — arg = PH_Elem_Core_Mass_Arg
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Core_Compute_Mass(config, ctx, arg, status)
    TYPE(PH_Elem_Desc),          INTENT(IN)    :: config
    TYPE(PH_Elem_Ctx),           INTENT(INOUT) :: ctx
    TYPE(PH_Elem_Core_Mass_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    TYPE(PH_Elem_GaussInt_Desc)      :: gauss
    TYPE(PH_Elem_ShapeFunc_Ctx) :: sf
    INTEGER(i4) :: igp, ia, ib, idof, ndim, ndof, int_order
    REAL(wp)    :: wdetJ

    CALL init_error_status(status)

    ndim = config%cfg%ndim
    ndof = config%pop%n_dof
    ! Allocate output if needed
    IF (.NOT. ALLOCATED(arg%Me)) ALLOCATE(arg%Me(ndof, ndof))
    arg%Me = 0.0_wp

    int_order = PH_Elem_Core_GaussOrder(config%cfg%family_id)

    SELECT CASE(ndim)
      CASE(3)
        CALL gauss%Init3D(int_order)
      CASE(2)
        CALL gauss%Init2D(int_order)
      CASE DEFAULT
        status%status_code = IF_STATUS_INVALID
        status%message = "[PH_Elem_Core_Compute_Mass]: unsupported ndim"
        RETURN
    END SELECT

    DO igp = 1, gauss%n_points
      CALL ComputeShapeFunc(config%cfg%family_id, gauss%xi(igp,:), sf)
      CALL ComputeJacobian(sf, arg%coords)

      wdetJ = gauss%w(igp) * sf%detJ * arg%rho

      DO ia = 1, config%pop%n_nodes
        DO ib = 1, config%pop%n_nodes
          DO idof = 1, ndim
            arg%Me((ia-1)*ndim+idof, (ib-1)*ndim+idof) = &
              arg%Me((ia-1)*ndim+idof, (ib-1)*ndim+idof) &
              + wdetJ * sf%N(ia) * sf%N(ib)
          END DO
        END DO
      END DO
    END DO

    IF (ALLOCATED(gauss%xi)) DEALLOCATE(gauss%xi)
    IF (ALLOCATED(gauss%w))  DEALLOCATE(gauss%w)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Core_Compute_Mass

  !---------------------------------------------------------------------------
  ! SUBROUTINE: PH_Elem_Core_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Release element context resources.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Elem_Core_Finalize(state, ctx, status)
    TYPE(PH_Elem_State),   INTENT(INOUT) :: state
    TYPE(PH_Elem_Ctx),  INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (ASSOCIATED(ctx%lcl%u_elem))  DEALLOCATE(ctx%lcl%u_elem)
    IF (ASSOCIATED(ctx%lcl%du_elem)) DEALLOCATE(ctx%lcl%du_elem)
    IF (ASSOCIATED(ctx%evo%Ke))      DEALLOCATE(ctx%evo%Ke)
    IF (ASSOCIATED(ctx%evo%Ke_mat))  DEALLOCATE(ctx%evo%Ke_mat)
    IF (ASSOCIATED(ctx%evo%Ke_geo))  DEALLOCATE(ctx%evo%Ke_geo)
    IF (ASSOCIATED(ctx%evo%R_int))   DEALLOCATE(ctx%evo%R_int)
    IF (ASSOCIATED(ctx%lcl%dN_dX))   DEALLOCATE(ctx%lcl%dN_dX)
    IF (ASSOCIATED(ctx%lcl%J_mat))   DEALLOCATE(ctx%lcl%J_mat)

    state%initialized     = .FALSE.
    state%stiffness_built = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Elem_Core_Finalize

  !---------------------------------------------------------------------------
  ! FUNCTION:  PH_Elem_Core_Get_NDof
  ! PHASE:     P0
  ! PURPOSE:   Query total DOFs for element.
  !---------------------------------------------------------------------------
  FUNCTION PH_Elem_Core_Get_NDof(config) RESULT(ndof)
    TYPE(PH_Elem_Desc), INTENT(IN) :: config
    INTEGER(i4) :: ndof
    ndof = config%pop%n_dof
  END FUNCTION PH_Elem_Core_Get_NDof

  !---------------------------------------------------------------------------
  ! FUNCTION:  PH_Elem_Core_Get_NNodes
  ! PHASE:     P0
  ! PURPOSE:   Query number of nodes for element.
  !---------------------------------------------------------------------------
  FUNCTION PH_Elem_Core_Get_NNodes(config) RESULT(nnodes)
    TYPE(PH_Elem_Desc), INTENT(IN) :: config
    INTEGER(i4) :: nnodes
    nnodes = config%pop%n_nodes
  END FUNCTION PH_Elem_Core_Get_NNodes

  !---------------------------------------------------------------------------
  ! FUNCTION:  PH_Elem_Core_GaussOrder
  ! PHASE:     P0
  ! PURPOSE:   Default Gauss integration order per element family.
  !---------------------------------------------------------------------------
  FUNCTION PH_Elem_Core_GaussOrder(family_id) RESULT(order)
    INTEGER(i4), INTENT(IN) :: family_id
    INTEGER(i4) :: order

    SELECT CASE(family_id)
      CASE(1)          ! C3D4: 1-point
        order = 1_i4
      CASE(2, 3)       ! C3D8/C3D8R: 2x2x2
        order = 2_i4
      CASE(10)         ! C3D10: 2-point
        order = 2_i4
      CASE(20, 21)     ! C3D20/C3D20R: 3x3x3
        order = 3_i4
      CASE(30, 31, 40, 41, 50, 51)  ! CPE4/CPS4/S4 linear quads
        order = 2_i4
      CASE(32, 33, 42, 52, 53)      ! CPE8/CPS8/S8 quadratic quads
        order = 3_i4
      CASE(35, 45)     ! CPE3/CPS3: 1-point tri
        order = 1_i4
      CASE(36, 46)     ! CPE6/CPS6: 3-point tri
        order = 2_i4
      CASE(70, 80)     ! B21/T2D2: 2-point line
        order = 2_i4
      CASE(71, 81)     ! B22/T2D3: 3-point line
        order = 3_i4
      CASE DEFAULT
        order = 2_i4
    END SELECT
  END FUNCTION PH_Elem_Core_GaussOrder

END MODULE PH_Elem_Core
