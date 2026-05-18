!===============================================================================
! MODULE: NM_Assem_Sparse
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Core — Assembly sparse types (TripletList, CSRMatrix) for L3_MD
! BRIEF:  RT_TripletList / RT_CSRMatrix types breaking L3->L5 build cycle
!===============================================================================
module NM_Assem_Sparse
  use IF_Err_Brg, only: ErrorStatusType, init_error_status
  use IF_Prec_Core, only: wp, i4
  implicit none
  private

  public :: RT_TripletList
  public :: RT_CSRMatrix
  public :: RT_COOEntry
  public :: RT_Triplet_Init
  public :: RT_Triplet_Add
  public :: RT_Triplet_Free
  public :: RT_CSR_FromTriplet
  public :: RT_CSR_Free
  public :: RT_CSR_SpMV

  !=============================================================================
  ! Types (binary-compatible with RT_SolvSparse / RT_Shared_Def)
  !=============================================================================
  type, public :: RT_COOEntry
    integer(i4) :: row = 0_i4
    integer(i4) :: col = 0_i4
    real(wp) :: val = 0.0_wp
  end type RT_COOEntry

  type, public :: RT_TripletList
    integer(i4) :: capacity = 0_i4
    integer(i4) :: nnz      = 0_i4
    integer(i4), allocatable :: row(:)
    integer(i4), allocatable :: col(:)
    real(wp),    allocatable :: val(:)
    logical :: use_mem_pool = .false.
    logical :: row_from_pool = .false.
    logical :: col_from_pool = .false.
    logical :: val_from_pool = .false.
  end type RT_TripletList

  type, public :: RT_CSRMatrix
    integer(i4) :: nRows = 0_i4
    integer(i4) :: nCols = 0_i4
    integer(i4) :: nnz = 0_i4
    integer(i4), allocatable :: rowPtr(:)
    integer(i4), allocatable :: colInd(:)
    real(wp), allocatable :: values(:)
    logical :: is_symmetric = .false.
    logical :: init = .false.
  contains
    procedure :: matvec => RT_CSRMatrix_matvec
  end type RT_CSRMatrix

