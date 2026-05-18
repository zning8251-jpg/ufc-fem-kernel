!----------------------------------------------------------------------
! Sparse matrix module: storage, ordering, factorization, solve (SparsePakType)
!----------------------------------------------------------------------
! LEGACY THIRD-PARTY (UFC_命名规范_v3.0 §10.1):
!   Module name `SparsePakModule` does not follow UFC layer prefix convention.
!   Not renamed to avoid breaking external API.
!----------------------------------------------------------------------
module SparsePakModule
    implicit none
    private

    ! Core derived type: sparse matrix data (SparsePakType)
    type :: SparsePakType
        ! 1. Basic parameters
        integer(kind=4) :: n = 0                ! matrix order
        integer(kind=4) :: adj_num = 0          ! adjacency nnz count
        integer(kind=4) :: ierror = 0           ! error flag; not positive definite
        integer(kind=4) :: env_size = 0         ! envelope total size
        integer(kind=4) :: iband = 0            ! lower bandwidth
        integer(kind=4) :: nblks = 0            ! number of blocks
        integer(kind=4) :: maxnz = 0            ! max off-block nonzero capacity
        integer(kind=4) :: nofsub = 0           ! QMD subproblem count
        integer(kind=4) :: adj_max = 0          ! adjacency list max capacity

        ! 2. adjacency list storage
        integer(kind=4), allocatable :: adj_row(:)  ! adj row ptr (n+1)
        integer(kind=4), allocatable :: adj(:)      ! adj column indices

        ! 3. Permutation
        integer(kind=4), allocatable :: perm(:)     ! perm (n)
        integer(kind=4), allocatable :: perm_inv(:) ! inverse perm (n)

        ! 4. diagonal/level storage
        real(kind=8), allocatable :: diag(:)        ! diagonal (n)
        integer(kind=4), allocatable :: nodlvl(:)   ! node level (n)

        ! 5. Compressed storage
        real(kind=8), allocatable :: xlnz(:)        ! lower triangle nonzero
        integer(kind=4), allocatable :: ixlnz(:)    ! compressed row index (n+1)
        integer(kind=4), allocatable :: nzsub(:)    ! nonzero column subscript
        integer(kind=4), allocatable :: xnzsub(:)   ! column nnz start (n+1)

        ! 6. envelope/block storage
        integer(kind=4), allocatable :: xenv(:)     ! envelope index (n+1)
        real(kind=8), allocatable :: env(:)         ! envelope values
        integer(kind=4), allocatable :: xblk(:)     ! block index (nblks+1)
        integer(kind=4), allocatable :: father(:)   ! quotient tree father (nblks)
        integer(kind=4), allocatable :: xnonz(:)    ! off-block row index (n+1)
        real(kind=8), allocatable :: nonz(:)        ! off-block nonzero
        integer(kind=4), allocatable :: nzsubs(:)   ! off-block column subscript

        ! 7. Temp/aux arrays
        integer(kind=4), allocatable :: mask(:)      ! node mask (n)
        integer(kind=4), allocatable :: marker(:)    ! node marker (n)
        integer(kind=4), allocatable :: rchset(:)   ! reach set (2n)
        integer(kind=4), allocatable :: nbrhd(:)    ! neighbor set (2n)
        integer(kind=4), allocatable :: ls(:)       ! level storage (n)
        integer(kind=4), allocatable :: xls(:)      ! level index (n+1)
        integer(kind=4), allocatable :: qsize(:)    ! QMD supernode size (n)
        integer(kind=4), allocatable :: qlink(:)    ! QMD supernode link (n)
        integer(kind=4), allocatable :: deg(:)      ! node degree (n)
        real(kind=8), allocatable :: temp(:)        ! temp (n)
        integer(kind=4), allocatable :: first(:)     ! nonzero root (n)
        integer(kind=4), allocatable :: link(:)      ! link (n)
        integer(kind=4), allocatable :: stack(:)     ! stack (RQT, 2n)
        integer(kind=4), allocatable :: adjs(:)      ! adj set (RQT, n)
        integer(kind=4), allocatable :: sep(:)       ! separator (n)
        integer(kind=4), allocatable :: ovrlp(:)     ! QMD overlap (n)
        integer(kind=4), allocatable :: rchlnk(:)    ! symbolic factor link (n)
        integer(kind=4), allocatable :: mrglnk(:)    ! symbolic factor merge (n)

    contains
        ! Type-bound procedures
        procedure :: init => sparsepak_init
        procedure :: finalize => sparsepak_finalize

        ! Data add
        procedure :: addcom, addrcm, addrhs, addrqt

        ! Adjacency
        procedure :: adj_env_size, adj_print, adj_set, adj_show

        ! block processing
        procedure :: block_shuffle, fntadj, fnbenv, fntenv, fnenv

        ! Level/separator
        procedure :: fnlvls, fndsep, fn1wd, level_set, root_find

        ! Ordering
        procedure :: gennd, genqmd, genrcm, genrqt, gen1wd
        procedure :: rcm, rcm_sub, rqtree

        ! Factorization
        procedure :: gs_factor, es_factor, smb_factor, ts_factor

        ! Solve
        procedure :: gs_solve, el_solve, eu_solve, ts_solve

        ! QMD
        procedure :: qmdmrg, qmdqt, qmdrch, qmdupd

        ! Utilities
        procedure :: i4_swap, i4vec_copy, i4vec_indicator
        procedure :: i4vec_reverse, i4vec_sort_insert_a
        procedure :: perm_inverse, perm_rv, timestamp

        ! Other utils
        procedure :: degree, fnofnz, fnspan, reach
    end type SparsePakType

    ! export type for external use
    public :: SparsePakType

contains

!----------------------------------------------------------------------
! init/finalize
!----------------------------------------------------------------------

! Type init: allocate and init params
subroutine sparsepak_init(self, n, adj_max, adj_num, maxnon)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: n, adj_max, adj_num, maxnon
    integer(kind=4) :: alloc_stat, i

    ! assign basic params
    self%n = n
    self%adj_num = adj_num
    self%adj_max = adj_max

    ! Allocate fixed-size arrays
    allocate( &
        self%adj_row(n+1), &
        self%perm(n), &
        self%perm_inv(n), &
        self%diag(n), &
        self%nodlvl(n), &
        self%ixlnz(n+1), &
        self%xnzsub(n+1), &
        self%nzsubs(maxnon), &
        self%xenv(n+1), &
        self%xnonz(n+1), &
        self%mask(n), &
        self%marker(n), &
        self%ls(n), &
        self%xls(n+1), &
        self%qsize(n), &
        self%qlink(n), &
        self%deg(n), &
        self%temp(n), &
        self%first(n), &
        self%link(n), &
        self%adjs(n), &
        self%sep(n), &
        self%ovrlp(n), &
        self%rchlnk(n), &
        self%mrglnk(n), &
        self%rchset(2*n), &
        self%nbrhd(2*n), &
        self%stack(2*n), &
        stat=alloc_stat &
    )
    if (alloc_stat /= 0) error stop "sparsepak_init: fixed array alloc failed"

    ! allocate adj
    if (adj_max > 0) then
        allocate(self%adj(adj_max), stat=alloc_stat)
        if (alloc_stat /= 0) error stop "sparsepak_init: adj array alloc failed"
    end if

    if (allocated(self%father)) deallocate(self%father)

    ! init array defaults
    self%adj_num = 0
    self%adj_row = 1
    self%perm = [(i, i=1, n)]
    self%perm_inv = [(i, i=1, n)]
    self%diag = 0.0d0
    self%nodlvl = 0
    self%ixlnz = 0
    self%xnzsub = 0
    self%xenv = 0
    self%xnonz = 0
    self%mask = 1
    self%marker = 0
    self%ls = 0
    self%xls = 0
    self%qsize = 1
    self%qlink = 0
    self%deg = 0
    self%temp = 0.0d0
    self%first = 0
    self%link = 0
    self%adjs = 0
    self%sep = 0
    self%ovrlp = 0
    self%rchlnk = 0
    self%mrglnk = 0
    self%rchset = 0
    self%nbrhd = 0
    self%stack = 0

    ! Deallocate dynamic arrays
    call deallocate_dynamic(self)
end subroutine sparsepak_init

! Deallocate dynamic arrays
subroutine deallocate_dynamic(self)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4) :: alloc_stat

    ! Dealloc compressed storage
    if (allocated(self%xlnz)) then
        deallocate(self%xlnz, stat=alloc_stat)
        if (alloc_stat /= 0) write(*, '(a)') 'deallocate_dynamic: dealloc xlnz failed'
    end if
    if (allocated(self%nzsub)) then
        deallocate(self%nzsub, stat=alloc_stat)
        if (alloc_stat /= 0) write(*, '(a)') 'deallocate_dynamic: dealloc nzsub failed'
    end if

    ! Dealloc envelope/block storage
    if (allocated(self%env)) then
        deallocate(self%env, stat=alloc_stat)
        if (alloc_stat /= 0) write(*, '(a)') 'deallocate_dynamic: dealloc env failed'
    end if
    if (allocated(self%xblk)) then
        deallocate(self%xblk, stat=alloc_stat)
        if (alloc_stat /= 0) write(*, '(a)') 'deallocate_dynamic: dealloc xblk failed'
    end if
    if (allocated(self%nonz)) then
        deallocate(self%nonz, stat=alloc_stat)
        if (alloc_stat /= 0) write(*, '(a)') 'deallocate_dynamic: dealloc nonz failed'
    end if
    if (allocated(self%nzsubs)) then
        deallocate(self%nzsubs, stat=alloc_stat)
        if (alloc_stat /= 0) write(*, '(a)') 'deallocate_dynamic: dealloc nzsubs failed'
    end if
end subroutine deallocate_dynamic

! Type finalize: dealloc and reset
subroutine sparsepak_finalize(self)
    class(SparsePakType), intent(inout) :: self

    ! Dealloc fixed-size arrays
    if (allocated(self%adj_row)) deallocate(self%adj_row)
    if (allocated(self%adj)) deallocate(self%adj)
    if (allocated(self%perm)) deallocate(self%perm)
    if (allocated(self%perm_inv)) deallocate(self%perm_inv)
    if (allocated(self%diag)) deallocate(self%diag)
    if (allocated(self%nodlvl)) deallocate(self%nodlvl)
    if (allocated(self%ixlnz)) deallocate(self%ixlnz)
    if (allocated(self%xnzsub)) deallocate(self%xnzsub)
    if (allocated(self%xenv)) deallocate(self%xenv)
    if (allocated(self%father)) deallocate(self%father)
    if (allocated(self%xnonz)) deallocate(self%xnonz)
    if (allocated(self%mask)) deallocate(self%mask)
    if (allocated(self%marker)) deallocate(self%marker)
    if (allocated(self%ls)) deallocate(self%ls)
    if (allocated(self%xls)) deallocate(self%xls)
    if (allocated(self%qsize)) deallocate(self%qsize)
    if (allocated(self%qlink)) deallocate(self%qlink)
    if (allocated(self%deg)) deallocate(self%deg)
    if (allocated(self%temp)) deallocate(self%temp)
    if (allocated(self%first)) deallocate(self%first)
    if (allocated(self%link)) deallocate(self%link)
    if (allocated(self%adjs)) deallocate(self%adjs)
    if (allocated(self%sep)) deallocate(self%sep)
    if (allocated(self%ovrlp)) deallocate(self%ovrlp)
    if (allocated(self%rchlnk)) deallocate(self%rchlnk)
    if (allocated(self%mrglnk)) deallocate(self%mrglnk)
    if (allocated(self%rchset)) deallocate(self%rchset)
    if (allocated(self%nbrhd)) deallocate(self%nbrhd)
    if (allocated(self%stack)) deallocate(self%stack)

    ! Deallocate dynamic arrays
    call deallocate_dynamic(self)

    ! Reset basic params
    self%n = 0
    self%adj_num = 0
    self%adj_max = 0
    self%ierror = 0
    self%env_size = 0
    self%iband = 0
    self%nblks = 0
    self%maxnz = 0
    self%nofsub = 0
end subroutine sparsepak_finalize

!----------------------------------------------------------------------
! Data-add routines
!----------------------------------------------------------------------

! Add lower triangle to compressed
subroutine addcom(self, isub, jsub, value)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: isub, jsub
    real(kind=8), intent(in) :: value
    integer(kind=4) :: i, j, k, kstop, kstrt, ksub

    ! Check required arrays
    if (.not. allocated(self%perm_inv)) error stop "addcom: perm_inv not allocated"
    if (.not. allocated(self%diag)) error stop "addcom: diag not allocated"
    if (.not. allocated(self%xlnz)) error stop "addcom: xlnz not allocated"
    if (.not. allocated(self%ixlnz)) error stop "addcom: ixlnz not allocated"
    if (.not. allocated(self%nzsub)) error stop "addcom: nzsub not allocated"
    if (.not. allocated(self%xnzsub)) error stop "addcom: xnzsub not allocated"
    if (.not. allocated(self%perm)) error stop "addcom: perm not allocated"

    ! Compute permuted row/col index
    i = self%perm_inv(isub)
    j = self%perm_inv(jsub)

    ! Diagonal update
    if (i == j) then
        self%diag(i) = self%diag(i) + value
        return
    end if

    ! Skip upper triangle
    if (i < j) return

    ! Compute search range
    kstrt = self%ixlnz(j)
    kstop = self%ixlnz(j+1) - 1

    ! Index validity check
    if (kstrt < 1 .or. kstop > size(self%xlnz)-1) then
        write(*, '(a)') 'ADDCOM - fatal error: IXLNZ array index out of bounds'
        write(*, '(a,i8,a,i8,a,i8)') 'J=', j, '; IXLNZ(J)=', self%ixlnz(j), &
            '; IXLNZ(J+1)=', self%ixlnz(j+1)
        write(*, '(a,i8,a,i8)') 'ISUB=', isub, '; JSUB=', jsub
        stop
    end if

    if (kstop < kstrt) then
        write(*, '(a)') 'ADDCOM - fatal error: no storage for column J'
        write(*, '(a,i8,a,i8,a,i8)') 'J=', j, '; KSTRT=', kstrt, '; KSTOP=', kstop
        write(*, '(a,i8,a,i8)') 'ISUB=', isub, '; JSUB=', jsub
        stop
    end if

    ! Compute NZSUBS start index
    ksub = self%xnzsub(j)
    if (ksub < 1 .or. ksub + (kstop - kstrt) > size(self%nzsub)) then
        write(*, '(a)') 'ADDCOM - fatal error: XNZSUBS(J) out of NZSUB range'
        write(*, '(a,i8,a,i8,a,i8)') 'J=', j, '; XNZSUBS(J)=', ksub, &
            '; NZSUB size=', size(self%nzsub)
        write(*, '(a,i8,a,i8)') ' required range: ', ksub, ' to ', ksub + (kstop - kstrt)
        stop
    end if

    ! search and update
    do k = kstrt, kstop
        ksub = self%xnzsub(j) + (k - kstrt)
        if (ksub < 1 .or. ksub > size(self%nzsub)) then
            write(*, '(a)') 'ADDCOM - fatal error: KSUB out of bounds'
            write(*, '(a,i8,a,i8,a,i8)') 'K=', k, '; KSTRT=', kstrt, '; KSUB=', ksub
            stop
        end if
        if (self%nzsub(ksub) == i) then
            self%xlnz(k) = self%xlnz(k) + value
            return
        end if
    end do

    stop "ADDCOM - fatal: no storage for (ISUB,JSUB)"
end subroutine addcom

! Add lower triangle to RCM envelope
subroutine addrcm(self, isub, jsub, value)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: isub, jsub
    real(kind=8), intent(in) :: value
    integer(kind=4) :: i, j, k

    ! Check required arrays
    if (.not. allocated(self%perm_inv)) error stop "addrcm: perm_inv not allocated"
    if (.not. allocated(self%diag)) error stop "addrcm: diag not allocated"
    if (.not. allocated(self%xenv)) error stop "addrcm: xenv not allocated"
    if (.not. allocated(self%env)) error stop "addrcm: env not allocated"

    ! Compute current row/col
    i = self%perm_inv(isub)
    j = self%perm_inv(jsub)

    ! Skip upper triangle
    if (i < j) return

    ! Diagonal update
    if (i == j) then
        self%diag(i) = self%diag(i) + value
        return
    end if

    ! Compute envelope index and update
    k = self%xenv(i+1) - i + j
    if (k < self%xenv(i)) then
        write(*, '(a)') 'ADDRCM - fatal: index out of envelope range'
        write(*, '(a,i8,a,i8)') 'ISUB=', isub, ' JSUB=', jsub
        stop
    end if
    self%env(k) = self%env(k) + value
end subroutine addrcm

! Add to RHS (permuted index)
subroutine addrhs(self, isub, rhs, value)
    class(SparsePakType), intent(in) :: self
    integer(kind=4), intent(in) :: isub
    real(kind=8), intent(inout) :: rhs(:)
    real(kind=8), intent(in) :: value
    integer(kind=4) :: i

    ! Check arguments
    if (size(rhs) /= self%n) error stop "addrhs: rhs size mismatch"
    if (.not. allocated(self%perm_inv)) error stop "addrhs: perm_inv not allocated"

    ! Compute permuted index and update
    i = self%perm_inv(isub)
    if (1 <= i .and. i <= self%n) then
        rhs(i) = rhs(i) + value
    end if
end subroutine addrhs

