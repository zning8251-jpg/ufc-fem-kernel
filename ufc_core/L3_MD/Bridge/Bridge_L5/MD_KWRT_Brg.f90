!===============================================================================
! MODULE: MD_KWRT_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — KeyWord L3→L5 bridge
! BRIEF:  Forward solver-keyword parsing (AST→Properties) to L5_RT parsers.
!===============================================================================


MODULE MD_KWRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Solver_ComplexFrequency_Parse, ONLY: Parse_COMPLEX_FREQUENCY_Keyword
  USE RT_Solver_ComplexFrequency_Type, ONLY: ComplexFrequencyProperties
  USE RT_Solver_Direct_Parse, ONLY: Parse_DIRECT_Keyword
  USE RT_Solver_Direct_Type, ONLY: DirectProperties
  USE RT_Solver_ModalDamping_Parse, ONLY: Parse_MODAL_DAMPING_Keyword
  USE RT_Solver_ModalDamping_Type, ONLY: ModalDampingProperties
  USE RT_Solver_ModalDynamic_Parse, ONLY: Parse_MODAL_DYNAMIC_Keyword
  USE RT_Solver_ModalDynamic_Type, ONLY: ModalDynamicProperties
  USE RT_Solver_ResponseSpectrum_Parse, ONLY: Parse_RESPONSE_SPECTRUM_Keyword
  USE RT_Solver_ResponseSpectrum_Type, ONLY: ResponseSpectrumProperties
  USE RT_Solver_SteadyState_Parse, ONLY: Parse_STEADY_STATE_DYNAMICS_Keyword
  USE RT_Solver_SteadyState_Type, ONLY: SteadyStateProperties
  USE RT_Solver_Substructure_Parse, ONLY: Parse_SUBSTRUCTURE_Keyword
  USE RT_Solver_Substructure_Type, ONLY: SubstructureProperties
  USE RT_Solv_Riks_Parse, ONLY: Parse_STATIC_RIKS_Keyword
  USE RT_Solv_Riks_Type, ONLY: RiksSolverConfig, RiksSolverConfig_To_UF_RiksControl
  USE MD_Step_Proc, ONLY: UF_RiksControl
  IMPLICIT NONE
  PRIVATE
  
  ! --- Re-exported RT solver property types ---
  PUBLIC :: ComplexFrequencyProperties, DirectProperties, ModalDampingProperties, &
            ModalDynamicProperties, ResponseSpectrumProperties, &
            SteadyStateProperties, SubstructureProperties
  
  ! --- Bridge procedures ---
  
  PUBLIC :: MD_RT_KW_ParseComplexFrequency
  PUBLIC :: MD_RT_KW_ParseDirect
  PUBLIC :: MD_RT_KW_ParseModalDamping
  PUBLIC :: MD_RT_KW_ParseModalDynamic
  PUBLIC :: MD_RT_KW_ParseResponseSpectrum
  PUBLIC :: MD_RT_KW_ParseSteadyState
  PUBLIC :: MD_RT_KW_ParseSubstructure
  PUBLIC :: MD_RT_KW_ParseStaticRiks

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_KW_ParseComplexFrequency
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Parse COMPLEX_FREQUENCY keyword (bridge → RT parser).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_KW_ParseComplexFrequency(node, props, status)
    USE MD_KW, ONLY: KW_ASTNodeType
    TYPE(KW_ASTNodeType), INTENT(IN) :: node
    TYPE(ComplexFrequencyProperties), INTENT(OUT) :: props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL Parse_COMPLEX_FREQUENCY_Keyword(node, props, status)
    
  END SUBROUTINE MD_RT_KW_ParseComplexFrequency

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_KW_ParseDirect
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Parse DIRECT keyword (bridge → RT parser).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_KW_ParseDirect(node, props, status)
    USE MD_KW, ONLY: KW_ASTNodeType
    TYPE(KW_ASTNodeType), INTENT(IN) :: node
    TYPE(DirectProperties), INTENT(OUT) :: props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL Parse_DIRECT_Keyword(node, props, status)
    
  END SUBROUTINE MD_RT_KW_ParseDirect

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_KW_ParseModalDamping
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Parse MODAL_DAMPING keyword (bridge → RT parser).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_KW_ParseModalDamping(node, props, status)
    USE MD_KW, ONLY: KW_ASTNodeType
    TYPE(KW_ASTNodeType), INTENT(IN) :: node
    TYPE(ModalDampingProperties), INTENT(OUT) :: props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL Parse_MODAL_DAMPING_Keyword(node, props, status)
    
  END SUBROUTINE MD_RT_KW_ParseModalDamping

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_KW_ParseModalDynamic
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Parse MODAL_DYNAMIC keyword (bridge → RT parser).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_KW_ParseModalDynamic(node, props, status)
    USE MD_KW, ONLY: KW_ASTNodeType
    TYPE(KW_ASTNodeType), INTENT(IN) :: node
    TYPE(ModalDynamicProperties), INTENT(OUT) :: props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL Parse_MODAL_DYNAMIC_Keyword(node, props, status)
    
  END SUBROUTINE MD_RT_KW_ParseModalDynamic

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_KW_ParseResponseSpectrum
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Parse RESPONSE_SPECTRUM keyword (bridge → RT parser).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_KW_ParseResponseSpectrum(node, props, status)
    USE MD_KW, ONLY: KW_ASTNodeType
    TYPE(KW_ASTNodeType), INTENT(IN) :: node
    TYPE(ResponseSpectrumProperties), INTENT(OUT) :: props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL Parse_RESPONSE_SPECTRUM_Keyword(node, props, status)
    
  END SUBROUTINE MD_RT_KW_ParseResponseSpectrum

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_KW_ParseSteadyState
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Parse STEADY_STATE_DYNAMICS keyword (bridge → RT parser).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_KW_ParseSteadyState(node, props, status)
    USE MD_KW, ONLY: KW_ASTNodeType
    TYPE(KW_ASTNodeType), INTENT(IN) :: node
    TYPE(SteadyStateProperties), INTENT(OUT) :: props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL Parse_STEADY_STATE_DYNAMICS_Keyword(node, props, status)
    
  END SUBROUTINE MD_RT_KW_ParseSteadyState

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_KW_ParseSubstructure
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Parse SUBSTRUCTURE keyword (bridge → RT parser).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_KW_ParseSubstructure(node, props, status)
    USE MD_KW, ONLY: KW_ASTNodeType
    TYPE(KW_ASTNodeType), INTENT(IN) :: node
    TYPE(SubstructureProperties), INTENT(OUT) :: props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Bridge: Direct call to L5_RT function (same signature)
    CALL Parse_SUBSTRUCTURE_Keyword(node, props, status)
    
  END SUBROUTINE MD_RT_KW_ParseSubstructure

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_KW_ParseStaticRiks
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Parse *STATIC,RIKS keyword and convert to UF_RiksControl.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_KW_ParseStaticRiks(node, riks_ctrl, status)
    USE MD_KW, ONLY: KW_ASTNodeType
    TYPE(KW_ASTNodeType), INTENT(IN) :: node
    TYPE(UF_RiksControl), INTENT(OUT) :: riks_ctrl
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(RiksSolverConfig) :: riks_config

    CALL init_error_status(status)
    CALL Parse_STATIC_RIKS_Keyword(node, riks_config, "STATIC_RIKS", status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL RiksSolverConfig_To_UF_RiksControl(riks_config, riks_ctrl)
  END SUBROUTINE MD_RT_KW_ParseStaticRiks

END MODULE MD_KWRT_Brg
