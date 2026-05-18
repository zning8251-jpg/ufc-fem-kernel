! FK_MD_Mat_Elastic_Def.f90
! L3_Model — Material: Linear Elastic descriptor (template)
!
! Architectural pattern:
!   - Material descriptors are pure data (Desc type)
!   - Immutable after construction
!   - Separate from evaluation logic (Algo type in L4)
!
! File naming: {Layer}_{Domain}_{Role}.f90
!   Layer  = FK_MD (Model Data)
!   Domain = Mat (Material)
!   Role   = Def (Data Definition)

MODULE FK_MD_Mat_Elastic_Def
  USE FK_IF_Base_DP, ONLY: I4, WP

  IMPLICIT NONE
  PRIVATE

  !══════════════════════════════════════════════════════
  ! PUBLIC TYPES
  !══════════════════════════════════════════════════════
  PUBLIC :: FK_MD_Mat_Elastic_Desc_Type
  PUBLIC :: FK_MD_Mat_Elastic_Desc_Init

  !══════════════════════════════════════════════════════
  ! TYPE: Linear Elastic Material Descriptor (Desc)
  !══════════════════════════════════════════════════════
  TYPE :: FK_MD_Mat_Elastic_Desc_Type
    CHARACTER(len=64) :: mat_name = ''
    REAL(WP) :: youngs_modulus = 0.0_WP   ! E
    REAL(WP) :: poisson_ratio  = 0.0_WP   ! ν
    REAL(WP) :: density        = 0.0_WP   ! ρ

    ! Derived (computed once during Init)
    REAL(WP) :: shear_modulus  = 0.0_WP   ! G = E/(2*(1+ν))
    REAL(WP) :: lame_lambda    = 0.0_WP   ! λ = E*ν/((1+ν)*(1-2ν))
  END TYPE FK_MD_Mat_Elastic_Desc_Type

CONTAINS

  !────────────────────────────────────────────────────
  ! Init — construct and validate descriptor
  !────────────────────────────────────────────────────
  SUBROUTINE FK_MD_Mat_Elastic_Desc_Init(desc, mat_name, E, nu, rho, status)
    TYPE(FK_MD_Mat_Elastic_Desc_Type), INTENT(OUT) :: desc
    CHARACTER(len=*),                  INTENT(IN)  :: mat_name
    REAL(WP),                          INTENT(IN)  :: E, nu, rho
    INTEGER(I4),                       INTENT(OUT) :: status

    desc%mat_name       = mat_name
    desc%youngs_modulus = E
    desc%poisson_ratio  = nu
    desc%density        = rho

    ! Derived quantities (computed once)
    desc%shear_modulus  = E / (2.0_WP * (1.0_WP + nu))
    desc%lame_lambda    = E * nu / ((1.0_WP + nu) * (1.0_WP - 2.0_WP * nu))

    status = 0
  END SUBROUTINE FK_MD_Mat_Elastic_Desc_Init

END MODULE FK_MD_Mat_Elastic_Def
