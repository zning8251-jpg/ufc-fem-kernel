!===============================================================================
! MODULE: PH_Elem_Contm
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  Continuum element calculation bridge facade (LEGACY — frozen)
! LEGACY-FROZEN: Production Ke/Fe MUST use PH_Elem_Domain gold path; see
!   Element/Legacy/LEGACY_CONTM_BOUNDARY.md (change: p2-element-legacy-contm-retire).
! Status: LEGACY | Do not extend | G6-W0 quarantine
!===============================================================================
MODULE PH_Elem_Contm
  USE IF_Prec_Core, ONLY: i4
  USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx, UF_ElemFlags
  USE MD_Elem_Base, ONLY: UF_Int_Full, UF_Int_Reduced, UF_Int_Selective
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, ONLY: MatProps, UF_MaterialModel
  USE PH_ElemContm_Ops, ONLY: &
    Core_Calc_Continuum2D => Calc_Continuum2D, &
    Core_Calc_Continuum3D => Calc_Continuum3D, &
    Core_Calc_Continuum_Poro => Calc_Continuum_Poro, &
    Core_Calc_Continuum_Thermal => Calc_Continuum_Thermal, &
    Core_Calc_Continuum_THM => Calc_Continuum_THM, &
    Calc_Continuum, &
    Calc_Continuum_MatProps, &
    UF_Init_Continuum, &
    UF_Init_Continuum2D, &
    UF_Init_Continuum3D, &
    UF_Init_Continuum_Poro, &
    UF_Init_Continuum_THM, &
    UF_Init_Continuum_Thermal
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Calc_Continuum2D
  PUBLIC :: Calc_Continuum3D
  PUBLIC :: CompPoro
  PUBLIC :: CompThm
  PUBLIC :: CompTHM
  PUBLIC :: Calc_Continuum
  PUBLIC :: Calc_Continuum_MatProps
  PUBLIC :: UF_Init_Continuum
  PUBLIC :: UF_Init_Continuum2D
  PUBLIC :: UF_Init_Continuum3D
  PUBLIC :: UF_Init_Continuum_Poro
  PUBLIC :: UF_Init_Continuum_THM
  PUBLIC :: UF_Init_Continuum_Thermal
  PUBLIC :: PH_Contm_Args

  !=============================================================================
  ! TYPE: PH_Contm_Args
  ! Purpose: INTF-style argument bundle for continuum element calculation
  ! Status: INTF-001 Progressive Refactoring
  !=============================================================================
  TYPE :: PH_Contm_Args
    !-- Input: Element type and formulation
    TYPE(UF_ElemType)     :: elem_type                 ! Element type code
    TYPE(UF_ElemFormul)   :: formul                    ! Formulation parameters
    TYPE(UF_ElemCtx)      :: ctx                       ! Element context
    
    !-- Input: Material models
    CLASS(*), POINTER     :: mat_models(:) => NULL()   ! Material models array
    
    !-- Input/Output: Element state (unified)
    CLASS(*), POINTER     :: state => NULL()           ! Element state (in/out unified)
    
    !-- Output: Flags
    CLASS(*), POINTER     :: flags => NULL()           ! Output flags
    
  END TYPE PH_Contm_Args

