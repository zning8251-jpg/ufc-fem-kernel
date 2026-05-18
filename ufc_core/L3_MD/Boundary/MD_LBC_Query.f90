!===============================================================================
! MODULE:  MD_LBC_Query
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Impl
! BRIEF:   Node/element/surface set query and flat-index mapping utilities.
! NOTE:   Region-name lookup uses Ldbc_FindNodeSetId / Ldbc_FindSurfaceSetId / Ldbc_FindElementSetId
!          (same module as Ldbc_FlatMap_*; pilot P4 naming cleanup vs legacy Helper_* misnomers).
!===============================================================================
MODULE MD_LBC_Query
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Model_Lib_Core, ONLY: UF_Model
    USE MD_Elem_Mgr, ONLY: ElemType, UF_ElementType_FillById, UF_El_GetConnectivity

    IMPLICIT NONE
    PRIVATE

    PUBLIC :: Ldbc_FlatMap_NodeSet, Ldbc_FlatMap_ElemSet, Ldbc_FlatMap_SurfSet
    PUBLIC :: Ldbc_FindElementIndexById
    PUBLIC :: Ldbc_GetSurfaceElemFaceArrays
    PUBLIC :: Ldbc_GetNodeSetNodes
    PUBLIC :: Ldbc_GetElemSetElements
    PUBLIC :: Ldbc_GetElementNodes
    PUBLIC :: Ldbc_GetFaceNodes
    PUBLIC :: Ldbc_NodeCoordsForMeshIndex
    PUBLIC :: Ldbc_FindNodeSetId
    PUBLIC :: Ldbc_FindSurfaceSetId
    PUBLIC :: Ldbc_FindElementSetId

