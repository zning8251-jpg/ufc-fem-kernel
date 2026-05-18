!===============================================================================
! MODULE: MD_Constr_Brg
! LAYER:  L3_MD
! DOMAIN: Constraint
! ROLE:   Brg — Bridge surface/elset names to node lists for L4/L5
! BRIEF:  Resolve Tie/Coupling/Rigid surface names to slave-master node pairs.
! PILOT:  Desc surface/elset → assembly lookup → filled pairs; no duplicate entry API.
!===============================================================================
!
! Procedures:
!   [P1] MD_TieConstraint_TryResolveSurfaces       — Tie slave-master pairing
!   [P1] MD_CplConstraint_TryResolveSurfaceOrElset  — Coupling node resolution
!   [P1] MD_RigidBody_TryResolveFromAssembly        — Rigid body node resolution
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Const | Role:Brg | FuncSet:Brg | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Constraint/CONTRACT.md

MODULE MD_Constr_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Constr_Def, ONLY: TieConstraintDef, CplConstraintDef, RigidBodyDef, &
      COUPLING_TYPE_KINEMATIC, COUPLING_TYPE_DISTRIBUTING
  USE MD_Asm_Mgr, ONLY: MD_Assembly_GetSurfaceByName_Idx, MD_Asm_GetSurfaceByName_Arg, &
      MD_Assembly_GetElemSetByName_Idx, MD_Asm_GetElemSetByName_Arg, &
      MD_Assembly_GetNodeSetByName_Idx, MD_Asm_GetNodeSetByName_Arg
  USE MD_Mesh_Domain, ONLY: MD_Mesh_GetElemConnect_Idx, MD_Mesh_GetElemConnect_Arg, &
      MD_Mesh_GetNodeCoords_Idx, MD_Mesh_GetNodeCoords_Arg
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: MD_SURF_BRIDGE_MAX_NODES = 8192_i4

  PUBLIC :: MD_TieConstraint_TryResolveSurfaces
  PUBLIC :: MD_CplConstraint_TryResolveSurfaceOrElset
  PUBLIC :: MD_RigidBody_TryResolveFromAssembly

