!===============================================================================
! MODULE: PH_Elem_StructuralFacade
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  `family_id` 分类助手�与 `PH_ElemReg_Algo` ?PH_ELEM_FAMILY_* �致�?!          �?Domain /
!===============================================================================
MODULE PH_Elem_StructuralFacade
  USE IF_Prec_Core, ONLY: i4
  USE PH_Elem_Reg, ONLY: PH_ELEM_FAMILY_SOLID_3D, PH_ELEM_FAMILY_SOLID_2D, PH_ELEM_FAMILY_SHELL, &
       PH_ELEM_FAMILY_BEAM, PH_ELEM_FAMILY_TRUSS, PH_ELEM_FAMILY_OTHER
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Element_Family_Is3DContinuum
  PUBLIC :: PH_Element_Family_Is2DContinuum
  PUBLIC :: PH_Element_Family_IsShellBeamTruss
  PUBLIC :: PH_Element_Family_IsFieldOrCouplingBucket

CONTAINS

  !> 3D 实体连续体（C3D*?  PURE FUNCTION PH_Element_Family_Is3DContinuum(family_id) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: family_id
    LOGICAL :: ok
    ok = (family_id == PH_ELEM_FAMILY_SOLID_3D)
  END FUNCTION PH_Element_Family_Is3DContinuum

  !> 2D 连续体（CPE/CPS/CAX?  PURE FUNCTION PH_Element_Family_Is2DContinuum(family_id) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: family_id
    LOGICAL :: ok
    ok = (family_id == PH_ELEM_FAMILY_SOLID_2D)
  END FUNCTION PH_Element_Family_Is2DContinuum

  !> �?/ �?/ 桁（力学�自由度�截面或膜层等效 D�不用纯 npe×ndim 体元分支?  PURE FUNCTION PH_Element_Family_IsShellBeamTruss(family_id) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: family_id
    LOGICAL :: ok
    ok = (family_id == PH_ELEM_FAMILY_SHELL .OR. family_id == PH_ELEM_FAMILY_BEAM .OR. &
         family_id == PH_ELEM_FAMILY_TRUSS)
  END FUNCTION PH_Element_Family_IsShellBeamTruss

  !> �它桶：膜、声、扩散、耦合�用单元等（**�得**默认�?`C_tan(6×6)` 体元核）
  PURE FUNCTION PH_Element_Family_IsFieldOrCouplingBucket(family_id) RESULT(ok)
    INTEGER(i4), INTENT(IN) :: family_id
    LOGICAL :: ok
    ok = (family_id == PH_ELEM_FAMILY_OTHER)
  END FUNCTION PH_Element_Family_IsFieldOrCouplingBucket

END MODULE PH_Elem_StructuralFacade