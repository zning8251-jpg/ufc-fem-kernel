!===============================================================================
! MODULE: RT_Solv_Sparse
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Util (Sparse)
! BRIEF:  Sparse CSR matrix operations: SpMV / factorization / direct solve
!===============================================================================
!
! Process族:
!   P0: Init (Triplet_Init, LU_Setup)          [COLD_PATH]
!   P1: Populate (Triplet_Add, CSR_FromTriplet) [HOT_PATH]
!   P2: Compute (CSR_SpMV, LU_Solv)            [HOT_PATH]
!   P0: Finalize (Triplet_Free, LU_Destroy)    [COLD_PATH]
!
! Status: SIO-REFACTORED | Last verified: 2026-04-28
!===============================================================================

module RT_Solv_Sparse
  !! Sparse matrix utilities: COO/Triplet, CSR, BlockCSR, LU factorization.
  !! Clients: RT_Solv_Lin, RT_Solv_Mgr.

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status
  USE IF_Prec_Core, only: wp, i4
  USE NM_Assem_Sparse, only: RT_TripletList, RT_COOEntry, RT_CSRMatrix, RT_CSR_Free
  USE RT_Shared_Def, only: RT_Sol_DofMap, RT_Sol_Cfg
  ! RT_CoreMemPool temporarily disabled - using standard ALLOCATE/DEALLOCATE
  ! use RT_CoreMemPool, only: g_core_mem_pool
  use NM_Solv_Direct, only: UF_LUFactor, direct_lu_factor, direct_lu_solve

  implicit none
  private

  public :: RT_COOEntry
  public :: RT_TripletList
  public :: RT_LUHandle
  public :: RT_BlockCSRMatrix
  public :: RT_Triplet_Init
  public :: RT_Triplet_Add
  public :: RT_Triplet_Free
  public :: RT_CSR_FromTriplet
  public :: RT_CSR_FromTripletMerged
  public :: RT_CSR_SpMV
  public :: RT_CSR_AddToValue
  public :: RT_BlockCSR_FromTriplet
  public :: RT_BlockCSR_Free
  public :: RT_LU_Setup_FromCSR
  public :: RT_LU_Solv
  public :: RT_LU_Destroy
  public :: RT_LinearSolve_Direct

  ! RT_TripletList, RT_COOEntry, RT_CSRMatrix: from NM_AssemSparse (L2_NM)

  !=============================================================================
  ! Sparse Matrix Types (RT_LUHandle, RT_BlockCSRMatrix use RT_CSRMatrix)
  !=============================================================================
  type, public :: RT_LUHandle
    type(RT_CSRMatrix) :: A_L3
    type(UF_LUFactor)  :: LU
    logical            :: isInitd = .false.
  end type RT_LUHandle

  type, public :: RT_BlockCSRMatrix
    integer(i4) :: nFields = 0_i4
    integer(i4), allocatable :: fieldEqCount(:)
    type(RT_CSRMatrix), allocatable :: blocks(:,:)
  end type RT_BlockCSRMatrix
  ! Phase3 S5.4.1 Ownership and lifecycle (RT layer).
  !   RT_CSRMatrix: create via RT_CSR_FromTriplet / csr_init_from_coo; free via RT_CSR_Free / csr_destroy; caller owns.
  !   RT_LUHandle: create via RT_LU_Setup_FromCSR, free via RT_LU_Destroy; caller must free before reuse.
  !   RT_BlockCSRMatrix: create via RT_BlockCSR_FromTriplet, free via RT_BlockCSR_Free.
  ! Phase3 S5.3.1 Assembly path here; RT_BlockCSR_FromTriplet has numcore/block structure support; Brg for GPU interface.
  !   RT_BlockCSRMatrix RT_BlockCSR_FromTriplet RT_BlockCSR_Free ??
  ! Phase3 S5.3.1 ? ?? RT_BlockCSR_FromTriplet numcore ???? Brg ? ))

