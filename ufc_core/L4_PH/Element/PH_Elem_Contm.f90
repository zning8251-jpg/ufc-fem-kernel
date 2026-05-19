!===============================================================================
! MODULE: PH_Elem_Contm
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc — thin legacy re-export (G6-W2 facade)
! BRIEF:  Production Ke/Fe MUST use PH_Elem_Domain; MD coupling in Legacy/PH_Elem_Contm_Brg.
! See:    Element/Legacy/LEGACY_CONTM_BOUNDARY.md
!===============================================================================
MODULE PH_Elem_Contm
  USE PH_ElemContm_Ops, ONLY: &
    Calc_Continuum2D, Calc_Continuum3D, Calc_Continuum, Calc_Continuum_MatProps, &
    UF_Init_Continuum, UF_Init_Continuum2D, UF_Init_Continuum3D, &
    UF_Init_Continuum_Poro, UF_Init_Continuum_THM, UF_Init_Continuum_Thermal
  USE PH_Elem_Contm_Brg, ONLY: PH_Contm_Args, CompPoro, CompThm, CompTHM, &
    Calc_Continuum2D_Arg, Calc_Continuum3D_Arg
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
  PUBLIC :: Calc_Continuum2D_Arg
  PUBLIC :: Calc_Continuum3D_Arg

END MODULE PH_Elem_Contm
