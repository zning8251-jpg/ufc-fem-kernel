!===============================================================================
! MODULE: PH_Constr_Period
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Eval — core Periodic BC algorithm implementations
! BRIEF:  Macro strain/stress averaging, periodic DOF pairing, and enforcement.
!===============================================================================
! Theory:
!   Macro strain: ε̄ = 1/V ∫_V ε dV
!   Macro stress: σ̄ = 1/V ∫_V σ dV
!   Displacement jump: Δu = ε̄·L (L = RVE size vector)
! Status:  CORE | Last verified: 2026-03-01
!
! Contents (A-Z):
!   Types:
!     - (None)
!   Subroutines:
!     - PH_Constr_PeriodCore_ComputeMacroStrain
!     - PH_Constr_PeriodCore_ComputeMacroStress
!     - PH_Constr_PeriodCore_IdentifyBoundaryNodes
!     - PH_Constr_PeriodCore_ResizeNodePairsArray
!   Functions:
!     - (None)
!===============================================================================

MODULE PH_Constr_Period
  USE IF_Base_Def, ONLY: ZERO, ONE, SMALL_VAL => SMALL
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_ConstrPeriod_Def
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! Public interface (only for API layer)
  ! ==========================================================================
  PUBLIC :: PH_Constr_PeriodCore_ComputeMacroStrain
  PUBLIC :: PH_Constr_PeriodCore_ComputeMacroStress
  PUBLIC :: PH_Constr_PeriodCore_IdentifyBoundaryNodes
  PUBLIC :: PH_Constr_PeriodCore_ResizeNodePairsArray

  !=============================================================================
  ! INTF-001
  ! Purpose: PH_Constr_PeriodCore_IdentifyBoundaryNodes(5 )
  ! Theory: RVE : ε̄ = 1/V∫�?dV Δu = ε̄·L (L = RVE )
  ! : |coord - min_val| < tol �?minus; |coord - max_val| < tol �?plus
  ! Status: Draft |
  !=============================================================================
  PUBLIC :: PH_Constr_PeriodCore_BoundaryArgs
  TYPE :: PH_Constr_PeriodCore_BoundaryArgs
    REAL(wp), POINTER :: coords(:,:) => NULL()  !! (3, nNodes)
    INTEGER(i4) :: nNodes    = 0_i4  ! periodic BC node count
    INTEGER(i4) :: direction = 1_i4   !! 1=x, 2=y, 3=z
    TYPE(Period_BC_Params), POINTER :: params => NULL()  ! parameter / descriptor ptr
    INTEGER(i4), POINTER :: minus_nodes(:) => NULL()  !! ALLOCATABLE
    INTEGER(i4), POINTER :: plus_nodes(:)  => NULL()  !! ALLOCATABLE
  END TYPE PH_Constr_PeriodCore_BoundaryArgs

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Constr_PeriodCore_ComputeMacroStrain: Compute macro strain via volume averaging
  ! Theory: ε̄ = 1/V ∫_V ε dV
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Constr_PeriodCore_ComputeMacroStrain(params, element_strains, element_volumes, &
                                      nElems, state)
    TYPE(Period_BC_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: element_strains(:,:)   ! (6, n_elem) Voigt notation
    REAL(wp), INTENT(IN) :: element_volumes(:)     ! (n_elem)
    INTEGER(i4), INTENT(IN) :: nElems
    TYPE(Period_BC_State), INTENT(INOUT) :: state

    INTEGER(i4) :: i_elem
    REAL(wp) :: total_volume

    state%computed_macro_strain = ZERO
    total_volume = ZERO

    ! Volume-weighted averaging
    DO i_elem = 1, nElems
      state%computed_macro_strain = state%computed_macro_strain + &
                                   element_strains(:, i_elem) * element_volumes(i_elem)
      total_volume = total_volume + element_volumes(i_elem)
    END DO

    IF (total_volume > SMALL_VAL) THEN
      state%computed_macro_strain = state%computed_macro_strain / total_volume
    END IF

    state%rve_volume = total_volume

  END SUBROUTINE PH_Constr_PeriodCore_ComputeMacroStrain

  !-----------------------------------------------------------------------------
  ! PH_Constr_PeriodCore_ComputeMacroStress: Compute macro stress via volume averaging
  ! Theory: σ̄ = 1/V ∫_V σ dV
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Constr_PeriodCore_ComputeMacroStress(params, element_stresses, element_volumes, &
                                      nElems, state)
    TYPE(Period_BC_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: element_stresses(:,:)  ! (6, n_elem) Voigt notation
    REAL(wp), INTENT(IN) :: element_volumes(:)     ! (n_elem)
    INTEGER(i4), INTENT(IN) :: nElems
    TYPE(Period_BC_State), INTENT(INOUT) :: state

    INTEGER(i4) :: i_elem
    REAL(wp) :: total_volume

    state%computed_macro_stress = ZERO
    total_volume = ZERO

    ! Volume-weighted averaging
    DO i_elem = 1, nElems
      state%computed_macro_stress = state%computed_macro_stress + &
                                   element_stresses(:, i_elem) * element_volumes(i_elem)
      total_volume = total_volume + element_volumes(i_elem)
    END DO

    IF (total_volume > SMALL_VAL) THEN
      state%computed_macro_stress = state%computed_macro_stress / total_volume
    END IF

  END SUBROUTINE PH_Constr_PeriodCore_ComputeMacroStress

  !-----------------------------------------------------------------------------
  ! PH_Constr_PeriodCore_IdentifyBoundaryNodes: Identify minus/plus boundary nodes
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Constr_PeriodCore_IdentifyBoundaryNodes(coords, nNodes, params, direction, &
                                        minus_nodes, plus_nodes)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: nNodes, direction
    TYPE(Period_BC_Params), INTENT(IN) :: params
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: minus_nodes(:), plus_nodes(:)

    INTEGER(i4) :: i, count_minus, count_plus
    INTEGER(i4), ALLOCATABLE :: temp_minus(:), temp_plus(:)
    REAL(wp) :: coord_val, min_val, max_val, tol

    ALLOCATE(temp_minus(nNodes))
    ALLOCATE(temp_plus(nNodes))

    tol = params%pairing_tolerance
    min_val = params%rve_origin(direction)
    max_val = params%rve_origin(direction) + params%rve_size(direction)

    count_minus = 0_i4
    count_plus = 0_i4

    ! Identify boundary nodes
    DO i = 1, nNodes
      coord_val = coords(direction, i)

      IF (ABS(coord_val - min_val) < tol) THEN
        count_minus = count_minus + 1
        temp_minus(count_minus) = i
      ELSE IF (ABS(coord_val - max_val) < tol) THEN
        count_plus = count_plus + 1
        temp_plus(count_plus) = i
      END IF
    END DO

    ! Resize arrays
    ALLOCATE(minus_nodes(count_minus))
    ALLOCATE(plus_nodes(count_plus))
    minus_nodes = temp_minus(1:count_minus)
    plus_nodes = temp_plus(1:count_plus)

    DEALLOCATE(temp_minus, temp_plus)

  END SUBROUTINE PH_Constr_PeriodCore_IdentifyBoundaryNodes

  !-----------------------------------------------------------------------------
  ! PH_Constr_PeriodCore_ResizeNodePairsArray: Resize node pairs array
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Constr_PeriodCore_ResizeNodePairsArray(node_pairs, new_size)
    TYPE(Node_Pair_Data), ALLOCATABLE, INTENT(INOUT) :: node_pairs(:)
    INTEGER(i4), INTENT(IN) :: new_size

    TYPE(Node_Pair_Data), ALLOCATABLE :: temp(:)
    INTEGER(i4) :: old_sz, ncopy, i

    IF (new_size <= 0_i4) THEN
      IF (ALLOCATED(node_pairs)) DEALLOCATE(node_pairs)
      RETURN
    END IF

    IF (.NOT. ALLOCATED(node_pairs)) THEN
      ALLOCATE(node_pairs(new_size))
      RETURN
    END IF

    old_sz = SIZE(node_pairs)
    ncopy = MIN(old_sz, new_size)
    ALLOCATE(temp(new_size))
    DO i = 1, ncopy
      temp(i) = node_pairs(i)
    END DO
    DEALLOCATE(node_pairs)
    ALLOCATE(node_pairs(new_size))
    node_pairs(1:new_size) = temp(1:new_size)
    DEALLOCATE(temp)

  END SUBROUTINE PH_Constr_PeriodCore_ResizeNodePairsArray

END MODULE PH_Constr_Period