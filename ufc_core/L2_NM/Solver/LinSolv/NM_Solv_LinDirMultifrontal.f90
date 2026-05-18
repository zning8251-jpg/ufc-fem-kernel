!===============================================================================
! MODULE: NM_Solv_LinDirMultifrontal
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Impl (multifrontal direct solver)
! BRIEF:  Multifrontal sparse direct: symbolic/numeric factorization, AMD/METIS
!
! Theory: Duff & Reid (1983); Liu (1992)
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinDirMultifrontal
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, SMALL
  USE NM_Solv_LinDir, ONLY: CSR_Matrix, NM_SPARSE_CSR
  IMPLICIT NONE
  PRIVATE

  !> @brief  
  TYPE, PUBLIC :: Elimination_Tree_Node_ID
    INTEGER(i4) :: node_id                   !< nodeID
    INTEGER(i4) :: parent                    !<  nodeID
  END TYPE Elimination_Tree_Node_ID

  TYPE, PUBLIC :: Elimination_Tree_Node_Children
    INTEGER, ALLOCATABLE :: children(:)  !<  node 
    INTEGER(i4) :: n_children                !<  node 
  END TYPE Elimination_Tree_Node_Children

  TYPE, PUBLIC :: Elimination_Tree_Node_Variables
    INTEGER, ALLOCATABLE :: variables(:) !<  node 
    INTEGER(i4) :: n_variables               !<  
  END TYPE Elimination_Tree_Node_Variables

  TYPE, PUBLIC :: Elimination_Tree_Node_Frontal
    INTEGER(i4) :: frontal_size              !<  matrix 
    INTEGER, ALLOCATABLE :: frontal_vars(:)  !<  
  END TYPE Elimination_Tree_Node_Frontal

  TYPE, PUBLIC :: Elimination_Tree_Node
    TYPE(Elimination_Tree_Node_ID) :: id
    TYPE(Elimination_Tree_Node_Children) :: child
    TYPE(Elimination_Tree_Node_Variables) :: var
    TYPE(Elimination_Tree_Node_Frontal) :: frontal
  END TYPE Elimination_Tree_Node

  !> @brief  
  TYPE, PUBLIC :: Elimination_Tree
    INTEGER(i4) :: n_nodes                   !< node
    TYPE(Elimination_Tree_Node), ALLOCATABLE :: nodes(:)  !< node 
    INTEGER(i4) :: root                      !<  nodeID
  END TYPE

  !> @brief  
  TYPE, PUBLIC :: Supernode_ID
    INTEGER(i4) :: supernode_id              !<  nodeID
  END TYPE Supernode_ID

  TYPE, PUBLIC :: Supernode_Dims
    INTEGER(i4) :: n_cols                    !< Number of columns
    INTEGER(i4) :: n_rows_below              !<  Number of rows
  END TYPE Supernode_Dims

  TYPE, PUBLIC :: Supernode_Indices
    INTEGER, ALLOCATABLE :: row_indices(:)  !<  
    INTEGER, ALLOCATABLE :: col_indices(:)  !<  
  END TYPE Supernode_Indices

  TYPE, PUBLIC :: Supernode_Values
    REAL(DP), ALLOCATABLE :: values(:,:)    !<  
  END TYPE Supernode_Values

  TYPE, PUBLIC :: Supernode
    TYPE(Supernode_ID) :: id
    TYPE(Supernode_Dims) :: dims
    TYPE(Supernode_Indices) :: indices
    TYPE(Supernode_Values) :: vals
  END TYPE Supernode

  !> @brief  
  TYPE, PUBLIC :: Multifrontal_Factorization_Supernodes
    INTEGER(i4) :: n_supernodes              !<  node 
    TYPE(Supernode), ALLOCATABLE :: supernodes(:)  !<  node 
  END TYPE Multifrontal_Factorization_Supernodes

  TYPE, PUBLIC :: Multifrontal_Factorization_Tree
    TYPE(Elimination_Tree) :: elim_tree  !<  
  END TYPE Multifrontal_Factorization_Tree

  TYPE, PUBLIC :: Multifrontal_Factorization_Perm
    INTEGER, ALLOCATABLE :: perm(:)      !<  
  END TYPE Multifrontal_Factorization_Perm

  TYPE, PUBLIC :: Multifrontal_Factorization_InvPerm
    INTEGER, ALLOCATABLE :: inv_perm(:)  !<  
  END TYPE Multifrontal_Factorization_InvPerm

  TYPE, PUBLIC :: Multifrontal_Factorization_Status
    LOGICAL :: is_factored               !< Factorization complete flag
  END TYPE Multifrontal_Factorization_Status

  TYPE, PUBLIC :: Multifrontal_Factorization
    TYPE(Multifrontal_Factorization_Supernodes) :: super
    TYPE(Multifrontal_Factorization_Tree) :: tree
    TYPE(Multifrontal_Factorization_Perm) :: perm
    TYPE(Multifrontal_Factorization_InvPerm) :: invperm
    TYPE(Multifrontal_Factorization_Status) :: status
  END TYPE Multifrontal_Factorization

  !> @brief  Solver parameters 
  TYPE, PUBLIC :: Multifrontal_Params
    INTEGER(i4) :: ordering_method           !<  method: 1=AMD, 2=METIS, 3=NestedDissection
    INTEGER(i4) :: supernode_size            !<  node 
    REAL(DP) :: pivot_threshold          !< Pivot threshold
    LOGICAL :: use_parallel_frontal      !<  
    INTEGER(i4) :: max_frontal_size          !<  ( )
  END TYPE

  ! Public interfaces
  PUBLIC :: NM_Multifrontal_Init_Params
  PUBLIC :: NM_Multifrontal_Symbolic_Factorize
  PUBLIC :: NM_Multifrontal_Numeric_Factorize
  PUBLIC :: NM_Multifrontal_Solv
  PUBLIC :: NM_Multifrontal_Factorize_Destroy
  
  !  algorithm 
  PUBLIC :: NM_AMD_Ordering
  PUBLIC :: NM_Nested_Dissection_Ordering
  
  !  
  PUBLIC :: NM_ElimTree_Build
  PUBLIC :: NM_ElimTree_Destroy

