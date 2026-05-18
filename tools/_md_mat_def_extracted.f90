  !=============================================================================
  ! MatContext Procedures
  !=============================================================================
  subroutine Init(this, kin, desc, material_id, nprops, nstatev, status)
    class(MatCtxLegacy),           intent(inout) :: this
    type(UF_Kinematics),     intent(in)    :: kin
    type(Desc_MaterialModel), intent(in)    :: desc
    integer(i4),             intent(in)    :: material_id
    integer(i4),             intent(in)    :: nprops
    integer(i4),             intent(in)    :: nstatev
    type(ErrorStatusType),   intent(out)   :: status

    call init_error_status(status)

    this%kin = kin
    this%desc = desc
    this%material_id = material_id
    this%nprops = nprops
    this%nstatev = nstatev

    if (nprops > 0) then
      allocate(this%props(nprops))
      this%props(:) = 0.0_wp
    end if

    if (nstatev > 0) then
      allocate(this%statev(nstatev))
      this%statev(:) = 0.0_wp
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine Init

  subroutine Clean(this)
    USE IF_Mem_Mgr, only: mem_disassociate_pointer, mem_free, g_mem_pool
    class(MatCtxLegacy), intent(inout) :: this
    type(ErrorStatusType) :: status

    ! Clean up props memory
    if (this%props_associate .and. associated(this%props)) then
      call mem_disassociate_pointer(g_mem_pool, this%props_mem_id, status)
      nullify(this%props)
      this%props_associate = .false.
      call mem_free(g_mem_pool, this%props_mem_id, status)
      this%props_mem_id = 0_i4
    else if (associated(this%props)) then
      deallocate(this%props)
      nullify(this%props)
    end if

    ! Clean up statev memory
    if (this%statev_associat .and. associated(this%statev)) then
      call mem_disassociate_pointer(g_mem_pool, this%statev_mem_id, status)
      nullify(this%statev)
      this%statev_associat = .false.
      call mem_free(g_mem_pool, this%statev_mem_id, status)
      this%statev_mem_id = 0_i4
    else if (associated(this%statev)) then
      deallocate(this%statev)
      nullify(this%statev)
    end if

    this%material_id = 0_i4
    this%nprops = 0_i4
    this%nstatev = 0_i4
  end subroutine Clean

  subroutine SetProps(this, props)
    class(MatCtxLegacy), intent(inout) :: this
    real(wp),      intent(in)    :: props(:)

    integer(i4) :: n

    if (.not. associated(this%props)) return

    n = min(size(props), this%nprops)
    if (n > 0) then
      this%props(1:n) = props(1:n)
    end if
  end subroutine SetProps

  subroutine SetStateV(this, statev)
    class(MatCtxLegacy), intent(inout) :: this
    real(wp),      intent(in)    :: statev(:)

    integer(i4) :: n

    if (.not. associated(this%statev)) return

    n = min(size(statev), this%nstatev)
    if (n > 0) then
      this%statev(1:n) = statev(1:n)
    end if
  end subroutine SetStateV

  subroutine GetProps(this, props)
    class(MatCtxLegacy), intent(in) :: this
    real(wp),      intent(out) :: props(:)

    integer(i4) :: n

    if (.not. associated(this%props)) then
      props(:) = 0.0_wp
      return
    end if

    n = min(size(props), this%nprops)
    if (n > 0) then
      props(1:n) = this%props(1:n)
    end if
    if (n < size(props)) then
      props(n+1:) = 0.0_wp
    end if
  end subroutine GetProps

  subroutine GetStateV(this, statev)
    class(MatCtxLegacy), intent(in) :: this
    real(wp),      intent(out) :: statev(:)

    integer(i4) :: n

    if (.not. associated(this%statev)) then
      statev(:) = 0.0_wp
      return
    end if

    n = min(size(statev), this%nstatev)
    if (n > 0) then
      statev(1:n) = this%statev(1:n)
    end if
    if (n < size(statev)) then
      statev(n+1:) = 0.0_wp
    end if
  end subroutine GetStateV

  subroutine AllocateProps(this, nprops, status)
    USE IF_Mem_Mgr, only: mem_alloc_pointer, mem_associate_pointer, g_mem_pool
    class(MatCtxLegacy), intent(inout) :: this
    integer(i4),            intent(in)    :: nprops
    type(ErrorStatusType),  intent(out)   :: status

    integer(i4) :: dims(1)

    call init_error_status(status)

    if (nprops <= 0) then
      status%status_code = -1
      status%message = "Invalid number of properties"
      return
    end if

    if (this%props_associate) then
      call this%Clean()
    end if

    this%nprops = nprops
    dims(1) = nprops

    call mem_alloc_pointer(g_mem_pool, 1, 1, dims, 0, 1, &
                          "MatProps_" // trim(this%desc%name), &
                          this%props_mem_id, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call mem_associate_pointer(g_mem_pool, this%props_mem_id, &
                              ptr_real=this%props, status=status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    this%props_associate = .true.
    status%status_code = MD_MAT_STATUS_OK
  end subroutine AllocateProps

  subroutine AllocateStateV(this, nstatev, status)
    USE IF_Mem_Mgr, only: mem_alloc_pointer, mem_associate_pointer, g_mem_pool
    class(MatCtxLegacy), intent(inout) :: this
    integer(i4),            intent(in)    :: nstatev
    type(ErrorStatusType),  intent(out)   :: status

    integer(i4) :: dims(1)

    call init_error_status(status)

    if (nstatev <= 0) then
      status%status_code = -1
      status%message = "Invalid number of state variables"
      return
    end if

    if (this%statev_associat) then
      call this%Destroy()
    end if

    this%nstatev = nstatev
    dims(1) = nstatev

    call mem_alloc_pointer(g_mem_pool, 1, 1, dims, 0, 1, &
                          "MatStateV_" // trim(this%desc%name), &
                          this%statev_mem_id, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call mem_associate_pointer(g_mem_pool, this%statev_mem_id, &
                              ptr_real=this%statev, status=status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    this%statev_associat = .true.
    status%status_code = MD_MAT_STATUS_OK
  end subroutine AllocateStateV

  function IsPropsAssociated(this) result(is_associated)
    class(MatCtxLegacy), intent(in) :: this
    logical :: is_associated
    is_associated = this%props_associate .and. associated(this%props)
  end function IsPropsAssociated

  function IsStateVAssociated(this) result(is_associated)
    class(MatCtxLegacy), intent(in) :: this
    logical :: is_associated
    is_associated = this%statev_associat .and. associated(this%statev)
  end function IsStateVAssociated

  !=============================================================================
  ! MatResult Procedures
  !=============================================================================
  subroutine Init(this, ntens, nstatev, status)
    class(MatRes),          intent(inout) :: this
    integer(i4),            intent(in)    :: ntens
    integer(i4),            intent(in)    :: nstatev
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    if (.not. allocated(this%stress)) then
      allocate(this%stress(ntens))
    end if

    if (.not. allocated(this%tangent)) then
      allocate(this%tangent(ntens, ntens))
    end if

    if (nstatev > 0 .and. .not. allocated(this%statev)) then
      allocate(this%statev(nstatev))
    end if

    call this%Reset()
    status%status_code = MD_MAT_STATUS_OK
  end subroutine Init

  subroutine Clean(this)
    class(MatRes), intent(inout) :: this
    if (allocated(this%stress)) deallocate(this%stress)
    if (allocated(this%tangent)) deallocate(this%tangent)
    if (allocated(this%statev)) deallocate(this%statev)
  end subroutine Clean

  subroutine Reset(this)
    class(MatRes), intent(inout) :: this
    if (allocated(this%stress)) this%stress(:) = 0.0_wp
    if (allocated(this%tangent)) this%tangent(:,:) = 0.0_wp
    if (allocated(this%statev)) this%statev(:) = 0.0_wp
    this%sse = 0.0_wp
    this%spd = 0.0_wp
    this%scd = 0.0_wp
    this%rpl = 0.0_wp
    this%failed = .false.
    this%is_plastic = .false.
    this%suggest_cutback = .false.
    this%pnewdt_factor = 1.0_wp
  end subroutine Reset

  !=============================================================================
  ! MatProperties Procedures
  !=============================================================================
  subroutine Init(this, material_id, nprops, status)
    class(MatProps),        intent(inout) :: this
    integer(i4),            intent(in)    :: material_id
    integer(i4),            intent(in)    :: nprops
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    this%material_id = material_id
    this%nprops = nprops

    if (nprops > 0) then
      allocate(this%props(nprops))
      this%props(:) = 0.0_wp
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine Init

  subroutine Clean(this)
    class(MatProps), intent(inout) :: this
    if (allocated(this%props)) deallocate(this%props)
    this%material_id = 0_i4
    this%nprops = 0_i4
  end subroutine Clean

  subroutine SetProp(this, idx, value)
    class(MatProps), intent(inout) :: this
    integer(i4),     intent(in)    :: idx
    real(wp),        intent(in)    :: value
    if (idx >= 1 .and. idx <= this%nprops) then
      this%props(idx) = value
    end if
  end subroutine SetProp

  subroutine GetProp(this, idx, value)
    class(MatProps), intent(in)  :: this
    integer(i4),     intent(in)  :: idx
    real(wp),        intent(out) :: value
    value = 0.0_wp
    if (idx >= 1 .and. idx <= this%nprops) then
      value = this%props(idx)
    end if
  end subroutine GetProp

  !=============================================================================
  ! MD_MAT_UMAT_Intf Procedures
  !=============================================================================
  subroutine Init(this, material_id, material_name, nprops, nstatev, &
                                  requires_temp, supports_2d, supports_3d, status)
    class(MD_MAT_UMAT_Intf), intent(inout) :: this
    integer(i4),            intent(in)    :: material_id
    character(len=*),       intent(in)    :: material_name
    integer(i4),            intent(in)    :: nprops
    integer(i4),            intent(in)    :: nstatev
    logical,                intent(in)    :: requires_temp
    logical,                intent(in)    :: supports_2d
    logical,                intent(in)    :: supports_3d
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    this%material_id = material_id
    this%material_name = trim(material_name)
    this%nprops = nprops
    this%nstatev = nstatev
    this%requires_temp = requires_temp
    this%supports_2d = supports_2d
    this%supports_3d = supports_3d

    status%status_code = MD_MAT_STATUS_OK
  end subroutine Init

  subroutine Valid(this, status)
    class(MD_MAT_UMAT_Intf), intent(in)  :: this
    type(ErrorStatusType),  intent(out) :: status

    call init_error_status(status)

    if (this%material_id <= 0) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Invalid Mat ID"
      return
    end if

    if (this%nprops < 0) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Invalid number of props"
      return
    end if

    if (this%nstatev < 0) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Invalid number of state variables"
      return
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine Valid

  !=============================================================================
  ! MD_MAT_UMAT_Input Procedures
  !=============================================================================
  subroutine Init(this, ntens, nstatv, nprops, status)
    class(MD_MAT_UMAT_Input),      intent(inout) :: this
    integer(i4),            intent(in)    :: ntens
    integer(i4),            intent(in)    :: nstatv
    integer(i4),            intent(in)    :: nprops
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    allocate(this%stress(ntens))
    allocate(this%statev(nstatv))
    allocate(this%stran(ntens))
    allocate(this%dstran(ntens))
    allocate(this%props(nprops))

    this%stress(:) = 0.0_wp
    this%statev(:) = 0.0_wp
    this%stran(:) = 0.0_wp
    this%dstran(:) = 0.0_wp
    this%props(:) = 0.0_wp
    this%time(:) = 0.0_wp
    this%dtime = 0.0_wp
    this%temp = 0.0_wp
    this%dtemp = 0.0_wp
    this%coords(:) = 0.0_wp
    this%drot(:,:) = 0.0_wp
    this%dfgrd0(:,:) = 0.0_wp
    this%dfgrd1(:,:) = 0.0_wp
    this%pnewdt = 1.0_wp
    this%celent = 0.0_wp
    this%noel = 0_i4
    this%npt = 0_i4
    this%layer = 0_i4
    this%kspt = 0_i4
    this%kstep = 0_i4
    this%kinc = 0_i4
    this%ndir = 3_i4
    this%nshr = 3_i4
    this%ntens = ntens
    this%nstatv = nstatv
    this%nprops = nprops

    status%status_code = MD_MAT_STATUS_OK
  end subroutine Init

  subroutine Clean(this)
    class(MD_MAT_UMAT_Input), intent(inout) :: this
    if (allocated(this%stress)) deallocate(this%stress)
    if (allocated(this%statev)) deallocate(this%statev)
    if (allocated(this%stran)) deallocate(this%stran)
    if (allocated(this%dstran)) deallocate(this%dstran)
    if (allocated(this%props)) deallocate(this%props)
  end subroutine Clean

  subroutine FromKinematics(this, kin)
    class(MD_MAT_UMAT_Input), intent(inout) :: this
    type(UF_Kinematics), intent(in) :: kin

    integer(i4) :: ntens

    ntens = this%ntens
    this%stran(1:ntens) = kin%mech%strain(1:ntens)
    this%dstran(1:ntens) = kin%mech%dStrain(1:ntens)
    this%time(1) = kin%time%current
    this%time(2) = kin%time%total
    this%dtime = kin%time%inc
    this%temp = kin%temp%current
    this%dtemp = kin%temp%inc
    this%noel = kin%cfg%id
    this%npt = kin%ipID
  end subroutine FromKinematics

  !=============================================================================
  ! MD_MAT_UMAT_Output Procedures
  !=============================================================================
  subroutine Init(this, ntens, nstatv, status)
    class(MD_MAT_UMAT_Output),     intent(inout) :: this
    integer(i4),            intent(in)    :: ntens
    integer(i4),            intent(in)    :: nstatv
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    allocate(this%stress(ntens))
    allocate(this%statev(nstatv))
    allocate(this%ddsdde(ntens, ntens))
    allocate(this%ddsddt(ntens))
    allocate(this%drplde(ntens))

    this%stress(:) = 0.0_wp
    this%statev(:) = 0.0_wp
    this%ddsdde(:,:) = 0.0_wp
    this%ddsddt(:) = 0.0_wp
    this%drplde(:) = 0.0_wp
    this%sse = 0.0_wp
    this%spd = 0.0_wp
    this%scd = 0.0_wp
    this%rpl = 0.0_wp
    this%drpldt = 0.0_wp
    this%pnewdt = 1.0_wp

    status%status_code = MD_MAT_STATUS_OK
  end subroutine Init

  subroutine Clean(this)
    class(MD_MAT_UMAT_Output), intent(inout) :: this
    if (allocated(this%stress)) deallocate(this%stress)
    if (allocated(this%statev)) deallocate(this%statev)
    if (allocated(this%ddsdde)) deallocate(this%ddsdde)
    if (allocated(this%ddsddt)) deallocate(this%ddsddt)
    if (allocated(this%drplde)) deallocate(this%drplde)
  end subroutine Clean

  subroutine ToState(this, state)
    class(MD_MAT_UMAT_Output), intent(in) :: this
    type(State_IntPoint), intent(inout) :: state

    integer(i4) :: ntens, nstatev

    ntens = size(this%stress)
    nstatev = size(this%statev)

    state%stress(1:ntens) = this%stress(1:ntens)
    state%pop%nStateV = nstatev
    state%statev(1:nstatev) = this%statev(1:nstatev)
    state%sse = this%sse
    state%spd = this%spd
    state%scd = this%scd
    state%rpl = this%rpl
  end subroutine ToState

  !=============================================================================
  ! PROCEDURES FROM MD_Material_Ctx
  !=============================================================================

  subroutine MatCtx_Init(this)
    class(MD_Material_Ctx), intent(inout) :: this
    type(ErrorStatusType) :: status
    call init_error_status(status)
    call this%sta%SetStatus(status)
    this%init = .true.
  end subroutine MatCtx_Init

  subroutine MatCtx_Clean(this)
    class(MD_Material_Ctx), intent(inout) :: this
    nullify(this%desc)
    nullify(this%sta)
    nullify(this%algo)
    nullify(this%ctx)
    nullify(this%res)
    nullify(this%kin)
    nullify(this%desc_legacy)
    this%success = .false.
    this%init = .false.
  end subroutine MatCtx_Clean

  subroutine MatCtx_Reset(this)
    class(MD_Material_Ctx), intent(inout) :: this
    this%success = .false.
    call this%sta%ClearStatus()
  end subroutine MatCtx_Reset

  function MatCtx_GetStat(this) result(status)
    class(MD_Material_Ctx), intent(in) :: this
    type(ErrorStatusType) :: status
    if (.not. this%init) then
      call init_error_status(status)
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_Material_Ctx not initialized'
    else
      status = this%sta%GetStatus()
    end if
  end function MatCtx_GetStat

  subroutine MatCtx_SetStat(this, status)
    class(MD_Material_Ctx), intent(inout) :: this
    type(ErrorStatusType), intent(in) :: status
    call this%sta%SetStatus(status)
  end subroutine MatCtx_SetStat

  subroutine MatCtx_ClrStat(this)
    class(MD_Material_Ctx), intent(inout) :: this
    call this%sta%ClearStatus()
  end subroutine MatCtx_ClrStat

  function MatCtx_IsOk(this) result(is_ok)
    class(MD_Material_Ctx), intent(in) :: this
    logical :: is_ok
    is_ok = this%sta%IsOK()
  end function MatCtx_IsOk

  function MatCtx_IsErr(this) result(is_error)
    class(MD_Material_Ctx), intent(in) :: this
    logical :: is_error
    is_error = this%sta%IsError()
  end function MatCtx_IsErr

  subroutine MatCtx_Bind(this, desc, sta, algo, ctx, res, kin, desc_legacy)
    class(MD_Material_Ctx), intent(inout) :: this
    type(MD_Mat_Desc), target, intent(in), optional :: desc
    type(MD_MatSta), target, intent(in), optional :: sta
    type(MD_MatAlgo), target, intent(in), optional :: algo
    type(MatCtxLegacy), target, intent(in), optional :: ctx
    type(MatRes), target, intent(in), optional :: res
    type(UF_Kinematics), target, intent(in), optional :: kin
    type(Desc_MaterialModel), target, intent(in), optional :: desc_legacy

    if (present(desc)) this%desc => desc
    if (present(sta)) this%mat_sta => sta
    if (present(algo)) this%algo => algo
    if (present(ctx)) this%ctx => ctx
    if (present(res)) this%res => res
    if (present(kin)) this%kin => kin
    if (present(desc_legacy)) this%desc_legacy => desc_legacy

    call this%Init()
  end subroutine MatCtx_Bind

  function MatCtx_Valid(this) result(is_valid)
    class(MD_Material_Ctx), intent(in) :: this
    logical :: is_valid

    is_valid = .true.

    if (.not. this%init) then
      is_valid = .false.
      return
    end if

    if (.not. associated(this%ctx) .and. .not. associated(this%desc)) then
      is_valid = .false.
      return
    end if
  end function MatCtx_Valid

  function MatCtx_GetCtx(this) result(ctx)
    class(MD_Material_Ctx), intent(in) :: this
    type(MatCtxLegacy), pointer :: ctx
    ctx => this%ctx
  end function MatCtx_GetCtx

  function MatCtx_GetRes(this) result(res)
    class(MD_Material_Ctx), intent(in) :: this
    type(MatRes), pointer :: res
    res => this%res
  end function MatCtx_GetRes

  function MatCtx_GetDesc(this) result(desc)
    class(MD_Material_Ctx), intent(in) :: this
    type(MD_Mat_Desc), pointer :: desc
    desc => this%desc
  end function MatCtx_GetDesc

  function MatCtx_GetSta(this) result(sta)
    class(MD_Material_Ctx), intent(in) :: this
    type(MD_MatSta), pointer :: sta
    sta => this%mat_sta
  end function MatCtx_GetSta

  function MatCtx_GetAlgo(this) result(algo)
    class(MD_Material_Ctx), intent(in) :: this
    type(MD_MatAlgo), pointer :: algo
    algo => this%algo
  end function MatCtx_GetAlgo