CONTAINS

  !----------------------------------------------------------------------------
  SUBROUTINE push_unique(list, n, nid, overflow)
    INTEGER(i4), INTENT(INOUT) :: list(:)
    INTEGER(i4), INTENT(INOUT) :: n
    INTEGER(i4), INTENT(IN) :: nid
    LOGICAL, INTENT(OUT) :: overflow
    INTEGER(i4) :: j
    overflow = .FALSE.
    IF (nid < 1_i4) RETURN
    DO j = 1, n
      IF (list(j) == nid) RETURN
    END DO
    IF (n >= SIZE(list)) THEN
      overflow = .TRUE.
      RETURN
    END IF
    n = n + 1_i4
    list(n) = nid
  END SUBROUTINE push_unique

  !----------------------------------------------------------------------------
  SUBROUTINE sort_nodes(a, n)
    INTEGER(i4), INTENT(INOUT) :: a(:)
    INTEGER(i4), INTENT(IN) :: n
    INTEGER(i4) :: i, j, t
    DO i = 2, n
      t = a(i)
      j = i
      DO WHILE (j > 1 .AND. a(j - 1) > t)
        a(j) = a(j - 1)
        j = j - 1
      END DO
      a(j) = t
    END DO
  END SUBROUTINE sort_nodes

  !----------------------------------------------------------------------------
  SUBROUTINE MD_SurfaceDef_CollectNodes(elem_ids, n_faces, nodes, nn, status)
    INTEGER(i4), INTENT(IN) :: elem_ids(:)
    INTEGER(i4), INTENT(IN) :: n_faces
    INTEGER(i4), INTENT(OUT) :: nodes(MD_SURF_BRIDGE_MAX_NODES)
    INTEGER(i4), INTENT(OUT) :: nn
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Mesh_GetElemConnect_Arg) :: ec
    INTEGER(i4) :: i, k, eidx
    LOGICAL :: ov

    CALL init_error_status(status)
    nn = 0_i4
    nodes = 0_i4
    IF (n_faces < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_SurfaceDef_CollectNodes: empty surface'
      RETURN
    END IF
    DO i = 1, n_faces
      IF (i > SIZE(elem_ids)) EXIT
      eidx = elem_ids(i)
      IF (eidx < 1_i4) CYCLE
      CALL MD_Mesh_GetElemConnect_Idx(eidx, ec, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      DO k = 1, ec%npe
        CALL push_unique(nodes, nn, INT(ec%connect(k), i4), ov)
        IF (ov) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_SurfaceDef_CollectNodes: node cap exceeded (increase MD_SURF_BRIDGE_MAX_NODES)'
          RETURN
        END IF
      END DO
    END DO
    IF (nn < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_SurfaceDef_CollectNodes: no nodes collected'
      RETURN
    END IF
    CALL sort_nodes(nodes, nn)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_SurfaceDef_CollectNodes

  !----------------------------------------------------------------------------
  SUBROUTINE MD_ElemSet_CollectNodes(member_elems, n_mem, nodes, nn, status)
    INTEGER(i4), INTENT(IN) :: member_elems(:)
    INTEGER(i4), INTENT(IN) :: n_mem
    INTEGER(i4), INTENT(OUT) :: nodes(MD_SURF_BRIDGE_MAX_NODES)
    INTEGER(i4), INTENT(OUT) :: nn
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_Mesh_GetElemConnect_Arg) :: ec
    INTEGER(i4) :: i, k
    LOGICAL :: ov

    CALL init_error_status(status)
    nn = 0_i4
    nodes = 0_i4
    IF (n_mem < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_ElemSet_CollectNodes: empty elset'
      RETURN
    END IF
    DO i = 1, MIN(n_mem, SIZE(member_elems))
      IF (member_elems(i) < 1_i4) CYCLE
      CALL MD_Mesh_GetElemConnect_Idx(member_elems(i), ec, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      DO k = 1, ec%npe
        CALL push_unique(nodes, nn, INT(ec%connect(k), i4), ov)
        IF (ov) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_ElemSet_CollectNodes: node cap exceeded'
          RETURN
        END IF
      END DO
    END DO
    IF (nn < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_ElemSet_CollectNodes: no nodes collected'
      RETURN
    END IF
    CALL sort_nodes(nodes, nn)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_ElemSet_CollectNodes

  !----------------------------------------------------------------------------
  !> If `n_pairs==0` and slave/master surface names set, fill `slave_nodes` /
  !> `master_nodes`. **Default (mesh on)**: for each slave node, pick **closest**
  !> master node (Euclidean, 3D coords); masters may repeat. **Fallback**: sorted
  !> index pairing up to min(n_slave,n_master).
  !----------------------------------------------------------------------------
  SUBROUTINE MD_TieConstraint_TryResolveSurfaces(tie, status)
    TYPE(TieConstraintDef), INTENT(INOUT) :: tie
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_Asm_GetSurfaceByName_Arg) :: as, am
    INTEGER(i4) :: ns(MD_SURF_BRIDGE_MAX_NODES), nm(MD_SURF_BRIDGE_MAX_NODES)
    INTEGER(i4) :: nns, nnm, np, i, jm, j_best
    LOGICAL :: have_surf, use_nn
    TYPE(MD_Mesh_GetNodeCoords_Arg) :: c_s, c_m
    TYPE(ErrorStatusType) :: stn
    REAL(wp) :: dx, dy, dz, d2, best2

    CALL init_error_status(status)
    IF (tie%n_pairs > 0_i4 .AND. ALLOCATED(tie%slave_nodes) .AND. ALLOCATED(tie%master_nodes)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    have_surf = LEN_TRIM(tie%slave_surface) > 0 .AND. LEN_TRIM(tie%master_surface) > 0
    IF (.NOT. have_surf) THEN
      status%status_code = IF_STATUS_OK
      status%message = 'MD_TieConstraint_TryResolveSurfaces: no surface names; pairs unchanged'
      RETURN
    END IF

    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%assembly%initialized) THEN
      status%status_code = IF_STATUS_OK
      status%message = 'MD_TieConstraint_TryResolveSurfaces: assembly not ready; pairs unchanged'
      RETURN
    END IF

    CALL MD_Assembly_GetSurfaceByName_Idx(TRIM(tie%slave_surface), as, status)
    IF (status%status_code /= IF_STATUS_OK .OR. .NOT. as%found) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_OK
      status%message = 'MD_TieConstraint_TryResolveSurfaces: slave surface not found'
      RETURN
    END IF
    CALL MD_Assembly_GetSurfaceByName_Idx(TRIM(tie%master_surface), am, status)
    IF (status%status_code /= IF_STATUS_OK .OR. .NOT. am%found) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_OK
      status%message = 'MD_TieConstraint_TryResolveSurfaces: master surface not found'
      RETURN
    END IF

    IF (.NOT. ALLOCATED(as%def%elem_ids) .OR. .NOT. ALLOCATED(am%def%elem_ids)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_TieConstraint_TryResolveSurfaces: surface elem_ids not allocated'
      RETURN
    END IF

    CALL MD_SurfaceDef_CollectNodes(as%def%elem_ids, as%def%n_faces, ns, nns, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL MD_SurfaceDef_CollectNodes(am%def%elem_ids, am%def%n_faces, nm, nnm, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (nns < 1_i4 .OR. nnm < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_TieConstraint_TryResolveSurfaces: empty node pairing'
      RETURN
    END IF

    IF (ALLOCATED(tie%slave_nodes)) DEALLOCATE(tie%slave_nodes)
    IF (ALLOCATED(tie%master_nodes)) DEALLOCATE(tie%master_nodes)

    use_nn = g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%mesh%initialized
    IF (use_nn) THEN
      ALLOCATE(tie%slave_nodes(nns), tie%master_nodes(nns))
      tie%n_pairs = nns
      DO i = 1, nns
        CALL MD_Mesh_GetNodeCoords_Idx(ns(i), c_s, stn)
        IF (stn%status_code /= IF_STATUS_OK) THEN
          use_nn = .FALSE.
          EXIT
        END IF
        j_best = 1_i4
        best2 = HUGE(1.0_wp)
        DO jm = 1, nnm
          CALL MD_Mesh_GetNodeCoords_Idx(nm(jm), c_m, stn)
          IF (stn%status_code /= IF_STATUS_OK) CYCLE
          dx = c_m%coords(1) - c_s%coords(1)
          dy = c_m%coords(2) - c_s%coords(2)
          dz = c_m%coords(3) - c_s%coords(3)
          d2 = dx * dx + dy * dy + dz * dz
          IF (d2 < best2) THEN
            best2 = d2
            j_best = jm
          END IF
        END DO
        tie%slave_nodes(i) = ns(i)
        tie%master_nodes(i) = nm(j_best)
      END DO
    END IF

    IF (.NOT. use_nn) THEN
      IF (ALLOCATED(tie%slave_nodes)) DEALLOCATE(tie%slave_nodes)
      IF (ALLOCATED(tie%master_nodes)) DEALLOCATE(tie%master_nodes)
      np = MIN(nns, nnm)
      ALLOCATE(tie%slave_nodes(np), tie%master_nodes(np))
      DO i = 1, np
        tie%slave_nodes(i) = ns(i)
        tie%master_nodes(i) = nm(i)
      END DO
      tie%n_pairs = np
      status%status_code = IF_STATUS_OK
      WRITE (status%message, '(A,I0,A)') 'MD_TieConstraint_TryResolveSurfaces: index-paired ', np, ' node pairs (no mesh NN)'
    ELSE
      status%status_code = IF_STATUS_OK
      WRITE (status%message, '(A,I0,A)') 'MD_TieConstraint_TryResolveSurfaces: nearest-master paired ', tie%n_pairs, ' slave nodes'
    END IF
  END SUBROUTINE MD_TieConstraint_TryResolveSurfaces

  !----------------------------------------------------------------------------
  SUBROUTINE MD_CplConstraint_TryResolveSurfaceOrElset(cpl, status)
    TYPE(CplConstraintDef), INTENT(INOUT) :: cpl
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_Asm_GetSurfaceByName_Arg) :: asurf
    TYPE(MD_Asm_GetElemSetByName_Arg) :: aes
    INTEGER(i4) :: nodes(MD_SURF_BRIDGE_MAX_NODES)
    INTEGER(i4) :: nn, i
    REAL(wp) :: wsum

    CALL init_error_status(status)
    IF (cpl%n_coupled > 0_i4 .AND. ALLOCATED(cpl%coupled_nodes)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (LEN_TRIM(cpl%surface_name) == 0) THEN
      status%status_code = IF_STATUS_OK
      status%message = 'MD_CplConstraint_TryResolveSurfaceOrElset: no surface/elset name'
      RETURN
    END IF
    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%assembly%initialized) THEN
      status%status_code = IF_STATUS_OK
      status%message = 'MD_CplConstraint_TryResolveSurfaceOrElset: assembly not ready'
      RETURN
    END IF

    CALL MD_Assembly_GetSurfaceByName_Idx(TRIM(cpl%surface_name), asurf, status)
    IF (status%status_code == IF_STATUS_OK .AND. asurf%found .AND. ALLOCATED(asurf%def%elem_ids)) THEN
      CALL MD_SurfaceDef_CollectNodes(asurf%def%elem_ids, asurf%def%n_faces, nodes, nn, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    ELSE
      CALL init_error_status(status)
      CALL MD_Assembly_GetElemSetByName_Idx(TRIM(cpl%surface_name), aes, status)
      IF (status%status_code /= IF_STATUS_OK .OR. .NOT. aes%found) THEN
        CALL init_error_status(status)
        status%status_code = IF_STATUS_OK
        status%message = 'MD_CplConstraint_TryResolveSurfaceOrElset: name not found as surface or elset'
        RETURN
      END IF
      IF (.NOT. ALLOCATED(aes%def%members)) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      CALL MD_ElemSet_CollectNodes(aes%def%members, aes%def%n_members, nodes, nn, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    IF (ALLOCATED(cpl%coupled_nodes)) DEALLOCATE(cpl%coupled_nodes)
    IF (ALLOCATED(cpl%weights)) DEALLOCATE(cpl%weights)
    ALLOCATE(cpl%coupled_nodes(nn), cpl%weights(nn))
    cpl%n_coupled = nn
    wsum = REAL(nn, wp)
    IF (wsum <= 0.0_wp) wsum = 1.0_wp
    IF (cpl%coupling_type == COUPLING_TYPE_DISTRIBUTING) THEN
      DO i = 1, nn
        cpl%coupled_nodes(i) = nodes(i)
        cpl%weights(i) = 1.0_wp / wsum
      END DO
    ELSE
      DO i = 1, nn
        cpl%coupled_nodes(i) = nodes(i)
        cpl%weights(i) = 1.0_wp
      END DO
    END IF
    status%status_code = IF_STATUS_OK
    WRITE (status%message, '(A,I0,A)') 'MD_CplConstraint_TryResolveSurfaceOrElset: ', nn, ' coupled nodes'
  END SUBROUTINE MD_CplConstraint_TryResolveSurfaceOrElset

  !----------------------------------------------------------------------------
  SUBROUTINE MD_RigidBody_TryResolveFromAssembly(rbd, status)
    TYPE(RigidBodyDef), INTENT(INOUT) :: rbd
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_Asm_GetElemSetByName_Arg) :: aes
    TYPE(MD_Asm_GetNodeSetByName_Arg) :: ans
    INTEGER(i4) :: nodes(MD_SURF_BRIDGE_MAX_NODES)
    INTEGER(i4) :: nn, i, nkeep, j, nm
    INTEGER(i4), ALLOCATABLE :: tmp(:)

    CALL init_error_status(status)
    IF (rbd%n_tied > 0_i4 .AND. ALLOCATED(rbd%tied_nodes)) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (LEN_TRIM(rbd%element_set) == 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (.NOT. g_ufc_global%IsReady() .OR. .NOT. g_ufc_global%md_layer%assembly%initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (rbd%tie_nset) THEN
      CALL MD_Assembly_GetNodeSetByName_Idx(TRIM(rbd%element_set), ans, status)
      IF (status%status_code /= IF_STATUS_OK .OR. .NOT. ans%found) THEN
        CALL init_error_status(status)
        status%status_code = IF_STATUS_OK
        status%message = 'MD_RigidBody_TryResolveFromAssembly: nset not found'
        RETURN
      END IF
      IF (.NOT. ALLOCATED(ans%def%members)) RETURN
      nm = ans%def%n_members
      nn = 0_i4
      nodes = 0_i4
      DO i = 1, MIN(nm, SIZE(ans%def%members))
        IF (nn >= MD_SURF_BRIDGE_MAX_NODES) EXIT
        IF (ans%def%members(i) < 1_i4) CYCLE
        nn = nn + 1_i4
        nodes(nn) = ans%def%members(i)
      END DO
      IF (nn < 1_i4) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'MD_RigidBody_TryResolveFromAssembly: empty nset'
        RETURN
      END IF
      CALL sort_nodes(nodes, nn)
    ELSE
      CALL MD_Assembly_GetElemSetByName_Idx(TRIM(rbd%element_set), aes, status)
      IF (status%status_code /= IF_STATUS_OK .OR. .NOT. aes%found) THEN
        CALL init_error_status(status)
        status%status_code = IF_STATUS_OK
        status%message = 'MD_RigidBody_TryResolveFromAssembly: elset not found'
        RETURN
      END IF
      IF (.NOT. ALLOCATED(aes%def%members)) RETURN
      CALL MD_ElemSet_CollectNodes(aes%def%members, aes%def%n_members, nodes, nn, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    nkeep = 0_i4
    DO i = 1, nn
      IF (nodes(i) == rbd%ref_node) CYCLE
      nkeep = nkeep + 1_i4
    END DO
    IF (nkeep < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'MD_RigidBody_TryResolveFromAssembly: no slave nodes after removing ref'
      RETURN
    END IF

    ALLOCATE(tmp(nkeep))
    j = 0_i4
    DO i = 1, nn
      IF (nodes(i) == rbd%ref_node) CYCLE
      j = j + 1_i4
      tmp(j) = nodes(i)
    END DO

    IF (ALLOCATED(rbd%tied_nodes)) DEALLOCATE(rbd%tied_nodes)
    ALLOCATE(rbd%tied_nodes(nkeep))
    rbd%tied_nodes(:) = tmp(:)
    rbd%n_tied = nkeep
    DEALLOCATE(tmp)
    status%status_code = IF_STATUS_OK
    WRITE (status%message, '(A,I0,A)') 'MD_RigidBody_TryResolveFromAssembly: ', nkeep, ' tied nodes'
  END SUBROUTINE MD_RigidBody_TryResolveFromAssembly

END MODULE MD_Constr_Brg