contains

  subroutine csr_init_from_coo(A, nRows, nCols, coo, nEntries, ierr)
    type(RT_CSRMatrix), intent(inout) :: A
    integer(i4), intent(in) :: nRows, nCols, nEntries
    type(RT_COOEntry), intent(in) :: coo(:)
    integer(i4), intent(out) :: ierr

    integer(i4) :: i, j, k, nnz
    integer(i4), allocatable :: rowCounts(:), rowStart(:)

    ierr = 0_i4
    nnz = max(nEntries, 0_i4)

    if (A%init) call RT_CSR_Free(A)

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
      if (coo(i)%row >= 1_i4 .and. coo(i)%row <= nRows) then
        rowCounts(coo(i)%row) = rowCounts(coo(i)%row) + 1_i4
      end if
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

  subroutine RT_Triplet_Init(list, capacity)
    type(RT_TripletList), intent(inout) :: list
    integer(i4),          intent(in)    :: capacity

    integer(i4) :: ncap
    type(ErrorStatusType) :: mem_status

    call init_error_status(mem_status)
    list%use_mem_pool = .false.  ! Memory pool disabled
    list%row_from_pool = .false.
    list%col_from_pool = .false.
    list%val_from_pool = .false.

    if (allocated(list%row)) then
      deallocate(list%row, list%col, list%val)
    end if

    ncap = max(1_i4, capacity)
    list%capacity = ncap
    list%nnz      = 0_i4

    if (list%use_mem_pool) then
      ! call g_core_mem_pool%AllocInt1D('triplet_row', ncap, list%row, mem_status)
      if (mem_status%status_code /= 0) then
        allocate(list%row(ncap))
      else
        list%row_from_pool = .true.
      end if
    else
      allocate(list%row(ncap))
    end if

    if (list%use_mem_pool) then
      ! call g_core_mem_pool%AllocInt1D('triplet_col', ncap, list%col, mem_status)
      if (mem_status%status_code /= 0) then
        allocate(list%col(ncap))
      else
        list%col_from_pool = .true.
      end if
    else
      allocate(list%col(ncap))
    end if

    if (list%use_mem_pool) then
      ! call g_core_mem_pool%AllocDP1D('triplet_val', ncap, list%val, mem_status)
      if (mem_status%status_code /= 0) then
        allocate(list%val(ncap))
      else
        list%val_from_pool = .true.
      end if
    else
      allocate(list%val(ncap))
    end if
  end subroutine RT_Triplet_Init

  subroutine RT_Triplet_Add(list, i, j, v)
    type(RT_TripletList), intent(inout) :: list
    integer(i4),          intent(in)    :: i, j
    real(wp),             intent(in)    :: v

    integer(i4) :: newCap

    if (.not. allocated(list%row)) then
      call RT_Triplet_Init(list, 128_i4)
    end if

    if (list%nnz >= list%capacity) then
      newCap = max(2_i4*list%capacity, list%capacity + 128_i4)
      call extendTriplet(list, newCap)
    end if

    list%nnz = list%nnz + 1_i4
    list%row(list%nnz) = i
    list%col(list%nnz) = j
    list%val(list%nnz) = v
  contains
    subroutine extendTriplet(lst, newCap)
      type(RT_TripletList), intent(inout) :: lst
      integer(i4),          intent(in)    :: newCap
      integer(i4), allocatable :: r(:), c(:)
      real(wp),    allocatable :: a(:)
      integer(i4) :: nold
      type(ErrorStatusType) :: mem_status
      logical :: r_from_pool, c_from_pool, a_from_pool

      call init_error_status(mem_status)
      r_from_pool = .false.
      c_from_pool = .false.
      a_from_pool = .false.

      nold = lst%nnz

      if (lst%use_mem_pool) then
        ! call g_core_mem_pool%AllocInt1D('triplet_extend_r', newCap, r, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(r(newCap))
        else
          r_from_pool = .true.
        end if
      else
        allocate(r(newCap))
      end if

      if (lst%use_mem_pool) then
        ! call g_core_mem_pool%AllocInt1D('triplet_extend_c', newCap, c, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(c(newCap))
        else
          c_from_pool = .true.
        end if
      else
        allocate(c(newCap))
      end if

      if (lst%use_mem_pool) then
        ! call g_core_mem_pool%AllocDP1D('triplet_extend_a', newCap, a, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(a(newCap))
        else
          a_from_pool = .true.
        end if
      else
        allocate(a(newCap))
      end if

      if (nold > 0) then
        r(1:nold) = lst%row(1:nold)
        c(1:nold) = lst%col(1:nold)
        a(1:nold) = lst%val(1:nold)
      end if

      if (lst%row_from_pool) then
        ! call g_core_mem_pool%Dealloc('triplet_row')
      else
        if (allocated(lst%row)) deallocate(lst%row)
      end if
      if (lst%col_from_pool) then
        ! call g_core_mem_pool%Dealloc('triplet_col')
      else
        if (allocated(lst%col)) deallocate(lst%col)
      end if
      if (lst%val_from_pool) then
        ! call g_core_mem_pool%Dealloc('triplet_val')
      else
        if (allocated(lst%val)) deallocate(lst%val)
      end if

      lst%row = r
      lst%col = c
      lst%val = a
      lst%capacity = newCap

      lst%row_from_pool = r_from_pool
      lst%col_from_pool = c_from_pool
      lst%val_from_pool = a_from_pool
    end subroutine extendTriplet
  end subroutine RT_Triplet_Add

  subroutine RT_Triplet_Free(list)
    type(RT_TripletList), intent(inout) :: list

    ! Memory pool disabled - always use standard DEALLOCATE
    if (allocated(list%row)) deallocate(list%row)
    if (allocated(list%col)) deallocate(list%col)
    if (allocated(list%val)) deallocate(list%val)
    list%capacity = 0_i4
    list%nnz      = 0_i4
  end subroutine RT_Triplet_Free

  subroutine RT_CSR_FromTriplet(list, nRows, nCols, A)
    type(RT_TripletList), intent(in)    :: list
    integer(i4),          intent(in)    :: nRows, nCols
    type(RT_CSRMatrix),   intent(inout) :: A

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

  ! ---------------------------------------------------------------------------
  ! RT_CSR_FromTripletMerged: sort (row,col), sum duplicate entries, build CSR.
  ! Use for MPC penalty κ·A^T·A additions where new fill-in must merge with K.
  ! ---------------------------------------------------------------------------
  subroutine RT_CSR_FromTripletMerged(list, nRows, nCols, A, ierr)
    type(RT_TripletList), intent(inout) :: list
    integer(i4),          intent(in)    :: nRows, nCols
    type(RT_CSRMatrix),   intent(inout) :: A
    integer(i4),          intent(out)   :: ierr

    integer(i4) :: n, k, km, i, j, t, root, last, child, par
    integer(i4), allocatable :: ord(:)
    type(RT_COOEntry), allocatable :: coo(:)
    integer(i4) :: r0, c0
    real(wp) :: vsum

    ierr = 0_i4
    n = list%nnz
    if (n <= 0_i4) then
      allocate(coo(1))
      call csr_init_from_coo(A, nRows, nCols, coo, 0_i4, ierr)
      deallocate(coo)
      return
    end if

    allocate(ord(n))
    do k = 1, n
      ord(k) = k
    end do

    ! Max-heap sort: permutation ord ends up sorted by (row,col) ascending
    do k = n / 2_i4, 1_i4, -1_i4
      call triplet_sift_down(list, ord, n, k)
    end do
    do k = n, 2_i4, -1_i4
      t = ord(1)
      ord(1) = ord(k)
      ord(k) = t
      call triplet_sift_down(list, ord, k - 1_i4, 1_i4)
    end do

    ! Count merged nnz
    km = 1_i4
    i = ord(1)
    r0 = list%row(i)
    c0 = list%col(i)
    do k = 2, n
      j = ord(k)
      if (list%row(j) /= r0 .or. list%col(j) /= c0) then
        km = km + 1_i4
        r0 = list%row(j)
        c0 = list%col(j)
      end if
    end do

    allocate(coo(km))
    km = 1_i4
    i = ord(1)
    r0 = list%row(i)
    c0 = list%col(i)
    vsum = list%val(i)
    do k = 2, n
      j = ord(k)
      if (list%row(j) == r0 .and. list%col(j) == c0) then
        vsum = vsum + list%val(j)
      else
        coo(km)%row = r0
        coo(km)%col = c0
        coo(km)%val = vsum
        km = km + 1_i4
        r0 = list%row(j)
        c0 = list%col(j)
        vsum = list%val(j)
      end if
    end do
    coo(km)%row = r0
    coo(km)%col = c0
    coo(km)%val = vsum

    call csr_init_from_coo(A, nRows, nCols, coo, km, ierr)
    deallocate(coo, ord)
  contains

    subroutine triplet_sift_down(lst, idx, nheap, root0)
      type(RT_TripletList), intent(in) :: lst
      integer(i4), intent(inout) :: idx(:)
      integer(i4), intent(in) :: nheap, root0
      integer(i4) :: rpos, best, lch, rch, tmp

      rpos = root0
      do
        best = rpos
        lch = 2_i4 * rpos
        rch = lch + 1_i4
        if (lch <= nheap) then
          if (triplet_key_greater(lst, idx(lch), idx(best))) best = lch
        end if
        if (rch <= nheap) then
          if (triplet_key_greater(lst, idx(rch), idx(best))) best = rch
        end if
        if (best == rpos) exit
        tmp = idx(rpos)
        idx(rpos) = idx(best)
        idx(best) = tmp
        rpos = best
      end do
    end subroutine triplet_sift_down

    logical function triplet_key_greater(lst, ia, ib)
      type(RT_TripletList), intent(in) :: lst
      integer(i4), intent(in) :: ia, ib
      triplet_key_greater = (lst%row(ia) > lst%row(ib)) .or. &
        (lst%row(ia) == lst%row(ib) .and. lst%col(ia) > lst%col(ib))
    end function triplet_key_greater

  end subroutine RT_CSR_FromTripletMerged

  ! I-03: Add value to existing (row,col) entry in CSR (for SparsityPattern reuse)
  subroutine RT_CSR_AddToValue(A, row, col, val)
    type(RT_CSRMatrix), intent(inout) :: A
    integer(i4), intent(in) :: row, col
    real(wp), intent(in) :: val
    integer(i4) :: k, start_k, end_k
    if (.not. A%init .or. row < 1_i4 .or. row > A%nRows .or. col < 1_i4 .or. col > A%nCols) return
    if (.not. allocated(A%rowPtr) .or. .not. allocated(A%colInd) .or. .not. allocated(A%values)) return
    start_k = A%rowPtr(row)
    end_k = A%rowPtr(row + 1) - 1
    do k = start_k, end_k
      if (A%colInd(k) == col) then
        A%values(k) = A%values(k) + val
        return
      end if
    end do
  end subroutine RT_CSR_AddToValue

  ! Phase3 S5.2.2: ufc_numcore UF_SparseOps sparse_matvec
  subroutine RT_CSR_SpMV(A, x, y)
    type(RT_CSRMatrix), intent(in)  :: A
    real(wp),           intent(in)  :: x(:)
    real(wp),           intent(out) :: y(:)
    call A%matvec(x, y)
  end subroutine RT_CSR_SpMV

  ! Phase3 S5.3.1: Block assembly path (Triplet BlockCSR by field); Brg may add block-level numcore interface if supported.
  subroutine RT_BlockCSR_FromTriplet(list, dofMap, blockMat)
    type(RT_TripletList),  intent(in)    :: list
    type(RT_Sol_DofMap),   intent(in)    :: dofMap
    type(RT_BlockCSRMatrix), intent(inout) :: blockMat

    integer(i4) :: nFields, fi, fj
    integer(i4), allocatable :: blockNnz(:,:)
    integer(i4) :: k, row, col, fieldRow, fieldCol
    integer(i4) :: nrows, ncols, nEntries, ierr, idx
    type(RT_COOEntry), allocatable :: coo(:)

    call RT_BlockCSR_Free(blockMat)

    nFields = dofMap%nFields
    if (nFields <= 0_i4) then
      blockMat%nFields = 0_i4
      return
    end if

    blockMat%nFields = nFields
    allocate(blockMat%fieldEqCount(nFields))
    blockMat%fieldEqCount = dofMap%fieldEqCount(1:nFields)

    allocate(blockMat%blocks(nFields, nFields))
    allocate(blockNnz(nFields, nFields))
    blockNnz = 0_i4

    do k = 1, list%nnz
      row = list%row(k)
      col = list%col(k)
      if (row < 1_i4 .or. row > dofMap%nTotalEq) cycle
      if (col < 1_i4 .or. col > dofMap%nTotalEq) cycle

      fieldRow = dofMap%eqFieldId(row)
      fieldCol = dofMap%eqFieldId(col)
      if (fieldRow < 1_i4 .or. fieldRow > nFields) cycle
      if (fieldCol < 1_i4 .or. fieldCol > nFields) cycle

      blockNnz(fieldRow, fieldCol) = blockNnz(fieldRow, fieldCol) + 1_i4
    end do

    do fi = 1, nFields
      nrows = blockMat%fieldEqCount(fi)
      do fj = 1, nFields
        ncols = blockMat%fieldEqCount(fj)
        nEntries = blockNnz(fi, fj)

        if (nEntries > 0_i4) then
          allocate(coo(nEntries))
          idx = 0_i4
          do k = 1, list%nnz
            row = list%row(k)
            col = list%col(k)
            if (row < 1_i4 .or. row > dofMap%nTotalEq) cycle
            if (col < 1_i4 .or. col > dofMap%nTotalEq) cycle
            fieldRow = dofMap%eqFieldId(row)
            fieldCol = dofMap%eqFieldId(col)
            if (fieldRow /= fi .or. fieldCol /= fj) cycle
            idx = idx + 1_i4
            coo(idx)%row = dofMap%eqLocalInField(row)
            coo(idx)%col = dofMap%eqLocalInField(col)
            coo(idx)%val = list%val(k)
          end do
          call csr_init_from_coo(blockMat%blocks(fi, fj), nrows, ncols, coo, nEntries, ierr)
          deallocate(coo)
        else
          allocate(coo(1))
          call csr_init_from_coo(blockMat%blocks(fi, fj), nrows, ncols, coo, 0_i4, ierr)
          deallocate(coo)
        end if
      end do
    end do
  end subroutine RT_BlockCSR_FromTriplet

  subroutine RT_BlockCSR_Free(blockMat)
    type(RT_BlockCSRMatrix), intent(inout) :: blockMat
    integer(i4) :: fi, fj

    if (allocated(blockMat%blocks)) then
      do fi = 1, size(blockMat%blocks, 1)
        do fj = 1, size(blockMat%blocks, 2)
          if (blockMat%blocks(fi, fj)%init) then
            call RT_CSR_Free(blockMat%blocks(fi, fj))
          end if
        end do
      end do
      deallocate(blockMat%blocks)
    end if

    if (allocated(blockMat%fieldEqCount)) then
      deallocate(blockMat%fieldEqCount)
    end if

    blockMat%nFields = 0_i4
  end subroutine RT_BlockCSR_Free

  subroutine RT_LU_Setup_FromCSR(A, handle, info)
    type(RT_CSRMatrix), intent(in)    :: A
    type(RT_LUHandle),  intent(inout) :: handle
    integer(i4),        intent(out)   :: info

    if (handle%isInitd) call RT_LU_Destroy(handle)

    info = 0_i4
    if (A%nRows <= 0_i4 .or. A%nnz <= 0_i4) then
      info = -1_i4
      handle%isInitd = .false.
      return
    end if

    handle%A_L3%nRows = A%nRows
    handle%A_L3%nCols = A%nCols
    handle%A_L3%nnz   = A%nnz
    allocate(handle%A_L3%rowPtr(size(A%rowPtr)))
    allocate(handle%A_L3%colInd(size(A%colInd)))
    allocate(handle%A_L3%values(size(A%values)))
    handle%A_L3%rowPtr = A%rowPtr
    handle%A_L3%colInd = A%colInd
    handle%A_L3%values = A%values
    handle%A_L3%is_symmetric = .false.
    handle%A_L3%init = .true.

    call direct_lu_factor(handle%A_L3, handle%LU, info)
    if (info /= 0_i4) then
      call RT_CSR_Free(handle%A_L3)
      handle%isInitd = .false.
      return
    end if

    handle%isInitd = .true.
  end subroutine RT_LU_Setup_FromCSR

  subroutine RT_LU_Solv(handle, b, x, info)
    type(RT_LUHandle), intent(in)    :: handle
    real(wp),          intent(in)    :: b(:)
    real(wp),          intent(inout) :: x(:)
    integer(i4),       intent(out)   :: info

    if (.not. handle%isInitd) then
      info = -1_i4
      return
    end if

    x = 0.0_wp
    call direct_lu_solve(handle%LU, b, x, info)
  end subroutine RT_LU_Solv

  subroutine RT_LU_Destroy(handle)
    type(RT_LUHandle), intent(inout) :: handle
    if (handle%isInitd) then
      call handle%LU%destroy()
      call RT_CSR_Free(handle%A_L3)
      handle%isInitd = .false.
    end if
  end subroutine RT_LU_Destroy

  subroutine RT_LinearSolve_Direct(A, b, x, converged, info)
    type(RT_CSRMatrix), intent(in)  :: A
    real(wp),           intent(in)  :: b(:)
    real(wp),           intent(out) :: x(:)
    logical,            intent(out) :: converged
    integer(i4),        intent(out) :: info

    type(UF_LUFactor) :: lu
    integer(i4) :: ierr

    call direct_lu_factor(A, lu, ierr)
    if (ierr /= 0_i4) then
      converged = .false.
      info = ierr
      call lu%destroy()
      x = 0.0_wp
      return
    end if

    call direct_lu_solve(lu, b, x, ierr)
    call lu%destroy()

    info = ierr
    converged = (ierr == 0_i4)
  end subroutine RT_LinearSolve_Direct

end module RT_Solv_Sparse