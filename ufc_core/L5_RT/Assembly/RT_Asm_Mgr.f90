!===============================================================================
! MODULE: RT_Asm_Mgr
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Mgr
! BRIEF:  FE assembly manager -- K/M/R/F triplet-based scatter and CSR build
!===============================================================================
! Layer:  L5_RT - Runtime Layer
! Domain: Asm - Assembly
! Purpose: Finite element assembly core for K/M/R/F matrices
! Theory:
!   Assembly Process:
!   - Element loop: Σ_e K_e ?K_global
!   - DOF mapping: K_global(I,J) += K_e(i,j) where I=DOF(i), J=DOF(j)
!   - Sparse storage: CSR format (row_ptr, col_ind, values)
!   Parallel Assembly:
!   - OpenMP: thread-local buffers ?atomic merge
!   - MPI: domain decomposition ?global assembly via Allreduce
!   Performance Optimization:
!   - Pre-allocated triplet list ?CSR conversion once
!   - Cache-friendly access patterns
! Status: CORE | Last verified: 2026-03-06
!
! Logic Chain (Mermaid):
! ```mermaid
! flowchart TB
!     subgraph Assembly["Assembly Process"]
!         A[RT_Asm_Init] --> B[Element Loop]
!     end
!     
!     subgraph Elem["Per Element"]
!         B --> C[Get Element DOFs]
!         C --> D[Compute K_e, R_e]
!         D --> E[Local→Global Mapping]
!         E --> F[Add to TripletList]
!     end
!     
!     subgraph Finalize["Finalize"]
!         F --> G[Convert to CSR]
!         G --> H[RT_Asm_Finalize]
!     end
! ```
!
! Contents (A-Z):
!   Types:
!     - RT_Asm_AssemStiff_In, RT_Asm_AssemStiff_Out
!     - RT_Asm_AssemResidual_In, RT_Asm_AssemResidual_Out
!     - RT_Asm_AssemMass_In, RT_Asm_AssemMass_Out
!   Subroutines:
!     - RT_Asm_Init, RT_Asm_Finalize
!     - RT_Asm_AssemStiff, RT_Asm_AssemResidual
!     - RT_Asm_AssemMass, RT_Asm_AssemDamping
!===============================================================================

