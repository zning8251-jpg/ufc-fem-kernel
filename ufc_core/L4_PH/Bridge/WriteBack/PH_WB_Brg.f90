!===============================================================================
! MODULE: PH_WB_Brg
! LAYER:  L4_PH
! DOMAIN: WriteBack
! ROLE:   Brg [DEPRECATED — migrated to L4_PH/WriteBack/PH_WB_Def.f90 + Core]
! BRIEF:  Legacy bridge kept for backward compatibility.
!
! DEPRECATED (Phase 6): The authoritative L4 WriteBack types now live in
!   L4_PH/WriteBack/PH_WB_Def.f90 (four-type definitions) and
!   L4_PH/WriteBack/PH_WB_Core.f90 (format preparation engine).
!   This file kept for backward compat — new code should USE PH_WB_Def directly.
!===============================================================================

MODULE PH_WB_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE PH_WB_Mgr, ONLY: PH_WriteBack_Desc, PH_WriteBack_State, &
                               PH_WriteBack_Args, PH_WriteBack_NodeDisp, &
                               PH_WriteBack_NodeVel, PH_WriteBack_NodeAccel, &
                               PH_WriteBack_ElemStress, PH_WriteBack_ElemStrain
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_WriteBack_ApplyNodeDisp, PH_WriteBack_ApplyNodeVel
  PUBLIC :: PH_WriteBack_ApplyNodeAccel, PH_WriteBack_ApplyNodePos
  PUBLIC :: PH_WriteBack_ApplyElemStress, PH_WriteBack_ApplyElemStrain
  
CONTAINS
  
  ! ==========================================================================
  ! PUBLIC API: Node Write-Back Operations
  ! ==========================================================================
  
  SUBROUTINE PH_WriteBack_ApplyNodeDisp(node_idx, disp, status)
    !! Apply nodal displacement write-back (thin wrapper)
    !! @param[in] node_idx Node index
    !! @param[in] disp Displacement vector (3 components)
    !! @param[out] status Error status
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: disp(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_WriteBack_NodeDisp(node_idx, disp, status)
  END SUBROUTINE PH_WriteBack_ApplyNodeDisp
  
  SUBROUTINE PH_WriteBack_ApplyNodeVel(node_idx, vel, status)
    !! Apply nodal velocity write-back (thin wrapper)
    !! @param[in] node_idx Node index
    !! @param[in] vel Velocity vector (3 components)
    !! @param[out] status Error status
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: vel(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_WriteBack_NodeVel(node_idx, vel, status)
  END SUBROUTINE PH_WriteBack_ApplyNodeVel
  
  SUBROUTINE PH_WriteBack_ApplyNodeAccel(node_idx, accel, status)
    !! Apply nodal acceleration write-back (thin wrapper)
    !! @param[in] node_idx Node index
    !! @param[in] accel Acceleration vector (3 components)
    !! @param[out] status Error status
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: accel(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_WriteBack_NodeAccel(node_idx, accel, status)
  END SUBROUTINE PH_WriteBack_ApplyNodeAccel
  
  SUBROUTINE PH_WriteBack_ApplyNodePos(node_idx, coords, status)
    !! Apply nodal position write-back (thin wrapper)
    !! @param[in] node_idx Node index
    !! @param[in] coords Coordinate vector (3 components)
    !! @param[out] status Error status
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: coords(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_WriteBack_NodePos(node_idx, coords, status)
  END SUBROUTINE PH_WriteBack_ApplyNodePos
  
  ! ==========================================================================
  ! PUBLIC API: Element Write-Back Operations
  ! ==========================================================================
  
  SUBROUTINE PH_WriteBack_ApplyElemStress(elem_idx, ip_idx, stress, status)
    !! Apply element stress write-back (thin wrapper)
    !! @param[in] elem_idx Element index
    !! @param[in] ip_idx Integration point index
    !! @param[in] stress Stress tensor (6 components, Voigt notation)
    !! @param[out] status Error status
    INTEGER(i4), INTENT(IN) :: elem_idx, ip_idx
    REAL(wp), INTENT(IN) :: stress(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_WriteBack_ElemStress(elem_idx, ip_idx, stress, status)
  END SUBROUTINE PH_WriteBack_ApplyElemStress
  
  SUBROUTINE PH_WriteBack_ApplyElemStrain(elem_idx, ip_idx, strain, status)
    !! Apply element strain write-back (thin wrapper)
    !! @param[in] elem_idx Element index
    !! @param[in] ip_idx Integration point index
    !! @param[in] strain Strain tensor (6 components, Voigt notation)
    !! @param[out] status Error status
    INTEGER(i4), INTENT(IN) :: elem_idx, ip_idx
    REAL(wp), INTENT(IN) :: strain(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL PH_WriteBack_ElemStrain(elem_idx, ip_idx, strain, status)
  END SUBROUTINE PH_WriteBack_ApplyElemStrain
  
END MODULE PH_WB_Brg