! Set RQT nonzero count
subroutine addrqt(self, isub, jsub, value, nofnz)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: isub, jsub, nofnz
    real(kind=8), intent(in) :: value
    integer(kind=4) :: i, j, k, kstrt, kstop

    ! Check nonz allocated
    if (.not. allocated(self%nonz)) then
        write(*, '(a)') 'ADDRQT - fatal: self%nonz not allocated'
        write(*, '(a)') 'Call FNOFNZ first to set nofnz and allocate nonz'
        error stop
    end if

    ! Check nonz size
    if (size(self%nonz) < nofnz) then
        write(*, '(a)') 'ADDRQT - fatal error: self%nonz too small'
        write(*, '(a,i8,a,i8)') 'size(self%nonz) = ', size(self%nonz), &
            '; nofnz = ', nofnz
        error stop
    end if

    ! Check indices valid
    if (isub < 1 .or. isub > self%n) then
        write(*, '(a)') 'ADDRQT - fatal error: invalid row index isub'
        write(*, '(a,i8,a,i8)') 'isub = ', isub, '; self%n = ', self%n
        error stop
    end if
    if (jsub < 1 .or. jsub > self%n) then
        write(*, '(a)') 'ADDRQT - fatal error: invalid column index jsub'
        write(*, '(a,i8,a,i8)') 'jsub = ', jsub, '; self%n = ', self%n
        error stop
    end if

    ! Locate nonzero and write
    kstrt = self%xnonz(isub)
    kstop = self%xnonz(isub+1) - 1
    if (kstrt > kstop) then
        write(*, '(a,i8)') 'ADDRQT - warning: row isub has no nonzero slot', isub
        return
    end if

    do k = kstrt, kstop
        if (k > size(self%nzsubs)) error stop "ADDRQT: nzsubs index out of bounds"
        if (self%nzsubs(k) == jsub) then
            self%nonz(k) = self%nonz(k) + value
            return
        end if
    end do

    write(*, '(a)') 'ADDRQT - warning: nonzero entry position not found'
    write(*, '(a,i8,a,i8)') '(isub, jsub) = (', isub, ', ', jsub, ')'
end subroutine addrqt

!----------------------------------------------------------------------
! adjacency routines
!----------------------------------------------------------------------

! Compute envelope size from adj
subroutine adj_env_size(self, env_size)
    class(SparsePakType), intent(in) :: self
    integer(kind=4), intent(out) :: env_size
    integer(kind=4) :: add, col, i, j, row

    ! Check required arrays
    if (.not. allocated(self%adj_row)) error stop "adj_env_size: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "adj_env_size: adj not allocated"
    if (.not. allocated(self%perm)) error stop "adj_env_size: perm not allocated"
    if (.not. allocated(self%perm_inv)) error stop "adj_env_size: perm_inv not allocated"

    ! Init and compute
    env_size = 0
    do i = 1, self%n
        row = self%perm(i)
        add = 0
        do j = self%adj_row(row), self%adj_row(row+1) - 1
            if (j > size(self%adj)) error stop "adj_env_size: adj index out of bounds"
            col = self%perm_inv(self%adj(j))
            if (col < i) then
                add = max(add, i - col)
            end if
        end do
        env_size = env_size + add
    end do
end subroutine adj_env_size

! Print sparse adjacency
subroutine adj_print(self)
    class(SparsePakType), intent(in) :: self
    integer(kind=4) :: i, jhi, jlo, jmax, jmin

    ! Check required arrays
    if (.not. allocated(self%adj_row)) error stop "adj_print: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "adj_print: adj not allocated"

    ! Print header
    write(*, '(a)') ' '
    write(*, '(a)') 'ADJ_PRINT: sparse matrix adjacency structure'
    write(*, '(a,i8)') 'matrix order N = ', self%n
    write(*, '(a,i8)') 'nnz = ', self%adj_num
    write(*, '(a)') '  row    column indices'
    write(*, '(a)') ' '

    ! Print by row
    do i = 1, self%n
        jmin = self%adj_row(i)
        jmax = self%adj_row(i+1) - 1
        if (jmin > jmax) cycle

        if (jmax > size(self%adj)) then
            write(*, '(a,i8)') 'adj_print: row adj array too small, i=', i
            stop
        end if

        ! 10 elements per group
        do jlo = jmin, jmax, 10
            jhi = min(jlo+9, jmax)
            if (jlo == jmin) then
                write(*, '(i6,6x,10i6)') i, self%adj(jlo:jhi)
            else
                write(*, '(6x,6x,10i6)') self%adj(jlo:jhi)
            end if
        end do
    end do
end subroutine adj_print

! Build adj for symmetric (skip diag)
subroutine adj_set(self, irow, jcol)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: irow, jcol
    integer(kind=4) :: i, j, k, kback, khi, klo

    ! Check required arrays
    if (.not. allocated(self%adj_row)) error stop "adj_set: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "adj_set: adj not allocated"

    ! Negative index = init
    if (irow < 0 .or. jcol < 0) then
        write(*, '(a)') 'ADJ_SET - init adjacency (negative irow/jcol)'
        write(*, '(a,i8)') 'N = ', self%n
        write(*, '(a,i8)') 'max adjacency size = ', self%adj_max
        write(*, '(a,i8)') 'max adj size = ', self%adj_max
        self%adj_row(1:self%n+1) = 1
        self%adj(1:self%adj_max) = 0
        return
    end if

    ! Skip diagonal
    if (irow == jcol) return

    ! Index validity check
    if (self%n < irow) then
        write(*, '(a)') 'ADJ_SET - fatal error: N < IROW'
        write(*, '(a,i8,a,i8)') 'IROW=', irow, ' N=', self%n
        stop
    else if (irow < 1) then
        write(*, '(a)') 'ADJ_SET - fatal error: IROW < 1'
        write(*, '(a,i8)') 'IROW=', irow
        stop
    else if (self%n < jcol) then
        write(*, '(a)') 'ADJ_SET - fatal error: N < JCOL'
        write(*, '(a,i8,a,i8)') 'JCOL=', jcol, ' N=', self%n
        stop
    else if (jcol < 1) then
        write(*, '(a)') 'ADJ_SET - fatal error: JCOL < 1'
        write(*, '(a,i8)') 'JCOL=', jcol
        stop
    end if

    ! Symmetric handling
    i = irow
    j = jcol
20  continue

    ! Check if entry exists
    klo = self%adj_row(i)
    khi = self%adj_row(i+1) - 1
    do k = klo, khi
        if (k > size(self%adj)) error stop "adj_set: adj index out of bounds"
        if (self%adj(k) == j) then
            if (i == irow) then
                i = jcol
                j = irow
                go to 20
            end if
            return
        end if
    end do

    ! Check storage sufficient
    if (self%adj_max < self%adj_num + 1) then
        write(*, '(a)') 'ADJ_SET - fatal error: storage exhausted'
        write(*, '(a,i8,a,i8)') 'IROW=', irow, ' JCOL=', jcol
        stop
    end if

    ! Shift and insert
    do k = self%adj_row(i+1), self%adj_row(self%n+1)
        if (k > self%adj_max) error stop "adj_set: adj_row exceeds adj_max"
        kback = self%adj_row(self%n+1) + self%adj_row(i+1) - k
        if (kback+1 > self%adj_max) error stop "adj_set: shift exceeds adj_max"
        self%adj(kback+1) = self%adj(kback)
    end do
    self%adj(self%adj_row(i+1)) = j

    ! Update row pointer
    do k = i + 1, self%n + 1
        self%adj_row(k) = self%adj_row(k) + 1
    end do
    self%adj_num = self%adj_row(self%n+1) - 1

    ! Insert at symmetric pos
    if (i == irow) then
        i = jcol
        j = irow
        go to 20
    end if
end subroutine adj_set

! Show sparsity (bandwidth)
subroutine adj_show(self, iband)
    class(SparsePakType), intent(in) :: self
    integer(kind=4), intent(out) :: iband
    character(len=1), allocatable :: band(:)
    integer(kind=4) :: col, i, j, k, nonz, alloc_stat

    ! Check required arrays
    if (.not. allocated(self%adj_row)) error stop "adj_show: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "adj_show: adj not allocated"
    if (.not. allocated(self%perm)) error stop "adj_show: perm not allocated"
    if (.not. allocated(self%perm_inv)) error stop "adj_show: perm_inv not allocated"

    ! Alloc local array
    allocate(band(self%n), stat=alloc_stat)
    if (alloc_stat /= 0) error stop "adj_show: band array alloc failed"

    ! Init
    iband = 0
    nonz = 0

    ! Print header
    write(*, '(a)') ' '
    write(*, '(a)') 'ADJ_SHOW: nonzero structure'
    write(*, '(a)') ' '

    ! Build and print by row
    do i = 1, self%n
        band(1:self%n) = ' '
        band(i) = 'X'  ! Mark diagonal

        do j = self%adj_row(self%perm(i)), self%adj_row(self%perm(i)+1) - 1
            if (j > size(self%adj)) error stop "adj_show: adj index out of bounds"
            col = self%perm_inv(self%adj(j))
            if (col < i) then
                nonz = nonz + 1
            end if
            iband = max(iband, i - col)
            band(col) = 'X'
        end do

        write(*, '(i6,1x,100a1)') i, band(1:self%n)
    end do

    ! Print stats
    write(*, '(a)') ' '
    write(*, '(a,i8)') 'lower bandwidth = ', iband
    write(*, '(a,i8,a)') 'envelope nnz = ', nonz

    ! Dealloc local array
    if (allocated(band)) deallocate(band)
end subroutine adj_show

!----------------------------------------------------------------------
! Block-processing routines
!----------------------------------------------------------------------

! Reorder block (RCM_SUB)
subroutine block_shuffle(self, nblks, xblk, perm)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: nblks, xblk(:)
    integer(kind=4), intent(inout) :: perm(:)
    integer(kind=4) :: bnum(self%n), i, ip, istop, istrt, j, jstop
    integer(kind=4) :: jstrt, k, mask(self%n), nabor, nbrblk, node, nsubg
    integer(kind=4) :: subg(self%n)

    ! Param check
    if (size(xblk) /= nblks + 1) then
        write(*, '(a)') 'BLOCK_SHUFFLE - fatal: xblk size mismatch'
        write(*, '(a,i8,a,i8)') 'size(xblk)=', size(xblk), ' nblks+1=', nblks+1
        error stop
    end if
    if (size(perm) /= self%n) then
        write(*, '(a)') 'BLOCK_SHUFFLE - fatal: perm size mismatch'
        write(*, '(a,i8,a,i8)') 'size(perm)=', size(perm), ' self%n=', self%n
        error stop
    end if

    ! Init block id and mask
    mask(1:self%n) = 0
    do k = 1, nblks
        do i = xblk(k), xblk(k+1)-1
            node = perm(i)
            bnum(node) = k
            mask(node) = 0
        end do
    end do

    ! Process blocks (no prior neighbor)
    do k = 1, nblks
        istrt = xblk(k)
        istop = xblk(k+1)-1
        nsubg = 0

        ! Gather nodes with no prior neighbor
        do i = istrt, istop
            node = perm(i)
            jstrt = self%adj_row(node)
            jstop = self%adj_row(node+1)-1

            ! Check prior block neighbor
            do j = jstrt, jstop
                nabor = self%adj(j)
                nbrblk = bnum(nabor)
                if (nbrblk < k) go to 40
            end do

            ! Gather subgraph nodes
            nsubg = nsubg + 1
            subg(nsubg) = node
            ip = istrt + nsubg - 1
            perm(i) = perm(ip)
40          continue
        end do

        ! Call RCM_SUB reorder subgraph
        if (nsubg > 0) then
            call self%rcm_sub( &
                subg = subg(1:nsubg), &
                nsubg = nsubg, &
                perm_start = istrt, &
                mask = mask &
            )
        end if
    end do
end subroutine block_shuffle

! Cholesky diag block envelope
subroutine fnbenv(self, xblk, env_size)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: xblk(:)
    integer(kind=4), intent(out) :: env_size
    integer(kind=4) :: blkbeg, blkend, i, ifirst, inhd, k, newnhd
    integer(kind=4) :: nhdsze, node, rchsze, alloc_stat

    ! Check params and arrays
    if (size(xblk) /= self%nblks + 1) error stop "fnbenv: xblk size mismatch"
    if (.not. allocated(self%adj_row)) error stop "fnbenv: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "fnbenv: adj not allocated"
    if (.not. allocated(self%perm)) error stop "fnbenv: perm not allocated"
    if (.not. allocated(self%perm_inv)) error stop "fnbenv: perm_inv not allocated"
    if (.not. allocated(self%mask)) error stop "fnbenv: mask not allocated"
    if (.not. allocated(self%marker)) error stop "fnbenv: marker not allocated"
    if (.not. allocated(self%xenv)) error stop "fnbenv: xenv not allocated"

    ! Init
    env_size = 1
    self%mask(1:self%n) = 0
    self%marker(1:self%n) = 1

    ! Alloc reach/neighbor sets
    if (.not. allocated(self%rchset)) then
        allocate(self%rchset(2*self%n), stat=alloc_stat)
        if (alloc_stat /= 0) error stop "fnbenv: rchset alloc failed"
    end if
    if (.not. allocated(self%nbrhd)) then
        allocate(self%nbrhd(2*self%n), stat=alloc_stat)
        if (alloc_stat /= 0) error stop "fnbenv: nbrhd alloc failed"
    end if

    ! Compute envelope per block
    do k = 1, self%nblks
        nhdsze = 0
        blkbeg = xblk(k)
        blkend = xblk(k+1) - 1

        ! Mark nodes in current block
        do i = xblk(k), xblk(k+1) - 1
            if (i > self%n) error stop "fnbenv: perm index out of bounds"
            node = self%perm(i)
            self%marker(node) = 0
        end do

        ! Loop nodes in current block
        do i = xblk(k), xblk(k+1) - 1
            if (i > self%n) error stop "fnbenv: perm index out of bounds"
            node = self%perm(i)
            rchsze = 0
            newnhd = 0

            ! Call REACH for reach/neighbor
            call self%reach(node, rchsze, self%rchset(blkbeg:), newnhd, &
                self%nbrhd(nhdsze+1:))
            nhdsze = nhdsze + newnhd

            ! Update envelope index
            ifirst = self%marker(node)
            ifirst = self%perm_inv(ifirst)
            self%xenv(i) = env_size
            env_size = env_size + i - ifirst
        end do

        ! Reset neighbor marker
        do inhd = 1, nhdsze
            if (inhd > size(self%nbrhd)) error stop "fnbenv: nbrhd index out of bounds"
            node = self%nbrhd(inhd)
            self%marker(node) = 0
        end do

        ! Reset current block marker
        do i = blkbeg, blkend
            if (i > self%n) error stop "fnbenv: perm index out of bounds"
            node = self%perm(i)
            self%marker(node) = 0
            self%mask(node) = 1
        end do
    end do

    ! Adjust envelope size
    self%xenv(self%n+1) = env_size
    env_size = env_size - 1
end subroutine fnbenv

! Tree partition envelope index
subroutine fntenv(self, xblk, env_size)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: xblk(:)
    integer(kind=4), intent(out) :: env_size
    integer(kind=4) :: blkbeg, blkend, i, ifirst, j, jstop, jstrt
    integer(kind=4) :: k, kfirst, nbr, node

    if (size(xblk) /= self%nblks + 1) then
        error stop "fntenv: xblk size must be nblks+1"
    end if
    if (.not. allocated(self%adj_row)) error stop "fntenv: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "fntenv: adj not allocated"
    if (.not. allocated(self%perm)) error stop "fntenv: perm not allocated"
    if (.not. allocated(self%perm_inv)) error stop "fntenv: perm_inv not allocated"
    if (.not. allocated(self%xenv)) error stop "fntenv: xenv not allocated"

    env_size = 1

    do k = 1, self%nblks
        blkbeg = xblk(k)
        blkend = xblk(k+1) - 1
        if (blkbeg < 1 .or. blkend > self%n) error stop "fntenv: block range invalid"
        kfirst = blkend
        do i = blkbeg, blkend
            node = self%perm(i)
            if (node < 1 .or. node > self%n) error stop "fntenv: perm node out of range"
            jstrt = self%adj_row(node)
            jstop = self%adj_row(node+1) - 1
            ifirst = i
            do j = jstrt, jstop
                if (j > size(self%adj)) error stop "fntenv: adj index out of range"
                nbr = self%adj(j)
                nbr = self%perm_inv(nbr)
                if (nbr < 1 .or. nbr > self%n) error stop "fntenv: perm_inv result invalid"

                ! First nonzero in current row
                if (blkbeg <= nbr) then
                    ifirst = min(ifirst, nbr)
                else
                    ifirst = min(ifirst, kfirst)
                    kfirst = min(kfirst, i)
                end if
            end do

            ! Update envelope size
            env_size = env_size + i - ifirst
        end do
    end do

    ! Adjust envelope index and total size
    self%xenv(blkend+1) = env_size
    env_size = env_size - 1
end subroutine fntenv

