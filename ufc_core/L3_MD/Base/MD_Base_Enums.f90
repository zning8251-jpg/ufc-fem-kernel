!===============================================================================
! MODULE:  MD_Base_Enums
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Def (enumeration constants)
! BRIEF:   Core global enumerations and constants for model definition layer.
!          Category, step type, DOF, field, load/BC, solver, topology, and
!          error code constants. All INTEGER(i4) PARAMETER.
!===============================================================================
MODULE MD_Base_Enums
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg,   ONLY: log_error
  IMPLICIT NONE
  PUBLIC

  !---------------------------------------------------------------------------
  ! 1. Core Categories
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_CAT_DESC   = 1_i4  ! descriptor category
  INTEGER(i4), PARAMETER :: MD_MODEL_CAT_STATE  = 2_i4  ! state category
  INTEGER(i4), PARAMETER :: MD_MODEL_CAT_ALGO   = 3_i4  ! algorithm category
  INTEGER(i4), PARAMETER :: MD_MODEL_CAT_ALGO_S = 4_i4  ! algorithm sub-category
  INTEGER(i4), PARAMETER :: MD_MODEL_CAT_STEP_D = 5_i4  ! step descriptor category
  INTEGER(i4), PARAMETER :: MD_MODEL_CAT_STEP_S = 6_i4  ! step state category
  INTEGER(i4), PARAMETER :: MD_MODEL_CAT_CTX    = 7_i4  ! context category

  !---------------------------------------------------------------------------
  ! 2. Step Types
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_STEP_STATIC       = 1_i4  ! static analysis
  INTEGER(i4), PARAMETER :: MD_MODEL_STEP_IMPL_DYN     = 2_i4  ! implicit dynamic
  INTEGER(i4), PARAMETER :: MD_MODEL_STEP_EXPL_DYN     = 3_i4  ! explicit dynamic
  INTEGER(i4), PARAMETER :: MD_MODEL_STEP_ARC_LEN      = 4_i4  ! arc-length method
  INTEGER(i4), PARAMETER :: MD_MODEL_STEP_CONTACT_INIT = 5_i4  ! contact init
  INTEGER(i4), PARAMETER :: MD_MODEL_STEP_HEAT_TRANSFE = 6_i4  ! heat transfer
  INTEGER(i4), PARAMETER :: MD_MODEL_STEP_COUPLED_TEMP = 7_i4  ! coupled temp-disp
  INTEGER(i4), PARAMETER :: MD_MODEL_STEP_EIGEN_FREQUE = 8_i4  ! eigenfrequency

  !---------------------------------------------------------------------------
  ! 3. DOF Identifiers
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_U1  = 1_i4   ! displacement X
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_U2  = 2_i4   ! displacement Y
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_U3  = 3_i4   ! displacement Z
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_UR1 = 4_i4   ! rotation X
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_UR2 = 5_i4   ! rotation Y
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_UR3 = 6_i4   ! rotation Z
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_TEMP = 11_i4  ! temperature
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_POR  = 12_i4  ! pore pressure
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_EPOT = 13_i4  ! electric potential
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_CHEM = 14_i4  ! chemical potential
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_MPOT = 15_i4  ! magnetic potential
  INTEGER(i4), PARAMETER :: MD_MODEL_DOF_MAX_PER_NOD = 16  ! max DOF per node

  !---------------------------------------------------------------------------
  ! 4. Field Identifiers
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_STRUCT   = 1_i4  ! structural field
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_THERMAL  = 2_i4  ! thermal field
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_PORE     = 3_i4  ! pore field
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_FLUID    = 4_i4  ! fluid field
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_ACOUSTIC = 5_i4  ! acoustic field
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_ELECTRIC = 6_i4  ! electric field
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_MAGNETIC = 7_i4  ! magnetic field
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_CHEMICAL = 8_i4  ! chemical field
  INTEGER(i4), PARAMETER :: MD_MODEL_FIELD_MAX      = 8_i4  ! max field count

  !---------------------------------------------------------------------------
  ! 5. Load & BC Types
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_LOAD_CONCENT = 1_i4  ! concentrated load
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_LOAD_DISTRIB = 2_i4  ! distributed load
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_LOAD_PRESSUR = 3_i4  ! pressure load
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_LOAD_BODYFOR = 4_i4  ! body force
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_LOAD_GRAVITY = 5_i4  ! gravity load
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_LOAD_THERMAL = 6_i4  ! thermal load
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_LOAD_EDGEDIS = 7_i4  ! edge distributed
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_LOAD_CENTRIF = 8_i4  ! centrifugal load

  INTEGER(i4), PARAMETER :: MD_MODEL_UF_BC_DISPLACEM = 1_i4   ! displacement BC
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_BC_Velocity  = 2_i4   ! velocity BC
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_BC_ACCELERAT = 3_i4   ! acceleration BC
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_BC_Fixed     = 4_i4   ! fixed BC
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_BC_TEMPERATU = 6_i4   ! temperature BC
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_BC_Symmetry  = 10_i4  ! symmetry BC

  !---------------------------------------------------------------------------
  ! 6. Solver & Convergence Types
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_SOLVER_FULLN = 1_i4  ! full Newton
  INTEGER(i4), PARAMETER :: UF_Solver_BFGS           = 3_i4  ! BFGS quasi-Newton
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_SOLVER_ARCLE = 5_i4  ! arc-length solver
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_CONV_FORCE   = 1_i4  ! force convergence
  INTEGER(i4), PARAMETER :: UF_CONV_DISPLAC          = 2_i4  ! displacement conv
  INTEGER(i4), PARAMETER :: UF_Conv_Energy           = 3_i4  ! energy convergence

  INTEGER(i4), PARAMETER :: MD_MODEL_UF_PREDEF_Temp  = 1_i4  ! predefined temp
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_ENERGY_KE    = 1_i4  ! kinetic energy
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_ENERGY_IE    = 2_i4  ! internal energy
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_ENERGY_SE    = 3_i4  ! strain energy
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_ENERGY_WORKE = 9_i4  ! work energy
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_ENERGY_NUMBU = 16_i4 ! energy buffer size

  !---------------------------------------------------------------------------
  ! 7. MV Location Types
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_MV_LOC_Node  = 1_i4  ! node location
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_MV_LOC_ELEME = 2_i4  ! element location
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_MV_LOC_GLOBA = 3_i4  ! global location
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_MV_LOC_Step  = 4_i4  ! step location
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_MV_LOC_INCRE = 5_i4  ! increment location
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_MV_LOC_CONTA = 6_i4  ! contact location

  !---------------------------------------------------------------------------
  ! 8. Target Types
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_Node  = 1_i4  ! single node
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_NODES = 2_i4  ! node set
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_ELEME = 3_i4  ! single element
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_ELEMS = 4_i4  ! element set
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_SURFA = 5_i4  ! single surface
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_SURFS = 6_i4  ! surface set

  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_SCOPE       = 1_i4  ! model scope
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_SCOPE_PART  = 2_i4  ! part scope
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TARGET_SCOPE_ASSEM = 3_i4  ! assembly scope

  !---------------------------------------------------------------------------
  ! 9. Family & Topology Types
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_FAMILY_UNKNO = 0_i4  ! unknown family
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_FAMILY_CONTI = 1_i4  ! continuum family
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_FAMILY_STRUC = 2_i4  ! structural family
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_FAMILY_THERM = 3_i4  ! thermal family
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_FAMILY_Other = 9_i4  ! other family

  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Unknown = 0_i4  ! unknown topology
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Point   = 1_i4  ! point element
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Line    = 2_i4  ! line element
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Tri     = 3_i4  ! triangle element
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Quad    = 4_i4  ! quadrilateral
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Tet     = 5_i4  ! tetrahedron
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Hex     = 6_i4  ! hexahedron
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Wedge   = 7_i4  ! wedge/prism
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_TOPO_Pyramid = 8_i4  ! pyramid

  !---------------------------------------------------------------------------
  ! 10. Job Status Types
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOB_STATUS_U = 0_i4  ! unknown status
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOB_STATUS_S = 1_i4  ! success
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOB_STATUS_N = 2_i4  ! not converged
  INTEGER(i4), PARAMETER :: MD_MODEL_UF_JOB_STATUS_E = 3_i4  ! error

  !---------------------------------------------------------------------------
  ! 11. Error Categories & Codes
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_ERROR_CATEGORY_PARSE    = 12_i4  ! parse errors
  INTEGER(i4), PARAMETER :: MD_ERROR_CATEGORY_MATERIAL = 13_i4  ! material errors

  ! Parsing errors: 4000-4099
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_PARSE_BASE              = 4000_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_PARSE_SYNTAX_ERROR      = 4001_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_PARSE_INVALID_KEYWORD   = 4002_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_PARSE_MISSING_PARAMETER = 4003_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_PARSE_INVALID_VALUE     = 4004_i4

  ! Validation errors: 4100-4199
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_VALIDATE_BASE               = 4100_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_VALIDATE_INCONSISTENT       = 4101_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_VALIDATE_MISSING_DEPENDENCY = 4102_i4

  ! Material errors: 4200-4299
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_MATERIAL_BASE           = 4200_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_MATERIAL_NOT_FOUND      = 4201_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_MATERIAL_INVALID_PARAMS = 4202_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_MATERIAL_STATE_INVALID  = 4203_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_MATERIAL_LIBRARY_ERROR  = 4204_i4

  ! Model structure errors: 4300-4399
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_MODEL_BASE              = 4300_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_MODEL_INCOMPLETE        = 4301_i4
  INTEGER(i4), PARAMETER :: MD_ERROR_CODE_MODEL_INVALID_STRUCTURE = 4302_i4

  !---------------------------------------------------------------------------
  ! 12. Error Utility Types
  !---------------------------------------------------------------------------

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_UtilsErrorIn_Arg
  ! KIND:  Arg
  ! DESC:  Error reporting input argument bundle
  !---------------------------------------------------------------------------
  TYPE :: Utils_Error_In
    CHARACTER(LEN=256) :: msg = ""  ! error message text
  END TYPE Utils_Error_In


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Base_UtilsErrorOut_Arg
  ! KIND:  Arg
  ! DESC:  Error reporting output argument bundle
  !---------------------------------------------------------------------------
  TYPE :: Utils_Error_Out
    INTEGER(i4) :: status = 0  ! error status code
  END TYPE Utils_Error_Out

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: uf_error
  ! PHASE:      P0
  ! PURPOSE:    Report error via logging system
  !---------------------------------------------------------------------------
  SUBROUTINE uf_error(msg)
    CHARACTER(LEN=*), INTENT(IN) :: msg  ! [in] error message
    CALL log_error("UF_Utils", msg)
  END SUBROUTINE uf_error

END MODULE MD_Base_Enums
