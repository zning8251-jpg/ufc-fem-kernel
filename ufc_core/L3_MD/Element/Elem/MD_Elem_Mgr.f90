!===============================================================================
! MODULE:  MD_Elem_Mgr
! LAYER:   L3_MD
! DOMAIN:  Element / Elem
! ROLE:    _Mgr
! BRIEF:   Element manager — P0 Register: unified element type system
!          and catalog with formulation descriptors.
! **W2**：**ElemType/ElemFormul** 统一目录与 L3 注册；与 **`MD_Elem_Reg`** / **Populate** 类型 ID 真源一致。
!===============================================================================
!
! Contents (A-Z):
!   Types:
!     - ElemType (Desc): Element type descriptor
!     - ElemFormul (Desc): Element formulation descriptor
!     - ElemCtx (Ctx): Element context
!     - IPState (State): Integration point state (imported from MD_Mesh_Elem_Types)
!     - ElemState (State): Element state
!   Subroutines:
!     - ElemType_Init, ElemFormul_Init, ElemCtx_Init
!     - IPState_Init, ElemState_Init
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Element | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Element/Elem/CONTRACT.md

MODULE MD_Elem_Mgr
!>>> UFC_L3_CONTRACT | Element/Elem/CONTRACT.md
  !! UniField-Core Element Core Module
  !! Design Principles:
  !!   - Unified Element type system
  !!   - Element catalog management
  !!   - Element dispatch system
  !!   - User Element support

  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
                        IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND, IF_STATUS_NOT_FOUND
  USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_AllocReal2D, &
                        UF_Mem_FreeReal1D, UF_Mem_FreeReal2D, &
                        IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER
  USE IF_Prec_Core,        only: wp, i4, i8
  USE MD_Mesh_NodeDef, ONLY: MD_Node_Type
  USE MD_Base_Enums, ONLY: UF_FAMILY_CONTI, UF_TOPO_Point, UF_TOPO_Line, &
                           UF_TOPO_Tri, UF_TOPO_Quad, UF_TOPO_Tet, &
                           UF_TOPO_Hex, UF_TOPO_Wedge, UF_TOPO_Pyramid
  USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, StateBase, CtxBase, &
                              CAT_DESC, CAT_STATE, CAT_CTX, UF_FAMILY_UNKNO, &
                              UF_Topo_Unknown
  USE IF_Err_Brg, ONLY: uf_set_error
  USE MD_Base_ObjModel,         only: UF_FAMILY_CONTI
  USE MD_Mat_Lib, only: MatProps
  USE MD_Mesh_Elem, ONLY: MeshElemState, MeshElemDesc, IPState
  ! Use MD_Kinematics_Def only; avoid MD_TypeSystem/MD_Element_Base to break
  ! circular dep: MD_Elem_Algo <-> MD_Element_Base. UF_Kinematics_Solid2D_FromContext
  ! uses base ElemType/ElemFormul/ElemCtx (not UF_* extended types).
  use MD_Kinematics_Def,  only: UF_Kinematics
  use MD_Out_UniFld,          only: GetEffOrder
  ! Bridge modules for L4_PH and L5_RT layer access (no direct USE)
  use MD_ElemPH_Brg, only: MD_PH_Elem_CalcContinuum2D, MD_PH_Elem_CalcContinuum3D, &
                            MD_PH_Elem_CalcPoroSaturated, MD_PH_Elem_CalcPoroTwoPhase, &
                            MD_PH_Elem_CalcThermal, MD_PH_Elem_CalcTHM
  use MD_ElemRT_Brg, only: MD_RT_Elem_Comp
  implicit none

  private

  !=============================================================================
  ! Element Type Constants (from MD_Element_Type, merged)
  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_UNKNOWN = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_POINT = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_LINE2 = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_LINE3 = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_TRI3 = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_TRI6 = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_QUAD4 = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_QUAD8 = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_TET4 = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_TET10 = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_HEX8 = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_HEX20 = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_WEDGE6 = 12_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_WEDGE15 = 13_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_PYRAMID5 = 14_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_PYRAMID13 = 15_i4
  
  ! Shell elements (ABAQUS 6-21, 6 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_S3 = 100_i4      ! S3 - 3-node triangular shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_S3R = 101_i4   ! S3R - reduced S3
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_S4 = 102_i4      ! S4 - 4-node quad shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_S4R = 103_i4     ! S4R - reduced S4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_S8R = 104_i4     ! S8R - reduced S8
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_S8  = 104_i4     ! S8 - 8-node quad shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_S9R5 = 105_i4   ! S9R5 - reduced S9
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_S9  = 105_i4    ! S9 - 9-node shell
  
  ! Truss elements (ABAQUS 2-24, 3D)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_T2D2 = 200_i4    ! T2D2 - 2-node 2D truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_T3D2 = 201_i4    ! T3D2 - 2-node 3D truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_T3D3 = 202_i4    ! T3D3 - 3-node 3D truss
  
  ! Membrane elements (ABAQUS 25-28)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_M3D3 = 300_i4    ! M3D3 - 3-node membrane
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_M3D4 = 301_i4    ! M3D4 - 4-node membrane
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_M3D4R = 302_i4   ! M3D4R - reduced M3D4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEMENT_M3D8R = 303_i4   ! M3D8R - 8-node membrane
  
  ! Form IDs 17+ (C3D etc), ~30 total
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_UNKNOWN = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_LAGRANGE = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_SERENDIPIT = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_HIERARCHIC = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_NURBS = 4_i4
  ! Enhanced Formul type IDs (for RT_Elem_Impl compatibility)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_C3D4 = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_C3D4R = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_C3D6 = 12_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_C3D6R = 13_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_C3D10 = 14_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_C3D10R = 15_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_C3D15R = 16_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_C3D20 = 20_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_FORM_S8 = 8_i4

  !=============================================================================
  ! Abaqus-Compatible Element Type Constants (merged from MD_Element_Types.f90)
  ! These use MD_MESH_ELEM_* naming convention for Abaqus compatibility
  !=============================================================================
  
  ! USER-DEFINED ELEMENT
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_USER = 0_i4
  
  ! 3D CONTINUUM ELEMENTS (C3Dxx) - Range 1-99
  ! Tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D4   = 1_i4    ! 4-node tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D10  = 2_i4    ! 10-node tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D10M = 3_i4    ! 10-node modified tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D10E = 4_i4    ! 10-node enhanced tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D10R = 5_i4    ! 10-node reduced integration tetrahedron
  
  ! Hexahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8   = 10_i4   ! 8-node hexahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8R  = 11_i4   ! 8-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8I  = 12_i4   ! 8-node incompatible modes
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8H  = 13_i4   ! 8-node hybrid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D20  = 14_i4   ! 20-node hexahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D20R = 15_i4   ! 20-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D20H = 16_i4   ! 20-node hybrid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D20I = 18_i4   ! 20-node incompatible modes
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D27  = 17_i4   ! 27-node hexahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D27R = 19_i4   ! 27-node reduced integration
  
  ! Wedge (Pentahedron)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D6   = 20_i4   ! 6-node wedge
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D15  = 21_i4   ! 15-node wedge
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D6R  = 22_i4   ! 6-node wedge, reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D15R = 23_i4   ! 15-node wedge, reduced integration
  
  ! Pyramid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D5   = 25_i4   ! 5-node pyramid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D13  = 26_i4   ! 13-node pyramid
  
  ! Coupled 3D elements
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8T  = 30_i4   ! 8-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D20T = 31_i4   ! 20-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8P  = 35_i4   ! 8-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D20P = 36_i4   ! 20-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8PT = 40_i4   ! 8-node pore pressure + thermal
  ! 3D thermo-mechanical (displacement + temperature per node); L4: PH_Elem_C3D*n*T_Core
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D4T   = 32_i4   ! 4-node tet thermal coupled (16 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D6T   = 33_i4   ! 6-node wedge thermal coupled (24 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D10T  = 34_i4   ! 10-node tet thermal coupled (40 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D15T  = 37_i4   ! 15-node wedge thermal coupled (60 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D27T  = 38_i4   ! 27-node hex thermal coupled (108 dof)
  ! 3D displacement鈥損ore pressure (L4: PH_Elem_C3D*n*P_Core); ids in gap 39?4 (40 = C3D8PT)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D4P   = 39_i4   ! 4-node tet pore coupled (16 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D6P   = 41_i4   ! 6-node wedge pore coupled (24 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D10P  = 42_i4   ! 10-node tet pore coupled (40 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D15P  = 43_i4   ! 15-node wedge pore coupled (60 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D27P  = 44_i4   ! 27-node hex pore coupled (108 dof)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8EAS = 45_i4   ! 8-node hex enhanced assumed strain
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_C3D8FBAR= 46_i4   ! 8-node hex F-bar variant
  
  ! 2D CONTINUUM - PLANE STRAIN (CPExx) - Range 100-149
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE3   = 100_i4  ! 3-node triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE6   = 101_i4  ! 6-node triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE6R  = 102_i4  ! 6-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE4   = 110_i4  ! 4-node quadrilateral
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE4R  = 111_i4  ! 4-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE4H  = 112_i4  ! 4-node hybrid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE4I  = 116_i4  ! 4-node incompatible modes
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE8   = 113_i4  ! 8-node quadrilateral
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE8R  = 114_i4  ! 8-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE8H  = 115_i4  ! 8-node hybrid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE8I  = 117_i4  ! 8-node incompatible modes
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE3T  = 118_i4  ! 3-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE6T  = 119_i4  ! 6-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE4T  = 120_i4  ! 4-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE8T  = 121_i4  ! 8-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE3P  = 122_i4  ! 3-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE6P  = 123_i4  ! 6-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE4P  = 125_i4  ! 4-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPE8P  = 126_i4  ! 8-node pore pressure coupled
  ! Generalized plane strain (CPEG)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPEG4  = 130_i4  ! 4-node generalized plane strain
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPEG4R = 131_i4  ! 4-node reduced
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPEG6  = 132_i4  ! 6-node generalized plane strain
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPEG8  = 133_i4  ! 8-node generalized plane strain
  
  ! 2D CONTINUUM - PLANE STRESS (CPSxx) - Range 150-199
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS3   = 150_i4  ! 3-node triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS6   = 151_i4  ! 6-node triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS6R  = 152_i4  ! 6-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS4   = 160_i4  ! 4-node quadrilateral
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS4R  = 161_i4  ! 4-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS4I  = 164_i4  ! 4-node incompatible modes
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS8   = 162_i4  ! 8-node quadrilateral
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS8R  = 163_i4  ! 8-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS3T  = 168_i4  ! 3-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS6T  = 169_i4  ! 6-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS4T  = 170_i4  ! 4-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS8T  = 171_i4  ! 8-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS3P  = 172_i4  ! 3-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS4P  = 173_i4  ! 4-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS6P  = 174_i4  ! 6-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CPS8P  = 175_i4  ! 8-node pore pressure coupled
  
  ! 2D CONTINUUM - AXISYMMETRIC (CAXxx) - Range 200-249
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX3   = 200_i4  ! 3-node triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX6   = 201_i4  ! 6-node triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX6R  = 202_i4  ! 6-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX4   = 210_i4  ! 4-node quadrilateral
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX4R  = 211_i4  ! 4-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX4H  = 212_i4  ! 4-node hybrid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX8   = 213_i4  ! 8-node quadrilateral
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX8R  = 214_i4  ! 8-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX8I  = 215_i4  ! 8-node incompatible modes
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX8H  = 216_i4  ! 8-node hybrid
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX3T  = 218_i4  ! 3-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX6T  = 219_i4  ! 6-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX4T  = 220_i4  ! 4-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX8T  = 221_i4  ! 8-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX3P  = 222_i4  ! 3-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX6P  = 223_i4  ! 6-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX4P  = 225_i4  ! 4-node pore pressure coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CAX8P  = 226_i4  ! 8-node pore pressure coupled
  
  ! SHELL ELEMENTS (Sxx) - Range 300-399
  ! Triangular shells
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S3    = 300_i4   ! 3-node shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S3R   = 305_i4   ! 3-node reduced shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_STRI3 = 301_i4   ! 3-node thin shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S6    = 302_i4   ! 6-node shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S6R   = 303_i4   ! 6-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_STRI65= 304_i4   ! 6-node 5-DOF thin shell
  
  ! Quadrilateral shells
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S4    = 310_i4   ! 4-node general shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S4R   = 311_i4   ! 4-node reduced integration (most common)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S4RS  = 312_i4   ! 4-node small strain
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S4R5  = 316_i4   ! 4-node 5-DOF thin shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S8    = 313_i4   ! 8-node shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S8R   = 314_i4   ! 8-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S8R5  = 317_i4   ! 8-node 5-DOF thin shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S9R5  = 315_i4   ! 9-node 5-DOF shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S9    = 318_i4   ! 9-node shell
  
  ! Continuum shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_SC6R  = 320_i4   ! 6-node continuum shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_SC8R  = 321_i4   ! 8-node continuum shell
  
  ! Thermal coupled shells
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S4T   = 330_i4   ! 4-node thermal coupled
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_S8RT  = 331_i4   ! 8-node reduced thermal coupled
  
  ! Axisymmetric shells (SAX)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_SAX1  = 335_i4   ! 1-node axisymmetric shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_SAX2  = 336_i4   ! 2-node axisymmetric shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_SAX2T = 337_i4   ! 2-node axisymmetric shell thermal
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DS3   = 340_i4   ! 3-node thermal shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DS4   = 341_i4   ! 4-node thermal shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DS6   = 342_i4   ! 6-node thermal shell
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DS8   = 343_i4   ! 8-node thermal shell
  
  ! BEAM ELEMENTS (Bxx) - Range 400-449
  ! 2D Beams
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B21   = 400_i4   ! 2-node 2D beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B21H  = 401_i4   ! 2-node 2D hybrid beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B22   = 402_i4   ! 3-node 2D beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B22H  = 403_i4   ! 3-node 2D hybrid beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B23   = 405_i4   ! 2-node 2D cubic beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B21T  = 404_i4   ! 2-node 2D beam + TEMP (8 dof: 2x(3 mech + T))
  
  ! 3D Beams
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B31   = 410_i4   ! 2-node 3D beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B31H  = 411_i4   ! 2-node 3D hybrid beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B31OS = 412_i4   ! 2-node 3D open section beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B32   = 413_i4   ! 3-node 3D beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B32H  = 414_i4   ! 3-node 3D hybrid beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B32OS = 415_i4   ! 3-node 3D open section beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B33   = 416_i4   ! 2-node 3D cubic beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B33H  = 417_i4   ! 2-node 3D cubic hybrid beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B34   = 418_i4   ! 2-node 3D pipe beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B34H  = 419_i4   ! 2-node 3D pipe hybrid beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B31T  = 420_i4   ! 2-node 3D thermal beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_B31EX = 421_i4   ! 2-node 3D external beam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_PIPE21= 430_i4   ! 2-node pipe
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_PIPE22= 431_i4   ! 2-node pipe variant
  
  ! TRUSS ELEMENTS (Txx) - Range 450-479
  ! 2D Truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T2D2  = 450_i4   ! 2-node 2D truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T2D2H = 451_i4   ! 2-node 2D hybrid truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T2D3  = 452_i4   ! 3-node 2D truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T2D3H = 453_i4   ! 3-node 2D hybrid truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T2D2T = 454_i4   ! 2-node 2D thermal truss
  
  ! 3D Truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T3D2  = 460_i4   ! 2-node 3D truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T3D2H = 461_i4   ! 2-node 3D hybrid truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T3D3  = 462_i4   ! 3-node 3D truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T3D3H = 463_i4   ! 3-node 3D hybrid truss
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_T3D2T = 464_i4   ! 2-node 3D thermal truss
  
  ! MEMBRANE ELEMENTS (Mxx) - Range 480-499
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D3  = 480_i4   ! 3-node membrane
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D3R = 481_i4   ! 3-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D4  = 482_i4   ! 4-node membrane
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D4R = 483_i4   ! 4-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D6  = 484_i4   ! 6-node membrane
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D6R = 485_i4   ! 6-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D8  = 486_i4   ! 8-node membrane
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D8R = 487_i4   ! 8-node reduced integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M3D9R = 488_i4   ! 4-node routed membrane proxy
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M2D3  = 490_i4   ! 3-node 2D membrane
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M2D3R = 491_i4   ! 3-node 2D reduced
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M2D4  = 492_i4   ! 4-node 2D membrane
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_M2D4R = 493_i4   ! 4-node 2D reduced
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_MAX2  = 495_i4   ! 2-node axisymmetric membrane
  
  ! HEAT TRANSFER ELEMENTS (DCxx) - Range 500-549
  ! 1D
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC1D2 = 500_i4   ! 2-node 1D heat
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC1D3 = 501_i4   ! 3-node 1D heat
  
  ! 2D
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC2D3 = 510_i4   ! 3-node 2D triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC2D4 = 511_i4   ! 4-node 2D quad
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC2D6 = 512_i4   ! 6-node 2D triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC2D8 = 513_i4   ! 8-node 2D quad
  
  ! 3D
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC3D4 = 520_i4   ! 4-node tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC3D6 = 521_i4   ! 6-node wedge
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC3D8 = 522_i4   ! 8-node hexahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC3D10= 523_i4   ! 10-node tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC3D15= 524_i4   ! 15-node wedge
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DC3D20= 525_i4   ! 20-node hexahedron
  
  ! PORE DIFFUSION TEST ELEMENTS (Pxx...) - Range 800-819
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_P3D8SAT = 800_i4   ! 8-node 3D pore diffusion (saturated hexahedron)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_P3D8RCH = 801_i4   ! 8-node 3D Richards/two-phase hexahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_P3D6SAT = 802_i4   ! 6-node 3D pore diffusion (saturated wedge)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_P3D6RCH = 803_i4   ! 6-node 3D Richards/two-phase wedge
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_P2D4SAT = 810_i4   ! 4-node 2D pore diffusion (saturated quad)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_P2D4RCH = 811_i4   ! 4-node 2D Richards/two-phase quad
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_P2D8SAT = 812_i4   ! 8-node 2D pore diffusion (saturated quad)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_P2D8RCH = 813_i4   ! 8-node 2D Richards/two-phase quad
  
  ! ACOUSTIC ELEMENTS (ACxx) - Range 550-599
  ! 1D
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC1D2 = 550_i4   ! 2-node 1D acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC1D3 = 551_i4   ! 3-node 1D acoustic
  
  ! 2D
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC2D3 = 560_i4   ! 3-node 2D triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC2D4 = 561_i4   ! 4-node 2D quad
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC2D4R= 562_i4   ! 4-node 2D reduced
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC2D6 = 563_i4   ! 6-node 2D triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC2D8 = 564_i4   ! 8-node 2D quad
  
  ! 3D
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC3D4 = 570_i4   ! 4-node tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC3D6 = 571_i4   ! 6-node wedge
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC3D8 = 572_i4   ! 8-node hexahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC3D8R= 573_i4   ! 8-node reduced
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC3D10= 574_i4   ! 10-node tetrahedron
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC3D15= 575_i4   ! 15-node wedge
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_AC3D20= 576_i4   ! 20-node hexahedron
  
  ! Axisymmetric acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_ACAX3 = 580_i4   ! 3-node axisymmetric acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_ACAX4 = 581_i4   ! 4-node axisymmetric acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_ACAX6 = 582_i4   ! 6-node axisymmetric acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_ACAX8 = 583_i4   ! 8-node axisymmetric acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_ACAX4R= 584_i4   ! 4-node axisymmetric acoustic reduced
  
  ! COHESIVE ELEMENTS (COHxx) - Range 600-649
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_COH2D4  = 600_i4  ! 4-node 2D cohesive
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_COH2D6  = 601_i4  ! 6-node 2D cohesive
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_COHAX4  = 605_i4  ! 4-node axisymmetric cohesive
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_COHAX6  = 606_i4  ! 6-node axisymmetric cohesive
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_COH3D6  = 610_i4  ! 6-node 3D cohesive (triangular)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_COH3D8  = 611_i4  ! 8-node 3D cohesive (quad)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_COH3D12 = 612_i4  ! 12-node 3D cohesive
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_COH3D16 = 613_i4  ! 16-node 3D cohesive
  
  ! RIGID ELEMENTS (Rxx) - Range 650-659
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_R2D2  = 650_i4   ! 2-node 2D rigid link
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_R3D3  = 651_i4   ! 3-node 3D rigid triangle
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_R3D4  = 652_i4   ! 4-node 3D rigid quad
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_RAX2  = 653_i4   ! 2-node axisymmetric rigid
  
  ! CONNECTOR & SPECIAL ELEMENTS - Range 700-799
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CONN2D2 = 700_i4  ! 2-node 2D connector
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_CONN3D2 = 701_i4  ! 2-node 3D connector
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_SPRING1 = 710_i4  ! 1-node spring (ground)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_SPRING2 = 711_i4  ! 2-node spring
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_SPRINGA = 712_i4  ! Axial spring
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DASHPOT1= 720_i4  ! 1-node dashpot
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_DASHPOT2= 721_i4  ! 2-node dashpot
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_MASS    = 730_i4  ! Point mass
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_ELEM_ROTARYI = 731_i4  ! Rotary inertia
  
  ! STRESS/STRAIN COMPONENT COUNTS (for NTENS, NDI, NSHR)
  ! NTENS: Total number of stress/strain components
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NTENS_1D = 1_i4        ! 1D: ?_xx
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NTENS_2D_PE = 4_i4     ! 2D Plane Strain: ?_xx, ?_yy, ?_zz, ?_xy
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NTENS_2D_PS = 3_i4     ! 2D Plane Stress: ?_xx, ?_yy, ?_xy
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NTENS_3D = 6_i4        ! 3D: ?_xx, ?_yy, ?_zz, ?_xy, ?_xz, ?_yz
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NTENS_AXI = 4_i4       ! Axisymmetric: ?_rr, ?_zz, ?_??, ?_rz
  
  ! NDI: Number of direct stress components
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NDI_1D = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NDI_2D = 2_i4          ! Plane stress
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NDI_2D_PE = 3_i4       ! Plane strain (includes ?_zz)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NDI_3D = 3_i4
  
  ! NSHR: Number of shear stress components
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NSHR_1D = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NSHR_2D = 1_i4         ! ?_xy
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_NSHR_3D = 3_i4         ! ?_xy, ?_xz, ?_yz

  !=============================================================================
  ! Element Type Definitions (alias: ElementType -> ElemType)
  !=============================================================================
  
  !=============================================================================
  ! TYPE: ElemType
  ! Category: Desc (Descriptor - read-only configuration)
  ! Purpose: Element type descriptor containing element topology and DOF information.
  ! Members:
  !   elem_type_id: Element type identifier
  !   name: Element name (e.g., "C3D8", "S4R")
  !   n_nodes: Number of nodes
  !   n_edges / n_faces: Topology counts
  !   dim: Spatial dimension n_dim ?{2,3}
  !   family / topo: Family and topology identifiers
  !   n_dof_per_node: DOF per node
  !   n_int_points: Default integration point count n_gp
  !   has_struct / has_thermal / has_pore: Physics capability flags
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(DescBase) :: ElemType
    INTEGER(i4) :: elem_type_id = 0_i4
    INTEGER(i4) :: n_nodes = 0_i4                    ! n_nodes  ??^+
    INTEGER(i4) :: n_edges = 0_i4                    ! n_edges  ??^+
    INTEGER(i4) :: n_faces = 0_i4                    ! n_faces  ??^+
    INTEGER(i4) :: dim = 0_i4                       ! n_dim  ?{2,3}
    INTEGER(i4) :: family = 0_i4
    INTEGER(i4) :: topo = 0_i4
    INTEGER(i4) :: n_dof_per_node = 0_i4               ! n_dof_per_node  ??^+
    INTEGER(i4) :: n_int_points = 0_i4                ! n_gp  ??^+
    LOGICAL :: has_struct = .false.
    LOGICAL :: has_thermal = .false.
    LOGICAL :: has_pore = .false.
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => ElemType_RegLayout
    PROCEDURE, PUBLIC :: Ensure => ElemType_Ensure
    PROCEDURE, PUBLIC :: Init => ElemType_Init_Base
  END TYPE ElemType

  !=============================================================================
  ! TYPE: ElemFormul
  ! Category: Desc (Descriptor - read-only configuration)
  ! Purpose: Element formulation descriptor containing integration and formulation parameters.
  ! Members:
  !   formulationType: Formulation type identifier
  !   order: Polynomial order p ??^+
  !   nIntPoints: Number of integration points n_gp ??^+
  !   reducedintegrat: Reduced integration flag
  !   hourglasscontro: Hourglass control flag
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(DescBase) :: ElemFormul
    INTEGER(i4) :: formulationType = MD_MESH_FORM_UNKNOWN
    INTEGER(i4) :: order = 1_i4                     ! p  ??^+
    INTEGER(i4) :: nIntPoints = 0_i4                 ! n_gp  ??^+
    LOGICAL :: reducedintegrat = .false.
    LOGICAL :: hourglasscontro = .false.
    ! --- Aligned with MD_Element_Base / UF_ElemFormul (kinematics & integration policy) ---
    INTEGER(i4) :: kineFormulation = 2_i4           ! default UL (see UF_Form_UL = 2)
    INTEGER(i4) :: integration_scheme = 1_i4        ! default full (see UF_Int_Full = 1)
    LOGICAL :: use_bbar = .false.
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => ElemFormul_RegLayout
    PROCEDURE, PUBLIC :: Ensure => ElemFormul_Ensure
    PROCEDURE, PUBLIC :: Init => ElemFormul_Init_Base
  END TYPE ElemFormul

  !=============================================================================
  ! TYPE: ElemCtx
  ! Category: Ctx (Context - aggregates references/embedding of Desc/State/Algo)
  ! Purpose: Element context aggregating element type, configuration, and coordinate data.
  ! Members:
  !   id: Element context identifier
  !   ElemType: Element type identifier
  !   nNodes: Number of nodes n_nodes ??^+
  !   nIntPoints: Number of integration points n_gp ??^+
  !   currentTime: Current time t ? ?
  !   deltaTime: Time increment ?t ??^+
  !   coords_ref: Reference coordinates X? ??^(n_dim n_nodes)
  !   coords_prev: Previous coordinates X_{n} ??^(n_dim n_nodes)
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(CtxBase) :: ElemCtx
    INTEGER(i4) :: id = 0_i4
    INTEGER(i4) :: ElemType = MD_MESH_ELEMENT_UNKNOWN
    INTEGER(i4) :: nNodes = 0_i4                    ! n_nodes
    INTEGER(i4) :: nIntPoints = 0_i4                ! n_gp
    REAL(wp) :: currentTime = 0.0_wp                ! t
    REAL(wp) :: deltaTime = 0.0_wp                  ! dt
    REAL(wp), ALLOCATABLE :: coords_ref(:,:)        ! X0
    REAL(wp), ALLOCATABLE :: coords_prev(:,:)       ! X_n
    REAL(wp), ALLOCATABLE :: coords_curr(:,:)       ! X_curr = X0 + u (UL)
    REAL(wp), ALLOCATABLE :: disp_total(:,:)        ! u (n_dim, n_nodes)
    REAL(wp), ALLOCATABLE :: disp_incr(:,:)         ! du (n_dim, n_nodes)
    ! [Data chain] three-step indexing L3鈫扡5
    INTEGER(i4) :: step_idx = 0_i4                 ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => ElemCtx_RegLayout
    PROCEDURE, PUBLIC :: Ensure => ElemCtx_Ensure
    PROCEDURE, PUBLIC :: Init => ElemCtx_Init
  END TYPE ElemCtx

  !=============================================================================
  ! TYPE: IPState
  ! Note: IPState is defined in MD_Mesh_Elem_Types to break circular dependency.
  ! It is imported via USE MD_Mesh_Elem_Types, ONLY: IPState
  !=============================================================================

  !=============================================================================
  ! TYPE: ElemState
  ! Category: State (State - read/write runtime data)
  ! Purpose: Element state containing element matrices and runtime data.
  ! Members:
  !   id: Element state identifier
  !   failed: Failure flag
  !   stableDt: Stable time step ?t_stable ??^+
  !   Ke: Element stiffness matrix K_e ??^(n_dof_e n_dof_e)
  !   Re: Element residual vector R_e ??^(n_dof_e)
  !   Me: Element mass matrix M_e ??^(n_dof_e n_dof_e)
  !   Ce: Element damping matrix C_e ??^(n_dof_e n_dof_e)
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(StateBase) :: ElemState
    INTEGER(i4) :: id = 0_i4
    LOGICAL :: failed = .false.
    REAL(wp) :: stableDt = 0.0_wp                   ! ?t_stable  ??^+
    REAL(wp), POINTER :: Ke(:,:) => NULL()         ! K_e  ??^(n_dof_e n_dof_e)
    REAL(wp), POINTER :: Re(:) => NULL()            ! R_e  ??^(n_dof_e)
    REAL(wp), POINTER :: Me(:,:) => NULL()          ! M_e  ??^(n_dof_e n_dof_e)
    REAL(wp), POINTER :: Ce(:,:) => NULL()          ! C_e  ??^(n_dof_e n_dof_e)
    INTEGER(i4) :: Ke_id = -1_i4, Re_id = -1_i4, Me_id = -1_i4, Ce_id = -1_i4
    TYPE(IPState), ALLOCATABLE :: ipStates(:)
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => ElemState_RegLayout
    PROCEDURE, PUBLIC :: Ensure => ElemState_Ensure
    PROCEDURE, PUBLIC :: Init => ElemState_Init
  END TYPE ElemState

  TYPE, PUBLIC :: ShapeFuncResult
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4) :: nIntPoints = 0_i4
    REAL(wp), ALLOCATABLE :: N(:,:)
    REAL(wp), ALLOCATABLE :: dNdxi(:,:,:)
    REAL(wp), ALLOCATABLE :: dNdx(:,:,:)
    REAL(wp), ALLOCATABLE :: detJ(:)
    REAL(wp), ALLOCATABLE :: weights(:)
  CONTAINS
    PROCEDURE, PUBLIC :: Init => ShapeFuncResult_Init
    PROCEDURE, PUBLIC :: Clear => ShapeFuncResult_Clear
  END TYPE ShapeFuncResult

  TYPE, PUBLIC :: ElemFlags
    LOGICAL :: failed = .false.
    LOGICAL :: suggest_cutback = .false.
    LOGICAL :: requires_reasse = .false.
    REAL(wp) :: stableDt = 0.0_wp
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: nlgeom = 0_i4            ! Geometric nonlinearity flag (0=OFF,1=ON)
    INTEGER(i4) :: formulation_typ = 0_i4   ! 0=linear, 1=TL, 2=UL
  END TYPE ElemFlags

  !=============================================================================
  ! Abstract Interface for StructGaussKernel
  !=============================================================================
  abstract interface
    subroutine UF_Struct_IpKernel(ip, sf, dN_dx, dVol, radius)
      import :: wp, i4, ShapeFuncResult
      integer(i4), intent(in) :: ip
      type(ShapeFuncResult), intent(in) :: sf
      real(wp), intent(in) :: dN_dx(:,:)
      real(wp), intent(in) :: dVol, radius
    end subroutine UF_Struct_IpKernel
  end abstract interface

  !=============================================================================
  ! Element Family Constants
  !=============================================================================
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY    = 1_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY   = 2_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY        = 3_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY        = 4_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY     = 5_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY         = 6_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY        = 7_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY       = 8_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY      = 9_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_FAMILY         = 99_i4

  !=============================================================================
  ! Element Catalog Connectivity Constants
  !=============================================================================
  integer(i4), parameter, public :: MD_MESH_UF_EC_MAX_FACE  = 6_i4
  integer(i4), parameter, public :: MD_MESH_UF_EC_MAX_EDGE  = 12_i4
  integer(i4), parameter, public :: MD_MESH_UF_EC_MAX_NODES = 9_i4
  integer(i4), parameter, public :: MD_MESH_UF_EC_MAX_NODES = 3_i4

  !=============================================================================
  ! Element Type Constants (Extended with FEAP-style elements)
  !=============================================================================
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_CP        = 1_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_CP        = 2_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_C3        = 3_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_C3       = 4_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_S4          = 5_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_S8          = 6_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_S4         = 7_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_B2         = 8_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_B3         = 9_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_T2        = 10_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_T2       = 11_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_T3        = 12_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_M3        = 13_i4
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_M3        = 14_i4
  ! FEAP-style beam and shell elements
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_B2   = 15_i4   ! Euler-Bernoulli beam
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_B2    = 16_i4   ! Timoshenko beam
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_S4    = 17_i4   ! Kirchhoff-Love shell
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_S4  = 18_i4   ! Mindlin-Reissner shell
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_S4 = 19_i4  ! Composite shell
  integer(i4), parameter, public :: MD_MESH_ELEMENT_TYPE_US        = 999_i4

  !===============================================================================
  ! FEAP-Style Element Constants
  !===============================================================================

  ! Beam element types
  integer(i4), parameter, public :: MD_MESH_BEAM_EULER_BERN = 1
  integer(i4), parameter, public :: MD_MESH_BEAM_TIMOSHENKO      = 2
  integer(i4), parameter, public :: MD_MESH_BEAM_COMPOSITE       = 3

  ! Shell element types
  integer(i4), parameter, public :: MD_MESH_SHELL_THIN_KIRC = 1
  integer(i4), parameter, public :: MD_MESH_SHELL_THICK_MIN  = 2
  integer(i4), parameter, public :: MD_MESH_SHELL_COMPOSITE      = 3

  !=============================================================================
  ! Element Metadata Type
  !=============================================================================
  type, public :: ElementMetadata
    integer(i4)                          :: element_type           = 0_i4
    integer(i4)                          :: family              = MD_MESH_ELEMENT_FAMILY
    character(len=80)                    :: name                = ""
    character(len=200)                   :: description         = ""
    integer(i4)                          :: nNodes           = 0_i4
    integer(i4)                          :: nIps             = 0_i4
    integer(i4)                          :: nDofs            = 0_i4
    integer(i4)                          :: spatial_dim         = 0_i4
    logical                              :: supports_2d         = .true.
    logical                              :: supports_3d         = .true.
    logical                              :: supports_nlgeom     = .true.
    logical                              :: supports_materi   = .true.
    logical                              :: available           = .true.
  contains
    procedure :: Init
    procedure :: Clean
    procedure :: Valid
    procedure :: GetFamilyName
  end type ElementMetadata

  !=============================================================================
  ! Desc_Element (from MD_Elem_API, merged Phase 2)
  ! External description type for element conversion from frontend/IO.
  !=============================================================================
  type, public :: Desc_Element
    integer(i4) :: element_type = 0_i4
    character(len=64) :: element_type_na = ""
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: nIntPoints = 0_i4
  end type Desc_Element

  !=============================================================================
  ! Element Catalog Type
  !=============================================================================
  type, public :: ElementCatalog
    integer(i4)                          :: nElems        = 0_i4
    integer(i4)                          :: max_elements        = 100_i4
    type(ElementMetadata), allocatable   :: elements(:)
    LOGICAL :: init = .false.
  contains
    procedure :: Init
    procedure :: Clean
    procedure :: RegisterElement
    procedure :: GetElement
    procedure :: FindElement
    procedure :: ListElements
    procedure :: GetElementsByFamily
    procedure :: InitDefaults
  end type ElementCatalog

  ! Global element catalog
  type(ElementCatalog), save :: g_element_catal

  ! Public interfaces - sorted alphabetically
  public :: Desc_Element
  public :: ElementCatalog
  public :: ElementMetadata
  public :: Element_FromDesc_Metadata
  public :: UF_Adapt_ElementState_To_State
  public :: UF_Adapt_ElementType_To_Desc
  public :: UF_ApplyEdgeLoad
  public :: UF_ApplyFacePressure
  public :: UF_ApplyFaceTraction
  public :: UF_ElementCatalog_GetConnectivity
  public :: UF_GetFaceNormal
  public :: StructGaussKernel
  public :: UF_Struct_GaussKernel
  
  ! From MD_Element_Dispatch.f90
  public :: DispatchCompute
  public :: DispatchFromType
  
  ! From MD_Element_KinHelpers.f90
  public :: UF_Kinematics_Solid2D_FromContext
  ! [REMOVED] Legacy alias Kin_Solid2D_FromCtx (no external refs)
  
  ! From MD_Element_User.f90
  public :: Calc_UserElement
  public :: UF_Init_UserElement
  ! From merged MD_Element_Type
  public :: ElemType, ElemFormul, ElemCtx, ShapeFuncResult, ElemFlags, ElemState
  ! Note: IPState is re-exported from MD_Mesh_Elem_Types
  public :: IPState
  public :: UF_Element_PrepareIntPointStates, UF_Elem_PrepareStructStorage
  public :: UF_ElementType_FillById, UF_ElementType_FromId

contains

  !=============================================================================
  ! Element Type procedures (from merged MD_Element_Type)
  !=============================================================================
  SUBROUTINE UF_ElementType_FillById(this, elemTypeId)
    CLASS(ElemType), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: elemTypeId
    INTEGER(i4) :: dof_per_node, nNodes, nEdges, nFaces, dim, topo, nInt
    CHARACTER(len=64) :: name
    dof_per_node = 3_i4
    nNodes   = 0_i4
    nEdges = 0_i4
    nFaces = 0_i4
    dim      = 3_i4
    topo     = UF_TOPO_Unknown
    nInt     = 1_i4
    name     = 'UNKNOWN'
    SELECT CASE (elemTypeId)
    CASE (MD_MESH_ELEMENT_POINT)
      name='POINT1'
      dim=1
      topo=UF_TOPO_Point
      nNodes=1
      nEdges=0
      nFaces=0
      nInt=1
    CASE (MD_MESH_ELEMENT_LINE2)
      name='B31'
      dim=1
      topo=UF_TOPO_Line
      nNodes=2
      nEdges=1
      nFaces=0
      nInt=2
    CASE (MD_MESH_ELEMENT_LINE3)
      name='B32'
      dim=1
      topo=UF_TOPO_Line
      nNodes=3
      nEdges=1
      nFaces=0
      nInt=3
    CASE (MD_MESH_ELEMENT_TRI3)
      name='CPE3'
      dim=2
      topo=UF_TOPO_Tri
      nNodes=3
      nEdges=3
      nFaces=1
      nInt=3
    CASE (MD_MESH_ELEMENT_TRI6)
      name='CPE6'
      dim=2
      topo=UF_TOPO_Tri
      nNodes=6
      nEdges=3
      nFaces=1
      nInt=3
    CASE (MD_MESH_ELEMENT_QUAD4)
      name='CPE4'
      dim=2
      topo=UF_TOPO_Quad
      nNodes=4
      nEdges=4
      nFaces=1
      nInt=4
    CASE (MD_MESH_ELEMENT_QUAD8)
      name='CPE8'
      dim=2
      topo=UF_TOPO_Quad
      nNodes=8
      nEdges=4
      nFaces=1
      nInt=4
    CASE (MD_MESH_ELEMENT_TET4)
      name='C3D4'
      dim=3
      topo=UF_TOPO_Tet
      nNodes=4
      nEdges=6
      nFaces=4
      nInt=1
    CASE (MD_MESH_ELEMENT_TET10)
      name='C3D10'
      dim=3
      topo=UF_TOPO_Tet
      nNodes=10
      nEdges=6
      nFaces=4
      nInt=4
    CASE (MD_MESH_ELEMENT_HEX8)
      name='C3D8'
      dim=3
      topo=UF_TOPO_Hex
      nNodes=8
      nEdges=12
      nFaces=6
      nInt=8
    CASE (MD_MESH_ELEMENT_HEX20)
      name='C3D20'
      dim=3
      topo=UF_TOPO_Hex
      nNodes=20
      nEdges=12
      nFaces=6
      nInt=27
    CASE (MD_MESH_ELEMENT_WEDGE6)
      name='C3D6'
      dim=3
      topo=UF_TOPO_Wedge
      nNodes=6
      nEdges=9
      nFaces=5
      nInt=6
    CASE (MD_MESH_ELEMENT_WEDGE15)
      name='C3D15'
      dim=3
      topo=UF_TOPO_Wedge
      nNodes=15
      nEdges=9
      nFaces=5
      nInt=9
    CASE (MD_MESH_ELEMENT_PYRAMID5)
      name='C3D5'
      dim=3
      topo=UF_TOPO_Pyramid
      nNodes=5
      nEdges=8
      nFaces=5
      nInt=5
    CASE (MD_MESH_ELEMENT_PYRAMID13)
      name='C3D13'
      dim=3
      topo=UF_TOPO_Pyramid
      nNodes=13
      nEdges=8
      nFaces=5
      nInt=8
    CASE DEFAULT
      name='UNKNOWN'
      dim=3
      topo=UF_TOPO_Unknown
      nNodes=0
      nEdges=0
      nFaces=0
      nInt=1
    END SELECT
    SELECT CASE (dim)
    CASE (1); dof_per_node = 1
    CASE (2); dof_per_node = 2
    CASE DEFAULT; dof_per_node = 3
    END SELECT
    CALL this%Init(elem_type_id=elemTypeId, name=name, n_nodes=nNodes, n_edges=nEdges, &
                   n_faces=nFaces, dim=dim, family=UF_FAMILY_CONTI, topo=topo, &
                   n_dof_per_node=dof_per_node, n_int_points=nInt, &
                   has_struct=.true., has_thermal=.false., has_pore=.false.)
  END SUBROUTINE UF_ElementType_FillById

  FUNCTION UF_ElementType_FromId(elemTypeId) RESULT(elem)
    INTEGER(i4), INTENT(IN) :: elemTypeId
    TYPE(ElemType) :: elem
    CALL UF_ElementType_FillById(elem, elemTypeId)
  END FUNCTION UF_ElementType_FromId

  !=============================================================================
  ! Structured Interface Types for Element Operations
  !=============================================================================
  
  !---------------------------------------------------------------------------
  ! Structured Interface: ElemType_Init
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: ElemType_Init_In
    TYPE(ElemType), POINTER :: elemType => null()
    INTEGER(i4) :: elem_type_id = 0_i4
    CHARACTER(len=64) :: name = ""
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_edges = 0_i4
    INTEGER(i4) :: n_faces = 0_i4
    INTEGER(i4) :: dim = 0_i4
    INTEGER(i4) :: family = 0_i4
    INTEGER(i4) :: topo = 0_i4
    INTEGER(i4) :: n_dof_per_node = 0_i4
    INTEGER(i4) :: n_int_points = 0_i4
    LOGICAL :: has_struct = .false.
    LOGICAL :: has_thermal = .false.
    LOGICAL :: has_pore = .false.
  END TYPE ElemType_Init_In

  TYPE, PUBLIC :: ElemType_Init_Out
    TYPE(ErrorStatusType) :: status
  END TYPE ElemType_Init_Out

  !=============================================================================
  ! STRUCTURED INTERFACE PROCEDURES
  !=============================================================================
  
  !> @brief Initialize element type (structured interface)
  SUBROUTINE ElemType_Init_Structured(in, out)
    TYPE(ElemType_Init_In), INTENT(IN) :: in
    TYPE(ElemType_Init_Out), INTENT(OUT) :: out
    
    CALL init_error_status(out%status)
    IF (.NOT. ASSOCIATED(in%elemType)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "ElemType pointer is null"
      RETURN
    END IF
    CALL in%elemType%Init(in%cfg%elem_type_id, in%name, in%pop%n_nodes, in%n_edges, in%n_faces, &
                          in%dim, in%family, in%topo, in%n_dof_per_node, in%n_int_points, &
                          in%has_struct, in%has_thermal, in%has_pore)
    out%status%status_code = IF_STATUS_OK
  END SUBROUTINE ElemType_Init_Structured
  
  PUBLIC :: ElemType_Init_Structured

  !---------------------------------------------------------------------------
  ! Init override (matches DescBase)
  !---------------------------------------------------------------------------
  SUBROUTINE ElemType_Init_Base(this)
    CLASS(ElemType), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    this%algo_type_name = 'DESC::ElemType'
  END SUBROUTINE ElemType_Init_Base

  !---------------------------------------------------------------------------
  ! LEGACY INTERFACE: ElemType_Init
  ! NOTE: This is a legacy interface. Use structured types ElemType_Init_In/Out instead.
  !---------------------------------------------------------------------------
  SUBROUTINE ElemType_Init(this, elem_type_id, name, n_nodes, n_edges, n_faces, dim, family, topo, &
      n_dof_per_node, n_int_points, has_struct, has_thermal, has_pore)
    CLASS(ElemType), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: elem_type_id, n_nodes, n_edges, n_faces, dim, family, topo
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_dof_per_node, n_int_points
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name
    LOGICAL, INTENT(IN), OPTIONAL :: has_struct, has_thermal, has_pore
    CALL this%Init()
    IF (PRESENT(elem_type_id)) this%cfg%elem_type_id = elem_type_id
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(n_nodes)) this%pop%n_nodes = n_nodes
    IF (PRESENT(n_edges)) this%n_edges = n_edges
    IF (PRESENT(n_faces)) this%n_faces = n_faces
    IF (PRESENT(dim)) this%dim = dim
    IF (PRESENT(family)) this%family = family
    IF (PRESENT(topo)) this%topo = topo
    IF (PRESENT(n_dof_per_node)) this%n_dof_per_node = n_dof_per_node
    IF (PRESENT(n_int_points)) this%n_int_points = n_int_points
    IF (PRESENT(has_struct)) this%has_struct = has_struct
    IF (PRESENT(has_thermal)) this%has_thermal = has_thermal
    IF (PRESENT(has_pore)) this%has_pore = has_pore
  END SUBROUTINE ElemType_Init

  SUBROUTINE ElemType_RegLayout(this)
    CLASS(ElemType), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(13)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'elem_type_id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'n_nodes'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'n_edges'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    fields(5)%field_name = 'n_faces'
    fields(5)%data_type = IF_DATA_TYPE_INT
    fields(5)%offset_bytes = offset
    offset = offset + 4
    fields(6)%field_name = 'dim'
    fields(6)%data_type = IF_DATA_TYPE_INT
    fields(6)%offset_bytes = offset
    offset = offset + 4
    fields(7)%field_name = 'family'
    fields(7)%data_type = IF_DATA_TYPE_INT
    fields(7)%offset_bytes = offset
    offset = offset + 4
    fields(8)%field_name = 'topo'
    fields(8)%data_type = IF_DATA_TYPE_INT
    fields(8)%offset_bytes = offset
    offset = offset + 4
    fields(9)%field_name = 'n_dof_per_node'
    fields(9)%data_type = IF_DATA_TYPE_INT
    fields(9)%offset_bytes = offset
    offset = offset + 4
    fields(10)%field_name = 'n_int_points'
    fields(10)%data_type = IF_DATA_TYPE_INT
    fields(10)%offset_bytes = offset
    offset = offset + 4
    fields(11)%field_name = 'has_struct'
    fields(11)%data_type = IF_DATA_TYPE_INT
    fields(11)%offset_bytes = offset
    offset = offset + 4
    fields(12)%field_name = 'has_thermal'
    fields(12)%data_type = IF_DATA_TYPE_INT
    fields(12)%offset_bytes = offset
    offset = offset + 4
    fields(13)%field_name = 'has_pore'
    fields(13)%data_type = IF_DATA_TYPE_INT
    fields(13)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 13, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ElemType_RegLayout")
  END SUBROUTINE ElemType_RegLayout

  SUBROUTINE ElemType_Ensure(this)
    CLASS(ElemType), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) this%varName = 'UF_ELEMENTTYPE'
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ElemType_Ensure")
  END SUBROUTINE ElemType_Ensure

  SUBROUTINE ElemFormul_Init_Base(this)
    CLASS(ElemFormul), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    this%algo_type_name = 'DESC::ElemFormul'
  END SUBROUTINE ElemFormul_Init_Base

  SUBROUTINE ElemFormul_Init(this, formulationType, order, numIntPoints, reducedintegrat, hourglasscontro)
    CLASS(ElemFormul), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: formulationType, order, numIntPoints
    LOGICAL, INTENT(IN), OPTIONAL :: reducedintegrat, hourglasscontro
    CALL this%Init()
    IF (PRESENT(formulationType)) this%formulationType = formulationType
    IF (PRESENT(order)) this%order = order
    IF (PRESENT(numIntPoints)) this%nIntPoints = numIntPoints
    IF (PRESENT(reducedintegrat)) this%reducedintegrat = reducedintegrat
    IF (PRESENT(hourglasscontro)) this%hourglasscontro = hourglasscontro
  END SUBROUTINE ElemFormul_Init

  SUBROUTINE ElemFormul_RegLayout(this)
    CLASS(ElemFormul), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(8)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'formulationType'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'order'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'nIntPoints'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'reducedintegrat'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    fields(5)%field_name = 'hourglasscontro'
    fields(5)%data_type = IF_DATA_TYPE_INT
    fields(5)%offset_bytes = offset
    offset = offset + 4
    fields(6)%field_name = 'kineFormulation'
    fields(6)%data_type = IF_DATA_TYPE_INT
    fields(6)%offset_bytes = offset
    offset = offset + 4
    fields(7)%field_name = 'integration_scheme'
    fields(7)%data_type = IF_DATA_TYPE_INT
    fields(7)%offset_bytes = offset
    offset = offset + 4
    fields(8)%field_name = 'use_bbar'
    fields(8)%data_type = IF_DATA_TYPE_INT
    fields(8)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 8, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ElemFormul_RegLayout")
  END SUBROUTINE ElemFormul_RegLayout

  SUBROUTINE ElemFormul_Ensure(this)
    CLASS(ElemFormul), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) this%varName = 'UF_ElemFormul'
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ElemFormul_Ensure")
  END SUBROUTINE ElemFormul_Ensure

  SUBROUTINE ElemCtx_Init(this, id, ElemType, numNodes, numIntPoints, currentTime, deltaTime)
    CLASS(ElemCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id, ElemType, numNodes, numIntPoints
    REAL(wp), INTENT(IN), OPTIONAL :: currentTime, deltaTime
    CALL this%CoreBase%Init('CTX::ELEMENT', CAT_CTX)
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(ElemType)) this%ElemType = ElemType
    IF (PRESENT(numNodes)) this%nNodes = numNodes
    IF (PRESENT(numIntPoints)) this%nIntPoints = numIntPoints
    IF (PRESENT(currentTime)) this%currentTime = currentTime
    IF (PRESENT(deltaTime)) this%deltaTime = deltaTime
  END SUBROUTINE ElemCtx_Init

  SUBROUTINE ElemCtx_RegLayout(this)
    CLASS(ElemCtx), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(6)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'; fields(1)%data_type = IF_DATA_TYPE_INT; fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'ElemType'; fields(2)%data_type = IF_DATA_TYPE_INT; fields(2)%offset_bytes = offset; offset = offset + 4
    fields(3)%field_name = 'nNodes'; fields(3)%data_type = IF_DATA_TYPE_INT; fields(3)%offset_bytes = offset; offset = offset + 4
    fields(4)%field_name = 'nIntPoints'; fields(4)%data_type = IF_DATA_TYPE_INT; fields(4)%offset_bytes = offset; offset = offset + 4
    fields(5)%field_name = 'currentTime'; fields(5)%data_type = IF_DATA_TYPE_DP; fields(5)%offset_bytes = offset; offset = offset + 8
    fields(6)%field_name = 'deltaTime'; fields(6)%data_type = IF_DATA_TYPE_DP; fields(6)%offset_bytes = offset; offset = offset + 8
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 6, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ElemCtx_RegLayout")
  END SUBROUTINE ElemCtx_RegLayout

  SUBROUTINE ElemCtx_Ensure(this)
    CLASS(ElemCtx), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_ELEMENTCTX_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "ElemCtx_Ensure")
  END SUBROUTINE ElemCtx_Ensure

  ! Note: IPState bound procedures (Init, RegLayout, Ensure) are defined in MD_Mesh_Elem_Types

  SUBROUTINE ElemState_RegLayout(this)
    CLASS(ElemState), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
  END SUBROUTINE ElemState_RegLayout

  SUBROUTINE ElemState_Ensure(this)
    CLASS(ElemState), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) this%varName = 'UF_ELEMENTSTATE'
  END SUBROUTINE ElemState_Ensure

  SUBROUTINE ElemState_Init(this, id_opt)
    CLASS(ElemState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id_opt
    this%category = CAT_STATE
    this%typeName = 'UF_ELEMENTSTATE'
    this%cfg%id = 0_i4
    IF (PRESENT(id_opt)) this%cfg%id = id_opt
    this%failed = .false.
    this%stableDt = 0.0_wp
    NULLIFY(this%evo%Ke, this%Re, this%Me, this%Ce)
    this%Ke_id = -1_i4
    this%Re_id = -1_i4
    this%Me_id = -1_i4
    this%Ce_id = -1_i4
  END SUBROUTINE ElemState_Init

  SUBROUTINE ShapeFuncResult_Init(this, numNodes, numIntPoints)
    CLASS(ShapeFuncResult), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: numNodes, numIntPoints
    IF (PRESENT(numNodes)) this%nNodes = numNodes
    IF (PRESENT(numIntPoints)) this%nIntPoints = numIntPoints
    IF (this%nNodes > 0 .AND. this%nIntPoints > 0) THEN
      ALLOCATE(this%N(this%nNodes, this%nIntPoints))
      ALLOCATE(this%dNdxi(3, this%nNodes, this%nIntPoints))
      ALLOCATE(this%dNdx(3, this%nNodes, this%nIntPoints))
      ALLOCATE(this%detJ(this%nIntPoints))
      ALLOCATE(this%weights(this%nIntPoints))
      this%N = 0.0_wp
      this%dNdxi = 0.0_wp
      this%dNdx = 0.0_wp
      this%detJ = 0.0_wp
      this%weights = 0.0_wp
    END IF
  END SUBROUTINE ShapeFuncResult_Init

  SUBROUTINE ShapeFuncResult_Clear(this)
    CLASS(ShapeFuncResult), INTENT(INOUT) :: this
    IF (ALLOCATED(this%N)) DEALLOCATE(this%N)
    IF (ALLOCATED(this%dNdxi)) DEALLOCATE(this%dNdxi)
    IF (ALLOCATED(this%dNdx)) DEALLOCATE(this%dNdx)
    IF (ALLOCATED(this%detJ)) DEALLOCATE(this%detJ)
    IF (ALLOCATED(this%weights)) DEALLOCATE(this%weights)
    this%nNodes = 0_i4
    this%nIntPoints = 0_i4
  END SUBROUTINE ShapeFuncResult_Clear

  SUBROUTINE UF_Elem_PrepareStructStorage(ElemType, ElemState, needMass, needDamp)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemState), INTENT(INOUT) :: ElemState
    LOGICAL, INTENT(IN), OPTIONAL :: needMass, needDamp
    INTEGER(i4) :: nDOF, pid
    LOGICAL :: useMass, useDamp
    TYPE(ErrorStatusType) :: mem_status
    nDOF = ElemType%pop%n_nodes * merge(ElemType%n_dof_per_node, 3_i4, ElemType%n_dof_per_node > 0_i4)
    IF (nDOF <= 0) RETURN
    useMass = .true.
    useDamp = .true.
    IF (PRESENT(needMass)) useMass = needMass
    IF (PRESENT(needDamp)) useDamp = needDamp
    IF (.NOT. ASSOCIATED(ElemState%evo%Ke)) THEN
      CALL UF_Mem_AllocReal2D(IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER, nDOF, nDOF, 'element_Ke', ElemState%evo%Ke, pid, mem_status)
      IF (mem_status%status_code == IF_STATUS_OK) ElemState%Ke_id = pid
      IF (mem_status%status_code /= 0) ALLOCATE(ElemState%evo%Ke(nDOF, nDOF))
    ELSE IF (SIZE(ElemState%evo%Ke,1) /= nDOF .OR. SIZE(ElemState%evo%Ke,2) /= nDOF) THEN
      IF (ElemState%Ke_id >= 0) CALL UF_Mem_FreeReal2D(ElemState%Ke_id, mem_status)
      IF (ASSOCIATED(ElemState%evo%Ke)) DEALLOCATE(ElemState%evo%Ke)
      ElemState%Ke_id = -1_i4
      CALL UF_Mem_AllocReal2D(IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER, nDOF, nDOF, 'element_Ke', ElemState%evo%Ke, pid, mem_status)
      IF (mem_status%status_code == IF_STATUS_OK) ElemState%Ke_id = pid
      IF (mem_status%status_code /= 0) ALLOCATE(ElemState%evo%Ke(nDOF, nDOF))
    END IF
    IF (.NOT. ASSOCIATED(ElemState%Re)) THEN
      CALL UF_Mem_AllocReal1D(IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER, nDOF, 'element_Re', ElemState%Re, pid, mem_status)
      IF (mem_status%status_code == IF_STATUS_OK) ElemState%Re_id = pid
      IF (mem_status%status_code /= 0) ALLOCATE(ElemState%Re(nDOF))
    ELSE IF (SIZE(ElemState%Re) /= nDOF) THEN
      IF (ElemState%Re_id >= 0) THEN
        CALL UF_Mem_FreeReal1D(ElemState%Re_id, mem_status)
        NULLIFY(ElemState%Re)
      ELSE IF (ASSOCIATED(ElemState%Re)) THEN
        DEALLOCATE(ElemState%Re)
      END IF
      ElemState%Re_id = -1_i4
      CALL UF_Mem_AllocReal1D(IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER, nDOF, 'element_Re', ElemState%Re, pid, mem_status)
      IF (mem_status%status_code == IF_STATUS_OK) ElemState%Re_id = pid
      IF (mem_status%status_code /= 0) ALLOCATE(ElemState%Re(nDOF))
    END IF
    IF (useMass) THEN
      IF (.NOT. ASSOCIATED(ElemState%Me)) THEN
        CALL UF_Mem_AllocReal2D(IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER, nDOF, nDOF, 'element_Me', ElemState%Me, pid, mem_status)
        IF (mem_status%status_code == IF_STATUS_OK) ElemState%Me_id = pid
        IF (mem_status%status_code /= 0) ALLOCATE(ElemState%Me(nDOF, nDOF))
      ELSE IF (SIZE(ElemState%Me,1) /= nDOF .OR. SIZE(ElemState%Me,2) /= nDOF) THEN
        IF (ElemState%Me_id >= 0) CALL UF_Mem_FreeReal2D(ElemState%Me_id, mem_status)
        IF (ASSOCIATED(ElemState%Me)) DEALLOCATE(ElemState%Me)
        ElemState%Me_id = -1_i4
        CALL UF_Mem_AllocReal2D(IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER, nDOF, nDOF, 'element_Me', ElemState%Me, pid, mem_status)
        IF (mem_status%status_code == IF_STATUS_OK) ElemState%Me_id = pid
        IF (mem_status%status_code /= 0) ALLOCATE(ElemState%Me(nDOF, nDOF))
      END IF
    END IF
    IF (useDamp) THEN
      IF (.NOT. ASSOCIATED(ElemState%Ce)) THEN
        CALL UF_Mem_AllocReal2D(IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER, nDOF, nDOF, 'element_Ce', ElemState%Ce, pid, mem_status)
        IF (mem_status%status_code == IF_STATUS_OK) ElemState%Ce_id = pid
        IF (mem_status%status_code /= 0) ALLOCATE(ElemState%Ce(nDOF, nDOF))
      ELSE IF (SIZE(ElemState%Ce,1) /= nDOF .OR. SIZE(ElemState%Ce,2) /= nDOF) THEN
        IF (ElemState%Ce_id >= 0) THEN
          CALL UF_Mem_FreeReal2D(ElemState%Ce_id, mem_status)
          NULLIFY(ElemState%Ce)
        ELSE IF (ASSOCIATED(ElemState%Ce)) THEN
          DEALLOCATE(ElemState%Ce)
        END IF
        ElemState%Ce_id = -1_i4
        CALL UF_Mem_AllocReal2D(IF_MEM_DOMAIN_ELEM, IF_MEM_DOMAIN_LAYER, nDOF, nDOF, 'element_Ce', ElemState%Ce, pid, mem_status)
        IF (mem_status%status_code == IF_STATUS_OK) ElemState%Ce_id = pid
        IF (mem_status%status_code /= 0) ALLOCATE(ElemState%Ce(nDOF, nDOF))
      END IF
    END IF
  END SUBROUTINE UF_Elem_PrepareStructStorage

  SUBROUTINE UF_El_PrepareIntPointStates(ElemType, ElemState, nInt_opt)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemState), INTENT(INOUT) :: ElemState
    INTEGER(i4), INTENT(IN), OPTIONAL :: nInt_opt
    INTEGER(i4) :: nInt, i
    nInt = ElemType%n_int_points
    IF (PRESENT(nInt_opt)) nInt = nInt_opt
    IF (nInt <= 0_i4) nInt = 1_i4
    IF (.NOT. ALLOCATED(ElemState%ipStates)) THEN
      ALLOCATE(ElemState%ipStates(nInt))
    ELSE IF (SIZE(ElemState%ipStates) /= nInt) THEN
      DEALLOCATE(ElemState%ipStates)
      ALLOCATE(ElemState%ipStates(nInt))
    END IF
    DO i = 1, nInt
      ElemState%ipStates(i)%ipId = i
      ElemState%ipStates(i)%cfg%id = i
    END DO
  END SUBROUTINE UF_Element_PrepareIntPointStates

  !=============================================================================
  ! ElementMetadata_Init
  !=============================================================================
  subroutine ElementMetadata_Init(this, element_type, family, name, description, &
                                nNodes, nIps, nDofs, spatial_dim, &
                                supports_2d, supports_3d, supports_nlgeom, &
                                supports_materi, status)
    class(ElementMetadata), intent(inout) :: this
    integer(i4),               intent(in)    :: element_type
    integer(i4),               intent(in)    :: family
    character(len=*),          intent(in)    :: name
    character(len=*),          intent(in)    :: description
    integer(i4),               intent(in)    :: nNodes
    integer(i4),               intent(in)    :: nIps
    integer(i4),               intent(in)    :: nDofs
    integer(i4),               intent(in)    :: spatial_dim
    logical,                   intent(in)    :: supports_2d
    logical,                   intent(in)    :: supports_3d
    logical,                   intent(in)    :: supports_nlgeom
    logical,                   intent(in)    :: supports_materi
    type(ErrorStatusType),     intent(out)   :: status

    call init_error_status(status)

    this%element_type = element_type
    this%family = family
    this%name = trim(name)
    this%cfg%description = trim(description)
    this%nNodes = nNodes
    this%nIps = nIps
    this%nDofs = nDofs
    this%spatial_dim = spatial_dim
    this%supports_2d = supports_2d
    this%supports_3d = supports_3d
    this%supports_nlgeom = supports_nlgeom
    this%supports_materi = supports_materi
    this%available = .true.

    status%status_code = IF_STATUS_OK
  end subroutine ElementMetadata_Init

  !=============================================================================
  ! Element_FromDesc_Metadata (from MD_Elem_API, merged Phase 2)
  ! Converts Desc_Element to ElementMetadata.
  !=============================================================================
  subroutine Element_FromDesc_Metadata(desc_element, md_metadata, status)
    type(Desc_Element), intent(in) :: desc_element
    type(ElementMetadata), intent(inout) :: md_metadata
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    md_metadata%element_type = desc_element%element_type
    md_metadata%name = trim(desc_element%element_type_na)
    md_metadata%nNodes = desc_element%nNodes
    md_metadata%nIps = desc_element%nIntPoints
    md_metadata%spatial_dim = 3_i4

    select case (desc_element%element_type)
      case (1, 2)
        md_metadata%family = 1_i4
      case (3, 4)
        md_metadata%family = 3_i4
      case (5, 6, 7)
        md_metadata%family = 4_i4
      case (8, 9)
        md_metadata%family = 6_i4
      case default
        md_metadata%family = 1_i4
    end select

    status%status_code = IF_STATUS_OK
  end subroutine Element_FromDesc_Metadata

  !=============================================================================
  ! ElementMetadata_Destroy
  !=============================================================================
  subroutine ElementMetadata_Clean(this)
    class(ElementMetadata), intent(inout) :: this

    this%element_type = 0_i4
    this%family = MD_MESH_ELEMENT_FAMILY
    this%name = ""
    this%cfg%description = ""
    this%nNodes = 0_i4
    this%nIps = 0_i4
    this%nDofs = 0_i4
    this%spatial_dim = 0_i4
    this%supports_2d = .true.
    this%supports_3d = .true.
    this%supports_nlgeom = .true.
    this%supports_materi = .true.
    this%available = .false.
  end subroutine ElementMetadata_Clean

  !=============================================================================
  ! ElementMetadata_Valid
  !=============================================================================
  subroutine ElementMetadata_Valid(this, status)
    class(ElementMetadata), intent(in)  :: this
    type(ErrorStatusType),     intent(out) :: status

    call init_error_status(status)

    if (this%element_type <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid Element type"
      return
    end if

    if (this%nNodes <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of nodes"
      return
    end if

    if (this%nIps <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of integration points"
      return
    end if

    if (this%nDofs <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of DOFs"
      return
    end if

    if (this%spatial_dim <= 0) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid spatial dimension"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine ElementMetadata_Valid

  !=============================================================================
  ! ElementMetadata_GetFamilyName
  !=============================================================================
  function ElementMetadata_GetFamilyName(this) result(name)
    class(ElementMetadata), intent(in) :: this
    character(len=80) :: name

    select case(this%family)
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Continuum"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Structural"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Solid"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Shell"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Membrane"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Beam"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Truss"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Spring"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "Dashpot"
      case(MD_MESH_ELEMENT_FAMILY)
        name = "User-Defined"
      case default
        name = "Unknown"
    end select
  end function ElementMetadata_GetFamilyName

  !=============================================================================
  ! ElementCatalog_Init
  !=============================================================================
  subroutine ElementCatalog_Init(this, max_elements, status)
    class(ElementCatalog), intent(inout) :: this
    integer(i4),             intent(in), optional :: max_elements
    type(ErrorStatusType),   intent(out)   :: status

    call init_error_status(status)

    if (this%init) then
      status%status_code = IF_STATUS_OK
      return
    end if

    if (present(max_elements)) then
      this%max_elements = max_elements
    end if

    allocate(this%elements(this%max_elements))
    this%elements(:)%available = .false.
    this%nElems = 0_i4
    this%init = .true.

    status%status_code = IF_STATUS_OK
  end subroutine ElementCatalog_Init

  !=============================================================================
  ! ElementCatalog_Destroy
  !=============================================================================
  subroutine ElementCatalog_Clean(this)
    class(ElementCatalog), intent(inout) :: this

    if (allocated(this%elements)) then
      deallocate(this%elements)
    end if

    this%nElems = 0_i4
    this%init = .false.
  end subroutine ElementCatalog_Clean

  !=============================================================================
  ! ElementCatalog_RegElement
  !=============================================================================
  subroutine ElementCatalog_RegElement(this, element_type, family, name, description, &
                                          nNodes, nIps, nDofs, spatial_dim, &
                                          supports_2d, supports_3d, supports_nlgeom, &
                                          supports_materi, status)
    class(ElementCatalog),  intent(inout) :: this
    integer(i4),                intent(in)    :: element_type
    integer(i4),                intent(in)    :: family
    character(len=*),           intent(in)    :: name
    character(len=*),           intent(in)    :: description
    integer(i4),                intent(in)    :: nNodes
    integer(i4),                intent(in)    :: nIps
    integer(i4),                intent(in)    :: nDofs
    integer(i4),                intent(in)    :: spatial_dim
    logical,                    intent(in)    :: supports_2d
    logical,                    intent(in)    :: supports_3d
    logical,                    intent(in)    :: supports_nlgeom
    logical,                    intent(in)    :: supports_materi
    type(ErrorStatusType),      intent(out)   :: status

    integer(i4) :: idx

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementCatalog not initialized"
      return
    end if

    if (this%nElems >= this%max_elements) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementCatalog full"
      return
    end if

    idx = this%nElems + 1

    call this%elements(idx)%Init(element_type, family, name, description, &
                               nNodes, nIps, nDofs, spatial_dim, &
                               supports_2d, supports_3d, supports_nlgeom, &
                               supports_materi, status)
    if (status%status_code /= IF_STATUS_OK) return

    this%nElems = this%nElems + 1_i4
    status%status_code = IF_STATUS_OK
  end subroutine ElementCatalog_RegElement

  !=============================================================================
  ! ElementCatalog_GetElement
  !=============================================================================
  subroutine ElementCatalog_GetElement(this, element_type, metadata, status)
    class(ElementCatalog),  intent(in)    :: this
    integer(i4),               intent(in)    :: element_type
    type(ElementMetadata),  intent(out)   :: metadata
    type(ErrorStatusType),     intent(out)   :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementCatalog not initialized"
      return
    end if

    do i = 1, this%nElems
      if (this%elements(i)%element_type == element_type .and. this%elements(i)%available) then
        metadata = this%elements(i)
        status%status_code = IF_STATUS_OK
        return
      end if
    end do

    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "Element type not found in catalog"
  end subroutine ElementCatalog_GetElement

  !=============================================================================
  ! ElementCatalog_FindElement
  !=============================================================================
  subroutine ElementCatalog_FindElement(this, name, element_type, status)
    class(ElementCatalog),  intent(in)    :: this
    character(len=*),          intent(in)    :: name
    integer(i4),               intent(out)   :: element_type
    type(ErrorStatusType),     intent(out)   :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementCatalog not initialized"
      element_type = 0_i4
      return
    end if

    do i = 1, this%nElems
      if (trim(this%elements(i)%name) == trim(name) .and. this%elements(i)%available) then
        element_type = this%elements(i)%element_type
        status%status_code = IF_STATUS_OK
        return
      end if
    end do

    element_type = 0_i4
    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "Element name not found in catalog"
  end subroutine ElementCatalog_FindElement

  !=============================================================================
  ! ElementCatalog_ListElements
  !=============================================================================
  subroutine ElementCatalog_ListElements(this, element_types, element_names, nFound, status)
    class(ElementCatalog),  intent(in)    :: this
    integer(i4),               intent(out)   :: element_types(:)
    character(len=*),          intent(out)   :: element_names(:)
    integer(i4),               intent(out)   :: nFound
    type(ErrorStatusType),     intent(out)   :: status

    integer(i4) :: i, max_output

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementCatalog not initialized"
      nFound = 0_i4
      return
    end if

    max_output = min(size(element_types), size(element_names))
    nFound = 0_i4

    do i = 1, this%nElems
      if (this%elements(i)%available) then
        nFound = nFound + 1_i4
        if (nFound <= max_output) then
          element_types(nFound) = this%elements(i)%element_type
          element_names(nFound) = trim(this%elements(i)%name)
        end if
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ElementCatalog_ListElements

  !=============================================================================
  ! ElementCatalog_GetElementsByFamily
  !=============================================================================
  subroutine El_GetElementsByFamily(this, family, element_types, element_names, nFound, status)
    class(ElementCatalog),  intent(in)    :: this
    integer(i4),               intent(in)    :: family
    integer(i4),               intent(out)   :: element_types(:)
    character(len=*),          intent(out)   :: element_names(:)
    integer(i4),               intent(out)   :: nFound
    type(ErrorStatusType),     intent(out)   :: status

    integer(i4) :: i, max_output

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementCatalog not initialized"
      nFound = 0_i4
      return
    end if

    max_output = min(size(element_types), size(element_names))
    nFound = 0_i4

    do i = 1, this%nElems
      if (this%elements(i)%available .and. this%elements(i)%family == family) then
        nFound = nFound + 1_i4
        if (nFound <= max_output) then
          element_types(nFound) = this%elements(i)%element_type
          element_names(nFound) = trim(this%elements(i)%name)
        end if
      end if
    end do

    status%status_code = IF_STATUS_OK
  end subroutine ElementCatalog_GetElementsByFamily

  !=============================================================================
  ! ElementCatalog_InitializeDefaults
  !=============================================================================
  subroutine ElementCatalog_InitDefaults(this, status)
    class(ElementCatalog),  intent(inout) :: this
    type(ErrorStatusType),     intent(out)   :: status

    call init_error_status(status)

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPE4", description="4-node plane strain quadrilateral", &
                               nNodes=4, nIps=4, nDofs=8, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPE8", description="8-node plane strain quadrilateral", &
                               nNodes=8, nIps=9, nDofs=16, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D8", description="8-node brick Element", &
                               nNodes=8, nIps=8, nDofs=24, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D20", description="20-node brick Element", &
                               nNodes=20, nIps=27, nDofs=60, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    ! ========================================================================
    ! Porous Elements (Structure-Pore Pressure Coupled) - 3D
    ! ========================================================================
    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D4P", description="4-node tetrahedron with pore pressure", &
                               nNodes=4, nIps=1, nDofs=16, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D6P", description="6-node wedge with pore pressure", &
                               nNodes=6, nIps=2, nDofs=24, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D8P", description="8-node hexahedron with pore pressure", &
                               nNodes=8, nIps=8, nDofs=32, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D10P", description="10-node tetrahedron with pore pressure", &
                               nNodes=10, nIps=4, nDofs=40, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D15P", description="15-node wedge with pore pressure", &
                               nNodes=15, nIps=6, nDofs=60, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D20P", description="20-node hexahedron with pore pressure", &
                               nNodes=20, nIps=27, nDofs=80, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_C3, family=MD_MESH_ELEMENT_FAMILY, &
                               name="C3D27P", description="27-node hexahedron with pore pressure", &
                               nNodes=27, nIps=27, nDofs=108, spatial_dim=3, &
                               supports_2d=.false., supports_3d=.true., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    ! ========================================================================
    ! Porous Elements (Structure-Pore Pressure Coupled) - 2D Plane Strain
    ! ========================================================================
    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPE3P", description="3-node triangle plane strain with pore pressure", &
                               nNodes=3, nIps=1, nDofs=9, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPE4P", description="4-node quadrilateral plane strain with pore pressure", &
                               nNodes=4, nIps=4, nDofs=12, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPE6P", description="6-node triangle plane strain with pore pressure", &
                               nNodes=6, nIps=3, nDofs=18, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPE8P", description="8-node quadrilateral plane strain with pore pressure", &
                               nNodes=8, nIps=9, nDofs=24, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    ! ========================================================================
    ! Porous Elements (Structure-Pore Pressure Coupled) - 2D Plane Stress
    ! ========================================================================
    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPS3P", description="3-node triangle plane stress with pore pressure", &
                               nNodes=3, nIps=1, nDofs=9, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPS4P", description="4-node quadrilateral plane stress with pore pressure", &
                               nNodes=4, nIps=4, nDofs=12, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPS6P", description="6-node triangle plane stress with pore pressure", &
                               nNodes=6, nIps=3, nDofs=18, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CPS8P", description="8-node quadrilateral plane stress with pore pressure", &
                               nNodes=8, nIps=9, nDofs=24, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    ! ========================================================================
    ! Porous Elements (Structure-Pore Pressure Coupled) - Axisymmetric
    ! ========================================================================
    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CAX3P", description="3-node triangle axisymmetric with pore pressure", &
                               nNodes=3, nIps=1, nDofs=9, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CAX4P", description="4-node quadrilateral axisymmetric with pore pressure", &
                               nNodes=4, nIps=4, nDofs=12, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CAX6P", description="6-node triangle axisymmetric with pore pressure", &
                               nNodes=6, nIps=3, nDofs=18, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%RegisterElement(element_type=MD_MESH_ELEMENT_TYPE_CP, family=MD_MESH_ELEMENT_FAMILY, &
                               name="CAX8P", description="8-node quadrilateral axisymmetric with pore pressure", &
                               nNodes=8, nIps=9, nDofs=24, spatial_dim=2, &
                               supports_2d=.true., supports_3d=.false., &
                               supports_nlgeom=.true., supports_materi=.true., status=status)
    if (status%status_code /= IF_STATUS_OK) return

    status%status_code = IF_STATUS_OK
  end subroutine ElementCatalog_InitDefaults

  !=============================================================================
  ! ElementDispatcher_Init
  !=============================================================================
  subroutine ElementDispatcher_Init(this, status)
    class(ElementDispatcher), intent(inout) :: this
    type(ErrorStatusType),   intent(out)   :: status

    call init_error_status(status)

    if (this%init) then
      status%status_code = IF_STATUS_OK
      return
    end if

    call this%catalog%Init(status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%catalog%InitDefaults(status=status)
    if (status%status_code /= IF_STATUS_OK) return

    this%init = .true.
    status%status_code = IF_STATUS_OK
  end subroutine ElementDispatcher_Init

  !=============================================================================
  ! ElementDispatcher_Destroy
  !=============================================================================
  subroutine ElementDispatcher_Clean(this)
    class(ElementDispatcher), intent(inout) :: this

    call this%catalog%Clean()
    this%init = .false.
  end subroutine ElementDispatcher_Clean

  !=============================================================================
  ! ElementDispatcher_Dispatch
  !=============================================================================
  subroutine ElementDispatcher_Dispatch(this, element_type, status)
    class(ElementDispatcher), intent(in)  :: this
    integer(i4),             intent(in)    :: element_type
    type(ErrorStatusType),   intent(out)   :: status

    type(ElementMetadata) :: metadata

    call init_error_status(status)

    call this%GetElementInfo(element_type, metadata, status)
    if (status%status_code /= IF_STATUS_OK) return

    status%status_code = IF_STATUS_OK
  end subroutine ElementDispatcher_Dispatch

  !=============================================================================
  ! ElementDispatcher_GetElementInfo
  !=============================================================================
  subroutine El_GetElementInfo(this, element_type, metadata, status)
    class(ElementDispatcher), intent(in)  :: this
    integer(i4),             intent(in)    :: element_type
    type(ElementMetadata),  intent(out) :: metadata
    type(ErrorStatusType),   intent(out) :: status

    call this%catalog%GetElement(element_type, metadata, status)
  end subroutine ElementDispatcher_GetElementInfo

  !=============================================================================
  ! ElementDispatcher_ValidElement
  !=============================================================================
  subroutine El_ValidElement(this, element_type, status)
    class(ElementDispatcher), intent(in)  :: this
    integer(i4),             intent(in)    :: element_type
    type(ErrorStatusType),   intent(out)   :: status

    type(ElementMetadata) :: metadata

    call this%GetElementInfo(element_type, metadata, status)
    if (status%status_code /= IF_STATUS_OK) return

    call metadata%Valid(status)
  end subroutine ElementDispatcher_ValidElement

  !=============================================================================
  ! ElementAdapter_Init
  !=============================================================================
  subroutine ElementAdapter_Init(this, element_type, adapter_type, status)
    class(ElementAdapter),   intent(inout) :: this
    integer(i4),             intent(in)    :: element_type
    integer(i4),             intent(in)    :: adapter_type
    type(ErrorStatusType),   intent(out)   :: status

    call init_error_status(status)

    this%element_type = element_type
    this%adapter_type = adapter_type
    this%init = .true.

    status%status_code = IF_STATUS_OK
  end subroutine ElementAdapter_Init

  !=============================================================================
  ! ElementAdapter_Destroy
  !=============================================================================
  subroutine ElementAdapter_Clean(this)
    class(ElementAdapter), intent(inout) :: this

    this%element_type = 0_i4
    this%adapter_type = 0_i4
    this%init = .false.
  end subroutine ElementAdapter_Clean

  !=============================================================================
  ! ElementAdapter_Adapt
  !=============================================================================
  subroutine ElementAdapter_Adapt(this, status)
    class(ElementAdapter),   intent(inout) :: this
    type(ErrorStatusType),   intent(out)   :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine ElementAdapter_Adapt

  !=============================================================================
  ! ElementAdapter_Valid
  !=============================================================================
  subroutine ElementAdapter_Valid(this, status)
    class(ElementAdapter),   intent(in)  :: this
    type(ErrorStatusType),   intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementAdapter not initialized"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine ElementAdapter_Valid

  !=============================================================================
  ! UserElement_Init
  !=============================================================================
  subroutine UserElement_Init(this, element_type, name, source_file, compiled_lib, status)
    class(UserElement),     intent(inout) :: this
    integer(i4),             intent(in)    :: element_type
    character(len=*),        intent(in)    :: name
    character(len=*),        intent(in)    :: source_file
    character(len=*),        intent(in)    :: compiled_lib
    type(ErrorStatusType),   intent(out)   :: status

    call init_error_status(status)

    this%element_type = element_type
    this%name = trim(name)
    this%source_file = trim(source_file)
    this%compiled_lib = trim(compiled_lib)
    this%loaded = .false.
    this%validated = .false.

    status%status_code = IF_STATUS_OK
  end subroutine UserElement_Init

  !=============================================================================
  ! UserElement_Destroy
  !=============================================================================
  subroutine UserElement_Clean(this)
    class(UserElement),     intent(inout) :: this

    this%element_type = 0_i4
    this%name = ""
    this%source_file = ""
    this%compiled_lib = ""
    this%loaded = .false.
    this%validated = .false.
  end subroutine UserElement_Clean

  !=============================================================================
  ! UserElement_Load
  !=============================================================================
  subroutine UserElement_Load(this, status)
    class(UserElement),   intent(inout) :: this
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    this%loaded = .true.
    status%status_code = IF_STATUS_OK
  end subroutine UserElement_Load

  !=============================================================================
  ! UserElement_Valid
  !=============================================================================
  subroutine UserElement_Valid(this, status)
    class(UserElement),   intent(in)  :: this
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    if (.not. this%loaded) then
      status%status_code = IF_STATUS_INVALID
      status%message = "User Element not loaded"
      return
    end if

    this%validated = .true.
    status%status_code = IF_STATUS_OK
  end subroutine UserElement_Valid

  !=============================================================================
  ! UserElement_GetMetadata
  !=============================================================================
  subroutine UserElement_GetMetadata(this, metadata)
    class(UserElement),   intent(in)  :: this
    type(ElementMetadata), intent(out) :: metadata

    metadata = this%metadata
  end subroutine UserElement_GetMetadata

  !=============================================================================
  ! ElementManager_Init
  !=============================================================================
  subroutine ElementManager_Init(this, max_elements, max_user_elemen, status)
    class(ElementManager),  intent(inout) :: this
    integer(i4),           intent(in), optional :: max_elements
    integer(i4),           intent(in), optional :: max_user_elemen
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    if (this%init) then
      status%status_code = IF_STATUS_OK
      return
    end if

    call this%catalog%Init(max_elements, status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%catalog%InitDefaults(status=status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%dispatcher%Init(status=status)
    if (status%status_code /= IF_STATUS_OK) return

    if (present(max_user_elemen)) then
      this%max_user_elemen = max_user_elemen
    end if

    allocate(this%user_elements(this%max_user_elemen))
    this%num_user_elements = 0_i4

    this%init = .true.
    status%status_code = IF_STATUS_OK
  end subroutine ElementManager_Init

  !=============================================================================
  ! ElementManager_Destroy
  !=============================================================================
  subroutine ElementManager_Clean(this)
    class(ElementManager), intent(inout) :: this

    integer(i4) :: i

    call this%catalog%Clean()
    call this%dispatcher%Clean()

    do i = 1, this%num_user_elements
      call this%user_elements(i)%Clean()
    end do

    if (allocated(this%user_elements)) then
      deallocate(this%user_elements)
    end if

    this%num_user_elements = 0_i4
    this%init = .false.
  end subroutine ElementManager_Clean

  !=============================================================================
  ! ElementMgr_RegElement
  !=============================================================================
  subroutine ElementMgr_RegElement(this, element_type, family, name, description, &
                                         nNodes, nIps, nDofs, spatial_dim, &
                                         supports_2d, supports_3d, supports_nlgeom, &
                                         supports_materi, status)
    class(ElementManager),  intent(inout) :: this
    integer(i4),                intent(in)    :: element_type
    integer(i4),                intent(in)    :: family
    character(len=*),           intent(in)    :: name
    character(len=*),           intent(in)    :: description
    integer(i4),                intent(in)    :: nNodes
    integer(i4),                intent(in)    :: nIps
    integer(i4),                intent(in)    :: nDofs
    integer(i4),                intent(in)    :: spatial_dim
    logical,                    intent(in)    :: supports_2d
    logical,                    intent(in)    :: supports_3d
    logical,                    intent(in)    :: supports_nlgeom
    logical,                    intent(in)    :: supports_materi
    type(ErrorStatusType),      intent(out)   :: status

    call this%catalog%RegisterElement(element_type, family, name, description, &
                                    nNodes, nIps, nDofs, spatial_dim, &
                                    supports_2d, supports_3d, supports_nlgeom, &
                                    supports_materi, status)
  end subroutine ElementMgr_RegElement

  !=============================================================================
  ! ElementMgr_RegUserElement
  !=============================================================================
  subroutine ElementMgr_RegUserElement(this, element_type, name, source_file, compiled_lib, status)
    class(ElementManager),  intent(inout) :: this
    integer(i4),                intent(in)    :: element_type
    character(len=*),           intent(in)    :: name
    character(len=*),           intent(in)    :: source_file
    character(len=*),           intent(in)    :: compiled_lib
    type(ErrorStatusType),      intent(out)   :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementManager not initialized"
      return
    end if

    if (this%num_user_elements >= this%max_user_elemen) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementManager user elements full"
      return
    end if

    this%num_user_elements = this%num_user_elements + 1_i4

    call this%user_elements(this%num_user_elements)%Init(element_type, name, source_file, compiled_lib, status)
    if (status%status_code /= IF_STATUS_OK) return

    status%status_code = IF_STATUS_OK
  end subroutine ElementMgr_RegUserElement

  !=============================================================================
  ! ElementMgr_GetElementInfo
  !=============================================================================
  subroutine ElementMgr_GetElementInfo(this, element_type, metadata, status)
    class(ElementManager),  intent(in)    :: this
    integer(i4),               intent(in)    :: element_type
    type(ElementMetadata),  intent(out)   :: metadata
    type(ErrorStatusType),     intent(out)   :: status

    call this%dispatcher%GetElementInfo(element_type, metadata, status)
  end subroutine ElementMgr_GetElementInfo

  !=============================================================================
  ! ElementManager_ListElements
  !=============================================================================
  subroutine ElementManager_ListElements(this, element_types, element_names, nFound, status)
    class(ElementManager),  intent(in)    :: this
    integer(i4),               intent(out)   :: element_types(:)
    character(len=*),          intent(out)   :: element_names(:)
    integer(i4),               intent(out)   :: nFound
    type(ErrorStatusType),     intent(out)   :: status

    call this%catalog%ListElements(element_types, element_names, nFound, status)
  end subroutine ElementManager_ListElements

  !=============================================================================
  ! ElementManager_Dispatch
  !=============================================================================
  subroutine ElementManager_Dispatch(this, element_type, status)
    class(ElementManager),  intent(in)    :: this
    integer(i4),             intent(in)    :: element_type
    type(ErrorStatusType),   intent(out)   :: status

    call this%dispatcher%Dispatch(element_type, status)
  end subroutine ElementManager_Dispatch

  !=============================================================================
  ! ElementManager_Valid
  !=============================================================================
  subroutine ElementManager_Valid(this, status)
    class(ElementManager),  intent(in)  :: this
    type(ErrorStatusType),   intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "ElementManager not initialized"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine ElementManager_Valid

  !=============================================================================
  ! Element Catalog Connectivity Query
  !=============================================================================
  subroutine UF_El_GetConnectivity(elemName, dim, nFace, nEdge, face_nodes, edge_nodes, ierr)
    character(len=*), intent(in)  :: elemName
    integer(i4),      intent(out) :: dim
    integer(i4),      intent(out) :: nFace, nEdge
    integer(i4),      intent(out) :: face_nodes(:,:)
    integer(i4),      intent(out) :: edge_nodes(:,:)
    integer(i4),      intent(out) :: ierr

    character(len=:), allocatable :: name

    ierr      = 0_i4
    dim       = 0_i4
    nFace     = 0_i4
    nEdge     = 0_i4
    face_nodes = 0_i4
    edge_nodes = 0_i4

    name = trim(elemName)

    select case (name)

    case ('C3D4')
      dim   = 3_i4
      nFace = 4_i4
      nEdge = 6_i4
      face_nodes(1:4,1:3) = reshape([ &
        1_i4, 2_i4, 3_i4, &
        1_i4, 2_i4, 4_i4, &
        2_i4, 3_i4, 4_i4, &
        1_i4, 3_i4, 4_i4 ], [4,3])
      edge_nodes(1:6,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 1_i4, &
        1_i4, 4_i4, &
        2_i4, 4_i4, &
        3_i4, 4_i4 ], [6,2])

    case ('C3D10', 'C3D10M')
      dim   = 3_i4
      nFace = 4_i4
      nEdge = 6_i4
      face_nodes(1:4,1:6) = reshape([ &
        1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4, &
        1_i4, 2_i4, 4_i4, 7_i4, 8_i4, 9_i4, &
        2_i4, 3_i4, 4_i4, 5_i4, 9_i4, 10_i4, &
        1_i4, 3_i4, 4_i4, 6_i4, 8_i4, 10_i4 ], [4,6])
      edge_nodes(1:6,1:3) = reshape([ &
        1_i4, 2_i4, 5_i4, &
        2_i4, 3_i4, 6_i4, &
        3_i4, 1_i4, 4_i4, &
        1_i4, 4_i4, 8_i4, &
        2_i4, 4_i4, 9_i4, &
        3_i4, 4_i4, 10_i4 ], [6,3])

    case ('C3D8', 'C3D8R', 'C3D8I', 'C3D8H', 'C3D8T', 'P3D8SAT', 'P3D8RCH')
      dim   = 3_i4
      nFace = 6_i4
      nEdge = 12_i4
      face_nodes(1:6,1:4) = reshape([ &
        1_i4, 2_i4, 3_i4, 4_i4, &
        5_i4, 6_i4, 7_i4, 8_i4, &
        1_i4, 2_i4, 6_i4, 5_i4, &
        2_i4, 3_i4, 7_i4, 6_i4, &
        3_i4, 4_i4, 8_i4, 7_i4, &
        4_i4, 1_i4, 5_i4, 8_i4  ], [6,4])
      edge_nodes(1:12,1:2) = reshape([ &
        1_i4, 2_i4, & 2_i4, 3_i4, & 3_i4, 4_i4, & 4_i4, 1_i4, &
        5_i4, 6_i4, & 6_i4, 7_i4, & 7_i4, 8_i4, & 8_i4, 5_i4, &
        1_i4, 5_i4, & 2_i4, 6_i4, & 3_i4, 7_i4, & 4_i4, 8_i4 ], [12,2])

    case ('C3D20', 'C3D20R', 'C3D20H', 'C3D20T')
      dim   = 3_i4
      nFace = 6_i4
      nEdge = 12_i4
      face_nodes(1:6,1:8) = reshape([ &
        1_i4, 2_i4, 3_i4, 4_i4, 9_i4, 10_i4, 11_i4, 12_i4, &
        5_i4, 6_i4, 7_i4, 8_i4, 13_i4, 14_i4, 15_i4, 16_i4, &
        1_i4, 2_i4, 6_i4, 5_i4, 9_i4, 18_i4, 13_i4, 17_i4, &
        2_i4, 3_i4, 7_i4, 6_i4, 10_i4, 19_i4, 14_i4, 18_i4, &
        3_i4, 4_i4, 8_i4, 7_i4, 11_i4, 20_i4, 15_i4, 19_i4, &
        4_i4, 1_i4, 5_i4, 8_i4, 12_i4, 17_i4, 16_i4, 20_i4 ], [6,8])
      edge_nodes(1:12,1:3) = reshape([ &
        1_i4, 2_i4, 9_i4,  &
        2_i4, 3_i4, 10_i4, &
        3_i4, 4_i4, 11_i4, &
        4_i4, 1_i4, 12_i4, &
        5_i4, 6_i4, 13_i4, &
        6_i4, 7_i4, 14_i4, &
        7_i4, 8_i4, 15_i4, &
        8_i4, 5_i4, 16_i4, &
        1_i4, 5_i4, 17_i4, &
        2_i4, 6_i4, 18_i4, &
        3_i4, 7_i4, 19_i4, &
        4_i4, 8_i4, 20_i4  ], [12,3])

    case ('C3D27')
      dim   = 3_i4
      nFace = 6_i4
      nEdge = 12_i4
      face_nodes(1:6,1:9) = reshape([ &
        1_i4, 2_i4, 3_i4, 4_i4, 9_i4, 10_i4, 11_i4, 12_i4, 21_i4, &
        5_i4, 6_i4, 7_i4, 8_i4,13_i4, 14_i4, 15_i4, 16_i4, 22_i4, &
        1_i4, 2_i4, 6_i4, 5_i4, 9_i4, 18_i4, 13_i4, 17_i4, 23_i4, &
        2_i4, 3_i4, 7_i4, 6_i4,10_i4, 19_i4, 14_i4, 18_i4, 24_i4, &
        3_i4, 4_i4, 8_i4, 7_i4,11_i4, 20_i4, 15_i4, 19_i4, 25_i4, &
        4_i4, 1_i4, 5_i4, 8_i4,12_i4, 17_i4, 16_i4, 20_i4, 26_i4 ], [6,9])
      edge_nodes(1:12,1:3) = reshape([ &
        1_i4, 2_i4, 9_i4,  & 2_i4, 3_i4,10_i4, & 3_i4, 4_i4,11_i4, & 4_i4, 1_i4,12_i4, &
        5_i4, 6_i4,13_i4, & 6_i4, 7_i4,14_i4, & 7_i4, 8_i4,15_i4, & 8_i4, 5_i4,16_i4, &
        1_i4, 5_i4,17_i4, & 2_i4, 6_i4,18_i4, & 3_i4, 7_i4,19_i4, & 4_i4, 8_i4,20_i4 ], [12,3])

    case ('CPE4', 'CPE4R', 'CPE4T', 'CPS4', 'CPS4R', 'CPS4T', &
          'CAX4', 'CAX4R', 'CAX4H', 'CAX4T', 'P2D4SAT', 'P2D4RCH')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:4) = [1_i4, 2_i4, 3_i4, 4_i4]
      edge_nodes(1:4,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 4_i4, &
        4_i4, 1_i4 ], [4,2])

    case ('CPE3', 'CPS3', 'CAX3')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:3) = [1_i4, 2_i4, 3_i4]
      edge_nodes(1:3,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 1_i4 ], [3,2])

    case ('CPE6', 'CPE6R', 'CPS6', 'CPS6R', 'CAX6', 'CAX6R')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:6) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4]
      edge_nodes(1:3,1:3) = reshape([ &
        1_i4, 2_i4, 4_i4, &
        2_i4, 3_i4, 5_i4, &
        3_i4, 1_i4, 6_i4 ], [3,3])

    case ('CPE8', 'CPE8R', 'CPE8T', 'CPS8', 'CPS8R', 'CPS8T', &
          'CAX8', 'CAX8R', 'CAX8T')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:8) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4, 7_i4, 8_i4]
      edge_nodes(1:4,1:3) = reshape([ &
        1_i4, 2_i4, 5_i4, &
        2_i4, 3_i4, 6_i4, &
        3_i4, 4_i4, 7_i4, &
        4_i4, 1_i4, 8_i4 ], [4,3])

    case ('S4', 'S4R', 'S4RS', 'S4T')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:4) = [1_i4, 2_i4, 3_i4, 4_i4]
      edge_nodes(1:4,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 4_i4, &
        4_i4, 1_i4 ], [4,2])

    case ('S3', 'STRI3')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:3) = [1_i4, 2_i4, 3_i4]
      edge_nodes(1:3,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 1_i4 ], [3,2])

    case ('STRI65', 'S6', 'S6R')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:6) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4]
      edge_nodes(1:3,1:3) = reshape([ &
        1_i4, 2_i4, 4_i4, &
        2_i4, 3_i4, 5_i4, &
        3_i4, 1_i4, 6_i4 ], [3,3])

    case ('S8', 'S8R', 'S8RT')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:8) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4, 7_i4, 8_i4]
      edge_nodes(1:4,1:3) = reshape([ &
        1_i4, 2_i4, 5_i4, &
        2_i4, 3_i4, 6_i4, &
        3_i4, 4_i4, 7_i4, &
        4_i4, 1_i4, 8_i4 ], [4,3])

    case ('S9R5')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:9) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4, 7_i4, 8_i4, 9_i4]
      edge_nodes(1:4,1:3) = reshape([ &
        1_i4, 2_i4, 5_i4, &
        2_i4, 3_i4, 6_i4, &
        3_i4, 4_i4, 7_i4, &
        4_i4, 1_i4, 8_i4 ], [4,3])

    case ('SC6R')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:6) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4]
      edge_nodes(1:3,1:3) = reshape([ &
        1_i4, 2_i4, 4_i4, &
        2_i4, 3_i4, 5_i4, &
        3_i4, 1_i4, 6_i4 ], [3,3])

    case ('SC8R')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:8) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4, 7_i4, 8_i4]
      edge_nodes(1:4,1:3) = reshape([ &
        1_i4, 2_i4, 5_i4, &
        2_i4, 3_i4, 6_i4, &
        3_i4, 4_i4, 7_i4, &
        4_i4, 1_i4, 8_i4 ], [4,3])

    case ('B21', 'B21H', 'B21T', 'B31', 'B31H', 'B31OS', 'B31T', 'B31EX')
      dim   = 1_i4
      nFace = 0_i4
      nEdge = 1_i4
      edge_nodes(1,1:2) = [1_i4, 2_i4]

    case ('B22', 'B22H', 'B32', 'B32H', 'B32OS', 'B33', 'B33H', 'B34', 'B34H')
      dim   = 1_i4
      nFace = 0_i4
      nEdge = 1_i4
      edge_nodes(1,1:3) = [1_i4, 2_i4, 3_i4]

    case ('T2D2', 'T2D2H', 'T2D2T', 'T3D2', 'T3D2H', 'T3D2T')
      dim   = 1_i4
      nFace = 0_i4
      nEdge = 1_i4
      edge_nodes(1,1:2) = [1_i4, 2_i4]

    case ('T2D3', 'T2D3H', 'T3D3', 'T3D3H')
      dim   = 1_i4
      nFace = 0_i4
      nEdge = 1_i4
      edge_nodes(1,1:3) = [1_i4, 2_i4, 3_i4]

    case ('M3D4', 'M3D4R', 'M2D4', 'M2D4R')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:4) = [1_i4, 2_i4, 3_i4, 4_i4]
      edge_nodes(1:4,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 4_i4, &
        4_i4, 1_i4 ], [4,2])

    case ('M3D3', 'M3D3R', 'M2D3', 'M2D3R')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:3) = [1_i4, 2_i4, 3_i4]
      edge_nodes(1:3,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 1_i4 ], [3,2])

    case ('M3D6', 'M3D6R')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:6) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4]
      edge_nodes(1:3,1:3) = reshape([ &
        1_i4, 2_i4, 4_i4, &
        2_i4, 3_i4, 5_i4, &
        3_i4, 1_i4, 6_i4 ], [3,3])

    case ('M3D8', 'M3D8R')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:8) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4, 7_i4, 8_i4]
      edge_nodes(1:4,1:3) = reshape([ &
        1_i4, 2_i4, 5_i4, &
        2_i4, 3_i4, 6_i4, &
        3_i4, 4_i4, 7_i4, &
        4_i4, 1_i4, 8_i4 ], [4,3])

    case ('DC1D2', 'AC1D2')
      dim   = 1_i4
      nFace = 0_i4
      nEdge = 1_i4
      edge_nodes(1,1:2) = [1_i4, 2_i4]

    case ('DC1D3', 'AC1D3')
      dim   = 1_i4
      nFace = 0_i4
      nEdge = 1_i4
      edge_nodes(1,1:3) = [1_i4, 2_i4, 3_i4]

    case ('DC2D3', 'AC2D3')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:3) = [1_i4, 2_i4, 3_i4]
      edge_nodes(1:3,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 1_i4 ], [3,2])

    case ('DC2D4', 'AC2D4')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:4) = [1_i4, 2_i4, 3_i4, 4_i4]
      edge_nodes(1:4,1:2) = reshape([ &
        1_i4, 2_i4, &
        2_i4, 3_i4, &
        3_i4, 4_i4, &
        4_i4, 1_i4 ], [4,2])

    case ('DC2D6', 'AC2D6')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 3_i4
      face_nodes(1,1:6) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4]
      edge_nodes(1:3,1:3) = reshape([ &
        1_i4, 2_i4, 4_i4, &
        2_i4, 3_i4, 5_i4, &
        3_i4, 1_i4, 6_i4 ], [3,3])

    case ('DC2D8', 'AC2D8', 'P2D8SAT', 'P2D8RCH')
      dim   = 2_i4
      nFace = 1_i4
      nEdge = 4_i4
      face_nodes(1,1:8) = [1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4, 7_i4, 8_i4]
      edge_nodes(1:4,1:3) = reshape([ &
        1_i4, 2_i4, 5_i4, &
        2_i4, 3_i4, 6_i4, &
        3_i4, 4_i4, 7_i4, &
        4_i4, 1_i4, 8_i4 ], [4,3])

    case ('DC3D4', 'AC3D4')
      dim   = 3_i4
      nFace = 4_i4
      nEdge = 6_i4
      face_nodes(1:4,1:3) = reshape([ &
        1_i4, 2_i4, 3_i4, &
        1_i4, 2_i4, 4_i4, &
        2_i4, 3_i4, 4_i4, &
        1_i4, 3_i4, 4_i4 ], [4,3])
      edge_nodes(1:6,1:2) = reshape([ &
        1_i4, 2_i4, & 2_i4, 3_i4, & 3_i4, 1_i4, &
        1_i4, 4_i4, & 2_i4, 4_i4, & 3_i4, 4_i4 ], [6,2])

    case ('DC3D8', 'AC3D8')
      dim   = 3_i4
      nFace = 6_i4
      nEdge = 12_i4
      face_nodes(1:6,1:4) = reshape([ &
        1_i4, 2_i4, 3_i4, 4_i4, &
        5_i4, 6_i4, 7_i4, 8_i4, &
        1_i4, 2_i4, 6_i4, 5_i4, &
        2_i4, 3_i4, 7_i4, 6_i4, &
        3_i4, 4_i4, 8_i4, 7_i4, &
        4_i4, 1_i4, 5_i4, 8_i4 ], [6,4])
      edge_nodes(1:12,1:2) = reshape([ &
        1_i4, 2_i4, & 2_i4, 3_i4, & 3_i4, 4_i4, & 4_i4, 1_i4, &
        5_i4, 6_i4, & 6_i4, 7_i4, & 7_i4, 8_i4, & 8_i4, 5_i4, &
        1_i4, 5_i4, & 2_i4, 6_i4, & 3_i4, 7_i4, & 4_i4, 8_i4 ], [12,2])

    case ('DC3D10', 'AC3D10')
      dim   = 3_i4
      nFace = 4_i4
      nEdge = 6_i4
      face_nodes(1:4,1:6) = reshape([ &
        1_i4, 2_i4, 3_i4, 4_i4, 5_i4, 6_i4, &
        1_i4, 2_i4, 4_i4, 7_i4, 8_i4, 9_i4, &
        2_i4, 3_i4, 4_i4, 5_i4, 9_i4, 10_i4, &
        1_i4, 3_i4, 4_i4, 6_i4, 8_i4, 10_i4 ], [4,6])
      edge_nodes(1:6,1:3) = reshape([ &
        1_i4, 2_i4, 5_i4, &
        2_i4, 3_i4, 6_i4, &
        3_i4, 1_i4, 4_i4, &
        1_i4, 4_i4, 8_i4, &
        2_i4, 4_i4, 9_i4, &
        3_i4, 4_i4, 10_i4 ], [6,3])

    case ('DC3D6', 'AC3D6', 'P3D6SAT', 'P3D6RCH')
      dim   = 3_i4
      nFace = 5_i4
      nEdge = 9_i4
      face_nodes(1:5,1:4) = reshape([ &
        1_i4, 2_i4, 3_i4, 0_i4, &
        4_i4, 5_i4, 6_i4, 0_i4, &
        1_i4, 2_i4, 5_i4, 4_i4, &
        2_i4, 3_i4, 6_i4, 5_i4, &
        3_i4, 1_i4, 4_i4, 6_i4  ], [5,4])
      edge_nodes(1:9,1:2) = reshape([ &
        1_i4, 2_i4, & 2_i4, 3_i4, & 3_i4, 1_i4, &
        4_i4, 5_i4, & 5_i4, 6_i4, & 6_i4, 4_i4, &
        1_i4, 4_i4, & 2_i4, 5_i4, & 3_i4, 6_i4   ], [9,2])

    case ('DC3D15', 'AC3D15')
      dim   = 3_i4
      nFace = 5_i4
      nEdge = 9_i4
      face_nodes(1:5,1:8) = reshape([ &
        1_i4, 2_i4, 3_i4, 7_i4, 8_i4, 9_i4, 0_i4, 0_i4, &
        4_i4, 5_i4, 6_i4,10_i4,11_i4,12_i4, 0_i4, 0_i4, &
        1_i4, 2_i4, 5_i4, 4_i4, 7_i4,14_i4,10_i4,13_i4, &
        2_i4, 3_i4, 6_i4, 5_i4, 8_i4,15_i4,11_i4,14_i4, &
        3_i4, 1_i4, 4_i4, 6_i4, 9_i4,13_i4,12_i4,15_i4 ], [5,8])
      edge_nodes(1:9,1:3) = reshape([ &
        1_i4, 2_i4, 7_i4,  & 2_i4, 3_i4, 8_i4,  & 3_i4, 1_i4, 9_i4,  &
        4_i4, 5_i4,10_i4,  & 5_i4, 6_i4,11_i4,  & 6_i4, 4_i4,12_i4,  &
        1_i4, 4_i4,13_i4,  & 2_i4, 5_i4,14_i4,  & 3_i4, 6_i4,15_i4 ], [9,3])

    case ('DC3D20', 'AC3D20')
      dim   = 3_i4
      nFace = 6_i4
      nEdge = 12_i4
      face_nodes(1:6,1:8) = reshape([ &
        1_i4, 2_i4, 3_i4, 4_i4, 9_i4, 10_i4, 11_i4, 12_i4, &
        5_i4, 6_i4, 7_i4, 8_i4, 13_i4, 14_i4, 15_i4, 16_i4, &
        1_i4, 2_i4, 6_i4, 5_i4, 9_i4, 18_i4, 13_i4, 17_i4, &
        2_i4, 3_i4, 7_i4, 6_i4,10_i4, 19_i4, 14_i4, 18_i4, &
        3_i4, 4_i4, 8_i4, 7_i4,11_i4, 20_i4, 15_i4, 19_i4, &
        4_i4, 1_i4, 5_i4, 8_i4,12_i4, 17_i4, 16_i4, 20_i4 ], [6,8])
      edge_nodes(1:12,1:3) = reshape([ &
        1_i4, 2_i4, 9_i4,  & 2_i4, 3_i4,10_i4, & 3_i4, 4_i4,11_i4, & 4_i4, 1_i4,12_i4, &
        5_i4, 6_i4,13_i4, & 6_i4, 7_i4,14_i4, & 7_i4, 8_i4,15_i4, & 8_i4, 5_i4,16_i4, &
        1_i4, 5_i4,17_i4, & 2_i4, 6_i4,18_i4, & 3_i4, 7_i4,19_i4, & 4_i4, 8_i4,20_i4 ], [12,3])

    case ('DC3D27', 'AC3D27')
      dim   = 3_i4
      nFace = 6_i4
      nEdge = 12_i4
      face_nodes(1:6,1:9) = reshape([ &
        1_i4, 2_i4, 3_i4, 4_i4, 9_i4, 10_i4, 11_i4, 12_i4, 21_i4, &
        5_i4, 6_i4, 7_i4, 8_i4,13_i4, 14_i4, 15_i4, 16_i4, 22_i4, &
        1_i4, 2_i4, 6_i4, 5_i4, 9_i4, 18_i4, 13_i4, 17_i4, 23_i4, &
        2_i4, 3_i4, 7_i4, 6_i4,10_i4, 19_i4, 14_i4, 18_i4, 24_i4, &
        3_i4, 4_i4, 8_i4, 7_i4,11_i4, 20_i4, 15_i4, 19_i4, 25_i4, &
        4_i4, 1_i4, 5_i4, 8_i4,12_i4, 17_i4, 16_i4, 20_i4, 26_i4 ], [6,9])
      edge_nodes(1:12,1:3) = reshape([ &
        1_i4, 2_i4, 9_i4,  & 2_i4, 3_i4,10_i4, & 3_i4, 4_i4,11_i4, & 4_i4, 1_i4,12_i4, &
        5_i4, 6_i4,13_i4, & 6_i4, 7_i4,14_i4, & 7_i4, 8_i4,15_i4, & 8_i4, 5_i4,16_i4, &
        1_i4, 5_i4,17_i4, & 2_i4, 6_i4,18_i4, & 3_i4, 7_i4,19_i4, & 4_i4, 8_i4,20_i4 ], [12,3])

    case default
      ierr  = -1_i4
      dim   = 0_i4
      nFace = 0_i4
      nEdge = 0_i4
    end select

  end subroutine UF_ElementCatalog_GetConnectivity

  !=============================================================================
  ! Surface Load Tools
  !=============================================================================
  subroutine UF_GetFaceNormal(face_coords, n_face_nodes, normal)
    real(wp), intent(in)  :: face_coords(:,:)
    integer(i4), intent(in) :: n_face_nodes
    real(wp), intent(out) :: normal(3)

    real(wp) :: v1(3), v2(3), norm_length

    if (n_face_nodes >= 3) then
      v1 = face_coords(:,2) - face_coords(:,1)
      v2 = face_coords(:,3) - face_coords(:,1)
    else
      normal = [0.0_wp, 0.0_wp, 1.0_wp]
      return
    end if

    normal(1) = v1(2)*v2(3) - v1(3)*v2(2)
    normal(2) = v1(3)*v2(1) - v1(1)*v2(3)
    normal(3) = v1(1)*v2(2) - v1(2)*v2(1)

    norm_length = sqrt(normal(1)**2 + normal(2)**2 + normal(3)**2)
    if (norm_length > 1.0e-15_wp) then
      normal = normal / norm_length
    else
      normal = [0.0_wp, 0.0_wp, 1.0_wp]
    end if
  end subroutine UF_GetFaceNormal

  subroutine UF_ApplyFacePressure(face_coords, n_face_nodes, pressure, nodal_forces)
    real(wp), intent(in)  :: face_coords(:,:)
    integer(i4), intent(in) :: n_face_nodes
    real(wp), intent(in)  :: pressure
    real(wp), intent(out) :: nodal_forces(:,:)

    real(wp) :: normal(3), area, force_per_node
    real(wp) :: v1(3), v2(3), tri_area
    integer(i4) :: i

    call UF_GetFaceNormal(face_coords, n_face_nodes, normal)

    if (n_face_nodes == 3) then
      v1 = face_coords(:,2) - face_coords(:,1)
      v2 = face_coords(:,3) - face_coords(:,1)
      tri_area = 0.5_wp * sqrt( &
           (v1(2)*v2(3) - v1(3)*v2(2))**2 &
         + (v1(3)*v2(1) - v1(1)*v2(3))**2 &
         + (v1(1)*v2(2) - v1(2)*v2(1))**2 )
      area = tri_area
    else if (n_face_nodes == 4) then
      v1 = face_coords(:,2) - face_coords(:,1)
      v2 = face_coords(:,3) - face_coords(:,1)
      tri_area = 0.5_wp * sqrt( &
           (v1(2)*v2(3) - v1(3)*v2(2))**2 &
         + (v1(3)*v2(1) - v1(1)*v2(3))**2 &
         + (v1(1)*v2(2) - v1(2)*v2(1))**2 )
      v1 = face_coords(:,3) - face_coords(:,1)
      v2 = face_coords(:,4) - face_coords(:,1)
      area = tri_area + 0.5_wp * sqrt( &
           (v1(2)*v2(3) - v1(3)*v2(2))**2 &
         + (v1(3)*v2(1) - v1(1)*v2(3))**2 &
         + (v1(1)*v2(2) - v1(2)*v2(1))**2 )
    else
      area = 1.0_wp
    end if

    force_per_node = -pressure * area / real(max(1_i4, n_face_nodes), wp)

    do i = 1, n_face_nodes
      nodal_forces(:, i) = force_per_node * normal
    end do
  end subroutine UF_ApplyFacePressure

  subroutine UF_ApplyFaceTraction(face_coords, n_face_nodes, traction, nodal_forces)
    real(wp), intent(in)  :: face_coords(:,:)
    integer(i4), intent(in) :: n_face_nodes
    real(wp), intent(in)  :: traction(3)
    real(wp), intent(out) :: nodal_forces(:,:)

    real(wp) :: area, v1(3), v2(3), tri_area, total_force(3)
    integer(i4) :: i

    if (n_face_nodes == 3) then
      v1 = face_coords(:,2) - face_coords(:,1)
      v2 = face_coords(:,3) - face_coords(:,1)
      tri_area = 0.5_wp * sqrt( &
           (v1(2)*v2(3) - v1(3)*v2(2))**2 &
         + (v1(3)*v2(1) - v1(1)*v2(3))**2 &
         + (v1(1)*v2(2) - v1(2)*v2(1))**2 )
      area = tri_area
    else if (n_face_nodes == 4) then
      v1 = face_coords(:,2) - face_coords(:,1)
      v2 = face_coords(:,3) - face_coords(:,1)
      tri_area = 0.5_wp * sqrt( &
           (v1(2)*v2(3) - v1(3)*v2(2))**2 &
         + (v1(3)*v2(1) - v1(1)*v2(3))**2 &
         + (v1(1)*v2(2) - v1(2)*v2(1))**2 )
      v1 = face_coords(:,3) - face_coords(:,1)
      v2 = face_coords(:,4) - face_coords(:,1)
      area = tri_area + 0.5_wp * sqrt( &
           (v1(2)*v2(3) - v1(3)*v2(2))**2 &
         + (v1(3)*v2(1) - v1(1)*v2(3))**2 &
         + (v1(1)*v2(2) - v1(2)*v2(1))**2 )
    else
      area = 1.0_wp
    end if

    total_force = traction * area

    do i = 1, n_face_nodes
      nodal_forces(:, i) = total_force / real(max(1_i4, n_face_nodes), wp)
    end do
  end subroutine UF_ApplyFaceTraction

  subroutine UF_ApplyEdgeLoad(edge_coords, n_edge_nodes, isPressure, magnitude, direction, nodal_forces)
    real(wp), intent(in)  :: edge_coords(:,:)
    integer(i4), intent(in) :: n_edge_nodes
    logical,   intent(in)  :: isPressure
    real(wp), intent(in)   :: magnitude
    real(wp), intent(in)   :: direction(3)
    real(wp), intent(out)  :: nodal_forces(:,:)

    integer(i4) :: ndim, i
    real(wp) :: edge_vec(3), edge_length, normal2d(2), traction(3), force_per_node(3)

    ndim = size(edge_coords, 1)

    edge_vec = 0.0_wp
    edge_vec(1:ndim) = edge_coords(1:ndim, n_edge_nodes) - edge_coords(1:ndim, 1)
    edge_length = sqrt(edge_vec(1)**2 + edge_vec(2)**2 + edge_vec(3)**2)
    if (edge_length <= 1.0e-15_wp) then
      nodal_forces = 0.0_wp
      return
    end if

    if (isPressure .and. ndim == 2) then
      normal2d(1) =  edge_vec(2) / edge_length
      normal2d(2) = -edge_vec(1) / edge_length
      force_per_node(1) = -magnitude * edge_length * normal2d(1) / real(max(1_i4,n_edge_nodes), wp)
      force_per_node(2) = -magnitude * edge_length * normal2d(2) / real(max(1_i4,n_edge_nodes), wp)
      force_per_node(3) = 0.0_wp
    else if (isPressure .and. ndim == 3) then
      traction = magnitude * direction
      force_per_node = traction * edge_length / real(max(1_i4,n_edge_nodes), wp)
    else
      traction = magnitude * direction
      force_per_node = traction * edge_length / real(max(1_i4,n_edge_nodes), wp)
    end if

    nodal_forces = 0.0_wp
    do i = 1, n_edge_nodes
      nodal_forces(1:min(3,ndim), i) = force_per_node(1:min(3,ndim))
    end do
  end subroutine UF_ApplyEdgeLoad

  !=============================================================================
  ! Element Adapter Functions
  !=============================================================================
  subroutine UF_Ad_El_To_State(state_old, state_new, element_id, nIntPoints)
    type(ElemState), intent(in)      :: state_old
    type(ElemState),        intent(inout) :: state_new
    integer(i4),           intent(in),   optional :: element_id, nIntPoints

    if (present(element_id)) then
      state_new%cfg%id = element_id
    else
      state_new%cfg%id = state_old%cfg%id
    end if

    if (present(nIntPoints)) then
      state_new%nIntPoints = nIntPoints
    else
      if (allocated(state_old%ipStates)) then
        state_new%nIntPoints = size(state_old%ipStates)
      else
        state_new%nIntPoints = 0_i4
      end if
    end if

    state_new%elemStatus = state_old%elemStatus
    state_new%active     = state_old%active
    state_new%failed     = state_old%failed
    state_new%stableDt   = state_old%stableDt

    state_new%rhs_norm   = 0.0_wp
    if (allocated(state_old%Re)) then
      state_new%rhs_norm = sum(state_old%Re**2)
      state_new%rhs_norm = sqrt(state_new%rhs_norm)
    end if

    state_new%int_energy = 0.0_wp

  end subroutine UF_Adapt_ElementState_To_State

  subroutine UF_Adapt_ElementType_To_Desc(element_old, desc)
    type(ElemType),     intent(in)    :: element_old
    class(ElemType),   intent(inout) :: desc

    desc%cfg%elem_type_id  = element_old%cfg%elem_type_id
    desc%name        = trim(element_old%name)
    desc%family      = 0_i4
    desc%topo        = 0_i4
    desc%dim         = element_old%dim
    desc%pop%n_nodes      = element_old%pop%n_nodes
    desc%n_dof_per_node = 0_i4
    desc%n_int_points  = 0_i4
    desc%has_struct   = .true.
    desc%has_thermal  = .false.
    desc%has_pore     = .false.

  end subroutine UF_Adapt_ElementType_To_Desc

  !=============================================================================
  ! StructGaussKernel Functions
  !=============================================================================
  subroutine UF_Struct_GaussKernel(ElemType, Formul, Ctx, ipKernel)
    type(ElemType),        intent(in) :: ElemType
    type(ElemFormul), intent(in) :: Formul
    type(ElemCtx),     intent(in) :: Ctx
    procedure(UF_Struct_IpKernel)          :: ipKernel

    integer(i4) :: nNode, nDim, ip, nInt, iNode
    integer(i4) :: integrationorde
    logical     :: isAxisym
    real(wp), allocatable :: gaussCoords(:,:), weights(:)
    type(ShapeFuncResult) :: sf
    real(wp), allocatable :: dN_dx(:,:)
    real(wp) :: detJ, dVol, radius, r_coord

    nNode   = ElemType%pop%n_nodes
    nDim    = ElemType%dim
    isAxisym = (index(ElemType%name, 'CAX') > 0)

    integrationorde = GetEffOrder(ElemType, Formul)
    call UF_GetGaussPoints(ElemType%topo, integrationorde, nDim, gaussCoords, weights)
    if (.not. allocated(weights)) return
    nInt = size(weights)

    if (allocated(dN_dx)) deallocate(dN_dx)
    allocate(dN_dx(nNode, nDim))

    do ip = 1, nInt
      call UF_GetShapeFunctions(ElemType%name, gaussCoords(:,ip), sf)

      if (Formul%kineFormulation == UF_Form_UL) then
        call UF_ComputeJacobian(Ctx%coords_curr(1:nDim, :), sf%dN_dxi, detJ, dN_dx)
      else
        call UF_ComputeJacobian(Ctx%coords_ref(1:nDim, :), sf%dN_dxi, detJ, dN_dx)
      end if

      dVol = detJ * weights(ip)

      radius = 0.0_wp
      if (isAxisym) then
        do iNode = 1, nNode
          if (Formul%kineFormulation == UF_Form_UL) then
            r_coord = Ctx%coords_curr(1, iNode)
          else
            r_coord = Ctx%coords_ref(1, iNode)
          end if
          radius  = radius + sf%N(iNode, 1) * r_coord
        end do
        if (radius < 1.0e-10_wp) radius = 1.0e-10_wp
        dVol = dVol * 6.283185307179586_wp * radius
      else if (nDim == 2) then
        dVol = dVol * 1.0_wp
      end if

      call ipKernel(ip, sf, dN_dx, dVol, radius)

    end do

    if (allocated(dN_dx))       deallocate(dN_dx)
    if (allocated(gaussCoords)) deallocate(gaussCoords)
    if (allocated(weights))     deallocate(weights)

  end subroutine UF_Struct_GaussKernel

  interface StructGaussKernel
