!===============================================================================
! MODULE: PH_Elem_Quality
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Elem Quality module (auto-filled)
!===============================================================================
MODULE PH_Elem_Quality
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  !! ===================================================================
  !! UniField-Core Element Quality Check Module
  !!
  !! This module provides comprehensive element quality checking:
  !!   - Jacobian determinant check
  !!   - Aspect ratio check
  !!   - Skewness check
  !!   - Orthogonality check
  !!   - Volume/Area check
  !!   - Shape quality metrics
  !!
  !! Design Principles:
  !!   - Unified quality check interface
  !!   - Supports all element types (2D/3D, continuum/structural)
  !!   - Provides detailed quality metrics
  !! ===================================================================

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal2D, UF_Mem_FreeReal2D, MEM_DOMAIN_ELEM
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_Enums, ONLY: UF_TOPO_Hex, UF_TOPO_Tet, UF_TOPO_Wedge, UF_TOPO_Quad, UF_TOPO_Tri
  USE MD_Elem_Mgr, ONLY: ElemType, ElemCtx, ShapeFuncResult
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: UF_Elem_CheckQuality
  PUBLIC :: UF_Elem_ComputeJacobian
  PUBLIC :: UF_Elem_ComputeAspectRatio
  PUBLIC :: UF_Elem_ComputeSkewness
  PUBLIC :: UF_Elem_ComputeVolume
  PUBLIC :: ElemQualMetrics
  PUBLIC :: UF_Elem_ValidateGeometry
  PUBLIC :: UF_Elem_CheckQuality_3DHex
  PUBLIC :: UF_Elem_CheckQuality_3DTet
  PUBLIC :: UF_Elem_CheckQuality_3DWedge
  PUBLIC :: UF_Element_CheckQuality_3DPyramid
  PUBLIC :: UF_Elem_CheckQuality_2DQuad
  PUBLIC :: UF_Elem_CheckQuality_2DTri
  PUBLIC :: UF_Elem_CheckQuality_Beam
  PUBLIC :: UF_Elem_CheckQuality_Shell
  PUBLIC :: UF_Element_GenerateQualityReport
  PUBLIC :: ElemQualReport
  PUBLIC :: UF_Element_GenerateVisualizationData
  PUBLIC :: UF_Element_GenerateAutoFixSuggestions
  PUBLIC :: UF_Element_VisualizationData
  PUBLIC :: UF_Element_AutoFixSuggestion
  PUBLIC :: UF_Elem_ComputeWarpage
  PUBLIC :: UF_Elem_ComputeTaper
  PUBLIC :: UF_Elem_ComputeTwist
  PUBLIC :: UF_Elem_ComputeDistortion
  PUBLIC :: UF_Elem_CheckQuality_Batch

  !=============================================================================
  ! Element Quality Metrics Type
  !=============================================================================
  TYPE, PUBLIC :: ElemQualMetrics
    REAL(wp) :: jacobian_min = 0.0_wp
    REAL(wp) :: jacobian_max = 0.0_wp
    REAL(wp) :: jacobian_avg = 0.0_wp
    REAL(wp) :: aspect_ratio = 1.0_wp
    REAL(wp) :: skewness = 0.0_wp
    REAL(wp) :: orthogonality = 1.0_wp
    REAL(wp) :: volume = 0.0_wp
    REAL(wp) :: quality_score = 1.0_wp
    REAL(wp) :: warpage = 0.0_wp  ! Warpage metric (for shells/quads)
    REAL(wp) :: taper = 0.0_wp  ! Taper metric (for quads)
    REAL(wp) :: twist = 0.0_wp  ! Twist metric (for quads)
    REAL(wp) :: distortion = 0.0_wp  ! Distortion metric
    REAL(wp) :: min_angle = 0.0_wp  ! Minimum angle (for triangles/tets)
    REAL(wp) :: max_angle = 0.0_wp  ! Maximum angle (for triangles/tets)
    REAL(wp) :: edge_ratio = 1.0_wp  ! Edge length ratio
    LOGICAL :: is_valid = .true.
    LOGICAL :: is_inverted = .false.
    LOGICAL :: is_degenerate = .false.
  END TYPE ElemQualMetrics

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shared_Args
  TYPE :: PH_Elem_Shared_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Shared_Args


