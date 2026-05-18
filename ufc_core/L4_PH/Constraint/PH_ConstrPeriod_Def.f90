!===============================================================================
! MODULE: PH_ConstrPeriod_Def
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Def — Periodic BC type definitions for RVE/homogenization
! BRIEF:  Node_Pair_Data, Period_BC_Params, Period_BC_State types.
!===============================================================================
!
! Contents (A-Z):
!   Types:
!     - Node_Pair_Data        - Periodic node pairing data
!     - Period_BC_Params      - Periodic BC configuration parameters
!     - Period_BC_State       - Periodic BC computation state
!   Subroutines:
!     - (None)
!   Functions:
!     - (None)
!===============================================================================

MODULE PH_ConstrPeriod_Def
  USE IF_Base_Def, ONLY: ZERO
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  
  ! ==========================================================================
  ! Public types
  ! ==========================================================================
  PUBLIC :: Node_Pair_Data
  PUBLIC :: Period_BC_Params
  PUBLIC :: Period_BC_State
  
  ! ==========================================================================
  ! Period BC Parameters - configuration
  ! ==========================================================================
  TYPE :: Period_BC_Params
    ! RVE geometry
    REAL(wp) :: rve_size(3) = ZERO               ! RVE dimensions [Lx, Ly, Lz]
    REAL(wp) :: rve_origin(3) = ZERO             ! RVE origin coordinates
    
    ! Periodicity directions
    LOGICAL :: periodic_x = .FALSE.              ! X-direction periodicity
    LOGICAL :: periodic_y = .FALSE.              ! Y-direction periodicity
    LOGICAL :: periodic_z = .FALSE.              ! Z-direction periodicity
    
    ! Macro strain
    REAL(wp) :: macro_strain(6) = ZERO           ! Macro strain [εxx, εyy, εzz, γxy, γyz, γxz]
    LOGICAL :: impose_macro_strain = .FALSE.     ! Whether to impose macro strain
    
    ! BC type
    INTEGER(i4) :: bc_type = 1_i4                ! 1=displacement periodicity, 2=mixed, 3=stress periodicity
    
    ! Pairing tolerance
    REAL(wp) :: pairing_tolerance = 1.0e-6_wp    ! Node pairing tolerance
  END TYPE Period_BC_Params
  
  ! ==========================================================================
  ! Period BC State - computation results
  ! ==========================================================================
  TYPE :: Period_BC_State
    INTEGER(i4) :: nNode_pairs = 0_i4            ! Number of node pairs
    REAL(wp) :: computed_macro_strain(6) = ZERO  ! Computed macro strain
    REAL(wp) :: computed_macro_stress(6) = ZERO  ! Computed macro stress
    REAL(wp) :: rve_volume = ZERO                ! RVE volume
    LOGICAL :: is_consistent = .TRUE.            ! Whether BC is consistent
  END TYPE Period_BC_State
  
  ! ==========================================================================
  ! Node Pair Data - periodic node pairing
  ! ==========================================================================
  TYPE :: Node_Pair_Data
    INTEGER(i4) :: node_minus_id = 0_i4          ! Minus-side node ID
    INTEGER(i4) :: node_plus_id = 0_i4           ! Plus-side node ID
    INTEGER(i4) :: boundary_face = 0_i4          ! Boundary face ID (1=x-, 2=x+, 3=y-, ...)
    REAL(wp) :: coords_minus(3) = ZERO           ! Minus-side coordinates
    REAL(wp) :: coords_plus(3) = ZERO            ! Plus-side coordinates
    LOGICAL :: is_corner_node = .FALSE.          ! Whether corner node
    LOGICAL :: is_edge_node = .FALSE.            ! Whether edge node
  END TYPE Node_Pair_Data

END MODULE PH_ConstrPeriod_Def
