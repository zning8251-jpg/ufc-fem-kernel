!===============================================================================
! MODULE: PH_Elem_Contm_Brg
! LAYER:  L4_PH
! DOMAIN: Element/Legacy
! ROLE:   Brg — MD↔UF continuum dispatch (LEGACY — frozen, G6-W2 quarantine)
! BRIEF:  All USE MD_* for legacy Contm live here; not on production Ke/Fe path.
! See:    Element/Legacy/LEGACY_CONTM_BOUNDARY.md
!===============================================================================
MODULE PH_Elem_Contm_Brg
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_ERROR
  USE MD_TypeSystem, ONLY: UF_ElemType, UF_ElemFormul, UF_ElemCtx, UF_ElemFlags
  USE MD_Elem_Base, ONLY: UF_Int_Full, UF_Int_Reduced, UF_Int_Selective
  USE MD_Elem_Mgr, ONLY: ElemType, ElemFormul, ElemCtx, ElemFlags, ElemState
  USE MD_Mat_Lib, ONLY: MatProps, UF_MaterialModel
  USE PH_ElemContm_Ops, ONLY: &
    Core_Calc_Continuum2D => Calc_Continuum2D, &
    Core_Calc_Continuum3D => Calc_Continuum3D, &
    Core_Calc_Continuum_Poro => Calc_Continuum_Poro, &
    Core_Calc_Continuum_Thermal => Calc_Continuum_Thermal, &
    Core_Calc_Continuum_THM => Calc_Continuum_THM
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Contm_Args
  PUBLIC :: Calc_Continuum2D_Arg
  PUBLIC :: Calc_Continuum3D_Arg
  PUBLIC :: CompPoro
  PUBLIC :: CompThm
  PUBLIC :: CompTHM

  TYPE, PUBLIC :: PH_Contm_Args
    TYPE(UF_ElemType)     :: elem_type
    TYPE(UF_ElemFormul)   :: formul
    TYPE(UF_ElemCtx)      :: ctx
    CLASS(*), POINTER     :: mat_models(:) => NULL()
    CLASS(*), POINTER     :: state => NULL()
    CLASS(*), POINTER     :: flags => NULL()
  END TYPE PH_Contm_Args