! Build quotient tree adjacency
subroutine fntadj(self, xblk, father, nblks)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: xblk(:), nblks
    integer(kind=4), intent(out) :: father(:)
    integer(kind=4) :: b, i, ib, j, jb, nabor, node, blk(self%n)
    integer(kind=4) :: jstrt, jstop

    ! Check father size
    if (size(father) /= nblks) then
        write(*, '(a)') 'FNTADJ - fatal: father size vs nblks mismatch'
        write(*, '(a,i8,a,i8)') 'size(father) = ', size(father), &
            '; nblks = ', nblks
        error stop
    end if
    if (size(xblk) /= nblks + 1) then
        write(*, '(a)') 'FNTADJ - fatal: xblk size mismatch'
        write(*, '(a,i8,a,i8)') 'size(xblk) = ', size(xblk), &
            '; nblks+1 = ', nblks + 1
        error stop
    end if

    blk(1:self%n) = 0
    do b = 1, nblks
        do i = xblk(b), xblk(b+1) - 1
            if (i < 1 .or. i > self%n) then
                write(*, '(a)') 'FNTADJ - fatal: xblk node index out of range'
                write(*, '(a,i8,a,i8,a,i8)') 'b = ', b, '; i = ', i, &
                    '; self%n = ', self%n
                error stop
            end if
            node = self%perm(i)
            blk(node) = b
        end do
    end do

    ! init father array
    father(1:nblks) = 0

    ! Loop blocks, find parent block
    do b = 1, nblks
        do i = xblk(b), xblk(b+1) - 1
            node = self%perm(i)
            jstrt = self%adj_row(node)
            jstop = self%adj_row(node + 1) - 1

            do j = jstrt, jstop
                if (j > size(self%adj)) error stop "FNTADJ: adj index out of bounds"
                nabor = self%adj(j)
                jb = blk(nabor)
                ib = blk(node)

                ! Parent rule: neighbor block < current and parent unset
                if (jb /= 0 .and. jb < ib .and. father(ib) == 0) then
                    father(ib) = jb
                end if
            end do
        end do
    end do

    write(*, '(a)') ' '
    write(*, '(a,i8)') 'FNTADJ done: quotient tree father init'
    write(*, '(a,i8)') 'nblks = ', nblks
    write(*, '(a,i8)') 'father size = ', size(father)
end subroutine fntadj

!----------------------------------------------------------------------
! Compute envelope of reordered matrix (lower bandwidth)
! From adj and perm, compute xenv, env_size, iband
! Output: xenv(1:n+1), env_size, iband
!----------------------------------------------------------------------
subroutine fnenv(self, env_size, iband)
    class(SparsePakType), intent(inout) :: self  ! Uses adj/perm/xenv, updates xenv
    integer(kind=4), intent(out) :: env_size     ! Output: envelope total nnz
    integer(kind=4), intent(out) :: iband       ! Output: lower bandwidth

    ! Local variables
    integer(kind=4) :: i, ifirst, iperm, j, jstop, jstrt, nabor  ! i=permuted row, iperm=original row
	integer(kind=4) :: jband

    ! -------------------------- Param validity (legacy)--------------------------
    ! Check required arrays allocated
    if (.not. allocated(self%adj_row)) then
        error stop "fnenv: adj_row not allocated (call sparsepak_init first)"
    end if
    if (.not. allocated(self%adj)) then
        error stop "fnenv: adj not allocated (call sparsepak_init first)"
    end if
    if (.not. allocated(self%perm)) then
        error stop "fnenv: perm not allocated (call genrcm/gennd first)"
    end if
    if (.not. allocated(self%perm_inv)) then
        error stop "fnenv: perm_inv not allocated (call perm_inverse first)"
    end if
    if (.not. allocated(self%xenv)) then
        error stop "fnenv: xenv not allocated (call sparsepak_init first)"
    end if

    ! -------------------------- Init output (legacy)--------------------------
    iband = 0          ! Init iband (zero if no nnz)
    env_size = 1       ! Envelope index start (xenv(1)=1)

    ! -------------------------- Compute envelope per row--------------------------
    do i = 1, self%n  ! i: permuted row (1..n)
        ! 1. Record envelope start for current row
        self%xenv(i) = env_size

        ! 2. Map to original row (perm(i))
        iperm = self%perm(i)

        ! 3. Get adj range for original row
        jstrt = self%adj_row(iperm)    ! Start index for row iperm
        jstop = self%adj_row(iperm+1) - 1  ! End index for row iperm

        ! 4. If no adj nnz, skip
        if (jstrt > jstop) cycle

        ! 5. Find the first nonzero column index in current row (after permutation)
        ifirst = i  ! Initialize to current row index (diagonal position)
        do j = jstrt, jstop
            ! Check adj index out of bounds (enhance robustness)
            if (j > size(self%adj)) then
                write(*, '(a)') 'fnenv - fatal error: adj index out of bounds'
                write(*, '(a,i8,a,i8,a,i8)')  'perm row i=', i,  'orig row iperm=', iperm,  'adj index j=', j
                stop
            end if

            ! Transform adjacent node to permuted column index (perm_inv(adj(j)) maps original column to permuted column)
            nabor = self%adj(j)                ! Original column index
            nabor = self%perm_inv(nabor)       ! Transform to permuted column index

            ! Update the first nonzero column index of current row (take minimum)
            ifirst = min(ifirst, nabor)
        end do

        ! 6. Compute envelope contribution and bandwidth for current row
        jband = i - ifirst  ! Envelope width of current row (row index - first nonzero column)
        env_size = env_size + jband  ! Accumulate envelope total size
        iband = max(iband, jband)    ! Update lower bandwidth (take maximum width over all rows)
    end do

    ! -------------------------- Correct envelope index and total size (legacy critical step) --------------------------
    self%xenv(self%n + 1) = env_size  ! Last envelope index (marks envelope end)
    env_size = env_size - 1          ! Total nonzero count in envelope = index difference (xenv(n+1)-xenv(1))
end subroutine fnenv

!----------------------------------------------------------------------
! Subroutines related to level structure and separator sets
!----------------------------------------------------------------------

! Generate node level structure
subroutine fnlvls(self, root, nlvl, lvl_xls, ls)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(inout) :: root
    integer(kind=4), intent(out) :: nlvl, lvl_xls(:)
    integer(kind=4), intent(out) :: ls(:)
    integer(kind=4) :: j, lvl, node, lvl_start, lvl_end

    ! Precondition parameter check
    if (size(ls) /= self%n) then
        write(*, '(a)') 'FNLVLS - fatal error: ls size does not match matrix order'
        write(*, '(a,i8,a,i8)') 'size(ls) = ', size(ls), '; self%n = ', self%n
        error stop
    end if
    if (size(lvl_xls) /= self%n + 1) then
        write(*, '(a)') 'FNLVLS - fatal: lvl_xls size must be self%n+1'
        write(*, '(a,i8,a,i8)') 'size(lvl_xls) = ', size(lvl_xls), &
            '; self%n+1 = ', self%n + 1
        error stop
    end if
    if (.not. allocated(self%nodlvl)) then
        write(*, '(a)') 'FNLVLS - fatal: nodlvl not allocated (call init first)'
        error stop
    end if

    ! Call root_find to generate level structure
    call self%root_find( &
        root = root, &
        nlvl = nlvl, &
        xls = lvl_xls, &
        ls = ls &
    )

    ! Assign level number to each node
    do lvl = 1, nlvl
        lvl_start = lvl_xls(lvl)
        lvl_end = lvl_xls(lvl + 1) - 1

        ! Validate level indices
        if (lvl_start < 1 .or. lvl_end > self%n) then
            write(*, '(a)') 'FNLVLS - fatal: level index range invalid'
            write(*, '(a,i8,a,i8,a,i8)') 'level = ', lvl, '; start = ', lvl_start, &
                '; end = ', lvl_end
            write(*, '(a,i8)') 'self%n = ', self%n
            error stop
        end if

        ! Assign level number
        do j = lvl_start, lvl_end
            node = ls(j)
            if (node < 1 .or. node > self%n) then
                write(*, '(a)') 'FNLVLS - fatal: ls node index out of range'
                write(*, '(a,i8,a,i8,a,i8)') 'ls(', j, ') = ', node, &
                    '; self%n = ', self%n
                error stop
            end if
            self%nodlvl(node) = lvl
        end do
    end do
end subroutine fnlvls

! Find small separator set for graph connected component
subroutine fndsep(self, root, nsep, sep)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(inout) :: root
    integer(kind=4), intent(out) :: nsep, sep(:)
    integer(kind=4) :: i, j, jstop, jstrt, midbeg, midend, midlvl
    integer(kind=4) :: mp1beg, mp1end, nbr, nlvl, node, ccsize

    ! Check required arrays
    if (.not. allocated(self%adj_row)) error stop "fndsep: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "fndsep: adj not allocated"
    if (.not. allocated(self%mask)) error stop "fndsep: mask not allocated"
    if (.not. allocated(self%ls)) error stop "fndsep: ls not allocated"
    if (.not. allocated(self%xls)) error stop "fndsep: xls not allocated"

    ! Generate level structure and get component size
    call self%root_find(root, nlvl, self%xls, self%ls)
    ccsize = self%xls(nlvl+1) - 1

    ! Check sep array capacity
    if (size(sep) < ccsize) then
        write(*, '(a)') 'FNDSEP - fatal error: sep array size insufficient'
        write(*, '(a,i8,a,i8)') 'required size (comp) = ', ccsize, &
            ' actual size = ', size(sep)
        write(*, '(a,i8,a,i8)') 'comp root = ', root, ' matrix order N = ', self%n
        stop
    end if

    ! Component too small, entire component becomes separator set
    if (nlvl < 3) then
        nsep = ccsize
        do i = 1, nsep
            if (i > size(self%ls)) error stop "fndsep: ls index out of bounds"
            node = self%ls(i)
            sep(i) = node
            self%mask(node) = 0
        end do
        return
    end if

    ! Find middle level
    midlvl = (nlvl + 2) / 2
    midbeg = self%xls(midlvl)
    mp1beg = self%xls(midlvl+1)
    midend = mp1beg - 1
    mp1end = self%xls(midlvl+2) - 1

    ! Mark middle+1 level nodes
    do i = mp1beg, mp1end
        if (i > size(self%ls)) error stop "fndsep: ls index out of bounds"
        node = self%ls(i)
        if (node < 1 .or. node > self%n) error stop "fndsep: ls node out of range"
        self%adj_row(node) = -self%adj_row(node)
    end do

    ! Filter separator set nodes from middle level
    nsep = 0
    do i = midbeg, midend
        if (i > size(self%ls)) error stop "fndsep: ls index out of bounds"
        node = self%ls(i)
        jstrt = self%adj_row(node)
        jstop = abs(self%adj_row(node+1)) - 1

        do j = jstrt, jstop
            if (j > size(self%adj)) error stop "fndsep: adj index out of bounds"
            nbr = self%adj(j)
            if (nbr < 1 .or. nbr > self%n) error stop "fndsep: adj neighbor out of range"

            if (self%adj_row(nbr) <= 0) then
                nsep = nsep + 1
                sep(nsep) = node
                self%mask(node) = 0
                exit
            end if
        end do
    end do

    ! Reset adj_row markers
    do i = mp1beg, mp1end
        if (i > size(self%ls)) error stop "fndsep: ls index out of bounds"
        node = self%ls(i)
        if (node < 1 .or. node > self%n) error stop "fndsep: ls node out of range"
        self%adj_row(node) = -self%adj_row(node)
    end do
end subroutine fndsep

! Find one-way separator for graph connected component
subroutine fn1wd(self, root, nsep, sep, nlvl, lvl_xls, ls)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(inout) :: root
    integer(kind=4), intent(out) :: nsep, nlvl, lvl_xls(:), ls(:)
    integer(kind=4), intent(out) :: sep(:)
    real(kind=8) :: deltp1, fnlvl, width
    integer(kind=4) :: i, j, k, kstop, kstrt, lp1beg, lp1end, lvl
    integer(kind=4) :: lvlbeg, lvlend, nbr, node, nabor

    ! Check parameter validity
    if (size(sep) < self%n) error stop "fn1wd: sep size insufficient"
    if (size(lvl_xls) < self%n + 1) error stop "fn1wd: lvl_xls size insufficient"
    if (size(ls) < self%n) error stop "fn1wd: ls size insufficient"
    if (.not. allocated(self%adj_row)) error stop "fn1wd: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "fn1wd: adj not allocated"
    if (.not. allocated(self%mask)) error stop "fn1wd: mask not allocated"

    ! Generate level structure
    call self%root_find(root, nlvl, lvl_xls, ls)

    ! Compute component size and level width
    fnlvl = real(nlvl, kind=8)
    nsep = lvl_xls(nlvl+1) - 1
    if (nsep <= 0) then
        write(*, '(a)') 'FN1WD - warning: empty component'
        return
    end if
    width = real(nsep, kind=8) / fnlvl

    ! Compute level spacing parameter
    deltp1 = 1.0D+00 + sqrt((3.0D+00 * width + 13.0D+00) / 2.0D+00)

    ! Component too small, entire component becomes separator set
    if (nsep < 50 .or. 0.5D+00 * fnlvl < deltp1) then
        if (nsep > size(sep)) error stop "fn1wd: sep size insufficient"
        do i = 1, nsep
            if (i > size(ls)) error stop "fn1wd: ls index out of bounds"
            node = ls(i)
            sep(i) = node
            self%mask(node) = 0
        end do
        return
    end if

    ! Filter parallel separators
    nsep = 0
    i = 0
    do
        i = i + 1
        lvl = int(real(i, kind=8) * deltp1 + 0.5D+00)
        if (nlvl <= lvl) exit

        ! Level index range
        lvlbeg = lvl_xls(lvl)
        lp1beg = lvl_xls(lvl+1)
        lvlend = lp1beg - 1
        lp1end = lvl_xls(lvl+2) - 1

        ! Mark next level nodes
        do j = lp1beg, lp1end
            if (j > size(ls)) error stop "fn1wd: ls index out of bounds"
            node = ls(j)
            if (node < 1 .or. node > self%n) error stop "fn1wd: ls node out of range"
            self%adj_row(node) = -self%adj_row(node)
        end do

        ! Filter current level nodes
        do j = lvlbeg, lvlend
            if (j > size(ls)) error stop "fn1wd: ls index out of bounds"
            node = ls(j)
            if (node < 1 .or. node > self%n) error stop "fn1wd: ls node out of range"

            kstrt = self%adj_row(node)
            kstop = abs(self%adj_row(node+1)) - 1
            do k = kstrt, kstop
                if (k > size(self%adj)) error stop "fn1wd: adj index out of bounds"
                nabor = self%adj(k)
                if (nabor < 1 .or. nabor > self%n) error stop "fn1wd: adj neighbor out of range"

                if (self%adj_row(nabor) <= 0) then
                    nsep = nsep + 1
                    if (nsep > size(sep)) error stop "fn1wd: sep size insufficient"
                    sep(nsep) = node
                    self%mask(node) = 0
                    exit
                end if
            end do
        end do

        ! Reset ADJ_ROW markers
        do j = lp1beg, lp1end
            if (j > size(ls)) error stop "fn1wd: ls index out of bounds"
            node = ls(j)
            if (node < 1 .or. node > self%n) error stop "fn1wd: ls node out of range"
            self%adj_row(node) = -self%adj_row(node)
        end do
    end do
end subroutine fn1wd

! Generate connected level structure from root node
subroutine level_set(self, root, mask, nlvl, xls, ls)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: root
    integer(kind=4), intent(inout) :: mask(:)
    integer(kind=4), intent(out) :: nlvl, xls(:), ls(:)
    integer(kind=4) :: i, ccsize, j, jstop, jstrt, lbegin, lvlend
    integer(kind=4) :: lvsize, nbr, node

    ! Check parameter validity
    if (size(mask) < self%n) error stop "level_set: mask size insufficient"
    if (size(xls) < self%n + 1) error stop "level_set: xls size insufficient"
    if (size(ls) < self%n) error stop "level_set: ls size insufficient"
    if (.not. allocated(self%adj_row)) error stop "level_set: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "level_set: adj not allocated"

    ! Initialize level structure
    mask(root) = 0
    ls(1) = root
    nlvl = 0
    lvlend = 0
    ccsize = 1

    ! Iteratively generate levels
    do
        lbegin = lvlend + 1
        lvlend = ccsize
        nlvl = nlvl + 1
        xls(nlvl) = lbegin

        ! Traverse current level nodes
        do i = lbegin, lvlend
            node = ls(i)
            jstrt = self%adj_row(node)
            jstop = self%adj_row(node+1) - 1

            ! Process adjacent nodes
            do j = jstrt, jstop
                if (j > size(self%adj)) error stop "level_set: adj index out of bounds"
                nbr = self%adj(j)
                if (mask(nbr) /= 0) then
                    ccsize = ccsize + 1
                    if (ccsize > size(ls)) error stop "level_set: ls size insufficient"
                    ls(ccsize) = nbr
                    mask(nbr) = 0
                end if
            end do
        end do

        ! Check next level
        lvsize = ccsize - lvlend
        if (lvsize <= 0) exit
    end do

    ! Reset mask
    xls(nlvl+1) = lvlend + 1
    do i = 1, ccsize
        node = ls(i)
        mask(node) = 1
    end do
end subroutine level_set

