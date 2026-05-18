! LEGACY: External third-party library - exempt from UFC naming/style conventions
module hsl_mi20_double_ciface
   use hsl_mi20_double, only:                    &
      f_mi20_data          => mi20_data,         &
      f_mi20_keep          => mi20_keep,         &
      f_mi20_control       => mi20_control,      &
      f_mi20_solve_control => mi20_solve_control,&
      f_mi20_info          => mi20_info,         &
      f_mi20_setup         => mi20_setup,        &
      f_mi20_setup_csr     => mi20_setup_csr,    &
      f_mi20_setup_csc     => mi20_setup_csc,    &
      f_mi20_setup_coord   => mi20_setup_coord,  &
      f_mi20_finalize      => mi20_finalize,     &
      f_mi20_precondition  => mi20_precondition, &
      f_mi20_solve         => mi20_solve
   use hsl_zd11_double, only:                    &
      f_zd11_type          => zd11_type,         &
      f_zd11_put           => zd11_put
   use iso_c_binding
   implicit none

   integer, parameter :: wp = C_DOUBLE

   type, bind(C) :: mi20_control
      integer(C_INT) :: f_arrays ! true (!=0) or false (==0)
      integer(C_INT) :: aggressive
      integer(C_INT) :: c_fail
      integer(C_INT) :: max_levels
      integer(C_INT) :: max_points
      real(wp) :: reduction
      integer(C_INT) :: st_method
      real(wp) :: st_parameter
      integer(C_INT) :: testing
      real(wp) :: trunc_parameter
      integer(C_INT) :: coarse_solver
      integer(C_INT) :: coarse_solver_its
      real(wp) :: damping
      real(wp) :: err_tol
      integer(C_INT) :: levels
      integer(C_INT) :: pre_smoothing
      integer(C_INT) :: smoother
      integer(C_INT) :: post_smoothing
      integer(C_INT) :: v_iterations
      integer(C_INT) :: print_level
      integer(C_INT) :: print
      integer(C_INT) :: error
      integer(C_INT) :: one_pass_coarsen
   end type mi20_control

   type, bind(C) :: mi20_solve_control
      real(wp) ::  abs_tol
      real(wp) ::  breakdown_tol  
      integer(C_INT) :: gmres_restart 
      logical(C_BOOL) :: init_guess  
      integer(C_INT) :: krylov_solver  
      integer(C_INT) :: max_its  
      integer(C_INT) :: preconditioner_side  
      real(wp) ::  rel_tol  
   end type mi20_solve_control

   type, bind(C) :: mi20_info
      integer(C_INT) :: flag
      integer(C_INT) :: clevels
      integer(C_INT) :: cpoints
      integer(C_INT) :: cnnz
      integer(C_INT) :: stat
      integer(C_INT) :: getrf_info
      integer(C_INT) :: iterations
      real(wp) :: residual
   end type mi20_info

   type ciface_keep_type
      type(f_zd11_type) :: matrix
      type(f_mi20_data), dimension(:), allocatable :: data
      type(f_mi20_keep) :: keep
   end type ciface_keep_type
