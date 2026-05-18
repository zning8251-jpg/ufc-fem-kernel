!===============================================================================
! MODULE: AP_Inp_Mat
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Impl — material model command handlers
! BRIEF:  Material model commands (Elastic, Plastic, Hyperelastic, etc.).
!
! Process phases:
!   P1: Cmd_Material / Cmd_Elastic / Cmd_Plastic / Cmd_Hyperelastic
!   P2: parse_material_properties / validate_material_model
!===============================================================================
MODULE AP_Inp_Mat
  USE AP_Inp_Script, only: Cmd_Reg, Cmd_FormatError
  USE AP_Inp_Param, only: PARSEKEYVALUERE, ParseKeyValueInt, ParseKeyValueStr, ParseArray
  USE AP_Inp_Def, only: Cmd, CmdCtx
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, only: i4, wp
  
  ! UFC Material API imports - via Bridge module
  USE AP_Brg_L3, only: MatTree, MaterialDesc, MatDesc, ModelTree, &
                                    UF_MaterialDef, MaterialDef_Init_Structured, &
                                    MaterialDef_Init_In, MaterialDesc_Init_Structured_Wrapper
  
  implicit none
  private
  
  !===============================================================================
  ! Material Type Constants
  !===============================================================================
  integer(i4), parameter :: MAT_TYPE_ELAS = 1
  integer(i4), parameter :: MAT_TYPE_PLASTI = 2
  integer(i4), parameter :: MAT_TYPE_HYP = 3
  integer(i4), parameter :: MAT_TYPE_VISC = 4
  integer(i4), parameter :: MAT_TYPE_DAMAGE = 5
  integer(i4), parameter :: MAT_TYPE_USER = 10
  
  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: UF_Cmd_Mat_RegAll
  public :: ParseMaterialParams
  