CONTAINS

  !> Map UF_ElemFormul fields onto MD_Elem_Algo%ElemFormul (aligned components).
  SUBROUTINE PH_Contm_Map_UF_Formul_to_Elem(uf, ef)
    TYPE(UF_ElemFormul), INTENT(IN) :: uf
    TYPE(ElemFormul), INTENT(OUT) :: ef

    ef%formulationType = uf%formulationType
    ef%order = uf%order
    ef%nIntPoints = uf%nIntPoints
    ef%reducedintegrat = uf%reducedintegrat
    ef%hourglasscontro = uf%hourglasscontro
    ef%kineFormulation = uf%kineFormulation
    ef%integration_scheme = uf%integration_scheme
    ef%use_bbar = uf%use_bbar
    IF (uf%integration_scheme == UF_Int_Reduced) ef%reducedintegrat = .TRUE.
    IF (uf%integration_scheme == UF_Int_Selective) ef%hourglasscontro = .TRUE.
  END SUBROUTINE PH_Contm_Map_UF_Formul_to_Elem

  SUBROUTINE PH_Contm_Build_UFMM_from_MatProps(mp, ufmm)
    TYPE(MatProps), INTENT(IN) :: mp(:)
    TYPE(UF_MaterialModel), ALLOCATABLE, INTENT(OUT) :: ufmm(:)
    INTEGER(i4) :: i, n

    n = SIZE(mp)
    ALLOCATE(ufmm(n))
    DO i = 1, n
      ufmm(i)%cfg%id = mp(i)%material_id
      IF (ALLOCATED(mp(i)%props)) THEN
        CALL ufmm(i)%props%Init(material_id=mp(i)%material_id, props=mp(i)%props)
      ELSE
        CALL ufmm(i)%props%Init(material_id=mp(i)%material_id)
      END IF
    END DO
  END SUBROUTINE PH_Contm_Build_UFMM_from_MatProps

  SUBROUTINE PH_Contm_Assign_Flags_out(fl, flags)
    TYPE(ElemFlags), INTENT(IN) :: fl
    CLASS(*), INTENT(INOUT) :: flags

    SELECT TYPE (t => flags)
    TYPE IS (UF_ElemFlags)
      t = fl
    TYPE IS (ElemFlags)
      t = fl
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE PH_Contm_Assign_Flags_out

  SUBROUTINE Calc_Continuum2D(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(UF_ElemFlags) :: fl_uf
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate contract
    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[Calc_Continuum2D]: state not associated')
      END IF
      RETURN
    END IF

    SELECT TYPE (si => args%state)
    TYPE IS (ElemState)
      ! Note: state_out same as state_in for continuum mechanics
      SELECT TYPE (mm => args%mat_models)
      TYPE IS (UF_MaterialModel)
        CALL Core_Calc_Continuum2D(args%elem_type, args%formul, args%ctx, si, mm, si, fl_uf)
        IF (ASSOCIATED(args%flags)) args%flags = fl_uf
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Core_Calc_Continuum2D(args%elem_type, args%formul, args%ctx, si, ufm, si, fl_uf)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) args%flags = fl_uf
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE Calc_Continuum2D

  SUBROUTINE Calc_Continuum3D(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(UF_ElemFlags) :: fl_uf
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate contract
    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[Calc_Continuum3D]: state not associated')
      END IF
      RETURN
    END IF

    SELECT TYPE (si => args%state)
    TYPE IS (ElemState)
      ! Note: state_out same as state_in for continuum mechanics
      SELECT TYPE (mm => args%mat_models)
      TYPE IS (UF_MaterialModel)
        CALL Core_Calc_Continuum3D(args%elem_type, args%formul, args%ctx, si, mm, si, fl_uf)
        IF (ASSOCIATED(args%flags)) args%flags = fl_uf
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Core_Calc_Continuum3D(args%elem_type, args%formul, args%ctx, si, ufm, si, fl_uf)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) args%flags = fl_uf
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE Calc_Continuum3D

  SUBROUTINE CompPoro(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ElemType) :: et
    TYPE(ElemFormul) :: ef
    TYPE(ElemCtx) :: cx
    TYPE(ElemFlags) :: fl
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate contract
    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[CompPoro]: state not associated')
      END IF
      RETURN
    END IF
    
    et = args%elem_type
    CALL PH_Contm_Map_UF_Formul_to_Elem(args%formul, ef)
    cx = args%ctx

    SELECT TYPE (si => args%state)
    TYPE IS (ElemState)
      SELECT TYPE (mm => args%mat_models)
      TYPE IS (UF_MaterialModel)
        CALL Core_Calc_Continuum_Poro(et, ef, cx, si, mm, si, fl)
        IF (ASSOCIATED(args%flags)) args%flags = fl
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Core_Calc_Continuum_Poro(et, ef, cx, si, ufm, si, fl)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) args%flags = fl
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE CompPoro

  SUBROUTINE CompThm(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ElemType) :: et
    TYPE(ElemFormul) :: ef
    TYPE(ElemCtx) :: cx
    TYPE(ElemFlags) :: fl
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate contract
    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[CompThm]: state not associated')
      END IF
      RETURN
    END IF
    
    et = args%elem_type
    CALL PH_Contm_Map_UF_Formul_to_Elem(args%formul, ef)
    cx = args%ctx

    SELECT TYPE (si => args%state)
    TYPE IS (ElemState)
      SELECT TYPE (mm => args%mat_models)
      TYPE IS (UF_MaterialModel)
        CALL Core_Calc_Continuum_Thermal(et, ef, cx, si, mm, si, fl)
        IF (ASSOCIATED(args%flags)) args%flags = fl
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Core_Calc_Continuum_Thermal(et, ef, cx, si, ufm, si, fl)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) args%flags = fl
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE CompThm

  SUBROUTINE CompTHM(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ElemType) :: et
    TYPE(ElemFormul) :: ef
    TYPE(ElemCtx) :: cx
    TYPE(ElemFlags) :: fl
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate contract
    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[CompTHM]: state not associated')
      END IF
      RETURN
    END IF
    
    et = args%elem_type
    CALL PH_Contm_Map_UF_Formul_to_Elem(args%formul, ef)
    cx = args%ctx

    SELECT TYPE (si => args%state)
    TYPE IS (ElemState)
      SELECT TYPE (mm => args%mat_models)
      TYPE IS (UF_MaterialModel)
        CALL Core_Calc_Continuum_THM(et, ef, cx, si, mm, si, fl)
        IF (ASSOCIATED(args%flags)) args%flags = fl
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Core_Calc_Continuum_THM(et, ef, cx, si, ufm, si, fl)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) args%flags = fl
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE CompTHM

END MODULE PH_Elem_Contm