contains
   subroutine copy_control_in(ccontrol, fcontrol, f_arrays)
      type(mi20_control), intent(in) :: ccontrol
      type(f_mi20_control), intent(out) :: fcontrol
      logical, intent(out) :: f_arrays

      f_arrays                = (ccontrol%f_arrays.ne.0)
      fcontrol%aggressive     = ccontrol%aggressive
      fcontrol%c_fail         = ccontrol%c_fail
      fcontrol%max_levels     = ccontrol%max_levels
      fcontrol%max_points     = ccontrol%max_points
      fcontrol%reduction      = ccontrol%reduction
      fcontrol%st_method      = ccontrol%st_method
      fcontrol%st_parameter   = ccontrol%st_parameter
      fcontrol%testing        = ccontrol%testing
      fcontrol%trunc_parameter= ccontrol%trunc_parameter
      fcontrol%coarse_solver  = ccontrol%coarse_solver
      fcontrol%coarse_solver_its = ccontrol%coarse_solver_its
      fcontrol%damping        = ccontrol%damping
      fcontrol%err_tol        = ccontrol%err_tol
      fcontrol%levels         = ccontrol%levels
      fcontrol%pre_smoothing  = ccontrol%pre_smoothing
      fcontrol%smoother       = ccontrol%smoother
      fcontrol%post_smoothing = ccontrol%post_smoothing
      fcontrol%v_iterations   = ccontrol%v_iterations
      fcontrol%print_level    = ccontrol%print_level
      fcontrol%print          = ccontrol%print
      fcontrol%error          = ccontrol%error
      fcontrol%one_pass_coarsen = (ccontrol%one_pass_coarsen.ne.0)
   end subroutine copy_control_in

   subroutine copy_info_out(finfo, cinfo)
      type(f_mi20_info), intent(in) :: finfo
      type(mi20_info), intent(out) :: cinfo

      cinfo%flag        = finfo%flag
      cinfo%clevels     = finfo%clevels
      cinfo%cpoints     = finfo%cpoints
      cinfo%cnnz        = finfo%cnnz
      cinfo%stat        = finfo%stat
      cinfo%getrf_info  = finfo%getrf_info
      cinfo%residual    = finfo%residual
      cinfo%iterations  = finfo%iterations
   end subroutine copy_info_out

   subroutine copy_solve_control_in(csolve_control, fsolve_control)
      type(mi20_solve_control), intent(in) :: csolve_control
      type(f_mi20_solve_control), intent(out) :: fsolve_control

      fsolve_control%abs_tol             = csolve_control%abs_tol          
      fsolve_control%breakdown_tol       = csolve_control%breakdown_tol
      fsolve_control%gmres_restart       = csolve_control%gmres_restart
      fsolve_control%init_guess          = csolve_control%init_guess
      fsolve_control%krylov_solver       = csolve_control%krylov_solver
      fsolve_control%max_its             = csolve_control%max_its  
      fsolve_control%preconditioner_side = csolve_control%preconditioner_side
      fsolve_control%rel_tol             = csolve_control%rel_tol  
   end subroutine copy_solve_control_in

subroutine mi20_default_control_d(ccontrol) bind(C)
   use hsl_mi20_double_ciface
   implicit none

   type(mi20_control), intent(out) :: ccontrol

   type(f_mi20_control) :: fcontrol

   ccontrol%f_arrays          = 0 ! (false) default to C style arrays
   ccontrol%aggressive        = fcontrol%aggressive
   ccontrol%c_fail            = fcontrol%c_fail
   ccontrol%max_levels        = fcontrol%max_levels
   ccontrol%max_points        = fcontrol%max_points
   ccontrol%reduction         = fcontrol%reduction
   ccontrol%st_method         = fcontrol%st_method
   ccontrol%st_parameter      = fcontrol%st_parameter
   ccontrol%testing           = fcontrol%testing
   ccontrol%trunc_parameter   = fcontrol%trunc_parameter
   ccontrol%coarse_solver     = fcontrol%coarse_solver
   ccontrol%coarse_solver_its = fcontrol%coarse_solver_its
   ccontrol%damping           = fcontrol%damping
   ccontrol%err_tol           = fcontrol%err_tol
   ccontrol%levels            = fcontrol%levels
   ccontrol%pre_smoothing     = fcontrol%pre_smoothing
   ccontrol%smoother          = fcontrol%smoother
   ccontrol%post_smoothing    = fcontrol%post_smoothing
   ccontrol%v_iterations      = fcontrol%v_iterations
   ccontrol%print_level       = fcontrol%print_level
   ccontrol%print             = fcontrol%print
   ccontrol%error             = fcontrol%error
   ccontrol%one_pass_coarsen  = 0 ! false
   if(fcontrol%one_pass_coarsen) ccontrol%one_pass_coarsen = 1 ! true
end subroutine mi20_default_control_d

subroutine mi20_default_solve_control_d(csolve_control) bind(C)
  use hsl_mi20_double_ciface
  implicit none
  
  type(mi20_solve_control), intent(out) :: csolve_control

  type(f_mi20_solve_control) :: fsolve_control