CONTAINS

  SUBROUTINE Ldbc_FlatMap_NodeSet(model, flatId, iPart, jSet, ok)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: flatId
    INTEGER(i4), INTENT(OUT) :: iPart, jSet
    LOGICAL, INTENT(OUT) :: ok
    INTEGER(i4) :: ip, offset, ns
    ok = .FALSE.
    iPart = 0_i4
    jSet = 0_i4
    IF (flatId <= 0_i4) RETURN
    offset = 0_i4
    IF (ALLOCATED(model%parts)) THEN
      DO ip = 1_i4, INT(SIZE(model%parts), i4)
        IF (.NOT. ALLOCATED(model%parts(ip)%nodeSets)) CYCLE
        ns = INT(SIZE(model%parts(ip)%nodeSets), i4)
        IF (flatId > offset .AND. flatId <= offset + ns) THEN
          iPart = ip
          jSet = flatId - offset
          ok = .TRUE.
          RETURN
        END IF
        offset = offset + ns
      END DO
    END IF
    IF (ALLOCATED(model%assembly%nodeSets)) THEN
      ns = INT(SIZE(model%assembly%nodeSets), i4)
      IF (flatId > offset .AND. flatId <= offset + ns) THEN
        iPart = 0_i4
        jSet = flatId - offset
        ok = .TRUE.
      END IF
    END IF
  END SUBROUTINE Ldbc_FlatMap_NodeSet

  SUBROUTINE Ldbc_FlatMap_ElemSet(model, flatId, iPart, jSet, ok)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: flatId
    INTEGER(i4), INTENT(OUT) :: iPart, jSet
    LOGICAL, INTENT(OUT) :: ok
    INTEGER(i4) :: ip, offset, ns
    ok = .FALSE.
    iPart = 0_i4
    jSet = 0_i4
    IF (flatId <= 0_i4) RETURN
    offset = 0_i4
    IF (ALLOCATED(model%parts)) THEN
      DO ip = 1_i4, INT(SIZE(model%parts), i4)
        IF (.NOT. ALLOCATED(model%parts(ip)%elemSets)) CYCLE
        ns = INT(SIZE(model%parts(ip)%elemSets), i4)
        IF (flatId > offset .AND. flatId <= offset + ns) THEN
          iPart = ip
          jSet = flatId - offset
          ok = .TRUE.
          RETURN
        END IF
        offset = offset + ns
      END DO
    END IF
    IF (ALLOCATED(model%assembly%elemSets)) THEN
      ns = INT(SIZE(model%assembly%elemSets), i4)
      IF (flatId > offset .AND. flatId <= offset + ns) THEN
        iPart = 0_i4
        jSet = flatId - offset
        ok = .TRUE.
      END IF
    END IF
  END SUBROUTINE Ldbc_FlatMap_ElemSet

  SUBROUTINE Ldbc_FlatMap_SurfSet(model, flatId, iPart, jSet, ok)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: flatId
    INTEGER(i4), INTENT(OUT) :: iPart, jSet
    LOGICAL, INTENT(OUT) :: ok
    INTEGER(i4) :: ip, offset, ns
    ok = .FALSE.
    iPart = 0_i4
    jSet = 0_i4
    IF (flatId <= 0_i4) RETURN
    offset = 0_i4
    IF (ALLOCATED(model%parts)) THEN
      DO ip = 1_i4, INT(SIZE(model%parts), i4)
        IF (.NOT. ALLOCATED(model%parts(ip)%surfSets)) CYCLE
        ns = INT(SIZE(model%parts(ip)%surfSets), i4)
        IF (flatId > offset .AND. flatId <= offset + ns) THEN
          iPart = ip
          jSet = flatId - offset
          ok = .TRUE.
          RETURN
        END IF
        offset = offset + ns
      END DO
    END IF
    IF (ALLOCATED(model%assembly%surfSets)) THEN
      ns = INT(SIZE(model%assembly%surfSets), i4)
      IF (flatId > offset .AND. flatId <= offset + ns) THEN
        iPart = 0_i4
        jSet = flatId - offset
        ok = .TRUE.
      END IF
    END IF
  END SUBROUTINE Ldbc_FlatMap_SurfSet

  SUBROUTINE Ldbc_FindElementIndexById(model, elemId, iPart, iElem, found)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: elemId
    INTEGER(i4), INTENT(OUT) :: iPart, iElem
    LOGICAL, INTENT(OUT) :: found
    INTEGER(i4) :: ip, k
    found = .FALSE.
    iPart = 0_i4
    iElem = 0_i4
    IF (.NOT. ALLOCATED(model%parts)) RETURN
    DO ip = 1_i4, INT(SIZE(model%parts), i4)
      IF (.NOT. ALLOCATED(model%parts(ip)%elements)) CYCLE
      DO k = 1_i4, INT(SIZE(model%parts(ip)%elements), i4)
        IF (model%parts(ip)%elements(k)%cfg%id == elemId) THEN
          iPart = ip
          iElem = k
          found = .TRUE.
          RETURN
        END IF
      END DO
    END DO
  END SUBROUTINE Ldbc_FindElementIndexById

  SUBROUTINE Ldbc_GetSurfaceElemFaceArrays(model, flatSurfId, elems, faces)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: flatSurfId
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: elems(:)
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: faces(:)
    INTEGER(i4) :: iPart, jSet, n, i
    LOGICAL :: ok
    IF (ALLOCATED(elems)) DEALLOCATE(elems)
    IF (ALLOCATED(faces)) DEALLOCATE(faces)
    ALLOCATE(elems(0))
    ALLOCATE(faces(0))
    CALL Ldbc_FlatMap_SurfSet(model, flatSurfId, iPart, jSet, ok)
    IF (.NOT. ok) RETURN
    IF (iPart > 0_i4) THEN
      IF (jSet < 1_i4 .OR. jSet > SIZE(model%parts(iPart)%surfSets)) RETURN
      IF (.NOT. ALLOCATED(model%parts(iPart)%surfSets(jSet)%elemIds)) RETURN
      n = INT(SIZE(model%parts(iPart)%surfSets(jSet)%elemIds), i4)
      IF (n <= 0_i4) RETURN
      ALLOCATE(elems(n), faces(n))
      elems(:) = model%parts(iPart)%surfSets(jSet)%elemIds(:)
      IF (ALLOCATED(model%parts(iPart)%surfSets(jSet)%faceIds)) THEN
        IF (SIZE(model%parts(iPart)%surfSets(jSet)%faceIds) == n) THEN
          faces(:) = model%parts(iPart)%surfSets(jSet)%faceIds(:)
        ELSE
          DO i = 1_i4, n
            faces(i) = 1_i4
          END DO
        END IF
      ELSE
        DO i = 1_i4, n
          faces(i) = 1_i4
        END DO
      END IF
    ELSE
      IF (jSet < 1_i4 .OR. jSet > SIZE(model%assembly%surfSets)) RETURN
      IF (.NOT. ALLOCATED(model%assembly%surfSets(jSet)%elemIds)) RETURN
      n = INT(SIZE(model%assembly%surfSets(jSet)%elemIds), i4)
      IF (n <= 0_i4) RETURN
      ALLOCATE(elems(n), faces(n))
      elems(:) = model%assembly%surfSets(jSet)%elemIds(:)
      IF (ALLOCATED(model%assembly%surfSets(jSet)%faceIds)) THEN
        IF (SIZE(model%assembly%surfSets(jSet)%faceIds) == n) THEN
          faces(:) = model%assembly%surfSets(jSet)%faceIds(:)
        ELSE
          DO i = 1_i4, n
            faces(i) = 1_i4
          END DO
        END IF
      ELSE
        DO i = 1_i4, n
          faces(i) = 1_i4
        END DO
      END IF
    END IF
  END SUBROUTINE Ldbc_GetSurfaceElemFaceArrays

  SUBROUTINE Ldbc_GetNodeSetNodes(model, nodeSetId, nodeList)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: nodeSetId
    INTEGER(i4), INTENT(OUT), POINTER :: nodeList(:)
    INTEGER(i4) :: iPart, jSet, nn
    LOGICAL :: ok
    IF (ASSOCIATED(nodeList)) THEN
      DEALLOCATE(nodeList)
      NULLIFY(nodeList)
    ELSE
      NULLIFY(nodeList)
    END IF
    IF (nodeSetId <= 0_i4) RETURN
    CALL Ldbc_FlatMap_NodeSet(model, nodeSetId, iPart, jSet, ok)
    IF (.NOT. ok) RETURN
    IF (iPart > 0_i4) THEN
      IF (jSet < 1_i4 .OR. jSet > SIZE(model%parts(iPart)%nodeSets)) RETURN
      IF (.NOT. ALLOCATED(model%parts(iPart)%nodeSets(jSet)%nodeIds)) RETURN
      nn = INT(SIZE(model%parts(iPart)%nodeSets(jSet)%nodeIds), i4)
      IF (nn <= 0_i4) RETURN
      ALLOCATE(nodeList(nn))
      nodeList(:) = model%parts(iPart)%nodeSets(jSet)%nodeIds(:)
    ELSE
      IF (jSet < 1_i4 .OR. jSet > SIZE(model%assembly%nodeSets)) RETURN
      IF (.NOT. ALLOCATED(model%assembly%nodeSets(jSet)%nodeIds)) RETURN
      nn = INT(SIZE(model%assembly%nodeSets(jSet)%nodeIds), i4)
      IF (nn <= 0_i4) RETURN
      ALLOCATE(nodeList(nn))
      nodeList(:) = model%assembly%nodeSets(jSet)%nodeIds(:)
    END IF
  END SUBROUTINE Ldbc_GetNodeSetNodes

  SUBROUTINE Ldbc_GetElemSetElements(model, elemSet, elemList)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: elemSet
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: elemList(:)
    INTEGER(i4) :: iPart, jSet, ne
    LOGICAL :: ok
    IF (ALLOCATED(elemList)) DEALLOCATE(elemList)
    ALLOCATE(elemList(0))
    IF (elemSet <= 0_i4) RETURN
    CALL Ldbc_FlatMap_ElemSet(model, elemSet, iPart, jSet, ok)
    IF (.NOT. ok) RETURN
    IF (iPart > 0_i4) THEN
      IF (jSet < 1_i4 .OR. jSet > SIZE(model%parts(iPart)%elemSets)) RETURN
      IF (.NOT. ALLOCATED(model%parts(iPart)%elemSets(jSet)%elemIds)) RETURN
      ne = INT(SIZE(model%parts(iPart)%elemSets(jSet)%elemIds), i4)
      IF (ne <= 0_i4) RETURN
      ALLOCATE(elemList(ne))
      elemList(:) = model%parts(iPart)%elemSets(jSet)%elemIds(:)
    ELSE
      IF (jSet < 1_i4 .OR. jSet > SIZE(model%assembly%elemSets)) RETURN
      IF (.NOT. ALLOCATED(model%assembly%elemSets(jSet)%elemIds)) RETURN
      ne = INT(SIZE(model%assembly%elemSets(jSet)%elemIds), i4)
      IF (ne <= 0_i4) RETURN
      ALLOCATE(elemList(ne))
      elemList(:) = model%assembly%elemSets(jSet)%elemIds(:)
    END IF
  END SUBROUTINE Ldbc_GetElemSetElements

  SUBROUTINE Ldbc_GetElementNodes(model, elemId, elemNodes)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: elemId
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: elemNodes(:)
    INTEGER(i4) :: iPart, iElem, m, nnix
    LOGICAL :: found
    IF (ALLOCATED(elemNodes)) DEALLOCATE(elemNodes)
    ALLOCATE(elemNodes(0))
    CALL Ldbc_FindElementIndexById(model, elemId, iPart, iElem, found)
    IF (.NOT. found) RETURN
    IF (.NOT. ALLOCATED(model%parts(iPart)%elements(iElem)%conn)) RETURN
    nnix = INT(SIZE(model%parts(iPart)%elements(iElem)%conn), i4)
    IF (nnix <= 0_i4) RETURN
    ALLOCATE(elemNodes(nnix))
    DO m = 1_i4, nnix
      elemNodes(m) = model%parts(iPart)%elements(iElem)%conn(m)
    END DO
  END SUBROUTINE Ldbc_GetElementNodes

  SUBROUTINE Ldbc_GetFaceNodes(model, elemId, faceId, faceNodes, ownerPart)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: elemId, faceId
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: faceNodes(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ownerPart
    INTEGER(i4) :: iPart, iElem, ierr, nFace, nEdge, diml, lf, lj, nnix, cnt
    INTEGER(i4) :: face_tab(6, 9), edge_tab(12, 3)
    TYPE(ElemType) :: et
    LOGICAL :: found
    IF (ALLOCATED(faceNodes)) DEALLOCATE(faceNodes)
    ALLOCATE(faceNodes(0))
    CALL Ldbc_FindElementIndexById(model, elemId, iPart, iElem, found)
    IF (.NOT. found) RETURN
    IF (PRESENT(ownerPart)) ownerPart = iPart
    IF (.NOT. ALLOCATED(model%parts(iPart)%elements(iElem)%conn)) RETURN
    CALL UF_ElementType_FillById(et, model%parts(iPart)%elements(iElem)%elemTypeId)
    CALL UF_El_GetConnectivity(TRIM(et%name), diml, nFace, nEdge, face_tab, edge_tab, ierr)
    IF (ierr /= 0_i4) RETURN
    IF (faceId < 1_i4 .OR. faceId > nFace) RETURN
    cnt = 0_i4
    DO lf = 1_i4, SIZE(face_tab, 2)
      IF (face_tab(faceId, lf) <= 0_i4) EXIT
      cnt = cnt + 1_i4
    END DO
    IF (cnt <= 0_i4) RETURN
    ALLOCATE(faceNodes(cnt))
    DO lf = 1_i4, cnt
      lj = face_tab(faceId, lf)
      IF (lj < 1_i4 .OR. lj > SIZE(model%parts(iPart)%elements(iElem)%conn)) THEN
        faceNodes(lf) = 0_i4
        CYCLE
      END IF
      nnix = model%parts(iPart)%elements(iElem)%conn(lj)
      IF (nnix >= 1_i4 .AND. nnix <= SIZE(model%parts(iPart)%nodes)) THEN
        faceNodes(lf) = nnix
      ELSE
        faceNodes(lf) = 0_i4
      END IF
    END DO
  END SUBROUTINE Ldbc_GetFaceNodes

  SUBROUTINE Ldbc_NodeCoordsForMeshIndex(model, iPart, meshIdx, coords, ok)
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: iPart, meshIdx
    REAL(wp), INTENT(OUT) :: coords(3)
    LOGICAL, INTENT(OUT) :: ok
    ok = .FALSE.
    coords = 0.0_wp
    IF (iPart < 1_i4 .OR. iPart > SIZE(model%parts)) RETURN
    IF (.NOT. ALLOCATED(model%parts(iPart)%nodes)) RETURN
    IF (meshIdx < 1_i4 .OR. meshIdx > SIZE(model%parts(iPart)%nodes)) RETURN
    coords(:) = model%parts(iPart)%nodes(meshIdx)%coords(:)
    ok = .TRUE.
  END SUBROUTINE Ldbc_NodeCoordsForMeshIndex

  FUNCTION Ldbc_FindNodeSetId(model, regionName) RESULT(setId)
    TYPE(UF_Model), INTENT(IN), TARGET :: model
    CHARACTER(len=*), INTENT(IN) :: regionName
    INTEGER(i4) :: setId
    INTEGER(i4) :: i
    CHARACTER(len=64) :: setName, trimmedRegionName
    setId = 0_i4
    trimmedRegionName = TRIM(regionName)
    IF (LEN_TRIM(trimmedRegionName) == 0) RETURN
    IF (ALLOCATED(model%assembly%nodeSets)) THEN
      DO i = 1, SIZE(model%assembly%nodeSets)
        setName = TRIM(model%assembly%nodeSets(i)%name)
        IF (setName == trimmedRegionName) THEN
          setId = i
          RETURN
        END IF
      END DO
    END IF
    IF (ALLOCATED(model%assembly%node_sets)) THEN
      DO i = 1, model%assembly%num_node_sets
        setName = TRIM(model%assembly%node_sets(i)%name)
        IF (setName == trimmedRegionName) THEN
          setId = i
          RETURN
        END IF
      END DO
    END IF
    IF (ALLOCATED(model%parts)) THEN
      IF (SIZE(model%parts) >= 1) THEN
        IF (ALLOCATED(model%parts(1)%nodeSets)) THEN
          DO i = 1, SIZE(model%parts(1)%nodeSets)
            setName = TRIM(model%parts(1)%nodeSets(i)%name)
            IF (setName == trimmedRegionName) THEN
              setId = i
              RETURN
            END IF
          END DO
        END IF
      END IF
    END IF
  END FUNCTION Ldbc_FindNodeSetId

  FUNCTION Ldbc_FindSurfaceSetId(model, surfaceName) RESULT(setId)
    TYPE(UF_Model), INTENT(IN), TARGET :: model
    CHARACTER(len=*), INTENT(IN) :: surfaceName
    INTEGER(i4) :: setId
    INTEGER(i4) :: iPart, iSurf, offset
    CHARACTER(len=64) :: setName, trimmedSurfaceName
    setId = 0_i4
    trimmedSurfaceName = TRIM(surfaceName)
    IF (LEN_TRIM(trimmedSurfaceName) == 0) RETURN
    offset = 0_i4
    IF (ALLOCATED(model%parts)) THEN
      DO iPart = 1, SIZE(model%parts)
        IF (.NOT. ALLOCATED(model%parts(iPart)%surfSets)) CYCLE
        DO iSurf = 1, SIZE(model%parts(iPart)%surfSets)
          setName = TRIM(model%parts(iPart)%surfSets(iSurf)%name)
          IF (setName == trimmedSurfaceName) THEN
            setId = offset + iSurf
            RETURN
          END IF
        END DO
        offset = offset + SIZE(model%parts(iPart)%surfSets)
      END DO
    END IF
    IF (ALLOCATED(model%assembly%surfSets)) THEN
      DO iSurf = 1, SIZE(model%assembly%surfSets)
        setName = TRIM(model%assembly%surfSets(iSurf)%name)
        IF (setName == trimmedSurfaceName) THEN
          setId = offset + iSurf
          RETURN
        END IF
      END DO
    END IF
  END FUNCTION Ldbc_FindSurfaceSetId

  FUNCTION Ldbc_FindElementSetId(model, elemSetName) RESULT(setId)
    TYPE(UF_Model), INTENT(IN), TARGET :: model
    CHARACTER(len=*), INTENT(IN) :: elemSetName
    INTEGER(i4) :: setId
    INTEGER(i4) :: iPart, iSet, offset
    CHARACTER(len=64) :: setName, trimmedElemSetName
    setId = 0_i4
    trimmedElemSetName = TRIM(elemSetName)
    IF (LEN_TRIM(trimmedElemSetName) == 0) RETURN
    offset = 0_i4
    IF (ALLOCATED(model%parts)) THEN
      DO iPart = 1, SIZE(model%parts)
        IF (.NOT. ALLOCATED(model%parts(iPart)%elemSets)) CYCLE
        DO iSet = 1, SIZE(model%parts(iPart)%elemSets)
          setName = TRIM(model%parts(iPart)%elemSets(iSet)%name)
          IF (setName == trimmedElemSetName) THEN
            setId = offset + iSet
            RETURN
          END IF
        END DO
        offset = offset + SIZE(model%parts(iPart)%elemSets)
      END DO
    END IF
    IF (ALLOCATED(model%assembly%elemSets)) THEN
      DO iSet = 1, SIZE(model%assembly%elemSets)
        setName = TRIM(model%assembly%elemSets(iSet)%name)
        IF (setName == trimmedElemSetName) THEN
          setId = offset + iSet
          RETURN
        END IF
      END DO
    END IF
  END FUNCTION Ldbc_FindElementSetId

END MODULE MD_LBC_Query