MODULE RT_Asm_Mgr
!> [CORE] Finite element assembly (K/M/R/F matrices)
!> Theory: K_global(I,J) += K_e(i,j), CSR sparse storage
!> Status: CORE | Last verified: 2026-03-06
    USE IF_Base_Def, ONLY: ZERO, ONE
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE NM_Assem_Sparse, ONLY: RT_TripletList, RT_Triplet_Add
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! Structured Input/Output Types
    ! ==========================================================================
    ! RT_Asm_AssemStiff
    TYPE, PUBLIC :: RT_Asm_AssemStiff_In
        REAL(wp), ALLOCATABLE :: K_element(:,:)  ! Element stiffness matrix K_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
    END TYPE RT_Asm_AssemStiff_In
    TYPE, PUBLIC :: RT_Asm_AssemStiff_Out
        REAL(wp), ALLOCATABLE :: K_global(:,:)  ! Global stiffness matrix K
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemStiff_Out

    ! RT_Asm_AssemResid
    TYPE, PUBLIC :: RT_Asm_AssemResid_In
        REAL(wp), ALLOCATABLE :: R_element(:)  ! Element residual vector R_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
    END TYPE RT_Asm_AssemResid_In
    TYPE, PUBLIC :: RT_Asm_AssemResid_Out
        REAL(wp), ALLOCATABLE :: R_global(:)  ! Global residual vector R
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemResid_Out

    ! RT_Asm_AssemMass
    TYPE, PUBLIC :: RT_Asm_AssemMass_In
        REAL(wp), ALLOCATABLE :: M_element(:,:)  ! Element mass matrix M_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
    END TYPE RT_Asm_AssemMass_In
    TYPE, PUBLIC :: RT_Asm_AssemMass_Out
        REAL(wp), ALLOCATABLE :: M_global(:,:)  ! Global mass matrix M
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemMass_Out

    ! RT_Asm_AssemDamp
    TYPE, PUBLIC :: RT_Asm_AssemDamp_In
        REAL(wp), ALLOCATABLE :: C_element(:,:)  ! Element damping matrix C_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
    END TYPE RT_Asm_AssemDamp_In
    TYPE, PUBLIC :: RT_Asm_AssemDamp_Out
        REAL(wp), ALLOCATABLE :: C_global(:,:)  ! Global damping matrix C
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemDamp_Out

    ! RT_Asm_AddElemStiff
    TYPE, PUBLIC :: RT_Asm_AddElemStiff_In
        REAL(wp), ALLOCATABLE :: K_element(:,:)  ! Element stiffness matrix K_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        REAL(wp), ALLOCATABLE :: K_global(:,:)  ! Global stiffness matrix K (inout)
    END TYPE RT_Asm_AddElemStiff_In
    TYPE, PUBLIC :: RT_Asm_AddElemStiff_Out
        REAL(wp), ALLOCATABLE :: K_global(:,:)  ! Updated global stiffness matrix K
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AddElemStiff_Out

    ! RT_Asm_AddElemResid
    TYPE, PUBLIC :: RT_Asm_AddElemResid_In
        REAL(wp), ALLOCATABLE :: R_element(:)  ! Element residual vector R_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        REAL(wp), ALLOCATABLE :: R_global(:)  ! Global residual vector R (inout)
    END TYPE RT_Asm_AddElemResid_In
    TYPE, PUBLIC :: RT_Asm_AddElemResid_Out
        REAL(wp), ALLOCATABLE :: R_global(:)  ! Updated global residual vector R
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AddElemResid_Out

    ! RT_Asm_GetElemDOF
    TYPE, PUBLIC :: RT_Asm_GetElemDOF_In
        INTEGER(i4) :: elem_id  ! Element ID
        INTEGER(i4), ALLOCATABLE :: node_ids(:)  ! Node IDs
        INTEGER(i4) :: dof_per_node  ! DOF per node
    END TYPE RT_Asm_GetElemDOF_In
    TYPE, PUBLIC :: RT_Asm_GetElemDOF_Out
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_GetElemDOF_Out

    ! RT_Asm_ScatterElemToGlob
    TYPE, PUBLIC :: RT_Asm_ScatterElemToGlob_In
        REAL(wp), ALLOCATABLE :: elem_vec(:)  ! Element vector
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        REAL(wp), ALLOCATABLE :: global_vec(:)  ! Global vector (inout)
    END TYPE RT_Asm_ScatterElemToGlob_In
    TYPE, PUBLIC :: RT_Asm_ScatterElemToGlob_Out
        REAL(wp), ALLOCATABLE :: global_vec(:)  ! Updated global vector
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_ScatterElemToGlob_Out

    ! RT_Asm_AssemStiffSparse
    TYPE, PUBLIC :: RT_Asm_AssemStiffSparse_In
        REAL(wp), ALLOCATABLE :: K_element(:,:)  ! Element stiffness matrix K_e
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        TYPE(RT_TripletList) :: K_triplets  ! Triplet list (inout)
    END TYPE RT_Asm_AssemStiffSparse_In
    TYPE, PUBLIC :: RT_Asm_AssemStiffSparse_Out
        TYPE(RT_TripletList) :: K_triplets  ! Updated triplet list
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemStiffSparse_Out

    ! RT_Asm_AssemMassConsist
    TYPE, PUBLIC :: RT_Asm_AssemMassConsist_In
        REAL(wp), ALLOCATABLE :: N(:)  ! Shape functions
        REAL(wp) :: density  ! Material density ρ
        REAL(wp) :: detJ  ! Determinant of Jacobian |J|
        REAL(wp) :: weight  ! Integration weight
        INTEGER(i4) :: n_gauss  ! Number of Gauss points
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        REAL(wp), ALLOCATABLE :: M_global(:,:)  ! Global mass matrix M (inout)
    END TYPE RT_Asm_AssemMassConsist_In
    TYPE, PUBLIC :: RT_Asm_AssemMassConsist_Out
        REAL(wp), ALLOCATABLE :: M_global(:,:)  ! Updated global mass matrix M
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemMassConsist_Out

    ! RT_Asm_AssemLoadOpt
    TYPE, PUBLIC :: RT_Asm_AssemLoadOpt_In
        REAL(wp), ALLOCATABLE :: N(:)  ! Shape functions
        REAL(wp), ALLOCATABLE :: load_value(:)  ! Load values
        REAL(wp) :: detJ  ! Determinant of Jacobian |J|
        REAL(wp) :: weight  ! Integration weight
        INTEGER(i4) :: n_gauss  ! Number of Gauss points
        INTEGER(i4), ALLOCATABLE :: elem_dof(:)  ! Element DOF indices
        LOGICAL :: use_vectorized  ! Use vectorized assembly
        REAL(wp), ALLOCATABLE :: F_global(:)  ! Global force vector F (inout)
    END TYPE RT_Asm_AssemLoadOpt_In
    TYPE, PUBLIC :: RT_Asm_AssemLoadOpt_Out
        REAL(wp), ALLOCATABLE :: F_global(:)  ! Updated global force vector F
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemLoadOpt_Out

    ! RT_Asm_AssemDampRayleigh
    TYPE, PUBLIC :: RT_Asm_AssemDampRayleigh_In
        REAL(wp), ALLOCATABLE :: M_global(:,:)  ! Global mass matrix M
        REAL(wp), ALLOCATABLE :: K_global(:,:)  ! Global stiffness matrix K
        REAL(wp) :: alpha  ! Rayleigh damping coefficient α
        REAL(wp) :: beta  ! Rayleigh damping coefficient β
        REAL(wp), ALLOCATABLE :: C_global(:,:)  ! Global damping matrix C (inout)
    END TYPE RT_Asm_AssemDampRayleigh_In
    TYPE, PUBLIC :: RT_Asm_AssemDampRayleigh_Out
        REAL(wp), ALLOCATABLE :: C_global(:,:)  ! Updated global damping matrix C = αM + βK
        TYPE(ErrorStatusType) :: status
    END TYPE RT_Asm_AssemDampRayleigh_Out
    
    ! ==========================================================================
    ! PUBLIC TYPES
    ! ==========================================================================
    ! Structured input/output types
    PUBLIC :: RT_Asm_AssemStiff_In, RT_Asm_AssemStiff_Out
    PUBLIC :: RT_Asm_AssemResid_In, RT_Asm_AssemResid_Out
    PUBLIC :: RT_Asm_AssemMass_In, RT_Asm_AssemMass_Out
    PUBLIC :: RT_Asm_AssemDamp_In, RT_Asm_AssemDamp_Out
    PUBLIC :: RT_Asm_AddElemStiff_In, RT_Asm_AddElemStiff_Out
    PUBLIC :: RT_Asm_AddElemResid_In, RT_Asm_AddElemResid_Out
    PUBLIC :: RT_Asm_GetElemDOF_In, RT_Asm_GetElemDOF_Out
    PUBLIC :: RT_Asm_ScatterElemToGlob_In, RT_Asm_ScatterElemToGlob_Out
    PUBLIC :: RT_Asm_AssemStiffSparse_In, RT_Asm_AssemStiffSparse_Out
    PUBLIC :: RT_Asm_AssemMassConsist_In, RT_Asm_AssemMassConsist_Out
    PUBLIC :: RT_Asm_AssemLoadOpt_In, RT_Asm_AssemLoadOpt_Out
    PUBLIC :: RT_Asm_AssemDampRayleigh_In, RT_Asm_AssemDampRayleigh_Out

    ! ==========================================================================
    ! Parallel assembly modes (SMP)
    ! ==========================================================================
    PUBLIC :: RT_Asm_AddElemStiff_Atomic
    PUBLIC :: RT_Asm_AddElemStiff_InPlace
    PUBLIC :: RT_Asm_ScatterResid_Atomic

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    ! Structured interfaces
    PUBLIC :: RT_Asm_AssemStiff_Structured
    PUBLIC :: RT_Asm_AssemResid_Structured
    PUBLIC :: RT_Asm_AssemMass_Structured
    PUBLIC :: RT_Asm_AssemDamp_Structured
    PUBLIC :: RT_Asm_AddElemStiff_Structured
    PUBLIC :: RT_Asm_AddElemResid_Structured
    PUBLIC :: RT_Asm_GetElemDOF_Structured
    PUBLIC :: RT_Asm_ScatterElemToGlob_Structured
    PUBLIC :: RT_Asm_AssemStiffSparse_Structured
    PUBLIC :: RT_Asm_AssemMassConsist_Structured
    PUBLIC :: RT_Asm_AssemLoadOpt_Structured
    PUBLIC :: RT_Asm_AssemDampRayleigh_Structured
    ! Legacy interfaces (deprecated)
    PUBLIC :: RT_Asm_AssemStiff
    PUBLIC :: RT_Asm_AssemResid
    PUBLIC :: RT_Asm_AssemMass
    PUBLIC :: RT_Asm_AssemDamp
    PUBLIC :: RT_Asm_AddElemStiff
    PUBLIC :: RT_Asm_AddElemResid
    PUBLIC :: RT_Asm_GetElemDOF
    PUBLIC :: RT_Asm_ScatterElemToGlob
    PUBLIC :: RT_Asm_AssemStiffSparse
    PUBLIC :: RT_Asm_AssemMassConsist
    PUBLIC :: RT_Asm_AssemLoadOpt
    PUBLIC :: RT_Asm_AssemDampRayleigh
    