! Generate level structure from root node (enhanced ls size validation)
subroutine root_find(self, root, nlvl, xls, ls)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(inout) :: root
    integer(kind=4), intent(out) :: nlvl, xls(:), ls(:)
    integer(kind=4) :: ccsize, j, jstrt_node, k, kstop, kstrt, mindeg  ! Rename jstrt to jstrt_node to avoid conflict
    integer(kind=4) :: nabor, ndeg, node, nunlvl, mask_copy(self%n)
	integer(kind=4) :: jstrt

    ! Enforce ls size validation (ensure storage for all node level information)
    if (size(ls) < self%n) then
        write(*, '(a)') 'ROOT_FIND - fatal error: ls size insufficient'
        write(*, '(a,i8,a,i8)') 'required size self%n = ', self%n, &
            '; actual size = ', size(ls)
        error stop
    end if

    ! Validate xls size (level index must cover all levels + 1 end marker)
    if (size(xls) /= self%n + 1) then
        write(*, '(a)') 'ROOT_FIND - fatal: xls size must be self%n+1'
        write(*, '(a,i8,a,i8)') 'required size self%n+1 = ', self%n + 1, &
            '; actual size = ', size(xls)
        error stop
    end if

    ! Save self%mask copy (avoid modifying instance mask, reduce side effects)
    mask_copy = self%mask

    ! Call level_set to generate initial level structure (pass complete ls/xls)
    call self%level_set( &
        root = root, &
        mask = mask_copy, &
        nlvl = nlvl, &
        xls = xls, &
        ls = ls &
    )
    ccsize = xls(nlvl + 1) - 1  ! Connected component size: actual node count in ls

    ! Special case: complete graph (1 level) or line graph (levels = component size), no optimization needed
    if (nlvl == 1 .or. nlvl == ccsize) then
        self%mask = mask_copy
        return
    end if

    ! Iteratively find pseudo-peripheral node (optimize level structure, reduce separator set size)
    do
        mindeg = ccsize  ! Initialize minimum degree to component size (maximum possible value)
        jstrt = xls(nlvl)  ! Start index of last level (position in ls)
        root = ls(jstrt)   ! Initial candidate root node (start from first node of last level)

        ! -------------------------- Fix: Add missing ENDIF --------------------------
        ! Traverse last level, find minimum degree node as new root
        if (jstrt < ccsize) then  ! Only traverse if last level has multiple nodes
            do j = jstrt, ccsize
                node = ls(j)  ! Current traversed node (from last level)
                ndeg = 0      ! Initialize current node degree
                ! Read adjacency list range of current node (avoid name conflict with outer jstrt, rename to jstrt_node)
                jstrt_node = self%adj_row(node)
                kstop = self%adj_row(node + 1) - 1
                
                ! Compute current node degree (count only mask_copy filtered nodes)
                do k = jstrt_node, kstop
                    if (k > size(self%adj)) error stop "ROOT_FIND: adj index out of bounds"
                    nabor = self%adj(k)
                    if (mask_copy(nabor) /= 0) ndeg = ndeg + 1  ! Count only filtered neighbors
                end do
                
                ! Update minimum degree node (find node with smallest degree as new root)
                if (ndeg < mindeg) then
                    root = node    ! Update root to current minimum degree node
                    mindeg = ndeg  ! Update minimum degree
                end if
            end do
        end if  ! -------------------------- Supplementary: Close if (jstrt < ccsize) --------------------------
        
        ! Regenerate level structure for candidate root node (verify optimization)
        mask_copy = self%mask  ! Reset mask copy
        call self%level_set( &
            root = root, &
            mask = mask_copy, &
            nlvl = nunlvl, &
            xls = xls, &
            ls = ls &
        )
        
        ! Level count no longer increases, optimal pseudo-peripheral node found, exit iteration
        if (nunlvl <= nlvl) exit
        nlvl = nunlvl  ! Update level count to newly generated level count
        
        ! Line graph check: levels = component size, no further optimization needed (avoid infinite loop)
        if (ccsize <= nlvl) exit
    end do
    
    ! Restore instance mask (avoid modifying instance state, keep interface pure)
    self%mask = mask_copy
end subroutine root_find

!----------------------------------------------------------------------
! Subroutines related to ordering algorithms
!----------------------------------------------------------------------

! Generate nested dissection ordering for general graph
subroutine gennd(self, perm)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(out) :: perm(:)
    integer(kind=4) :: i, mask(self%n), nsep, num, root, ccsize, nlvl

    ! Check parameter validity
    if (size(perm) /= self%n) then
        print *, "gennd: perm size mismatch (expected size=N, actual size=)"// &
            trim(str(size(perm)))//trim(str(self%n))
        stop
    end if
    if (.not. allocated(self%adj_row)) error stop "gennd: adj_row not allocated (call init first)"
    if (.not. allocated(self%adj)) error stop "gennd: adj not allocated (call init first)"
    if (.not. allocated(self%mask)) error stop "gennd: mask not allocated (call init first)"

    ! Initialize local filtering mask
    mask(1:self%n) = 1
    num = 0  ! Total count of generated separator set nodes

    ! Generate separator set for each connected component
    do i = 1, self%n
        if (mask(i) /= 0) then
            root = i  ! Use current unprocessed node as component root
            
            ! Estimate component size
            call self%root_find(root, nlvl, self%xls, perm(num+1:num+self%n))
            ccsize = self%xls(nlvl+1) - 1  ! Component size
            
            ! Check perm slice capacity
            if (num + ccsize > self%n) then
                write(*, '(a)') 'GENND - fatal error: perm size insufficient'
                write(*, '(a,i8,a,i8,a,i8)') 'comp root', root, &
                    ' component size=', ccsize, ' remaining perm capacity=', self%n - num
                stop
            end if
            
            ! Call fndsep to generate separator
            call self%fndsep(root, nsep, perm(num+1:num+ccsize))
            
            ! Update ordering counter
            num = num + nsep
            
            ! All nodes ordered: reverse perm
            if (self%n <= num) then
                call self%i4vec_reverse(self%n, perm)
                return
            end if
            
            ! Mark separator set nodes as processed
            do root = 1, nsep
                if (num - nsep + root < 1 .or. num - nsep + root > self%n) then
                    error stop "gennd: perm index out of range (sep marker)"
                end if
                mask(perm(num - nsep + root)) = 0
            end do
        end if
    end do
    
    ! All components processed, reverse separator
    call self%i4vec_reverse(self%n, perm)
end subroutine gennd

! Implement Quotient Minimum Degree (QMD) algorithm
subroutine genqmd(self, perm, perm_inv, nofsub)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(out) :: perm(:), perm_inv(:)
    integer(kind=4), intent(out) :: nofsub
    integer(kind=4), allocatable :: adj_orig(:), adj_row_orig(:)
    integer(kind=4) :: inode, ip, irch, i, j, ndeg, nhdsze, qs, search
    integer(kind=4) :: node, np, num, nxnode, thresh, rchsze, mindeg, alloc_stat
    integer(kind=4), allocatable :: temp_adj(:)

    ! check base arrays
    if (.not. allocated(self%adj) .or. .not. allocated(self%adj_row)) then
        error stop "genqmd: adj/adj_row not allocated (call init first)"
    end if

    ! Allocate temporary arrays to save original data
    allocate(adj_orig(size(self%adj)), adj_row_orig(size(self%adj_row)), &
        stat=alloc_stat)
    if (alloc_stat /= 0) error stop "genqmd: original adj array alloc failed"
    adj_orig = self%adj
    adj_row_orig = self%adj_row

    ! init QMD params
    if (size(perm) /= self%n .or. size(perm_inv) /= self%n) then
        error stop "genqmd: perm/perm_inv size mismatch"
    end if
    if (.not. allocated(self%marker)) error stop "genqmd: marker not allocated"
    if (.not. allocated(self%qsize)) error stop "genqmd: qsize not allocated"
    if (.not. allocated(self%qlink)) error stop "genqmd: qlink not allocated"
    if (.not. allocated(self%deg)) error stop "genqmd: deg not allocated"

    nofsub = 0
    mindeg = self%n
    num = 0
    perm(1:self%n) = [(i, i=1, self%n)]
    perm_inv(1:self%n) = [(i, i=1, self%n)]
    self%qsize(1:self%n) = 1
    self%qlink(1:self%n) = 0
    self%marker(1:self%n) = 0

    ! Compute node degree using original adj
    do node = 1, self%n
        self%deg(node) = adj_row_orig(node+1) - adj_row_orig(node)
        mindeg = min(mindeg, self%deg(node))
    end do
    thresh = mindeg

    ! Allocate temporary adj for QMD processing
    if (.not. allocated(temp_adj)) then
        allocate(temp_adj(size(adj_orig)), stat=alloc_stat)
        if (alloc_stat /= 0) error stop "genqmd: temp_adj allocation failed"
        temp_adj = adj_orig
    end if

    ! Iteratively eliminate supernodes
    do while (num < self%n)
        mindeg = self%n
        node = -1

        ! Find minimum degree supernode
        do search = 1, self%n
            if (self%marker(search) /= 0) cycle
            qs = self%qsize(search)
            if (qs == 0) error stop "genqmd: qsize invalid"
            if (self%deg(search)*1.0d0/qs < mindeg*1.0d0/self%qsize(max(1, node))) then
                mindeg = self%deg(search)
                node = search
            end if
        end do
        if (node == -1) error stop "genqmd: no valid node found (all marked)"

        search = node
        nofsub = nofsub + 1
        self%marker(node) = 1

        ! Temporary assignment for subroutine use
        self%adj = temp_adj
        self%adj_row = adj_row_orig

        ! Call QMD related subroutines
        call self%qmdrch(node, rchsze, nhdsze)
        if (rchsze > 0) call self%qmdupd(rchsze, self%rchset(1:rchsze))

        ! Update permutation
        nxnode = node
        do while (nxnode > 0)
            num = num + 1
            np = perm_inv(nxnode)
            ip = perm(num)
            perm(np) = ip
            perm_inv(ip) = np
            perm(num) = nxnode
            perm_inv(nxnode) = num
            self%deg(nxnode) = -1
            nxnode = self%qlink(nxnode)
        end do

        if (rchsze > 0) call self%qmdqt(node, rchsze, self%rchset(1:rchsze))
        self%marker(node) = 0

        ! Reset markers
        do irch = 1, rchsze
            inode = self%rchset(irch)
            if (self%marker(inode) == 1) then
                self%marker(inode) = 0
                if (self%deg(inode) < thresh) then
                    thresh = self%deg(inode)
                    search = perm_inv(inode)
                end if
            end if
        end do

        ! Save temporary adj modifications
        temp_adj = self%adj
    end do

    ! Restore original adj/adj_row
    self%adj = adj_orig
    self%adj_row = adj_row_orig
    if (allocated(temp_adj)) deallocate(temp_adj)
    if (allocated(adj_orig)) deallocate(adj_orig)
    if (allocated(adj_row_orig)) deallocate(adj_row_orig)
end subroutine genqmd

! Generate Reverse Cuthill-McKee (RCM) ordering for general graph
subroutine genrcm(self, perm)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(out) :: perm(:)
    integer(kind=4) :: i, ccsize, mask(self%n), nlvl, num, root, xls(self%n+1)

    ! Check parameter validity
    if (size(perm) /= self%n) error stop "genrcm: perm size mismatch"
    if (.not. allocated(self%adj_row)) error stop "genrcm: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "genrcm: adj not allocated"
    if (.not. allocated(self%ls)) error stop "genrcm: ls not allocated"

    ! Initialize local mask
    mask(1:self%n) = 1
    num = 1  ! Ordering start index

    ! Generate RCM ordering for each connected component
    do i = 1, self%n
        if (mask(i) /= 0) then
            root = i
            
            ! Generate level structure
            call self%root_find(root, nlvl, xls, perm(num:num+self%n-1))
            
            ! Generate RCM ordering
            call self%rcm(root, mask, perm(num:num+self%n-1), ccsize)
            
            ! Update ordering index
            num = num + ccsize
            if (self%n < num) return
        end if
    end do
end subroutine genrcm

! Generate quotient tree (RQT) partition ordering
subroutine genrqt(self, nblks, xblk, perm)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(out) :: nblks
    integer(kind=4), allocatable, intent(out) :: xblk(:)
    integer(kind=4), intent(out) :: perm(:)
    integer(kind=4) :: i, ixls, leaf, nlvl, root, nodlvl(self%n)
    integer(kind=4) :: lvl_xls(self%n + 1), alloc_stat
    integer(kind=4), allocatable :: temp_xblk(:)

    ! Precondition parameter check
    if (size(perm) /= self%n) then
        write(*, '(a)') 'GENRQT - fatal error: PERM size does not match matrix order'
        write(*, '(a,i8,a,i8)') 'size(perm) = ', size(perm), '; self%n = ', self%n
        error stop
    end if
    if (.not. allocated(self%ls)) then
        write(*, '(a)') 'GENRQT - fatal: ls not allocated (call init first)'
        error stop
    end if
    if (size(self%ls) /= self%n) then
        write(*, '(a)') 'GENRQT - fatal error: self%ls size insufficient'
        write(*, '(a,i8,a,i8)') 'size(self%ls) = ', size(self%ls), '; self%n = ', self%n
        error stop
    end if

    ! Initialize core variables
    nodlvl(1:self%n) = 1
    self%nblks = 0
    if (allocated(xblk)) deallocate(xblk)

    ! Allocate temporary block index arrays
    allocate(temp_xblk(self%n + 1), stat=alloc_stat)
    if (alloc_stat /= 0) then
        write(*, '(a)') 'GENRQT - fatal error: temp_xblk allocation failed'
        write(*, '(a,i8)') 'request size self%n+1 = ', self%n + 1
        error stop
    end if
    temp_xblk(1) = 1

    ! Generate RQT ordering for each connected component
    do i = 1, self%n
        if (nodlvl(i) == 1) then
            root = i
            
            ! Generate node level structure
            call self%fnlvls( &
                root = root, &
                nlvl = nlvl, &
                lvl_xls = lvl_xls, &
                ls = self%ls &
            )
            
            ! Find leaf nodes
            ixls = lvl_xls(nlvl)
            if (ixls < 1 .or. ixls > self%n) then
                write(*, '(a)') 'GENRQT - fatal: last level start index out of range'
                write(*, '(a,i8,a,i8)') 'ixls = ', ixls, '; self%n = ', self%n
                deallocate(temp_xblk)
                error stop
            end if
            leaf = self%ls(ixls)
            
            ! Generate quotient tree ordering
            call self%rqtree( &
                leaf = leaf, &
                perm = perm, &
                xblk = temp_xblk &
            )
        end if
    end do

    ! Generate final output xblk
    nblks = self%nblks
    allocate(xblk(nblks + 1), stat=alloc_stat)
    if (alloc_stat /= 0) then
        write(*, '(a)') 'GENRQT - fatal error: output xblk allocation failed'
        write(*, '(a,i8,a,i8)') 'request size nblks+1 = ', nblks + 1, '; nblks = ', nblks
        deallocate(temp_xblk)
        error stop
    end if
    xblk(1:nblks + 1) = temp_xblk(1:nblks + 1)

    ! Release temporary arrays
    deallocate(temp_xblk)

    ! Debug information
    write(*, '(a)') ' '
    write(*, '(a,i12)') 'GENRQT done: RQT nblks = ', nblks
    write(*, '(a,i12)') 'xblk size nblks+1 = ', nblks + 1
end subroutine genrqt

! Generate one-way dissection (1WD) partitioning for general graph
subroutine gen1wd(self, nblks, xblk, perm)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(out) :: nblks
    integer(kind=4), allocatable, intent(out) :: xblk(:)
    integer(kind=4), intent(out) :: perm(:)
    integer(kind=4) :: i, actual_add, ccsize, j, k, lnum, node, nsep, num, root
    integer(kind=4) :: nlvl, mask(self%n), ls(self%n), xls(self%n + 1)
    integer(kind=4), allocatable :: sep(:), temp_xblk(:)
    integer(kind=4) :: alloc_stat

    ! Parameter validity check
    if (size(perm) /= self%n) then
        write(*, '(a)') 'GEN1WD - fatal error: perm size does not match matrix order'
        write(*, '(a,i8,a,i8)') 'size(perm) = ', size(perm), '; self%n = ', self%n
        error stop
    end if

    ! Alloc local array
    allocate(sep(self%n), stat=alloc_stat)
    if (alloc_stat /= 0) error stop "GEN1WD: sep allocation failed"
    allocate(temp_xblk(self%n + 1), stat=alloc_stat)
    if (alloc_stat /= 0) error stop "GEN1WD: temp_xblk allocation failed"

    ! Initialize variables
    mask(1:self%n) = 1
    num = 0
    nblks = 0
    temp_xblk(1) = 1

    ! Generate 1WD partition for each connected component
    do i = 1, self%n
        if (mask(i) == 0) cycle
        root = i

        ! Generate separator set for current component
        call self%fn1wd( &
            root = root, &
            nsep = nsep, &
            sep = sep, &
            nlvl = nlvl, &
            lvl_xls = xls, &
            ls = ls &
        )

        ! Add separator set nodes to ordering
        if (nsep <= 0) cycle
        actual_add = min(nsep, self%n - num)
        if (actual_add <= 0) cycle

        do k = 1, actual_add
            perm(num + k) = sep(k)
            mask(sep(k)) = 0
        end do
        num = num + actual_add
        nblks = nblks + 1
        temp_xblk(nblks) = num - actual_add + 1

        ! Process remaining nodes after separator set
        ccsize = xls(nlvl + 1) - 1
        do j = 1, ccsize
            node = ls(j)
            if (mask(node) == 0) cycle

            ! Generate level structure for sub-component
            call self%level_set( &
                root = node, &
                mask = mask, &
                nlvl = nlvl, &
                xls = xls, &
                ls = ls &
            )

            ! Copy sub-component nodes to perm
            lnum = num + 1
            actual_add = xls(nlvl + 1) - 1
            actual_add = min(actual_add, self%n - num)

            do k = 1, actual_add
                perm(num + k) = ls(k)
                mask(ls(k)) = 0
            end do

            ! Update block count and index
            num = num + actual_add
            nblks = nblks + 1
            temp_xblk(nblks) = lnum

            if (num >= self%n) exit
        end do

        if (num >= self%n) exit
    end do

    ! Reverse perm array (consistent with 1WD ordering logic)
    call self%i4vec_reverse(self%n, perm)

    ! Reverse block index array
    call self%i4vec_reverse(nblks, temp_xblk(1:nblks))
    temp_xblk(nblks + 1) = self%n + 1

    ! Allocate output xblk
    if (allocated(xblk)) deallocate(xblk)
    allocate(xblk(nblks + 1), stat=alloc_stat)
    if (alloc_stat /= 0) error stop "GEN1WD: xblk allocation failed"
    xblk(1:nblks + 1) = temp_xblk(1:nblks + 1)

    ! Debug information
    write(*, '(a)') ' '
    write(*, '(a,i8)') 'GEN1WD done: 1WD nblks = ', nblks
    write(*, '(a,i8)') 'xblk size nblks+1 = ', size(xblk)

    ! Release local resources
    deallocate(sep, temp_xblk)