!  csolve_control%f_arrrays     = 0 ! (false) default to C style arrays
  csolve_control%abs_tol             = fsolve_control%abs_tol          
  csolve_control%breakdown_tol       = fsolve_control%breakdown_tol
  csolve_control%gmres_restart       = fsolve_control%gmres_restart
  csolve_control%init_guess          = fsolve_control%init_guess
  csolve_control%krylov_solver       = fsolve_control%krylov_solver
  csolve_control%max_its             = fsolve_control%max_its  
  csolve_control%preconditioner_side = fsolve_control%preconditioner_side
  csolve_control%rel_tol             = fsolve_control%rel_tol  

end subroutine mi20_default_solve_control_d

subroutine mi20_finalize_d(ckeep, ccontrol, cinfo) bind(C)
   use hsl_mi20_double_ciface
   implicit none

   type(C_PTR) :: ckeep
   type(mi20_control), intent(in) :: ccontrol
   type(mi20_info) :: cinfo

   logical :: f_arrays
   type(ciface_keep_type), pointer :: fkeep_wrap
   type(f_mi20_control) :: fcontrol
   type(f_mi20_info) :: finfo

   ! Copy data in and associate pointers correctly
   call C_F_POINTER(ckeep, fkeep_wrap)
   call copy_control_in(ccontrol, fcontrol, f_arrays)

   ! Call the Fortran routine
   call f_mi20_finalize(fkeep_wrap%data, fkeep_wrap%keep, fcontrol, finfo)

   ! Free memory
   deallocate(fkeep_wrap)
   ckeep = C_NULL_PTR

   ! Copy data out
   call copy_info_out(finfo, cinfo)

end subroutine mi20_finalize_d

subroutine mi20_precondition_d(crhs, csolution, ckeep, ccontrol, cinfo) bind(C)
   use hsl_mi20_double_ciface
   implicit none

   type(C_PTR), value :: crhs
   type(C_PTR), value :: csolution
   type(C_PTR) :: ckeep
   type(mi20_control), intent(in) :: ccontrol
   type(mi20_info) :: cinfo

   logical :: f_arrays
   real(wp), dimension(:), pointer :: frhs
   real(wp), dimension(:), pointer :: fsolution
   type(ciface_keep_type), pointer :: fkeep_wrap
   type(f_mi20_control) :: fcontrol
   type(f_mi20_info) :: finfo

   ! Copy data in and associate pointers correctly
   call copy_control_in(ccontrol, fcontrol, f_arrays)
   call C_F_POINTER(ckeep, fkeep_wrap)
   call C_F_POINTER(crhs, frhs, shape = (/ fkeep_wrap%keep%A%n /))
   call C_F_POINTER(csolution, fsolution, shape = (/ fkeep_wrap%keep%A%n /))

   ! Call the Fortran routine
   call f_mi20_precondition(fkeep_wrap%data, frhs, &
      fsolution, fkeep_wrap%keep, fcontrol, finfo)

   ! Copy data out
   call copy_info_out(finfo, cinfo)
end subroutine mi20_precondition_d

subroutine mi20_setup_coord_d(n, ne, crow, ccol, cval, ckeep, ccontrol, cinfo) &
      bind(C)
   use hsl_mi20_double_ciface
   implicit none

   integer(C_INT), value, intent(in) :: n, ne
   type(C_PTR), value :: crow
   type(C_PTR), value :: ccol
   type(C_PTR), value :: cval
   type(C_PTR) :: ckeep
   type(mi20_control), intent(in) :: ccontrol
   type(mi20_info), intent(out) :: cinfo

   logical :: f_arrays
   integer(C_INT), dimension(:), pointer :: frow, fcol
   integer(C_INT), dimension(:), allocatable :: frow_copy, fcol_copy
   real(wp), dimension(:), pointer :: fval
   type(ciface_keep_type), pointer :: fkeep_wrap
   type(f_mi20_control) :: fcontrol
   type(f_mi20_info) :: finfo

   ! Copy data in and associate pointers correctly
   call copy_control_in(ccontrol, fcontrol, f_arrays)
   allocate(fkeep_wrap)
   ckeep = C_LOC(fkeep_wrap)

   call C_F_POINTER(crow, frow, shape = (/ ne /))
   allocate(frow_copy(ne))
   frow_copy = frow
   if( .not. f_arrays)  then
      frow_copy(:) = frow_copy(:) + 1
   end if
   
   call C_F_POINTER(ccol, fcol, shape = (/ ne /))
   allocate(fcol_copy(ne))
   fcol_copy = fcol
   if(.not. f_arrays) then
      fcol_copy(:) = fcol_copy(:) + 1
   end if

   call C_F_POINTER(cval, fval, shape = (/ ne /))

   ! Call the Fortran routine
   call f_mi20_setup_coord(frow_copy, fcol_copy, fval, ne, n, fkeep_wrap%data, &
                         fkeep_wrap%keep, fcontrol, finfo)

   ! Copy data out
   call copy_info_out(finfo, cinfo)