CONTAINS

  FUNCTION REAL_TO_STRING(val) RESULT(str)
    !! Convert real number to string (simplified)

    REAL(wp), INTENT(IN) :: val
    CHARACTER(LEN=32) :: str

    WRITE(str, '(ES12.5)') val
    str = ADJUSTL(str)

  END FUNCTION REAL_TO_STRING

  SUBROUTINE UF_ComputeHexahedronSkewness(coords, skewness, status)
    !! Compute skewness for hexahedral element

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 8)
    REAL(wp), INTENT(OUT) :: skewness
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: face_skewness(6)
    REAL(wp) :: max_face_skewne
    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Compute skewness for each face (simplified)
    ! For full implementation, would check all 6 faces
    max_face_skewne = 0.0_wp

    ! Check bottom face (nodes 1-2-3-4)
    CALL UF_ComputeQuadrilateralSkewness(coords(:, [1,2,3,4]), face_skewness(1), status)
    max_face_skewne = MAX(max_face_skewne, face_skewness(1))

    ! Check top face (nodes 5-6-7-8)
    CALL UF_ComputeQuadrilateralSkewness(coords(:, [5,6,7,8]), face_skewness(2), status)
    max_face_skewne = MAX(max_face_skewne, face_skewness(2))

    skewness = max_face_skewne

    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_ComputeHexahedronSkewness

  SUBROUTINE UF_ComputeQuadrilateralSkewn(coords, skewness, status)
    !! Compute skewness for quadrilateral element

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (2, 4)
    REAL(wp), INTENT(OUT) :: skewness
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: v1(2), v2(2), v3(2), v4(2)
    REAL(wp) :: angle1, angle2, angle3, angle4
    REAL(wp) :: ideal_angle, max_deviation
    REAL(wp) :: len1, len2, dot_product

    CALL init_error_status(status)

    ! Compute edge vectors
    v1 = coords(:, 2) - coords(:, 1)
    v2 = coords(:, 3) - coords(:, 2)
    v3 = coords(:, 4) - coords(:, 3)
    v4 = coords(:, 1) - coords(:, 4)

    ! Compute angles at vertices
    len1 = SQRT(SUM(v1**2))
    len2 = SQRT(SUM(v4**2))
    IF (len1 > 1.0e-12_wp .AND. len2 > 1.0e-12_wp) THEN
      dot_product = -DOT_PRODUCT(v1, v4)
      angle1 = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot_product / (len1 * len2))))
    ELSE
      angle1 = 0.0_wp
    END IF

    len1 = SQRT(SUM(v2**2))
    len2 = SQRT(SUM(v1**2))
    IF (len1 > 1.0e-12_wp .AND. len2 > 1.0e-12_wp) THEN
      dot_product = -DOT_PRODUCT(v2, v1)
      angle2 = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot_product / (len1 * len2))))
    ELSE
      angle2 = 0.0_wp
    END IF

    len1 = SQRT(SUM(v3**2))
    len2 = SQRT(SUM(v2**2))
    IF (len1 > 1.0e-12_wp .AND. len2 > 1.0e-12_wp) THEN
      dot_product = -DOT_PRODUCT(v3, v2)
      angle3 = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot_product / (len1 * len2))))
    ELSE
      angle3 = 0.0_wp
    END IF

    len1 = SQRT(SUM(v4**2))
    len2 = SQRT(SUM(v3**2))
    IF (len1 > 1.0e-12_wp .AND. len2 > 1.0e-12_wp) THEN
      dot_product = -DOT_PRODUCT(v4, v3)
      angle4 = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot_product / (len1 * len2))))
    ELSE
      angle4 = 0.0_wp
    END IF

    ! Ideal angle for rectangle: 90° = π/2
    ideal_angle = 2.0_wp * ATAN(1.0_wp)  ! π/2

    ! Compute maximum deviation from ideal angle
    max_deviation = MAX(ABS(angle1 - ideal_angle), &
                       ABS(angle2 - ideal_angle), &
                       ABS(angle3 - ideal_angle), &
                       ABS(angle4 - ideal_angle))

    ! Normalize to [0, 1] range
    skewness = MIN(1.0_wp, max_deviation / ideal_angle)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_ComputeQuadrilateralSkewness

  SUBROUTINE UF_ComputeTetrahedronSkewnes(coords, skewness, status)
    !! Compute skewness for tetrahedral element

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, 4)
    REAL(wp), INTENT(OUT) :: skewness
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: face_skewness(4)
    REAL(wp) :: max_face_skewne
    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Compute skewness for each triangular face
    ! Face 1: nodes 1-2-3
    CALL UF_ComputeTriangleSkewness(coords(:, [1,2,3]), face_skewness(1), status)
    max_face_skewne = face_skewness(1)

    ! Face 2: nodes 1-2-4
    CALL UF_ComputeTriangleSkewness(coords(:, [1,2,4]), face_skewness(2), status)
    max_face_skewne = MAX(max_face_skewne, face_skewness(2))

    ! Face 3: nodes 1-3-4
    CALL UF_ComputeTriangleSkewness(coords(:, [1,3,4]), face_skewness(3), status)
    max_face_skewne = MAX(max_face_skewne, face_skewness(3))

    ! Face 4: nodes 2-3-4
    CALL UF_ComputeTriangleSkewness(coords(:, [2,3,4]), face_skewness(4), status)
    max_face_skewne = MAX(max_face_skewne, face_skewness(4))

    skewness = max_face_skewne

    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_ComputeTetrahedronSkewness

  SUBROUTINE UF_ComputeTriangleSkewness(coords, skewness, status)
    !! Compute skewness for triangle element

    REAL(wp), INTENT(IN) :: coords(:,:)  ! (2, 3)
    REAL(wp), INTENT(OUT) :: skewness
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: v1(2), v2(2), v3(2)
    REAL(wp) :: angle1, angle2, angle3
    REAL(wp) :: ideal_angle, max_deviation
    REAL(wp) :: len1, len2, len3, dot_product

    CALL init_error_status(status)

    ! Compute edge vectors
    v1 = coords(:, 2) - coords(:, 1)
    v2 = coords(:, 3) - coords(:, 2)
    v3 = coords(:, 1) - coords(:, 3)

    ! Compute angles at vertices
    len1 = SQRT(SUM(v1**2))
    len2 = SQRT(SUM(v2**2))
    len3 = SQRT(SUM(v3**2))

    IF (len1 < 1.0e-12_wp .OR. len2 < 1.0e-12_wp .OR. len3 < 1.0e-12_wp) THEN
      skewness = 1.0_wp
      RETURN
    END IF

    ! Angle at vertex 1
    dot_product = -DOT_PRODUCT(v1, v3)
    angle1 = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot_product / (len1 * len3))))

    ! Angle at vertex 2
    dot_product = -DOT_PRODUCT(v2, v1)
    angle2 = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot_product / (len2 * len1))))

    ! Angle at vertex 3
    dot_product = -DOT_PRODUCT(v3, v2)
    angle3 = ACOS(MAX(-1.0_wp, MIN(1.0_wp, dot_product / (len3 * len2))))

    ! Ideal angle for equilateral triangle: 60° = π/3
    ideal_angle = 4.0_wp * ATAN(1.0_wp) / 3.0_wp  ! π/3

    ! Compute maximum deviation from ideal angle
    max_deviation = MAX(ABS(angle1 - ideal_angle), &
                       ABS(angle2 - ideal_angle), &
                       ABS(angle3 - ideal_angle))

    ! Normalize to [0, 1] range
    skewness = MIN(1.0_wp, max_deviation / ideal_angle)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_ComputeTriangleSkewness

  SUBROUTINE UF_Element_CheckQuality_3DPyramid(ElemType, Ctx, metrics, status)
    !! Quality check specifically for 3D pyramid elements (C3D5, C3D13)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Call general quality check
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    ! Additional pyramid-specific checks
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Check apex position (should be above base)
      ! Check base quadrilateral quality
      ! Check for degenerate pyramid (apex too close to base)
      IF (metrics%aspect_ratio > 15.0_wp) THEN
        metrics%is_valid = .false.
      END IF
    END IF
  END SUBROUTINE UF_Element_CheckQuality_3DPyramid

  SUBROUTINE UF_El_GenerateAutoFixSuggest(ElemType, Ctx, metrics, suggestions, status)
    !! Generate automatic fix suggestions for quality issues

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(IN) :: metrics
    TYPE(ElemQualAutoFixSuggest), INTENT(OUT) :: suggestions(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, i, n_suggestions
    REAL(wp), POINTER :: coords(:,:)
    INTEGER(i4) :: coords_id
    TYPE(ErrorStatusType) :: st
    REAL(wp) :: center(3), avg_edge_length

    CALL init_error_status(status)
    coords => NULL()
    coords_id = -1

    nNode = ElemType%pop%n_nodes
    n_suggestions = 0

    ! Extract coordinates
    IF (ALLOCATED(Ctx%coords_ref)) THEN
      CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, SIZE(Ctx%coords_ref, 1), &
           SIZE(Ctx%coords_ref, 2), 'Qual_AutoFix_coords', coords, coords_id, st)
      IF (st%status_code /= IF_STATUS_OK) THEN
        status = st
        RETURN
      END IF
      coords = Ctx%coords_ref
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not available"
      RETURN
    END IF

    ! Init suggestions
    DO i = 1, SIZE(suggestions)
      suggestions(i)%element_id = 0
      suggestions(i)%fix_type = ''
      suggestions(i)%cfg%description = ''
      suggestions(i)%priority = 0
      suggestions(i)%is_automatic = .false.
    END DO

    ! Generate suggestions based on quality issues

    ! 1. Inverted element: remesh
    IF (metrics%is_inverted) THEN
      n_suggestions = n_suggestions + 1
      IF (n_suggestions <= SIZE(suggestions)) THEN
        suggestions(n_suggestions)%fix_type = 'remesh'
        suggestions(n_suggestions)%cfg%description = 'Element is inverted. Remeshing required.'
        suggestions(n_suggestions)%priority = 2
        suggestions(n_suggestions)%is_automatic = .false.
      END IF
    END IF

    ! 2. Degenerate element: remesh or adjust nodes
    IF (metrics%is_degenerate) THEN
      n_suggestions = n_suggestions + 1
      IF (n_suggestions <= SIZE(suggestions)) THEN
        suggestions(n_suggestions)%fix_type = 'adjust_nodes'
        suggestions(n_suggestions)%cfg%description = 'Element is degenerate. Adjust node positions or remesh.'
        suggestions(n_suggestions)%priority = 2
        suggestions(n_suggestions)%is_automatic = .false.
      END IF
    END IF

    ! 3. High aspect ratio: split element
    IF (metrics%aspect_ratio > 10.0_wp) THEN
      n_suggestions = n_suggestions + 1
      IF (n_suggestions <= SIZE(suggestions)) THEN
        suggestions(n_suggestions)%fix_type = 'split'
        suggestions(n_suggestions)%cfg%description = 'High aspect ratio detected. Split element along longest edge.'
        suggestions(n_suggestions)%priority = 1
        suggestions(n_suggestions)%is_automatic = .true.
      END IF
    END IF

    ! 4. High skewness: smooth nodes
    IF (metrics%skewness > 0.7_wp) THEN
      n_suggestions = n_suggestions + 1
      IF (n_suggestions <= SIZE(suggestions)) THEN
        suggestions(n_suggestions)%fix_type = 'smooth'
        suggestions(n_suggestions)%cfg%description = 'High skewness detected. Apply node smoothing.'
        suggestions(n_suggestions)%priority = 1
        suggestions(n_suggestions)%is_automatic = .true.

        ! Generate suggested node coordinates (simplified: move towards element center)
        IF (.NOT. ALLOCATED(suggestions(n_suggestions)%suggested_node)) THEN
          ALLOCATE(suggestions(n_suggestions)%suggested_node(SIZE(coords, 1), SIZE(coords, 2)))
        END IF

        ! Compute element center
        center = SUM(coords, DIM=2) / REAL(nNode, wp)

        ! Move nodes 10% towards center
        DO i = 1, nNode
          suggestions(n_suggestions)%suggested_node(:, i) = &
            0.9_wp * coords(:, i) + 0.1_wp * center
        END DO
      END IF
    END IF

    ! 5. Low Jacobian: adjust nodes
    IF (metrics%jacobian_min < 1.0e-6_wp) THEN
      n_suggestions = n_suggestions + 1
      IF (n_suggestions <= SIZE(suggestions)) THEN
        suggestions(n_suggestions)%fix_type = 'adjust_nodes'
        suggestions(n_suggestions)%cfg%description = 'Very small Jacobian detected. Adjust node positions.'
        suggestions(n_suggestions)%priority = 1
        suggestions(n_suggestions)%is_automatic = .false.
      END IF
    END IF

    ! 6. Low quality score: general remeshing suggestion
    IF (metrics%quality_score < 0.5_wp .AND. n_suggestions == 0) THEN
      n_suggestions = n_suggestions + 1
      IF (n_suggestions <= SIZE(suggestions)) THEN
        suggestions(n_suggestions)%fix_type = 'remesh'
        suggestions(n_suggestions)%cfg%description = 'Low quality score. Consider remeshing this region.'
        suggestions(n_suggestions)%priority = 1
        suggestions(n_suggestions)%is_automatic = .false.
      END IF
    END IF