end subroutine gen1wd

! Generate RCM ordering for connected component (with reverse operation)
subroutine rcm(self, root, mask, perm, ccsize)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: root
    integer(kind=4), intent(inout) :: mask(:), perm(:)
    integer(kind=4), intent(out) :: ccsize
    integer(kind=4) :: deg(self%n), fnbr, i, j, jstop, jstrt, k, l, lbegin
    integer(kind=4) :: lnbr, lperm, lvlend, nbr, node

    ! Check params and arrays
    if (size(mask) < self%n) error stop "rcm: mask size insufficient"
    if (size(perm) < self%n) error stop "rcm: perm size insufficient"
    if (.not. allocated(self%adj_row)) error stop "rcm: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "rcm: adj not allocated"
    if (.not. allocated(self%deg)) error stop "rcm: deg not allocated"

    ! Compute node degree
    call self%degree(root, ccsize, perm)
    mask(root) = 0
    if (ccsize <= 1) return

    ! Initialize level parameters
    lvlend = 0
    lnbr = 1

    ! Level traversal to generate Cuthill-McKee ordering
    do while (lvlend < lnbr)
        lbegin = lvlend + 1
        lvlend = lnbr

        ! Traverse current level nodes
        do i = lbegin, lvlend
            node = perm(i)
            jstrt = self%adj_row(node)
            jstop = self%adj_row(node+1) - 1

            ! Collect unprocessed neighbors
            fnbr = lnbr + 1
            do j = jstrt, jstop
                if (j > size(self%adj)) error stop "rcm: adj index out of bounds"
                nbr = self%adj(j)
                if (mask(nbr) /= 0) then
                    lnbr = lnbr + 1
                    if (lnbr > size(perm)) error stop "rcm: perm size insufficient"
                    mask(nbr) = 0
                    perm(lnbr) = nbr
                end if
            end do

            ! Sort neighbors by ascending degree
            if (fnbr < lnbr) then
                call self%i4vec_sort_insert_a(lnbr - fnbr + 1, perm(fnbr:lnbr))
            end if
        end do
    end do

    ! Reverse RCM ordering generation
    call self%i4vec_reverse(ccsize, perm(1:ccsize))
end subroutine rcm

! RCM reordering for subgraph (block_shuffle auxiliary)
subroutine rcm_sub(self, subg, nsubg, perm_start, mask)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: subg(:), nsubg, perm_start
    integer(kind=4), intent(inout) :: mask(:)
    integer(kind=4) :: ccsize, i, nlvl, node, num, xls(self%n+1), root

    ! Initialize mask and node markers
    do i = 1, nsubg
        node = subg(i)
        mask(node) = 1
    end do

    num = 0  ! Sub-graph internal ordering counter
    do i = 1, nsubg
        node = subg(i)
        if (mask(node) == 1) then
            root = node

            ! Generate level structure
            call self%root_find( &
                root = root, &
                nlvl = nlvl, &
                xls = xls, &
                ls = self%ls &
            )

            ! Call RCM ordering for sub-component
            call self%rcm( &
                root = root, &
                mask = mask, &
                perm = self%perm(perm_start+num:perm_start+num+self%n-1), &
                ccsize = ccsize &
            )

            num = num + ccsize
            if (nsubg <= num) exit
        end if
    end do

    ! Reset mask
    do i = 1, nsubg
        node = subg(i)
        mask(node) = 0
    end do
end subroutine rcm_sub