end subroutine mi20_setup_coord_d

subroutine mi20_setup_csc_d(n, cptr, crow, cval, ckeep, ccontrol, cinfo) bind(C)
   use hsl_mi20_double_ciface
   implicit none

   integer(C_INT), value, intent(in) :: n
   type(C_PTR), value :: cptr
   type(C_PTR), value :: crow
   type(C_PTR), value :: cval
   type(C_PTR) :: ckeep
   type(mi20_control), intent(in) :: ccontrol
   type(mi20_info), intent(out) :: cinfo

   logical :: f_arrays
   integer(C_INT), dimension(:), pointer :: fptr, frow
   integer(C_INT), dimension(:), allocatable :: fptr_copy, frow_copy
   real(wp), dimension(:), pointer :: fval
   type(ciface_keep_type), pointer :: fkeep_wrap
   type(f_mi20_control) :: fcontrol
   type(f_mi20_info) :: finfo
   integer(C_INT) :: ne

   ! Copy data in and associate pointers correctly
   call copy_control_in(ccontrol, fcontrol, f_arrays)
   allocate(fkeep_wrap)
   ckeep = C_LOC(fkeep_wrap)

   call C_F_POINTER(cptr, fptr, shape = (/ n+1 /))
   allocate(fptr_copy(n+1))
   fptr_copy = fptr
   if( .not. f_arrays)  then
      fptr_copy(:) = fptr_copy(:) + 1
   end if

   ne = fptr(n+1)
   
   call C_F_POINTER(crow, frow, shape = (/ ne /))
   allocate(frow_copy(ne))
   frow_copy = frow
   if(.not. f_arrays) then
      frow_copy(:) = frow_copy(:) + 1
   end if

   call C_F_POINTER(cval, fval, shape = (/ ne /))

   ! Call the Fortran routine
   call f_mi20_setup_csc(fptr_copy, frow_copy, fval, ne, n, fkeep_wrap%data, &
                         fkeep_wrap%keep, fcontrol, finfo)

   ! Copy data out
   call copy_info_out(finfo, cinfo)

end subroutine mi20_setup_csc_d