!>>> UFC_L3_QUENCH | Domain:Element | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

    module procedure UF_Struct_GaussKernel
  end interface

  !===============================================================================
  ! FEAP-STYLE BEAM AND SHELL ELEMENTS
  !===============================================================================

  !---------------------------------------------------------------------------
  ! UF_BeamElement_EulerBernoulli - Euler-Bernoulli beam element
  ! Classical beam theory without shear deformation
  !---------------------------------------------------------------------------
  subroutine UF_Be_EulerBernoulli(coords, material_props, cross_section, &
                                          displacements, stiffness, force, status)
    real(wp), intent(in)  :: coords(3,2)         ! Node coordinates (x,y,z for 2 nodes)
    real(wp), intent(in)  :: material_props(:)   ! [E, nu, rho]
    real(wp), intent(in)  :: cross_section(2)    ! [area, I] - cross section area and moment of inertia
    real(wp), intent(in)  :: displacements(6)    ! Nodal displacements [u1,v1,1, u2,v2,2]
    real(wp), intent(out) :: stiffness(6,6)      ! Element stiffness matrix
    real(wp), intent(out) :: force(6)            ! Element force vector
    integer(i4), intent(out) :: status           ! Status code

    real(wp) :: L, E, A, I, EA, EI
    real(wp) :: k_local(6,6)  ! Local stiffness matrix
    real(wp) :: T(6,6)        ! 2D Euler-Bernoulli beam 6x6 transformation
    real(wp) :: u_local(6)    ! local displacement
    real(wp) :: f_local(6)    ! local force
    real(wp) :: dx(2), c, s   ! dx, cos(theta), sin(theta)

    status = 0
    stiffness = 0.0_wp
    force = 0.0_wp

    ! Compute element length (projected in XY plane for 2D Euler-Bernoulli beam)
    dx(1) = coords(1,2) - coords(1,1)
    dx(2) = coords(2,2) - coords(2,1)
    L = sqrt(dx(1)**2 + dx(2)**2)
    if (L <= 1.0e-12_wp) then
      ! Zero length check
      status = -1
      stiffness = 0.0_wp
      force = 0.0_wp
      return
    end if

    ! Rotation: x along dx, y perp to x, z out-of-plane
    c = dx(1) / L   ! cos(theta)
    s = dx(2) / L   ! sin(theta)

    ! Mat and geometric properties
    E = material_props(1)  ! Young's modulus
    A = cross_section(1)   ! Cross-section area
    I = cross_section(2)   ! Moment of inertia

    EA = E * A
    EI = E * I

    ! Local stiffness matrix for Euler-Bernoulli beam
    k_local = 0.0_wp

    ! Axial stiffness terms
    k_local(1,1) = EA / L
    k_local(1,4) = -EA / L
    k_local(4,1) = -EA / L
    k_local(4,4) = EA / L

    ! Bending stiffness terms (Euler-Bernoulli)
    k_local(2,2) = 12.0_wp * EI / L**3
    k_local(2,3) = 6.0_wp * EI / L**2
    k_local(2,5) = -12.0_wp * EI / L**3
    k_local(2,6) = 6.0_wp * EI / L**2

    k_local(3,2) = 6.0_wp * EI / L**2
    k_local(3,3) = 4.0_wp * EI / L
    k_local(3,5) = -6.0_wp * EI / L**2
    k_local(3,6) = 2.0_wp * EI / L

    k_local(5,2) = -12.0_wp * EI / L**3
    k_local(5,3) = -6.0_wp * EI / L**2
    k_local(5,5) = 12.0_wp * EI / L**3
    k_local(5,6) = -6.0_wp * EI / L**2

    k_local(6,2) = 6.0_wp * EI / L**2
    k_local(6,3) = 2.0_wp * EI / L
    k_local(6,5) = -6.0_wp * EI / L**2
    k_local(6,6) = 4.0_wp * EI / L

    !===================================================================
    ! DOF order (beam): [u1, v1, theta1, u2, v2, theta2]
    !   u: x-displacement, v: y-displacement, theta: z-rotation
    !-------------------------------------------------------------------

    ! 6x6 local-to-global transformation T
    T = 0.0_wp

    ! Block 1 (node 1)
    T(1,1) = c
    T(1,2) = s
    T(2,1) = -s
    T(2,2) = c
    T(3,3) = 1.0_wp   ! rotation 2D

    ! Block 2 (node 2)
    T(4,4) = c
    T(4,5) = s
    T(5,4) = -s
    T(5,5) = c
    T(6,6) = 1.0_wp

    ! u_local = T * u_global
    u_local = matmul(T, displacements)

    ! f_local = K_local * u_local
    f_local = matmul(k_local, u_local)

    ! K_global = T^T * K_local * T
    stiffness = matmul(transpose(T), matmul(k_local, T))

    ! f_global = T^T * f_local
    force = matmul(transpose(T), f_local)

  end subroutine UF_BeamElement_EulerBernoulli

  !===============================================================================
  ! PUBLIC INTERFACES FOR FEAP-STYLE ELEMENTS
  !===============================================================================

  public :: UF_BeamElement_EulerBernoulli

  ! ===================================================================
  ! Element Dispatch Functions (from MD_Element_Dispatch.f90)
  ! ===================================================================
  
  subroutine DispatchCompute(desc, ElemType, Formul, Ctx, &
                             state_in, Mat, state_out, flags)
    !! Dispatch element computation based on element description
    
    class(ElemType),      intent(in)    :: desc
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(MatProps),          intent(inout) :: Mat
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(inout) :: flags

    logical :: isStructSingle
    logical :: isPoro, isThermalStruct, isThermalOnly, isTHM, isPoreSingle, isPoreSat, isPoreTwo

    type(MatProps), allocatable :: matModels(:)
    character(len=32) :: elemName_trim
    integer(i4) :: nInt_old

    isStructSingle = (desc%family    == UF_FAMILY_CONTI) .and. &
                     (desc%has_struct .eqv. .true.)          .and. &
                     (.not. desc%has_thermal)                .and. &
                     (.not. desc%has_pore)

    elemName_trim = trim(ElemType%name)

    isPoro          = (desc%family == UF_FAMILY_CONTI) .and. desc%has_struct .and. (.not. desc%has_thermal) .and. desc%has_pore
    isThermalStruct = (desc%family == UF_FAMILY_CONTI) .and. desc%has_struct .and. desc%has_thermal            .and. (.not. desc%has_pore)
    isThermalOnly   = (desc%family == UF_FAMILY_CONTI) .and. (.not. desc%has_struct) .and. desc%has_thermal    .and. (.not. desc%has_pore)
    isTHM           = (desc%family == UF_FAMILY_CONTI) .and. desc%has_struct .and. desc%has_thermal            .and. desc%has_pore
    isPoreSingle    = (desc%family == UF_FAMILY_CONTI) .and. (.not. desc%has_struct) .and. (.not. desc%has_thermal) .and. desc%has_pore
    isPoreSat       = isPoreSingle .and. index(elemName_trim, 'SAT') > 0
    isPoreTwo       = isPoreSingle .and. index(elemName_trim, 'RCH') > 0

    if (isStructSingle) then
      nInt_old = max(1_i4, ElemType%n_int_points)
      allocate(matModels(nInt_old))
      matModels = Mat

      if (desc%dim == 3) then
        call MD_PH_Elem_CalcContinuum3D(ElemType, Formul, Ctx, state_in, &
                                        matModels, state_out, flags)
      else
        call MD_PH_Elem_CalcContinuum2D(ElemType, Formul, Ctx, state_in, &
                                        matModels, state_out, flags)
      end if

      deallocate(matModels)

    else if (isPoro) then
      nInt_old = max(1_i4, ElemType%n_int_points)
      allocate(matModels(nInt_old))
      matModels = Mat

      call MD_PH_Elem_CalcPoro(ElemType, Formul, Ctx, state_in, &
                                matModels, state_out, flags)

      deallocate(matModels)

    else if (isThermalStruct) then
      nInt_old = max(1_i4, ElemType%n_int_points)
      allocate(matModels(nInt_old))
      matModels = Mat

      call MD_PH_Elem_CalcThm(ElemType, Formul, Ctx, state_in, &
                              matModels, state_out, flags)

      deallocate(matModels)

    else if (isTHM) then
      nInt_old = max(1_i4, ElemType%n_int_points)
      allocate(matModels(nInt_old))
      matModels = Mat

      call MD_PH_Elem_CalcTHM(ElemType, Formul, Ctx, state_in, &
                              matModels, state_out, flags)

      deallocate(matModels)

    else if (isThermalOnly) then
      ! Thermal-only elements: dispatch to RT_Elem_Core which routes to specific DC* Calc functions
      ! This allows proper element-family-based dispatch (DC2D4, DC3D8, etc.)
      call MD_RT_Elem_Comp(ElemType, Formul, Ctx, state_in, &
                           Mat, state_out, flags, flags%status)

    else if (isPoreSat) then

      nInt_old = max(1_i4, ElemType%n_int_points)
      allocate(matModels(nInt_old))
      matModels = Mat

      call MD_PH_Elem_CalcPoroSaturated(ElemType, Formul, Ctx, state_in, &
                                        matModels, state_out, flags)

      deallocate(matModels)

    else if (isPoreTwo) then
      nInt_old = max(1_i4, ElemType%n_int_points)
      allocate(matModels(nInt_old))
      matModels = Mat

      call MD_PH_Elem_CalcPoroTwoPhase(ElemType, Formul, Ctx, state_in, &
                                       matModels, state_out, flags)

      deallocate(matModels)

    else
      call MD_RT_Elem_Comp(ElemType, Formul, Ctx, state_in, &
                           Mat, state_out, flags, flags%status)

    end if

  end subroutine DispatchCompute

  subroutine DispatchFromType(ElemType, Formul, Ctx, &
                              state_in, Mat, state_out, flags)
    !! Dispatch element computation from element type
    
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(MatProps),          intent(inout) :: Mat
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(inout) :: flags

    type(ElemType) :: desc

    call UF_Adapt_ElementType_To_Desc(ElemType, desc)

    call DispatchCompute(desc, ElemType, Formul, Ctx, &
                         state_in, Mat, state_out, flags)

  end subroutine DispatchFromType

  ! ===================================================================
  ! Element Kinematics Helpers (from MD_Element_KinHelpers.f90)
  ! ===================================================================
  
  subroutine UF_Ki_So_FromContxt(ElemType, Formul, Ctx, ip, kin)
    !! Compute 2D solid kinematics from element Ctx
    !! Uses base ElemType/ElemFormul/ElemCtx to avoid MD_Element_Base circular dep
    type(ElemType),        intent(in)    :: ElemType
    type(ElemFormul),      intent(in)    :: Formul
    type(ElemCtx),         intent(in)    :: Ctx
    integer(i4),           intent(in)    :: ip
    type(UF_Kinematics),   intent(inout) :: kin

    type(ShapeFuncResult) :: sf
    real(wp), allocatable    :: gaussCoords(:,:), weights(:)
    real(wp), allocatable    :: dN_dx(:,:)
    real(wp) :: grad_u(3,3)
    integer(i4) :: nDim, nNode, nInt, topo, order
    integer(i4) :: a
    real(wp) :: detJ

    nDim  = 2_i4
    nNode = ElemType%pop%n_nodes

    kin%meta%dim  = nDim
    kin%meta%ndi  = 3_i4
    kin%meta%nshr = 3_i4
    kin%meta%ntens = 6_i4

    kin%cfg%id = Ctx%cfg%id
    kin%ipID   = ip
    kin%stepID = Ctx%cfg%id
    kin%incID  = Ctx%incId

    kin%time   = Ctx%time
    kin%dTime  = Ctx%dTime

    kin%mech%strain  = 0.0_wp
    kin%mech%dStrain = 0.0_wp
    kin%mech%F       = 0.0_wp
    kin%mech%F_old   = 0.0_wp
    kin%mech%F_incr  = 0.0_wp
    kin%mech%Jac     = 1.0_wp
    kin%mech%C       = 0.0_wp
    kin%mech%R       = 0.0_wp

    kin%mech%coords_ref  = 0.0_wp
    kin%mech%coords_curr = 0.0_wp

    topo  = ElemType%topo
    order = 2_i4

    call UF_GetGaussPoints(topo, order, nDim, gaussCoords, weights)
    if (.not. allocated(weights)) return

    nInt = size(weights)
    if (ip < 1 .or. ip > nInt) return

    call UF_GetShapeFunctions(ElemType%name, gaussCoords(1:nDim, ip), sf)

    if (.not. allocated(Ctx%coords_ref)) return
    if (size(Ctx%coords_ref,2) < nNode) return

    call UF_ComputeJacobian(Ctx%coords_ref(1:nDim,1:nNode), &
                            sf%dN_dxi(1:nNode,1:nDim), detJ, dN_dx)

    kin%mech%Jac = detJ

    do a = 1, nNode
      kin%mech%coords_ref(1:nDim) = kin%mech%coords_ref(1:nDim) + &
           sf%N(a) * Ctx%coords_ref(1:nDim,a)
      if (allocated(Ctx%coords_curr)) then
        if (size(Ctx%coords_curr,2) >= a) then
          kin%mech%coords_curr(1:nDim) = kin%mech%coords_curr(1:nDim) + &
               sf%N(a) * Ctx%coords_curr(1:nDim,a)
        end if
      else
        kin%mech%coords_curr(1:nDim) = kin%mech%coords_curr(1:nDim) + &
             sf%N(a) * (Ctx%coords_ref(1:nDim,a) + Ctx%disp_total(1:nDim,a))
      end if
    end do

    grad_u = 0.0_wp
    do a = 1, nNode
      grad_u(1,1) = grad_u(1,1) + Ctx%disp_total(1,a) * dN_dx(a,1)
      grad_u(2,1) = grad_u(2,1) + Ctx%disp_total(2,a) * dN_dx(a,1)
      grad_u(1,2) = grad_u(1,2) + Ctx%disp_total(1,a) * dN_dx(a,2)
      grad_u(2,2) = grad_u(2,2) + Ctx%disp_total(2,a) * dN_dx(a,2)
    end do

    kin%mech%strain = 0.0_wp
    kin%mech%strain(1) = grad_u(1,1)
    kin%mech%strain(2) = grad_u(2,2)
    kin%mech%strain(3) = 0.0_wp
    kin%mech%strain(4) = grad_u(1,2) + grad_u(2,1)
    kin%mech%strain(5) = 0.0_wp
    kin%mech%strain(6) = 0.0_wp

    kin%mech%dStrain = 0.0_wp

    kin%thermal%temp  = 0.0_wp
    kin%thermal%dTemp = 0.0_wp

    if (allocated(Ctx%temp)) then
      do a = 1, min(nNode, size(Ctx%temp))
        kin%thermal%temp = kin%thermal%temp + sf%N(a) * Ctx%temp(a)
      end do
    end if

    if (allocated(Ctx%temp_incr)) then
      do a = 1, min(nNode, size(Ctx%temp_incr))
        kin%thermal%dTemp = kin%thermal%dTemp + sf%N(a) * Ctx%temp_incr(a)
      end do
    end if

  end subroutine UF_Kinematics_Solid2D_FromContext

  ! [REMOVED] Legacy INTERFACE alias Kin_Solid2D_FromCtx (no external refs)

  ! ===================================================================
  ! User Element Functions (from MD_Element_User.f90)
  ! ===================================================================
  
  subroutine UF_Init_UserElement(Element, name)
    !! Init user-defined element
    
    type(ElemType), intent(inout) :: Element
    character(len=*),     intent(in)    :: name

    Element%name   = trim(name)

    Element%dim          = 0_i4
    Element%pop%n_nodes     = 0_i4

    Element%compute => Calc_UserElement
  end subroutine UF_Init_UserElement

  subroutine Calc_UserElement(ElemType, Formul, Ctx, state_in, &
                                 matModels, state_out, flags)
    !! Compute user-defined element
    
    type(ElemType),       intent(in)    :: ElemType
    type(ElemFormul), intent(in)    :: Formul
    type(ElemCtx),    intent(in)    :: Ctx
    type(ElemState),         intent(in)    :: state_in
    type(MatProps),          intent(in)    :: matModels(:)
    type(ElemState),         intent(inout) :: state_out
    type(ElemFlags),      intent(out)   :: flags

    integer(i4) :: nNode, ndof_per_node, ndof_total, ip

    nNode         = ElemType%pop%n_nodes
    ndof_per_node = merge(ElemType%n_dof_per_node, 3_i4, ElemType%n_dof_per_node > 0_i4)
    if (ndof_per_node <= 0_i4) ndof_per_node = 1_i4
    ndof_total    = nNode * ndof_per_node

    state_out%evo%Ke = 0.0_wp
    state_out%Re = 0.0_wp
    state_out%Me = 0.0_wp
    state_out%Ce = 0.0_wp

    flags%failed              = .false.
    flags%suggest_cutback     = .false.
    flags%requires_reasse = .false.
    flags%stableDt            = 0.0_wp

    call init_error_status(flags%status)
    call MD_RT_Elem_Comp(ElemType, Formul, Ctx, state_in, matModels(1), state_out, flags, flags%status)

    state_out%elemStatus = 0_i4
    if (allocated(state_out%ipStates)) then
      do ip = 1, size(state_out%ipStates)
        select case (state_out%ipStates(ip)%statusFlag)
        case (-1_i4)
          state_out%elemStatus = -1_i4
          exit
        case (1_i4)
          if (state_out%elemStatus /= -1_i4) state_out%elemStatus = 1_i4
        end select
      end do
    end if

    state_out%failed   = flags%failed
    state_out%stableDt = flags%stableDt

  end subroutine Calc_UserElement

  !=============================================================================
  ! Extended Element Types (merged from MD_Element.f90)
  !=============================================================================
  
  ! Constants from MD_Element.f90 (some may duplicate existing constants above)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_ELEMENT_NAME = 80
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_NODES_PER_ELEMENT_EXT = 27  ! For HEX27
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_INT_POINTS_EXT = 100
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MESH_MAX_ELEMENT_TAGS = 100
  
  !=============================================================================
  ! TYPE: MD_IntegrationPoint_Type
  ! Purpose: Extended integration point type with detailed state information
  !=============================================================================
  TYPE, PUBLIC :: MD_IntegrationPoint_Type
      INTEGER(i4) :: ip_id = 0_i4                 ! Integration point ID
      REAL(wp) :: coords_local(3) = 0.0_wp        ! Local coordinates (?, ?, ?)
      REAL(wp) :: coords_global(3) = 0.0_wp       ! Global coordinates
      REAL(wp) :: weight = 0.0_wp                 ! Integration weight
      REAL(wp) :: jacobian = 0.0_wp               ! Jacobian determinant
      REAL(wp) :: jacobian_matrix(3,3) = 0.0_wp  ! Jacobian matrix
      REAL(wp), ALLOCATABLE :: state_variables(:) ! State variables at IP
      REAL(wp), ALLOCATABLE :: sigma(:)          ! Stress tensor
      REAL(wp), ALLOCATABLE :: strain(:)          ! Strain tensor
      LOGICAL :: is_active = .TRUE.                ! Active/inactive flag
  END TYPE MD_IntegrationPoint_Type
  
  !=============================================================================
  ! TYPE: MD_Element_Type
  ! Purpose: Extended element definition with connectivity, integration points, state
  !          This is a higher-level wrapper around ElemType for element management
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_Element_Type
      ! Basic identification (name inherited from BaseDesc)
      INTEGER(i4) :: id = 0_i4                    ! Element ID (1-based)
      
      ! Element type and topology
      INTEGER(i4) :: elem_type = MD_MESH_ELEMENT_UNKNOWN  ! Element type code
      INTEGER(i4) :: nNodes = 0_i4             ! Number of nodes
      INTEGER(i4) :: spatial_dim = 3_i4          ! Spatial dimension (2 or 3)
      
      ! Connectivity
      INTEGER(i4) :: connectivity(MD_MESH_MAX_NODES_PER_ELEMENT_EXT) = 0_i4  ! Node connectivity
      INTEGER(i4), ALLOCATABLE :: node_ids(:)     ! Node IDs (for reference)
      
      ! Section and Mat assignment
      INTEGER(i4) :: section_id = 0_i4           ! Section ID
      INTEGER(i4) :: material_id = 0_i4          ! Mat ID
      INTEGER(i4) :: orientation_id = 0_i4       ! Orientation ID
      
      ! Integration points
      INTEGER(i4) :: nIntPoints = 0_i4        ! Number of integration points
      TYPE(MD_IntegrationPoint_Type), ALLOCATABLE :: int_points(:) ! Integration points
      
      ! State variable management
      INTEGER(i4) :: statev_offset = 0_i4        ! Offset in global STATEV array
      INTEGER(i4) :: num_state_vars = 0_i4       ! Number of state variables per IP
      
      ! Element properties
      REAL(wp) :: volume = 0.0_wp                 ! Element volume
      REAL(wp) :: area = 0.0_wp                   ! Element area (for 2D elements)
      REAL(wp) :: mass = 0.0_wp                  ! Element mass
      REAL(wp) :: thickness = 0.0_wp             ! Thickness (for shell/membrane)
      
      ! Quality metrics
      REAL(wp) :: aspect_ratio = 0.0_wp          ! Aspect ratio
      REAL(wp) :: skewness = 0.0_wp              ! Skewness
      REAL(wp) :: jacobian_ratio = 0.0_wp        ! Jacobian ratio (min/max)
      REAL(wp) :: quality_score = 0.0_wp        ! Overall quality score
      
      ! Connectivity information
      INTEGER(i4) :: num_neighbors = 0_i4        ! Number of neighboring elements
      INTEGER(i4), ALLOCATABLE :: neighbor_list(:) ! Neighboring element IDs
      
      ! Tags and metadata
      INTEGER(i4) :: num_tags = 0_i4
      CHARACTER(LEN=MD_MESH_MAX_ELEMENT_NAME), ALLOCATABLE :: tags(:)
      
      ! Status flags
      LOGICAL :: is_active = .TRUE.               ! Active/inactive flag
      LOGICAL :: is_distorted = .FALSE.           ! Distorted element flag
      LOGICAL :: is_deleted = .FALSE.             ! Deleted element flag
      
  CONTAINS
      PROCEDURE :: Init => MD_Element_Init_Base
      PROCEDURE :: Clean => MD_Element_Clean
      PROCEDURE :: Valid => MD_Element_Valid
      PROCEDURE :: GetConnectivity => MD_Element_GetConnectivity
      PROCEDURE :: SetConnectivity => MD_Element_SetConnectivity
      PROCEDURE :: GetSection => MD_Element_GetSection
      PROCEDURE :: SetSection => MD_Element_SetSection
      PROCEDURE :: GetVolume => MD_Element_GetVolume_Func
      PROCEDURE :: GetArea => MD_Element_GetArea_Func
      PROCEDURE :: GetQuality => MD_Element_GetQuality
      PROCEDURE :: ComputeJacobian => MD_Element_ComputeJacobian
      PROCEDURE :: AddIntegrationPoint => MD_Element_AddIntegrationPoint
      PROCEDURE :: GetIntegrationPoint => MD_Element_GetIntegrationPoint
      PROCEDURE :: AddNeighbor => MD_Element_AddNeighbor
      PROCEDURE :: RemoveNeighbor => MD_Element_RemoveNeighbor
      PROCEDURE :: AddTag => MD_Element_AddTag
      PROCEDURE :: HasTag => MD_Element_HasTag
      PROCEDURE :: GetStatistics => MD_Element_GetStatistics
  END TYPE MD_Element_Type
  
  !=============================================================================
  ! TYPE: MD_Element_State
  ! Purpose: Extended element state with nodal values and IP states
  !=============================================================================
  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_Element_State
      INTEGER(i4) :: element_id = 0_i4           ! Reference to element ID
      
      ! Nodal values
      REAL(wp), ALLOCATABLE :: nodal_displacement(:,:)  ! Nodal displacements (nNodes x 3)
      REAL(wp), ALLOCATABLE :: nodal_velocity(:,:)      ! Nodal velocities
      REAL(wp), ALLOCATABLE :: nodal_acceleration(:,:)  ! Nodal accelerations
      
      ! Element-level values
      REAL(wp) :: element_force(6) = 0.0_wp      ! Element forces/moments
      REAL(wp) :: element_strain_energy = 0.0_wp ! Strain energy
      REAL(wp) :: element_kinetic_energy = 0.0_wp ! Kinetic energy
      
      ! Integration point states (aggregated from IP states)
      REAL(wp), ALLOCATABLE :: ip_stress(:,:)     ! Stress at IPs (num_ip x 6)
      REAL(wp), ALLOCATABLE :: ip_strain(:,:)     ! Strain at IPs (num_ip x 6)
      REAL(wp), ALLOCATABLE :: ip_state_vars(:,:) ! State variables at IPs
      
      ! History variables
      REAL(wp), ALLOCATABLE :: history(:)        ! User-defined history variables
      
  CONTAINS
      PROCEDURE :: Init => MD_ElementState_Init
      PROCEDURE :: Clean => MD_ElementState_Clean
      PROCEDURE :: Update => MD_ElementState_Update
      PROCEDURE :: GetStrainEnergy => MD_ElementState_GetStrainEnergy
      PROCEDURE :: SetStrainEnergy => MD_ElementState_SetStrainEnergy
  END TYPE MD_Element_State
  
  ! Public interfaces from MD_Element.f90
  PUBLIC :: MD_Element_Type, MD_Element_State, MD_IntegrationPoint_Type
  PUBLIC :: MD_Elem_Create, MD_Elem_Destroy
  PUBLIC :: MD_Elem_SetConnectivity, MD_Elem_GetConnectivity
  PUBLIC :: MD_Elem_SetSection, MD_Elem_GetSection
  PUBLIC :: MD_Element_GetVolume, MD_Element_GetArea
  PUBLIC :: MD_Elem_GetStatistics, MD_Elem_Valid
  PUBLIC :: MD_Elem_ComputeJacobian, MD_Elem_GetQuality

