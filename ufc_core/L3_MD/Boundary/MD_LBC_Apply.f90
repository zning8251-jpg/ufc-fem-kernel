!===============================================================================
! MODULE:  MD_LBC_Apply
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Impl
! BRIEF:   Load distribution algorithms, BC application, extended statistics API.
!===============================================================================
MODULE MD_LBC_Apply
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Err_Brg, ONLY: log_warn
    USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc
    USE MD_Amp_Mgr, ONLY: Amp_GetFactor
    USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
    USE MD_Model_Lib_Core, ONLY: UF_Model
    USE MD_Elem_Mgr, ONLY: ElemType, UF_ElementType_FillById, UF_El_GetConnectivity
    USE MD_Load_Mgr, ONLY: LoadDef, LOAD_CONCENTRAT, LOAD_DISTRIBUTE, LOAD_PRESSURE, &
                            LOAD_BODY_FORCE, LOAD_GRAVITY, LOAD_CENTRIFUGA, LOAD_CORIOLIS, &
                            TARGET_NODE, TARGET_NODESET, TARGET_SURFACE, TARGET_ELEMSET
    USE MD_BC_Mgr, ONLY: BCDef, BC_DISPLACEMENT, BC_VELOCITY, BC_ACCELERATION
    USE MD_LBC_Core, ONLY: md_lbc_amp_from_uf
    USE MD_LBC_Query, ONLY: Ldbc_GetNodeSetNodes, Ldbc_GetElemSetElements, Ldbc_GetElementNodes, &
                             Ldbc_GetFaceNodes, Ldbc_GetSurfaceElemFaceArrays, &
                             Ldbc_NodeCoordsForMeshIndex, Ldbc_FindElementIndexById
    USE MD_LBC_Helper, ONLY: MD_LoadBC_Helper_ComputeFaceNormalArea

    IMPLICIT NONE
    PRIVATE

    ! Warning status constant (used in original code)
    INTEGER(i4), PARAMETER :: STATUS_WARNING = 2_i4

    ! Load distribution algorithms
    PUBLIC :: LoadBC_DistributeLoad_ToNodes
    PUBLIC :: LoadBC_DistributeLoad_ToElements
    PUBLIC :: LoadBC_DistributeLoad_ToSurface

    ! BC application algorithms
    PUBLIC :: LoadBC_ApplyBC_Velocity
    PUBLIC :: LoadBC_ApplyBC_Acceleration
    PUBLIC :: LoadBC_ApplyBC_Displacement_GetNodes

    ! Follower/Pressure/Body force application
    PUBLIC :: ApplyLoad_FollowerForce
    PUBLIC :: ApplyLoad_PressureFollowing
    PUBLIC :: ApplyLoad_BodyForce

    ! Extended API
    PUBLIC :: UF_DisplacementBC_GetStatistics, UF_DisplacementBC_ApplyAtTime
    PUBLIC :: UF_VelocityBC_GetStatistics, UF_AccelerationBC_GetStatistics
    PUBLIC :: UF_ConcentratedLoad_GetStatistics, UF_ConcentratedLoad_ApplyAtTime
    PUBLIC :: UF_DistributedLoad_GetStatistics, UF_DistributedLoad_ComputeNodalForces
    PUBLIC :: UF_InitialDisplacement_GetStatistics, UF_InitialVelocity_GetStatistics
    PUBLIC :: UF_InitialTemperature_GetStatistics
    PUBLIC :: UF_TemperatureField_GetStatistics, UF_TemperatureField_Interpolate
    PUBLIC :: MD_Amp_Slot_GetStatistics, UF_LoadCombination_ComputeEffectiveLoad