subroutine mi20_setup_csr_d(n, cptr, ccol, cval, ckeep, ccontrol, cinfo) bind(C)
   use hsl_mi20_double_ciface
   implicit none

   integer(C_INT), value, intent(in) :: n
   type(C_PTR), value :: cptr
   type(C_PTR), value :: ccol
   type(C_PTR), value :: cval
   type(C_PTR) :: ckeep
   type(mi20_control), intent(in) :: ccontrol
   type(mi20_info), intent(out) :: cinfo

   logical :: f_arrays
   integer(C_INT), dimension(:), pointer :: fptr, fcol
   integer(C_INT), dimension(:), allocatable :: fptr_copy, fcol_copy
   real(wp), dimension(:), pointer :: fval
   type(ciface_keep_type), pointer :: fkeep_wrap
   type(f_mi20_control) :: fcontrol
   type(f_mi20_info) :: finfo
   integer(C_INT) :: ne

   ! Copy data in and associate pointers correctly
   call copy_control_in(ccontrol, fcontrol, f_arrays)
   allocate(fkeep_wrap)
   ckeep = C_LOC(fkeep_wrap)

   call C_F_POINTER(cptr, fptr, shape = (/ n+1 /))
   allocate(fptr_copy(n+1))
   fptr_copy = fptr
   if( .not. f_arrays)  then
      fptr_copy(:) = fptr_copy(:) + 1
   end if

   ne = fptr(n+1)
   
   call C_F_POINTER(ccol, fcol, shape = (/ ne /))
   allocate(fcol_copy(ne))
   fcol_copy = fcol
   if(.not. f_arrays) then
      fcol_copy(:) = fcol_copy(:) + 1
   end if

   call C_F_POINTER(cval, fval, shape = (/ ne /))

   ! Call the Fortran routine
   call f_mi20_setup_csr(fptr_copy, fcol_copy, fval, ne, n, fkeep_wrap%data, &
                         fkeep_wrap%keep, fcontrol, finfo)

   ! Copy data out
   call copy_info_out(finfo, cinfo)

end subroutine mi20_setup_csr_d

subroutine mi20_setup_d(n, cptr, ccol, cval, ckeep, ccontrol, cinfo) bind(C)
   use hsl_mi20_double_ciface
   implicit none

   integer(C_INT), value, intent(in) :: n
   type(C_PTR), value :: cptr
   type(C_PTR), value :: ccol
   type(C_PTR), value :: cval
   type(C_PTR) :: ckeep
   type(mi20_control), intent(in) :: ccontrol
   type(mi20_info), intent(out) :: cinfo

   integer(C_INT), dimension(:), pointer :: fptr

! explicit interface to mi20_setup_csr_d
   interface
      subroutine mi20_setup_csr_d(n, cptr, ccol, cval, ckeep, ccontrol, cinfo) &
            bind(C)
        use hsl_mi20_double_ciface
        implicit none
        integer(C_INT), value, intent(in) :: n
        type(C_PTR), value :: cptr
        type(C_PTR), value :: ccol
        type(C_PTR), value :: cval
        type(C_PTR) :: ckeep
        type(mi20_control), intent(in) :: ccontrol
        type(mi20_info), intent(out) :: cinfo
      end subroutine mi20_setup_csr_d
   end interface

   call C_F_POINTER(cptr, fptr, shape = (/ n+1 /))
   
   call mi20_setup_csr_d(n, cptr, ccol, cval, ckeep, ccontrol, cinfo)

end subroutine mi20_setup_d

subroutine mi20_solve_d(crhs, csolution, ckeep, ccontrol, csolve_control, &
      cinfo) bind(C)
   use hsl_mi20_double_ciface
   implicit none

   type(C_PTR), value :: crhs
   type(C_PTR), value :: csolution
   type(C_PTR) :: ckeep
   type(mi20_control), intent(in) :: ccontrol
   type(mi20_solve_control), intent(in) :: csolve_control
   type(mi20_info) :: cinfo

   logical :: f_arrays
   real(wp), dimension(:), pointer :: frhs
   real(wp), dimension(:), pointer :: fsolution
   type(ciface_keep_type), pointer :: fkeep_wrap
   type(f_mi20_control) :: fcontrol
   type(f_mi20_solve_control) :: fsolve_control
   type(f_mi20_info) :: finfo

   ! Copy data in and associate pointers correctly
   call copy_control_in(ccontrol, fcontrol, f_arrays)
   call copy_solve_control_in(csolve_control,fsolve_control)
   call C_F_POINTER(ckeep, fkeep_wrap)
   call C_F_POINTER(crhs, frhs, shape = (/ fkeep_wrap%keep%A%n /))
   call C_F_POINTER(csolution, fsolution, shape = (/ fkeep_wrap%keep%A%n /))

   ! Call the Fortran routine
   
   call f_mi20_solve(fkeep_wrap%data, frhs, &
      fsolution, fkeep_wrap%keep, fcontrol, fsolve_control, finfo)
   
   ! Copy data out
   call copy_info_out(finfo, cinfo)
end subroutine mi20_solve_d