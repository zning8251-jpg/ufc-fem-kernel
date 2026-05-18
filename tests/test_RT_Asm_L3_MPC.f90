!===============================================================================
! test_RT_Asm_L3_MPC: Regression for L3 MPC via RT_Asm_ApplyL3Constraints (penalty
!   triplet merge) and PH_Constraint elimination + Update_Lambda residual.
! Model: 2 nodes x 3 DOF -> nDOF=6; MPC u(node1,ux) - u(node2,ux) = 0  => eq 1 & 4.
! Run: cmake -DUFC_BUILD_TESTING=ON ..  (or BUILD_TESTING=ON), build, ctest -R RT_Asm_L3_MPC
!===============================================================================
program test_RT_Asm_L3_MPC
  use IF_Prec_Core, only: wp, i4
  use IF_Err_API, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  use UFC_GlobalContainer_Core, only: g_ufc_global
  use MD_Constraint_Types, only: MPCConstraintDef, MPCConstraintDef_Init, &
      MPCConstraintDef_AddTerm, MPCConstraintDef_Cleanup, MPC_TYPE_GENERAL
  use RT_Asm_Solv, only: RT_Asm_ApplyL3Constraints, RT_Asm_Cfg
  use RT_Solv_Sparse_Core, only: RT_Triplet_Init, RT_Triplet_Add, RT_Triplet_Free, &
      RT_CSR_FromTripletMerged, RT_CSR_Free
  use RT_Solv_Type, only: RT_CSRMatrix
  use PH_Constraint_Domain_Core, only: PH_Constraint_Domain, &
      PH_Constr_AddMPCEquation_Arg, PH_Constr_ExtendCSRForMPC_Arg, &
      PH_Constr_Apply_Elimination_CSR_Arg, PH_Constr_Update_Lambda_Arg
  implicit none

  type(ErrorStatusType) :: st, st2
  type(RT_Asm_Cfg) :: cfg
  type(RT_CSRMatrix) :: K
  type(RT_TripletList) :: tl
  type(MPCConstraintDef) :: mpc
  type(PH_Constraint_Domain) :: ph_dom
  type(PH_Constr_AddMPCEquation_Arg) :: add_a
  type(PH_Constr_ExtendCSRForMPC_Arg) :: ext_a
  type(PH_Constr_Apply_Elimination_CSR_Arg) :: elim_a
  type(PH_Constr_Update_Lambda_Arg) :: lam_a

  integer(i4), parameter :: n_dof = 6_i4
  real(wp), parameter :: kappa = 1.0e4_wp
  real(wp), parameter :: tol = 1.0e-8_wp
  integer(i4) :: ierr, i, nnz_ex
  real(wp) :: v11, v14, v41, v44
  real(wp) :: fv(n_dof)

  call init_error_status(st)
  call g_ufc_global%Init('l3_mpc_reg', 3_i4, st)
  if (st%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: UFC_Global_Init', st%status_code
    stop 1
  end if

  ! --- L3 MPC: (node 1, dof 1) - (node 2, dof 1) = 0  -> global eq 1 and 4 ---
  call MPCConstraintDef_Init(mpc, 'tie_ux', MPC_TYPE_GENERAL, st2)
  call MPCConstraintDef_AddTerm(mpc, 1_i4, 1_i4, 1.0_wp, st2)
  call MPCConstraintDef_AddTerm(mpc, 2_i4, 1_i4, -1.0_wp, st2)
  mpc%equation_rhs = 0.0_wp
  mpc%mpc_id = 1_i4
  if (st2%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: MPC build', st2%status_code
    call teardown(1)
  end if

  call g_ufc_global%md_layer%constraint%AddMPC(mpc, st2)
  call MPCConstraintDef_Cleanup(mpc, st2)
  if (st2%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: AddMPC', st2%status_code
    call teardown(1)
  end if

  ! --- 6x6 identity CSR ---
  call RT_Triplet_Init(tl, 32_i4)
  do i = 1, n_dof
    call RT_Triplet_Add(tl, i, i, 1.0_wp)
  end do
  call RT_CSR_FromTripletMerged(tl, n_dof, n_dof, K, ierr)
  call RT_Triplet_Free(tl)
  if (ierr /= 0_i4) then
    write (*, *) 'FAIL: CSR identity ierr=', ierr
    call teardown(1)
  end if

  ! --- A) RT_Asm_ApplyL3Constraints: MPC penalty merge (production path) ---
  fv = 0.0_wp
  cfg = RT_Asm_Cfg()
  cfg%apply_l3_constraints = .true.
  cfg%mpc_penalty_triplet_merge = .true.
  cfg%constraint_penalty = kappa
  cfg%l3_non_mpc_triplet_merge = .false.
  call RT_Asm_ApplyL3Constraints(K, fv, cfg, st2)
  if (st2%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: RT_Asm_ApplyL3Constraints', st2%status_code, trim(st2%message)
    call teardown(1)
  end if
  v11 = csr_entry(K, 1_i4, 1_i4)
  v14 = csr_entry(K, 1_i4, 4_i4)
  v41 = csr_entry(K, 4_i4, 1_i4)
  v44 = csr_entry(K, 4_i4, 4_i4)
  if (abs(v11 - (1.0_wp + kappa)) > tol * kappa) then
    write (*, *) 'FAIL: K(1,1) expected 1+kappa, got ', v11
    call teardown(1)
  end if
  if (abs(v14 - (-kappa)) > tol * kappa) then
    write (*, *) 'FAIL: K(1,4) expected -kappa, got ', v14
    call teardown(1)
  end if
  if (abs(v41 - (-kappa)) > tol * kappa) then
    write (*, *) 'FAIL: K(4,1) expected -kappa, got ', v41
    call teardown(1)
  end if
  if (abs(v44 - (1.0_wp + kappa)) > tol * kappa) then
    write (*, *) 'FAIL: K(4,4) expected 1+kappa, got ', v44
    call teardown(1)
  end if

  call RT_CSR_Free(K)

  ! --- B) PH: elimination + constraint residual (gold: g=0 for u1=u4) ---
  call RT_Triplet_Init(tl, 32_i4)
  do i = 1, n_dof
    call RT_Triplet_Add(tl, i, i, 1.0_wp)
  end do
  call RT_CSR_FromTripletMerged(tl, n_dof, n_dof, K, ierr)
  call RT_Triplet_Free(tl)
  if (ierr /= 0_i4) then
    write (*, *) 'FAIL: CSR identity (B) ierr=', ierr
    call teardown(1)
  end if

  call ph_dom%Init(1_i4, st2)
  if (st2%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: PH Init', st2%status_code
    call RT_CSR_Free(K)
    call teardown(1)
  end if

  allocate (add_a%coeffs(2), add_a%dofs(2))
  add_a%nTerms = 2_i4
  add_a%coeffs(1) = 1.0_wp
  add_a%coeffs(2) = -1.0_wp
  add_a%dofs(1) = 1_i4
  add_a%dofs(2) = 4_i4
  add_a%rhs = 0.0_wp
  call ph_dom%AddMPCEquation(add_a)
  if (add_a%status%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: AddMPCEquation', add_a%status%status_code
    call ph_dom%Finalize()
    call RT_CSR_Free(K)
    call teardown(1)
  end if
  deallocate (add_a%coeffs, add_a%dofs)

  ext_a%nDOF = 0_i4
  allocate (ext_a%rowPtr(K%nRows + 1), ext_a%colInd(K%nnz), ext_a%values(K%nnz))
  ext_a%rowPtr = K%rowPtr
  ext_a%colInd(1:K%nnz) = K%colInd(1:K%nnz)
  ext_a%values(1:K%nnz) = K%values(1:K%nnz)
  call ph_dom%ExtendCSRForMPC(ext_a)
  if (ext_a%status%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: ExtendCSRForMPC', ext_a%status%status_code
    call ph_dom%Finalize()
    call RT_CSR_Free(K)
    call teardown(1)
  end if

  nnz_ex = ext_a%rowPtr_out(n_dof + 1) - 1
  allocate (elim_a%rowPtr(n_dof + 1), elim_a%colInd(nnz_ex), elim_a%values(nnz_ex), elim_a%R(n_dof))
  elim_a%nDOF = n_dof
  elim_a%rowPtr = ext_a%rowPtr_out
  elim_a%colInd(1:nnz_ex) = ext_a%colInd_out(1:nnz_ex)
  elim_a%values(1:nnz_ex) = ext_a%values_out(1:nnz_ex)
  elim_a%R = 0.0_wp

  if (allocated(ext_a%rowPtr_out)) deallocate (ext_a%rowPtr_out)
  if (allocated(ext_a%colInd_out)) deallocate (ext_a%colInd_out)
  if (allocated(ext_a%values_out)) deallocate (ext_a%values_out)
  deallocate (ext_a%rowPtr, ext_a%colInd, ext_a%values)

  call ph_dom%Apply_Elimination_CSR(elim_a)
  if (elim_a%status%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: Apply_Elimination_CSR', elim_a%status%status_code
    call ph_dom%Finalize()
    call RT_CSR_Free(K)
    call teardown(1)
  end if

  allocate (lam_a%u(n_dof))
  lam_a%u = 0.0_wp
  lam_a%u(1) = 1.0_wp
  lam_a%u(4) = 1.0_wp
  lam_a%nLambda = 0_i4
  call ph_dom%Update_Lambda(lam_a)
  if (lam_a%status%status_code /= IF_STATUS_OK) then
    write (*, *) 'FAIL: Update_Lambda', lam_a%status%status_code
    call ph_dom%Finalize()
    deallocate (lam_a%u)
    call RT_CSR_Free(K)
    call teardown(1)
  end if
  if (lam_a%maxViolation > tol) then
    write (*, *) 'FAIL: MPC residual maxViolation=', lam_a%maxViolation
    call ph_dom%Finalize()
    deallocate (lam_a%u)
    call RT_CSR_Free(K)
    call teardown(1)
  end if

  deallocate (lam_a%u)
  deallocate (elim_a%rowPtr, elim_a%colInd, elim_a%values, elim_a%R)
  call ph_dom%Finalize()
  call RT_CSR_Free(K)

  write (*, *) 'PASS: test_RT_Asm_L3_MPC (penalty merge + PH elim residual)'
  call teardown(0)

contains

  subroutine teardown(code)
    integer, intent(in) :: code
    if (g_ufc_global%IsReady()) call g_ufc_global%Finalize()
    stop code
  end subroutine teardown

  function csr_entry(A, row, col) result(val)
    type(RT_CSRMatrix), intent(in) :: A
    integer(i4), intent(in) :: row, col
    real(wp) :: val
    integer(i4) :: p, j0, p0, p1
    val = 0.0_wp
    if (.not. A%init) return
    if (row < 1_i4 .or. row > A%nRows) return
    p0 = A%rowPtr(row)
    p1 = A%rowPtr(row + 1) - 1
    do p = p0, p1
      j0 = A%colInd(p)
      if (j0 == col) val = A%values(p)
    end do
  end function csr_entry

end program test_RT_Asm_L3_MPC