CONTAINS

  SUBROUTINE LoadBC_DistributeLoad_ToNodes(loadDef, model, nodeSet, time, F, status, md_layer)
    !! Distribute load to node set with production-level validation
    TYPE(LoadDef), INTENT(IN) :: loadDef
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: nodeSet
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4), POINTER :: nodeList(:)
    INTEGER(i4) :: i, nodeId, dof_global, nNodes
    REAL(wp) :: magnitude, amplitudeFactor
    INTEGER(i4) :: nApplied
    CALL init_error_status(status)
    nApplied = 0_i4
    IF (loadDef%loadType /= LOAD_CONCENTRAT .AND. loadDef%loadType /= LOAD_DISTRIBUTE) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Invalid load type for node distribution'
      RETURN
    END IF
    IF (SIZE(F) <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Force vector F is empty'
      RETURN
    END IF
    CALL Ldbc_GetNodeSetNodes(model, nodeSet, nodeList)
    IF (.NOT. ASSOCIATED(nodeList)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Node set not found or empty'
      RETURN
    END IF
    nNodes = SIZE(nodeList)
    IF (nNodes <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Node set contains no nodes'
      RETURN
    END IF
    amplitudeFactor = 1.0_wp
    IF (loadDef%amplitudeId > 0) THEN
      IF (PRESENT(md_layer)) THEN
        amplitudeFactor = md_lbc_amp_from_uf(model%amplitudes, loadDef%amplitudeId, time, md_layer)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        amplitudeFactor = Amp_GetFactor(model%amplitudes, loadDef%amplitudeId, time)
      END IF
    END IF
    magnitude = loadDef%magnitude * amplitudeFactor
    DO i = 1_i4, nNodes
      nodeId = nodeList(i)
      IF (nodeId <= 0) CYCLE
      IF (loadDef%dof > 0 .AND. loadDef%dof <= 6) THEN
        dof_global = (nodeId - 1_i4) * 6_i4 + loadDef%dof
      ELSE
        dof_global = (nodeId - 1_i4) * 3_i4 + 1_i4
      END IF
      IF (dof_global > 0 .AND. dof_global <= SIZE(F)) THEN
        F(dof_global) = F(dof_global) + magnitude
        nApplied = nApplied + 1_i4
      END IF
    END DO
    IF (nApplied > 0) THEN
      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A,I0,A)') 'Applied load to ', nApplied, ' nodes (out of ', nNodes, ')'
    ELSE
      status%status_code = STATUS_WARNING
      status%message = 'No loads were applied (DOF index out of range)'
    END IF
  END SUBROUTINE LoadBC_DistributeLoad_ToNodes

  SUBROUTINE LoadBC_DistributeLoad_ToElements(loadDef, model, elemSet, time, F, status, md_layer)
    !! Distribute load to element set (via element nodes)
    TYPE(LoadDef), INTENT(IN) :: loadDef
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: elemSet
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4), ALLOCATABLE :: elemList(:)
    INTEGER(i4) :: i, j, elemId, nElems, nApplied
    INTEGER(i4) :: nNodesPerElem, nodeId, dof_global
    INTEGER(i4), ALLOCATABLE :: elemNodes(:)
    REAL(wp) :: magnitude, amplitudeFactor, loadPerNode
    CALL init_error_status(status)
    nApplied = 0_i4
    IF (loadDef%loadType /= LOAD_DISTRIBUTE .AND. loadDef%loadType /= LOAD_BODY) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Invalid load type for element distribution'
      RETURN
    END IF
    IF (SIZE(F) <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Force vector F is empty'
      RETURN
    END IF
    CALL Ldbc_GetElemSetElements(model, elemSet, elemList)
    IF (.NOT. ALLOCATED(elemList)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Element set not found or empty'
      RETURN
    END IF
    nElems = SIZE(elemList)
    IF (nElems <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Element set contains no elements'
      RETURN
    END IF
    amplitudeFactor = 1.0_wp
    IF (loadDef%amplitudeId > 0) THEN
      IF (PRESENT(md_layer)) THEN
        amplitudeFactor = md_lbc_amp_from_uf(model%amplitudes, loadDef%amplitudeId, time, md_layer)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        amplitudeFactor = Amp_GetFactor(model%amplitudes, loadDef%amplitudeId, time)
      END IF
    END IF
    magnitude = loadDef%magnitude * amplitudeFactor
    DO i = 1_i4, nElems
      elemId = elemList(i)
      IF (elemId <= 0) CYCLE
      CALL Ldbc_GetElementNodes(model, elemId, elemNodes)
      IF (.NOT. ALLOCATED(elemNodes)) CYCLE
      nNodesPerElem = SIZE(elemNodes)
      IF (nNodesPerElem <= 0) THEN
        DEALLOCATE(elemNodes)
        CYCLE
      END IF
      loadPerNode = magnitude / REAL(nNodesPerElem, wp)
      DO j = 1_i4, nNodesPerElem
        nodeId = elemNodes(j)
        IF (nodeId <= 0) CYCLE
        IF (loadDef%dof > 0 .AND. loadDef%dof <= 6) THEN
          dof_global = (nodeId - 1_i4) * 6_i4 + loadDef%dof
        ELSE
          dof_global = (nodeId - 1_i4) * 3_i4 + 1_i4
        END IF
        IF (dof_global > 0 .AND. dof_global <= SIZE(F)) THEN
          F(dof_global) = F(dof_global) + loadPerNode
          nApplied = nApplied + 1_i4
        END IF
      END DO
      DEALLOCATE(elemNodes)
    END DO
    IF (nApplied > 0) THEN
      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A,I0,A)') 'Applied element load to ', nApplied, ' nodes (from ', nElems, ' elements)'
    ELSE
      status%status_code = STATUS_WARNING
      status%message = 'No element loads were applied'
    END IF
  END SUBROUTINE LoadBC_DistributeLoad_ToElements

  SUBROUTINE LoadBC_DistributeLoad_ToSurface(loadDef, model, surfaceSet, time, F, status, md_layer)
    !! Distribute load to surface set (pressure/traction)
    TYPE(LoadDef), INTENT(IN) :: loadDef
    TYPE(UF_Model), INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: surfaceSet
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4), ALLOCATABLE :: surfElems(:), surfFaces(:)
    INTEGER(i4) :: i, j, elemId, nFacets, nApplied
    INTEGER(i4) :: faceId, nNodesPerFace, nodeId
    INTEGER(i4) :: idof, ig, nnf, km, iFacePart
    INTEGER(i4), ALLOCATABLE :: faceNodes(:)
    REAL(wp) :: magnitude, amplitudeFactor, area
    REAL(wp) :: tractionVector(3), forcePerNode(3)
    REAL(wp) :: coords3d(3, 32), nrm3(3)
    LOGICAL :: gotC
    CALL init_error_status(status)
    nApplied = 0_i4
    IF (loadDef%loadType /= LOAD_PRESSURE .AND. loadDef%loadType /= LOAD_SURFACE) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Invalid load type for surface distribution'
      RETURN
    END IF
    IF (SIZE(F) <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Force vector F is empty'
      RETURN
    END IF
    CALL Ldbc_GetSurfaceElemFaceArrays(model, surfaceSet, surfElems, surfFaces)
    IF (.NOT. ALLOCATED(surfElems) .OR. SIZE(surfElems) <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Surface set not found or empty'
      RETURN
    END IF
    nFacets = INT(SIZE(surfElems), i4)
    amplitudeFactor = 1.0_wp
    IF (loadDef%amplitudeId > 0) THEN
      IF (PRESENT(md_layer)) THEN
        amplitudeFactor = md_lbc_amp_from_uf(model%amplitudes, loadDef%amplitudeId, time, md_layer)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        amplitudeFactor = Amp_GetFactor(model%amplitudes, loadDef%amplitudeId, time)
      END IF
    END IF
    magnitude = loadDef%magnitude * amplitudeFactor
    tractionVector = 0.0_wp
    IF (loadDef%dof > 0 .AND. loadDef%dof <= 3) THEN
      tractionVector(loadDef%dof) = magnitude
    ELSE
      tractionVector(3) = magnitude
    END IF
    DO i = 1_i4, nFacets
      elemId = surfElems(i)
      faceId = surfFaces(i)
      IF (elemId <= 0_i4) CYCLE
      IF (faceId <= 0_i4) CYCLE
      CALL Ldbc_GetFaceNodes(model, elemId, faceId, faceNodes, iFacePart)
      IF (.NOT. ALLOCATED(faceNodes)) CYCLE
      nNodesPerFace = INT(SIZE(faceNodes), i4)
      IF (nNodesPerFace <= 0) THEN
        DEALLOCATE(faceNodes)
        CYCLE
      END IF
      nnf = MIN(nNodesPerFace, 32_i4)
      DO km = 1_i4, nnf
        CALL Ldbc_NodeCoordsForMeshIndex(model, iFacePart, faceNodes(km), coords3d(:, km), gotC)
        IF (.NOT. gotC) coords3d(:, km) = 0.0_wp
      END DO
      CALL MD_LoadBC_Helper_ComputeFaceNormalArea(coords3d(:, 1:nnf), nnf, nrm3, area)
      IF (area <= 0.0_wp) THEN
        DEALLOCATE(faceNodes)
        CYCLE
      END IF
      forcePerNode = tractionVector * (area / REAL(nNodesPerFace, wp))
      DO j = 1_i4, nNodesPerFace
        nodeId = faceNodes(j)
        IF (nodeId <= 0_i4) CYCLE
        DO idof = 1_i4, 3_i4
          IF (ABS(forcePerNode(idof)) < 1.0e-14_wp) CYCLE
          ig = (nodeId - 1_i4) * 3_i4 + idof
          IF (ig > 0_i4 .AND. ig <= SIZE(F)) THEN
            F(ig) = F(ig) + forcePerNode(idof)
            nApplied = nApplied + 1_i4
          END IF
        END DO
      END DO
      DEALLOCATE(faceNodes)
    END DO
    IF (ALLOCATED(surfElems)) DEALLOCATE(surfElems)
    IF (ALLOCATED(surfFaces)) DEALLOCATE(surfFaces)
    IF (nApplied > 0) THEN
      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A,I0,A)') 'Applied surface load (', nApplied, ' DOF entries, ', nFacets, ' facets)'
    ELSE
      status%status_code = STATUS_WARNING
      status%message = 'No surface loads were applied'
    END IF
  END SUBROUTINE LoadBC_DistributeLoad_ToSurface

  SUBROUTINE LoadBC_ApplyBC_Velocity(bcDef, model, time, velocity, dof_mask, status, md_layer)
    !! Apply velocity boundary condition
    TYPE(BCDef), INTENT(IN) :: bcDef
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(INOUT) :: velocity(:)
    INTEGER(i4), INTENT(INOUT), OPTIONAL :: dof_mask(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4), POINTER :: nodeList(:)
    INTEGER(i4) :: i, nodeId, dof_global, nNodes, nApplied
    REAL(wp) :: vel_value, amplitudeFactor
    CALL init_error_status(status)
    nApplied = 0_i4
    IF (bcDef%bcType /= BC_VELOCITY) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Invalid BC type for velocity application'
      RETURN
    END IF
    IF (SIZE(velocity) <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Velocity vector is empty'
      RETURN
    END IF
    CALL Ldbc_GetNodeSetNodes(model, bcDef%targetId, nodeList)
    IF (.NOT. ASSOCIATED(nodeList)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Node set not found or empty'
      RETURN
    END IF
    nNodes = SIZE(nodeList)
    IF (nNodes <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Node set contains no nodes'
      RETURN
    END IF
    amplitudeFactor = 1.0_wp
    IF (bcDef%amplitudeId > 0) THEN
      IF (PRESENT(md_layer)) THEN
        amplitudeFactor = md_lbc_amp_from_uf(model%amplitudes, bcDef%amplitudeId, time, md_layer)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        amplitudeFactor = Amp_GetFactor(model%amplitudes, bcDef%amplitudeId, time)
      END IF
    END IF
    vel_value = bcDef%value * amplitudeFactor
    DO i = 1_i4, nNodes
      nodeId = nodeList(i)
      IF (nodeId <= 0) CYCLE
      IF (bcDef%dof > 0 .AND. bcDef%dof <= 6) THEN
        dof_global = (nodeId - 1_i4) * 6_i4 + bcDef%dof
      ELSE
        CYCLE
      END IF
      IF (dof_global < 1_i4 .OR. dof_global > SIZE(velocity)) CYCLE
      velocity(dof_global) = vel_value
      IF (PRESENT(dof_mask)) THEN
        IF (dof_global >= 1_i4 .AND. dof_global <= SIZE(dof_mask)) THEN
          dof_mask(dof_global) = 0_i4
        END IF
      END IF
      nApplied = nApplied + 1_i4
    END DO
    IF (nApplied > 0) THEN
      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A)') 'Applied velocity BC to ', nApplied, ' DOFs'
    ELSE
      status%status_code = STATUS_WARNING
      status%message = 'No velocity BCs were applied'
    END IF
  END SUBROUTINE LoadBC_ApplyBC_Velocity

  SUBROUTINE LoadBC_ApplyBC_Acceleration(bcDef, model, time, acceleration, dof_mask, status, md_layer)
    !! Apply acceleration boundary condition
    TYPE(BCDef), INTENT(IN) :: bcDef
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(INOUT) :: acceleration(:)
    INTEGER(i4), INTENT(INOUT), OPTIONAL :: dof_mask(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4), POINTER :: nodeList(:)
    INTEGER(i4) :: i, nodeId, dof_global, nNodes, nApplied
    REAL(wp) :: acc_value, amplitudeFactor
    CALL init_error_status(status)
    nApplied = 0_i4
    IF (bcDef%bcType /= BC_ACCELERATION) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Invalid BC type for acceleration application'
      RETURN
    END IF
    IF (SIZE(acceleration) <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Acceleration vector is empty'
      RETURN
    END IF
    CALL Ldbc_GetNodeSetNodes(model, bcDef%targetId, nodeList)
    IF (.NOT. ASSOCIATED(nodeList)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Node set not found or empty'
      RETURN
    END IF
    nNodes = SIZE(nodeList)
    IF (nNodes <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Node set contains no nodes'
      RETURN
    END IF
    amplitudeFactor = 1.0_wp
    IF (bcDef%amplitudeId > 0) THEN
      IF (PRESENT(md_layer)) THEN
        amplitudeFactor = md_lbc_amp_from_uf(model%amplitudes, bcDef%amplitudeId, time, md_layer)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        amplitudeFactor = Amp_GetFactor(model%amplitudes, bcDef%amplitudeId, time)
      END IF
    END IF
    acc_value = bcDef%value * amplitudeFactor
    DO i = 1_i4, nNodes
      nodeId = nodeList(i)
      IF (nodeId <= 0) CYCLE
      IF (bcDef%dof > 0 .AND. bcDef%dof <= 6) THEN
        dof_global = (nodeId - 1_i4) * 6_i4 + bcDef%dof
      ELSE
        CYCLE
      END IF
      IF (dof_global < 1_i4 .OR. dof_global > SIZE(acceleration)) CYCLE
      acceleration(dof_global) = acc_value
      IF (PRESENT(dof_mask)) THEN
        IF (dof_global >= 1_i4 .AND. dof_global <= SIZE(dof_mask)) THEN
          dof_mask(dof_global) = 0_i4
        END IF
      END IF
      nApplied = nApplied + 1_i4
    END DO
    IF (nApplied > 0) THEN
      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A)') 'Applied acceleration BC to ', nApplied, ' DOFs'
    ELSE
      status%status_code = STATUS_WARNING
      status%message = 'No acceleration BCs were applied'
    END IF
  END SUBROUTINE LoadBC_ApplyBC_Acceleration

  SUBROUTINE LoadBC_ApplyBC_Displacement_GetNodes(bcDef, model, time, nodeIds, &
       dofs, values, nOut, status, md_layer)
    TYPE(BCDef), INTENT(IN) :: bcDef
    TYPE(UF_Model), INTENT(IN) :: model
    REAL(wp), INTENT(IN) :: time
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: nodeIds(:), dofs(:)
    REAL(wp), INTENT(OUT), ALLOCATABLE :: values(:)
    INTEGER(i4), INTENT(OUT) :: nOut
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4), POINTER :: nodeList(:)
    INTEGER(i4) :: i, nodeId, nNodes
    REAL(wp) :: amplitudeFactor, presc_val
    CALL init_error_status(status)
    nOut = 0_i4
    IF (bcDef%bcType /= BC_DISPLACEMENT) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Invalid BC type for displacement application'
      RETURN
    END IF
    amplitudeFactor = 1.0_wp
    IF (bcDef%amplitudeId > 0_i4) THEN
      IF (PRESENT(md_layer)) THEN
        amplitudeFactor = md_lbc_amp_from_uf(model%amplitudes, bcDef%amplitudeId, time, md_layer)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        amplitudeFactor = Amp_GetFactor(model%amplitudes, bcDef%amplitudeId, time)
      END IF
    END IF
    presc_val = bcDef%value * amplitudeFactor
    SELECT CASE (bcDef%targetType)
    CASE (TARGET_NODE)
      nNodes = 1_i4
      IF (bcDef%targetId > 0_i4 .AND. bcDef%dof > 0_i4 .AND. bcDef%dof <= 6_i4) THEN
        ALLOCATE(nodeIds(1), dofs(1), values(1))
        nodeIds(1) = bcDef%targetId
        dofs(1) = bcDef%dof
        values(1) = presc_val
        nOut = 1_i4
      END IF
    CASE (TARGET_NODESET)
      CALL Ldbc_GetNodeSetNodes(model, bcDef%targetId, nodeList)
      IF (.NOT. ASSOCIATED(nodeList)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'Node set not found or empty'
        RETURN
      END IF
      nNodes = SIZE(nodeList)
      IF (nNodes > 0_i4 .AND. bcDef%dof > 0_i4 .AND. bcDef%dof <= 6_i4) THEN
        ALLOCATE(nodeIds(nNodes), dofs(nNodes), values(nNodes))
        DO i = 1_i4, nNodes
          nodeIds(i) = nodeList(i)
          dofs(i) = bcDef%dof
          values(i) = presc_val
        END DO
        nOut = nNodes
        DEALLOCATE(nodeList)
      END IF
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'Unsupported target type for displacement BC'
      RETURN
    END SELECT
    IF (nOut > 0_i4) status%status_code = IF_STATUS_OK
  END SUBROUTINE LoadBC_ApplyBC_Displacement_GetNodes

  SUBROUTINE ApplyLoad_FollowerForce(F, model, loadDef, displacement, &
                                      time, amplitudes, status, md_layer)
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(LoadDef), INTENT(IN) :: loadDef
    REAL(wp), INTENT(IN) :: displacement(:)
    REAL(wp), INTENT(IN) :: time
    TYPE(MD_Amp_Slot_Desc), INTENT(IN), OPTIONAL :: amplitudes(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4) :: i, nodeId, dofId
    INTEGER(i4), ALLOCATABLE :: nodeList(:)
    REAL(wp) :: magnitude, ampFactor
    REAL(wp) :: currentCoords(3), deformGrad(3,3), F_local(3)
    INTEGER(i4) :: nNodes
    CALL init_error_status(status)
    IF (loadDef%loadType /= LOAD_CONCENTRAT .AND. loadDef%loadType /= LOAD_DISTRIBUTE) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "FollowerForce: Invalid load type"
      RETURN
    END IF
    ampFactor = 1.0_wp
    IF (loadDef%amplitudeId > 0) THEN
      IF (PRESENT(md_layer)) THEN
        ampFactor = md_lbc_amp_from_uf(model%amplitudes, loadDef%amplitudeId, time, md_layer)
      ELSE IF (PRESENT(amplitudes)) THEN
        ampFactor = Amp_GetFactor(amplitudes, loadDef%amplitudeId, time)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        ampFactor = Amp_GetFactor(model%amplitudes, loadDef%amplitudeId, time)
      END IF
    END IF
    magnitude = loadDef%magnitude * ampFactor
    SELECT CASE (loadDef%targetType)
    CASE (TARGET_NODE)
      ALLOCATE(nodeList(1))
      nodeList(1) = loadDef%targetId
    CASE (TARGET_NODESET)
      CALL Ldbc_GetNodeSetNodes(model, loadDef%targetId, nodeList)
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "FollowerForce: Unsupported target type"
      RETURN
    END SELECT
    IF (.NOT. ALLOCATED(nodeList)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "FollowerForce: Node list not allocated"
      RETURN
    END IF
    nNodes = SIZE(nodeList)
    DO i = 1, nNodes
      nodeId = nodeList(i)
      IF (nodeId <= 0) CYCLE
      dofId = (nodeId - 1) * 6 + 1
      IF (dofId + 2 > SIZE(displacement)) CYCLE
      currentCoords(1) = displacement(dofId)
      currentCoords(2) = displacement(dofId+1)
      currentCoords(3) = displacement(dofId+2)
      deformGrad = 0.0_wp
      deformGrad(1,1) = 1.0_wp
      deformGrad(2,2) = 1.0_wp
      deformGrad(3,3) = 1.0_wp
      F_local = 0.0_wp
      IF (loadDef%dof >= 1 .AND. loadDef%dof <= 3) THEN
        F_local(loadDef%dof) = magnitude
      END IF
      IF (dofId > 0 .AND. dofId + 2 <= SIZE(F)) THEN
        F(dofId)   = F(dofId)   + F_local(1)
        F(dofId+1) = F(dofId+1) + F_local(2)
        F(dofId+2) = F(dofId+2) + F_local(3)
      END IF
    END DO
    status%status_code = IF_STATUS_OK
    status%message = "Follower force applied successfully"
  END SUBROUTINE ApplyLoad_FollowerForce

  SUBROUTINE ApplyLoad_PressureFollowing(F, model, loadDef, displacement, &
                                          time, amplitudes, status, md_layer)
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(LoadDef), INTENT(IN) :: loadDef
    REAL(wp), INTENT(IN) :: displacement(:)
    REAL(wp), INTENT(IN) :: time
    TYPE(MD_Amp_Slot_Desc), INTENT(IN), OPTIONAL :: amplitudes(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4) :: i, j, nodeId, dofId
    INTEGER(i4), ALLOCATABLE :: surfaceElements(:), faceNodes(:)
    REAL(wp) :: pressure, ampFactor
    REAL(wp) :: coords(3,4), currentCoords(3,4)
    REAL(wp) :: v1(3), v2(3), normal(3), area
    REAL(wp) :: nodalForce(3)
    INTEGER(i4) :: nElems, nFaceNodes
    CALL init_error_status(status)
    IF (loadDef%loadType /= LOAD_PRESSURE) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PressFollowing: Must be LOAD_PRESSURE type"
      RETURN
    END IF
    IF (loadDef%targetType /= TARGET_SURFACE) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PressFollowing: Must target a SURFACE"
      RETURN
    END IF
    ampFactor = 1.0_wp
    IF (loadDef%amplitudeId > 0) THEN
      IF (PRESENT(md_layer)) THEN
        ampFactor = md_lbc_amp_from_uf(model%amplitudes, loadDef%amplitudeId, time, md_layer)
      ELSE IF (PRESENT(amplitudes)) THEN
        ampFactor = Amp_GetFactor(amplitudes, loadDef%amplitudeId, time)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        ampFactor = Amp_GetFactor(model%amplitudes, loadDef%amplitudeId, time)
      END IF
    END IF
    pressure = loadDef%magnitude * ampFactor
    ALLOCATE(surfaceElements(0))
    IF (SIZE(surfaceElements) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PressFollowing: Surface has no elements"
      RETURN
    END IF
    nElems = SIZE(surfaceElements)
    DO i = 1, nElems
      CALL Ldbc_GetFaceNodes(model, surfaceElements(i), 1_i4, faceNodes)
      nFaceNodes = SIZE(faceNodes)
      IF (nFaceNodes < 3) CYCLE
      DO j = 1, MIN(nFaceNodes, 4)
        nodeId = faceNodes(j)
        dofId = (nodeId - 1) * 6 + 1
        IF (dofId + 2 > SIZE(displacement)) CYCLE
        currentCoords(:, j) = displacement(dofId:dofId+2)
      END DO
      v1 = currentCoords(:, 2) - currentCoords(:, 1)
      v2 = currentCoords(:, 3) - currentCoords(:, 1)
      normal(1) = v1(2) * v2(3) - v1(3) * v2(2)
      normal(2) = v1(3) * v2(1) - v1(1) * v2(3)
      normal(3) = v1(1) * v2(2) - v1(2) * v2(1)
      area = SQRT(DOT_PRODUCT(normal, normal))
      IF (area < 1.0e-12_wp) CYCLE
      normal = normal / area
      nodalForce = pressure * (area / REAL(nFaceNodes, wp)) * normal
      DO j = 1, nFaceNodes
        nodeId = faceNodes(j)
        dofId = (nodeId - 1) * 6 + 1
        IF (dofId + 2 > SIZE(F)) CYCLE
        F(dofId)   = F(dofId)   + nodalForce(1)
        F(dofId+1) = F(dofId+1) + nodalForce(2)
        F(dofId+2) = F(dofId+2) + nodalForce(3)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
    status%message = "Pressure following load applied successfully"
  END SUBROUTINE ApplyLoad_PressureFollowing

  SUBROUTINE ApplyLoad_BodyForce(F, model, loadDef, density, &
                                   time, amplitudes, status, md_layer)
    REAL(wp), INTENT(INOUT) :: F(:)
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(LoadDef), INTENT(IN) :: loadDef
    REAL(wp), INTENT(IN) :: density
    REAL(wp), INTENT(IN) :: time
    TYPE(MD_Amp_Slot_Desc), INTENT(IN), OPTIONAL :: amplitudes(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(MD_L3_LayerContainer), INTENT(IN), OPTIONAL :: md_layer
    INTEGER(i4) :: i, j, nodeId, dofId
    INTEGER(i4), ALLOCATABLE :: elemList(:), elemNodes(:)
    REAL(wp) :: magnitude(3), ampFactor
    REAL(wp) :: elemVolume, nodalForce
    INTEGER(i4) :: nElems, nNodes
    CALL init_error_status(status)
    IF (loadDef%loadType /= LOAD_BODY_FORCE .AND. &
        loadDef%loadType /= LOAD_GRAVITY .AND. &
        loadDef%loadType /= LOAD_CENTRIFUGA .AND. &
        loadDef%loadType /= LOAD_CORIOLIS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "BodyForce: Invalid load type"
      RETURN
    END IF
    ampFactor = 1.0_wp
    IF (loadDef%amplitudeId > 0) THEN
      IF (PRESENT(md_layer)) THEN
        ampFactor = md_lbc_amp_from_uf(model%amplitudes, loadDef%amplitudeId, time, md_layer)
      ELSE IF (PRESENT(amplitudes)) THEN
        ampFactor = Amp_GetFactor(amplitudes, loadDef%amplitudeId, time)
      ELSE IF (ALLOCATED(model%amplitudes)) THEN
        ampFactor = Amp_GetFactor(model%amplitudes, loadDef%amplitudeId, time)
      END IF
    END IF
    magnitude = 0.0_wp
    SELECT CASE (loadDef%loadType)
    CASE (LOAD_GRAVITY)
      magnitude(3) = -loadDef%magnitude * ampFactor
    CASE (LOAD_BODY_FORCE)
      IF (loadDef%dof >= 1 .AND. loadDef%dof <= 3) THEN
        magnitude(loadDef%dof) = loadDef%magnitude * ampFactor
      END IF
    CASE (LOAD_CENTRIFUGA)
      ! Centrifugal: F = rho * omega^2 * r
    CASE (LOAD_CORIOLIS)
      ! Coriolis: F = 2 * rho * omega x v
    END SELECT
    SELECT CASE (loadDef%targetType)
    CASE (TARGET_ELEMSET)
      CALL Ldbc_GetElemSetElements(model, loadDef%targetId, elemList)
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "BodyForce: Must target ELEMSET"
      RETURN
    END SELECT
    IF (.NOT. ALLOCATED(elemList)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "BodyForce: Element list not allocated"
      RETURN
    END IF
    nElems = SIZE(elemList)
    DO i = 1, nElems
      CALL Ldbc_GetElementNodes(model, elemList(i), elemNodes)
      IF (.NOT. ALLOCATED(elemNodes)) CYCLE
      nNodes = SIZE(elemNodes)
      IF (nNodes == 0) CYCLE
      elemVolume = 1.0_wp
      nodalForce = density * elemVolume / REAL(nNodes, wp)
      DO j = 1, nNodes
        nodeId = elemNodes(j)
        dofId = (nodeId - 1) * 6 + 1
        IF (dofId + 2 > SIZE(F)) CYCLE
        F(dofId)   = F(dofId)   + nodalForce * magnitude(1)
        F(dofId+1) = F(dofId+1) + nodalForce * magnitude(2)
        F(dofId+2) = F(dofId+2) + nodalForce * magnitude(3)
      END DO
      IF (ALLOCATED(elemNodes)) DEALLOCATE(elemNodes)
    END DO
    status%status_code = IF_STATUS_OK
    status%message = "Body force applied successfully"
  END SUBROUTINE ApplyLoad_BodyForce

  !============================================================================
  ! EXTENDED LOAD/BC API
  !============================================================================

  SUBROUTINE UF_DisplacementBC_GetStatistics(bc_def, stats, status)
    TYPE(BCDef), INTENT(IN) :: bc_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,I0,A,ES12.5,A,L1)') &
      'Displacement BC Statistics: id=', bc_def%cfg%id, &
      ', name="', TRIM(bc_def%name), &
      '", dof=', bc_def%dof, &
      ', value=', bc_def%value, &
      ', active=', bc_def%isActive
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_DisplacementBC_GetStatistics

  SUBROUTINE UF_DisplacementBC_ApplyAtTime(bc_def, time, amplitude_factor, &
                                            effective_value, status)
    TYPE(BCDef), INTENT(IN) :: bc_def
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(IN), OPTIONAL :: amplitude_factor
    REAL(wp), INTENT(OUT) :: effective_value
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (time < bc_def%startTime .OR. time > bc_def%endTime) THEN
      effective_value = 0.0_wp
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (PRESENT(amplitude_factor)) THEN
      effective_value = bc_def%value * amplitude_factor
    ELSE
      effective_value = bc_def%value
    END IF
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_DisplacementBC_ApplyAtTime

  SUBROUTINE UF_VelocityBC_GetStatistics(bc_def, stats, status)
    TYPE(BCDef), INTENT(IN) :: bc_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,I0,A,ES12.5,A,L1)') &
      'Velocity BC Statistics: id=', bc_def%cfg%id, &
      ', name="', TRIM(bc_def%name), &
      '", dof=', bc_def%dof, &
      ', value=', bc_def%value, &
      ', active=', bc_def%isActive
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_VelocityBC_GetStatistics

  SUBROUTINE UF_AccelerationBC_GetStatistics(bc_def, stats, status)
    TYPE(BCDef), INTENT(IN) :: bc_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,I0,A,ES12.5,A,L1)') &
      'Acceleration BC Statistics: id=', bc_def%cfg%id, &
      ', name="', TRIM(bc_def%name), &
      '", dof=', bc_def%dof, &
      ', value=', bc_def%value, &
      ', active=', bc_def%isActive
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_AccelerationBC_GetStatistics

  SUBROUTINE UF_ConcentratedLoad_GetStatistics(load_def, stats, status)
    TYPE(LoadDef), INTENT(IN) :: load_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,I0,A,ES12.5,A,L1)') &
      'Concentrated Load Statistics: id=', load_def%cfg%id, &
      ', name="', TRIM(load_def%name), &
      '", dof=', load_def%dof, &
      ', magnitude=', load_def%magnitude, &
      ', active=', load_def%isActive
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_ConcentratedLoad_GetStatistics

  SUBROUTINE UF_ConcentratedLoad_ApplyAtTime(load_def, time, amplitude_factor, &
                                             effective_magnitude, status)
    TYPE(LoadDef), INTENT(IN) :: load_def
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(IN), OPTIONAL :: amplitude_factor
    REAL(wp), INTENT(OUT) :: effective_magnitude
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (time < load_def%startTime .OR. time > load_def%endTime) THEN
      effective_magnitude = 0.0_wp
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (PRESENT(amplitude_factor)) THEN
      effective_magnitude = load_def%magnitude * amplitude_factor
    ELSE
      effective_magnitude = load_def%magnitude
    END IF
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_ConcentratedLoad_ApplyAtTime

  SUBROUTINE UF_DistributedLoad_GetStatistics(load_def, stats, status)
    TYPE(LoadDef), INTENT(IN) :: load_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,I0,A,ES12.5,A,L1)') &
      'Distributed Load Statistics: id=', load_def%cfg%id, &
      ', name="', TRIM(load_def%name), &
      '", targetType=', load_def%targetType, &
      ', magnitude=', load_def%magnitude, &
      ', active=', load_def%isActive
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_DistributedLoad_GetStatistics

  SUBROUTINE UF_DistributedLoad_ComputeNodalForces(load_def, element_area, &
                                                    nodal_forces, n_nodes, status)
    TYPE(LoadDef), INTENT(IN) :: load_def
    REAL(wp), INTENT(IN) :: element_area
    REAL(wp), INTENT(OUT) :: nodal_forces(:)
    INTEGER(i4), INTENT(IN) :: n_nodes
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: i
    REAL(wp) :: force_per_node
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (n_nodes > 0) THEN
      force_per_node = load_def%magnitude * element_area / REAL(n_nodes, wp)
      DO i = 1, MIN(n_nodes, SIZE(nodal_forces))
        nodal_forces(i) = force_per_node
      END DO
    ELSE
      nodal_forces = 0.0_wp
    END IF
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_DistributedLoad_ComputeNodalForces

  SUBROUTINE UF_InitialDisplacement_GetStatistics(ic_def, stats, status)
    TYPE(BCDef), INTENT(IN) :: ic_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,I0,A,ES12.5)') &
      'Initial Displacement Statistics: id=', ic_def%cfg%id, &
      ', name="', TRIM(ic_def%name), &
      '", dof=', ic_def%dof, &
      ', value=', ic_def%value
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_InitialDisplacement_GetStatistics

  SUBROUTINE UF_InitialVelocity_GetStatistics(ic_def, stats, status)
    TYPE(BCDef), INTENT(IN) :: ic_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,I0,A,ES12.5)') &
      'Initial Velocity Statistics: id=', ic_def%cfg%id, &
      ', name="', TRIM(ic_def%name), &
      '", dof=', ic_def%dof, &
      ', value=', ic_def%value
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_InitialVelocity_GetStatistics

  SUBROUTINE UF_InitialTemperature_GetStatistics(ic_def, stats, status)
    TYPE(BCDef), INTENT(IN) :: ic_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,ES12.5)') &
      'Initial Temperature Statistics: id=', ic_def%cfg%id, &
      ', name="', TRIM(ic_def%name), &
      '", value=', ic_def%value
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_InitialTemperature_GetStatistics

  SUBROUTINE UF_TemperatureField_GetStatistics(field_def, stats, status)
    TYPE(BCDef), INTENT(IN) :: field_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A,A,I0,A,ES12.5,A,L1)') &
      'Temperature Field Statistics: id=', field_def%cfg%id, &
      ', name="', TRIM(field_def%name), &
      '", targetType=', field_def%targetType, &
      ', value=', field_def%value, &
      ', active=', field_def%isActive
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_TemperatureField_GetStatistics

  SUBROUTINE UF_TemperatureField_Interpolate(field_def, coordinates, &
                                              temperature, status)
    TYPE(BCDef), INTENT(IN) :: field_def
    REAL(wp), INTENT(IN) :: coordinates(3)
    REAL(wp), INTENT(OUT) :: temperature
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    temperature = field_def%value
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_TemperatureField_Interpolate

  SUBROUTINE MD_Amp_Slot_GetStatistics(amp_def, stats, status)
    TYPE(MD_Amp_Slot_Desc), INTENT(IN) :: amp_def
    CHARACTER(LEN=512), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    WRITE(stats, '(A,I0,A,A)') &
      'Amplitude Statistics: id=', amp_def%cfg%id, &
      ', name="', TRIM(amp_def%name), '"'
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Amp_Slot_GetStatistics

  SUBROUTINE UF_LoadCombination_ComputeEffectiveLoad(load_defs, n_loads, &
                                                      combination_factors, &
                                                      effective_load, status)
    TYPE(LoadDef), INTENT(IN) :: load_defs(:)
    INTEGER(i4), INTENT(IN) :: n_loads
    REAL(wp), INTENT(IN) :: combination_factors(:)
    REAL(wp), INTENT(OUT) :: effective_load
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: i
    IF (PRESENT(status)) CALL init_error_status(status)
    effective_load = 0.0_wp
    DO i = 1, MIN(n_loads, SIZE(load_defs), SIZE(combination_factors))
      IF (load_defs(i)%isActive) THEN
        effective_load = effective_load + &
                         load_defs(i)%magnitude * combination_factors(i)
      END IF
    END DO
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_LoadCombination_ComputeEffectiveLoad

END MODULE MD_LBC_Apply
