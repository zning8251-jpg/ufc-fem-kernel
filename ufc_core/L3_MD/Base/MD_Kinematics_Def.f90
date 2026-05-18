!===============================================================================
! MODULE:  MD_Kinematics_Def
! LAYER:   L3_MD
! DOMAIN:  Model / Kinematics
! ROLE:    _Def (type definition authority)
! BRIEF:   Kinematics descriptor types for material integration interface.
!          Meta, time, temperature, mechanical, and thermal sub-types
!          composed into UF_Kinematics aggregate.
!===============================================================================
MODULE MD_Kinematics_Def
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_KinMeta_Desc
  ! KIND:  Desc
  ! DESC:  Kinematics metadata (dimension, stress components, formulation)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: KinematicsMeta
    INTEGER(i4) :: dim           = 0_i4  ! problem dimension
    INTEGER(i4) :: ndim          = 0_i4  ! spatial dimension
    INTEGER(i4) :: ndi           = 0_i4  ! direct stress components
    INTEGER(i4) :: nshr          = 0_i4  ! shear stress components
    INTEGER(i4) :: ntens         = 0_i4  ! total stress components
    INTEGER(i4) :: Formul        = 0_i4  ! formulation type ID
    INTEGER(i4) :: kine_class    = 0_i4  ! kinematics class
    INTEGER(i4) :: analysis_type = 0_i4  ! UMAT analysis type (1-4)
  END TYPE KinematicsMeta


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_KinTime_Desc
  ! KIND:  Desc
  ! DESC:  Time data for current increment
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: KinematicsTime
    REAL(wp) :: current = 0.0_wp  ! current step time
    REAL(wp) :: total   = 0.0_wp  ! total analysis time
    REAL(wp) :: inc     = 0.0_wp  ! time increment
  END TYPE KinematicsTime


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_KinTemp_Desc
  ! KIND:  Desc
  ! DESC:  Temperature data for current increment
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: KinematicsTemp
    REAL(wp) :: current = 0.0_wp  ! current temperature
    REAL(wp) :: inc     = 0.0_wp  ! temperature increment
  END TYPE KinematicsTemp


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_KinMech_Desc
  ! KIND:  Desc
  ! DESC:  Mechanical kinematics (strain, deformation gradient, coordinates)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: KinematicsMech
    REAL(wp) :: strain(6)      = 0.0_wp  ! total strain tensor (Voigt)
    REAL(wp) :: dStrain(6)     = 0.0_wp  ! strain increment (Voigt)
    REAL(wp) :: F(3,3)         = 0.0_wp  ! deformation gradient (current)
    REAL(wp) :: F_old(3,3)     = 0.0_wp  ! deformation gradient (previous)
    REAL(wp) :: F_incr(3,3)    = 0.0_wp  ! incremental deformation gradient
    REAL(wp) :: Jac            = 1.0_wp  ! Jacobian determinant
    REAL(wp) :: C(3,3)         = 0.0_wp  ! right Cauchy-Green tensor
    REAL(wp) :: R(3,3)         = 0.0_wp  ! rotation tensor
    REAL(wp) :: coords_ref(3)  = 0.0_wp  ! reference coordinates
    REAL(wp) :: coords_curr(3) = 0.0_wp  ! current coordinates
  END TYPE KinematicsMech


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_KinThermal_Desc
  ! KIND:  Desc
  ! DESC:  Thermal kinematics (temperature and increment)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: KinematicsThermal
    REAL(wp) :: temp  = 0.0_wp  ! temperature value
    REAL(wp) :: dTemp = 0.0_wp  ! temperature increment
  END TYPE KinematicsThermal


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_Kinematics_Desc
  ! KIND:  Desc
  ! DESC:  Main kinematics aggregate for material integration interface
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: UF_Kinematics
    TYPE(KinematicsMeta)     :: meta               ! metadata sub-type
    INTEGER(i4)              :: id     = 0_i4      ! element ID
    INTEGER(i4)              :: ipID   = 0_i4      ! integration point ID
    INTEGER(i4)              :: stepID = 0_i4      ! step ID
    INTEGER(i4)              :: incID  = 0_i4      ! increment ID
    TYPE(KinematicsTime)     :: time               ! time data
    TYPE(KinematicsTemp)     :: temp               ! temperature data
    TYPE(KinematicsMech)     :: mech               ! mechanical kinematics
    TYPE(KinematicsThermal)  :: thermal            ! thermal kinematics
    REAL(wp), POINTER        :: predef(:) => NULL() ! predefined field values
    REAL(wp), POINTER        :: user_real(:) => NULL() ! user-defined reals
  END TYPE UF_Kinematics

END MODULE MD_Kinematics_Def
