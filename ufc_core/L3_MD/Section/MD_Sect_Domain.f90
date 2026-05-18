!===============================================================================
! MODULE:  MD_Sect_Domain
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Domain
! BRIEF:   Section domain container — re-export from MD_Sect_Def for
!          backward compatibility.
!===============================================================================

MODULE MD_Sect_Domain
  USE MD_Sect_Def
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Sect_Domain
  PUBLIC :: MD_Sect_Desc, MD_Sect_Catalog_Desc, MD_Sect_Algo
  PUBLIC :: MD_SECTION_MAX
  PUBLIC :: MD_Sect_Add_Arg, MD_Sect_Validate_Arg
  PUBLIC :: MD_Sect_GetSummary_Arg
  PUBLIC :: MD_Sect_Get_Arg, MD_Section_GetSection_Idx
  PUBLIC :: MD_Sect_GetByName_Arg, MD_Section_GetSectionByName_Idx
  PUBLIC :: SECT_FAM_SOLID, SECT_FAM_SHELL, SECT_FAM_BEAM
  PUBLIC :: SECT_FAM_MEMBRANE, SECT_FAM_TRUSS, SECT_FAM_COHESIVE
  PUBLIC :: SECT_FAM_GASKET, SECT_FAM_ACOUSTIC, SECT_FAM_CONNECTOR
  PUBLIC :: SECT_FAM_COUNT
  PUBLIC :: SECT_TYPE_COUNT

END MODULE MD_Sect_Domain