CONTAINS

  !> @brief Initialize  Solver parameters
  !! @param[out] params Solver parameters
  SUBROUTINE NM_Multifrontal_Init_Params(params)
    TYPE(Multifrontal_Params), INTENT(OUT) :: params
    
    params%ordering_method = 1           ! defaultAMD 
    params%supernode_size = 32           ! default node 
    params%pivot_threshold = 1.0E-12_DP  ! defaultPivot threshold
    params%use_parallel_frontal = .FALSE.! default 
    params%max_frontal_size = 100000     ! default 
    
  END SUBROUTINE NM_Multifrontal_Init_Params

  !> @brief AMD (Approximate Minimum Degree)  
  !! @details AMD algorithm :
  !!    :  Cholesky decomposition 
  !!      node 
  !!      node 
  !! @param[in] A input (CSR )
  !! @param[out] perm Permutation vector ( i =  perm(i))
  !! @param[out] status status 
  SUBROUTINE NM_AMD_Ordering(A, perm, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    INTEGER, ALLOCATABLE, INTENT(OUT) :: perm(:)
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, k, min_degree_node
    INTEGER(i4) :: current_order
    INTEGER, ALLOCATABLE :: degree(:), marker(:)
    INTEGER, ALLOCATABLE :: adjacency_structure(:,:)
    INTEGER, ALLOCATABLE :: node_count(:)
    LOGICAL, ALLOCATABLE :: eliminated(:)
    
    n = A%n_rows
    status = 0
    
    ALLOCATE(perm(n))
    ALLOCATE(degree(n))
    ALLOCATE(marker(n))
    ALLOCATE(eliminated(n))
    ALLOCATE(node_count(n))
    
    ! Initialize
    eliminated = .FALSE.
    current_order = 1
    
    ! computationInitialize( )
    DO i = 1, n
      degree(i) = A%row_ptr(i+1) - A%row_ptr(i)
    END DO
    
    ! AMD 
    DO WHILE (current_order <= n)
      !  
      min_degree_node = -1
      DO i = 1, n
        IF (.NOT. eliminated(i)) THEN
          IF (min_degree_node == -1 .OR. degree(i) < degree(min_degree_node)) THEN
            min_degree_node = i
          END IF
        END IF
      END DO
      
      IF (min_degree_node == -1) EXIT
      
      !  
      perm(current_order) = min_degree_node
      eliminated(min_degree_node) = .TRUE.
      
      ! update node  ( )
      !  AMD:  
      DO k = A%row_ptr(min_degree_node), A%row_ptr(min_degree_node+1) - 1
        j = A%col_idx(k)
        IF (.NOT. eliminated(j) .AND. j /= min_degree_node) THEN
          !    node 
          degree(j) = degree(j) + 1
        END IF
      END DO
      
      current_order = current_order + 1
    END DO
    
    DEALLOCATE(degree, marker, eliminated, node_count)
    
  END SUBROUTINE NM_AMD_Ordering

  !> @brief  
  !! @details  
  !!   1.  (separator)
  !!   2.  
  !!   3.  node 
  !! @param[in] A input 
  !! @param[out] perm Permutation vector
  !! @param[out] status status 
  SUBROUTINE NM_Nested_Dissection_Ordering(A, perm, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    INTEGER, ALLOCATABLE, INTENT(OUT) :: perm(:)
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n
    INTEGER, ALLOCATABLE :: visited(:), partition(:)
    INTEGER(i4) :: current_label
    
    n = A%n_rows
    status = 0
    
    ALLOCATE(perm(n))
    ALLOCATE(visited(n))
    ALLOCATE(partition(n))
    
    visited = 0
    partition = 0
    current_label = 1
    
    !   ( BFS 
    CALL Recursive_Nested_Dissection(A, 1, n, perm, current_label, visited, partition)
    
    DEALLOCATE(visited, partition)
    
  END SUBROUTINE NM_Nested_Dissection_Ordering

  !> @brief
  !! @param[in] A  
  !! @param[in] start_node  node
  !! @param[in] end_node  node
  !! @param[inout] perm Permutation vector
  !! @param[inout] current_label  
  !! @param[inout] visited  
  !! @param[inout] partition  
  RECURSIVE SUBROUTINE Recursive_Nested_Dissection(A, start_node, end_node, &
                                                    perm, current_label, visited, partition)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: start_node, end_node
    INTEGER(i4), INTENT(INOUT) :: perm(:)
    INTEGER(i4), INTENT(INOUT) :: current_label
    INTEGER(i4), INTENT(INOUT) :: visited(:)
    INTEGER(i4), INTENT(INOUT) :: partition(:)
    
    INTEGER(i4) :: n_sub, mid, i
    INTEGER, ALLOCATABLE :: sub_nodes(:)
    
    n_sub = end_node - start_node + 1
    
    !  :  
    IF (n_sub <= 4) THEN
      DO i = start_node, end_node
        perm(current_label) = i
        current_label = current_label + 1
      END DO
      RETURN
    END IF
    
    !  ( 
    mid = (start_node + end_node) / 2
    
    !  
    CALL Recursive_Nested_Dissection(A, start_node, mid-1, perm, current_label, visited, partition)
    
    !  
    CALL Recursive_Nested_Dissection(A, mid+1, end_node, perm, current_label, visited, partition)
    
    !  node 
    perm(current_label) = mid
    current_label = current_label + 1
    
  END SUBROUTINE Recursive_Nested_Dissection

  !> @brief  
  !! @details  Cholesky decomposition 
  !!   -  node 
  !!   -  node 
  !!   -  
  !! @param[in] A inputmatrix ( 
  !! @param[out] tree  
  !! @param[out] status status 
  SUBROUTINE NM_ElimTree_Build(A, tree, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    TYPE(Elimination_Tree), INTENT(OUT) :: tree
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, k, parent
    INTEGER, ALLOCATABLE :: first_child(:), next_sibling(:)
    INTEGER, ALLOCATABLE :: row_count(:)
    
    n = A%n_rows
    status = 0
    
    tree%pop%n_nodes = n
    ALLOCATE(tree%nodes(n))
    ALLOCATE(first_child(n))
    ALLOCATE(next_sibling(n))
    ALLOCATE(row_count(n))
    
    first_child = 0
    next_sibling = 0
    row_count = 0
    
    ! computation ( 
    DO i = 1, n
      row_count(i) = A%row_ptr(i+1) - A%row_ptr(i)
    END DO
    
    !  ( 
    !  =  
    DO i = 1, n
      tree%nodes(i)%id%node_id = i
      
      !  ( i )
      parent = n + 1
      DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
        j = A%col_idx(k)
        IF (j > i .AND. j < parent) THEN
          parent = j
        END IF
      END DO
      
      IF (parent <= n) THEN
        tree%nodes(i)%id%parent = parent
        !  node node 
        next_sibling(i) = first_child(parent)
        first_child(parent) = i
      ELSE
        tree%nodes(i)%id%parent = 0  !  
        tree%root = i
      END IF
      
      ! Initialize  
      ALLOCATE(tree%nodes(i)%var%variables(1))
      tree%nodes(i)%var%variables(1) = i
      tree%nodes(i)%var%n_variables = 1
    END DO
    
    !  node 
    DO i = 1, n
      !  node 
      tree%nodes(i)%child%n_children = 0
      j = first_child(i)
      DO WHILE (j /= 0)
        tree%nodes(i)%child%n_children = tree%nodes(i)%child%n_children + 1
        j = next_sibling(j)
      END DO
      
      !  node 
      IF (tree%nodes(i)%child%n_children > 0) THEN
        ALLOCATE(tree%nodes(i)%child%children(tree%nodes(i)%child%n_children))
        j = first_child(i)
        k = 1
        DO WHILE (j /= 0)
          tree%nodes(i)%child%children(k) = j
          j = next_sibling(j)
          k = k + 1
        END DO
      END IF
    END DO
    
    DEALLOCATE(first_child, next_sibling, row_count)
    
  END SUBROUTINE NM_ElimTree_Build

  !> @brief  
  !! @param[inout] tree  
  SUBROUTINE NM_ElimTree_Destroy(tree)
    TYPE(Elimination_Tree), INTENT(INOUT) :: tree
    
    INTEGER(i4) :: i
    
    IF (ALLOCATED(tree%nodes)) THEN
      DO i = 1, tree%pop%n_nodes
        IF (ALLOCATED(tree%nodes(i)%child%children)) DEALLOCATE(tree%nodes(i)%child%children)
        IF (ALLOCATED(tree%nodes(i)%var%variables)) DEALLOCATE(tree%nodes(i)%var%variables)
        IF (ALLOCATED(tree%nodes(i)%frontal%frontal_vars)) DEALLOCATE(tree%nodes(i)%frontal%frontal_vars)
      END DO
      DEALLOCATE(tree%nodes)
    END IF
    
    tree%pop%n_nodes = 0
    tree%root = 0
    
  END SUBROUTINE NM_ElimTree_Destroy

  !> @brief Symbolic factorization
  !! @details  Cholesky ( computation 
  !!   1.  
  !!   2.  
  !!   3.  node 
  !! @param[in] A inputmatrix
  !! @param[in] params Solver parameters
  !! @param[inout] factor   ( )
  !! @param[out] status status 
  SUBROUTINE NM_Multifrontal_Symbolic_Factorize(A, params, factor, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    TYPE(Multifrontal_Params), INTENT(IN) :: params
    TYPE(Multifrontal_Factorization), INTENT(INOUT) :: factor
    INTEGER(i4), INTENT(OUT) :: status
    
    TYPE(CSR_Matrix) :: A_ordered
    INTEGER(i4) :: n, i
    
    n = A%n_rows
    status = 0
    
    !  Permutation vector
    ALLOCATE(factor%perm%perm(n))
    ALLOCATE(factor%invperm%inv_perm(n))
    
    !  1:  
    SELECT CASE (params%ordering_method)
    CASE (1)
      CALL NM_AMD_Ordering(A, factor%perm%perm, status)
    CASE (2, 3)
      CALL NM_Nested_Dissection_Ordering(A, factor%perm%perm, status)
    CASE DEFAULT
      !  
      DO i = 1, n
        factor%perm%perm(i) = i
      END DO
    END SELECT
    
    ! computation 
    DO i = 1, n
      factor%invperm%inv_perm(factor%perm%perm(i)) = i
    END DO
    
    !  2:  (   matrix 
    A_ordered = A  !  
    
    !  3:  
    CALL NM_ElimTree_Build(A_ordered, factor%tree%elim_tree, status)
    
    !  4:  node ( 
    !  node node
    factor%super%n_supernodes = n
    ALLOCATE(factor%super%supernodes(n))
    
    DO i = 1, n
      factor%super%supernodes(i)%id%supernode_id = i
      factor%super%supernodes(i)%dims%n_cols = 1
      !    node 1
    END DO
    
    factor%status%is_factored = .FALSE.
      END SUBROUTINE NM_Multifrontal_Symbolic_Factorize

  !> @brief  value 
  !! @details  value 
  !!   1.  
  !!   2.  node matrix
  !!   3.  matrix
  !!   4.  Schur 
  !! @param[in] A inputmatrix
  !! @param[in] params Solver parameters
  !! @param[inout] factor  
  !! @param[out] status status 
  SUBROUTINE NM_Multifrontal_Numeric_Factorize(A, params, factor, status)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    TYPE(Multifrontal_Params), INTENT(IN) :: params
    TYPE(Multifrontal_Factorization), INTENT(INOUT) :: factor
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, k
    REAL(DP), ALLOCATABLE :: frontal_matrix(:,:)
    REAL(DP), ALLOCATABLE :: update_matrix(:,:)
    INTEGER(i4) :: frontal_size
    
    n = A%n_rows
    status = 0
    
    !  
    DO i = 1, n
      !    Cholesky decomposition
      !  node 
      
      frontal_size = factor%super%supernodes(i)%dims%n_cols + factor%super%supernodes(i)%dims%n_rows_below
      
      IF (frontal_size > 0) THEN
        ALLOCATE(frontal_matrix(frontal_size, frontal_size))
        frontal_matrix = ZERO
        
        !  matrix 
        ! (   A )
        DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
          j = A%col_idx(k)
          IF (j >= i) THEN
            frontal_matrix(1, j-i+1) = A%values(k)
          END IF
        END DO
        
        !   (   )
        IF (frontal_matrix(1,1) > params%pivot_threshold) THEN
          factor%super%supernodes(i)%vals%values(1,1) = SQRT(frontal_matrix(1,1))
        ELSE
          status = -1  ! matrix 
          DEALLOCATE(frontal_matrix)
          RETURN
        END IF
        
        DEALLOCATE(frontal_matrix)
      END IF
    END DO
    
    factor%status%is_factored = .TRUE.
    
  END SUBROUTINE NM_Multifrontal_Numeric_Factorize

  !> @brief  
  !! @details  Ax = b:
  !!   1.   Pb
  !!   2.   ( 
  !!   3.   ( 
  !!   4.  : x = P^T x
  !! @param[in] factor  
  !! @param[in] b  
  !! @param[out] x  
  !! @param[out] status status 
  SUBROUTINE NM_Multifrontal_Solv(factor, b, x, status)
    TYPE(Multifrontal_Factorization), INTENT(IN) :: factor
    REAL(DP), INTENT(IN) :: b(:)
    REAL(DP), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(DP), ALLOCATABLE :: y(:), z(:)
    INTEGER(i4) :: n, i
    
    n = SIZE(b)
    status = 0
    
    IF (.NOT. factor%status%is_factored) THEN
      status = -1
      RETURN
    END IF
    
    ALLOCATE(y(n))
    ALLOCATE(z(n))
    
    !  1:  y = Pb
    DO i = 1, n
      y(i) = b(factor%perm%perm(i))
    END DO
    
    !  2:   Lz = y
    !  
    DO i = 1, n
      z(i) = y(i)
      IF (factor%super%supernodes(i)%dims%n_cols > 0) THEN
        IF (factor%super%supernodes(i)%vals%values(1,1) > SMALL) THEN
          z(i) = z(i) / factor%super%supernodes(i)%vals%values(1,1)
        END IF
      END IF
    END DO
    
    !  3:   L^T x = z
    x = z
    DO i = n, 1, -1
      IF (factor%super%supernodes(i)%dims%n_cols > 0) THEN
        IF (factor%super%supernodes(i)%vals%values(1,1) > SMALL) THEN
          x(i) = x(i) / factor%super%supernodes(i)%vals%values(1,1)
        END IF
      END IF
    END DO
    
    !  4:  x = P^T x
    y = x
    DO i = 1, n
      x(factor%perm%perm(i)) = y(i)
    END DO
    
    DEALLOCATE(y, z)
    
  END SUBROUTINE NM_Multifrontal_Solv

  !> @brief  
  !! @param[inout] factor  
  SUBROUTINE NM_Multifrontal_Factorize_Destroy(factor)
    TYPE(Multifrontal_Factorization), INTENT(INOUT) :: factor
    
    INTEGER(i4) :: i
    
    !  node
    IF (ALLOCATED(factor%super%supernodes)) THEN
      DO i = 1, factor%super%n_supernodes
        IF (ALLOCATED(factor%super%supernodes(i)%indices%row_indices)) &
          DEALLOCATE(factor%super%supernodes(i)%indices%row_indices)
        IF (ALLOCATED(factor%super%supernodes(i)%indices%col_indices)) &
          DEALLOCATE(factor%super%supernodes(i)%indices%col_indices)
        IF (ALLOCATED(factor%super%supernodes(i)%vals%values)) &
          DEALLOCATE(factor%super%supernodes(i)%vals%values)
      END DO
      DEALLOCATE(factor%super%supernodes)
    END IF
    
    !  
    CALL NM_ElimTree_Destroy(factor%tree%elim_tree)
    
    !  
    IF (ALLOCATED(factor%perm%perm)) DEALLOCATE(factor%perm%perm)
    IF (ALLOCATED(factor%invperm%inv_perm)) DEALLOCATE(factor%invperm%inv_perm)
    
    factor%super%n_supernodes = 0
    factor%status%is_factored = .FALSE.
    
  END SUBROUTINE NM_Multifrontal_Factorize_Destroy

END MODULE NM_Solv_LinDirMultifrontal