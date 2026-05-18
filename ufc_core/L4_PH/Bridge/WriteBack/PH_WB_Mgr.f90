!===============================================================================
! MODULE: PH_WB_Mgr
! LAYER:  L4_PH
! DOMAIN: WriteBack
! ROLE:   Mgr
! BRIEF:  WriteBack physics core (node disp/vel/accel, elem stress/strain to L3_MD)
!
! Four-Type: PH_WriteBack_Desc (Desc), PH_WriteBack_State (State),
!            PH_WriteBack_Args (Ctx/Arg bundle)
! Status: ACTIVE | AUTHORITY | Last verified: 2026-04-28
!===============================================================================

MODULE PH_WB_Mgr
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE MD_Mesh_Proc, ONLY: MD_Mesh_NodePos, MD_Mesh_NodeDisp, MD_Mesh_NodeVel, &
                          MD_Mesh_NodeAccel
  USE MD_WB_Brg, ONLY: MD_WB_Mesh_NodePos, MD_WB_Mesh_NodeDisp, &
                              MD_WB_Mesh_NodeVel, MD_WB_Mesh_NodeAccel, &
                              MD_WB_Mesh_ElemStress, MD_WB_Mesh_ElemStrain
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_WriteBack_Desc, PH_WriteBack_State, PH_WriteBack_Args
  PUBLIC :: PH_WriteBack_NodeDisp, PH_WriteBack_NodeVel, PH_WriteBack_NodeAccel
  PUBLIC :: PH_WriteBack_NodePos, PH_WriteBack_ElemStress, PH_WriteBack_ElemStrain
  
  ! ==========================================================================
  ! TYPE: PH_WriteBack_Desc (Category: Desc - immutable configuration)
  ! ==========================================================================
  TYPE, PUBLIC :: PH_WriteBack_Desc
    LOGICAL :: write_disp = .TRUE.      ! Output displacement flag
    LOGICAL :: write_vel = .FALSE.      ! Output velocity flag (dynamic only)
    LOGICAL :: write_accel = .FALSE.    ! Output acceleration flag (dynamic only)
    LOGICAL :: write_stress = .TRUE.    ! Output stress flag
    LOGICAL :: write_strain = .TRUE.    ! Output strain flag
    INTEGER(i4) :: output_freq = 1_i4   ! Output frequency (every N increments)
    CHARACTER(LEN=256) :: output_dir = "" ! Output directory path
  CONTAINS
    PROCEDURE :: Init => PH_WriteBack_Desc_Init
    PROCEDURE :: Validate => PH_WriteBack_Desc_Validate
  END TYPE PH_WriteBack_Desc
  
  ! ==========================================================================
  ! TYPE: PH_WriteBack_State (Category: State - runtime dynamic data)
  ! ==========================================================================
  TYPE, PUBLIC :: PH_WriteBack_State
    INTEGER(i4) :: total_nodes = 0_i4         ! Total nodes written
    INTEGER(i4) :: total_elements = 0_i4      ! Total elements written
    INTEGER(i4) :: current_increment = 0_i4   ! Current increment counter
    REAL(wp), ALLOCATABLE :: disp_buffer(:,:) ! Displacement buffer (3, nnodes)
    REAL(wp), ALLOCATABLE :: stress_buffer(:,:) ! Stress buffer (6, nelems)
    REAL(wp), ALLOCATABLE :: strain_buffer(:,:) ! Strain buffer (6, nelems)
  CONTAINS
    PROCEDURE :: Init => PH_WriteBack_State_Init
    PROCEDURE :: Finalize => PH_WriteBack_State_Finalize
    PROCEDURE :: Reset => PH_WriteBack_State_Reset
  END TYPE PH_WriteBack_State
  
  ! ==========================================================================
  ! TYPE: PH_WriteBack_Args (Category: Ctx - temporary context)
  ! ==========================================================================
  TYPE, PUBLIC :: PH_WriteBack_Args
    INTEGER(i4) :: node_idx = 0_i4          ! Node index
    INTEGER(i4) :: elem_idx = 0_i4          ! Element index
    INTEGER(i4) :: ip_idx = 0_i4            ! Integration point index
    REAL(wp) :: disp(3) = 0.0_wp            ! Displacement vector
    REAL(wp) :: vel(3) = 0.0_wp             ! Velocity vector
    REAL(wp) :: accel(3) = 0.0_wp           ! Acceleration vector
    REAL(wp) :: stress(6) = 0.0_wp          ! Stress tensor (Voigt notation)
    REAL(wp) :: strain(6) = 0.0_wp          ! Strain tensor (Voigt notation)
    TYPE(ErrorStatusType) :: status         ! Error status
  END TYPE PH_WriteBack_Args
  