CONTAINS

    ! ==========================================================================
    ! Structured Interfaces
    ! ==========================================================================
    SUBROUTINE RT_Asm_AssemStiff_Structured(in, out)
        !! Assemble element stiffness matrix into global stiffness matrix
        !!
        !! Theory:
        !!   Global stiffness matrix assembly:
        !!     K_ij = Σ_e K_e^{ij}
        !!
        !!   where K_e is the element stiffness matrix and the sum is over all elements.
        !!
        !! Input:
        !!   in%K_element: Element stiffness matrix K_e
        !!   in%elem_dof: Element DOF indices
        !!
        !! Output:
        !!   out%K_global: Global stiffness matrix K
        !!   out%status: Error status
        
        TYPE(RT_Asm_AssemStiff_In), INTENT(IN) :: in
        TYPE(RT_Asm_AssemStiff_Out), INTENT(OUT) :: out

        INTEGER(i4) :: n_dof, i, j, row_idx, col_idx

        CALL init_error_status(out%status)
        ALLOCATE(out%K_global(SIZE(in%K_element, 1), SIZE(in%K_element, 2)))
        out%K_global = 0.0_wp

        n_dof = SIZE(in%elem_dof)
        IF (SIZE(in%K_element, 1) /= n_dof .OR. SIZE(in%K_element, 2) /= n_dof) THEN
            out%status%status_code = IF_STATUS_INVALID
            out%status%message = 'RT_Asm_AssemStiff_Structured: Dimension mismatch'
            RETURN
        END IF

        ! Add element contributions to global matrix
        DO i = 1, n_dof
            row_idx = in%elem_dof(i)
            IF (row_idx <= 0 .OR. row_idx > SIZE(out%K_global, 1)) CYCLE
            
            DO j = 1, n_dof
                col_idx = in%elem_dof(j)
                IF (col_idx <= 0 .OR. col_idx > SIZE(out%K_global, 2)) CYCLE
                
                out%K_global(row_idx, col_idx) = out%K_global(row_idx, col_idx) + in%K_element(i, j)
            END DO
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AssemStiff_Structured

    SUBROUTINE RT_Asm_AssemResid_Structured(in, out)
        !! Assemble element residual vector into global residual vector
        !!
        !! Theory:
        !!   Global residual vector assembly:
        !!     R_i = Σ_e R_e^i
        !!
        !!   where R_e is the element residual vector and the sum is over all elements.
        !!
        !! Input:
        !!   in%R_element: Element residual vector R_e
        !!   in%elem_dof: Element DOF indices
        !!
        !! Output:
        !!   out%R_global: Global residual vector R
        !!   out%status: Error status
        
        TYPE(RT_Asm_AssemResid_In), INTENT(IN) :: in
        TYPE(RT_Asm_AssemResid_Out), INTENT(OUT) :: out

        INTEGER(i4) :: n_dof, i, dof_idx

        CALL init_error_status(out%status)
        ALLOCATE(out%R_global(SIZE(in%R_element)))
        out%R_global = 0.0_wp

        n_dof = SIZE(in%elem_dof)
        IF (SIZE(in%R_element) /= n_dof) THEN
            out%status%status_code = IF_STATUS_INVALID
            out%status%message = 'RT_Asm_AssemResid_Structured: Dimension mismatch'
            RETURN
        END IF

        ! Add element contributions to global residual
        DO i = 1, n_dof
            dof_idx = in%elem_dof(i)
            IF (dof_idx > 0 .AND. dof_idx <= SIZE(out%R_global)) THEN
                out%R_global(dof_idx) = out%R_global(dof_idx) + in%R_element(i)
            END IF
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AssemResid_Structured

    SUBROUTINE RT_Asm_AddElemStiff_Structured(in, out)
        !! Add element stiffness matrix to global stiffness matrix
        !!
        !! Theory:
        !!   Adds element contribution to existing global matrix:
        !!     K_ij += K_e^{ij}
        !!
        !! Input:
        !!   in%K_element: Element stiffness matrix K_e
        !!   in%elem_dof: Element DOF indices
        !!   in%K_global: Global stiffness matrix K (inout)
        !!
        !! Output:
        !!   out%K_global: Updated global stiffness matrix K
        !!   out%status: Error status
        
        TYPE(RT_Asm_AddElemStiff_In), INTENT(IN) :: in
        TYPE(RT_Asm_AddElemStiff_Out), INTENT(OUT) :: out

        INTEGER(i4) :: n_dof, i, j, row_idx, col_idx

        CALL init_error_status(out%status)
        ALLOCATE(out%K_global(SIZE(in%K_global, 1), SIZE(in%K_global, 2)))
        out%K_global = in%K_global

        n_dof = SIZE(in%elem_dof)
        IF (SIZE(in%K_element, 1) /= n_dof .OR. SIZE(in%K_element, 2) /= n_dof) THEN
            out%status%status_code = IF_STATUS_INVALID
            out%status%message = 'RT_Asm_AddElemStiff_Structured: Dimension mismatch'
            RETURN
        END IF

        ! Add element contributions
        DO i = 1, n_dof
            row_idx = in%elem_dof(i)
            IF (row_idx <= 0 .OR. row_idx > SIZE(out%K_global, 1)) CYCLE
            
            DO j = 1, n_dof
                col_idx = in%elem_dof(j)
                IF (col_idx <= 0 .OR. col_idx > SIZE(out%K_global, 2)) CYCLE
                
                out%K_global(row_idx, col_idx) = out%K_global(row_idx, col_idx) + in%K_element(i, j)
            END DO
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AddElemStiff_Structured

    SUBROUTINE RT_Asm_AddElemResid_Structured(in, out)
        !! Add element residual vector to global residual vector
        !!
        !! Theory:
        !!   Adds element contribution to existing global vector:
        !!     R_i += R_e^i
        !!
        !! Input:
        !!   in%R_element: Element residual vector R_e
        !!   in%elem_dof: Element DOF indices
        !!   in%R_global: Global residual vector R (inout)
        !!
        !! Output:
        !!   out%R_global: Updated global residual vector R
        !!   out%status: Error status
        
        TYPE(RT_Asm_AddElemResid_In), INTENT(IN) :: in
        TYPE(RT_Asm_AddElemResid_Out), INTENT(OUT) :: out

        TYPE(RT_Asm_AssemResid_In) :: resid_in
        TYPE(RT_Asm_AssemResid_Out) :: resid_out

        resid_in%R_element = in%R_element
        resid_in%elem_dof = in%elem_dof
        CALL RT_Asm_AssemResid_Structured(resid_in, resid_out)
        ALLOCATE(out%R_global(SIZE(in%R_global)))
        out%R_global = in%R_global
        out%R_global = out%R_global + resid_out%R_global
        out%status = resid_out%status
    END SUBROUTINE RT_Asm_AddElemResid_Structured

    ! ==========================================================================
    ! Parallel Assembly (SMP hot path)
    ! ==========================================================================

    SUBROUTINE RT_Asm_AddElemStiff_Atomic(K_global, K_element, elem_dof, &
                                          n_dof, status)
      !> ATOMIC-based assembly: safe under !$OMP PARALLEL DO
      REAL(wp), INTENT(INOUT) :: K_global(:,:)
      REAL(wp), INTENT(IN)    :: K_element(:,:)
      INTEGER(i4), INTENT(IN) :: elem_dof(:)
      INTEGER(i4), INTENT(IN) :: n_dof
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      INTEGER(i4) :: i, j, row_idx, col_idx

      CALL init_error_status(status)

      DO j = 1, n_dof
        col_idx = elem_dof(j)
        IF (col_idx <= 0 .OR. col_idx > SIZE(K_global, 2)) CYCLE
        DO i = 1, n_dof
          row_idx = elem_dof(i)
          IF (row_idx <= 0 .OR. row_idx > SIZE(K_global, 1)) CYCLE
          !$OMP ATOMIC
          K_global(row_idx, col_idx) = K_global(row_idx, col_idx) + &
                                       K_element(i, j)
        END DO
      END DO

      status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AddElemStiff_Atomic

    SUBROUTINE RT_Asm_AddElemStiff_InPlace(K_global, K_element, elem_dof, &
                                           n_dof, status)
      !> Direct in-place assembly (no allocation). Safe when used inside
      !> graph-coloring loops where same-colored elements have disjoint DOFs.
      REAL(wp), INTENT(INOUT) :: K_global(:,:)
      REAL(wp), INTENT(IN)    :: K_element(:,:)
      INTEGER(i4), INTENT(IN) :: elem_dof(:)
      INTEGER(i4), INTENT(IN) :: n_dof
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      INTEGER(i4) :: i, j, row_idx, col_idx

      CALL init_error_status(status)

      DO j = 1, n_dof
        col_idx = elem_dof(j)
        IF (col_idx <= 0 .OR. col_idx > SIZE(K_global, 2)) CYCLE
        DO i = 1, n_dof
          row_idx = elem_dof(i)
          IF (row_idx <= 0 .OR. row_idx > SIZE(K_global, 1)) CYCLE
          K_global(row_idx, col_idx) = K_global(row_idx, col_idx) + &
                                       K_element(i, j)
        END DO
      END DO

      status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AddElemStiff_InPlace

    SUBROUTINE RT_Asm_ScatterResid_Atomic(R_global, R_element, elem_dof, &
                                          n_dof, status)
      !> ATOMIC residual scatter: safe under !$OMP PARALLEL DO
      REAL(wp), INTENT(INOUT) :: R_global(:)
      REAL(wp), INTENT(IN)    :: R_element(:)
      INTEGER(i4), INTENT(IN) :: elem_dof(:)
      INTEGER(i4), INTENT(IN) :: n_dof
      TYPE(ErrorStatusType), INTENT(OUT) :: status

      INTEGER(i4) :: i, dof_idx

      CALL init_error_status(status)

      DO i = 1, n_dof
        dof_idx = elem_dof(i)
        IF (dof_idx <= 0 .OR. dof_idx > SIZE(R_global)) CYCLE
        !$OMP ATOMIC
        R_global(dof_idx) = R_global(dof_idx) + R_element(i)
      END DO

      status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_ScatterResid_Atomic

    ! ==========================================================================
    ! Legacy Interfaces (deprecated)
    ! ==========================================================================
    !> @deprecated Use RT_Asm_AddElemResid_Structured instead
    SUBROUTINE RT_Asm_AddElemResid(R_global, R_element, elem_dof, status)
        REAL(wp), INTENT(INOUT) :: R_global(:)
        REAL(wp), INTENT(IN) :: R_element(:)
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AddElemResid_In) :: in
        TYPE(RT_Asm_AddElemResid_Out) :: out

        ALLOCATE(in%R_element(SIZE(R_element)))
        in%R_element = R_element
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        ALLOCATE(in%R_global(SIZE(R_global)))
        in%R_global = R_global
        CALL RT_Asm_AddElemResid_Structured(in, out)
        R_global = out%R_global
        status = out%status
    END SUBROUTINE RT_Asm_AddElemResid

    !> @deprecated Use RT_Asm_AddElemStiff_Structured instead
    SUBROUTINE RT_Asm_AddElemStiff(K_global, K_element, elem_dof, status)
        REAL(wp), INTENT(INOUT) :: K_global(:,:)
        REAL(wp), INTENT(IN) :: K_element(:,:)
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AddElemStiff_In) :: in
        TYPE(RT_Asm_AddElemStiff_Out) :: out

        ALLOCATE(in%K_element(SIZE(K_element, 1), SIZE(K_element, 2)))
        in%K_element = K_element
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        ALLOCATE(in%K_global(SIZE(K_global, 1), SIZE(K_global, 2)))
        in%K_global = K_global
        CALL RT_Asm_AddElemStiff_Structured(in, out)
        K_global = out%K_global
        status = out%status
    END SUBROUTINE RT_Asm_AddElemStiff

    SUBROUTINE RT_Asm_As_Optimized(F_global, N, load_value, detJ, &
                                            weight, n_gauss, elem_dof, &
                                            use_vectorized, status)
        REAL(wp), INTENT(INOUT) :: F_global(:)
        REAL(wp), INTENT(IN) :: N(:)
        REAL(wp), INTENT(IN) :: load_value(:)
        REAL(wp), INTENT(IN) :: detJ, weight
        INTEGER(i4), INTENT(IN) :: n_gauss
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        LOGICAL, INTENT(IN) :: use_vectorized
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        REAL(wp) :: dV
        INTEGER(i4) :: i, n_nodes, dof_idx, n_dim
        
        CALL init_error_status(status)
        
        n_nodes = SIZE(N)
        n_dim = SIZE(load_value)
        dV = detJ * weight
        
        IF (use_vectorized) THEN
            ! Vectorized assembly (simplified)
            DO i = 1, n_nodes
                dof_idx = elem_dof(i)
                IF (dof_idx > 0 .AND. dof_idx <= SIZE(F_global)) THEN
                    F_global(dof_idx) = F_global(dof_idx) + &
                                       N(i) * load_value(MOD(i-1, n_dim) + 1) * dV
                END IF
            END DO
        ELSE
            ! Standard assembly
            DO i = 1, n_nodes
                dof_idx = elem_dof(i)
                IF (dof_idx > 0 .AND. dof_idx <= SIZE(F_global)) THEN
                    F_global(dof_idx) = F_global(dof_idx) + &
                                       N(i) * load_value(MOD(i-1, n_dim) + 1) * dV
                END IF
            END DO
        END IF
        
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE RT_Asm_AssemLoadOpt

    SUBROUTINE RT_Asm_AssemMass_Structured(in, out)
        !! Assemble element mass matrix into global mass matrix
        !!
        !! Theory:
        !!   Global mass matrix assembly:
        !!     M_ij = Σ_e M_e^{ij}
        !!
        !! Input:
        !!   in%M_element: Element mass matrix M_e
        !!   in%elem_dof: Element DOF indices
        !!
        !! Output:
        !!   out%M_global: Global mass matrix M
        !!   out%status: Error status
        
        TYPE(RT_Asm_AssemMass_In), INTENT(IN) :: in
        TYPE(RT_Asm_AssemMass_Out), INTENT(OUT) :: out

        TYPE(RT_Asm_AssemStiff_In) :: stiff_in
        TYPE(RT_Asm_AssemStiff_Out) :: stiff_out

        stiff_in%K_element = in%M_element
        stiff_in%elem_dof = in%elem_dof
        CALL RT_Asm_AssemStiff_Structured(stiff_in, stiff_out)
        ALLOCATE(out%M_global(SIZE(stiff_out%K_global, 1), SIZE(stiff_out%K_global, 2)))
        out%M_global = stiff_out%K_global
        out%status = stiff_out%status
    END SUBROUTINE RT_Asm_AssemMass_Structured

    SUBROUTINE RT_Asm_AssemDamp_Structured(in, out)
        !! Assemble element damping matrix into global damping matrix
        !!
        !! Theory:
        !!   Global damping matrix assembly:
        !!     C_ij = Σ_e C_e^{ij}
        !!
        !! Input:
        !!   in%C_element: Element damping matrix C_e
        !!   in%elem_dof: Element DOF indices
        !!
        !! Output:
        !!   out%C_global: Global damping matrix C
        !!   out%status: Error status
        
        TYPE(RT_Asm_AssemDamp_In), INTENT(IN) :: in
        TYPE(RT_Asm_AssemDamp_Out), INTENT(OUT) :: out

        TYPE(RT_Asm_AssemStiff_In) :: stiff_in
        TYPE(RT_Asm_AssemStiff_Out) :: stiff_out

        stiff_in%K_element = in%C_element
        stiff_in%elem_dof = in%elem_dof
        CALL RT_Asm_AssemStiff_Structured(stiff_in, stiff_out)
        ALLOCATE(out%C_global(SIZE(stiff_out%K_global, 1), SIZE(stiff_out%K_global, 2)))
        out%C_global = stiff_out%K_global
        out%status = stiff_out%status
    END SUBROUTINE RT_Asm_AssemDamp_Structured

    SUBROUTINE RT_Asm_AssemDampRayleigh_Structured(in, out)
        !! Assemble Rayleigh damping matrix
        !!
        !! Theory:
        !!   Rayleigh damping: C = α * M + β * K
        !!
        !!   where:
        !!     α = mass proportional damping coefficient
        !!     β = stiffness proportional damping coefficient
        !!     M = mass matrix
        !!     K = stiffness matrix
        !!
        !! Input:
        !!   in%M_global: Global mass matrix M
        !!   in%K_global: Global stiffness matrix K
        !!   in%alpha: Mass proportional damping coefficient α
        !!   in%beta: Stiffness proportional damping coefficient β
        !!   in%C_global: Global damping matrix C (inout)
        !!
        !! Output:
        !!   out%C_global: Updated global damping matrix C = αM + βK
        !!   out%status: Error status
        
        TYPE(RT_Asm_AssemDampRayleigh_In), INTENT(IN) :: in
        TYPE(RT_Asm_AssemDampRayleigh_Out), INTENT(OUT) :: out

        INTEGER(i4) :: n_dof, i, j

        CALL init_error_status(out%status)
        ALLOCATE(out%C_global(SIZE(in%C_global, 1), SIZE(in%C_global, 2)))
        out%C_global = in%C_global

        n_dof = SIZE(in%C_global, 1)
        IF (SIZE(in%M_global, 1) /= n_dof .OR. SIZE(in%K_global, 1) /= n_dof) THEN
            out%status%status_code = IF_STATUS_INVALID
            out%status%message = 'RT_Asm_AssemDampRayleigh_Structured: Dimension mismatch'
            RETURN
        END IF

        ! Rayleigh damping: C = α * M + β * K
        DO i = 1, n_dof
            DO j = 1, n_dof
                out%C_global(i, j) = in%alpha * in%M_global(i, j) + in%beta * in%K_global(i, j)
            END DO
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AssemDampRayleigh_Structured

    SUBROUTINE RT_Asm_AssemMassConsist_Structured(in, out)
        !! Assemble consistent mass matrix
        !!
        !! Theory:
        !!   Consistent mass matrix:
        !!     M_ij = ∫_Ω ρ * N_i * N_j dV
        !!
        !!   where:
        !!     ρ = material density
        !!     N_i, N_j = shape functions
        !!     dV = volume element
        !!
        !! Input:
        !!   in%N: Shape functions
        !!   in%density: Material density ρ
        !!   in%detJ: Determinant of Jacobian |J|
        !!   in%weight: Integration weight
        !!   in%n_gauss: Number of Gauss points
        !!   in%elem_dof: Element DOF indices
        !!   in%M_global: Global mass matrix M (inout)
        !!
        !! Output:
        !!   out%M_global: Updated global mass matrix M
        !!   out%status: Error status
        
        TYPE(RT_Asm_AssemMassConsist_In), INTENT(IN) :: in
        TYPE(RT_Asm_AssemMassConsist_Out), INTENT(OUT) :: out

        REAL(wp) :: dV
        INTEGER(i4) :: i, j, n_nodes, row_idx, col_idx

        CALL init_error_status(out%status)
        ALLOCATE(out%M_global(SIZE(in%M_global, 1), SIZE(in%M_global, 2)))
        out%M_global = in%M_global

        n_nodes = SIZE(in%N)
        dV = in%detJ * in%itr%weight

        ! Consistent mass matrix: M_ij = ?ρ * N_i * N_j dV
        DO i = 1, n_nodes
            row_idx = in%elem_dof(i)
            IF (row_idx <= 0 .OR. row_idx > SIZE(out%M_global, 1)) CYCLE
            
            DO j = 1, n_nodes
                col_idx = in%elem_dof(j)
                IF (col_idx <= 0 .OR. col_idx > SIZE(out%M_global, 2)) CYCLE
                
                out%M_global(row_idx, col_idx) = out%M_global(row_idx, col_idx) + &
                                                in%density * in%N(i) * in%N(j) * dV
            END DO
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AssemMassConsist_Structured

    SUBROUTINE RT_Asm_AssemLoadOpt_Structured(in, out)
        !! Assemble load vector (optimized)
        !!
        !! Theory:
        !!   Load vector assembly:
        !!     F_i = ∫_Ω N_i * f dV
        !!
        !!   where:
        !!     N_i = shape function
        !!     f = load value
        !!     dV = volume element
        !!
        !! Input:
        !!   in%N: Shape functions
        !!   in%load_value: Load values
        !!   in%detJ: Determinant of Jacobian |J|
        !!   in%weight: Integration weight
        !!   in%n_gauss: Number of Gauss points
        !!   in%elem_dof: Element DOF indices
        !!   in%use_vectorized: Use vectorized assembly
        !!   in%F_global: Global force vector F (inout)
        !!
        !! Output:
        !!   out%F_global: Updated global force vector F
        !!   out%status: Error status
        
        TYPE(RT_Asm_AssemLoadOpt_In), INTENT(IN) :: in
        TYPE(RT_Asm_AssemLoadOpt_Out), INTENT(OUT) :: out

        REAL(wp) :: dV
        INTEGER(i4) :: i, n_nodes, dof_idx, n_dim

        CALL init_error_status(out%status)
        ALLOCATE(out%F_global(SIZE(in%F_global)))
        out%F_global = in%F_global

        n_nodes = SIZE(in%N)
        n_dim = SIZE(in%load_value)
        dV = in%detJ * in%itr%weight

        ! Vectorized or standard assembly
        DO i = 1, n_nodes
            dof_idx = in%elem_dof(i)
            IF (dof_idx > 0 .AND. dof_idx <= SIZE(out%F_global)) THEN
                out%F_global(dof_idx) = out%F_global(dof_idx) + &
                                       in%N(i) * in%load_value(MOD(i-1, n_dim) + 1) * dV
            END IF
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AssemLoadOpt_Structured

    SUBROUTINE RT_Asm_AssemStiffSparse_Structured(in, out)
        !! Assemble element stiffness matrix into sparse triplet list
        !!
        !! Theory:
        !!   Sparse matrix assembly using triplet format (COO).
        !!   Only non-zero entries are stored.
        !!
        !! Input:
        !!   in%K_element: Element stiffness matrix K_e
        !!   in%elem_dof: Element DOF indices
        !!   in%K_triplets: Triplet list (inout)
        !!
        !! Output:
        !!   out%K_triplets: Updated triplet list
        !!   out%status: Error status
        
        TYPE(RT_Asm_AssemStiffSparse_In), INTENT(IN) :: in
        TYPE(RT_Asm_AssemStiffSparse_Out), INTENT(OUT) :: out

        INTEGER(i4) :: n_dof, i, j, row_idx, col_idx

        CALL init_error_status(out%status)
        out%K_triplets = in%K_triplets

        n_dof = SIZE(in%elem_dof)
        IF (SIZE(in%K_element, 1) /= n_dof .OR. SIZE(in%K_element, 2) /= n_dof) THEN
            out%status%status_code = IF_STATUS_INVALID
            out%status%message = 'RT_Asm_AssemStiffSparse_Structured: Dimension mismatch'
            RETURN
        END IF

        DO i = 1, n_dof
            row_idx = in%elem_dof(i)
            IF (row_idx <= 0) CYCLE
            
            DO j = 1, n_dof
                col_idx = in%elem_dof(j)
                IF (col_idx <= 0) CYCLE
                
                IF (ABS(in%K_element(i, j)) > 1.0e-15_wp) THEN
                    CALL RT_Triplet_Add(out%K_triplets, row_idx, col_idx, in%K_element(i, j))
                END IF
            END DO
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_AssemStiffSparse_Structured

    SUBROUTINE RT_Asm_GetElemDOF_Structured(in, out)
        !! Get element DOF indices
        !!
        !! Theory:
        !!   Computes element DOF indices from node IDs and DOF per node.
        !!   DOF mapping: DOF_i = (node_id - 1) * dof_per_node + local_dof
        !!
        !! Input:
        !!   in%elem_id: Element ID
        !!   in%node_ids: Node IDs
        !!   in%dof_per_node: DOF per node
        !!
        !! Output:
        !!   out%elem_dof: Element DOF indices
        !!   out%status: Error status
        
        TYPE(RT_Asm_GetElemDOF_In), INTENT(IN) :: in
        TYPE(RT_Asm_GetElemDOF_Out), INTENT(OUT) :: out

        INTEGER(i4) :: n_nodes, n_dof, i, j, dof_idx

        CALL init_error_status(out%status)

        n_nodes = SIZE(in%node_ids)
        n_dof = n_nodes * in%pop%dof_per_node

        ! Compute element DOF indices
        dof_idx = 1
        DO i = 1, n_nodes
            DO j = 1, in%pop%dof_per_node
                ! Simplified: assume sequential DOF numbering
                out%elem_dof(dof_idx) = (in%node_ids(i) - 1) * in%pop%dof_per_node + j
                dof_idx = dof_idx + 1
            END DO
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_GetElemDOF_Structured

    SUBROUTINE RT_Asm_ScatterElemToGlob_Structured(in, out)
        !! Scatter element vector to global vector
        !!
        !! Theory:
        !!   Maps element vector values to global vector using DOF mapping:
        !!     v_global[dof_i] = v_element[i]
        !!
        !! Input:
        !!   in%elem_vec: Element vector
        !!   in%elem_dof: Element DOF indices
        !!   in%global_vec: Global vector (inout)
        !!
        !! Output:
        !!   out%global_vec: Updated global vector
        !!   out%status: Error status
        
        TYPE(RT_Asm_ScatterElemToGlob_In), INTENT(IN) :: in
        TYPE(RT_Asm_ScatterElemToGlob_Out), INTENT(OUT) :: out

        INTEGER(i4) :: n_dof, i, dof_idx

        CALL init_error_status(out%status)
        ALLOCATE(out%global_vec(SIZE(in%global_vec)))
        out%global_vec = in%global_vec

        n_dof = SIZE(in%elem_vec)
        IF (SIZE(in%elem_dof) < n_dof) THEN
            out%status%status_code = IF_STATUS_INVALID
            out%status%message = 'RT_Asm_ScatterElemToGlob_Structured: Dimension mismatch'
            RETURN
        END IF

        ! Scatter element values to global vector
        DO i = 1, n_dof
            dof_idx = in%elem_dof(i)
            IF (dof_idx > 0 .AND. dof_idx <= SIZE(out%global_vec)) THEN
                out%global_vec(dof_idx) = in%elem_vec(i)
            END IF
        END DO

        out%status%status_code = IF_STATUS_OK
    END SUBROUTINE RT_Asm_ScatterElemToGlob_Structured

    ! ==========================================================================
    ! Legacy Interfaces (deprecated)
    ! ==========================================================================
    !> @deprecated Use RT_Asm_AssemDamp_Structured instead
    SUBROUTINE RT_Asm_AssemDamp(C_global, C_element, elem_dof, status)
        REAL(wp), INTENT(INOUT) :: C_global(:,:)
        REAL(wp), INTENT(IN) :: C_element(:,:)
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AssemDamp_In) :: in
        TYPE(RT_Asm_AssemDamp_Out) :: out

        ALLOCATE(in%C_element(SIZE(C_element, 1), SIZE(C_element, 2)))
        in%C_element = C_element
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        CALL RT_Asm_AssemDamp_Structured(in, out)
        C_global = out%C_global
        status = out%status
    END SUBROUTINE RT_Asm_AssemDamp

    !> @deprecated Use RT_Asm_AssemDampRayleigh_Structured instead
    SUBROUTINE RT_Asm_AssemDampRayleigh(C_global, M_global, K_global, &
                                               alpha, beta, status)
        REAL(wp), INTENT(INOUT) :: C_global(:,:)
        REAL(wp), INTENT(IN) :: M_global(:,:)
        REAL(wp), INTENT(IN) :: K_global(:,:)
        REAL(wp), INTENT(IN) :: alpha, beta
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AssemDampRayleigh_In) :: in
        TYPE(RT_Asm_AssemDampRayleigh_Out) :: out

        ALLOCATE(in%M_global(SIZE(M_global, 1), SIZE(M_global, 2)))
        in%M_global = M_global
        ALLOCATE(in%K_global(SIZE(K_global, 1), SIZE(K_global, 2)))
        in%K_global = K_global
        in%alpha = alpha
        in%beta = beta
        ALLOCATE(in%C_global(SIZE(C_global, 1), SIZE(C_global, 2)))
        in%C_global = C_global
        CALL RT_Asm_AssemDampRayleigh_Structured(in, out)
        C_global = out%C_global
        status = out%status
    END SUBROUTINE RT_Asm_AssemDampRayleigh

    !> @deprecated Use RT_Asm_AssemMass_Structured instead
    SUBROUTINE RT_Asm_AssemMass(M_global, M_element, elem_dof, status)
        REAL(wp), INTENT(INOUT) :: M_global(:,:)
        REAL(wp), INTENT(IN) :: M_element(:,:)
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AssemMass_In) :: in
        TYPE(RT_Asm_AssemMass_Out) :: out

        ALLOCATE(in%M_element(SIZE(M_element, 1), SIZE(M_element, 2)))
        in%M_element = M_element
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        CALL RT_Asm_AssemMass_Structured(in, out)
        M_global = out%M_global
        status = out%status
    END SUBROUTINE RT_Asm_AssemMass

    !> @deprecated Use RT_Asm_AssemMassConsist_Structured instead
    SUBROUTINE RT_Asm_AssemMassConsist(M_global, N, density, detJ, &
                                             weight, n_gauss, elem_dof, status)
        REAL(wp), INTENT(INOUT) :: M_global(:,:)
        REAL(wp), INTENT(IN) :: N(:)
        REAL(wp), INTENT(IN) :: density
        REAL(wp), INTENT(IN) :: detJ, weight
        INTEGER(i4), INTENT(IN) :: n_gauss
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AssemMassConsist_In) :: in
        TYPE(RT_Asm_AssemMassConsist_Out) :: out

        ALLOCATE(in%N(SIZE(N)))
        in%N = N
        in%density = density
        in%detJ = detJ
        in%itr%weight = weight
        in%n_gauss = n_gauss
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        ALLOCATE(in%M_global(SIZE(M_global, 1), SIZE(M_global, 2)))
        in%M_global = M_global
        CALL RT_Asm_AssemMassConsist_Structured(in, out)
        M_global = out%M_global
        status = out%status
    END SUBROUTINE RT_Asm_AssemMassConsist

    !> @deprecated Use RT_Asm_AssemResid_Structured instead
    SUBROUTINE RT_Asm_AssemResid(R_global, R_element, elem_dof, status)
        REAL(wp), INTENT(INOUT) :: R_global(:)
        REAL(wp), INTENT(IN) :: R_element(:)
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AssemResid_In) :: in
        TYPE(RT_Asm_AssemResid_Out) :: out

        ALLOCATE(in%R_element(SIZE(R_element)))
        in%R_element = R_element
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        CALL RT_Asm_AssemResid_Structured(in, out)
        R_global = out%R_global
        status = out%status
    END SUBROUTINE RT_Asm_AssemResid

    !> @deprecated Use RT_Asm_AssemStiff_Structured instead
    SUBROUTINE RT_Asm_AssemStiff(K_global, K_element, elem_dof, status)
        REAL(wp), INTENT(INOUT) :: K_global(:,:)
        REAL(wp), INTENT(IN) :: K_element(:,:)
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AssemStiff_In) :: in
        TYPE(RT_Asm_AssemStiff_Out) :: out

        ALLOCATE(in%K_element(SIZE(K_element, 1), SIZE(K_element, 2)))
        in%K_element = K_element
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        CALL RT_Asm_AssemStiff_Structured(in, out)
        K_global = out%K_global
        status = out%status
    END SUBROUTINE RT_Asm_AssemStiff

    !> @deprecated Use RT_Asm_AssemStiffSparse_Structured instead
    SUBROUTINE RT_Asm_AssemStiffSparse(K_triplets, K_element, elem_dof, &
                                               status)
        TYPE(RT_TripletList), INTENT(INOUT) :: K_triplets
        REAL(wp), INTENT(IN) :: K_element(:,:)
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AssemStiffSparse_In) :: in
        TYPE(RT_Asm_AssemStiffSparse_Out) :: out

        ALLOCATE(in%K_element(SIZE(K_element, 1), SIZE(K_element, 2)))
        in%K_element = K_element
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        in%K_triplets = K_triplets
        CALL RT_Asm_AssemStiffSparse_Structured(in, out)
        K_triplets = out%K_triplets
        status = out%status
    END SUBROUTINE RT_Asm_AssemStiffSparse

    !> @deprecated Use RT_Asm_GetElemDOF_Structured instead
    SUBROUTINE RT_Asm_GetElemDOF(elem_id, node_ids, dof_per_node, elem_dof, status)
        INTEGER(i4), INTENT(IN) :: elem_id
        INTEGER(i4), INTENT(IN) :: node_ids(:)
        INTEGER(i4), INTENT(IN) :: dof_per_node
        INTEGER(i4), INTENT(OUT) :: elem_dof(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_GetElemDOF_In) :: in
        TYPE(RT_Asm_GetElemDOF_Out) :: out

        in%elem_id = elem_id
        ALLOCATE(in%node_ids(SIZE(node_ids)))
        in%node_ids = node_ids
        in%pop%dof_per_node = dof_per_node
        CALL RT_Asm_GetElemDOF_Structured(in, out)
        elem_dof(1:SIZE(out%elem_dof)) = out%elem_dof
        status = out%status
    END SUBROUTINE RT_Asm_GetElemDOF

    !> @deprecated Use RT_Asm_ScatterElemToGlob_Structured instead
    SUBROUTINE RT_Asm_ScatterElemToGlob(elem_vec, elem_dof, global_vec, status)
        REAL(wp), INTENT(IN) :: elem_vec(:)
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        REAL(wp), INTENT(INOUT) :: global_vec(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_ScatterElemToGlob_In) :: in
        TYPE(RT_Asm_ScatterElemToGlob_Out) :: out

        ALLOCATE(in%elem_vec(SIZE(elem_vec)))
        in%elem_vec = elem_vec
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        ALLOCATE(in%global_vec(SIZE(global_vec)))
        in%global_vec = global_vec
        CALL RT_Asm_ScatterElemToGlob_Structured(in, out)
        global_vec = out%global_vec
        status = out%status
    END SUBROUTINE RT_Asm_ScatterElemToGlob

    !> @deprecated Use RT_Asm_AssemLoadOpt_Structured instead
    SUBROUTINE RT_Asm_AssemLoadOpt(F_global, N, load_value, detJ, &
                                            weight, n_gauss, elem_dof, &
                                            use_vectorized, status)
        REAL(wp), INTENT(INOUT) :: F_global(:)
        REAL(wp), INTENT(IN) :: N(:)
        REAL(wp), INTENT(IN) :: load_value(:)
        REAL(wp), INTENT(IN) :: detJ, weight
        INTEGER(i4), INTENT(IN) :: n_gauss
        INTEGER(i4), INTENT(IN) :: elem_dof(:)
        LOGICAL, INTENT(IN) :: use_vectorized
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(RT_Asm_AssemLoadOpt_In) :: in
        TYPE(RT_Asm_AssemLoadOpt_Out) :: out

        ALLOCATE(in%N(SIZE(N)))
        in%N = N
        ALLOCATE(in%load_value(SIZE(load_value)))
        in%load_value = load_value
        in%detJ = detJ
        in%itr%weight = weight
        in%n_gauss = n_gauss
        ALLOCATE(in%elem_dof(SIZE(elem_dof)))
        in%elem_dof = elem_dof
        in%use_vectorized = use_vectorized
        ALLOCATE(in%F_global(SIZE(F_global)))
        in%F_global = F_global
        CALL RT_Asm_AssemLoadOpt_Structured(in, out)
        F_global = out%F_global
        status = out%status
    END SUBROUTINE RT_Asm_AssemLoadOpt
END MODULE RT_Asm_Mgr