CONTAINS

  !=============================================================================
  ! Extended Element Implementation (merged from MD_Element.f90)
  !=============================================================================
  
  SUBROUTINE MD_Element_Init_Base(this)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      CALL DescBase_Init(this)
      this%algo_type_name = 'ELEMENT'
  END SUBROUTINE MD_Element_Init_Base

  SUBROUTINE MD_Element_Init(this, id, elem_type, connectivity, name, status)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: id, elem_type
      INTEGER(i4), INTENT(IN) :: connectivity(:)
      CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      INTEGER(i4) :: nNodes_expected
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      CALL this%Init()
      
      this%cfg%id = id
      this%elem_type = elem_type
      IF (PRESENT(name)) this%name = TRIM(name)
      
      ! Determine expected number of nodes based on element type
      SELECT CASE (elem_type)
      CASE (MD_MESH_ELEMENT_LINE2); nNodes_expected = 2_i4
      CASE (MD_MESH_ELEMENT_LINE3); nNodes_expected = 3_i4
      CASE (MD_MESH_ELEMENT_TRI3); nNodes_expected = 3_i4
      CASE (MD_MESH_ELEMENT_TRI6); nNodes_expected = 6_i4
      CASE (MD_MESH_ELEMENT_QUAD4); nNodes_expected = 4_i4
      CASE (MD_MESH_ELEMENT_QUAD8); nNodes_expected = 8_i4
      CASE (MD_MESH_ELEMENT_TET4); nNodes_expected = 4_i4
      CASE (MD_MESH_ELEMENT_TET10); nNodes_expected = 10_i4
      CASE (MD_MESH_ELEMENT_HEX8); nNodes_expected = 8_i4
      CASE (MD_MESH_ELEMENT_HEX20); nNodes_expected = 20_i4
      CASE DEFAULT; nNodes_expected = SIZE(connectivity)
      END SELECT
      
      IF (SIZE(connectivity) /= nNodes_expected .AND. nNodes_expected > 0) THEN
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = "MD_Element_Init: Connectivity size mismatch"
          END IF
          RETURN
      END IF
      
      this%nNodes = SIZE(connectivity)
      this%connectivity(1:this%nNodes) = connectivity(1:this%nNodes)
      
      IF (ALLOCATED(this%node_ids)) DEALLOCATE(this%node_ids)
      ALLOCATE(this%node_ids(this%nNodes))
      this%node_ids = connectivity(1:this%nNodes)
      
      ! Determine spatial dimension
      SELECT CASE (elem_type)
      CASE (MD_MESH_ELEMENT_TRI3, MD_MESH_ELEMENT_TRI6, MD_MESH_ELEMENT_QUAD4, MD_MESH_ELEMENT_QUAD8)
          this%spatial_dim = 2_i4
      CASE DEFAULT
          this%spatial_dim = 3_i4
      END SELECT
      
      ! Init defaults
      this%section_id = 0_i4
      this%material_id = 0_i4
      this%orientation_id = 0_i4
      this%nIntPoints = 0_i4
      IF (ALLOCATED(this%int_points)) DEALLOCATE(this%int_points)
      
      this%statev_offset = 0_i4
      this%num_state_vars = 0_i4
      
      this%volume = 0.0_wp
      this%area = 0.0_wp
      this%mass = 0.0_wp
      this%thickness = 0.0_wp
      
      this%aspect_ratio = 0.0_wp
      this%skewness = 0.0_wp
      this%jacobian_ratio = 0.0_wp
      this%quality_score = 0.0_wp
      
      this%num_neighbors = 0_i4
      IF (ALLOCATED(this%neighbor_list)) DEALLOCATE(this%neighbor_list)
      
      this%num_tags = 0_i4
      IF (ALLOCATED(this%tags)) DEALLOCATE(this%tags)
      
      this%is_active = .TRUE.
      this%is_distorted = .FALSE.
      this%is_deleted = .FALSE.
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_Init
  
  SUBROUTINE MD_Element_Clean(this)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      
      INTEGER(i4) :: i
      
      IF (ALLOCATED(this%node_ids)) DEALLOCATE(this%node_ids)
      
      IF (ALLOCATED(this%int_points)) THEN
          DO i = 1, SIZE(this%int_points)
              IF (ALLOCATED(this%int_points(i)%state_variables)) &
                  DEALLOCATE(this%int_points(i)%state_variables)
              IF (ALLOCATED(this%int_points(i)%sigma)) &
                  DEALLOCATE(this%int_points(i)%sigma)
              IF (ALLOCATED(this%int_points(i)%strain)) &
                  DEALLOCATE(this%int_points(i)%strain)
          END DO
          DEALLOCATE(this%int_points)
      END IF
      
      IF (ALLOCATED(this%neighbor_list)) DEALLOCATE(this%neighbor_list)
      IF (ALLOCATED(this%tags)) DEALLOCATE(this%tags)
      
      CALL this%DescBase%Clean()
      
  END SUBROUTINE MD_Element_Clean
  
  SUBROUTINE MD_Element_GetConnectivity(this, connectivity, status)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      INTEGER(i4), INTENT(OUT) :: connectivity(:)
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      IF (SIZE(connectivity) < this%nNodes) THEN
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = "MD_Elem_GetConnectivity: Array too small"
          END IF
          RETURN
      END IF
      
      connectivity(1:this%nNodes) = this%connectivity(1:this%nNodes)
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_GetConnectivity
  
  SUBROUTINE MD_Element_SetConnectivity(this, connectivity, status)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: connectivity(:)
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      IF (SIZE(connectivity) > MD_MESH_MAX_NODES_PER_ELEMENT_EXT) THEN
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = "MD_Elem_SetConnectivity: Too many nodes"
          END IF
          RETURN
      END IF
      
      this%nNodes = SIZE(connectivity)
      this%connectivity(1:this%nNodes) = connectivity(1:this%nNodes)
      
      IF (ALLOCATED(this%node_ids)) DEALLOCATE(this%node_ids)
      ALLOCATE(this%node_ids(this%nNodes))
      this%node_ids = connectivity(1:this%nNodes)
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_SetConnectivity
  
  SUBROUTINE MD_Element_GetSection(this, section_id, material_id, orientation_id, status)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      INTEGER(i4), INTENT(OUT) :: section_id, material_id, orientation_id
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      section_id = this%section_id
      material_id = this%material_id
      orientation_id = this%orientation_id
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_GetSection
  
  SUBROUTINE MD_Element_SetSection(this, section_id, material_id, orientation_id, status)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: section_id
      INTEGER(i4), INTENT(IN), OPTIONAL :: material_id, orientation_id
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      this%section_id = section_id
      IF (PRESENT(material_id)) this%material_id = material_id
      IF (PRESENT(orientation_id)) this%orientation_id = orientation_id
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_SetSection
  
  REAL(wp) FUNCTION MD_Element_GetVolume_Func(this) RESULT(volume)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      
      volume = this%volume
      
  END FUNCTION MD_Element_GetVolume_Func
  
  REAL(wp) FUNCTION MD_Element_GetArea_Func(this) RESULT(area)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      
      area = this%area
      
  END FUNCTION MD_Element_GetArea_Func
  
  SUBROUTINE MD_Element_ComputeJacobian(this, node_coords, jacobian, jacobian_det, status)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      REAL(wp), INTENT(IN) :: node_coords(:,:)  ! (nNodes x spatial_dim)
      REAL(wp), INTENT(OUT) :: jacobian(:,:)     ! Jacobian matrix
      REAL(wp), INTENT(OUT) :: jacobian_det
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      INTEGER(i4) :: i
      REAL(wp) :: coords_local(MD_MESH_MAX_NODES_PER_ELEMENT_EXT, 3)
      REAL(wp) :: dN_dxi(MD_MESH_MAX_NODES_PER_ELEMENT_EXT, 3)
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      ! Simplified Jacobian computation
      ! Production code should use proper shape function derivatives
      jacobian = 0.0_wp
      
      SELECT CASE (this%elem_type)
      CASE (MD_MESH_ELEMENT_HEX8)
          ! For HEX8, compute Jacobian at center (?=0, ?=0, ?=0)
          ! Simplified: use finite difference approximation
          jacobian(1,1) = 0.5_wp * (node_coords(2,1) - node_coords(1,1))
          jacobian(2,2) = 0.5_wp * (node_coords(4,1) - node_coords(1,1))
          jacobian(3,3) = 0.5_wp * (node_coords(5,1) - node_coords(1,1))
          jacobian_det = jacobian(1,1) * jacobian(2,2) * jacobian(3,3)
      CASE (MD_MESH_ELEMENT_TET4)
          ! For TET4, compute Jacobian
          jacobian(1,1) = node_coords(2,1) - node_coords(1,1)
          jacobian(1,2) = node_coords(3,1) - node_coords(1,1)
          jacobian(1,3) = node_coords(4,1) - node_coords(1,1)
          jacobian(2,1) = node_coords(2,2) - node_coords(1,2)
          jacobian(2,2) = node_coords(3,2) - node_coords(1,2)
          jacobian(2,3) = node_coords(4,2) - node_coords(1,2)
          jacobian(3,1) = node_coords(2,3) - node_coords(1,3)
          jacobian(3,2) = node_coords(3,3) - node_coords(1,3)
          jacobian(3,3) = node_coords(4,3) - node_coords(1,3)
          ! Determinant computation (simplified)
          jacobian_det = jacobian(1,1) * (jacobian(2,2)*jacobian(3,3) - jacobian(2,3)*jacobian(3,2)) - &
                        jacobian(1,2) * (jacobian(2,1)*jacobian(3,3) - jacobian(2,3)*jacobian(3,1)) + &
                        jacobian(1,3) * (jacobian(2,1)*jacobian(3,2) - jacobian(2,2)*jacobian(3,1))
          jacobian_det = jacobian_det / 6.0_wp  ! Volume scaling
      CASE DEFAULT
          ! Default: identity matrix
          jacobian = 0.0_wp
          DO i = 1, MIN(3, SIZE(jacobian,1))
              jacobian(i,i) = 1.0_wp
          END DO
          jacobian_det = 1.0_wp
      END SELECT
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_ComputeJacobian
  
  SUBROUTINE MD_Element_GetQuality(this, aspect_ratio, skewness, jacobian_ratio, quality_score, status)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      REAL(wp), INTENT(OUT) :: aspect_ratio, skewness, jacobian_ratio, quality_score
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      aspect_ratio = this%aspect_ratio
      skewness = this%skewness
      jacobian_ratio = this%jacobian_ratio
      quality_score = this%quality_score
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_GetQuality
  
  SUBROUTINE MD_Element_AddIntegrationPoint(this, ip_coords_local, ip_weight, status)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      REAL(wp), INTENT(IN) :: ip_coords_local(3)
      REAL(wp), INTENT(IN) :: ip_weight
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      TYPE(MD_IntegrationPoint_Type), ALLOCATABLE :: temp_points(:)
      INTEGER(i4) :: new_ip_id
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      new_ip_id = this%nIntPoints + 1
      
      IF (ALLOCATED(this%int_points)) THEN
          ALLOCATE(temp_points(new_ip_id))
          temp_points(1:this%nIntPoints) = this%int_points
          temp_points(new_ip_id) = MD_IntegrationPoint_Type()
          temp_points(new_ip_id)%ip_id = new_ip_id
          temp_points(new_ip_id)%coords_local = ip_coords_local
          temp_points(new_ip_id)%itr%weight = ip_weight
          temp_points(new_ip_id)%is_active = .TRUE.
          DEALLOCATE(this%int_points)
          this%int_points = temp_points
      ELSE
          ALLOCATE(this%int_points(1))
          this%int_points(1)%ip_id = 1
          this%int_points(1)%coords_local = ip_coords_local
          this%int_points(1)%itr%weight = ip_weight
          this%int_points(1)%is_active = .TRUE.
      END IF
      
      this%nIntPoints = new_ip_id
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_AddIntegrationPoint
  
  SUBROUTINE MD_Element_GetIntegrationPoint(this, ip_id, ip_point, status)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      INTEGER(i4), INTENT(IN) :: ip_id
      TYPE(MD_IntegrationPoint_Type), INTENT(OUT) :: ip_point
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      IF (.NOT. ALLOCATED(this%int_points) .OR. ip_id < 1 .OR. ip_id > this%nIntPoints) THEN
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_NOT_FOUND
              status%message = "MD_Element_GetIntegrationPoint: IP not found"
          END IF
          RETURN
      END IF
      
      ip_point = this%int_points(ip_id)
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_GetIntegrationPoint
  
  SUBROUTINE MD_Element_AddNeighbor(this, neighbor_id, status)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: neighbor_id
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      INTEGER(i4), ALLOCATABLE :: temp_list(:)
      INTEGER(i4) :: i
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      ! Check if already in list
      IF (ALLOCATED(this%neighbor_list)) THEN
          DO i = 1, this%num_neighbors
              IF (this%neighbor_list(i) == neighbor_id) THEN
                  IF (PRESENT(status)) status%status_code = IF_STATUS_OK
                  RETURN
              END IF
          END DO
      END IF
      
      ! Add to list
      this%num_neighbors = this%num_neighbors + 1
      IF (ALLOCATED(this%neighbor_list)) THEN
          ALLOCATE(temp_list(this%num_neighbors))
          temp_list(1:this%num_neighbors-1) = this%neighbor_list
          temp_list(this%num_neighbors) = neighbor_id
          DEALLOCATE(this%neighbor_list)
          this%neighbor_list = temp_list
      ELSE
          ALLOCATE(this%neighbor_list(1))
          this%neighbor_list(1) = neighbor_id
      END IF
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_AddNeighbor
  
  SUBROUTINE MD_Element_RemoveNeighbor(this, neighbor_id, status)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: neighbor_id
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      INTEGER(i4), ALLOCATABLE :: temp_list(:)
      INTEGER(i4) :: i, j
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      IF (.NOT. ALLOCATED(this%neighbor_list) .OR. this%num_neighbors == 0) THEN
          IF (PRESENT(status)) status%status_code = IF_STATUS_NOT_FOUND
          RETURN
      END IF
      
      ! Find and remove
      j = 0
      DO i = 1, this%num_neighbors
          IF (this%neighbor_list(i) /= neighbor_id) THEN
              j = j + 1
              IF (j < i) this%neighbor_list(j) = this%neighbor_list(i)
          END IF
      END DO
      
      IF (j < this%num_neighbors) THEN
          this%num_neighbors = j
          IF (j > 0) THEN
              ALLOCATE(temp_list(j))
              temp_list = this%neighbor_list(1:j)
              DEALLOCATE(this%neighbor_list)
              this%neighbor_list = temp_list
          ELSE
              DEALLOCATE(this%neighbor_list)
          END IF
          IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      ELSE
          IF (PRESENT(status)) status%status_code = IF_STATUS_NOT_FOUND
      END IF
      
  END SUBROUTINE MD_Element_RemoveNeighbor
  
  SUBROUTINE MD_Element_AddTag(this, tag, status)
      CLASS(MD_Element_Type), INTENT(INOUT) :: this
      CHARACTER(LEN=*), INTENT(IN) :: tag
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CHARACTER(LEN=MD_MESH_MAX_ELEMENT_NAME), ALLOCATABLE :: temp_tags(:)
      INTEGER(i4) :: i
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      ! Check if already exists
      IF (ALLOCATED(this%tags)) THEN
          DO i = 1, this%num_tags
              IF (TRIM(this%tags(i)) == TRIM(tag)) THEN
                  IF (PRESENT(status)) status%status_code = IF_STATUS_OK
                  RETURN
              END IF
          END DO
      END IF
      
      ! Add tag
      this%num_tags = this%num_tags + 1
      IF (ALLOCATED(this%tags)) THEN
          ALLOCATE(temp_tags(this%num_tags))
          temp_tags(1:this%num_tags-1) = this%tags
          temp_tags(this%num_tags) = TRIM(tag)
          DEALLOCATE(this%tags)
          this%tags = temp_tags
      ELSE
          ALLOCATE(this%tags(1))
          this%tags(1) = TRIM(tag)
      END IF
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_AddTag
  
  LOGICAL FUNCTION MD_Element_HasTag(this, tag) RESULT(has_tag)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      CHARACTER(LEN=*), INTENT(IN) :: tag
      
      INTEGER(i4) :: i
      
      has_tag = .FALSE.
      
      IF (ALLOCATED(this%tags)) THEN
          DO i = 1, this%num_tags
              IF (TRIM(this%tags(i)) == TRIM(tag)) THEN
                  has_tag = .TRUE.
                  RETURN
              END IF
          END DO
      END IF
      
  END FUNCTION MD_Element_HasTag
  
  FUNCTION MD_Element_Valid(this) RESULT(ok)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      LOGICAL :: ok
      ok = (this%cfg%id > 0) .AND. (this%elem_type /= MD_MESH_ELEMENT_UNKNOWN) .AND. (this%nNodes > 0)
  END FUNCTION MD_Element_Valid
  
  SUBROUTINE MD_Element_GetStatistics(this, stats, status)
      CLASS(MD_Element_Type), INTENT(IN) :: this
      CHARACTER(LEN=512), INTENT(OUT) :: stats
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      WRITE(stats, '(A,I0,A,I0,A,I0,A,I0,A,ES12.5,A,L1)') &
          'Element Statistics: id=', this%cfg%id, &
          ', type=', this%elem_type, &
          ', nNodes=', this%nNodes, &
          ', nIntPoints=', this%nIntPoints, &
          ', volume=', this%volume, &
          ', is_active=', this%is_active
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Element_GetStatistics
  
  SUBROUTINE MD_Elem_Create(element, id, elem_type, connectivity, name, status)
      TYPE(MD_Element_Type), INTENT(OUT) :: element
      INTEGER(i4), INTENT(IN) :: id, elem_type
      INTEGER(i4), INTENT(IN) :: connectivity(:)
      CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CALL element%Init(id, elem_type, connectivity, name, status)
      
  END SUBROUTINE MD_Elem_Create
  
  SUBROUTINE MD_Elem_Destroy(element, status)
      TYPE(MD_Element_Type), INTENT(INOUT) :: element
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      CALL element%Clean()
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_Elem_Destroy
  
  SUBROUTINE MD_Elem_SetConnectivity(element, connectivity, status)
      TYPE(MD_Element_Type), INTENT(INOUT) :: element
      INTEGER(i4), INTENT(IN) :: connectivity(:)
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CALL element%SetConnectivity(connectivity, status)
      
  END SUBROUTINE MD_Elem_SetConnectivity
  
  SUBROUTINE MD_Elem_GetConnectivity(element, connectivity, status)
      TYPE(MD_Element_Type), INTENT(IN) :: element
      INTEGER(i4), INTENT(OUT) :: connectivity(:)
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CALL element%GetConnectivity(connectivity, status)
      
  END SUBROUTINE MD_Elem_GetConnectivity
  
  SUBROUTINE MD_Elem_SetSection(element, section_id, material_id, orientation_id, status)
      TYPE(MD_Element_Type), INTENT(INOUT) :: element
      INTEGER(i4), INTENT(IN) :: section_id
      INTEGER(i4), INTENT(IN), OPTIONAL :: material_id, orientation_id
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CALL element%SetSection(section_id, material_id, orientation_id, status)
      
  END SUBROUTINE MD_Elem_SetSection
  
  SUBROUTINE MD_Elem_GetSection(element, section_id, material_id, orientation_id, status)
      TYPE(MD_Element_Type), INTENT(IN) :: element
      INTEGER(i4), INTENT(OUT) :: section_id, material_id, orientation_id
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CALL element%GetSection(section_id, material_id, orientation_id, status)
      
  END SUBROUTINE MD_Elem_GetSection
  
  REAL(wp) FUNCTION MD_Element_GetVolume(element) RESULT(volume)
      TYPE(MD_Element_Type), INTENT(IN) :: element
      
      volume = element%GetVolume()
      
  END FUNCTION MD_Element_GetVolume
  
  REAL(wp) FUNCTION MD_Element_GetArea(element) RESULT(area)
      TYPE(MD_Element_Type), INTENT(IN) :: element
      
      area = element%GetArea()
      
  END FUNCTION MD_Element_GetArea
  
  SUBROUTINE MD_Elem_ComputeJacobian(element, node_coords, jacobian, jacobian_det, status)
      TYPE(MD_Element_Type), INTENT(IN) :: element
      REAL(wp), INTENT(IN) :: node_coords(:,:)
      REAL(wp), INTENT(OUT) :: jacobian(:,:)
      REAL(wp), INTENT(OUT) :: jacobian_det
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CALL element%ComputeJacobian(node_coords, jacobian, jacobian_det, status)
      
  END SUBROUTINE MD_Elem_ComputeJacobian
  
  SUBROUTINE MD_Elem_GetQuality(element, aspect_ratio, skewness, jacobian_ratio, quality_score, status)
      TYPE(MD_Element_Type), INTENT(IN) :: element
      REAL(wp), INTENT(OUT) :: aspect_ratio, skewness, jacobian_ratio, quality_score
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CALL element%GetQuality(aspect_ratio, skewness, jacobian_ratio, quality_score, status)
      
  END SUBROUTINE MD_Elem_GetQuality
  
  SUBROUTINE MD_Elem_GetStatistics(element, stats, status)
      TYPE(MD_Element_Type), INTENT(IN) :: element
      CHARACTER(LEN=512), INTENT(OUT) :: stats
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      CALL element%GetStatistics(stats, status)
      
  END SUBROUTINE MD_Elem_GetStatistics
  
  SUBROUTINE MD_Elem_Valid(element, status)
      TYPE(MD_Element_Type), INTENT(IN) :: element
      TYPE(ErrorStatusType), INTENT(OUT) :: status
      
      CALL init_error_status(status)
      IF (.NOT. element%Valid()) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "MD_Elem_Valid: Element validation failed"
      ELSE
          status%status_code = IF_STATUS_OK
      END IF
      
  END SUBROUTINE MD_Elem_Valid
  
  SUBROUTINE MD_ElementState_Init(this, element_id, nNodes, nIntPoints, status)
      CLASS(MD_Element_State), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: element_id
      INTEGER(i4), INTENT(IN) :: nNodes, nIntPoints
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      CALL this%StateBase%Init('MD_MESH_ELEMENT_STATE', CAT_STATE)
      
      this%element_id = element_id
      
      ALLOCATE(this%nodal_displacement(nNodes, 3))
      ALLOCATE(this%nodal_velocity(nNodes, 3))
      ALLOCATE(this%nodal_acceleration(nNodes, 3))
      this%nodal_displacement = 0.0_wp
      this%nodal_velocity = 0.0_wp
      this%nodal_acceleration = 0.0_wp
      
      this%element_force = 0.0_wp
      this%element_strain_energy = 0.0_wp
      this%element_kinetic_energy = 0.0_wp
      
      IF (nIntPoints > 0) THEN
          ALLOCATE(this%ip_stress(nIntPoints, 6))
          ALLOCATE(this%ip_strain(nIntPoints, 6))
          ! Note: num_state_vars is not available in MD_Element_State, using default size of 1
          ALLOCATE(this%ip_state_vars(nIntPoints, 1))
          this%ip_stress = 0.0_wp
          this%ip_strain = 0.0_wp
          this%ip_state_vars = 0.0_wp
      END IF
      
      IF (ALLOCATED(this%history)) DEALLOCATE(this%history)
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_ElementState_Init
  
  SUBROUTINE MD_ElementState_Clean(this)
      CLASS(MD_Element_State), INTENT(INOUT) :: this
      
      IF (ALLOCATED(this%nodal_displacement)) DEALLOCATE(this%nodal_displacement)
      IF (ALLOCATED(this%nodal_velocity)) DEALLOCATE(this%nodal_velocity)
      IF (ALLOCATED(this%nodal_acceleration)) DEALLOCATE(this%nodal_acceleration)
      IF (ALLOCATED(this%ip_stress)) DEALLOCATE(this%ip_stress)
      IF (ALLOCATED(this%ip_strain)) DEALLOCATE(this%ip_strain)
      IF (ALLOCATED(this%ip_state_vars)) DEALLOCATE(this%ip_state_vars)
      IF (ALLOCATED(this%history)) DEALLOCATE(this%history)
      
      CALL this%StateBase%Clean()
      
  END SUBROUTINE MD_ElementState_Clean
  
  SUBROUTINE MD_ElementState_Update(this, dt, status)
      CLASS(MD_Element_State), INTENT(INOUT) :: this
      REAL(wp), INTENT(IN) :: dt
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      ! Update nodal displacements: u_new = u_old + v*dt + 0.5*a*dt^2
      this%nodal_displacement = this%nodal_displacement + &
          this%nodal_velocity * dt + HALF * this%nodal_acceleration * dt * dt
      
      ! Update nodal velocities: v_new = v_old + a*dt
      this%nodal_velocity = this%nodal_velocity + this%nodal_acceleration * dt
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_ElementState_Update
  
  REAL(wp) FUNCTION MD_ElementState_GetStrainEnergy(this) RESULT(strain_energy)
      CLASS(MD_Element_State), INTENT(IN) :: this
      
      strain_energy = this%element_strain_energy
      
  END FUNCTION MD_ElementState_GetStrainEnergy
  
  SUBROUTINE MD_ElementState_SetStrainEnergy(this, strain_energy, status)
      CLASS(MD_Element_State), INTENT(INOUT) :: this
      REAL(wp), INTENT(IN) :: strain_energy
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
      
      IF (PRESENT(status)) CALL init_error_status(status)
      
      this%element_strain_energy = strain_energy
      
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      
  END SUBROUTINE MD_ElementState_SetStrainEnergy

END MODULE MD_Elem_Mgr