CONTAINS
  
  ! ==========================================================================
  ! PH_WriteBack_Desc PROCEDURES
  ! ==========================================================================
  
  SUBROUTINE PH_WriteBack_Desc_Init(this)
    CLASS(PH_WriteBack_Desc), INTENT(INOUT) :: this
    
    this%write_disp = .TRUE.
    this%write_vel = .FALSE.
    this%write_accel = .FALSE.
    this%write_stress = .TRUE.
    this%write_strain = .TRUE.
    this%output_freq = 1_i4
    this%output_dir = ""
  END SUBROUTINE PH_WriteBack_Desc_Init
  
  FUNCTION PH_WriteBack_Desc_Validate(this) RESULT(is_valid)
    CLASS(PH_WriteBack_Desc), INTENT(IN) :: this
    LOGICAL :: is_valid
    
    is_valid = .TRUE.
    ! At least one output variable must be enabled
    IF (.NOT. (this%write_disp .OR. this%write_vel .OR. &
               this%write_accel .OR. this%write_stress .OR. &
               this%write_strain)) THEN
      is_valid = .FALSE.
    END IF
    
    ! Output frequency must be positive
    IF (this%output_freq <= 0_i4) THEN
      is_valid = .FALSE.
    END IF
  END FUNCTION PH_WriteBack_Desc_Validate
  
  ! ==========================================================================
  ! PH_WriteBack_State PROCEDURES
  ! ==========================================================================
  
  SUBROUTINE PH_WriteBack_State_Init(this, nnodes, nelems)
    CLASS(PH_WriteBack_State), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: nnodes, nelems
    
    this%total_nodes = 0_i4
    this%total_elements = 0_i4
    this%current_increment = 0_i4
    
    IF (ALLOCATED(this%disp_buffer)) DEALLOCATE(this%disp_buffer)
    IF (ALLOCATED(this%stress_buffer)) DEALLOCATE(this%stress_buffer)
    IF (ALLOCATED(this%strain_buffer)) DEALLOCATE(this%strain_buffer)
    
    ALLOCATE(this%disp_buffer(3, nnodes))
    ALLOCATE(this%stress_buffer(6, nelems))
    ALLOCATE(this%strain_buffer(6, nelems))
    
    this%disp_buffer = 0.0_wp
    this%stress_buffer = 0.0_wp
    this%strain_buffer = 0.0_wp
  END SUBROUTINE PH_WriteBack_State_Init
  
  SUBROUTINE PH_WriteBack_State_Finalize(this)
    CLASS(PH_WriteBack_State), INTENT(INOUT) :: this
    
    IF (ALLOCATED(this%disp_buffer)) DEALLOCATE(this%disp_buffer)
    IF (ALLOCATED(this%stress_buffer)) DEALLOCATE(this%stress_buffer)
    IF (ALLOCATED(this%strain_buffer)) DEALLOCATE(this%strain_buffer)
    
    this%total_nodes = 0_i4
    this%total_elements = 0_i4
    this%current_increment = 0_i4
  END SUBROUTINE PH_WriteBack_State_Finalize
  
  SUBROUTINE PH_WriteBack_State_Reset(this)
    CLASS(PH_WriteBack_State), INTENT(INOUT) :: this
    
    this%total_nodes = 0_i4
    this%total_elements = 0_i4
    this%current_increment = 0_i4
    
    IF (ALLOCATED(this%disp_buffer)) this%disp_buffer = 0.0_wp
    IF (ALLOCATED(this%stress_buffer)) this%stress_buffer = 0.0_wp
    IF (ALLOCATED(this%strain_buffer)) this%strain_buffer = 0.0_wp
  END SUBROUTINE PH_WriteBack_State_Reset
  
  ! ==========================================================================
  ! PHYSICAL WRITE-BACK OPERATIONS (L4_PH -> L3_MD)
  ! ==========================================================================
  
  SUBROUTINE PH_WriteBack_NodeDisp(node_idx, disp, status)
    !! Write nodal displacement to L3_MD container
    !! Pure physical computation - no scheduling or IO
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: disp(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Call L3_MD API to update nodal displacement
    CALL MD_WB_Mesh_NodeDisp(node_idx, disp, status)
    
    IF (status%status_code /= IF_STATUS_OK) THEN
      WRITE(status%message, '(A,I0,A)') &
        'PH_WriteBack: Failed to write displacement for node ', node_idx
    END IF
  END SUBROUTINE PH_WriteBack_NodeDisp
  
  SUBROUTINE PH_WriteBack_NodeVel(node_idx, vel, status)
    !! Write nodal velocity to L3_MD container
    !! Pure physical computation - no scheduling or IO
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: vel(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Call L3_MD API to update nodal velocity
    CALL MD_WB_Mesh_NodeVel(node_idx, vel, status)
    
    IF (status%status_code /= IF_STATUS_OK) THEN
      WRITE(status%message, '(A,I0,A)') &
        'PH_WriteBack: Failed to write velocity for node ', node_idx
    END IF
  END SUBROUTINE PH_WriteBack_NodeVel
  
  SUBROUTINE PH_WriteBack_NodePos(node_idx, coords, status)
    !! Write nodal position (coordinates) to L3_MD container
    !! Pure physical computation - no scheduling or IO
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: coords(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Call L3_MD API to update nodal coordinates
    CALL MD_WB_Mesh_NodePos(node_idx, coords, status)
    
    IF (status%status_code /= IF_STATUS_OK) THEN
      WRITE(status%message, '(A,I0,A)') &
        'PH_WriteBack: Failed to write coordinates for node ', node_idx
    END IF
  END SUBROUTINE PH_WriteBack_NodePos
  
  SUBROUTINE PH_WriteBack_NodeAccel(node_idx, accel, status)
    !! Write nodal acceleration to L3_MD container
    !! Pure physical computation - no scheduling or IO
    INTEGER(i4), INTENT(IN) :: node_idx
    REAL(wp), INTENT(IN) :: accel(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Call L3_MD API to update nodal acceleration
    CALL MD_WB_Mesh_NodeAccel(node_idx, accel, status)
    
    IF (status%status_code /= IF_STATUS_OK) THEN
      WRITE(status%message, '(A,I0,A)') &
        'PH_WriteBack: Failed to write acceleration for node ', node_idx
    END IF
  END SUBROUTINE PH_WriteBack_NodeAccel
  
  SUBROUTINE PH_WriteBack_ElemStress(elem_idx, ip_idx, stress, status)
    !! Write element stress to L3_MD container
    !! Pure physical computation - no scheduling or IO
    INTEGER(i4), INTENT(IN) :: elem_idx, ip_idx
    REAL(wp), INTENT(IN) :: stress(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Call L3_MD API to update element stress
    CALL MD_WB_Mesh_ElemStress(elem_idx, ip_idx, stress, status)
    
    IF (status%status_code /= IF_STATUS_OK) THEN
      WRITE(status%message, '(A,I0,A,I0,A)') &
        'PH_WriteBack: Failed to write stress for element ', elem_idx, &
        ' IP ', ip_idx
    END IF
  END SUBROUTINE PH_WriteBack_ElemStress
  
  SUBROUTINE PH_WriteBack_ElemStrain(elem_idx, ip_idx, strain, status)
    !! Write element strain to L3_MD container
    !! Pure physical computation - no scheduling or IO
    INTEGER(i4), INTENT(IN) :: elem_idx, ip_idx
    REAL(wp), INTENT(IN) :: strain(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Call L3_MD API to update element strain
    CALL MD_WB_Mesh_ElemStrain(elem_idx, ip_idx, strain, status)
    
    IF (status%status_code /= IF_STATUS_OK) THEN
      WRITE(status%message, '(A,I0,A,I0,A)') &
        'PH_WriteBack: Failed to write strain for element ', elem_idx, &
        ' IP ', ip_idx
    END IF
  END SUBROUTINE PH_WriteBack_ElemStrain
  
END MODULE PH_WB_Mgr