contains

  subroutine RT_Triplet_Init(list, capacity)
    type(RT_TripletList), intent(inout) :: list
    integer(i4), intent(in), optional :: capacity
    integer(i4) :: ncap
    ncap = 128_i4
    if (present(capacity)) ncap = max(1_i4, capacity)
    if (allocated(list%row)) deallocate(list%row, list%col, list%val)
    list%capacity = ncap
    list%nnz = 0_i4
    allocate(list%row(ncap), list%col(ncap), list%val(ncap))
  end subroutine RT_Triplet_Init

  subroutine RT_Triplet_Add(list, i, j, v)
    type(RT_TripletList), intent(inout) :: list
    integer(i4), intent(in) :: i, j
    real(wp), intent(in) :: v
    integer(i4) :: newCap
    integer(i4), allocatable :: r(:), c(:)
    real(wp), allocatable :: a(:)
    if (.not. allocated(list%row)) call RT_Triplet_Init(list, 128_i4)
    if (list%nnz >= list%capacity) then
      newCap = max(2_i4 * list%capacity, list%capacity + 128_i4)
      allocate(r(newCap), c(newCap), a(newCap))
      if (list%nnz > 0) then
        r(1:list%nnz) = list%row(1:list%nnz)
        c(1:list%nnz) = list%col(1:list%nnz)
        a(1:list%nnz) = list%val(1:list%nnz)
      end if
      deallocate(list%row, list%col, list%val)
      call move_alloc(r, list%row)
      call move_alloc(c, list%col)
      call move_alloc(a, list%val)
      list%capacity = newCap
    end if
    list%nnz = list%nnz + 1_i4
    list%row(list%nnz) = i
    list%col(list%nnz) = j
    list%val(list%nnz) = v
  end subroutine RT_Triplet_Add

  subroutine RT_Triplet_Free(list)
    type(RT_TripletList), intent(inout) :: list
    if (allocated(list%row)) deallocate(list%row)
    if (allocated(list%col)) deallocate(list%col)
    if (allocated(list%val)) deallocate(list%val)
    list%capacity = 0_i4
    list%nnz = 0_i4
  end subroutine RT_Triplet_Free

  subroutine csr_init_from_coo(A, nRows, nCols, coo, nEntries, ierr)
    type(RT_CSRMatrix), intent(inout) :: A
    integer(i4), intent(in) :: nRows, nCols, nEntries
    type(RT_COOEntry), intent(in) :: coo(:)
    integer(i4), intent(out) :: ierr
    integer(i4) :: i, j, k, nnz
    integer(i4), allocatable :: rowCounts(:), rowStart(:)
    ierr = 0_i4
    nnz = max(nEntries, 0_i4)
    if (allocated(A%rowPtr)) deallocate(A%rowPtr)
    if (allocated(A%colInd)) deallocate(A%colInd)
    if (allocated(A%values)) deallocate(A%values)
    A%nRows = nRows
    A%nCols = nCols
    A%nnz = nnz
    if (nnz == 0_i4) then
      allocate(A%rowPtr(nRows + 1))
      A%rowPtr = 1_i4
      A%init = .true.
      return
    end if
    allocate(rowCounts(nRows), rowStart(nRows))
    rowCounts = 0_i4
    do i = 1, nnz
      if (coo(i)%row >= 1_i4 .and. coo(i)%row <= nRows) &
        rowCounts(coo(i)%row) = rowCounts(coo(i)%row) + 1_i4
    end do
    allocate(A%rowPtr(nRows + 1))
    A%rowPtr(1) = 1_i4
    do i = 2, nRows + 1
      A%rowPtr(i) = A%rowPtr(i-1) + rowCounts(i-1)
    end do
    allocate(A%colInd(nnz), A%values(nnz))
    rowStart = A%rowPtr(1:nRows)
    do i = 1, nnz
      j = coo(i)%row
      if (j >= 1_i4 .and. j <= nRows) then
        k = rowStart(j)
        if (k <= A%rowPtr(j+1) - 1) then
          A%colInd(k) = coo(i)%col
          A%values(k) = coo(i)%val
          rowStart(j) = rowStart(j) + 1_i4
        end if
      end if
    end do
    deallocate(rowCounts, rowStart)
    A%init = .true.
  end subroutine csr_init_from_coo

  subroutine RT_CSR_FromTriplet(list, nRows, nCols, A)
    type(RT_TripletList), intent(in) :: list
    integer(i4), intent(in) :: nRows, nCols
    type(RT_CSRMatrix), intent(inout) :: A
    integer(i4) :: nEntries, k, ierr
    type(RT_COOEntry), allocatable :: coo(:)
    nEntries = list%nnz
    if (nEntries <= 0_i4) then
      allocate(coo(1))
      call csr_init_from_coo(A, nRows, nCols, coo, 0_i4, ierr)
      deallocate(coo)
      return
    end if
    allocate(coo(nEntries))
    do k = 1, nEntries
      coo(k)%row = list%row(k)
      coo(k)%col = list%col(k)
      coo(k)%val = list%val(k)
    end do
    call csr_init_from_coo(A, nRows, nCols, coo, nEntries, ierr)
    deallocate(coo)
  end subroutine RT_CSR_FromTriplet

  subroutine RT_CSR_Free(A)
    type(RT_CSRMatrix), intent(inout) :: A
    if (allocated(A%rowPtr)) deallocate(A%rowPtr)
    if (allocated(A%colInd)) deallocate(A%colInd)
    if (allocated(A%values)) deallocate(A%values)
    A%nRows = 0_i4
    A%nCols = 0_i4
    A%nnz = 0_i4
    A%init = .false.
  end subroutine RT_CSR_Free

  subroutine RT_CSR_SpMV(A, x, y)
    type(RT_CSRMatrix), intent(in) :: A
    real(wp), intent(in) :: x(:)
    real(wp), intent(out) :: y(:)
    call A%matvec(x, y)
  end subroutine RT_CSR_SpMV

  subroutine RT_CSRMatrix_matvec(this, x, y)
    class(RT_CSRMatrix), intent(in) :: this
    real(wp), intent(in) :: x(:)
    real(wp), intent(out) :: y(:)
    integer(i4) :: i, j, k
    y = 0.0_wp
    if (.not. this%init .or. size(x) /= this%nCols .or. size(y) /= this%nRows) return
    do i = 1, this%nRows
      do k = this%rowPtr(i), this%rowPtr(i+1) - 1
        j = this%colInd(k)
        y(i) = y(i) + this%values(k) * x(j)
      end do
    end do
  end subroutine RT_CSRMatrix_matvec

end module NM_Assem_Sparse