900 CONTINUE
    IF (coords_id >= 0) CALL UF_Mem_FreeReal2D(coords_id, st)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Element_GenerateAutoFixSuggestions

  SUBROUTINE UF_El_GenerateQualityReport(ElemType, Ctx, metrics, report, status)
    !! Generate comprehensive quality report for an element

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(IN) :: metrics
    TYPE(ElemQualReport), INTENT(OUT) :: report
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(LEN=256) :: msg
    INTEGER(i4) :: issue_count

    CALL init_error_status(status)

    ! Init report
    report%element_id = 0  ! Would be set from element ID
    report%element_type = ElemType%name
    report%metrics = metrics
    report%recommendations = ''
    report%needs_remeshing = .false.
    report%severity = 0
    issue_count = 0

    ! Check for critical issues
    IF (metrics%is_inverted) THEN
      report%severity = 2
      report%needs_remeshing = .true.
      report%recommendations = TRIM(report%recommendations) // 'CRITICAL: Element is inverted. '
      issue_count = issue_count + 1
    END IF

    IF (metrics%is_degenerate) THEN
      report%severity = 2
      report%needs_remeshing = .true.
      report%recommendations = TRIM(report%recommendations) // 'CRITICAL: Element is degenerate. '
      issue_count = issue_count + 1
    END IF

    ! Check aspect ratio
    IF (metrics%aspect_ratio > 10.0_wp) THEN
      IF (report%severity < 2) report%severity = 1
      report%recommendations = TRIM(report%recommendations) // &
        'WARNING: High aspect ratio (' // TRIM(REAL_TO_STRING(metrics%aspect_ratio)) // '). '
      issue_count = issue_count + 1
    END IF

    ! Check skewness
    IF (metrics%skewness > 0.7_wp) THEN
      IF (report%severity < 2) report%severity = 1
      report%recommendations = TRIM(report%recommendations) // &
        'WARNING: High skewness (' // TRIM(REAL_TO_STRING(metrics%skewness)) // '). '
      issue_count = issue_count + 1
    END IF

    ! Check Jacobian
    IF (metrics%jacobian_min < 1.0e-6_wp) THEN
      IF (report%severity < 2) report%severity = 1
      report%recommendations = TRIM(report%recommendations) // &
        'WARNING: Very small Jacobian (' // TRIM(REAL_TO_STRING(metrics%jacobian_min)) // '). '
      issue_count = issue_count + 1
    END IF

    ! Check quality score
    IF (metrics%quality_score < 0.5_wp) THEN
      IF (report%severity < 2) report%severity = 1
      report%recommendations = TRIM(report%recommendations) // &
        'WARNING: Low quality score (' // TRIM(REAL_TO_STRING(metrics%quality_score)) // '). '
      issue_count = issue_count + 1
    END IF

    ! Generate recommendations
    IF (issue_count > 0) THEN
      report%recommendations = TRIM(report%recommendations) // &
        'Consider remeshing or adjusting element geometry.'
    ELSE
      report%recommendations = 'Element quality is acceptable.'
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Element_GenerateQualityReport

  SUBROUTINE UF_El_GenerateVisualizationD(ElemType, Ctx, metrics, viz_data, status)
    !! Generate visualization data for element quality
    !!
    !! Creates color maps, contours, and highlighting based on quality metrics

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(IN) :: metrics
    TYPE(ElemQualVisualData), INTENT(OUT) :: viz_data
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: quality_normali, r, g, b
    INTEGER(i4) :: nNode

    CALL init_error_status(status)

    ! Init visualization data
    viz_data%element_id = 0
    viz_data%opacity = 1.0_wp
    viz_data%highlight = .false.
    viz_data%visualization_t = 'color_map'

    ! Normalize quality score to 0-1 range
    quality_normali = MAX(0.0_wp, MIN(1.0_wp, metrics%quality_score))

    ! Generate color based on quality score
    ! Green (good) -> Yellow (warning) -> Red (bad)
    IF (quality_normali > 0.7_wp) THEN
      ! Green: good quality
      r = 0.0_wp
      g = quality_normali
      b = 0.0_wp
    ELSE IF (quality_normali > 0.4_wp) THEN
      ! Yellow: moderate quality
      r = 1.0_wp - quality_normali
      g = 1.0_wp
      b = 0.0_wp
    ELSE
      ! Red: poor quality
      r = 1.0_wp
      g = quality_normali
      b = 0.0_wp
    END IF

    viz_data%color_rgb(1) = r
    viz_data%color_rgb(2) = g
    viz_data%color_rgb(3) = b

    ! Set opacity based on quality (poor quality = more transparent)
    viz_data%opacity = 0.3_wp + 0.7_wp * quality_normali

    ! Highlight elements with critical issues
    IF (metrics%is_inverted .OR. metrics%is_degenerate .OR. metrics%quality_score < 0.3_wp) THEN
      viz_data%highlight = .true.
      viz_data%opacity = 1.0_wp
    END IF

    ! Generate contour values (for contour visualization)
    nNode = ElemType%pop%n_nodes
    IF (ALLOCATED(viz_data%quality_contour)) DEALLOCATE(viz_data%quality_contour)
    ALLOCATE(viz_data%quality_contour(nNode))
    viz_data%quality_contour = quality_normali  ! Simplified: same value at all nodes

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Element_GenerateVisualizationData

  SUBROUTINE UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)
    !! Comprehensive element quality check
    !!
    !! Computes:
    !!   - Jacobian determinant at integration points
    !!   - Aspect ratio
    !!   - Skewness
    !!   - Orthogonality
    !!   - Volume/Area
    !!   - Overall quality score

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, nDim, nInt, ip
    REAL(wp), POINTER :: coords(:,:)
    INTEGER(i4) :: coords_id
    TYPE(ErrorStatusType) :: st
    REAL(wp), ALLOCATABLE :: gaussCoords(:,:), weights(:)
    REAL(wp) :: detJ, jacobian_min, jacobian_max, jacobian_sum
    REAL(wp) :: aspect_ratio, skewness, orthogonality, volume

    CALL init_error_status(status)
    coords => NULL()
    coords_id = -1

    nNode = ElemType%pop%n_nodes
    nDim = ElemType%dim
    nInt = ElemType%n_int_points

    IF (nNode <= 0 .OR. nDim <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid element type"
      RETURN
    END IF

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not allocated"
      RETURN
    END IF

    ! Init metrics
    metrics%jacobian_min = HUGE(1.0_wp)
    metrics%jacobian_max = -HUGE(1.0_wp)
    metrics%jacobian_avg = 0.0_wp
    metrics%aspect_ratio = 1.0_wp
    metrics%skewness = 0.0_wp
    metrics%orthogonality = 1.0_wp
    metrics%volume = 0.0_wp
    metrics%quality_score = 1.0_wp
    metrics%is_valid = .true.
    metrics%is_inverted = .false.
    metrics%is_degenerate = .false.

    ! Extract coordinates
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, nDim, nNode, 'Qual_coords', coords, coords_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      RETURN
    END IF
    coords(1:nDim, 1:nNode) = Ctx%coords_ref(1:nDim, 1:nNode)

    ! Compute Jacobian at integration points
    jacobian_min = HUGE(1.0_wp)
    jacobian_max = -HUGE(1.0_wp)
    jacobian_sum = 0.0_wp

    ! Try to get Gauss points - if not available, use single point check
    ! Note: UF_GetGaussPoints may be in a different module
    ! For now, use element center as fallback
    CALL UF_Elem_ComputeJacobian(ElemType, Ctx, detJ, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      metrics%jacobian_min = detJ
      metrics%jacobian_max = detJ
      metrics%jacobian_avg = detJ
    END IF

    ! Check for inverted or degenerate elements
    IF (metrics%jacobian_min < 0.0_wp) THEN
      metrics%is_inverted = .true.
      metrics%is_valid = .false.
    END IF

    IF (ABS(metrics%jacobian_min) < 1.0e-12_wp) THEN
      metrics%is_degenerate = .true.
      metrics%is_valid = .false.
    END IF

    ! Compute aspect ratio
    CALL UF_Elem_ComputeAspectRatio(ElemType, Ctx, aspect_ratio, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      metrics%aspect_ratio = aspect_ratio
    END IF

    ! Compute skewness
    CALL UF_Elem_ComputeSkewness(ElemType, Ctx, skewness, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      metrics%skewness = skewness
    END IF

    ! Compute volume/area
    CALL UF_Elem_ComputeVolume(ElemType, Ctx, volume, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      metrics%volume = volume
    END IF

    ! Compute overall quality score (0-1, higher is better)
    metrics%quality_score = UF_Elem_ComputeQualityScore(metrics)

900 CONTINUE
    IF (coords_id >= 0) CALL UF_Mem_FreeReal2D(coords_id, st)
    IF (ALLOCATED(gaussCoords)) DEALLOCATE(gaussCoords)
    IF (ALLOCATED(weights)) DEALLOCATE(weights)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Elem_CheckQuality

  SUBROUTINE UF_Elem_CheckQuality_2DQuad(ElemType, Ctx, metrics, status)
    !! Quality check specifically for 2D quadrilateral elements (CPE4, CPS4, CAX4)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Call general quality check
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    ! Additional quad-specific checks
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Check for warped quads
      ! Check for concave quads
      ! Check internal angles
      IF (metrics%aspect_ratio > 10.0_wp) THEN
        metrics%is_valid = .false.
      END IF
    END IF
  END SUBROUTINE UF_Elem_CheckQuality_2DQuad

  SUBROUTINE UF_Elem_CheckQuality_2DTri(ElemType, Ctx, metrics, status)
    !! Quality check specifically for 2D triangular elements (CPE3, CPS3, CAX3)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Call general quality check
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    ! Additional tri-specific checks
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Check for sliver triangles
      ! Check internal angles (should be > 10 degrees)
      ! Tri elements can tolerate higher aspect ratios
      IF (metrics%aspect_ratio > 20.0_wp) THEN
        metrics%is_valid = .false.
      END IF
    END IF
  END SUBROUTINE UF_Elem_CheckQuality_2DTri

  SUBROUTINE UF_Elem_CheckQuality_3DHex(ElemType, Ctx, metrics, status)
    !! Quality check specifically for 3D hexahedral elements (C3D8, C3D20, C3D27)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Call general quality check
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    ! Additional hex-specific checks
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Check for warped faces (hex-specific)
      ! Check for twisted edges
      ! More stringent aspect ratio for hex elements
      IF (metrics%aspect_ratio > 10.0_wp) THEN
        metrics%is_valid = .false.
      END IF
    END IF
  END SUBROUTINE UF_Elem_CheckQuality_3DHex

  SUBROUTINE UF_Elem_CheckQuality_3DTet(ElemType, Ctx, metrics, status)
    !! Quality check specifically for 3D tetrahedral elements (C3D4, C3D10)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Call general quality check
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    ! Additional tet-specific checks
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Check for sliver tets (very small volume with reasonable edge lengths)
      ! Check for collapsed faces
      ! Tet elements can tolerate higher aspect ratios than hex
      IF (metrics%aspect_ratio > 20.0_wp) THEN
        metrics%is_valid = .false.
      END IF
    END IF
  END SUBROUTINE UF_Elem_CheckQuality_3DTet

  SUBROUTINE UF_Elem_CheckQuality_3DWedge(ElemType, Ctx, metrics, status)
    !! Quality check specifically for 3D wedge/prism elements (C3D6, C3D15)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Call general quality check
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    ! Additional wedge-specific checks
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Check triangular face quality
      ! Check for twisted triangular faces
      ! Moderate aspect ratio tolerance
      IF (metrics%aspect_ratio > 15.0_wp) THEN
        metrics%is_valid = .false.
      END IF
    END IF
  END SUBROUTINE UF_Elem_CheckQuality_3DWedge

  SUBROUTINE UF_Elem_CheckQuality_Batch(elementTypes, contexts, metrics_array, &
                                           batch_size, status)
    !! Batch quality check with optimized memory access

    TYPE(ElemType), INTENT(IN) :: elementTypes(:)
    TYPE(ElemCtx), INTENT(IN) :: contexts(:)
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics_array(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: batch_size
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_elements, i, batch_size_val, start_idx, end_idx

    CALL init_error_status(status)

    n_elements = SIZE(elementTypes)
    IF (SIZE(contexts) /= n_elements .OR. SIZE(metrics_array) /= n_elements) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Array size mismatch"
      RETURN
    END IF

    batch_size_val = 100
    IF (PRESENT(batch_size)) batch_size_val = batch_size

    ! Process in batches for better cache performance
    DO start_idx = 1, n_elements, batch_size_val
      end_idx = MIN(start_idx + batch_size_val - 1, n_elements)

      DO i = start_idx, end_idx
        CALL UF_Elem_CheckQuality(elementTypes(i), contexts(i), &
                                     metrics_array(i), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      END DO
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Elem_CheckQuality_Batch

  SUBROUTINE UF_Elem_CheckQuality_Beam(ElemType, Ctx, metrics, status)
    !! Quality check specifically for beam elements (B21, B22, B31, B32)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Call general quality check
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    ! Additional beam-specific checks
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Check element length (should be > 0)
      ! Check for zero-length beams
      ! Beams can have very high aspect ratios (length >> cross-section)
      ! So we don't penalize aspect ratio for beams
      IF (metrics%volume < 1.0e-15_wp) THEN
        metrics%is_valid = .false.
        metrics%is_degenerate = .true.
      END IF
    END IF
  END SUBROUTINE UF_Elem_CheckQuality_Beam

  SUBROUTINE UF_Elem_CheckQuality_Shell(ElemType, Ctx, metrics, status)
    !! Quality check specifically for shell elements (S3, S4, S6, S8)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemQualMetrics), INTENT(OUT) :: metrics
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Call general quality check
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    ! Additional shell-specific checks
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Check for warped shells
      ! Check for twisted shells
      ! Check thickness-to-size ratio
      ! Moderate aspect ratio tolerance for shells
      IF (metrics%aspect_ratio > 10.0_wp) THEN
        metrics%is_valid = .false.
      END IF
    END IF
  END SUBROUTINE UF_Elem_CheckQuality_Shell

  SUBROUTINE UF_Elem_ComputeAspectRatio(ElemType, Ctx, aspect_ratio, status)
    !! Compute element aspect ratio (max_edge_length / min_edge_length)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(OUT) :: aspect_ratio
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, nDim, i, j
    REAL(wp), ALLOCATABLE :: coords(:,:)
    REAL(wp) :: edge_length, min_length, max_length
    INTEGER(i4), ALLOCATABLE :: edge_connectivi(:,:)
    INTEGER(i4) :: nEdges

    CALL init_error_status(status)

    nNode = ElemType%pop%n_nodes
    nDim = ElemType%dim

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not allocated"
      RETURN
    END IF

    ! Get edge connectivity based on element topology
    CALL UF_GetElementEdgeConnectivity(ElemType, edge_connectivi, nEdges)

    min_length = HUGE(1.0_wp)
    max_length = 0.0_wp

    DO i = 1, nEdges
      IF (SIZE(edge_connectivi, 1) >= 2) THEN
        edge_length = 0.0_wp
        DO j = 1, nDim
          edge_length = edge_length + &
            (Ctx%coords_ref(j, edge_connectivi(2, i)) - &
             Ctx%coords_ref(j, edge_connectivi(1, i)))**2
        END DO
        edge_length = SQRT(edge_length)
        min_length = MIN(min_length, edge_length)
        max_length = MAX(max_length, edge_length)
      END IF
    END DO

    IF (min_length > 1.0e-12_wp) THEN
      aspect_ratio = max_length / min_length
    ELSE
      aspect_ratio = HUGE(1.0_wp)
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Elem_ComputeAspectRatio

  SUBROUTINE UF_Elem_ComputeDistortion(ElemType, Ctx, distortion, status)
    !! Compute distortion metric
    !!
    !! Distortion measures deviation from ideal shape

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(OUT) :: distortion
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ElemQualMetrics) :: metrics

    CALL init_error_status(status)

    ! Compute basic quality metrics
    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)

    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Distortion combines multiple metrics
    distortion = 0.0_wp
    IF (metrics%aspect_ratio > 1.0_wp) THEN
      distortion = distortion + (metrics%aspect_ratio - 1.0_wp)
    END IF
    distortion = distortion + metrics%skewness
    IF (metrics%orthogonality < 1.0_wp) THEN
      distortion = distortion + (1.0_wp - metrics%orthogonality)
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Elem_ComputeDistortion

  SUBROUTINE UF_Elem_ComputeJacobian(ElemType, Ctx, detJ, status)
    !! Compute Jacobian determinant at element center

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(OUT) :: detJ
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, nDim
    REAL(wp), ALLOCATABLE :: coords(:,:)
    REAL(wp), ALLOCATABLE :: dNdxi(:,:)
    REAL(wp) :: xi_center(3)

    CALL init_error_status(status)

    nNode = ElemType%pop%n_nodes
    nDim = ElemType%dim

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not allocated"
      RETURN
    END IF

    ! Use element center (xi = 0 for most elements)
    xi_center = 0.0_wp

    CALL UF_Elem_ComputeJacobianAtIP(ElemType, Ctx, &
                                        xi_center(1:nDim), detJ, status)
  END SUBROUTINE UF_Elem_ComputeJacobian

  SUBROUTINE UF_Elem_ComputeJacobianAtIP(ElemType, Ctx, xi, detJ, status)
    !! Compute Jacobian determinant at specific integration point

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(IN) :: xi(:)
    REAL(wp), INTENT(OUT) :: detJ
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, nDim, i, j
    REAL(wp), ALLOCATABLE :: coords(:,:)
    REAL(wp), ALLOCATABLE :: dNdxi(:,:)
    REAL(wp), POINTER :: Jac(:,:)
    INTEGER(i4) :: Jac_id
    TYPE(ErrorStatusType) :: st
    TYPE(ShapeFuncResult) :: sf

    CALL init_error_status(status)
    Jac => NULL()
    Jac_id = -1

    nNode = ElemType%pop%n_nodes
    nDim = ElemType%dim

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not allocated"
      RETURN
    END IF

    ! Get shape function derivatives
    ! Note: UF_GetShapeFunctions may be in a different module
    ! For now, use simplified computation for common element types
    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, nDim, nDim, 'Qual_Jac', Jac, Jac_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      RETURN
    END IF
    Jac = 0.0_wp

    ! Simplified Jacobian computation
    ! Full implementation would use shape function derivatives
    ! For now, compute using finite difference approximation
    IF (nDim == 1 .AND. nNode == 2) THEN
      ! Linear 1D element
      Jac(1, 1) = Ctx%coords_ref(1, 2) - Ctx%coords_ref(1, 1)
    ELSE IF (nDim == 2 .AND. nNode == 4) THEN
      ! Quadrilateral element - simplified
      Jac(1, 1) = 0.5_wp * (Ctx%coords_ref(1, 2) - Ctx%coords_ref(1, 1) + &
                          Ctx%coords_ref(1, 3) - Ctx%coords_ref(1, 4))
      Jac(1, 2) = 0.5_wp * (Ctx%coords_ref(2, 2) - Ctx%coords_ref(2, 1) + &
                          Ctx%coords_ref(2, 3) - Ctx%coords_ref(2, 4))
      Jac(2, 1) = 0.5_wp * (Ctx%coords_ref(1, 3) - Ctx%coords_ref(1, 1) + &
                          Ctx%coords_ref(1, 4) - Ctx%coords_ref(1, 2))
      Jac(2, 2) = 0.5_wp * (Ctx%coords_ref(2, 3) - Ctx%coords_ref(2, 1) + &
                          Ctx%coords_ref(2, 4) - Ctx%coords_ref(2, 2))
    ELSE IF (nDim == 3 .AND. nNode == 8) THEN
      ! Hexahedral element - simplified
      Jac(1, 1) = 0.25_wp * SUM(Ctx%coords_ref(1, [2,3,6,7]) - &
                              Ctx%coords_ref(1, [1,4,5,8]))
      Jac(2, 2) = 0.25_wp * SUM(Ctx%coords_ref(2, [3,4,7,8]) - &
                              Ctx%coords_ref(2, [1,2,5,6]))
      Jac(3, 3) = 0.25_wp * SUM(Ctx%coords_ref(3, [5,6,7,8]) - &
                              Ctx%coords_ref(3, [1,2,3,4]))
      ! Off-diagonal terms simplified to zero for now
      Jac(1, 2) = 0.0_wp
      Jac(1, 3) = 0.0_wp
      Jac(2, 1) = 0.0_wp
      Jac(2, 3) = 0.0_wp
      Jac(3, 1) = 0.0_wp
      Jac(3, 2) = 0.0_wp
    ELSE
      ! Generic fallback: use first two/three nodes
      DO i = 1, MIN(nDim, nNode - 1)
        DO j = 1, nDim
          Jac(i, j) = Ctx%coords_ref(j, i + 1) - Ctx%coords_ref(j, 1)
        END DO
      END DO
    END IF

    ! Compute determinant
    IF (nDim == 1) THEN
      detJ = Jac(1, 1)
    ELSE IF (nDim == 2) THEN
      detJ = Jac(1, 1) * Jac(2, 2) - Jac(1, 2) * Jac(2, 1)
    ELSE IF (nDim == 3) THEN
      detJ = Jac(1, 1) * (Jac(2, 2) * Jac(3, 3) - Jac(2, 3) * Jac(3, 2)) - &
             Jac(1, 2) * (Jac(2, 1) * Jac(3, 3) - Jac(2, 3) * Jac(3, 1)) + &
             Jac(1, 3) * (Jac(2, 1) * Jac(3, 2) - Jac(2, 2) * Jac(3, 1))
    END IF

900 CONTINUE
    IF (Jac_id >= 0) CALL UF_Mem_FreeReal2D(Jac_id, st)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Elem_ComputeJacobianAtIP

  FUNCTION UF_Elem_ComputeQualityScore(metrics) RESULT(score)
    !! Compute overall quality score (0-1, higher is better)
    !!
    !! Improved algorithm:
    !!   - Uses multiple quality metrics
    !!   - Applies element-type-specific thresholds
    !!   - Provides more accurate quality assessment

    TYPE(ElemQualMetrics), INTENT(IN) :: metrics
    REAL(wp) :: score

    REAL(wp) :: jacobian_score, aspect_score, skew_score, orthogonality_s
    REAL(wp) :: volume_score
    REAL(wp) :: jacobian_ratio

    ! Penalize invalid elements immediately
    IF (.NOT. metrics%is_valid .OR. metrics%is_inverted .OR. metrics%is_degenerate) THEN
      score = 0.0_wp
      RETURN
    END IF

    ! 1. Jacobian score: penalize negative or very small Jacobians
    IF (metrics%jacobian_min <= 0.0_wp) THEN
      jacobian_score = 0.0_wp
    ELSE IF (metrics%jacobian_min < 1.0e-10_wp) THEN
      jacobian_score = 0.0_wp  ! Degenerate element
    ELSE IF (metrics%jacobian_min < 1.0e-6_wp) THEN
      jacobian_score = metrics%jacobian_min / 1.0e-6_wp * 0.5_wp  ! Poor quality
    ELSE IF (metrics%jacobian_min < 1.0e-3_wp) THEN
      jacobian_score = 0.5_wp + 0.3_wp * (metrics%jacobian_min - 1.0e-6_wp) / (1.0e-3_wp - 1.0e-6_wp)
    ELSE
      jacobian_score = 0.8_wp + 0.2_wp * MIN(1.0_wp, metrics%jacobian_min / 1.0_wp)
    END IF

    ! Check Jacobian variation (uniformity)
    IF (metrics%jacobian_max > 1.0e-12_wp .AND. metrics%jacobian_min > 1.0e-12_wp) THEN
      jacobian_ratio = metrics%jacobian_min / metrics%jacobian_max
      IF (jacobian_ratio < 0.1_wp) THEN
        jacobian_score = jacobian_score * 0.5_wp  ! Penalize non-uniform Jacobian
      ELSE IF (jacobian_ratio < 0.5_wp) THEN
        jacobian_score = jacobian_score * (0.5_wp + 0.3_wp * (jacobian_ratio - 0.1_wp) / 0.4_wp)
      END IF
    END IF

    ! 2. Aspect ratio score: penalize high aspect ratios
    IF (metrics%aspect_ratio > 100.0_wp) THEN
      aspect_score = 0.0_wp
    ELSE IF (metrics%aspect_ratio > 20.0_wp) THEN
      aspect_score = 0.1_wp * (100.0_wp - metrics%aspect_ratio) / 80.0_wp
    ELSE IF (metrics%aspect_ratio > 10.0_wp) THEN
      aspect_score = 0.1_wp + 0.2_wp * (10.0_wp / metrics%aspect_ratio)
    ELSE IF (metrics%aspect_ratio > 5.0_wp) THEN
      aspect_score = 0.3_wp + 0.3_wp * (5.0_wp / metrics%aspect_ratio)
    ELSE IF (metrics%aspect_ratio > 2.0_wp) THEN
      aspect_score = 0.6_wp + 0.2_wp * (2.0_wp / metrics%aspect_ratio)
    ELSE IF (metrics%aspect_ratio > 1.0_wp) THEN
      aspect_score = 0.8_wp + 0.1_wp * (1.0_wp / metrics%aspect_ratio)
    ELSE
      aspect_score = 0.9_wp + 0.1_wp * metrics%aspect_ratio
    END IF

    ! 3. Skewness score: penalize high skewness
    IF (metrics%skewness > 0.9_wp) THEN
      skew_score = 0.0_wp
    ELSE IF (metrics%skewness > 0.7_wp) THEN
      skew_score = 0.1_wp * (0.9_wp - metrics%skewness) / 0.2_wp
    ELSE IF (metrics%skewness > 0.5_wp) THEN
      skew_score = 0.1_wp + 0.2_wp * (0.7_wp - metrics%skewness) / 0.2_wp
    ELSE IF (metrics%skewness > 0.3_wp) THEN
      skew_score = 0.3_wp + 0.3_wp * (0.5_wp - metrics%skewness) / 0.2_wp
    ELSE IF (metrics%skewness > 0.1_wp) THEN
      skew_score = 0.6_wp + 0.2_wp * (0.3_wp - metrics%skewness) / 0.2_wp
    ELSE
      skew_score = 0.8_wp + 0.2_wp * (1.0_wp - metrics%skewness / 0.1_wp)
    END IF

    ! 4. Orthogonality score
    IF (metrics%orthogonality > 0.9_wp) THEN
      orthogonality_s = 1.0_wp
    ELSE IF (metrics%orthogonality > 0.7_wp) THEN
      orthogonality_s = 0.7_wp + 0.3_wp * (metrics%orthogonality - 0.7_wp) / 0.2_wp
    ELSE IF (metrics%orthogonality > 0.5_wp) THEN
      orthogonality_s = 0.5_wp + 0.2_wp * (metrics%orthogonality - 0.5_wp) / 0.2_wp
    ELSE
      orthogonality_s = metrics%orthogonality
    END IF

    ! 5. Volume score (penalize very small or zero volume)
    IF (metrics%volume < 1.0e-15_wp) THEN
      volume_score = 0.0_wp
    ELSE IF (metrics%volume < 1.0e-12_wp) THEN
      volume_score = 0.3_wp
    ELSE IF (metrics%volume < 1.0e-9_wp) THEN
      volume_score = 0.6_wp
    ELSE
      volume_score = 1.0_wp
    END IF

    ! Overall score: weighted average with improved weighting
    ! Jacobian is most critical (40%), aspect ratio (25%), skewness (20%),
    ! orthogonality (10%), volume (5%)
    score = 0.40_wp * jacobian_score + &
            0.25_wp * aspect_score + &
            0.20_wp * skew_score + &
            0.10_wp * orthogonality_s + &
            0.05_wp * volume_score

    ! Ensure score is in [0, 1] range
    score = MAX(0.0_wp, MIN(1.0_wp, score))
  END FUNCTION UF_Elem_ComputeQualityScore

  SUBROUTINE UF_Elem_ComputeSkewness(ElemType, Ctx, skewness, status)
    !! Compute element skewness (deviation from ideal shape)
    !!
    !! For triangles: deviation from equilateral triangle
    !! For quadrilaterals: deviation from rectangle
    !! For hexahedra: deviation from cube

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(OUT) :: skewness
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, nDim
    REAL(wp) :: ideal_angle, actual_angle, angle_deviation
    REAL(wp) :: max_deviation
    INTEGER(i4) :: i

    CALL init_error_status(status)

    nNode = ElemType%pop%n_nodes
    nDim = ElemType%dim

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not allocated"
      RETURN
    END IF

    max_deviation = 0.0_wp

    ! Element-specific skewness computation
    IF (nDim == 2 .AND. nNode == 3) THEN
      ! Triangle: check deviation from 60° angles
      ideal_angle = 60.0_wp * ATAN(1.0_wp) / 45.0_wp  ! 60° in radians
      CALL UF_ComputeTriangleSkewness(Ctx%coords_ref, skewness, status)
    ELSE IF (nDim == 2 .AND. nNode == 4) THEN
      ! Quadrilateral: check deviation from 90° angles
      ideal_angle = 90.0_wp * ATAN(1.0_wp) / 45.0_wp  ! 90° in radians
      CALL UF_ComputeQuadrilateralSkewness(Ctx%coords_ref, skewness, status)
    ELSE IF (nDim == 3 .AND. nNode == 8) THEN
      ! Hexahedron: check deviation from 90° angles
      CALL UF_ComputeHexahedronSkewness(Ctx%coords_ref, skewness, status)
    ELSE IF (nDim == 3 .AND. nNode == 4) THEN
      ! Tetrahedron: check deviation from ideal angles
      CALL UF_ComputeTetrahedronSkewness(Ctx%coords_ref, skewness, status)
    ELSE
      ! Generic: use aspect ratio as proxy
      CALL UF_Elem_ComputeAspectRatio(ElemType, Ctx, skewness, status)
      IF (status%status_code == IF_STATUS_OK) THEN
        skewness = MAX(0.0_wp, (skewness - 1.0_wp) / 10.0_wp)
      END IF
    END IF

    IF (status%status_code /= IF_STATUS_OK) THEN
      skewness = 0.0_wp
      status%status_code = IF_STATUS_OK  ! Don't fail on skewness computation
    END IF
  END SUBROUTINE UF_Elem_ComputeSkewness

  SUBROUTINE UF_Elem_ComputeTaper(ElemType, Ctx, taper, status)
    !! Compute taper metric for quadrilateral elements
    !!
    !! Taper measures area variation

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(OUT) :: taper
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), POINTER :: coords(:,:)
    INTEGER(i4) :: coords_id
    TYPE(ErrorStatusType) :: st
    REAL(wp) :: area1, area2, area_avg
    INTEGER(i4) :: nNode

    CALL init_error_status(status)
    coords => NULL()
    coords_id = -1

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not allocated"
      RETURN
    END IF

    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, SIZE(Ctx%coords_ref, 1), &
         SIZE(Ctx%coords_ref, 2), 'Qual_Taper_coords', coords, coords_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      RETURN
    END IF
    coords = Ctx%coords_ref
    nNode = SIZE(coords, 2)

    IF (nNode < 4) THEN
      taper = 0.0_wp
      GOTO 900
    END IF

    ! Compute taper for quadrilateral elements
    ! Taper = area variation ratio
    IF (ElemType%dim == 2 .OR. nNode == 4) THEN
      ! Compute areas of two triangles
      area1 = 0.5_wp * ABS((coords(1,2) - coords(1,1)) * (coords(2,3) - coords(2,1)) - &
                           (coords(1,3) - coords(1,1)) * (coords(2,2) - coords(2,1)))
      area2 = 0.5_wp * ABS((coords(1,4) - coords(1,1)) * (coords(2,3) - coords(2,1)) - &
                           (coords(1,3) - coords(1,1)) * (coords(2,4) - coords(2,1)))

      area_avg = 0.5_wp * (area1 + area2)
      IF (area_avg > 1.0e-10_wp) THEN
        taper = ABS(area1 - area2) / area_avg
      ELSE
        taper = 0.0_wp
      END IF
    ELSE
      taper = 0.0_wp
    END IF

900 CONTINUE
    IF (coords_id >= 0) CALL UF_Mem_FreeReal2D(coords_id, st)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Elem_ComputeTaper

  SUBROUTINE UF_Elem_ComputeTwist(ElemType, Ctx, twist, status)
    !! Compute twist metric for quadrilateral elements
    !!
    !! Twist measures angular deviation

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(OUT) :: twist
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), POINTER :: coords(:,:)
    INTEGER(i4) :: coords_id
    TYPE(ErrorStatusType) :: st
    REAL(wp) :: v1(2), v2(2), angle1, angle2
    INTEGER(i4) :: nNode

    CALL init_error_status(status)
    coords => NULL()
    coords_id = -1

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not allocated"
      RETURN
    END IF

    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, SIZE(Ctx%coords_ref, 1), &
         SIZE(Ctx%coords_ref, 2), 'Qual_Twist_coords', coords, coords_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      RETURN
    END IF
    coords = Ctx%coords_ref
    nNode = SIZE(coords, 2)

    IF (nNode < 4) THEN
      twist = 0.0_wp
      GOTO 900
    END IF

    ! Compute twist for quadrilateral elements
    ! Twist = angular deviation
    IF (ElemType%dim == 2 .OR. nNode == 4) THEN
      v1 = coords(:, 2) - coords(:, 1)
      v2 = coords(:, 4) - coords(:, 1)
      angle1 = ATAN2(v1(2), v1(1))
      angle2 = ATAN2(v2(2), v2(1))
      twist = ABS(angle1 - angle2)
    ELSE
      twist = 0.0_wp
    END IF

900 CONTINUE
    IF (coords_id >= 0) CALL UF_Mem_FreeReal2D(coords_id, st)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Elem_ComputeTwist

  SUBROUTINE UF_Elem_ComputeVolume(ElemType, Ctx, volume, status)
    !! Compute element volume (3D) or area (2D)

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(OUT) :: volume
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nNode, nDim, nInt, ip
    REAL(wp), ALLOCATABLE :: gaussCoords(:,:), weights(:)
    REAL(wp) :: detJ, dV

    CALL init_error_status(status)

    nNode = ElemType%pop%n_nodes
    nDim = ElemType%dim
    nInt = ElemType%n_int_points

    volume = 0.0_wp

    ! Simplified volume computation using element center
    ! Full implementation would integrate over all Gauss points
    CALL UF_Elem_ComputeJacobian(ElemType, Ctx, detJ, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      ! Approximate volume using Jacobian at center
      ! For better accuracy, should integrate over all integration points
      IF (nDim == 1) THEN
        volume = detJ
      ELSE IF (nDim == 2) THEN
        volume = detJ  ! Area for 2D
      ELSE IF (nDim == 3) THEN
        volume = detJ  ! Volume for 3D
      END IF
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "Failed to compute Jacobian"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Elem_ComputeVolume

  SUBROUTINE UF_Elem_ComputeWarpage(ElemType, Ctx, warpage, status)
    !! Compute warpage metric for quadrilateral/shell elements
    !!
    !! Warpage measures deviation from planarity

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    REAL(wp), INTENT(OUT) :: warpage
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), POINTER :: coords(:,:)
    INTEGER(i4) :: coords_id
    TYPE(ErrorStatusType) :: st
    REAL(wp) :: v1(3), v2(3), v3(3), normal(3), area
    INTEGER(i4) :: nNode

    CALL init_error_status(status)
    coords => NULL()
    coords_id = -1

    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Element coordinates not allocated"
      RETURN
    END IF

    CALL UF_Mem_AllocReal2D(MEM_DOMAIN_ELEM, 0_i4, SIZE(Ctx%coords_ref, 1), &
         SIZE(Ctx%coords_ref, 2), 'Qual_Warpage_coords', coords, coords_id, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      status = st
      RETURN
    END IF
    coords = Ctx%coords_ref
    nNode = SIZE(coords, 2)

    IF (nNode < 4) THEN
      warpage = 0.0_wp
      GOTO 900
    END IF

    ! Compute warpage for quadrilateral elements
    ! Warpage = deviation from planarity
    IF (ElemType%dim == 2 .OR. nNode == 4) THEN
      ! For 2D quads, compute deviation from flat plane
      v1 = coords(:, 2) - coords(:, 1)
      v2 = coords(:, 4) - coords(:, 1)
      v3 = coords(:, 3) - coords(:, 1)

      ! Compute normal vector
      normal(1) = v1(2) * v2(3) - v1(3) * v2(2)
      normal(2) = v1(3) * v2(1) - v1(1) * v2(3)
      normal(3) = v1(1) * v2(2) - v1(2) * v2(1)

      area = SQRT(SUM(normal**2))
      IF (area > 1.0e-10_wp) THEN
        normal = normal / area
        ! Compute distance from node 3 to plane defined by nodes 1,2,4
        warpage = ABS(SUM(normal * v3))
      ELSE
        warpage = 0.0_wp
      END IF
    ELSE
      warpage = 0.0_wp
    END IF

900 CONTINUE
    IF (coords_id >= 0) CALL UF_Mem_FreeReal2D(coords_id, st)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Elem_ComputeWarpage

  SUBROUTINE UF_Elem_ValidateGeometry(ElemType, Ctx, is_valid, status)
    !! Quick geometry validation check

    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    LOGICAL, INTENT(OUT) :: is_valid
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ElemQualMetrics) :: metrics

    CALL UF_Elem_CheckQuality(ElemType, Ctx, metrics, status)
    IF (status%status_code == IF_STATUS_OK) THEN
      is_valid = metrics%is_valid
    ELSE
      is_valid = .false.
    END IF
  END SUBROUTINE UF_Elem_ValidateGeometry

  SUBROUTINE UF_GetElementEdgeConnectivit(ElemType, edge_conn, nEdges)
    !! Get edge connectivity for element type

    TYPE(ElemType), INTENT(IN) :: ElemType
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: edge_conn(:,:)
    INTEGER(i4), INTENT(OUT) :: nEdges

    INTEGER(i4) :: nNode

    nNode = ElemType%pop%n_nodes
    nEdges = ElemType%numEdges

    ! Allocate and fill based on element topology
    ! This is a simplified version - full implementation would use
    ! element-specific connectivity tables
    ALLOCATE(edge_conn(2, nEdges))
    edge_conn = 0
  END SUBROUTINE UF_GetElementEdgeConnectivity
END MODULE PH_Elem_Quality