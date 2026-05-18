!===============================================================================
! MODULE:  MD_Elem_UEL_Def
! LAYER:   L3_MD
! DOMAIN:  Element / Elem (UEL bridge bundle; path `L3_MD/Element/Elem/`)
! ROLE:    Def — UEL call-parameter Desc (distinct from registry MD_Elem_Desc)
! BRIEF:   Immutable bundle mapping ABAQUS UEL signature fields (cold path / bridge).
! **W2**：与 **`Element/Elem/MD_Elem_Def.f90`** 中 **`MD_Elem_Desc`（域柱注册）** 分离；
!         L4/L5 UEL 适配层 **`USE`** 本模块的 **`MD_Elem_UEL_Desc`**，禁止复用同名 Base_Desc。
!===============================================================================
!
! Source: UEL signature parameter mapping
!   NDOFEL -> ndofel     NSVARS -> nsvars     MD_MESH_NNODE -> nnode
!   MCRD   -> mcrd       JTYPE  -> jtype      NPROPS -> nprops
!   PROPS  -> props(:)    NPREDF -> npredf     JDLTYP -> jdltyp(:,:)
!   MDLOAD -> mdload     JPROPS -> jprops(:)  NJPROP -> njprop
!
! Layer dependency:
!   USE IF_Prec_Core (wp, i4)
!===============================================================================
MODULE MD_Elem_UEL_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Elem_UEL_Desc

  !-----------------------------------------------------------------------------
  ! TYPE: MD_Elem_UEL_Desc
  ! DESC: Maps UEL-time parameters that describe element topology and property
  !       arrays (not incremental runtime quantities; those live in PH/RT).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Elem_UEL_Desc
    INTEGER(i4) :: ndofel = 0
    INTEGER(i4) :: nsvars  = 0
    INTEGER(i4) :: nnode   = 0
    INTEGER(i4) :: mcrd    = 3
    INTEGER(i4) :: jtype   = 0
    INTEGER(i4) :: nprops = 0
    REAL(wp), ALLOCATABLE    :: props(:)
    INTEGER(i4) :: npredf  = 0
    INTEGER(i4) :: mdload = 0
    INTEGER(i4), ALLOCATABLE :: jdltyp(:,:)
    INTEGER(i4) :: njprop = 0
    INTEGER(i4), ALLOCATABLE :: jprops(:)
    INTEGER(i4) :: integ_npts = 0_i4
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => UEL_Elem_Desc_Init
    PROCEDURE :: Reset  => UEL_Elem_Desc_Reset
  END TYPE MD_Elem_UEL_Desc

CONTAINS

  SUBROUTINE UEL_Elem_Desc_Init(self, nprops_in, njprop_in, npredf_in, mdload_in, ncols_jdl)
    CLASS(MD_Elem_UEL_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: nprops_in
    INTEGER(i4), INTENT(IN) :: njprop_in
    INTEGER(i4), INTENT(IN) :: npredf_in
    INTEGER(i4), INTENT(IN) :: mdload_in
    INTEGER(i4), INTENT(IN) :: ncols_jdl

    self%nprops = nprops_in
    self%njprop = njprop_in
    self%npredf = npredf_in
    self%mdload = mdload_in

    IF (nprops_in > 0) THEN
      IF (.NOT. ALLOCATED(self%props))  ALLOCATE(self%props(nprops_in))
      self%props = 0.0_wp
    END IF

    IF (njprop_in > 0) THEN
      IF (.NOT. ALLOCATED(self%jprops)) ALLOCATE(self%jprops(njprop_in))
      self%jprops = 0_i4
    END IF

    IF (mdload_in > 0 .AND. ncols_jdl > 0) THEN
      IF (.NOT. ALLOCATED(self%jdltyp)) ALLOCATE(self%jdltyp(mdload_in, ncols_jdl))
      self%jdltyp = 0_i4
    END IF

    self%is_initialized = .TRUE.
  END SUBROUTINE UEL_Elem_Desc_Init

  SUBROUTINE UEL_Elem_Desc_Reset(self)
    CLASS(MD_Elem_UEL_Desc), INTENT(INOUT) :: self
    IF (ALLOCATED(self%props))  DEALLOCATE(self%props)
    IF (ALLOCATED(self%jprops)) DEALLOCATE(self%jprops)
    IF (ALLOCATED(self%jdltyp)) DEALLOCATE(self%jdltyp)
    self%nprops = 0
    self%njprop = 0
    self%mdload = 0
    self%npredf = 0
    self%ndofel = 0
    self%nsvars = 0
    self%nnode  = 0
    self%mcrd   = 0
    self%jtype  = 0
    self%integ_npts = 0_i4
    self%is_initialized = .FALSE.
  END SUBROUTINE UEL_Elem_Desc_Reset

END MODULE MD_Elem_UEL_Def
