!===============================================================================
! MODULE:  MD_Elem_Family
! LAYER:   L3_MD
! DOMAIN:  Element / Elem
! ROLE:    _Impl
! BRIEF:   Element family mapping — P0 Register: L3 element type to family ID.
!===============================================================================
!
! Theory chain:
!   ABAQUS element naming: C3D=3D continuum, CPE=plane strain,
!   CPS=plane stress, CAX=axisymmetric, S=shell, B=beam, T=truss.
!   DC/AC/M etc. map to MD_MESH_ELEM_FAMILY_OTHER.
!
! Data chain:
!   elem_type (from MD_Elem_Algo MD_MESH_ELEM_*) -> ElemTypeToFamily -> family_id
!   Aligns with PH_ElemReg_Algo MD_MESH_ELEM_FAMILY_* (Phase 4).
!
! Status: Phase 4 | Last verified: 2026-03-17
!======================================================================
!>>> UFC_L3_QUENCH | Domain:Element | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Element/Elem/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Element | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Elem_Family
  USE IF_Prec_Core, ONLY: i4
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! MD_MESH_ELEM_FAMILY_*: 12 major families (aligned with Abaqus)
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_SOLID_3D = 1_i4   ! 3D continuum (C3D*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_SOLID_2D = 2_i4   ! 2D continuum (CPE*, CPS*, CAX*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_SHELL    = 3_i4   ! Shell (S*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_MEMBRANE = 4_i4   ! Membrane (M*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_BEAM     = 5_i4   ! Beam (B*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_TRUSS    = 6_i4   ! Truss (T*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_COHESIVE = 7_i4   ! Cohesive (COH*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_INFINITE = 8_i4   ! Infinite (CIN*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_ACOUSTIC = 9_i4   ! Acoustic (AC*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_GASKET   = 10_i4  ! Gasket (GK*)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_CONN     = 11_i4  ! Connector/Spring/Dashpot
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_MASS     = 12_i4  ! Mass/Inertia/Rigid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_OTHER    = 99_i4  ! Other/User

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_FAMILY_COUNT = 12_i4

  PUBLIC :: ElemTypeToFamily
  PUBLIC :: ElemFamilyToSectFamily

CONTAINS

  !--------------------------------------------------------------------
  ! ElemTypeToFamily: Map elem_type (L3 MD_MESH_ELEM_*) to family_id
  !--------------------------------------------------------------------
  PURE FUNCTION ElemTypeToFamily(elem_type) RESULT(family_id)
    INTEGER(i4), INTENT(IN) :: elem_type
    INTEGER(i4) :: family_id

    family_id = MD_MESH_ELEM_FAMILY_OTHER
    IF (elem_type == 0_i4) RETURN  ! MD_MESH_ELEM_USER

    IF (elem_type >= 1_i4 .AND. elem_type <= 99_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_SOLID_3D
    ELSE IF (elem_type >= 100_i4 .AND. elem_type <= 299_i4) THEN
      ! CPE (100-149), CPS (150-199), CAX (200-249)
      family_id = MD_MESH_ELEM_FAMILY_SOLID_2D
    ELSE IF (elem_type >= 300_i4 .AND. elem_type <= 399_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_SHELL
    ELSE IF (elem_type >= 400_i4 .AND. elem_type <= 449_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_BEAM
    ELSE IF (elem_type >= 450_i4 .AND. elem_type <= 479_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_TRUSS
    ELSE IF (elem_type >= 480_i4 .AND. elem_type <= 499_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_MEMBRANE
    ELSE IF (elem_type >= 550_i4 .AND. elem_type <= 599_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_ACOUSTIC
    ELSE IF (elem_type >= 600_i4 .AND. elem_type <= 649_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_INFINITE
    ELSE IF (elem_type >= 650_i4 .AND. elem_type <= 699_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_COHESIVE
    ELSE IF (elem_type >= 700_i4 .AND. elem_type <= 729_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_GASKET
    ELSE IF (elem_type >= 730_i4 .AND. elem_type <= 759_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_CONN
    ELSE IF (elem_type >= 760_i4 .AND. elem_type <= 799_i4) THEN
      family_id = MD_MESH_ELEM_FAMILY_MASS
    END IF
  END FUNCTION ElemTypeToFamily

  !--------------------------------------------------------------------
  ! ElemFamilyToSectFamily: Map element family to natural section family
  !   Solid3D/Solid2D/Infinite -> Solid(1)
  !   Shell -> Shell(2), Beam -> Beam(3), Membrane -> Membrane(4)
  !   Truss -> Truss(5), Cohesive -> Cohesive(6), Gasket -> Gasket(7)
  !   Acoustic -> Acoustic(8), Connector/Mass -> Connector(9)
  !--------------------------------------------------------------------
  PURE FUNCTION ElemFamilyToSectFamily(elem_family) RESULT(sect_fam)
    INTEGER(i4), INTENT(IN) :: elem_family
    INTEGER(i4) :: sect_fam

    SELECT CASE (elem_family)
    CASE (MD_MESH_ELEM_FAMILY_SOLID_3D, MD_MESH_ELEM_FAMILY_SOLID_2D, &
          MD_MESH_ELEM_FAMILY_INFINITE)
      sect_fam = 1_i4   ! SECT_FAM_SOLID
    CASE (MD_MESH_ELEM_FAMILY_SHELL)
      sect_fam = 2_i4   ! SECT_FAM_SHELL
    CASE (MD_MESH_ELEM_FAMILY_BEAM)
      sect_fam = 3_i4   ! SECT_FAM_BEAM
    CASE (MD_MESH_ELEM_FAMILY_MEMBRANE)
      sect_fam = 4_i4   ! SECT_FAM_MEMBRANE
    CASE (MD_MESH_ELEM_FAMILY_TRUSS)
      sect_fam = 5_i4   ! SECT_FAM_TRUSS
    CASE (MD_MESH_ELEM_FAMILY_COHESIVE)
      sect_fam = 6_i4   ! SECT_FAM_COHESIVE
    CASE (MD_MESH_ELEM_FAMILY_GASKET)
      sect_fam = 7_i4   ! SECT_FAM_GASKET
    CASE (MD_MESH_ELEM_FAMILY_ACOUSTIC)
      sect_fam = 8_i4   ! SECT_FAM_ACOUSTIC
    CASE (MD_MESH_ELEM_FAMILY_CONN, MD_MESH_ELEM_FAMILY_MASS)
      sect_fam = 9_i4   ! SECT_FAM_CONNECTOR
    CASE DEFAULT
      sect_fam = 0_i4   ! Unknown
    END SELECT
  END FUNCTION ElemFamilyToSectFamily

END MODULE MD_Elem_Family