! Generate quotient tree ordering for connected component in RQT method
subroutine rqtree(self, leaf, perm, xblk)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(inout) :: leaf
    integer(kind=4), intent(inout) :: perm(:), xblk(:)
    integer(kind=4) :: blksze, ip, j, jp, level, nadjs, node, npop
    integer(kind=4) :: nuleaf, num, toplvl, topstk, nspan, alloc_stat
    integer(kind=4) :: remaining  ! Explicitly declare all variables to avoid #6404 error

    ! -------------------------- 1. Fix: Stack allocation and size check (complete block structure) --------------------------
    if (.not. allocated(self%stack)) then
        allocate(self%stack(2*self%n), stat=alloc_stat)
        if (alloc_stat /= 0) then
            write(*, '(a)') 'RQTREE - fatal error: stack allocation failed'
            write(*, '(a,i8)') 'request size 2*self%n = ', 2*self%n
            error stop
        end if
    else if (size(self%stack) < 2*self%n) then  ! elseif concatenated, corresponding to outer if
        deallocate(self%stack)
        allocate(self%stack(2*self%n), stat=alloc_stat)
        if (alloc_stat /= 0) then
            write(*, '(a)') 'RQTREE - fatal: stack realloc failed'
            write(*, '(a,i8)') 'request size 2*self%n = ', 2*self%n
            error stop
        end if
    end if  ! Close if statement for stack allocation

    ! -------------------------- 2. Fix: Perm size check (complete block structure) --------------------------
    if (size(perm) /= self%n) then
        write(*, '(a)') 'RQTREE - fatal: PERM size mismatch'
        write(*, '(a,i8,a,i8)') 'size(perm) = ', size(perm), ' != self%n = ', self%n
        error stop
    end if  ! Close if statement for perm size check

    ! -------------------------- 3. Core fix: if-elseif structure for num initialization (resolve #6309/#6317)--------------------------
    ! Error root cause: original code uses single-line if (without then) followed by elseif, Fortran disallows this; needs to be changed to block structure
    if (self%nblks + 1 > size(xblk)) then
        write(*, '(a)') 'RQTREE - fatal error: XBLK size insufficient'
        write(*, '(a,i8,a,i8)') 'xblk size = ', size(xblk), &
            ' < self%nblks+1 = ', self%nblks+1
        error stop
    end if  ! Close if statement for xblk capacity check

    num = xblk(self%nblks + 1) - 1
    ! Change to block structure if-elseif, ensure each branch has corresponding then
    if (num < 0) then
        num = 0
    else if (num > self%n - 1) then  ! Now has corresponding if block, resolves #6309
        num = self%n - 1
        write(*, '(a)') 'RQTREE - Info: initial num truncated to self%n-1'
    end if  ! Close if-elseif block for num correction, resolves #6317

    ! -------------------------- 4. Stack initialization --------------------------
    self%stack(1) = 0
    self%stack(2) = 0
    topstk = 2
    toplvl = 0

    ! -------------------------- 5. Core loop (ensure all block structures complete)--------------------------
    do
        ! Direct exit when num reaches limit
        if (num >= self%n - 1) then
            write(*, '(a)') 'RQTREE - info: num at self%n-1, exit loop'
            exit
        end if  ! Close if statement for num upper limit check

        ! Assign perm(num+1) (leaf node enters ordering)
        perm(num + 1) = leaf
        blksze = 1
        level = self%nodlvl(leaf)
        self%nodlvl(leaf) = 0

        ! Expand block (call fnspan to generate nodes within block)
        nspan = blksze
        call self%fnspan(nspan, perm(num+1:num+nspan), level, nadjs, self%adjs, nuleaf)
        blksze = nspan

        ! Correct blksze (avoid exceeding remaining node count)
        remaining = (self%n - 1) - num
        if (blksze > remaining) then
            write(*, '(a)') 'RQTREE - warning: blksze exceeds remaining, truncated'
            write(*, '(a,i8,a,i8,a,i8)') 'num = ', num, '; remaining = ', remaining, &
                '; blksze = ', blksze, ' truncated to ', remaining
            blksze = remaining
        end if  ! Close if statement for blksze correction

        ! No remaining nodes, exit loop
        if (blksze <= 0) then
            write(*, '(a)') 'RQTREE - info: no remaining nodes, exit'
            exit
        end if

        ! Process incomplete leaf nodes (need further expansion)
        if (0 < nuleaf) then
            jp = num
            do j = 1, blksze
                jp = jp + 1
                if (jp > self%n) then
                    write(*, '(a)') 'RQTREE - fatal error: JP exceeds self%n'
                    write(*, '(a,i8,a,i8)') 'jp = ', jp, ' > self%n = ', self%n
                    error stop
                end if
                node = perm(jp)
                self%nodlvl(node) = level
            end do
            leaf = nuleaf
            cycle  ! Return to outer loop, continue processing incomplete leaf nodes
        end if  ! Close if statement for incomplete leaf nodes

        ! Leaf block generation complete: update block index and process next level
        do
            ! Check xblk capacity (avoid block index out of bounds)
            if (self%nblks + 1 > size(xblk)) then
                write(*, '(a)') 'RQTREE - fatal error: XBLK size insufficient'
                write(*, '(a,i8,a,i8)') 'xblk size = ', size(xblk), &
                    ' < self%nblks+1 = ', self%nblks+1
                error stop
            end if  ! Close if statement for xblk capacity check

            ! Update block count and index
            self%nblks = self%nblks + 1
            xblk(self%nblks) = num + 1  ! Record current block start index

            ! Accumulate num (update sorted node count)
            num = num + blksze

            ! Generate next level block (level completed)
            level = level - 1
            if (level <= 0) then
                xblk(self%nblks + 1) = num + 1  ! Record current block end index
                return  ! Level completed, exit subroutine
            end if  ! Close if statement for level judgment

            ! Copy adjacency set to perm (prepare next level block)
            remaining = (self%n - 1) - num
            if (nadjs > remaining) then
                write(*, '(a)') 'RQTREE - warning: nadjs exceeds remaining, truncated'
                write(*, '(a,i8,a,i8)') 'nadjs = ', nadjs, ' truncated to ', remaining
                nadjs = remaining
            end if

            ! No adjacency set, direct exit
            if (nadjs <= 0) then
                xblk(self%nblks + 1) = num + 1
                return
            end if  ! Close if statement for nadjs judgment

            ! Copy adjacency set nodes to perm
            call self%i4vec_copy(nadjs, self%adjs(1:nadjs), perm(num+1:num+nadjs))
            blksze = nadjs  ! Update block size to adjacency set size

            ! Merge stack nodes (merge blocks at same level)
            if (level == toplvl) then
                ! Check stack underflow
                if (topstk - 1 < 1 .or. topstk - npop - 2 < 1) then
                    write(*, '(a)') 'RQTREE - fatal error: stack underflow'
                    error stop
                end if

                ! Pop stack node count and merge
                npop = self%stack(topstk - 1)
                topstk = topstk - npop - 2

                ! Check if merged block size exceeds remaining nodes
                remaining = (self%n - 1) - num
                if (blksze + npop > remaining) then
                    write(*, '(a)') 'RQTREE - Warning: blksze+npop exceeds remaining nodes'
                    write(*, '(a,i8,a,i8)') 'blksze+npop = ', blksze + npop, &
                        ' Truncated to', remaining
                    npop = remaining - blksze
                    if (npop < 0) npop = 0
                end if  ! Close if statement for merged block size check

                ! Copy stack nodes to perm and update block size
                if (npop > 0) then
                    ip = num + blksze + 1
                    call self%i4vec_copy(npop, self%stack(topstk+1:topstk+npop), &
                        perm(ip:ip+npop-1))
                    blksze = blksze + npop  ! Merged block size
                end if  ! Close if statement for stack node copy
            end if  ! Close if statement for stack merge

            ! Expand new block (generate nodes for next level block)
            nspan = blksze
            call self%fnspan(nspan, perm(num+1:num+nspan), level, nadjs, self%adjs, nuleaf)
            blksze = nspan

            ! Correct blksze again (avoid exceeding remaining nodes)
            remaining = (self%n - 1) - num
            if (blksze > remaining) then
                blksze = remaining
            end if  ! Close if statement for second blksze correction

            ! Incomplete leaf nodes exist, break inner loop and continue processing
            if (0 < nuleaf) then
                exit
            end if  ! Close if statement for incomplete leaf node judgment
        end do  ! Close inner do loop (leaf block processing)
    end do  ! Close outer do loop (core loop)

    ! -------------------------- 6. Process last block end index (ensure block structure complete) --------------------------
    if (self%nblks + 1 <= size(xblk)) then
        xblk(self%nblks + 1) = num + 1  ! Record last block end index
    else
        write(*, '(a)') 'RQTREE - fatal error: XBLK size insufficient'
        error stop
    end if  ! Close if statement for last block index
end subroutine rqtree

!----------------------------------------------------------------------
! Subroutines related to factorization algorithms
!----------------------------------------------------------------------

! Symmetric Cholesky factorization for general sparse systems
subroutine gs_factor(self)
    class(SparsePakType), intent(inout) :: self
    real(kind=8) :: diagj, ljk, temp(self%n)
    integer(kind=4) :: first(self%n), i, ii, istop, istrt, isub, j, k, kfirst
    integer(kind=4) :: link(self%n), newk

    ! Check required arrays
    if (.not. allocated(self%xlnz)) error stop "gs_factor: xlnz not allocated"
    if (.not. allocated(self%ixlnz)) error stop "gs_factor: ixlnz not allocated"
    if (.not. allocated(self%nzsub)) error stop "gs_factor: nzsub not allocated"
    if (.not. allocated(self%xnzsub)) error stop "gs_factor: xnzsub not allocated"
    if (.not. allocated(self%diag)) error stop "gs_factor: diag not allocated"

    ! Initialize working arrays
    link(1:self%n) = 0
    temp(1:self%n) = 0.0D+00
    first(1:self%n) = 0

    ! Compute Cholesky factor column by column
    do j = 1, self%n
        diagj = 0.0D+00
        newk = link(j)

        ! Process dependencies
        do
            k = newk
            if (k == 0) exit
            newk = link(k)

            kfirst = first(k)
            if (kfirst < self%ixlnz(k) .or. kfirst >= self%ixlnz(k+1)) then
                error stop "gs_factor: first(k) invalid"
            end if

            ! Extract L(k,j)
            ljk = self%xlnz(kfirst)
            diagj = diagj + ljk**2

            ! Process dependency column off-diagonal entries
            istrt = kfirst + 1
            istop = self%ixlnz(k+1) - 1
            if (istop < istrt) cycle
            first(k) = istrt

            i = self%xnzsub(k) + (kfirst - self%ixlnz(k)) + 1
            if (i < 1 .or. i > size(self%nzsub)) error stop "gs_factor: nzsub index out of bounds"
            isub = self%nzsub(i)

            ! Update link pointers
            link(k) = link(isub)
            link(isub) = k

            ! Accumulate outer product correction
            do ii = istrt, istop
                if (i < 1 .or. i > size(self%nzsub)) error stop "gs_factor: nzsub index out of bounds"
                isub = self%nzsub(i)
                if (isub < 1 .or. isub > self%n) error stop "gs_factor: isub invalid"
                temp(isub) = temp(isub) + self%xlnz(ii) * ljk
                i = i + 1
            end do
        end do

        ! Compute diagonal element L(j,j)
        diagj = self%diag(j) - diagj
        if (diagj <= 0.0D+00) then
            write(*, '(a)') 'GS_FACTOR - fatal error: Matrix not positive definite'
            write(*, '(a,i8,a,g14.6)') 'J=', j, ' DIAG(J)=', diagj
            stop
        end if
        self%diag(j) = sqrt(diagj)

        ! Apply temp correction to current column nonzeros
        istrt = self%ixlnz(j)
        istop = self%ixlnz(j+1) - 1
        if (istrt <= istop) then
            first(j) = istrt
            i = self%xnzsub(j)
            if (i < 1 .or. i > size(self%nzsub)) error stop "gs_factor: xnzsub index out of bounds"
            isub = self%nzsub(i)

            ! Update link pointers
            link(j) = link(isub)
            link(isub) = j

            ! Element-wise correction for nonzeros
            do ii = istrt, istop
                if (i < 1 .or. i > size(self%nzsub)) error stop "gs_factor: nzsub index out of bounds"
                isub = self%nzsub(i)
                if (isub < 1 .or. isub > self%n) error stop "gs_factor: isub invalid"
                self%xlnz(ii) = (self%xlnz(ii) - temp(isub)) / self%diag(j)
                temp(isub) = 0.0D+00
                i = i + 1
            end do
        end if
    end do
end subroutine gs_factor

! Cholesky decomposition of positive definite envelope matrix (A=L*L^T)
subroutine es_factor(self, n_sys, xenv_sys, diag_sys, ierror)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: n_sys, xenv_sys(:)
    real(kind=8), intent(inout) :: diag_sys(:)
    integer(kind=4), intent(out) :: ierror
    integer(kind=4) :: i, iband, ifirst, ixenv, j, jstop
    real(kind=8) :: temp

    ierror = 0

    ! Validate first diagonal element
    if (diag_sys(1) <= 0.0D+00) then
        write(*, '(a)') 'ES_FACTOR - fatal error: Matrix not positive definite'
        ierror = 1
        return
    end if
    diag_sys(1) = sqrt(diag_sys(1))

    ! Row-by-row factorization
    do i = 2, n_sys
        ixenv = xenv_sys(i)
        iband = xenv_sys(i+1) - ixenv  ! block size
        temp = diag_sys(i)

        if (iband /= 0) then
            ifirst = i - iband  ! Starting index within block

            ! Call el_solve to solve
            call self%el_solve(iband, &
                               xenv_sys(ifirst:ifirst+iband), &
                               diag_sys(ifirst:ifirst+iband-1), &
                               self%env(ixenv:ixenv+iband-1))

            ! Accumulate sum of squares of L row off-diagonal elements
            jstop = xenv_sys(i+1) - 1
            do j = ixenv, jstop
                temp = temp - self%env(j)**2
            end do
        end if

        ! Validate positive definiteness
        if (temp <= 0.0D+00) then
            write(*, '(a)') 'ES_FACTOR - fatal error: Matrix not positive definite'
            ierror = 1
            return
        end if
        diag_sys(i) = sqrt(temp)
    end do
end subroutine es_factor

! Symbolic factorization of reordered sparse matrix (build compressed storage)
subroutine smb_factor(self, nofnz, maxsub)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(out) :: nofnz
    integer(kind=4), intent(inout) :: maxsub
    integer(kind=4) :: i, inz, j, jstop, jstrt, k, knz, kxsub, lmax, m
    integer(kind=4) :: marker(self%n), mrgk, mrkflg, nabor, node, np1
    integer(kind=4) :: nzbeg, nzend, rchm, alloc_stat

    ! Check dimension
    if (.not. allocated(self%adj_row)) error stop "smb_factor: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "smb_factor: adj not allocated"
    if (.not. allocated(self%perm)) error stop "smb_factor: perm not allocated"
    if (.not. allocated(self%perm_inv)) error stop "smb_factor: perm_inv not allocated"
    if (.not. allocated(self%ixlnz)) error stop "smb_factor: ixlnz not allocated"
    if (.not. allocated(self%xnzsub)) error stop "smb_factor: xnzsub not allocated"
    if (.not. allocated(self%rchlnk)) error stop "smb_factor: rchlnk not allocated"
    if (.not. allocated(self%mrglnk)) error stop "smb_factor: mrglnk not allocated"

    ! Allocate nzsub
    if (.not. allocated(self%nzsub)) then
        allocate(self%nzsub(maxsub), stat=alloc_stat)
        if (alloc_stat /= 0) error stop "smb_factor: nzsub allocation failed"
    else if (size(self%nzsub) < maxsub) then
        deallocate(self%nzsub)
        allocate(self%nzsub(maxsub), stat=alloc_stat)
        if (alloc_stat /= 0) error stop "smb_factor: nzsub realloc failed"
    end if

    ! Init
    nzbeg = 1
    nzend = 0
    self%ixlnz(1) = 1
    self%mrglnk(1:self%n) = 0
    marker(1:self%n) = 0
    np1 = self%n + 1

    ! Build compressed storage column-by-column
    do k = 1, self%n
        knz = 0
        mrgk = self%mrglnk(k)
        mrkflg = 0
        marker(k) = k
        if (mrgk /= 0) marker(k) = marker(mrgk)
        self%xnzsub(k) = nzend

        ! Access adjacency list
        node = self%perm(k)
        jstrt = self%adj_row(node)
        jstop = self%adj_row(node+1) - 1
        if (jstop < jstrt) go to 160

        ! Build RCHLNK linkage
        self%rchlnk(k) = np1
        do j = jstrt, jstop
            if (j > size(self%adj)) error stop "smb_factor: adj index out of bounds"
            nabor = self%adj(j)
            nabor = self%perm_inv(nabor)
            if (k < nabor) then
                rchm = k
                do
                    m = rchm
                    rchm = self%rchlnk(m)
                    if (nabor < rchm) exit
                end do
                knz = knz + 1
                self%rchlnk(m) = nabor
                self%rchlnk(nabor) = rchm
                if (marker(nabor) /= marker(k)) mrkflg = 1
            end if
        end do

        ! Batch elimination check
        lmax = 0
        if (mrkflg /= 0 .or. mrgk == 0) go to 40
        if (self%mrglnk(mrgk) /= 0) go to 40

        ! Inherit existing structure
        self%xnzsub(k) = self%xnzsub(mrgk) + 1
        knz = self%ixlnz(mrgk+1) - (self%ixlnz(mrgk) + 1)
        go to 150

40      continue
        ! Process dependencies
        i = k
50      continue
        i = self%mrglnk(i)
        if (i == 0) go to 90
        inz = self%ixlnz(i+1) - (self%ixlnz(i) + 1)
        jstrt = self%xnzsub(i) + 1
        jstop = self%xnzsub(i) + inz
        if (lmax < inz) then
            lmax = inz
            self%xnzsub(k) = jstrt
        end if

        ! Merge nonzero structures
        rchm = k
        do j = jstrt, jstop
            if (j > size(self%nzsub)) error stop "smb_factor: nzsub index out of bounds"
            nabor = self%nzsub(j)
            do
                m = rchm
                rchm = self%rchlnk(m)
                if (nabor <= rchm) exit
            end do
            if (rchm /= nabor) then
                knz = knz + 1
                self%rchlnk(m) = nabor
                self%rchlnk(nabor) = rchm
                rchm = nabor
            end if
        end do
        go to 50

90      continue
        ! Check for duplicate structure
        if (knz == lmax) go to 150

        ! Check for storage reuse
        if (nzend < nzbeg) go to 130
        i = self%rchlnk(k)
        do jstrt = nzbeg, nzend
            if (jstrt > size(self%nzsub)) error stop "smb_factor: nzsub index out of bounds"
            if (self%nzsub(jstrt) == i) go to 110
            if (i < self%nzsub(jstrt)) go to 130
        end do
        go to 130

110     continue
        ! Reuse storage
        self%xnzsub(k) = jstrt
        do j = jstrt, nzend
            if (j > size(self%nzsub)) error stop "smb_factor: nzsub index out of bounds"
            if (self%nzsub(j) /= i) go to 130
            i = self%rchlnk(i)
            if (self%n < i) go to 150
        end do
        nzend = jstrt - 1

130     continue
        ! Write to nzsub
        nzbeg = nzend + 1
        nzend = nzend + knz
        if (nzend > maxsub) then
            write(*, '(a)') 'SMB_FACTOR - fatal: storage exceeded'
            write(*, '(a,i8,a,i8)') 'MAXSUB=', maxsub, ' NZEND=', nzend
            stop
        end if
        i = k
        do j = nzbeg, nzend
            if (j > size(self%nzsub)) error stop "smb_factor: nzsub index out of bounds"
            i = self%rchlnk(i)
            self%nzsub(j) = i
            marker(i) = k
        end do
        self%xnzsub(k) = nzbeg
        marker(k) = k

150     continue
        ! Update merge linkage
        if (1 < knz) then
            kxsub = self%xnzsub(k)
            if (kxsub > size(self%nzsub)) error stop "smb_factor: nzsub index out of bounds"
            i = self%nzsub(kxsub)
            self%mrglnk(k) = self%mrglnk(i)
            self%mrglnk(i) = k
        end if

160     continue
        ! Update row index
        self%ixlnz(k+1) = self%ixlnz(k) + knz
    end do

    ! Output results
    nofnz = self%ixlnz(self%n) - 1
    maxsub = self%xnzsub(self%n)
    self%xnzsub(self%n+1) = self%xnzsub(self%n)
end subroutine smb_factor

! Symmetric Cholesky factorization for tree-partitioned system
subroutine ts_factor(self, xblk, father, ierror)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: xblk(:), father(:)
    integer(kind=4), intent(out) :: ierror
    real(kind=8) :: s, temp(self%n)
    integer(kind=4) :: blksze, col, col1, colbeg, colend, colsze
    integer(kind=4) :: first(self%n), fnz, fnz1, i, istop, istrt, isub
    integer(kind=4) :: j, jstop, jstrt, k, kenv, kenv0, kfathr
    integer(kind=4) :: row, rowbeg, rowend, alloc_stat
    real(kind=8), allocatable :: temp_nonz(:)

    ! Check parameter validity
    if (size(xblk) /= self%nblks + 1) then
        error stop "ts_factor: xblk size must be nblks+1"
    end if
    if (size(father) /= self%nblks) then
        error stop "ts_factor: father size must be nblks"
    end if
    if (.not. allocated(self%diag)) error stop "ts_factor: diag not allocated"
    if (.not. allocated(self%xenv)) error stop "ts_factor: xenv not allocated"
    if (.not. allocated(self%env)) error stop "ts_factor: env not allocated"
    if (.not. allocated(self%xnonz)) error stop "ts_factor: xnonz not allocated"
    if (.not. allocated(self%nzsubs)) error stop "ts_factor: nzsubs not allocated"

    ! Init
    ierror = 0
    temp(1:self%n) = 0.0D+00
    first(1:self%n) = self%xnonz(1:self%n)

    ! Allocate/expand nonz array
    if (.not. allocated(self%nonz)) then
        allocate(self%nonz(self%maxnz), stat=alloc_stat)
        if (alloc_stat /= 0) error stop "ts_factor: nonz allocation failed"
    else if (size(self%nonz) < self%maxnz) then
        allocate(temp_nonz(self%maxnz), stat=alloc_stat)
        if (alloc_stat /= 0) error stop "ts_factor: temp_nonz allocation failed"
        temp_nonz(1:size(self%nonz)) = self%nonz(1:size(self%nonz))
        call move_alloc(temp_nonz, self%nonz)
    end if

    ! Block-by-block factorization
    do k = 1, self%nblks
        ! Determine current block range
        rowbeg = xblk(k)
        rowend = xblk(k+1) - 1
        blksze = rowend - rowbeg + 1
        if (blksze <= 0) then
            write(*, '(a,i8)') 'ts_factor: block k=', k, 'invalid size'
            ierror = 2
            return
        end if

        ! Cholesky factorization within block
        call self%es_factor(blksze, &
                           self%xenv(rowbeg:rowbeg+blksze), &
                           self%diag(rowbeg:rowbeg+blksze), &
                           ierror)
        if (ierror /= 0) then
            write(*, '(a)') 'TS_FACTOR - fatal error: block factorization failed'
            write(*, '(a,i8,a,i8)') 'block K=', k, ' error code IERROR=', ierror
            write(*, '(a)') 'TS_FACTOR - fatal: matrix not positive definite'
            return
        end if

        ! Process parent block correction
        kfathr = father(k)
        if (kfathr <= 0) cycle

        ! Determine valid column range for parent block
        colbeg = xblk(kfathr)
        colend = xblk(kfathr+1) - 1
        if (colbeg > colend) cycle

        ! Find valid start for parent block
        do col = colbeg, colend
            jstrt = first(col)
            jstop = self%xnonz(col+1) - 1
            if (jstrt > jstop) cycle
            if (self%nzsubs(jstrt) > rowend) cycle
            exit
        end do
        colbeg = col

        ! Find valid end for parent block
        col = colend
        do col1 = colbeg, colend
            jstrt = first(col)
            jstop = self%xnonz(col+1) - 1
            if (jstrt > jstop) then
                col = col - 1
                cycle
            end if
            fnz1 = self%nzsubs(jstrt)
            if (fnz1 <= rowend) exit
            col = col - 1
        end do
        colend = col
        if (colbeg > colend) cycle

        ! Correct parent block column-by-column
        do col = colbeg, colend
            jstrt = first(col)
            jstop = self%xnonz(col+1) - 1
            if (jstrt > jstop) go to 130

            ! Extract starting row of nonzeros outside block
            fnz = self%nzsubs(jstrt)
            if (fnz > rowend) go to 130

            ! Copy nonzeros to temp
            do j = jstrt, jstop
                if (j > size(self%nzsubs)) error stop "ts_factor: nzsubs index out of bounds"
                row = self%nzsubs(j)
                if (row > rowend) exit
                if (row < 1 .or. row > self%n) error stop "ts_factor: row invalid"
                temp(row) = self%nonz(j)
            end do

            ! Forward + backward substitution
            colsze = rowend - fnz + 1
            if (colsze <= 0) then
                temp(fnz:rowend) = 0.0D+00
                go to 130
            end if
            call self%el_solve(colsze, &
                               self%xenv(fnz:fnz+colsze), &
                               self%diag(fnz:fnz+colsze-1), &
                               temp(fnz:fnz+colsze-1))
            call self%eu_solve(colsze, &
                               self%xenv(fnz:fnz+colsze), &
                               self%diag(fnz:fnz+colsze-1), &
                               temp(fnz:fnz+colsze-1))

            ! Compute inner product and correction
            kenv0 = self%xenv(col+1) - col
            do col1 = colbeg, colend
                istrt = first(col1)
                istop = self%xnonz(col1+1) - 1
                if (istrt > istop) cycle

                fnz1 = self%nzsubs(istrt)
                if (fnz1 > rowend) cycle
                if (fnz1 < fnz) cycle
                if (fnz1 == fnz .and. col1 < col) cycle

                ! Compute inner product
                s = 0.0D+00
                do i = istrt, istop
                    if (i > size(self%nzsubs)) error stop "ts_factor: nzsubs index out of bounds"
                    isub = self%nzsubs(i)
                    if (isub > rowend) exit
                    if (isub < 1 .or. isub > self%n) error stop "ts_factor: isub invalid"
                    s = s + temp(isub) * self%nonz(i)
                end do

                ! Correct parent block element
                if (col1 /= col) then
                    kenv = kenv0 + col1
                    if (col < col1) kenv = self%xenv(col1+1) - col1 + col
                    if (kenv < 1 .or. kenv > size(self%env)) error stop "ts_factor: env index out of bounds"
                    self%env(kenv) = self%env(kenv) - s
                else
                    self%diag(col1) = self%diag(col1) - s
                end if
            end do

            ! Reset temp
            temp(fnz:rowend) = 0.0D+00
130         continue
        end do

        ! Update parent block first array
        do col = colbeg, colend
            jstrt = first(col)
            jstop = self%xnonz(col+1) - 1
            if (jstrt > jstop) cycle
            do j = jstrt, jstop
                if (j > size(self%nzsubs)) error stop "ts_factor: nzsubs index out of bounds"
                row = self%nzsubs(j)
                if (row > rowend) then
                    first(col) = j
                    go to 150
                end if
            end do
            first(col) = jstop + 1
150         continue
        end do
    end do

    ! Release temporary arrays
    if (allocated(temp_nonz)) deallocate(temp_nonz)
end subroutine ts_factor

!----------------------------------------------------------------------
! Solution algorithm related subroutines
!----------------------------------------------------------------------

! Solve factored sparse system LL^T*x = b
subroutine gs_solve(self, rhs)
    class(SparsePakType), intent(in) :: self
    real(kind=8), intent(inout) :: rhs(:)
    real(kind=8) :: rhsj, s
    integer(kind=4) :: i, ii, istop, istrt, isub, j, jj

    ! Check parameters
    if (size(rhs) /= self%n) error stop "gs_solve: rhs size mismatch with n"
    if (.not. allocated(self%xlnz)) error stop "gs_solve: xlnz not allocated"
    if (.not. allocated(self%ixlnz)) error stop "gs_solve: ixlnz not allocated"
    if (.not. allocated(self%nzsub)) error stop "gs_solve: nzsub not allocated"
    if (.not. allocated(self%xnzsub)) error stop "gs_solve: xnzsub not allocated"
    if (.not. allocated(self%diag)) error stop "gs_solve: diag not allocated"

    ! Step 1: Forward substitution L*y = b
    do j = 1, self%n
        rhsj = rhs(j) / self%diag(j)
        rhs(j) = rhsj

        ! Process current column nonzeros
        istrt = self%ixlnz(j)
        istop = self%ixlnz(j+1) - 1
        i = self%xnzsub(j)
        do ii = istrt, istop
            if (i < 1 .or. i > size(self%nzsub)) error stop "gs_solve: nzsub index out of bounds"
            isub = self%nzsub(i)
            if (isub < 1 .or. isub > self%n) error stop "gs_solve: isub invalid"
            rhs(isub) = rhs(isub) - self%xlnz(ii) * rhsj
            i = i + 1
        end do
    end do

    ! Step 2: Backward substitution L^T*x = y
    j = self%n
    do jj = 1, self%n
        s = rhs(j)

        ! Process current row nonzeros
        istrt = self%ixlnz(j)
        istop = self%ixlnz(j+1) - 1
        i = self%xnzsub(j)
        do ii = istrt, istop
            if (i < 1 .or. i > size(self%nzsub)) error stop "gs_solve: nzsub index out of bounds"
            isub = self%nzsub(i)
            if (isub < 1 .or. isub > self%n) error stop "gs_solve: isub invalid"
            s = s - self%xlnz(ii) * rhs(isub)
            i = i + 1
        end do

        ! Solve for x(j)
        rhs(j) = s / self%diag(j)
        j = j - 1
    end do
end subroutine gs_solve

! Solve lower triangular envelope system L*x = b
subroutine el_solve(self, n_sys, xenv_sys, diag_sys, rhs_sys)
    class(SparsePakType), intent(in) :: self
    integer(kind=4), intent(in) :: n_sys, xenv_sys(:)
    real(kind=8), intent(in) :: diag_sys(:)
    real(kind=8), intent(inout) :: rhs_sys(:)
    integer(kind=4) :: i, iband, ifirst, k, kstop, kstrt, l, last
    real(kind=8) :: s

    ! Check parameters
    if (size(xenv_sys) /= n_sys + 1) error stop "el_solve: xenv_sys size mismatch"
    if (size(diag_sys) /= n_sys) error stop "el_solve: diag_sys size mismatch"
    if (size(rhs_sys) /= n_sys) error stop "el_solve: rhs_sys size mismatch"
    if (.not. allocated(self%env)) error stop "el_solve: env not allocated"

    ! Find first nonzero RHS element
    ifirst = 0
    do
        ifirst = ifirst + 1
        if (rhs_sys(ifirst) /= 0.0D+00) exit
        if (n_sys <= ifirst) return
    end do

    ! Forward substitution
    last = 0
    do i = ifirst, n_sys
        iband = xenv_sys(i+1) - xenv_sys(i)
        iband = min(iband, i - 1)
        s = rhs_sys(i)
        l = i - iband
        rhs_sys(i) = 0.0D+00

        ! Accumulate envelope contribution
        if (iband /= 0 .and. 1 <= last) then
            kstrt = xenv_sys(i+1) - iband
            kstop = xenv_sys(i+1) - 1
            if (kstop > size(self%env)) error stop "el_solve: env index out of bounds"
            do k = kstrt, kstop
                s = s - self%env(k) * rhs_sys(l)
                l = l + 1
            end do
        end if

        ! Update
        if (s /= 0.0D+00) then
            rhs_sys(i) = s / diag_sys(i)
            last = i
        end if
    end do
end subroutine el_solve

! Solve upper triangular envelope system U*x = b
subroutine eu_solve(self, n_sys, xenv_sys, diag_sys, rhs_sys)
    class(SparsePakType), intent(in) :: self
    integer(kind=4), intent(in) :: n_sys, xenv_sys(:)
    real(kind=8), intent(in) :: diag_sys(:)
    real(kind=8), intent(inout) :: rhs_sys(:)
    integer(kind=4) :: i, iband, k, kstop, kstrt, l

    ! Check parameters
    if (size(xenv_sys) /= n_sys + 1) error stop "eu_solve: xenv_sys size mismatch"
    if (size(diag_sys) /= n_sys) error stop "eu_solve: diag_sys size mismatch"
    if (size(rhs_sys) /= n_sys) error stop "eu_solve: rhs_sys size mismatch"
    if (.not. allocated(self%env)) error stop "eu_solve: env not allocated"

    ! Backward substitution
    i = n_sys + 1
    do
        i = i - 1
        if (i == 0) exit
        if (rhs_sys(i) == 0.0D+00) cycle

        ! Solve current entry
        rhs_sys(i) = rhs_sys(i) / diag_sys(i)

        ! Compute bandwidth
        iband = xenv_sys(i+1) - xenv_sys(i)
        if (i <= iband) iband = i - 1
        if (iband == 0) cycle

        ! Update preceding entries
        kstrt = i - iband
        kstop = i - 1
        l = xenv_sys(i+1) - iband
        if (l > size(self%env)) error stop "eu_solve: env index out of bounds"
        do k = kstrt, kstop
            rhs_sys(k) = rhs_sys(k) - self%env(l) * rhs_sys(i)
            l = l + 1
        end do
    end do
end subroutine eu_solve


! Tree-partitioned system solution (Forward + Backward substitution)
subroutine ts_solve(self, xblk, rhs)
    class(SparsePakType), intent(in) :: self
    integer(kind=4), intent(in) :: xblk(:)
    real(kind=8), intent(inout) :: rhs(:)
    real(kind=8) :: s, temp(self%n)
    integer(kind=4) :: col, col1, col2, i, j, jstop, jstrt, last, ncol, nrow
    integer(kind=4) :: rowbeg, rowend, row

    ! Check parameter validity
    if (size(xblk) /= self%nblks + 1) then
        error stop "ts_solve: xblk size must be nblks+1"
    end if
    if (size(rhs) /= self%n) then
        error stop "ts_solve: rhs size mismatch"
    end if
    if (.not. allocated(self%diag)) error stop "ts_solve: diag not allocated"
    if (.not. allocated(self%xenv)) error stop "ts_solve: xenv not allocated"
    if (.not. allocated(self%env)) error stop "ts_solve: env not allocated"
    if (.not. allocated(self%xnonz)) error stop "ts_solve: xnonz not allocated"
    if (.not. allocated(self%nonz)) error stop "ts_solve: nonz not allocated"
    if (.not. allocated(self%nzsubs)) error stop "ts_solve: nzsubs not allocated"

    ! Step 1: Forward substitution (process blocks in order)
    do i = 1, self%nblks
        rowbeg = xblk(i)
        rowend = xblk(i+1) - 1
        nrow = rowend - rowbeg + 1

        ! Forward substitution L*y = b
        call self%el_solve( &
            n_sys = nrow, &
            xenv_sys = self%xenv(rowbeg:rowbeg+nrow), &
            diag_sys = self%diag(rowbeg:rowbeg+nrow-1), &
            rhs_sys = rhs(rowbeg:rowbeg+nrow-1) &
        )

        ! Backward substitution L^T*x = y
        call self%eu_solve( &
            n_sys = nrow, &
            xenv_sys = self%xenv(rowbeg:rowbeg+nrow), &
            diag_sys = self%diag(rowbeg:rowbeg+nrow-1), &
            rhs_sys = rhs(rowbeg:rowbeg+nrow-1) &
        )
    end do

    ! Step 2: Backward substitution (process blocks in reverse order)
    if (self%nblks == 1) return
    last = xblk(self%nblks) - 1
    if (last >= 1) temp(1:last) = 0.0D+00

    i = self%nblks
    col1 = xblk(i)
    col2 = xblk(i+1) - 1
    do
        if (i == 1) exit

        ! Correct preceding block temporary arrays with current block solution
        if (self%xnonz(col2+1) /= self%xnonz(col1)) then
            do col = col1, col2
                s = rhs(col)
                if (s == 0.0D+00) cycle

                jstrt = self%xnonz(col)
                jstop = self%xnonz(col+1) - 1
                if (jstrt > jstop) cycle

                do j = jstrt, jstop
                    if (j > size(self%nzsubs)) error stop "ts_solve: nzsubs index out of bounds"
                    row = self%nzsubs(j)
                    if (row < 1 .or. row > last) cycle
                    temp(row) = temp(row) + s * self%nonz(j)
                end do
            end do
        end if

        ! Process previous block
        i = i - 1
        col1 = xblk(i)
        col2 = xblk(i+1) - 1
        ncol = col2 - col1 + 1
        if (ncol <= 0) then
            write(*, '(a,i8)') 'ts_solve: block i=', i, 'invalid size'
            return
        end if

        ! Solve within block and correct temporary array
        call self%el_solve(ncol, &
                           self%xenv(col1:col1+ncol), &
                           self%diag(col1:col1+ncol), &
                           temp(col1:col1+ncol))
        call self%eu_solve(ncol, &
                           self%xenv(col1:col1+ncol), &
                           self%diag(col1:col1+ncol), &
                           temp(col1:col1+ncol))

        ! Correct preceding block solution
        do j = col1, col2
            rhs(j) = rhs(j) - temp(j)
            temp(j) = 0.0D+00
        end do
    end do
end subroutine ts_solve

!----------------------------------------------------------------------
! QMD algorithm related subroutines
!----------------------------------------------------------------------

! Merge indistinguishable nodes in QMD algorithm
subroutine qmdmrg(self, deg0, nhdsze, nbrhd)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: deg0, nhdsze, nbrhd(:)
    integer(kind=4) :: deg1, head, inhd, iov, irch, j, jstrt, jstop
    integer(kind=4) :: link, lnode, mark, mrgsze, nabor, node, novrlp, root
    integer(kind=4) :: rchsze

    ! Check params and arrays
    if (nhdsze > size(nbrhd)) error stop "qmdmrg: nbrhd size insufficient"
    if (.not. allocated(self%adj_row)) error stop "qmdmrg: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "qmdmrg: adj not allocated"
    if (.not. allocated(self%deg)) error stop "qmdmrg: deg not allocated"
    if (.not. allocated(self%qsize)) error stop "qmdmrg: qsize not allocated"
    if (.not. allocated(self%qlink)) error stop "qmdmrg: qlink not allocated"
    if (.not. allocated(self%marker)) error stop "qmdmrg: marker not allocated"
    if (.not. allocated(self%rchset)) error stop "qmdmrg: rchset not allocated"
    if (.not. allocated(self%ovrlp)) error stop "qmdmrg: ovrlp not allocated"

    ! No neighborhood set, exit directly
    if (nhdsze <= 0) return

    ! Initialize neighborhood set markers
    do inhd = 1, nhdsze
        root = nbrhd(inhd)
        self%marker(root) = 0
    end do

    ! Merge supernodes one by one
    do inhd = 1, nhdsze
        root = nbrhd(inhd)
        self%marker(root) = -1
        rchsze = 0
        novrlp = 0
        deg1 = 0

20      continue
        ! Build reachable set and overlaps
        jstrt = self%adj_row(root)
        jstop = self%adj_row(root+1) - 1
        do j = jstrt, jstop
            if (j > size(self%adj)) error stop "qmdmrg: adj index out of bounds"
            nabor = self%adj(j)
            root = -nabor
            if (nabor < 0) go to 20
            if (nabor == 0) exit

            mark = self%marker(nabor)
            if (mark == 0) then
                ! Add to reachable set
                rchsze = rchsze + 1
                if (rchsze > size(self%rchset)) error stop "qmdmrg: rchset size insufficient"
                self%rchset(rchsze) = nabor
                deg1 = deg1 + self%qsize(nabor)
                self%marker(nabor) = 1
            else if (mark == 1) then
                ! Add to overlap set
                novrlp = novrlp + 1
                if (novrlp > size(self%ovrlp)) error stop "qmdmrg: ovrlp size insufficient"
                self%ovrlp(novrlp) = nabor
                self%marker(nabor) = 2
            end if
        end do

        ! Filter mergeable nodes
        head = 0
        mrgsze = 0
        do iov = 1, novrlp
            node = self%ovrlp(iov)
            jstrt = self%adj_row(node)
            jstop = self%adj_row(node+1) - 1

            ! Check adjacent node markers
            do j = jstrt, jstop
                if (j > size(self%adj)) error stop "qmdmrg: adj index out of bounds"
                nabor = self%adj(j)
                if (self%marker(nabor) == 0) then
                    self%marker(node) = 1
                    go to 110
                end if
            end do

            ! Merge supernodes
            mrgsze = mrgsze + self%qsize(node)
            self%marker(node) = -1
            lnode = node

            ! Find supernode linkage chain
            do
                link = self%qlink(lnode)
                if (link <= 0) exit
                lnode = link
            end do
            self%qlink(lnode) = head
            head = node

110         continue
        end do

        ! Update new supernode degree and size
        if (0 < head) then
            self%qsize(head) = mrgsze
            self%deg(head) = deg0 + deg1 - 1
            self%marker(head) = 2
        end if

        ! Reset markers
        root = nbrhd(inhd)
        self%marker(root) = 0
        do irch = 1, rchsze
            node = self%rchset(irch)
            self%marker(node) = 0
        end do
    end do
end subroutine qmdmrg

! Form new quotient graph in QMD algorithm
subroutine qmdqt(self, root, rchsze, rchset)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: root, rchsze, rchset(:)
    integer(kind=4) :: i, inode, ir, j, jj, jstrt, jstop, nabor, node, ptr
    integer(kind=4) :: new_size, alloc_stat, adj_row_old(self%n+1)
    integer(kind=4), allocatable :: temp_adj(:)

    ! Check params and arrays
    if (rchsze > size(rchset)) error stop "qmdqt: rchset size insufficient"
    if (.not. allocated(self%adj_row)) error stop "qmdqt: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "qmdqt: adj not allocated"
    if (.not. allocated(self%marker)) error stop "qmdqt: marker not allocated"

    adj_row_old = self%adj_row

    ! Mark root node neighbors
    jstrt = adj_row_old(root)
    jstop = adj_row_old(root+1) - 1
    do j = jstrt, jstop
        if (j > size(self%adj)) error stop "qmdqt: adj index out of bounds"
        nabor = self%adj(j)
        if (nabor == 0) exit
        self%marker(nabor) = -self%marker(nabor)
    end do

    ! Process reachable set nodes
    do ir = 1, rchsze
        node = rchset(ir)
        ptr = adj_row_old(node)
        jstrt = ptr

        ! Inner loop variable jj to avoid conflicts
        do jj = jstrt, adj_row_old(node+1) - 1
            if (jj > size(self%adj)) error stop "qmdqt: adj index out of bounds"
            nabor = self%adj(jj)
            if (nabor == 0) exit

            if (self%marker(nabor) < 0) then
                self%marker(nabor) = -self%marker(nabor)
                cycle
            elseif (self%deg(nabor) < 0 .and. self%qlink(nabor) /= 0) then
                cycle
            end if

            self%adj(ptr) = nabor
            ptr = ptr + 1
        end do

        ! Expand adj array
        if (ptr > size(self%adj)) then
            new_size = max(int(1.5*size(self%adj)), ptr + rchsze)
            allocate(temp_adj(new_size), stat=alloc_stat)
            if (alloc_stat /= 0) error stop "qmdqt: temp_adj allocation failed"
            temp_adj(1:size(self%adj)) = self%adj(1:size(self%adj))
            call move_alloc(temp_adj, self%adj)
        end if

        self%adj(ptr) = root
        ptr = ptr + 1
        self%adj_row(node+1) = ptr

        ! Reverse adjacency update
        do i = 1, rchsze
            inode = rchset(i)
            if (inode == node) cycle

            do j = adj_row_old(inode), adj_row_old(inode+1) - 1
                if (j > size(self%adj)) error stop "qmdqt: adj index out of bounds"
                if (self%adj(j) == node) go to 10
            end do

            ptr = adj_row_old(inode+1)
            if (ptr > size(self%adj)) then
                new_size = max(int(1.5*size(self%adj)), ptr + 1)
                allocate(temp_adj(new_size), stat=alloc_stat)
                if (alloc_stat /= 0) error stop "qmdqt: temp_adj allocation failed"
                temp_adj(1:size(self%adj)) = self%adj(1:size(self%adj))
                call move_alloc(temp_adj, self%adj)
            end if

            self%adj(ptr) = node
            self%adj_row(inode+1) = ptr + 1

10          continue
        end do
    end do

    ! Reset root node marker
    jstrt = adj_row_old(root)
    jstop = adj_row_old(root+1) - 1
    do j = jstrt, jstop
        if (j > size(self%adj)) error stop "qmdqt: adj index out of bounds"
        nabor = self%adj(j)
        if (nabor == 0) exit
        self%marker(nabor) = -self%marker(nabor)
    end do
end subroutine qmdqt

! Compute reachable set and neighborhood set in QMD algorithm
subroutine qmdrch(self, root, rchsze, nbrhdsz)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: root
    integer(kind=4), intent(out) :: rchsze, nbrhdsz
    integer(kind=4) :: i, istop, istrt, j, jstop, jstrt, nabor, node

    ! Check dimension
    if (.not. allocated(self%adj_row)) error stop "qmdrch: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "qmdrch: adj not allocated"
    if (.not. allocated(self%deg)) error stop "qmdrch: deg not allocated"
    if (.not. allocated(self%marker)) error stop "qmdrch: marker not allocated"
    if (.not. allocated(self%rchset)) error stop "qmdrch: rchset not allocated"
    if (.not. allocated(self%nbrhd)) error stop "qmdrch: nbrhd not allocated"

    ! Initialize output
    rchsze = 0
    nbrhdsz = 0
    istrt = self%adj_row(root)
    istop = self%adj_row(root+1) - 1

    ! Traverse root node adjacent nodes
    do i = istrt, istop
        if (i > size(self%adj)) error stop "qmdrch: adj index out of bounds"
        nabor = self%adj(i)
        if (nabor == 0) return

        if (self%marker(nabor) /= 0) cycle

        ! Distinguish reachable set from neighborhood set
        if (0 <= self%deg(nabor)) then
            ! Add to reachable set
            rchsze = rchsze + 1
            if (rchsze > size(self%rchset)) error stop "qmdrch: rchset size insufficient"
            self%rchset(rchsze) = nabor
            self%marker(nabor) = 1
            cycle
        end if

        ! Add to neighborhood set
        self%marker(nabor) = -1
        nbrhdsz = nbrhdsz + 1
        if (nbrhdsz > size(self%nbrhd)) error stop "qmdrch: nbrhd size insufficient"
        self%nbrhd(nbrhdsz) = nabor

20      continue
        ! Recursively process adjacency of neighborhood nodes
        jstrt = self%adj_row(nabor)
        jstop = self%adj_row(nabor+1) - 1
        do j = jstrt, jstop
            if (j > size(self%adj)) error stop "qmdrch: adj index out of bounds"
            node = self%adj(j)
            nabor = -node
            if (node < 0) go to 20
            if (node == 0) cycle

            if (self%marker(node) == 0) then
                rchsze = rchsze + 1
                if (rchsze > size(self%rchset)) error stop "qmdrch: rchset size insufficient"
                self%rchset(rchsze) = node
                self%marker(node) = 1
            end if
        end do
    end do
end subroutine qmdrch

! Update degrees of reachable set nodes in QMD algorithm
subroutine qmdupd(self, nlist, list)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: nlist, list(:)
    integer(kind=4) :: deg0, deg1, il, inhd, inode, irch, j, jstop, jstrt
    integer(kind=4) :: mark, nhdsze, node, rchsze, nabor

    ! Check params and arrays
    if (nlist > size(list)) error stop "qmdupd: list size insufficient"
    if (.not. allocated(self%adj_row)) error stop "qmdupd: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "qmdupd: adj not allocated"
    if (.not. allocated(self%deg)) error stop "qmdupd: deg not allocated"
    if (.not. allocated(self%qsize)) error stop "qmdupd: qsize not allocated"
    if (.not. allocated(self%qlink)) error stop "qmdupd: qlink not allocated"
    if (.not. allocated(self%marker)) error stop "qmdupd: marker not allocated"
    if (.not. allocated(self%rchset)) error stop "qmdupd: rchset not allocated"
    if (.not. allocated(self%nbrhd)) error stop "qmdupd: nbrhd not allocated"
    if (.not. allocated(self%ovrlp)) error stop "qmdupd: ovrlp not allocated"

    if (nlist <= 0) return

    deg0 = 0
    nhdsze = 0

    ! Collect neighborhood
    do il = 1, nlist
        node = list(il)
        deg0 = deg0 + self%qsize(node)
        jstrt = self%adj_row(node)
        jstop = self%adj_row(node+1) - 1

        do j = jstrt, jstop
            if (j > size(self%adj)) error stop "qmdupd: adj index out of bounds"
            nabor = self%adj(j)
            if (self%marker(nabor) == 0 .and. self%deg(nabor) < 0 &
                .and. self%qlink(nabor) == 0) then
                self%marker(nabor) = -1
                nhdsze = nhdsze + 1
                if (nhdsze > size(self%nbrhd)) error stop "qmdupd: nbrhd size insufficient"
                self%nbrhd(nhdsze) = nabor
            end if
        end do
    end do

    ! Merge indistinguishable nodes
    if (nhdsze > 0) call self%qmdmrg(deg0, nhdsze, self%nbrhd(1:nhdsze))

    ! Update reachable set node degrees
    do il = 1, nlist
        node = list(il)
        mark = self%marker(node)
        if (mark == 0 .or. mark == 1) then
            self%marker(node) = 2
            call self%qmdrch(node, rchsze, nhdsze)
            deg1 = deg0

            do irch = 1, rchsze
                inode = self%rchset(irch)
                deg1 = deg1 + self%qsize(inode)
                self%marker(inode) = 0
            end do

            self%deg(node) = deg1 - 1

            do inhd = 1, nhdsze
                inode = self%nbrhd(inhd)
                self%marker(inode) = 0
            end do
        end if
    end do
end subroutine qmdupd

!----------------------------------------------------------------------
! Other auxiliary subroutines
!----------------------------------------------------------------------

! Compute nodes in connected component
subroutine degree(self, root, ccsize, ls)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: root
    integer(kind=4), intent(out) :: ccsize, ls(:)
    integer(kind=4) :: i, ideg, j, jstop, jstrt, lbegin, lvlend, lvsize
    integer(kind=4) :: nbr, node

    ! Check params and arrays
    if (size(ls) < self%n) error stop "degree: ls size insufficient"
    if (.not. allocated(self%adj_row)) error stop "degree: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "degree: adj not allocated"
    if (.not. allocated(self%mask)) error stop "degree: mask not allocated"
    if (.not. allocated(self%deg)) error stop "degree: deg not allocated"

    ! Init
    ls(1) = root
    if (root < 1 .or. root > self%n) error stop "degree: root index out of bounds"
    self%adj_row(root) = -self%adj_row(root)
    lvlend = 0
    ccsize = 1

    ! Level-order traversal to compute node degree
    do
        lbegin = lvlend + 1
        lvlend = ccsize
        ccsize = ccsize  ! Keep loop variable consistent

        ! Compute nodes at current level
        do i = lbegin, lvlend
            if (i > size(ls)) error stop "degree: ls index out of bounds"
            node = ls(i)
            jstrt = -self%adj_row(node)
            jstop = abs(self%adj_row(node+1)) - 1
            if (jstrt < 1) error stop "degree: adj_row invalid"

            ideg = 0
            do j = jstrt, jstop
                if (j > size(self%adj)) error stop "degree: adj index out of bounds"
                nbr = self%adj(j)
                if (self%mask(nbr) /= 0) then
                    ideg = ideg + 1
                    if (0 <= self%adj_row(nbr)) then
                        self%adj_row(nbr) = -self%adj_row(nbr)
                        ccsize = ccsize + 1
                        if (ccsize > size(ls)) error stop "degree: ls size insufficient"
                        ls(ccsize) = nbr
                    end if
                end if
            end do
            self%deg(node) = ideg
        end do

        ! Check next level
        lvsize = ccsize - lvlend
        if (lvsize == 0) exit
    end do

    ! Reset adj_row markers
    do i = 1, ccsize
        if (i > size(ls)) error stop "degree: ls index out of bounds"
        node = ls(i)
        self%adj_row(node) = -self%adj_row(node)
    end do
end subroutine degree

! Compute off-block nonzero count and allocate nonz array
subroutine fnofnz(self, xblk, xnonz, nzsubs, nofnz)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: xblk(:)
    integer(kind=4), intent(out) :: xnonz(:), nzsubs(:), nofnz
    integer(kind=4) :: b, i, ib, j, jb, nabor, node, blk(self%n)
    integer(kind=4) :: alloc_stat, temp_nofnz, jstrt, jstop

    ! Step 1: Initialize block mapping
    blk(1:self%n) = 0
    do b = 1, size(xblk)-1
        do i = xblk(b), xblk(b+1)-1
            node = self%perm(i)
            blk(node) = b
        end do
    end do

    ! Step 2: Count total off-block nonzeros
    xnonz(1:self%n+1) = 1
    temp_nofnz = 0
    do b = 1, size(xblk)-1
        do i = xblk(b), xblk(b+1)-1
            node = self%perm(i)
            jstrt = self%adj_row(node)
            jstop = self%adj_row(node+1)-1

            do j = jstrt, jstop
                nabor = self%adj(j)
                jb = blk(nabor)
                ib = blk(node)

                ! Check for off-block nonzeros
                if (jb /= ib .and. nabor /= node) then
                    temp_nofnz = temp_nofnz + 1
                    if (temp_nofnz > nofnz) then
                        write(*, '(a)') 'FNOFNZ - warning: nofnz exceeds max capacity'
                        write(*, '(a,i8,a,i8)') 'temp_nofnz = ', temp_nofnz, &
                            '; max nofnz = ', nofnz
                        nofnz = temp_nofnz
                    end if
                    nzsubs(temp_nofnz) = jb
                end if
            end do
        end do
    end do
    nofnz = temp_nofnz

    ! Step 3: Allocate nonz array
    if (.not. allocated(self%nonz)) then
        allocate(self%nonz(nofnz), stat=alloc_stat)
        if (alloc_stat /= 0) then
            write(*, '(a)') 'FNOFNZ - fatal error: self%nonz allocation failed'
            write(*, '(a,i8)') 'Required size = nofnz = ', nofnz
            error stop
        end if
        self%nonz(1:nofnz) = 0.0d0
    else if (size(self%nonz) < nofnz) then
        deallocate(self%nonz)
        allocate(self%nonz(nofnz), stat=alloc_stat)
        if (alloc_stat /= 0) then
            write(*, '(a)') 'FNOFNZ - fatal: self%nonz realloc failed'
            write(*, '(a,i8)') 'Required size = nofnz = ', nofnz
            error stop
        end if
        self%nonz(1:nofnz) = 0.0d0
    end if

    ! Debug information
    write(*, '(a)') ' '
    write(*, '(a,i8)') 'FNOFNZ complete: off-block nonzeros = ', nofnz
    write(*, '(a,i8)') 'self%nonz allocated size = ', size(self%nonz)
end subroutine fnofnz

! Find span of level subgraph subset (RQT auxiliary routine)
subroutine fnspan(self, nspan, set, level, nadjs, adjs, leaf)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(inout) :: nspan, set(:)
    integer(kind=4), intent(in) :: level
    integer(kind=4), intent(out) :: nadjs, adjs(:), leaf
    integer(kind=4) :: i, j, jstop, jstrt, lvl, lvlm1, nbr, nbrlvl, node
    integer(kind=4) :: nabor, setptr

    ! Check parameters
    if (size(set) < nspan) error stop "fnspan: set size insufficient"
    if (size(adjs) < self%n) error stop "fnspan: adjs size insufficient"
    if (.not. allocated(self%adj_row)) error stop "fnspan: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "fnspan: adj not allocated"
    if (.not. allocated(self%nodlvl)) error stop "fnspan: nodlvl not allocated"

    ! Init
    leaf = 0
    nadjs = 0
    setptr = 0

10  continue
    setptr = setptr + 1
    if (nspan < setptr) return
    node = set(setptr)
    if (node < 1 .or. node > self%n) error stop "fnspan: set node out of range"

    ! Adjacency list range
    jstrt = self%adj_row(node)
    jstop = self%adj_row(node+1) - 1
    if (jstop < jstrt) go to 10

    ! Traverse adjacent nodes
    do j = jstrt, jstop
        if (j > size(self%adj)) error stop "fnspan: adj index out of bounds"
        nabor = self%adj(j)
        if (nabor < 1 .or. nabor > self%n) error stop "fnspan: adj neighbor out of range"

        nbrlvl = self%nodlvl(nabor)
        if (0 < nbrlvl) then
            if (level == nbrlvl) then
                ! Add to span subset at same level
                nspan = nspan + 1
                if (nspan > size(set)) error stop "fnspan: set size insufficient"
                set(nspan) = nabor
                self%nodlvl(nabor) = 0
            else if (level < nbrlvl) then
                ! High-level triggers leaf node search
                go to 60
            else
                ! Low-level adds to adjacency set
                nadjs = nadjs + 1
                if (nadjs > size(adjs)) error stop "fnspan: adjs size insufficient"
                adjs(nadjs) = nabor
                self%nodlvl(nabor) = 0
            end if
        end if
    end do
    go to 10

    ! Find leaf nodes
60  continue
    leaf = nabor
    lvl = level + 1

70  continue
    jstrt = self%adj_row(leaf)
    jstop = self%adj_row(leaf+1) - 1
    do j = jstrt, jstop
        if (j > size(self%adj)) error stop "fnspan: adj index out of bounds"
        nbr = self%adj(j)
        if (nbr < 1 .or. nbr > self%n) error stop "fnspan: adj neighbor out of range"

        if (lvl < self%nodlvl(nbr)) then
            leaf = nbr
            lvl = lvl + 1
            go to 70
        end if
    end do

    ! Reset neighborhood set node levels
    if (nadjs <= 0) return
    lvlm1 = level - 1
    do i = 1, nadjs
        node = adjs(i)
        if (node < 1 .or. node > self%n) error stop "fnspan: adjs node out of range"
        self%nodlvl(node) = lvlm1
    end do
end subroutine fnspan

! Compute reachable set and neighborhood set from root node
subroutine reach(self, root, rchsze, rchset, nhdsze, nbrhd)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: root
    integer(kind=4), intent(inout) :: rchsze, rchset(:)
    integer(kind=4), intent(out) :: nhdsze, nbrhd(:)
    integer(kind=4) :: i, istop, istrt, j, jstop, jstrt, nabor, nbr
    integer(kind=4) :: newnhd, node, nhdptr

    ! Check params and arrays
    if (.not. allocated(self%adj_row)) error stop "reach: adj_row not allocated"
    if (.not. allocated(self%adj)) error stop "reach: adj not allocated"
    if (.not. allocated(self%mask)) error stop "reach: mask not allocated"
    if (.not. allocated(self%marker)) error stop "reach: marker not allocated"

    ! Init
    nhdsze = 0
    newnhd = 0
    if (self%marker(root) <= 0) then
        rchsze = 1
        if (rchsze > size(rchset)) error stop "reach: rchset size insufficient"
        rchset(rchsze) = root
        self%marker(root) = root
    end if

    istrt = self%adj_row(root)
    istop = self%adj_row(root+1) - 1
    if (istop < istrt) return

    ! Traverse adjacent nodes
    do i = istrt, istop
        if (i > size(self%adj)) error stop "reach: adj index out of bounds"
        nabor = self%adj(i)
        if (self%marker(nabor) /= 0) cycle

        ! Adjacent node not in filter subset: Add to reachable set
        if (self%mask(nabor) <= 0) then
            rchsze = rchsze + 1
            if (rchsze > size(rchset)) error stop "reach: rchset size insufficient"
            rchset(rchsze) = nabor
            self%marker(nabor) = root
            cycle
        end if

        ! Adjacent node in filter subset: Add to neighborhood set
        nhdsze = nhdsze + 1
        newnhd = newnhd + 1
        if (newnhd > size(nbrhd)) error stop "reach: nbrhd size insufficient"
        nbrhd(newnhd) = nabor
        self%marker(nabor) = root
        nhdptr = newnhd

        do
            node = nbrhd(nhdptr)
            jstrt = self%adj_row(node)
            jstop = self%adj_row(node+1) - 1

            do j = jstrt, jstop
                if (j > size(self%adj)) error stop "reach: adj index out of bounds"
                nbr = self%adj(j)
                if (self%marker(nbr) == 0) then
                    if (self%mask(nbr) /= 0) then
                        ! Add to neighborhood set
                        nhdsze = nhdsze + 1
                        newnhd = newnhd + 1
                        if (newnhd > size(nbrhd)) error stop "reach: nbrhd size insufficient"
                        nbrhd(newnhd) = nbr
                        self%marker(nbr) = root
                    else
                        ! Add to reachable set
                        rchsze = rchsze + 1
                        if (rchsze > size(rchset)) error stop "reach: rchset size insufficient"
                        rchset(rchsze) = nbr
                        self%marker(nbr) = root
                    end if
                end if
            end do

            nhdptr = nhdptr + 1
            if (nhdsze < nhdptr) exit
        end do
    end do
end subroutine reach

!----------------------------------------------------------------------
! Auxiliary utility subroutines
!----------------------------------------------------------------------

! Swap two 4-byte integers
subroutine i4_swap(self, i, j)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(inout) :: i, j
    integer(kind=4) :: k

    k = i
    i = j
    j = k
end subroutine i4_swap

! Copy 4-byte integer vector
subroutine i4vec_copy(self, n, a, b)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: n, a(:)
    integer(kind=4), intent(out) :: b(:)

    if (size(a) < n .or. size(b) < n) then
        error stop "i4vec_copy: Source or target vector size insufficient"
    end if
    b(1:n) = a(1:n)
end subroutine i4vec_copy

! Generate identity integer vector (a(i)=i)
subroutine i4vec_indicator(self, n, a)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: n
    integer(kind=4), intent(out) :: a(:)
    integer(kind=4) :: i

    if (size(a) < n) error stop "i4vec_indicator: vector size insufficient"
    do i = 1, n
        a(i) = i
    end do
end subroutine i4vec_indicator

! Reverse 4-byte integer vector
subroutine i4vec_reverse(self, n, a)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: n
    integer(kind=4), intent(inout) :: a(:)
    integer(kind=4) :: i, temp

    if (size(a) < n) error stop "i4vec_reverse: vector size insufficient"
    do i = 1, n/2
        call self%i4_swap(a(i), a(n+1-i))
    end do
end subroutine i4vec_reverse

! Ascending insertion sort for 4-byte integer vector
subroutine i4vec_sort_insert_a(self, n, a)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: n
    integer(kind=4), intent(inout) :: a(:)
    integer(kind=4) :: i, j, x

    if (size(a) < n) error stop "i4vec_sort_insert_a: vector size insufficient"
    do i = 2, n
        x = a(i)
        j = i - 1
        do while (1 <= j)
            if (a(j) <= x) exit
            a(j+1) = a(j)
            j = j - 1
        end do
        a(j+1) = x
    end do
end subroutine i4vec_sort_insert_a

! Generate inverse of permutation vector
subroutine perm_inverse(self, perm, perm_inv)
    class(SparsePakType), intent(inout) :: self
    integer(kind=4), intent(in) :: perm(:)
    integer(kind=4), intent(out) :: perm_inv(:)
    integer(kind=4) :: i

    if (size(perm) /= self%n .or. size(perm_inv) /= self%n) then
        error stop "perm_inverse: perm/perm_inv size mismatch with n"
    end if
    do i = 1, self%n
        perm_inv(perm(i)) = i
    end do
end subroutine perm_inverse

! Restore original ordering of RHS (undo perm permutation)
subroutine perm_rv(self, rhs, perm)
    class(SparsePakType), intent(inout) :: self
    real(kind=8), intent(inout) :: rhs(:)
    integer(kind=4), intent(inout) :: perm(:)
    real(kind=8) :: pull, put
    integer(kind=4) :: iput, istart

    if (size(rhs) /= self%n .or. size(perm) /= self%n) then
        error stop "perm_rv: rhs/perm size mismatch with n"
    end if

    ! Mark unprocessed permutations
    perm(1:self%n) = -perm(1:self%n)
    istart = 0

20  continue
    do
        istart = istart + 1
        if (self%n < istart) return
        if (0 < perm(istart)) cycle

        ! Single element cycle
        if (abs(perm(istart)) == istart) then
            perm(istart) = abs(perm(istart))
            cycle
        end if

        ! Process permutation cycle
        perm(istart) = abs(perm(istart))
        iput = istart
        pull = rhs(iput)
        do
            iput = abs(perm(iput))
            put = rhs(iput)
            rhs(iput) = pull
            pull = put
            if (0 < perm(iput)) go to 20
            perm(iput) = abs(perm(iput))
        end do
    end do
end subroutine perm_rv

! Print current timestamp
subroutine timestamp(self)
    class(SparsePakType), intent(in) :: self
    character(len=8) :: ampm
    integer(kind=4) :: d, h, m, mm, s, values(8), y
    character(len=9), parameter, dimension(12) :: month = [ &
        'January  ', 'February ', 'March    ', 'April    ', &
        'May      ', 'June     ', 'July     ', 'August   ', &
        'September', 'October  ', 'November ', 'December ' ]

    ! Get system time and date
    call date_and_time(values=values)
    y = values(1)
    m = values(2)
    d = values(3)
    h = values(5)
    m = values(6)
    s = values(7)
    mm = values(8)

    ! Convert to 12-hour format
    if (h < 12) then
        ampm = 'AM'
    else if (h == 12) then
        if (m == 0 .and. s == 0) then
            ampm = 'Noon'
        else
            ampm = 'PM'
        end if
    else
        h = h - 12
        if (h < 12) then
            ampm = 'PM'
        else if (h == 12) then
            if (m == 0 .and. s == 0) then
                ampm = 'Midnight'
            else
                ampm = 'AM'
            end if
        end if
    end if

    ! Print timestamp
    write(*, '(i2,1x,a,1x,i4,2x,i2,a1,i2.2,a1,i2.2,a1,i3.3,1x,a)' ) &
        d, trim(month(values(2))), y, h, ':', m, ':', s, '.', mm, trim(ampm)
end subroutine timestamp

!----------------------------------------------------------------------
! Auxiliary function: Convert integer to string
!----------------------------------------------------------------------
function str(i) result(s)
    integer(kind=4), intent(in) :: i
    character(len=20) :: s
    write(s, '(i20)') i
    s = adjustl(s)
end function str

end module SparsePakModule