CONTAINS

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

  SUBROUTINE Calc_Continuum2D_Arg(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(UF_ElemFlags) :: fl_uf

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[Calc_Continuum2D_Arg]: state not associated')
      END IF
      RETURN
    END IF

    SELECT TYPE (si => args%state)
    TYPE IS (ElemState)
      SELECT TYPE (mm => args%mat_models)
      TYPE IS (UF_MaterialModel)
        CALL Calc_Continuum2D(args%elem_type, args%formul, args%ctx, si, mm, si, fl_uf)
        IF (ASSOCIATED(args%flags)) args%flags = fl_uf
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Calc_Continuum2D(args%elem_type, args%formul, args%ctx, si, ufm, si, fl_uf)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) args%flags = fl_uf
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE Calc_Continuum2D_Arg

  SUBROUTINE Calc_Continuum3D_Arg(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(UF_ElemFlags) :: fl_uf

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[Calc_Continuum3D_Arg]: state not associated')
      END IF
      RETURN
    END IF

    SELECT TYPE (si => args%state)
    TYPE IS (ElemState)
      SELECT TYPE (mm => args%mat_models)
      TYPE IS (UF_MaterialModel)
        CALL Calc_Continuum3D(args%elem_type, args%formul, args%ctx, si, mm, si, fl_uf)
        IF (ASSOCIATED(args%flags)) args%flags = fl_uf
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Calc_Continuum3D(args%elem_type, args%formul, args%ctx, si, ufm, si, fl_uf)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) args%flags = fl_uf
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE Calc_Continuum3D_Arg

  SUBROUTINE CompPoro_Arg(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(ElemType) :: et
    TYPE(ElemFormul) :: ef
    TYPE(ElemCtx) :: cx
    TYPE(ElemFlags) :: fl

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[CompPoro_Arg]: state not associated')
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
        CALL Calc_Continuum_Poro(et, ef, cx, si, mm, si, fl)
        IF (ASSOCIATED(args%flags)) CALL PH_Contm_Assign_Flags_out(fl, args%flags)
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Calc_Continuum_Poro(et, ef, cx, si, ufm, si, fl)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) CALL PH_Contm_Assign_Flags_out(fl, args%flags)
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE CompPoro_Arg

  SUBROUTINE CompThm_Arg(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(ElemType) :: et
    TYPE(ElemFormul) :: ef
    TYPE(ElemCtx) :: cx
    TYPE(ElemFlags) :: fl

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[CompThm_Arg]: state not associated')
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
        CALL Calc_Continuum_Thermal(et, ef, cx, si, mm, si, fl)
        IF (ASSOCIATED(args%flags)) CALL PH_Contm_Assign_Flags_out(fl, args%flags)
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Calc_Continuum_Thermal(et, ef, cx, si, ufm, si, fl)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) CALL PH_Contm_Assign_Flags_out(fl, args%flags)
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE CompThm_Arg

  SUBROUTINE CompTHM_Arg(args, status)
    TYPE(PH_Contm_Args), INTENT(INOUT) :: args
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(ElemType) :: et
    TYPE(ElemFormul) :: ef
    TYPE(ElemCtx) :: cx
    TYPE(ElemFlags) :: fl

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(args%state)) THEN
      IF (PRESENT(status)) THEN
        CALL init_error_status(status, IF_STATUS_ERROR, &
             message='[CompTHM_Arg]: state not associated')
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
        CALL Calc_Continuum_THM(et, ef, cx, si, mm, si, fl)
        IF (ASSOCIATED(args%flags)) CALL PH_Contm_Assign_Flags_out(fl, args%flags)
      TYPE IS (MatProps)
        BLOCK
          TYPE(UF_MaterialModel), ALLOCATABLE :: ufm(:)
          CALL PH_Contm_Build_UFMM_from_MatProps(mm, ufm)
          CALL Calc_Continuum_THM(et, ef, cx, si, ufm, si, fl)
          DEALLOCATE(ufm)
          IF (ASSOCIATED(args%flags)) CALL PH_Contm_Assign_Flags_out(fl, args%flags)
        END BLOCK
      CLASS DEFAULT
        CONTINUE
      END SELECT
    CLASS DEFAULT
      CONTINUE
    END SELECT
  END SUBROUTINE CompTHM_Arg

  ! L3 Bridge entry points (UF signature — MD_ElemPH_Brg)
  SUBROUTINE CompPoro(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags

    TYPE(PH_Contm_Args) :: args

    args%elem_type = ElemType
    args%formul = Formul
    args%ctx = Ctx
    args%mat_models => matModels
    args%state => state_in
    args%flags => flags
    CALL CompPoro_Arg(args)
  END SUBROUTINE CompPoro

  SUBROUTINE CompThm(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags

    TYPE(PH_Contm_Args) :: args

    args%elem_type = ElemType
    args%formul = Formul
    args%ctx = Ctx
    args%mat_models => matModels
    args%state => state_in
    args%flags => flags
    CALL CompThm_Arg(args)
  END SUBROUTINE CompThm

  SUBROUTINE CompTHM(ElemType, Formul, Ctx, state_in, matModels, state_out, flags)
    TYPE(UF_ElemType), INTENT(IN) :: ElemType
    TYPE(UF_ElemFormul), INTENT(IN) :: Formul
    TYPE(UF_ElemCtx), INTENT(INOUT) :: Ctx
    CLASS(*), INTENT(INOUT) :: state_in
    CLASS(*), INTENT(IN) :: matModels(:)
    CLASS(*), INTENT(INOUT) :: state_out
    CLASS(*), INTENT(INOUT) :: flags

    TYPE(PH_Contm_Args) :: args

    args%elem_type = ElemType
    args%formul = Formul
    args%ctx = Ctx
    args%mat_models => matModels
    args%state => state_in
    args%flags => flags
    CALL CompTHM_Arg(args)
  END SUBROUTINE CompTHM

END MODULE PH_Elem_Contm_Brg