contains

  subroutine Cmd_Creep(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(MaterialDesc), pointer :: material => null()
    type(ModelTree), pointer :: model_tree => null()
    class(MaterialDesc), pointer :: existing_material => null()
    character(len=64) :: mat_name, law_str
    real(wp) :: A, n, m
    integer(i4) :: ios
    logical :: found
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse material name
    call ParseKeyValueStr(cmd%param_str, 'name', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    ! Check if material already exists
    existing_material => model_tree%GetMaterial(name=mat_name)
    if (associated(existing_material)) then
      material => existing_material
    else
      allocate(material, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate material', status%message)
        return
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = 0  ! default
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    ! Parse creep law
    call ParseKeyValueStr(cmd%param_str, 'law', law_str, found)
    if (.not. found) law_str = 'strain'
    
    ! Parse creep parameters
    call PARSEKEYVALUERE(cmd%param_str, 'A', A, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'n', n, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'm', m, found, default_val=0.0_wp)
    ! Set material properties
    material%cfg%materialType = 'CREEP'
    material%pop%nProps = 3
    if (.not. allocated(material%props)) allocate(material%props(3))
    material%props(1) = A
    material%props(2) = n
    material%props(3) = m
    
    ! Add material to model tree if new
    if (.not. associated(existing_material)) then
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command CREEP: Material "', trim(mat_name), '" defined'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Creep

  subroutine Cmd_Damping(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(MaterialDesc), pointer :: material => null()
    type(ModelTree), pointer :: model_tree => null()
    class(MaterialDesc), pointer :: existing_material => null()
    character(len=64) :: mat_name
    real(wp) :: alpha, beta, composite
    integer(i4) :: ios
    logical :: found
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse material name
    call ParseKeyValueStr(cmd%param_str, 'name', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    ! Check if material already exists
    existing_material => model_tree%GetMaterial(name=mat_name)
    if (associated(existing_material)) then
      material => existing_material
    else
      allocate(material, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate material', status%message)
        return
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = 0  ! default
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    ! Parse damping parameters
    call PARSEKEYVALUERE(cmd%param_str, 'alpha', alpha, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'beta', beta, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'composite', composite, found, default_val=0.0_wp)
    ! Set material properties
    material%cfg%materialType = 'DAMPING'
    material%pop%nProps = 3
    if (.not. allocated(material%props)) allocate(material%props(3))
    material%props(1) = alpha
    material%props(2) = beta
    material%props(3) = composite
    
    ! Add material to model tree if new
    if (.not. associated(existing_material)) then
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command DAMPING: Material "', trim(mat_name), '" defined'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Damping

  subroutine Cmd_Elastic(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(MaterialDesc), pointer :: material => null()
    type(ModelTree), pointer :: model_tree => null()
    class(MaterialDesc), pointer :: existing_material => null()
    character(len=64) :: mat_name
    real(wp) :: E, nu, rho, G, K
    integer(i4) :: ios
    logical :: found
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse material name
    call ParseKeyValueStr(cmd%param_str, 'name', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    ! Check if material already exists
    existing_material => model_tree%GetMaterial(name=mat_name)
    if (associated(existing_material)) then
      material => existing_material
    else
      allocate(material, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate material', status%message)
        return
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = 0  ! default
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    ! Parse elastic parameters
    call PARSEKEYVALUERE(cmd%param_str, 'E', E, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'nu', nu, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'rho', rho, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'G', G, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'K', K, found, default_val=0.0_wp)
    
    ! Valid required parameters
    if (E <= 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Elastic modulus E must be positive', status%message)
      return
    end if
    
    if (nu < 0.0_wp .or. nu >= 0.5_wp) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Poisson ratio nu must be in [0, 0.5)', status%message)
      return
    end if
    
    ! Calculate derived properties if not provided
    if (G <= 0.0_wp .and. E > 0.0_wp .and. nu > 0.0_wp) then
      G = E / (2.0_wp * (1.0_wp + nu))
    end if
    
    if (K <= 0.0_wp .and. E > 0.0_wp .and. nu > 0.0_wp) then
      K = E / (3.0_wp * (1.0_wp - 2.0_wp * nu))
    end if
    
    ! Set material properties
    material%cfg%materialType = 'ELASTIC'
    material%pop%nProps = 5
    if (.not. allocated(material%props)) allocate(material%props(5))
    material%props(1) = E
    material%props(2) = nu
    material%props(3) = rho
    material%props(4) = G
    material%props(5) = K
    
    ! Add material to model tree if new
    if (.not. associated(existing_material)) then
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A,ES12.4,A,ES12.4)') 'Command ELASTIC: Material "', trim(mat_name), &
        '" defined (E=', E, ', nu=', nu, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Elastic

  subroutine Cmd_Hyperelastic(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(MaterialDesc), pointer :: material => null()
    type(ModelTree), pointer :: model_tree => null()
    class(MaterialDesc), pointer :: existing_material => null()
    character(len=64) :: mat_name, type_str
    real(wp) :: C10, C01, D1, mu_i(10), alpha_i(10)
    integer(i4) :: N, num_params, ios
    logical :: found
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse material name
    call ParseKeyValueStr(cmd%param_str, 'name', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    ! Check if material already exists
    existing_material => model_tree%GetMaterial(name=mat_name)
    if (associated(existing_material)) then
      material => existing_material
    else
      allocate(material, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate material', status%message)
        return
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = 0  ! default
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    ! Parse hyperelastic type
    call ParseKeyValueStr(cmd%param_str, 'type', type_str, found)
    if (.not. found) type_str = 'mooney_rivlin'
    
    ! Parse parameters based on type
    if (index(type_str, 'mooney') > 0 .or. index(type_str, 'rivlin') > 0) then
      ! Mooney-Rivlin: C10, C01, D1
      call PARSEKEYVALUERE(cmd%param_str, 'C10', C10, found, default_val=0.0_wp)
      call PARSEKEYVALUERE(cmd%param_str, 'C01', C01, found, default_val=0.0_wp)
      call PARSEKEYVALUERE(cmd%param_str, 'D1', D1, found, default_val=0.0_wp)
      ! Set material properties
      material%cfg%materialType = 'HYPERELASTIC'
      material%pop%nProps = 3
      if (.not. allocated(material%props)) allocate(material%props(3))
      material%props(1) = C10
      material%props(2) = C01
      material%props(3) = D1
    else if (index(type_str, 'neo') > 0 .or. index(type_str, 'hooke') > 0) then
      ! Neo-Hooke: C10, D1
      call PARSEKEYVALUERE(cmd%param_str, 'C10', C10, found, default_val=0.0_wp)
      call PARSEKEYVALUERE(cmd%param_str, 'D1', D1, found, default_val=0.0_wp)
      ! Set material properties
      material%cfg%materialType = 'HYPERELASTIC'
      material%pop%nProps = 2
      if (.not. allocated(material%props)) allocate(material%props(2))
      material%props(1) = C10
      material%props(2) = D1
    else if (index(type_str, 'ogden') > 0) then
      ! Ogden: N, mu_i, alpha_i
      call ParseKeyValueInt(cmd%param_str, 'N', N, found, default_val=1)
      call ParseArray(cmd%param_str, mu_i, num_params, 10)
      ! Parse alpha_i array
      call ParseArray(cmd%param_str, alpha_i, num_params, 10)
      ! Set material properties
      material%cfg%materialType = 'HYPERELASTIC'
      material%pop%nProps = 1 + 2 * N  ! N, mu_1...mu_N, alpha_1...alpha_N
      if (.not. allocated(material%props)) allocate(material%props(material%pop%nProps))
      material%props(1) = real(N, wp)
      material%props(2:1+N) = mu_i(1:N)
      material%props(2+N:1+2*N) = alpha_i(1:N)
    end if
    
    ! Add material to model tree if new
    if (.not. associated(existing_material)) then
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A,A)') 'Command HYPERELASTIC: Material "', trim(mat_name), &
        '" defined (type=', trim(type_str), ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Hyperelastic

  subroutine Cmd_Plastic(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(MaterialDesc), pointer :: material => null()
    type(ModelTree), pointer :: model_tree => null()
    class(MaterialDesc), pointer :: existing_material => null()
    character(len=64) :: mat_name
    real(wp) :: E, nu, sigma_y, E_t, rho
    integer(i4) :: ios
    logical :: found
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse material name
    call ParseKeyValueStr(cmd%param_str, 'name', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    ! Check if material already exists
    existing_material => model_tree%GetMaterial(name=mat_name)
    if (associated(existing_material)) then
      material => existing_material
    else
      allocate(material, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate material', status%message)
        return
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = 0  ! default
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    ! Parse plastic parameters
    call PARSEKEYVALUERE(cmd%param_str, 'E', E, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'nu', nu, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'sigma_y', sigma_y, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'E_t', E_t, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'rho', rho, found, default_val=0.0_wp)
    
    ! Valid required parameters
    if (E <= 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Elastic modulus E must be positive', status%message)
      return
    end if
    
    if (sigma_y <= 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Yield sigma sigma_y must be positive', status%message)
      return
    end if
    
    if (nu < 0.0_wp .or. nu >= 0.5_wp) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Poisson ratio nu must be in [0, 0.5)', status%message)
      return
    end if
    
    ! Set default hardening modulus if not provided
    if (E_t <= 0.0_wp) then
      E_t = 0.01_wp * E  ! Default: 1% of elastic modulus
    end if
    
    ! Set material properties
    material%cfg%materialType = 'PLASTIC'
    material%pop%nProps = 5
    if (.not. allocated(material%props)) allocate(material%props(5))
    material%props(1) = E
    material%props(2) = nu
    material%props(3) = sigma_y
    material%props(4) = E_t
    material%props(5) = rho
    
    ! Add material to model tree if new
    if (.not. associated(existing_material)) then
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A,ES12.4,A,ES12.4)') 'Command PLASTIC: Material "', trim(mat_name), &
        '" defined (E=', E, ', sigma_y=', sigma_y, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Plastic

  subroutine Cmd_UserMaterial(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(MaterialDesc), pointer :: material => null()
    type(ModelTree), pointer :: model_tree => null()
    class(MaterialDesc), pointer :: existing_material => null()
    character(len=64) :: mat_name, type_str, unsymm_str
    integer(i4) :: num_constants
    logical :: unsymm
    integer(i4) :: ios
    logical :: found
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse material name
    call ParseKeyValueStr(cmd%param_str, 'name', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    ! Check if material already exists
    existing_material => model_tree%GetMaterial(name=mat_name)
    if (associated(existing_material)) then
      material => existing_material
    else
      allocate(material, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate material', status%message)
        return
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = 0  ! default
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    ! Parse UMAT parameters
    call ParseKeyValueInt(cmd%param_str, 'constants', num_constants, found, default_val=0)
    call ParseKeyValueStr(cmd%param_str, 'type', type_str, found)
    call ParseKeyValueStr(cmd%param_str, 'unsymm', unsymm_str, found)
    unsymm = (index(unsymm_str, 'yes') > 0 .or. index(unsymm_str, 'true') > 0)
    ! Set material properties
    material%cfg%materialType = 'USER'
    material%pop%nProps = num_constants
    if (num_constants > 0) then
      if (.not. allocated(material%props)) allocate(material%props(num_constants))
      material%props = 0.0_wp  ! Init to zero, user should set via other commands
    end if
    if (len_trim(type_str) > 0) material%cfg%behavior = type_str
    
    ! Add material to model tree if new
    if (.not. associated(existing_material)) then
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A,I0,A)') 'Command USER_MATERIAL: Material "', trim(mat_name), &
        '" defined (constants=', num_constants, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_UserMaterial

  subroutine Cmd_Viscoelastic(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(MaterialDesc), pointer :: material => null()
    type(ModelTree), pointer :: model_tree => null()
    class(MaterialDesc), pointer :: existing_material => null()
    character(len=64) :: mat_name, time_type
    real(wp) :: E_inf, E_i(20), tau_i(20)
    integer(i4) :: num_terms, ios
    logical :: found
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse material name
    call ParseKeyValueStr(cmd%param_str, 'name', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    ! Check if material already exists
    existing_material => model_tree%GetMaterial(name=mat_name)
    if (associated(existing_material)) then
      material => existing_material
    else
      allocate(material, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate material', status%message)
        return
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = 0  ! default
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    ! Parse time type (prony/frequency)
    call ParseKeyValueStr(cmd%param_str, 'time', time_type, found)
    if (.not. found) time_type = 'prony'
    
    ! Parse parameters
    call PARSEKEYVALUERE(cmd%param_str, 'E_inf', E_inf, found, default_val=0.0_wp)
    call ParseArray(cmd%param_str, E_i, num_terms, 20)
    ! Parse tau_i array
    call ParseArray(cmd%param_str, tau_i, num_terms, 20)
    ! Set material properties
    material%cfg%materialType = 'VISCOELASTIC'
    material%pop%nProps = 1 + 2 * num_terms  ! E_inf, E_1...E_N, tau_1...tau_N
    if (.not. allocated(material%props)) allocate(material%props(material%pop%nProps))
    material%props(1) = E_inf
    material%props(2:1+num_terms) = E_i(1:num_terms)
    material%props(2+num_terms:1+2*num_terms) = tau_i(1:num_terms)
    
    ! Add material to model tree if new
    if (.not. associated(existing_material)) then
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command VISCOELASTIC: Material "', trim(mat_name), '" defined'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Viscoelastic

  subroutine ParseMaterialParams(param_str, mat_type, props, num_props, status)
    character(len=*), intent(in) :: param_str
    integer(i4), intent(out) :: mat_type
    real(wp), intent(out) :: props(:)
    integer(i4), intent(out) :: num_props
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i, eq_pos, comma_pos
    logical :: found
    character(len=64) :: type_str, key, value_str
    real(wp) :: E, nu, rho, sigma_y, E_t, C10, C01, E_inf, E_0, tau, sigma_f, G_f
    
    call init_error_status(status)
    
    mat_type = MAT_TYPE_ELAS  ! Default
    num_props = 0
    props = 0.0_wp
    
    ! Parse material type (use ParamParse-style helper)
    call ParseKeyValueStr(param_str, 'type', type_str, found)
    if (len_trim(type_str) > 0) then
      select case(trim(type_str))
      case('elastic')
        mat_type = MAT_TYPE_ELAS
      case('plastic', 'plastic_j2', 'j2')
        mat_type = MAT_TYPE_PLASTI
      case('hyperelastic', 'hyper')
        mat_type = MAT_TYPE_HYP
      case('viscoelastic', 'visco')
        mat_type = MAT_TYPE_VISC
      case('damage')
        mat_type = MAT_TYPE_DAMAGE
      case('user')
        mat_type = MAT_TYPE_USER
      end select
    end if
    
    ! Parse parameters based on material type
    select case(mat_type)
    case(MAT_TYPE_ELAS)
      ! Elastic: E, nu, rho
      E = 0.0_wp
      nu = 0.0_wp
      rho = 0.0_wp
      
      ! Use unified ParamParse helpers for key=value reals
      call PARSEKEYVALUERE(param_str, 'E',   E,   found)
      call PARSEKEYVALUERE(param_str, 'nu',  nu,  found)
      call PARSEKEYVALUERE(param_str, 'rho', rho, found)
      
      if (E > 0.0_wp) then
        props(1) = E
        props(2) = nu
        props(3) = rho
        num_props = 3
      end if
      
    case(MAT_TYPE_PLASTI)
      ! J2 Plasticity: E, nu, sigma_y, hardening
      E = 0.0_wp
      nu = 0.0_wp
      sigma_y = 0.0_wp
      E_t = 0.0_wp
      
      call PARSEKEYVALUERE(param_str, 'E',       E,       found)
      call PARSEKEYVALUERE(param_str, 'nu',      nu,      found)
      call PARSEKEYVALUERE(param_str, 'sigma_y', sigma_y, found)
      call PARSEKEYVALUERE(param_str, 'E_t',     E_t,     found)
      
      if (E > 0.0_wp .and. sigma_y > 0.0_wp) then
        props(1) = E
        props(2) = nu
        props(3) = sigma_y
        props(4) = E_t
        num_props = 4
      end if
      
    case(MAT_TYPE_HYP)
      ! Hyperelastic (Mooney-Rivlin): C10, C01
      C10 = 0.0_wp
      C01 = 0.0_wp
      
      call PARSEKEYVALUERE(param_str, 'C10', C10, found)
      call PARSEKEYVALUERE(param_str, 'C01', C01, found)
      
      if (C10 > 0.0_wp) then
        props(1) = C10
        props(2) = C01
        num_props = 2
      end if
      
    case(MAT_TYPE_VISC)
      ! Viscoelastic: E_inf, E_0, tau
      E_inf = 0.0_wp
      E_0 = 0.0_wp
      tau = 0.0_wp
      
      call PARSEKEYVALUERE(param_str, 'E_inf', E_inf, found)
      call PARSEKEYVALUERE(param_str, 'E_0',  E_0,  found)
      call PARSEKEYVALUERE(param_str, 'tau',  tau,  found)
      
      if (E_inf > 0.0_wp .and. E_0 > 0.0_wp .and. tau > 0.0_wp) then
        props(1) = E_inf
        props(2) = E_0
        props(3) = tau
        num_props = 3
      end if
      
    case(MAT_TYPE_DAMAGE)
      ! Damage: E, nu, sigma_f, G_f
      E = 0.0_wp
      nu = 0.0_wp
      sigma_f = 0.0_wp
      G_f = 0.0_wp
      
      call PARSEKEYVALUERE(param_str, 'E',      E,      found)
      call PARSEKEYVALUERE(param_str, 'nu',     nu,     found)
      call PARSEKEYVALUERE(param_str, 'sigma_f',sigma_f,found)
      call PARSEKEYVALUERE(param_str, 'G_f',    G_f,    found)
      
      if (E > 0.0_wp .and. sigma_f > 0.0_wp .and. G_f > 0.0_wp) then
        props(1) = E
        props(2) = nu
        props(3) = sigma_f
        props(4) = G_f
        num_props = 4
      end if
      
    case(MAT_TYPE_USER)
      ! User material: subroutine name and props
      ! Parse from param_str: subroutine=name,props=1.0,2.0,3.0
      ! TODO: Implement user material parsing
      num_props = 0
      
    end select
    
    status%status_code = IF_STATUS_OK
    
  end subroutine ParseMaterialParams

  subroutine UF_Cmd_Mat_RegAll(status)
    type(ErrorStatusType), intent(out), optional :: status
    
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    
    ! Extended material commands
    call Cmd_Reg('elastic', Cmd_Elastic, 'Elastic material', local_status)
    call Cmd_Reg('plastic', Cmd_Plastic, 'Plastic material (J2)', local_status)
    call Cmd_Reg('hyperelastic', Cmd_Hyperelastic, 'Hyperelastic material', local_status)
    call Cmd_Reg('viscoelastic', Cmd_Viscoelastic, 'Viscoelastic material', local_status)
    call Cmd_Reg('creep', Cmd_Creep, 'Creep material', local_status)
    call Cmd_Reg('damping', Cmd_Damping, 'Material damping', local_status)
    call Cmd_Reg('user_material', Cmd_UserMaterial, 'User-defined material (UMAT)', local_status)
    call Cmd_Reg('umat', Cmd_UserMaterial, 'User-defined material (alias)', local_status)
    
    if (present(status)) status = local_status
    
  end subroutine UF_Cmd_Mat_RegAll
end MODULE AP_Inp_Mat