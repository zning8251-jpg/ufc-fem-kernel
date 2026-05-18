! LEGACY: External third-party library - exempt from UFC naming/style conventions
! COPYRIGHT (c) 2006 Council for the Central Laboratory
!                    of the Research Councils
! This package may be copied and used in any application, provided no
! changes are made to these or any other lines.
! Original date 21 February 2006. Version 1.0.0.
! 6 March 2007 Version 1.1.0. Argument stat made non-optional

MODULE HSL_ZD11_double

!  ==========================
!  Sparse matrix derived type
!  ==========================

  TYPE, PUBLIC :: ZD11_type
    INTEGER(i4) :: m, n, ne
    CHARACTER, ALLOCATABLE, DIMENSION(:) :: id, type
    INTEGER, ALLOCATABLE, DIMENSION(:) :: row, col, ptr
    REAL ( KIND( 1.0D+0 ) ), ALLOCATABLE, DIMENSION(:) :: val
  END TYPE

CONTAINS

   SUBROUTINE ZD11_put(array,string,stat)
     CHARACTER, allocatable :: array(:)
     CHARACTER(*), intent(in) ::  string
     INTEGER, intent(OUT) ::  stat

     INTEGER(i4) :: i,l

     l = len_trim(string)
     if (allocated(array)) then
        deallocate(array,stat=stat)
        if (stat/=0) return
     end if
     allocate(array(l),stat=stat)
     if (stat/=0) return
     do i = 1, l
       array(i) = string(i:i)
     end do

   END SUBROUTINE ZD11_put

   FUNCTION ZD11_get(array)
     CHARACTER, intent(in):: array(:)
     CHARACTER(size(array)) ::  ZD11_get
! Give the value of array to string.

     integer :: i
     do i = 1, size(array)
        ZD11_get(i:i) = array(i)
     end do

   END FUNCTION ZD11_get

END MODULE HSL_ZD11_double


! COPYRIGHT (c) 2007 Science & Technology Facilities Council
! Original date 1 August 2007. Version 1.0.0. (Sue Dollar)
!
! 1 Decemeber 2010 Version 2.0.0 (Jonathan Hogg)
!    Modify interface to allow specificaiton of source and destination ranges,
!    substantially rewrite and simplify code, add long integer support, remove
!    support for unallocated arrays on input

! To convert to single:
!    s/double/single
!    change myreal definition
! To convert to integer:
!    s/double/integer
!    s/real(myreal)/integer(myinteger)
!    s/REAL (kind=myreal)/INTEGER (kind=myinteger)
!    change myreal definintion to myinteger
! To convert to long integer:
!    s/double/long_integer
!    s/real(myreal)/integer(myinteger)
!    s/REAL (kind=myreal)/INTEGER (kind=myinteger)
!    change myreal definintion to myinteger
! To convert to double complex:
!    s/double/double_complex
!    s/COMPLEX (kind=mycomplex)/COMPLEX (kind=mycomplex)
!    s/complex(mycomplex)/complex(mycomplex)
!    change myreal definition to mycomplex
! To convert to complex:
!    s/double/complex
!    s/COMPLEX (kind=mycomplex)/COMPLEX (kind=mycomplex)
!    s/complex(mycomplex)/complex(mycomplex)
!    change myreal definition to mycomplex
MODULE hsl_zb01_double

   IMPLICIT NONE
   PRIVATE

   ! ---------------------------------------------------
   ! Precision
   ! ---------------------------------------------------

   INTEGER(i4), PARAMETER :: myreal = kind(1.0d0)
   INTEGER(i4), PARAMETER :: myint = kind(1)
   INTEGER(i4), PARAMETER :: long = selected_int_kind(18)

   ! ---------------------------------------------------
   ! Error flags
   ! ---------------------------------------------------
   INTEGER (kind=myint), PARAMETER :: &
      zb01_err_lw = -1, &        ! lw<=lkeep/size(w) on input
      zb01_err_lw_1 = -2, &      ! lw<1 on input
      zb01_err_lw_both = -3, &   ! both -1 and -2
      zb01_err_lkeep = -4, &     ! lkeep>size(w) on input
      zb01_err_lkeep_l = -5, &   ! lkeep<1
      zb01_err_lkeep_both = -6, &! both -4 and -5
      zb01_err_filename = -7, &  ! filename too long
      zb01_err_file_size = -8, & ! file_size <2**12
      zb01_err_filename_exists = -9, & ! filename already exists
      zb01_err_mode = -10, &     ! mode out of range
      zb01_err_memory_alloc = -11, & ! memory alloc error
      zb01_err_memory_dealloc = -12, & ! memory dealloc error
      zb01_err_inquire = -13, &  ! error in Fortran inquire statement
      zb01_err_open = -14, &     ! error in Fortran open statement
      zb01_err_read = -15, &     ! error in Fortran read statement
      zb01_err_write = -16, &    ! error in Fortran write statement
      zb01_err_close = -17, &    ! error in Fortran close statement
      zb01_err_src_dest = -18, & ! src and dest sizes do not match
      zb01_err_w_unalloc = -19   ! w is unallocated on entry

   ! ---------------------------------------------------
   ! Warning flags
   ! ---------------------------------------------------
   INTEGER (kind=myint), PARAMETER :: &
      zb01_warn_lw = 1 ! size_out changed

   ! ---------------------------------------------------
   ! Derived type definitions
   ! ---------------------------------------------------

   TYPE, PUBLIC :: zb01_info
      INTEGER(i4) :: flag = 0        ! error/warning flag
      INTEGER(i4) :: iostat = 0      ! holds Fortran iostat parameter
      INTEGER(i4) :: stat = 0        ! holds Fortran stat parameter
      INTEGER(i4) :: files_used = 0  ! unit number scratch file written to
   END TYPE zb01_info

   INTERFACE zb01_resize1
      MODULE PROCEDURE zb01_resize1_double
   END INTERFACE

   INTERFACE zb01_resize2
      MODULE PROCEDURE zb01_resize2_double
   END INTERFACE

   PUBLIC zb01_resize1, zb01_resize2

CONTAINS

SUBROUTINE zb01_resize1_double(w,size_in,size_out,info,src,dest,filename, &
      file_size,mode)

  ! --------------------------------------
  ! Expands w to have larger size and copies all or part of the
  ! original array into the new array
  ! --------------------------------------

  ! w: is a REAL allocatable array of INTENT(INOUT). Must be allocated on entry.
  REAL (kind=myreal), DIMENSION (:), ALLOCATABLE, INTENT (INOUT) :: w

  ! size_in: is an INTEGER OF INTENT(IN). It holds the extent of w on entry.
  INTEGER (kind=long), INTENT(IN) :: size_in

  ! size_out: is an INTEGER of INTENT(INOUT). It holds the required size of w
  ! on input and the actual size of w on output
  INTEGER (kind=long), INTENT (INOUT) :: size_out

  ! info: is of derived type ZB01_info with intent(out).
  ! info%flag = ZB01_ERR_LW if 1<=size_out<=lkeep/size(w) on input
  ! ZB01_ERR_LW_L if size_out<=0
  ! ZB01_ERR_LKEEP if lkeep>size(w) on input
  ! ZB01_ERR_LKEEP_L if lkeep<1 on input
  ! ZB01_ERR_FILENAME if filename too long
  ! ZB01_ERR_FILE_SIZE if file_size <2**12
  ! ZB01_ERR_FILENAME_EXISTS if filename already exists
  ! ZB01_ERR_MODE if mode out of range
  ! ZB01_ERR_MEMORY_ALLOC if memory alloc error
  ! ZB01_ERR_MEMORY_DEALLOC if memory dealloc error
  ! ZB01_ERR_INQUIRE if error in Fortran inquire statement
  ! ZB01_ERR_OPEN if error in Fortran open statement
  ! ZB01_ERR_READ if error in Fortran read statement
  ! ZB01_ERR_WRITE if error in Fortran write statement
  ! ZB01_ERR_CLOSE if error in Fortran close statement
  ! ZB01_WARN_LW if size_out changed by subroutine
  ! ZB01_WARN_W if w not allocated on input
  ! info%iostat holds Fortran iostat parameter
  ! info%stat holds Fortran stat parameter
  ! info%unit holds unit number scratch file written to (negative if
  ! not)
  TYPE (zb01_info), INTENT (OUT) :: info

  ! src and dest: are OPTIONAL INTEGER arrays of INTENT(IN). They specify
  ! the source and destination ranges for any values to be kept.
  ! dest(2)-dest(1) must equal src(2)-src(1) and minval(src,dest)>0.
  INTEGER (kind=long), DIMENSION(2), INTENT (IN), OPTIONAL :: src
  INTEGER (kind=long), DIMENSION(2), INTENT (IN), OPTIONAL :: dest

  ! filename: is an OPTIONAL STRING OF CHARACTERS of INTENT(IN).
  ! It holds the name of the file to be used
  CHARACTER (len=*), INTENT (IN), OPTIONAL :: filename

  ! file_size: is an OPTIONAL INTEGER of INTENT(IN). It holds the length
  ! of
  ! of the files to be used if necessary
  INTEGER (kind=long), INTENT (IN), OPTIONAL :: file_size

  ! mode: is an OPTIONAL INTEGER of INTENT(IN). If mode==0, then the
  ! subroutine will firstly try to use a temporary array. If mode==1,
  ! then
  ! the subroutine will immediately use temporary files
  INTEGER, INTENT (IN), OPTIONAL :: mode

  ! --------------------------------------
  ! Local variables
  ! --------------------------------------

  ! wtemp: is a REAL allocatable array
  REAL (kind=myreal), DIMENSION (:), ALLOCATABLE :: wtemp

  ! length to use for wtemp
  INTEGER(i4) :: lwtemp

  ! Fortran stat parameter
  INTEGER(i4) :: stat

  INTEGER(i4) :: number_files, mode_copy
  INTEGER (kind=long) :: file_size_copy
  INTEGER, DIMENSION (:), ALLOCATABLE :: units
  integer (kind=long), dimension(2,2) :: src_copy, dest_copy

  ! --------------------------------------
  ! Check input for errors
  ! --------------------------------------

  info%flag = 0

  ! Check w is allocated
  if(.not.allocated(w)) then
    info%flag = zb01_err_w_unalloc
    return
  endif

  ! Setup src_copy and dest_copy
  src_copy(1,1) = 1
  src_copy(2,1) = size_in
  src_copy(1,2) = 1
  src_copy(2,2) = 1
  if(present(src)) then
    src_copy(:,1) = src(:)
  elseif(present(dest)) then
    src_copy(:,1) = dest(:)
  endif
  dest_copy(:,:) = src_copy(:,:)
  if(present(dest)) then
    dest_copy(:,1) = dest(:)
  endif

  if(minval(src_copy).lt.0 .or. minval(dest_copy).lt.0) &
    info%flag = zb01_err_lkeep_l

  if(maxval(src_copy) .gt. size_in) then
    if(info%flag.eq.zb01_err_lkeep_l) then
      info%flag = zb01_err_lkeep_both
    else
      info%flag = zb01_err_lkeep
    endif
  endif
  if(info%flag.lt.0) return
  
  if(any(src_copy(2,:)-src_copy(1,:) .ne. &
      dest_copy(2,:)-dest_copy(1,:))) then
    info%flag = zb01_err_src_dest
    return
  endif

  if(size_out.lt.1) then
    info%flag = zb01_err_lw_1
    return
  endif
  if(maxval(dest_copy).gt.size_out) then
    info%flag = zb01_err_lw
    return
  endif

  IF (present(filename)) THEN
    IF (len(filename)>400) THEN
      ! Error: len(filename) > 400
      info%flag = zb01_err_filename
      RETURN
    END IF
  END IF


  file_size_copy = 2**22_long
  if (present(file_size)) file_size_copy = file_size

  IF (file_size_copy<2**12) THEN
    ! Error: filesize < 2**12
    info%flag = zb01_err_file_size
    RETURN
  END IF

  mode_copy = 0
  if(present(mode)) mode_copy = mode
  IF (mode_copy<0 .OR. mode_copy>1) THEN
    ! Error: filesize < 2**12
    info%flag = zb01_err_mode
    RETURN
  END IF

  IF (src_copy(2,1)-src_copy(1,1)+1.le.0) THEN

    ! --------------------------------------
    ! No entries need to be copied
    ! --------------------------------------

    ! --------------------------------------
    ! Check whether expansion is required
    ! --------------------------------------
    IF (size_out==size_in) RETURN

    ! --------------------------------------
    ! Deallocate w
    ! --------------------------------------
    DEALLOCATE (w,STAT=info%stat)
    IF (info%stat>0) THEN
      info%flag = zb01_err_memory_dealloc
      RETURN
    END IF

    ! --------------------------------------
    ! Reallocate w
    ! --------------------------------------
    ALLOCATE (w(size_out),STAT=info%stat)
    IF (info%stat>0) THEN
      ! --------------------------------------
      ! Allocation of w failed
      ! --------------------------------------
      info%flag = zb01_err_memory_alloc
      RETURN
    END IF

  ELSE

    ! --------------------------------------
    ! entries need to be copied
    ! --------------------------------------


    ! --------------------------------------
    ! Check whether expansion is required
    ! --------------------------------------
    IF (size_out==size_in .and. all(src_copy(:,:).eq.dest_copy(:,:))) RETURN

    ! --------------------------------------
    ! Attempt to allocate temporary array
    ! --------------------------------------
    stat = 0
    ! Length of temporary array
    lwtemp = src_copy(2,1) - src_copy(1,1) + 1

    ! Allocate temporary array
    IF (mode_copy==0) ALLOCATE (wtemp(lwtemp),STAT=stat)

    IF (stat==0 .AND. mode_copy==0) THEN
      ! --------------------------------------
      ! Allocation successful
      ! --------------------------------------

      ! --------------------------------------
      ! Copy entries into wtemp
      ! --------------------------------------
      wtemp(1:lwtemp) = w(src_copy(1,1):src_copy(2,1))
      !print *, "copy w to wtemp"

      ! --------------------------------------
      ! Deallocate w
      ! --------------------------------------
      DEALLOCATE (w,STAT=info%stat)
      IF (info%stat>0) THEN
        info%flag = zb01_err_memory_dealloc
        RETURN
      END IF

      ! --------------------------------------
      ! Reallocate w
      ! --------------------------------------
      ALLOCATE (w(size_out),STAT=stat)
      IF (stat>0) THEN
        !print *, "fail alloc of w, copy wtemp to file", src_copy, size_out


        ! --------------------------------------
        ! Allocation not successful
        ! --------------------------------------
        call write_to_file(wtemp, size_in, src_copy, &
          units, number_files, file_size_copy, info, filename)
        if(info%flag.lt.0) return

        ! --------------------------------------
        ! Deallocate wtemp
        ! --------------------------------------
        DEALLOCATE (wtemp,STAT=info%stat)
        IF (info%stat>0) THEN
          info%flag = zb01_err_memory_dealloc
          RETURN
        END IF

        ! --------------------------------------
        ! Reallocate w
        ! --------------------------------------
        ALLOCATE (w(size_out),STAT=info%stat)
        IF (info%stat>0) THEN
          !print *, "still can't alloc w. give up (try and preserve)."
          ! --------------------------------------
          ! Allocation of w to desired size failed
          ! Try size=lwtemp
          ! --------------------------------------


          ALLOCATE (w(lwtemp),STAT=info%stat)
          IF (info%stat==0) THEN
            ! --------------------------------------
            ! Reassign lw
            ! --------------------------------------
            size_out = lwtemp
            info%flag = zb01_warn_lw

          ELSE
            !print *, "can't even do that!"

            ! --------------------------------------
            ! Allocation of w still failed - delete files
            ! --------------------------------------
            call delete_files(units, number_files, info, filename)
            if(info%flag.lt.0) return

            info%flag = zb01_err_memory_alloc
            RETURN
          END IF
        END IF

        !print *, "restore entries to w"
        ! --------------------------------------
        ! Copy entries back into w
        ! --------------------------------------
        call read_from_file(w, size_in, dest_copy, units, &
          number_files, file_size_copy, info, filename)

        RETURN
      END IF

      !print *, "copy wtemp back to w"
      ! --------------------------------------
      ! Copy entries
      ! --------------------------------------
      w(dest_copy(1,1):dest_copy(2,1)) = wtemp(1:lwtemp)

      ! --------------------------------------
      ! Deallocate wtemp
      ! --------------------------------------
      DEALLOCATE (wtemp,STAT=info%stat)
      IF (info%stat>0) THEN
        info%flag = zb01_err_memory_dealloc
        RETURN
      END IF
      RETURN

    ELSE
      !print *, "can't alloc wtemp, stow direct in file"
      ! --------------------------------------
      ! Allocation not successful
      ! --------------------------------------
      call write_to_file(w, size_in, src_copy, units, &
        number_files, file_size_copy, info, filename)
      if(info%flag.lt.0) return

      ! --------------------------------------
      ! Deallocate w
      ! --------------------------------------
      DEALLOCATE (w,STAT=info%stat)
      IF (info%stat>0) THEN
        info%flag = zb01_err_memory_dealloc
        RETURN
      END IF

      ! --------------------------------------
      ! Reallocate w
      ! --------------------------------------
      ALLOCATE (w(size_out),STAT=info%stat)
      IF (info%stat>0) THEN
        !print *, "can't alloc w"
        ! --------------------------------------
        ! Allocation of w to desired size failed
        ! Try size=lwtemp
        ! --------------------------------------

        ALLOCATE (w(lwtemp),STAT=info%stat)
        IF (info%stat==0) THEN
          ! --------------------------------------
          ! Reassign lw
          ! --------------------------------------
          size_out = lwtemp
          info%flag = zb01_warn_lw

        ELSE
          ! --------------------------------------
          ! Allocation of w failed again - delete files
          ! --------------------------------------
          call delete_files(units, number_files, info, filename)
          if(info%flag.lt.0) return

          info%flag = zb01_err_memory_alloc
          RETURN
        END IF
      END IF

      !print *, "restore values from file"
      call read_from_file(w, size_in, dest_copy, units, &
        number_files, file_size_copy, info, filename)

    END IF
  END IF

END SUBROUTINE zb01_resize1_double

! ---------------------------------------------------------------

SUBROUTINE zb01_resize2_double(w,size_in,size_out,info,src,dest,filename, &
      file_size,mode)

  ! --------------------------------------
  ! Expands w to have larger size and copies all or part of the
  ! original array into the new array
  ! --------------------------------------

  ! w: is a REAL allocatable array of INTENT(INOUT). Must be allocated on entry.
  REAL (kind=myreal), DIMENSION (:,:), ALLOCATABLE, INTENT (INOUT) :: w

  ! size_in: is an INTEGER array INTENT(IN). It holds the extent of w on entry.
  INTEGER (kind=long), INTENT(IN) :: size_in(2)

  ! size_out: is an INTEGER array of rank-one with size 2 and of
  ! INTENT(INOUT).
  ! On input, size_out(1) holds the required number of rows of w and size_out(2)
  ! holds
  ! the required number of columns of w. On successful output it
  ! contains
  ! the number of rows and columns that w has.
  INTEGER (kind=long), INTENT (INOUT) :: size_out(2)

  ! info: is of derived type ZB01_info with intent(out).
  ! info%flag = ZB01_ERR_LW if 1<=size_out<=lkeep/size(w) on input
  ! ZB01_ERR_LW_L if size_out<=0
  ! ZB01_ERR_LKEEP if lkeep>size(w) on input
  ! ZB01_ERR_LKEEP_L if lkeep<1 on input
  ! ZB01_ERR_FILENAME if filename too long
  ! ZB01_ERR_FILE_SIZE if file_size <2**12
  ! ZB01_ERR_FILENAME_EXISTS if filename already exists
  ! ZB01_ERR_MODE if mode out of range
  ! ZB01_ERR_MEMORY_ALLOC if memory alloc error
  ! ZB01_ERR_MEMORY_DEALLOC if memory dealloc error
  ! ZB01_ERR_INQUIRE if error in Fortran inquire statement
  ! ZB01_ERR_OPEN if error in Fortran open statement
  ! ZB01_ERR_READ if error in Fortran read statement
  ! ZB01_ERR_WRITE if error in Fortran write statement
  ! ZB01_ERR_CLOSE if error in Fortran close statement
  ! ZB01_WARN_LW if size_out changed by subroutine
  ! ZB01_WARN_W if w not allocated on input
  ! info%iostat holds Fortran iostat parameter
  ! info%stat holds Fortran stat parameter
  ! info%files_used holds unit number of files written to
  TYPE (zb01_info), INTENT (OUT) :: info

  ! src and dest: are OPTIONAL INTEGER arrays of INTENT(IN). They specify
  ! the source and destination ranges for any values to be kept.
  ! dest(2,:)-dest(1,:) must equal src(2,:)-src(1,:) and must be
  ! non-negative.
  INTEGER (kind=long), DIMENSION(2,2), INTENT (IN), OPTIONAL :: src
  INTEGER (kind=long), DIMENSION(2,2), INTENT (IN), OPTIONAL :: dest

  ! filename: is an OPTIONAL STRING OF CHARACTERS of INTENT(IN).
  ! It holds the name of the file to be used
  CHARACTER (len=*), INTENT (IN), OPTIONAL :: filename


  ! file_size: is an OPTIONAL INTEGER of INTENT(IN). It holds the length
  ! of the files to be used if necessary
  INTEGER (kind=long), INTENT (IN), OPTIONAL :: file_size

  ! mode: is an OPTIONAL INTEGER of INTENT(IN). If mode==0, then the
  ! subroutine will firstly try to use a temporary array. If mode==1,
  ! then the subroutine will immediately use temporary files
  INTEGER, INTENT (IN), OPTIONAL :: mode


  ! --------------------------------------
  ! Local variables
  ! --------------------------------------

  ! wtemp: is a REAL allocatable array
  REAL (kind=myreal), DIMENSION (:,:), ALLOCATABLE :: wtemp

  ! lengths to use for wtemp
  INTEGER(i4) :: lwtemp1, lwtemp2

  ! Fortran stat parameter
  INTEGER(i4) :: stat

  INTEGER(i4) :: number_files, mode_copy
  INTEGER (kind=long) :: file_size_copy
  INTEGER, DIMENSION (:), ALLOCATABLE :: units

  integer(long), dimension(2,2) :: src_copy, dest_copy

  info%flag = 0

  ! --------------------------------------
  ! Check input for errors
  ! --------------------------------------

  ! Check w is allocated
  if(.not.allocated(w)) then
    info%flag = zb01_err_w_unalloc
    return
  endif

  src_copy(1,1) = 1
  src_copy(2,1) = size_in(1)
  src_copy(1,2) = 1
  src_copy(2,2) = size_in(2)
  if(present(src)) then
    src_copy(:,:) = src(:,:)
  elseif(present(dest)) then
    src_copy(:,:) = dest(:,:)
  endif
  dest_copy(:,:) = src_copy(:,:)
  if(present(dest)) dest_copy(:,:) = dest(:,:)

  if(minval(src_copy).lt.0 .or. minval(dest_copy).lt.0) &
    info%flag = zb01_err_lkeep_l

  if(maxval(src_copy(:,1)).gt.size_in(1) .or. &
      maxval(src_copy(:,2)).gt.size_in(2)) then
    if(info%flag.eq.zb01_err_lkeep_l) then
      info%flag = zb01_err_lkeep_both
    else
      info%flag = zb01_err_lkeep
    endif
  endif
  if(info%flag.lt.0) return

  ! Note: be careful to only return one error for each dimension
  ! (combination of flags possible if dimensions are differently wrong)
  ! this is to match v1.0.0 behaviour
  if(minval(size_out).lt.1) info%flag = zb01_err_lw_1
  if((maxval(dest_copy(:,1)).gt.size_out(1) .and. size_out(1).ge.1) .or. &
     (maxval(dest_copy(:,2)).gt.size_out(2) .and. size_out(2).ge.1)) then
    if(info%flag.eq.zb01_err_lw_1) then
      info%flag = zb01_err_lw_both
    else
      info%flag = zb01_err_lw
    endif
  endif
  if(info%flag.lt.0) return
  
  if(any(src_copy(2,:)-src_copy(1,:) .ne. &
      dest_copy(2,:)-dest_copy(1,:))) then
    info%flag = zb01_err_src_dest
    return
  endif

  IF (present(filename)) THEN
    IF (len(filename)>400) THEN
      ! Error: len(filename) > 400
      info%flag = zb01_err_filename
      RETURN
    END IF
  END IF

  file_size_copy = 2**22_long
  if (present(file_size)) file_size_copy = file_size
  IF (file_size_copy<2**12) THEN
    ! Error: filesize < 2**12
    info%flag = zb01_err_file_size
    RETURN
  END IF

  mode_copy = 0
  if(present(mode)) mode_copy = mode
  IF (mode_copy<0 .OR. mode_copy>1) THEN
    ! Error: mode out of range
    info%flag = zb01_err_mode
    RETURN
  END IF

  IF (any(src_copy(2,:)-src_copy(1,:)+1.le.0)) THEN

    ! --------------------------------------
    ! No entries need to be copied
    ! --------------------------------------

    ! --------------------------------------
    ! Check whether expansion is required
    ! --------------------------------------
    IF (size_out(1)==size_in(1) .AND. size_out(2)==size_in(2)) RETURN

    ! --------------------------------------
    ! Deallocate w
    ! --------------------------------------
    DEALLOCATE (w,STAT=info%stat)
    IF (info%stat>0) THEN
      info%flag = zb01_err_memory_dealloc
      RETURN
    END IF

    ! --------------------------------------
    ! Reallocate w
    ! --------------------------------------
    ALLOCATE (w(size_out(1),size_out(2)),STAT=info%stat)
    IF (info%stat>0) THEN
      ! --------------------------------------
      ! Allocation of w failed
      ! --------------------------------------
      info%flag = zb01_err_memory_alloc
      RETURN
    END IF

  ELSE

    ! --------------------------------------
    ! Entries need to be copied
    ! --------------------------------------


    ! --------------------------------------
    ! Check whether expansion is required
    ! --------------------------------------
    IF (size_out(1)==size_in(1) .AND. size_out(2)==size_in(2) .and. &
         all(src_copy(:,:).eq.dest_copy(:,:))) RETURN

    ! --------------------------------------
    ! Attempt to allocate temporary array
    ! --------------------------------------
    stat = 0
    ! Size of temporary array
    lwtemp1 = src_copy(2,1) - src_copy(1,1) + 1
    lwtemp2 = src_copy(2,2) - src_copy(1,2) + 1

    ! Allocate temporary array
    IF (mode_copy==0) ALLOCATE (wtemp(lwtemp1,lwtemp2),STAT=stat)
    IF (stat==0 .AND. mode_copy==0) THEN
      ! --------------------------------------
      ! Allocation of temporary array successful
      ! --------------------------------------

      ! --------------------------------------
      ! Copy entries into wtemp
      ! --------------------------------------
      !print *, "copy to wtemp"
      wtemp(1:lwtemp1, 1:lwtemp2) = &
        w(src_copy(1,1):src_copy(2,1), src_copy(1,2):src_copy(2,2))

      ! --------------------------------------
      ! Deallocate w
      ! --------------------------------------
      DEALLOCATE (w,STAT=info%stat)
      IF (info%stat>0) THEN
        info%flag = zb01_err_memory_dealloc
        RETURN
      END IF

      ! --------------------------------------
      ! Reallocate w
      ! --------------------------------------
      ALLOCATE (w(size_out(1),size_out(2)),STAT=info%stat)
      IF (info%stat>0) THEN
        ! --------------------------------------
        ! Allocation of w not successful so copy temp into files
        ! --------------------------------------
        !print *, "copy wtemp to file"
        call write_to_file(wtemp, lwtemp1+0_long, src_copy, &
          units, number_files, file_size_copy, info, filename)
        if(info%flag.lt.0) return


        ! --------------------------------------
        ! Deallocate wtemp
        ! --------------------------------------
        DEALLOCATE (wtemp,STAT=info%stat)
        IF (info%stat>0) THEN
          info%flag = zb01_err_memory_dealloc
          RETURN
        END IF

        ! --------------------------------------
        ! Reallocate w
        ! --------------------------------------
        ALLOCATE (w(size_out(1),size_out(2)),STAT=info%stat)
        IF (info%stat>0) THEN
          ! --------------------------------------
          ! Allocation of w to desired size failed
          ! Try size=lwtemp
          ! --------------------------------------

          ALLOCATE (w(lwtemp1,lwtemp2),STAT=info%stat)
          IF (info%stat==0) THEN
            ! --------------------------------------
            ! Reassign size_out
            ! --------------------------------------
            size_out(1) = lwtemp1
            size_out(2) = lwtemp2
            info%flag = zb01_warn_lw

          ELSE
            ! Delete files
            call delete_files(units, number_files, info, filename)
            if(info%flag.lt.0) return

            info%flag = zb01_err_memory_alloc
            RETURN
          END IF
        END IF

        !print *, "restore from file1"
        call read_from_file(w, size_in(1), dest_copy, &
          units, number_files, file_size_copy, info, filename)

        RETURN

      END IF

      ! --------------------------------------
      ! Copy entries
      ! --------------------------------------
      w(dest_copy(1,1):dest_copy(2,1), dest_copy(1,2):dest_copy(2,2)) =&
        wtemp(1:lwtemp1, 1:lwtemp2)

      ! --------------------------------------
      ! Deallocate wtemp
      ! --------------------------------------
      DEALLOCATE (wtemp,STAT=info%stat)
      IF (info%stat>0) THEN
        info%flag = zb01_err_memory_dealloc
        RETURN
      END IF

      RETURN

    ELSE
      ! --------------------------------------
      ! Allocation of temporary array not successful or mode = 1
      ! --------------------------------------
      call write_to_file(w, size_in(1), src_copy, &
        units, number_files, file_size_copy, info, filename)
      if(info%flag.lt.0) return

      ! --------------------------------------
      ! Deallocate w
      ! --------------------------------------
      DEALLOCATE (w,STAT=info%stat)
      IF (info%stat>0) THEN
        info%flag = zb01_err_memory_dealloc
        RETURN
      END IF

      ! --------------------------------------
      ! Reallocate w
      ! --------------------------------------
      ALLOCATE (w(size_out(1),size_out(2)),STAT=info%stat)
      IF (info%stat>0) THEN
        ! --------------------------------------
        ! Allocation of w to desired size failed
        ! Try size=lwtemp
        ! --------------------------------------

        ALLOCATE (w(lwtemp1,lwtemp2),STAT=info%stat)
        IF (info%stat==0) THEN
          ! --------------------------------------
          ! Reassign lw
          ! --------------------------------------
          size_out(1) = lwtemp1
          size_out(2) = lwtemp2
          info%flag = zb01_warn_lw

        ELSE
          ! --------------------------------------
          ! Allocation of w fialed - Delete files
          ! --------------------------------------
          call delete_files(units, number_files, info, filename)
          if(info%flag.lt.0) return

          info%flag = zb01_err_memory_alloc
          RETURN
        END IF
      END IF

      call read_from_file(w, size_out(1), dest_copy, &
        units, number_files, file_size_copy, info, filename)


    END IF

  END IF

END SUBROUTINE zb01_resize2_double

subroutine write_to_file(w, ldw, src, units, number_files, &
      file_size_copy, info, filename)
  integer(long), intent(in) :: ldw ! leading edge of array w
  real(myreal), dimension(ldw, *), intent(in) :: w
  integer(long), dimension(2,2), intent(in) :: src
  integer, dimension(:), allocatable, intent(out) :: units
  integer, intent(out) :: number_files
  integer(long), intent(in) :: file_size_copy
  type(ZB01_info), intent(inout) :: info
  character(len=*), optional, intent(in) :: filename

  integer :: iolen
  CHARACTER (402) :: filename_no
  integer(long) :: ncol
  integer(long) :: nrow
  integer(long) :: total_size
  integer :: i, u
  CHARACTER (10) :: ci        ! Filename extension
  logical :: ex
  integer(long) :: idx1       ! first index into w
  integer(long) :: idx2       ! second index into w
  integer(long) :: written    ! number of bytes written to current file
  integer(long) :: len        ! length to write to file

  !print *, "write to file ", src(:,1), ",", src(:,2)

  ! --------------------------------------
  ! Work out number of files required
  ! --------------------------------------
  INQUIRE (iolength=iolen) w(1,1)
  nrow = src(2,1) - src(1,1)
  ncol = src(2,2) - src(1,2)
  total_size = nrow*ncol*iolen

  number_files = (total_size-1)/file_size_copy + 1
  info%files_used = number_files

  ! --------------------------------------
  ! Check files do not exist
  ! --------------------------------------
  IF (present(filename)) THEN
    DO i = 1, number_files
      IF (number_files/=1) THEN
        WRITE (ci,'(i5)') i
        filename_no = trim(filename) // adjustl(ci)
      ELSE
        filename_no = trim(filename)
      END IF
      INQUIRE (file=trim(filename_no),exist=ex, iostat=info%iostat)
      IF (info%iostat/=0) THEN
          info%flag = zb01_err_inquire
        return
      ELSE IF (ex) THEN
        info%flag = zb01_err_filename_exists
        return
      END IF
    END DO
  END IF


  ! --------------------------------------
  ! Allocate array for holding unit numbers
  ! --------------------------------------
  i = number_files
  IF (present(filename)) i = 1
  ALLOCATE (units(i),STAT=info%stat)
  IF (info%stat>0) THEN
    info%flag = zb01_err_memory_alloc
    return
  END IF

  ! --------------------------------------
  ! Find unit numbers
  ! --------------------------------------
  call find_units(units, info%iostat)
  if(info%iostat.ne.0) return

  ! --------------------------------------
  ! Open temporary files
  ! --------------------------------------

  IF (present(filename)) THEN
    DO i = 1, number_files
      IF (number_files/=1) THEN
        WRITE (ci,'(i5)') i
        filename_no = trim(filename) // adjustl(ci)
      ELSE
        filename_no = trim(filename)
      END IF
      u = units(1)
      OPEN (unit=u,file=trim(filename_no),iostat=info%iostat, &
        err=70,status='new',recl=file_size_copy,form='unformatted', &
        action='readwrite')
      CLOSE (unit=u,iostat=info%iostat,err=80,status='keep')
    END DO
  ELSE
    DO i = 1, number_files
      ! write(6,*) 'unit=',units(i)
      u = units(i)
      OPEN (unit=u,iostat=info%iostat,err=70,status='scratch', &
        recl=file_size_copy,form='unformatted',action='readwrite')
    END DO
  END IF

  ! --------------------------------------
  ! Copy entries
  ! --------------------------------------

  idx1 = src(1,1)
  idx2 = src(1,2)
  written = 0
  files: do i = 1, number_files
    if(present(filename)) then
      IF (number_files/=1) THEN
        WRITE (ci,'(i5)') i
        filename_no = trim(filename) // adjustl(ci)
      ELSE
        filename_no = trim(filename)
      END IF
      u = units(1)
      OPEN (unit=u,file=trim(filename_no), &
        iostat=info%iostat,err=70,status='old',recl=file_size_copy, &
        form='unformatted',action='readwrite', &
        position='rewind')
    else
      u = units(i)
    endif
    do while(file_size_copy - written .gt. 0)
       len = src(2,1) - idx1 + 1 ! amount to reach end of current column
       len = min(len, (file_size_copy-written)/iolen) ! limit to file size
       WRITE (unit=u,iostat=info%iostat,err=90) w(idx1:idx1+len-1,idx2)
       written = written + len*iolen
       idx1 = idx1 + len
       if(idx1.gt.src(2,1)) then
          idx1 = src(1,1)
          idx2 = idx2 + 1
          if(idx2.gt.src(2,2)) then
            if(present(filename)) &
              CLOSE (unit=u,iostat=info%iostat,err=80,status='keep')
            exit files
          endif
       endif
    end do
    if(present(filename)) &
      CLOSE (unit=u,iostat=info%iostat,err=80,status='keep')
  end do files

  return

  70 info%flag = zb01_err_open
  RETURN

  80 info%flag = zb01_err_close
  RETURN

  90 info%flag = zb01_err_write
  RETURN
end subroutine write_to_file

!
! This subroutine fills the array units with available unit numbers
! on which files can be opened
!
subroutine find_units(units, iost)
   integer, dimension(:), intent(out) :: units
   integer, intent(inout) :: iost

   integer :: i ! element of units we need to find
   integer :: u ! current unit to try
   logical :: ex ! .true. if unit exists
   logical :: open ! .true. if unit is not open

   iost = 0 ! initialise in case we do no loop iterations

   u = 8 ! unit to start with
   DO i = 1, size(units)
     DO u = u, huge(0)
       IF (u==100 .OR. u==101 .OR. u==102) CYCLE
       INQUIRE (unit=u,iostat=iost,exist=ex, opened=open)
       if(iost.ne.0) return
       IF (ex .AND. .NOT. open) THEN
         units(i) = u
         EXIT
       END IF
     END DO
     u = units(i) + 1
   END DO
end subroutine find_units

subroutine read_from_file(w, ldw, dest, units, number_files, &
      file_size_copy, info, filename)
  integer(long), intent(in) :: ldw
  real(myreal), dimension(ldw,*), intent(out) :: w
  integer(long), dimension(2,2), intent(in) :: dest
  integer, dimension(:), intent(in) :: units
  integer, intent(in) :: number_files
  integer(long), intent(in) :: file_size_copy
  type(ZB01_info), intent(inout) :: info
  character(len=*), optional, intent(in) :: filename

  integer :: iolen            ! io length of a single element of w
  CHARACTER (402) :: filename_no
  character (10) :: ci
  integer :: i                ! current file
  integer :: u                ! current unit
  integer(long) :: idx1       ! first index into w
  integer(long) :: idx2       ! second index into w
  integer(long) :: done       ! number of bytes read from current file
  integer(long) :: len        ! length to read from file

  !print *, "read from file ", dest(:,1), ",", dest(:,2)

  INQUIRE (iolength=iolen) w(1,1)

  idx1 = dest(1,1)
  idx2 = dest(1,2)
  done = 0
  files: do i = 1, number_files
    if(present(filename)) then
      IF (number_files/=1) THEN
        WRITE (ci,'(i5)') i
        filename_no = trim(filename) // adjustl(ci)
      ELSE
        filename_no = trim(filename)
      END IF
      u = units(1)
      OPEN (unit=u,file=trim(filename_no), &
        iostat=info%iostat,err=70,status='old',recl=file_size_copy, &
        form='unformatted',action='readwrite', &
        position='rewind')
    else
      u = units(i)
      rewind(u)
    endif
    do while(file_size_copy - done .gt. 0)
       len = dest(2,1) - idx1 + 1 ! amount to reach end of current column
       len = min(len, (file_size_copy-done)/iolen) ! limit to file size
       READ (unit=u,iostat=info%iostat,err=90) w(idx1:idx1+len-1,idx2)
       done = done + len*iolen
       idx1 = idx1 + len
       if(idx1.gt.dest(2,1)) then
          idx1 = dest(1,1)
          idx2 = idx2 + 1
          if(idx2.gt.dest(2,2)) then
            if(present(filename)) &
              CLOSE (unit=u,iostat=info%iostat,err=80,status='delete')
            exit files
          endif
       endif
    end do
    CLOSE (unit=u,iostat=info%iostat,err=80,status='delete')
  end do files

  return

  70 info%flag = zb01_err_open
  RETURN

  80 info%flag = zb01_err_close
  RETURN

  90 info%flag = zb01_err_read
  RETURN
end subroutine read_from_file

subroutine delete_files(units, number_files, info, filename)
  integer, dimension(:), intent(in) :: units
  integer, intent(in) :: number_files
  type(ZB01_info), intent(inout) :: info
  character(len=*), optional, intent(in) :: filename

  character(402) :: filename_no
  character(10) :: ci
  integer :: i, u

  IF (present(filename)) THEN
    do i = 1, number_files
      IF (number_files/=1) THEN
        WRITE (ci,'(i5)') i
        filename_no = trim(filename) // adjustl(ci)
      ELSE
        filename_no = trim(filename)
      END IF
      u = units(1)
      OPEN (unit=u,file=trim(filename_no), &
        iostat=info%iostat,err=70,status='old', &
        form='unformatted',action='readwrite')
      CLOSE (unit=u,iostat=info%iostat,err=80, &
        status='delete')
    END DO
  ELSE
    DO i = 1, number_files
      u = units(i)
      CLOSE (unit=u,iostat=info%iostat,err=80, &
        status='delete')
    END DO
  END IF

  RETURN

  70 info%flag = zb01_err_open
  RETURN

  80 info%flag = zb01_err_close
  RETURN

end subroutine delete_files

END MODULE hsl_zb01_double
! COPYRIGHT (c) 2001,2014 Science and Technology Facilities Council (STFC)
!
! Version 2.3.0
! See ChangeLog for version history.
!
 module HSL_MC65_double

  use hsl_zd11_double
  implicit none
  private

  INTEGER(i4), PARAMETER :: myreal = KIND( 1.0D0 )
  INTEGER(i4), PARAMETER :: myint = KIND( 1)

  integer (kind = myint), public, parameter :: &
       MC65_ERR_MEMORY_ALLOC = -1, &  ! memory alloc failure
       MC65_ERR_MEMORY_DEALLOC = -2, & ! memory deallocate failure
       ! dimension mismatch in matrix_sum
       MC65_ERR_SUM_DIM_MISMATCH = -3,&
       ! dimension mismatch in matrix_multiply
       MC65_ERR_MATMUL_DIM_MISMATCH = -4, &
       ! dimension mismatch in matrix_multiply_graph
       MC65_ERR_MATMULG_DIM_MISMATCH = -5, &
       ! y = Ax with A pattern only and x real.
       MC65_ERR_MATVEC_NOVALUE = -6, &
       ! no vacant unit has been found MC65_MATRIX_WRITE
       MC65_ERR_NO_VACANT_UNIT = -7,&
       ! if in MC65_MATRIX_READ, the file <file_name> does not exist.
       MC65_ERR_READ_FILE_MISS = -8,&
       ! if in MC65_MATRIX_READ, opening of
       ! the file <file_name> returns iostat /= 0
       MC65_ERR_READ_OPEN = -9, &
       ! in MC65_matrix_read, string length of matrix type
       ! exceeds maximum allowed (2000)
       MC65_ERR_READ_MAXLEN = -10, &
       ! in MC65_matrix_read, the particular FORM
       ! is not supported
       MC65_ERR_READ_WRONGFORM = -11, &
       ! in MC65_MATRIX_CONDENSE, try to condense
       ! a matrix that is not of type "pattern"
       MC65_ERR_CONDENSE_NOPAT = -12, &
       ! if PTR(1:M+1) is not monotonically increasing
       ! MATRIX_CONSTRUCT
       MC65_ERR_RANGE_PTR = -13, &
       ! if number of entries in sparse matrix-matrix product is too large
       ! to be represented by integer kind
       MC65_ERR_SMM_TOO_LARGE = -14

  integer (kind = myint), public, parameter :: &
       !  COL is not within the range of [1,n] MATRIX_CONSTRUCT,
       ! such entries are excluded in the construct of the matrix
       MC65_WARN_RANGE_COL = 1, &
       ! IRN is not within the  range of {\tt [1,M]}. In
       ! matrix_construct using coordinate formatted input data.
       ! related entries excluded
       MC65_WARN_RANGE_IRN = 2, &
       ! JCN is not within the  range of {\tt [1,N]}. In
       ! matrix_construct using coordinate formatted input data.
       ! related entries excluded
       MC65_WARN_RANGE_JCN = 3,&
       ! IN MC65_MATRIX_DIAGONAL_FIRST, some diagonal elements
       ! are missing!
       MC65_WARN_MV_DIAG_MISSING = 4,&
       ! if duplicate entries were
       !  found when cleaning the matrix
       MC65_WARN_DUP_ENTRY = 5,&
       ! if both out-of-range and duplicate entries are found. In
       ! matrix construct
       MC65_WARN_ENTRIES = 6,&
       ! if both out-of-range IRN and JCN entries found, such entries
       ! are excluded in the construct of the matrix
       MC65_WARN_RANGE_BOTH = 7
  public &
       MC65_print_message, &
       MC65_matrix_construct, &
       MC65_matrix_destruct, &
       MC65_matrix_reallocate, &
       MC65_matrix_transpose, &
       MC65_matrix_copy, &
       MC65_matrix_clean, &
       MC65_matrix_sort, &
       MC65_matrix_sum, &
       MC65_matrix_symmetrize, &
       MC65_matrix_getrow, &
       MC65_matrix_getrowval, &
       MC65_matrix_is_symmetric, &
       MC65_matrix_is_pattern,&
       MC65_matrix_is_different, &
       MC65_matrix_multiply, &
       MC65_matrix_multiply_graph, &
       MC65_matrix_multiply_vector, &
       MC65_matrix_to_coo, &
       MC65_matrix_remove_diagonal,&
       MC65_matrix_diagonal_first, &
       MC65_matrix_write, &
       MC65_matrix_read,&
       MC65_matrix_condense

!       MC65_matrix_fill, &
!       MC65_matrix_component,&
!       MC65_matrix_crop_unsym, &
!       MC65_matrix_crop



  interface MC65_print_message
     module procedure csr_print_message
  end interface

  interface MC65_matrix_construct
     module procedure csr_matrix_construct
     module procedure csr_to_csr_matrix
     module procedure coo_to_csr_format
  end interface
  interface MC65_matrix_is_symmetric
     module procedure csr_matrix_is_symmetric
  end interface
  interface MC65_matrix_is_pattern
     module procedure csr_matrix_is_pattern
  end interface
  interface MC65_matrix_sort
     module procedure csr_matrix_sort
  end interface
  interface MC65_matrix_clean
     module procedure csr_matrix_clean
  end interface
  interface MC65_matrix_multiply
     module procedure csr_matrix_multiply
  end interface
  interface MC65_matrix_multiply_graph
     module procedure csr_matrix_multiply_graph
  end interface
  interface MC65_matrix_to_coo
     module procedure csr_matrix_to_coo
  end interface
  interface MC65_matrix_write
     module procedure csr_matrix_write
  end interface
  interface MC65_matrix_read
     module procedure csr_matrix_read
  end interface
  interface MC65_matrix_reallocate
     module procedure csr_matrix_reallocate
  end interface

  interface MC65_matrix_destruct
     module procedure csr_matrix_destruct
  end interface
  interface MC65_matrix_transpose
     module procedure csr_matrix_transpose
  end interface
  interface MC65_matrix_symmetrize
     module procedure csr_matrix_symmetrize
  end interface
  interface MC65_matrix_getrow
     module procedure csr_matrix_getrow
  end interface
  interface MC65_matrix_getrowval
     module procedure csr_matrix_getrowval
  end interface
  interface MC65_matrix_sum
     module procedure csr_matrix_sum
  end interface
  interface MC65_matrix_copy
     module procedure csr_matrix_copy
  end interface
  interface MC65_matrix_multiply_vector
     module procedure csr_matrix_multiply_rvector
     module procedure csr_matrix_multiply_ivector
  end interface
  interface MC65_matrix_condense
     module procedure csr_matrix_condense
  end interface
  interface MC65_matrix_diagonal_first
     module procedure csr_matrix_diagonal_first
  end interface
  interface MC65_matrix_remove_diagonal
     module procedure csr_matrix_remove_diagonal
  end interface
!!$  interface MC65_matrix_fill
!!$     module procedure csr_matrix_fill
!!$  end interface
!!$  interface MC65_matrix_component
!!$     module procedure csr_matrix_component
!!$  end interface
!!$  interface MC65_matrix_crop
!!$     module procedure csr_matrix_crop
!!$  end interface
!!$  interface MC65_matrix_crop_unsym
!!$     module procedure csr_matrix_crop_unsym
!!$  end interface
  interface MC65_matrix_is_different
     module procedure csr_matrix_diff
  end interface
  interface expand
     module procedure expand1
     module procedure iexpand1
  end interface


contains

  subroutine csr_print_message(info,stream,context)
    ! printing error message
    ! info: is an integer scaler of INTENT (IN).
    ! It is the information flag
    !       whose corresponding error message is to be printed.
    ! stream: is an OPTIONAL integer scaler of INTENT (IN).
    !         It is the unit number
    !         the user wish to print the error message to.
    !         If this number
    !         is negative, printing is supressed. If not supplied,
    !         unit 6 is the default unit to print the error message.
    ! context: is an OPTIONAL assumed size CHARACTER array
    !          of INTENT (IN).
    !          It describes the context under which the error occurred.
    integer (kind = myint), intent (in) :: info
    integer (kind = myint), intent (in), optional :: stream
    character (len = *), optional, intent (in) :: context
    integer (kind = myint) :: unit,length



    if (present(stream)) then
       unit = stream
    else
       unit = 6
    end if
    if (unit <= 0) return

    if (info > 0) then
       write(unit,advance = "yes", fmt = "(' WARNING: ')")
    else if (info < 0) then
       write(unit,advance = "yes", fmt = "(' ERROR: ')")
    end if

    if (present(context)) then
       length = len_trim(context)
       write(unit,advance = "no", fmt = "(a,' : ')") context(1:length)
    end if

    select case (info)
    case (0)
       write(unit,"(a)") "successful completion"
    case (MC65_ERR_MEMORY_ALLOC)
       write(unit,"(A)") "memory allocation failure failure"
    case(MC65_ERR_MEMORY_DEALLOC)
       write(unit,"(A)") "memory deallocate failure"
    case(MC65_ERR_SUM_DIM_MISMATCH)
       write(unit,"(A)") &
            "dimension mismatch of matrices in MC65_matrix_sum"
    case(MC65_ERR_MATMUL_DIM_MISMATCH)
       write(unit,"(A)") "dimension mismatch in matrix_multiply"
    case(MC65_ERR_MATMULG_DIM_MISMATCH)
       write(unit,"(A)") "dimension mismatch in matrix_multiply_graph"
    case(MC65_ERR_MATVEC_NOVALUE)
       write(unit,"(A)") "try to compute y = Ax or y = A^Tx "
       write(unit,"(A)") "with A pattern only and x real"
    case(MC65_ERR_RANGE_PTR)
       write(unit,"(A)") "PTR(1:M+1) is not monotonically &
            &increasing  in MATRIX_CONSTRUCT"
    case(MC65_ERR_NO_VACANT_UNIT)
       write(unit,"(A)") "no vacant I/O unit has been &
            &found MC65_MATRIX_WRITE"
    case(MC65_ERR_READ_FILE_MISS)
       write(unit,"(A)") "in MC65_MATRIX_READ, &
            &the file to be read does not exist"
    case(MC65_ERR_READ_OPEN)
       write(unit,"(A)") "error opening file in MC65_MATRIX_READ"
    case(MC65_ERR_READ_MAXLEN)
       write(unit,"(A)") "in MC65_matrix_read, &
            &string length of matrix type"
       write(unit,"(A)") "exceeds maximum allowed (2000)"
    case(MC65_ERR_READ_WRONGFORM)
       write(unit,"(A)") "in MC65_matrix_read, &
            &the supplied input format is not supported"
    case(MC65_ERR_CONDENSE_NOPAT)
       write(unit,"(A)") "in MC65_MATRIX_CONDENSE, try to condense"
       write(unit,"(A)") "a matrix that is not of type 'pattern'"
       ! warnings ===========
    case(MC65_WARN_MV_DIAG_MISSING)
       write(unit,"(A)") "IN MC65_MATRIX_DIAGONAL_FIRST, &
            &some diagonal elements"
       write(unit,"(A)") "are missing"
    case(MC65_WARN_RANGE_COL)
       write(unit,"(A)") "Some column indices in COL array are not "
       write(unit,"(A)") "within the range of [1,N] &
            &in MATRIX_CONSTRUCT"
       write(unit,"(A)") "such entries are excluded &
            &in the constructed matrix"
    case(MC65_WARN_RANGE_IRN)
       write(unit,"(A)") "IRN is not within the &
            &range of [1,M] in MATRIX_CONSTRUCT"
       write(unit,"(A)") "using coordinate formatted input data. &
            &Such entries are excluded"
    case(MC65_WARN_RANGE_JCN)
       write(unit,"(A)") "JCN is not within the &
            &range of [1,N] in matrix_construct"
       write(unit,"(A)") " using coordinate formatted &
            &input data. Such entries are excluded"
    case (MC65_WARN_DUP_ENTRY)
       write(unit,"(A)") "duplicate entries were found&
            &and had been merged (summed)"
    case (MC65_WARN_ENTRIES)
       write(unit,"(A)") "both duplicate entries and out-of-range entries &
            &were found &
            &and had been treated"
    case (MC65_WARN_RANGE_BOTH)
       write(unit,"(A)") "both out-of-range IRN and JCN entries found. &
            &Such entries are excluded in the constructed matrix"
    case default
       write(*,"(a,i10,a)") "you have supplied an info flag of ",&
            info," this is not a recognized info flag"
    end select
  end subroutine csr_print_message


  subroutine csr_matrix_construct(matrix,m,nz,info,n,type,stat)
    ! subroutine csr_matrix_construct(matrix,m,nz,info[,n,type])
    ! 1) initialise the matrix row/column dimensions and
    ! matrix type, allocate row pointers
    ! by default n = m and type = "general"
    ! 2) allocate a space of nz for the column indices matrix%col
    ! and when matrix%type /= "pattern",
    ! also allocate space for entry values matrix%val.

    ! matrix: of the derived type ZD11_type, INTENT (inOUT),
    !         the sparse matrix in compressed sparse row format
    type (zd11_type), intent (inout) :: matrix

    ! m: is an integer scaler of INTENT (IN), hold the row dimension
    integer (kind = myint), intent (in) :: m

    ! nz: integer scaler of INTENT (IN).
    !     It contains the storage needs to be allocated for the
    !     entries of matrix.
    !     including the storage needs to be allocated for
    !     the array that holds
    !     the column indices; and when type /= "pattern",
    !     also the space allocated to hold the values of the matrix.
    !     $nz$ must be greater than or equal to the number of
    !     entries in the matrix
    !     if $nz < 0$, a storage  of 0 entry is allocated.
    integer (kind = myint), intent (in) :: nz

    ! info: is an integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory allocation failed
    integer (kind = myint), intent (out) :: info

    ! n: is an optional integer scaler of INTENT (IN). If supplied
    !    it contains the column dimension of the matrix
    integer (kind = myint), optional, intent (in) :: n

    ! type: is an optional character array of unspecified length.
    !       INTENT (IN).
    !       If supplied gives the type of the matrix.
    !       If not supplied,
    !       the type of the matrix will be set to "general"
    character (len=*), optional, intent (in) :: type

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! ==================== locals =========================
    ! ierr: error tag for deallocation
    integer (kind = myint) :: ierr
    ! nz1: space allocated
    integer (kind = myint) :: nz1

    if (present(stat)) stat = 0
    info = 0
    ierr = 0

    matrix%m = m
    if (present(n)) then
       matrix%n = n
    else
       matrix%n = m
    end if

    ! CHECK THAT storage is not already existing and if so
    ! see if it is already large enough
    if (allocated(matrix%ptr)) then
       if (size(matrix%ptr) < m+1) then
          deallocate(matrix%ptr,stat = ierr)
          if (present(stat)) stat = ierr
          if (ierr /= 0) then
             info = MC65_ERR_MEMORY_DEALLOC
             return
          end if
          allocate(matrix%ptr(m+1),stat = ierr)
          if (present(stat)) stat = ierr
       end if
    else
       allocate(matrix%ptr(m+1),stat = ierr)
       if (present(stat)) stat = ierr
    end if
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if

    ! get rid of the storage of type anyway without
    ! checking to see if
    ! it has large enough storage.
    if (allocated(matrix%type)) then
       deallocate(matrix%type, stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          info = MC65_ERR_MEMORY_DEALLOC
          return
       end if
    end if

    ! by default the matrix has entry values.
    if (present(type)) then
       call zd11_put(matrix%type,type,stat = ierr)
    else
       call zd11_put(matrix%type,"general",stat = ierr)
    end if
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if

    ! allocate space for the column indices and possibly the values
    nz1 = nz
    if (nz1 < 0) then
       nz1 = 0
    end if

    ! check to see if col is already allocated and
    ! if so if the storage
    ! is large enough
    if (allocated(matrix%col)) then
       if (size(matrix%col) < nz1) then
          deallocate(matrix%col,stat = ierr)
          if (present(stat)) stat = ierr
          if (ierr /= 0) then
             info = MC65_ERR_MEMORY_DEALLOC
             return
          end if
          allocate(matrix%col(nz1),stat = ierr)
          if (present(stat)) stat = ierr
       end if
    else
       allocate(matrix%col(nz1),stat = ierr)
       if (present(stat)) stat = ierr
    end if
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if

    if (ZD11_get(matrix%type) == "pattern")  then
       if (allocated(matrix%val)) then
          deallocate(matrix%val,stat = ierr)
          if (present(stat)) stat = ierr
          if (ierr /= 0) then
             info = MC65_ERR_MEMORY_DEALLOC
          end if
       end if
       return
    end if

    ! check if matrix%val is allocated already, if so
    ! cehck if the size is large enough
    if (allocated(matrix%val)) then
       if (size(matrix%val) < nz1) then
          deallocate(matrix%val,stat = ierr)
          if (present(stat)) stat = ierr
          if (ierr /= 0) then
             info = MC65_ERR_MEMORY_DEALLOC
             return
          end if
          allocate(matrix%val(nz1),stat = ierr)
          if (present(stat)) stat = ierr
       end if
    else
       allocate(matrix%val(nz1),stat = ierr)
       if (present(stat)) stat = ierr
    end if
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if

  end subroutine csr_matrix_construct

  subroutine csr_matrix_destruct(matrix,info,stat)
    ! subroutine csr_matrix_destruct(matrix,info):
    !
    ! destruct the matrix object by deallocating all
    ! space occupied by
    ! matrix. including matrix%ptr, matrix%col and matrix%type.
    ! when matrix%type /= "pattern", also
    ! deallocate matrix%val

    ! matrix: is of the derived type ZD11_type,
    !         with INTENT (INOUT). It
    !         the sparse matrix object to be destroyed.
    type (zd11_type), intent (inout) :: matrix

    ! info: is an integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed
    integer (kind = myint), intent (out) :: info

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! ===================== local variables =============
    ! ierr: error tag for deallocation
    integer (kind = myint) :: ierr

    info = 0
    if (present(stat)) stat = 0

    deallocate(matrix%col,matrix%ptr, stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
       return
    end if


    if (ZD11_get(matrix%type) == "pattern")  then
       deallocate(matrix%type, stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          info = MC65_ERR_MEMORY_DEALLOC
       end if
       return
    end if

    deallocate(matrix%type, matrix%val, stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
       return
    end if

  end subroutine csr_matrix_destruct

  subroutine csr_matrix_reallocate(matrix,nz,info,stat)
    ! subroutine csr_matrix_reallocate(matrix,nz,info)
    !
    ! reallocate a space of nz for the column index array
    ! and when matrix%type /= "pattern", for the value array
    ! of the sparse matrix in the compact sparse row format.
    ! if nz < 0, a space of 0 will be allocated.
    ! The original context of the array(s),
    ! will be copied to the beginning of the reallocated
    ! array(s). When nz is smaller than the size of
    ! the said array(s), only part of the original
    ! array(s) up to the nz-th element is copied.

    ! matrix: is of the derived type ZD11_type with INTENT (INOUT),
    !         this is the sparse matrix to be reallocated.
    type (zd11_type), intent (inout) :: matrix

    ! nz:  is an integer scaler of INTENT (IN). It holds the
    !     space to be reallocated for the array of
    !     the column indices; and when the matrix
    !     is of type "pattern",
    !     also holds the space to be reallocated
    !     for the array of the entry
    !     values of the matrix.
    !     If nz < 0, a space of 0 will be allocated.

    integer (kind = myint), intent (in) :: nz

    ! info: is an integer scaler of INTENT (OUT).
    !       = 0  if the subroutine returns successfully;
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed.
    integer (kind = myint), intent (out) :: info

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! ================= local variables ================
    ! nz1: actual space allocated
    integer (kind = myint) :: nz1, ierr

    info = 0
    if (present(stat)) stat = 0

    if (nz < 0) then
       nz1 = 0
    else
       nz1 = nz
    end if

    if (size(matrix%col) /= nz1) then
       call expand(matrix%col,nz1,info,ierr)
       if (present(stat)) stat = ierr
       if (info < 0) then
          return
       end if
    end if

    if (ZD11_get(matrix%type) == "pattern")  return

    if (size(matrix%val) /= nz1) then
       call expand(matrix%val,nz1,info,ierr)
       if (present(stat)) stat = ierr
    end if


  end subroutine csr_matrix_reallocate

  subroutine csr_matrix_transpose(MATRIX1,MATRIX2,info,merge,pattern,stat)
    ! subroutine csr_matrix_transpose(MATRIX1,MATRIX2[,merge])
    !
    ! find the transpose of matrix MATRIX1 and
    ! put it in matrix MATRIX2. MATRIX2 = MATRIX1^T
    ! If merge is present and merge = .true.,
    ! repeated entries in MATRIX1 will be summed
    ! in MATRIX2
    ! If pattern is present and pattern = .true.,
    ! the new matrix will be of type "pattern" and
    ! will have no values

    ! MATRIX1: of the derived type ZD11_type, INTENT (INOUT),
    !    the matrix to be transposed
    type (zd11_type), intent (in) :: MATRIX1
    ! MATRIX2: of the derived type ZD11_type, INTENT (INOUT),
    !    MATRIX2 = MATRIX1^T. If merge = .true.,
    !    repeated entries of MATRIX1 are
    !    summed in MATRIX2.
    type (zd11_type), intent (inout) :: MATRIX2

    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed
    integer (kind = myint), intent (out) :: info

    ! merge: optional logical of INTENT (IN).
    !        if merge = .true, repeated entries of
    !        MATRIX1 will be merged in MATRIX2
    !        by summing the entry values. By default,
    !        no merge is performed.
    logical, intent (in), optional :: merge

    ! pattern: optional logical of INTENT (IN).
    !          if pattern = .true., MATRIX2 will have only
    !          the pattern of MATRIX1^T
    logical, intent (in), optional :: pattern

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! ================== local variables ===============
    !
    ! rowsz: number of entries in each row of MATRIX2
    integer (kind = myint), allocatable, dimension (:) :: rowsz


    ! mask: a masking array to see if a particular entry in a row
    !    has already appeared before.
    integer (kind = myint), dimension (:), allocatable :: mask

    integer (kind = myint) :: n,m,ierr,nz

    ! to_merge: whether repeated entries should be
    ! merged by summing the entry values
    logical :: to_merge

    ! pattern_only: whether the transpose matrix will be
    !    pattern only.
    logical :: pattern_only

    info = 0
    if (present(stat)) stat = 0

    to_merge = .false.
    pattern_only = .false.
    if (present(pattern)) then
       pattern_only = pattern
    end if
    if (ZD11_get(MATRIX1%type) == "pattern") pattern_only = .true.

    if (present(merge)) then
       to_merge = merge
    end if

    m = MATRIX1%n
    n = MATRIX1%m

    ! number of entries in each row of MATRIX2
    allocate(rowsz(m),stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if
    rowsz = 0

    if (to_merge) then
       allocate(mask(m),stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          info = MC65_ERR_MEMORY_ALLOC
          return
       end if
       mask = 0
       CALL csr_matrix_transpose_rowsz(n,MATRIX1%ptr,MATRIX1%col,rowsz,mask)
    else
       CALL csr_matrix_transpose_rowsz(n,MATRIX1%ptr,MATRIX1%col,rowsz)
    end if

    nz = sum(rowsz)

    if (pattern_only) then
       call csr_matrix_construct(MATRIX2,m,nz,info,n = n,&
            type = "pattern",stat=ierr)
    else
       call csr_matrix_construct(MATRIX2,m,nz,info,n = n,&
            type = ZD11_get(MATRIX1%type),stat=ierr)
    end if
    if (present(stat)) stat = ierr

    if (info < 0 ) return

    if (pattern_only) then
       if (to_merge) then
          call csr_matrix_transpose_pattern(m,n,MATRIX1%ptr,MATRIX1%col, &
                                  MATRIX2%ptr,MATRIX2%col,rowsz,mask)
       else
          call csr_matrix_transpose_pattern(m,n,MATRIX1%ptr,MATRIX1%col, &
                                  MATRIX2%ptr,MATRIX2%col,rowsz)
       end if
    else
       if (to_merge) then
          call csr_matrix_transpose_values(m,n,MATRIX1%ptr,MATRIX1%col, &
                   MATRIX1%val,MATRIX2%ptr,MATRIX2%col,MATRIX2%val,rowsz,mask)
       else
          call csr_matrix_transpose_values(m,n,MATRIX1%ptr,MATRIX1%col, &
                   MATRIX1%val,MATRIX2%ptr,MATRIX2%col,MATRIX2%val,rowsz)
       end if
    end if

    if (to_merge) then
       deallocate(mask,stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          info = MC65_ERR_MEMORY_DEALLOC
          return
       end if
    end if

    deallocate(rowsz,stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
    end if

  end subroutine csr_matrix_transpose


  subroutine csr_matrix_transpose_rowsz(n,ia,ja,rowsz,mask)
    ! get the number of elements in each row
    ! this is an internal private routine
    ! called by csr_matrix_transpose

    ! n: row dimension of A
    ! ia: row pointer of A
    ! ja: column indices of A
    ! rowsz: the number of elements in each row
    ! mask: zero on entry. On exit mask <= 0. If mask(k) = -i,
    !       column index
    !       k has been seen in row i of A.
    !       this argument is optional, and only present
    !       if repeated entries in A is to be merged when forming A^T
    integer (kind = myint), intent (in) :: n,ia(*),ja(*)
    integer (kind = myint), intent (inout) :: rowsz(*)
    integer (kind = myint), intent (inout), optional :: mask(*)
    integer (kind = myint) :: i,j,k

    if (present(mask)) then
       do i=1,n
          do j = ia(i),ia(i+1)-1
             k = ja(j)
             if (mask(k) /= -i) then
                mask(k) = -i
                rowsz(k) = rowsz(k) + 1
             end if
          end do
       end do
    else
       do i=1,n
          do j = ia(i),ia(i+1)-1
             k = ja(j)
             rowsz(k) = rowsz(k) + 1
          end do
       end do
    end if
  end subroutine csr_matrix_transpose_rowsz



  subroutine csr_matrix_transpose_values(m,n,ia,ja,aa,ib,jb,&
       bb,rowsz,mask)
    ! transpose the matrix A=(ia,ja,aa) that is not pattern only
    ! to give B=(ib,jb,bb). If mask is present,
    ! repeated entries in A will be merged
    ! this is an internal private routine
    ! called by csr_matrix_transpose

    ! n: row dimension of A
    ! m: column dimension of A
    ! ia: row pointer of A
    ! ja: column indices of A
    ! aa: values of A
    ! ib: row pointer of A
    ! jb: column indices of A
    ! bb: values of B
    ! rowsz: the number of elements in each row
    ! mask: zero on entry. On exit mask <= 0. If mask(k) = -i,
    !       column index
    !       k has been seen in row i of A.
    !       this argument is optional, and only present
    !       if repeated entries in A is to be merged when forming A^T
    integer (kind = myint), intent (in) :: m,n,ia(*),ja(*)
    integer (kind = myint), intent (out) :: ib(*),jb(*)
    real (kind = myreal), intent(in) :: aa(*)
    real (kind = myreal), intent(out) :: bb(*)
    integer (kind = myint), intent (inout) :: rowsz(*)
    integer (kind = myint), intent (inout), optional :: mask(*)

    integer (kind = myint) :: i,j,k,l1,l2

    ib(1) = 1
    do i = 1, m
       ib(i+1) = ib(i) + rowsz(i)
    end do
    rowsz(1:m) = ib(1:m)

    if (present(mask)) then
       do i=1,n
          l1 = ia(i)
          l2 = ia(i+1)-1
          do j = l1,l2
             k = ja(j)
             if (mask(k) <= 0) then
                ! record the position of (k,i) in the
                ! transpose matrix
                mask(k) = rowsz(k)
                jb(rowsz(k)) = i
                bb(rowsz(k)) = aa(j)
                rowsz(k) = rowsz(k) + 1
             else
                bb(mask(k)) = bb(mask(k))+aa(j)
             end if
          end do
          ! Note: Can't use following array statement instead of the next loop
          ! as there may be repeated entries in a column.
          ! mask(ja(l1:l2)) = 0
          do j = l1, l2
             mask(ja(j)) = 0
          end do
       end do

    else
       do i=1,n
          do j = ia(i),ia(i+1)-1
             k = ja(j)
             jb(rowsz(k)) = i
             bb(rowsz(k)) = aa(j)
             rowsz(k) = rowsz(k) + 1
          end do
       end do
    end if

  end subroutine csr_matrix_transpose_values




  subroutine csr_matrix_transpose_pattern(m,n,ia,ja,ib,jb,rowsz,mask)
    ! transpose the matrix A=(ia,ja) that is  pattern only
    ! to give B=(ib,jb). If mask is present,
    ! repeated entries in A will be merged
    ! this is an internal private routine
    ! called by csr_matrix_transpose

    ! n: row dimension of A
    ! m: column dimension of A
    ! ia: row pointer of A
    ! ja: column indices of A
    ! aa: values of A
    ! ib: row pointer of A
    ! jb: column indices of A
    ! bb: values of B
    ! rowsz: the number of elements in each row
    ! mask: zero on entry. On exit mask <= 0. If mask(k) = -i,
    !       column index
    !       k has been seen in row i of A.
    !       this argument is optional, and only present
    !       if repeated entries in A is to be merged when forming A^T
    integer (kind = myint), intent (in) :: m,n,ia(*),ja(*)
    integer (kind = myint), intent (out) :: ib(*),jb(*)
    integer (kind = myint), intent (inout) :: rowsz(*)
    integer (kind = myint), intent (inout), optional :: mask(*)

    integer (kind = myint) :: i,j,k,l1,l2
    ib(1) = 1
    do i = 1, m
       ib(i+1) = ib(i) + rowsz(i)
    end do
    rowsz(1:m) = ib(1:m)

    if (present(mask)) then
       do i=1,n
          l1 = ia(i)
          l2 = ia(i+1)-1
          do j = l1,l2
             k = ja(j)
             if (mask(k) <= 0) then
                ! record the position of (k,i) in the
                ! transpose matrix
                mask(k) = rowsz(k)
                jb(rowsz(k)) = i
                rowsz(k) = rowsz(k) + 1
             end if
          end do
          ! Note: Can't use following array statement instead of the next loop
          ! as there may be repeated entries in a column.
          ! mask(ja(l1:l2)) = 0
          do j = l1, l2
             mask(ja(j)) = 0
          end do
       end do

    else
       do i=1,n
          do j = ia(i),ia(i+1)-1
             k = ja(j)
             jb(rowsz(k)) = i
             rowsz(k) = rowsz(k) + 1
          end do
       end do
    end if

  end subroutine csr_matrix_transpose_pattern


  subroutine csr_matrix_copy(MATRIX1,MATRIX2,info,stat)
    ! subroutine csr_matrix_copy(MATRIX1,MATRIX2,info)
    !
    ! Subroutine {\tt MC65\_MATRIX\_COPY} creates a new sparse matrix
    ! {\tt B} which is a copy of the existing sparse matrix
    ! {\tt MATRIX1}.
    ! Storage is allocated for {\tt MATRIX2} and this storage should
    ! be deallocated when {\tt MATRIX2} is no longer used by calling
    ! subroutine {\tt MC65_MATRIX_DESTRUCT}.


    ! MATRIX1: of the derived type ZD11_type, INTENT (IN),
    !    the matrix to be copied from
    type (zd11_type), intent (in) :: MATRIX1

    ! MATRIX2: of the derived type ZD11_type, INTENT (IN),
    !    the matrix to be copied to
    type (zd11_type), intent (inout) :: MATRIX2

    ! info: integer scaler of INTENT (INOUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed
    integer (kind = myint), intent (out) :: info

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! n: column size
    ! m: row size
    ! nz: number of entries in a.
    integer (kind = myint) :: nz,n,m

    if (present(stat)) stat = 0

    nz = MATRIX1%ptr(MATRIX1%m+1)-1
    n = MATRIX1%n
    m = MATRIX1%m
    if (present(stat)) then
       call csr_matrix_construct(MATRIX2,m,nz,info, n = n,&
            type = zd11_get(MATRIX1%type),stat=stat)
    else
       call csr_matrix_construct(MATRIX2,m,nz,info, n = n,&
            type = zd11_get(MATRIX1%type))
    end if
    if (info < 0) return
    MATRIX2%ptr(1:m+1) = MATRIX1%ptr(1:m+1)
    MATRIX2%col(1:nz) = MATRIX1%col(1:nz)
    if (ZD11_get(MATRIX1%type) == "pattern")  return
    MATRIX2%val(1:nz) = MATRIX1%val(1:nz)
  end subroutine csr_matrix_copy



  subroutine csr_matrix_clean(matrix,info,realloc,stat)
    ! subroutine csr_matrix_clean(matrix,info[,realloc])
    !
    ! cleaning the matrix by removing redundant entries
    ! for pattern only matrix, or
    ! by summing it with existing ones for non-pattern only matrix

    ! matrix:  is of the derived type {\tt ZD11\_type} with
    !     INTENT (INOUT),
    !     it is the  the sparse matrix to be cleaned
    type (zd11_type), intent (inout) :: matrix

    ! info: is a integer scaler of INTENT (OUT).
    ! {\tt INFO = 0} if the subroutine completes successfully;
    ! {\tt INFO = MC65\_ERR\_MEMORY\_ALLOC} if memory allocation
    !     failed; and
    ! {\tt INFO = MC65\_ERR\_MEMORY\_DEALLOC} if memory
    !     deallocation failed;
    ! INFO = MC65_WARN_DUP_ENTRY if duplicate entries were
    !  found when cleaning the matrix
    ! Error message can be printed by calling subroutine
    !    {\tt MC65\_ERROR\_MESSAGE}
    integer (kind = myint), intent (out) :: info

    ! realloc:  is an optional real scaler of INTENT (IN).
    !     It is used to control the reallocation of storage.
    ! \begin{itemize}
    !  \item{} if {\tt REALLOC < 0}, no reallocation.
    !  \item{} if {\tt REALLOC == 0}, reallocation is carried out
    !  \item{} if {\tt REALLOC > 0}, reallocation iff
    !       memory saving is greater than
    !      {\tt REALLOC*100}\%. For example,
    !      if {\tt REALLOC = 0.5}, reallocation will be carried out
    !      if saving in storage is greater than 50\%
    !  \end{itemize}
    ! If {\tt REALLOC} is not present, no reallocation
    !    is carried out.
    real (kind = myreal), INTENT(IN), optional :: realloc

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! m: row dimension of matrix
    ! n: column dimension of the matrix
    ! nz: number of entries after the matrix is cleaned
    integer (kind = myint) :: n,m,nz

    ! ia: row pointer of the original matrix
    ! ja: column entries
    ! ib:  row pointer of the cleaned matrix
    integer (kind = myint), allocatable, dimension(:) :: ib

    integer (kind = myint) :: ierr


    ! mask: mask array which tells if an entry has been seen before
    integer (kind = myint), allocatable, dimension (:) :: mask

    ! nz_old: space occupied before cleaning
    ! nentry_old: number of entries in the matrix before cleaning
    integer (kind = myint) :: nz_old, nentry_old

    info = 0
    if (present(stat)) stat = 0
    nz_old = size(matrix%col)
    m = matrix%m
    n = matrix%n
    nentry_old = matrix%ptr(m+1)-1

    allocate(mask(n), ib(m+1), stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if
    mask = 0

    if (ZD11_get(matrix%type) /= "pattern" ) then
       call csr_matrix_clean_private(m,nz,ib,mask,matrix%ptr,matrix%col, &
                                     a = matrix%val)
    else
       call csr_matrix_clean_private(m,nz,ib,mask,matrix%ptr,matrix%col)
    end if

    if (present(realloc)) then
       if (realloc == 0.0_myreal.or.(realloc > 0.and.&
            &nz_old > (1.0_myreal + realloc)*nz)) then
          call csr_matrix_reallocate(matrix,nz,info,stat=ierr)
          if (present(stat)) stat = ierr
          if (info < 0) return
       end if
    end if

    deallocate(mask,ib,stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
    end if

    if (nentry_old /= matrix%ptr(m+1)-1) then
       INFO = MC65_WARN_DUP_ENTRY
    END if

  end subroutine csr_matrix_clean


  subroutine csr_matrix_clean_private(m,nz,ib,mask,ia,ja,a)
    ! clean the matrix a = (ia,ja,a) by summing repeated entries
    ! or clean the matrix a = (ia,ja) by removing repeated entries
    ! this is a private routine called by csr_matrix_clean.
    !
    ! m: row dimension
    ! nz: number of nonzeros in the cleaned matrix
    ! ia: row pointer
    ! ja: column indices
    ! a: values. Optional
    ! ib: new row pointer for cleaned matrix
    ! mask: naming array set to zero on entry
    integer (kind = myint), intent (in) :: m
    integer (kind = myint), intent(inout) :: ia(*),ja(*),mask(*)
    integer (kind = myint), intent(out) :: nz,ib(*)
    real (kind = myreal), intent (inout), optional :: a(*)

    integer (kind = myint) :: i,j,jj

    ib(1) = 1
    nz = 1
    if (present(a)) then
       do i = 1, m
          do j = ia(i),ia(i+1)-1
             jj = ja(j)
             if (mask(jj) == 0) then
                mask(jj) = nz
                ja(nz) = jj
                a(nz) = a(j)
                nz = nz + 1
             else
                a(mask(jj)) = a(mask(jj)) + a(j)
             end if
          end do
          ib(i+1) = nz
          do j = ib(i),nz-1
             mask(ja(j)) = 0
          end do
       end do
    else
       do i = 1, m
          do j = ia(i),ia(i+1)-1
             jj = ja(j)
             if (mask(jj) == 0) then
                mask(jj) = nz
                ja(nz) = jj
                nz = nz + 1
             end if
          end do
          ib(i+1) = nz
          do j = ib(i),nz-1
             mask(ja(j)) = 0
          end do
       end do
    end if
    nz = nz - 1
    ia(1:m+1) = ib(1:m+1)
  end subroutine csr_matrix_clean_private


  subroutine csr_matrix_sort(matrix,info,stat)
    ! subroutine csr_matrix_sort(matrix,info)
    !
    ! sort all rows of a matrix into increasing column indices
    ! This is achieved by doing transpose twice.
    ! Repeated entries will be merged.

    ! matrix: is of the derived type ZD11_type, INTENT (inOUT),
    !         the sparse matrix in compressed sparse row format
    type (zd11_type), intent (inout) :: matrix

    ! info: integer scaler of INTENT (OUT).
    !      INFO = 0 if the subroutine completes successfully;
    !      INFO = MC65_ERR_MEMORY_ALLOC if memory
    !      allocation failed; and
    !      INFO = MC65_ERR_MEMORY_DEALLOC if memory
    !      deallocation failed.
    integer (kind = myint), intent (out) :: info

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! temporary copy of transpose of the matrix
    type (zd11_type) :: matrix_trans

    if (present(stat)) stat = 0

    if ( present(stat) ) then
       call csr_matrix_transpose(matrix,matrix_trans,info,merge=.true.,&
            stat=stat)
    else
       call csr_matrix_transpose(matrix,matrix_trans,info,merge=.true.)
    end if
    if (info < 0) return

    if ( present(stat) )then
       call csr_matrix_destruct(matrix,info,stat=stat)
    else
       call csr_matrix_destruct(matrix,info)
    end if
    if (info < 0) return

    if ( present(stat) ) then
       call csr_matrix_transpose(matrix_trans,matrix,info,stat=stat)
    else
       call csr_matrix_transpose(matrix_trans,matrix,info)
    end if
    if (info < 0) return

    if ( present(stat) ) then
       call csr_matrix_destruct(matrix_trans,info,stat=stat)
    else
       call csr_matrix_destruct(matrix_trans,info)
    end if

  end subroutine csr_matrix_sort

  subroutine csr_matrix_sum(matrix1,matrix2,result_matrix,&
       info,scaling,graph,stat)
    ! subroutine csr_matrix_sum(matrix1,matrix2,result_matrix,
    !       info[,scaling,graph])
    ! Subroutine {\tt MC65\_MATRIX\_SUM} adds two matrix
    !   {\tt MATRIX1} and {\tt MATRIX2} together,
    !    and return the resulting matrix in {\tt RESULT\_MATRIX}.
    !   If the {\tt OPTIONAL} argument {\tt GRAPH}
    !   is present and is {\tt .TRUE.},
    !   the {\tt RESULT\_MATRIX} is the sum of {\tt MATRIX1}
    !   and {\tt MATRIX2}, but with diagonal removed and
    !   all other entries set to 1.0
    !   (1.0D0 for {\tt HSL\_MC65\_DOUBLE}).
    !    Otherwise if the {\tt OPTIONAL} argument
    !   {\tt SCALING} is present,
    !    the scaled summation {\tt Matrix1+SCALING*MATRISX2}
    !    is calculated.

    ! matrix1: of the derived type ZD11_type, INTENT (IN),
    !         a sparse matrix in compressed sparse row format
    ! matrix2: of the derived type ZD11_type, INTENT (IN),
    !         a sparse matrix in compressed sparse row format
    type (zd11_type), intent (in) :: matrix1,matrix2

    ! \itt{result_matrix} is of the derived type
    !   {\tt ZD11\_type} with INTENT (inOUT),
    !   result_matrix is one of the following
    ! \begin{itemize}
    !     \item{} If {\tt GRAPH} is present and is
    !       {\tt .TRUE.}, {\tt RESULT\_MATRIX}
    !       is a matrix of type ``general'', and is set to the sum
    !       of {\tt MATRIX1} and {\tt MATRIX2},
    !       with the diagonal removed
    !       and with all entry values set to 1.0
    !     \item{} Otherwise {\tt RESULT\_MATRIX =
    !       MATRIX1 + MATRIX2}. The type of {\tt RESULT\_MATRIX}
    !       is set to ``pattern'' either {\tt MATRIX1}
    !       or {\tt MATRIX2} is of this type, or else it is
    !       set to the type of {\tt MATRIX1} if
    !       both {\tt MATRIX1} and {\tt MATRIX2}
    !       have the same type, otherwise
    !       it is set as ``general''.
    !     \item{} If the {\tt OPTIONAL} argument
    !       {\tt SCALING} is present,
    !       {\tt RESULT\_MATRIX = MATRIX1 + SCALING*MATRIX2}
    ! \end{itemize}
    type (zd11_type), intent (inout) :: result_matrix

    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed
    !       = MC65_ERR_SUM_DIM_MISMATCH if row (column)
    !         dimension of matrix1 and matrix2 does not match.
    integer (kind = myint), intent (out) :: info

    ! scaling:  matrix2 is to be scaled by *scaling is
    real (kind = myreal), intent (in), optional :: scaling

    ! graph: optional logical scaler of intent (in).
    !        When present and is .true.
    !        the diagonals of the summation is removed, and
    !        entry values set to one if the result_matrix is
    !        not pattern only.
    logical, intent(in), optional :: graph

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! m: row dimension of matrix1
    ! n: column dimension of matrix1
    ! nz: number of entries in the summation matrix1+matrix2
    integer (kind = myint) :: n,m,nz

    integer (kind = myint) :: ierr

    ! mask: mask array to indicate if a particular column index
    !       has been seen
    integer (kind = myint), allocatable, dimension (:) :: mask
    logical :: is_graph

    info = 0
    if (present(stat)) stat = 0

    is_graph = .false.
    if (present(graph)) then
       is_graph = graph
    end if

    m = matrix1%m
    n = matrix1%n
    if (m /= matrix2%m .or. n /= matrix2%n) then
       info = MC65_ERR_SUM_DIM_MISMATCH
       return
    end if

    allocate (mask(n), stat = ierr)
    if ( present(stat) ) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if

    mask = 0

    ! work out the number of entries of the summation.
    if (is_graph) then
       call csr_matrix_sum_getnz(m,matrix1%ptr,matrix1%col,matrix2%ptr, &
                       matrix2%col,mask,nz,graph = is_graph)
    else
       call csr_matrix_sum_getnz(m,matrix1%ptr,matrix1%col,matrix2%ptr, &
                       matrix2%col,mask,nz)
    end if

    ! construct the new matrix
    ! if one of the matrix is pattern only, then
    ! the result matrix has to be pattern only. If
    ! a graph is to be formed, the matrix is always of type "general"
    ! and filled with values 1.0
    if (is_graph) then
       call csr_matrix_construct(result_matrix,m,nz,info,&
            n = n,type = "general",stat=ierr)
    else if (ZD11_get(matrix1%type) == "pattern".or.&
         &ZD11_get(matrix2%type) == "pattern") then
       call csr_matrix_construct(result_matrix,m,nz,info,&
            n = n,type = "pattern",stat=ierr)
    else if (ZD11_get(matrix1%type) == ZD11_get(matrix2%type)) then
       call csr_matrix_construct(result_matrix,m,nz,info,n = n,&
            type = ZD11_get(matrix1%type),stat=ierr)
    else
       call csr_matrix_construct(result_matrix,m,nz,info,&
            n = n,type = "general",stat=ierr)
    end if
    if (present(stat)) stat=ierr
    if (info < 0) then
       return
    end if

    if (ZD11_get(result_matrix%type) /= "pattern" ) then
       IF (PRESENT(SCALING).and.(.not.is_graph)) THEN
          call csr_matrix_sum_values(m,nz,matrix1%ptr,matrix1%col,matrix1%val, &
                   matrix2%ptr,matrix2%col,matrix2%val,result_matrix%ptr, &
                   result_matrix%col,result_matrix%val,mask,scaling = scaling)
       ELSE if (is_graph) then
          call csr_matrix_sum_graph(m,nz,matrix1%ptr,matrix1%col, &
                   matrix2%ptr,matrix2%col,result_matrix%ptr, &
                   result_matrix%col,result_matrix%val,mask)
       else
          call csr_matrix_sum_values(m,nz,matrix1%ptr,matrix1%col,matrix1%val, &
                   matrix2%ptr,matrix2%col,matrix2%val,result_matrix%ptr, &
                   result_matrix%col,result_matrix%val,mask)
       END IF
    else
       call csr_matrix_sum_pattern(m,nz,matrix1%ptr,matrix1%col, &
                   matrix2%ptr,matrix2%col,result_matrix%ptr, &
                   result_matrix%col,mask)
    end if

    deallocate(mask,stat = ierr)
    if ( present(stat) ) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
    end if

  end subroutine csr_matrix_sum


  subroutine csr_matrix_sum_getnz(m,ia,ja,ib,jb,mask,nz,graph)
    ! get the number of nonzeros in the sum of two matrix
    ! (ia,ja) and (ib,jb), and return that number in nz
    ! this is a private routine called by csr_matrix_sum
    !
    ! m: row dimension of A
    ! ia: row pointer of A
    ! ja: column indices of A
    ! ib: row pointer of B
    ! jb: column indices of B
    ! mask: masking array to show whether a particular entry
    !       in the summed matrix has already been see. Initialised
    !       to zero on entry, on exit <= 0.
    ! nz: number of nonzeros in the summed matrix
    ! GRAPH: optional. If present and is true, diagonals
    !        in the summation matrix is not counted
    integer (kind = myint), intent (in) :: m,ia(*),ib(*),ja(*),jb(*)
    integer (kind = myint), intent (inout) :: mask(*)
    integer (kind = myint), intent (out) :: nz
    logical, intent (in),optional :: graph

    logical :: is_graph

    integer (kind = myint) :: i,j,jj

    is_graph = .false.
    if (present(graph)) then
       is_graph = graph
    end if

    if (is_graph) then
       nz = 0
       do i = 1, m
          do j = ia(i), ia(i+1)-1
             jj = ja(j)
             if (jj == i) cycle
             if (mask(jj) /= -i) then
                mask(jj) = -i
                nz = nz + 1
             end if
          end do
          do j = ib(i), ib(i+1)-1
             jj = jb(j)
             if (jj == i) cycle
             if (mask(jj) /= -i) then
                mask(jj) = -i
                nz = nz + 1
             end if
          end do
       end do
    else

       nz = 0
       do i = 1, m
          do j = ia(i), ia(i+1)-1
             jj = ja(j)
             if (mask(jj) /= -i) then
                mask(jj) = -i
                nz = nz + 1
             end if
          end do
          do j = ib(i), ib(i+1)-1
             jj = jb(j)
             if (mask(jj) /= -i) then
                mask(jj) = -i
                nz = nz + 1
             end if
          end do
       end do
    end if
  end subroutine csr_matrix_sum_getnz


  subroutine csr_matrix_sum_values(m,nz,ia,ja,a,ib,jb,b,ic,jc,c,&
       mask,scaling)
    ! sum the two matrix A=(ia,ja,a) and B=(ib,jb,b) into C=(ic,jc,c)
    ! if scaling is present, B will be scaled by it before summing
    !
    !
    ! m: row dimension of A
    ! nz: number of nonzeros in the summation C
    ! ia: row pointer of A
    ! ja: column indices of A
    ! a: values of A
    ! ib: row pointer of B
    ! jb: column indices of B
    ! b: values of B
    ! ic: row pointer of C
    ! jc: column indices of C
    ! c: values of C
    ! mask: masking array to show whether a particular entry
    !       in the summed matrix has already been see. Initialised
    !       to <= 0 on entry
    integer (kind = myint), intent (in) :: m,ia(*),ib(*),ja(*),jb(*)
    real (kind = myreal), intent (in) :: a(*),b(*)
    integer (kind = myint), intent (out) :: ic(*),jc(*)
    real (kind = myreal), intent (out) :: c(*)
    integer (kind = myint), intent (inout) :: mask(*)
    real (kind = myreal), intent (in), optional :: scaling
    integer (kind = myint), intent (out) :: nz


    integer (kind = myint) :: i,j,jj


    ic(1) = 1
    nz = 1
    if (.not.present(scaling)) then
       do i = 1, m
          do j = ia(i), ia(i+1)-1
             jj = ja(j)
             if (mask(jj) <= 0) then
                mask(jj) = nz
                jc(nz) = jj
                c(nz) = a(j)
                nz = nz + 1
             else
                c(mask(jj)) = c(mask(jj)) +  a(j)
             end if
          end do
          do j = ib(i),ib(i+1)-1
             jj = jb(j)
             if (mask(jj) <= 0) then
                mask(jj) = nz
                jc(nz) = jj
                c(nz) = b(j)
                nz = nz + 1
             else
                c(mask(jj)) = c(mask(jj)) +  b(j)
             end if
          end do
          ic(i+1) = nz
          do j = ic(i),nz-1
             mask(jc(j)) = 0
          end do
       end do
    else
       do i = 1, m
          do j = ia(i), ia(i+1)-1
             jj = ja(j)
             if (mask(jj) <= 0) then
                mask(jj) = nz
                jc(nz) = jj
                c(nz) = a(j)
                nz = nz + 1
             else
                c(mask(jj)) = c(mask(jj)) +  a(j)
             end if
          end do
          do j = ib(i),ib(i+1)-1
             jj = jb(j)
             if (mask(jj) <= 0) then
                mask(jj) = nz
                jc(nz) = jj
                c(nz) = scaling*b(j)
                nz = nz + 1
             else
                c(mask(jj)) = c(mask(jj)) +  scaling*b(j)
             end if
          end do
          ic(i+1) = nz
          do j = ic(i),nz-1
             mask(jc(j)) = 0
          end do
       end do

    end if
    nz = nz-1
  end subroutine csr_matrix_sum_values



  subroutine csr_matrix_sum_graph(m,nz,ia,ja,ib,jb,ic,jc,c,mask)
    ! sum the two matrix A=(ia,ja,a) and B=(ib,jb,b) into C=(ic,jc,c)
    ! diagonals of C is ignored and
    ! all entries of C set to one
    !
    ! m: row dimension of A
    ! nz: number of nonzeros in the summation C
    ! ia: row pointer of A
    ! ja: column indices of A
    ! ib: row pointer of B
    ! jb: column indices of B
    ! ic: row pointer of C
    ! jc: column indices of C
    ! c: values of C
    ! mask: masking array to show whether a particular entry
    !       in the summed matrix has already been see. Initiualised
    !       to <= 0 on entry
    integer (kind = myint), intent (in) :: m,ia(*),ib(*),ja(*),jb(*)
    integer (kind = myint), intent (out) :: ic(*),jc(*)
    real (kind = myreal), intent (out) :: c(*)
    integer (kind = myint), intent (inout) :: mask(*)
    integer (kind = myint), intent (out) :: nz


    integer (kind = myint) :: i,j,jj


    ic(1) = 1
    nz = 1
    do i = 1, m
       do j = ia(i), ia(i+1)-1
          jj = ja(j)
          if (jj == i) cycle
          if (mask(jj) <= 0) then
             mask(jj) = nz
             jc(nz) = jj
             c(nz) =  1.0_myreal
             nz = nz + 1
          else
             c(mask(jj)) = 1.0_myreal
          end if
       end do
       do j = ib(i),ib(i+1)-1
          jj = jb(j)
          if (jj == i) cycle
          if (mask(jj) <= 0) then
             mask(jj) = nz
             jc(nz) = jj
             c(nz) = 1.0_myreal
             nz = nz + 1
          else
             c(mask(jj)) = 1.0_myreal
          end if
       end do
       ic(i+1) = nz
       do j = ic(i),nz-1
          mask(jc(j)) = 0
       end do
    end do
    nz = nz-1
  end subroutine csr_matrix_sum_graph


  subroutine csr_matrix_sum_pattern(m,nz,ia,ja,ib,jb,ic,jc,mask)
    ! sum the two matrix A=(ia,ja) and B=(ib,jb, into C=(ic,jc),
    !    patterns only.
    ! m: row dimension of A
    ! nz: number of nonzeros in the summation C
    ! ia: row pointer of A
    ! ja: column indices of A
    ! ib: row pointer of B
    ! jb: column indices of B
    ! ic: row pointer of C
    ! jc: column indices of C
    ! mask: masking array to show whether a particular entry
    !       in the summed matrix has already been see. Initiualised
    !       to <= 0 on entry
    ! graph: optional logical, when present and is .true.,
    !        the diagonals of the C will not be generated.
    integer (kind = myint), intent (in) :: m,ia(*),ib(*),ja(*),jb(*)
    integer (kind = myint), intent (out) :: ic(*),jc(*)
    integer (kind = myint), intent (inout) :: mask(*)
    integer (kind = myint), intent (out) :: nz

    integer (kind = myint) :: i,j,jj

!!$    is_graph = .false.
!!$    if (present(graph)) then
!!$       is_graph = graph
!!$    end if


    ic(1) = 1
    nz = 1

!!$    if (is_graph) then
!!$       do i = 1, m
!!$          do j = ia(i), ia(i+1)-1
!!$             jj = ja(j)
!!$             if (jj == i) cycle
!!$             if (mask(jj) <= 0) then
!!$                mask(jj) = nz
!!$                jc(nz) = jj
!!$                nz = nz + 1
!!$             end if
!!$          end do
!!$          do j = ib(i),ib(i+1)-1
!!$             jj = jb(j)
!!$             if (jj == i) cycle
!!$             if (mask(jj) <= 0) then
!!$                mask(jj) = nz
!!$                jc(nz) = jj
!!$                nz = nz + 1
!!$             end if
!!$          end do
!!$          ic(i+1) = nz
!!$          do j = ic(i),nz-1
!!$             mask(jc(j)) = 0
!!$          end do
!!$       end do
!!$    else
       do i = 1, m
          do j = ia(i), ia(i+1)-1
             jj = ja(j)
             if (mask(jj) <= 0) then
                mask(jj) = nz
                jc(nz) = jj
                nz = nz + 1
             end if
          end do
          do j = ib(i),ib(i+1)-1
             jj = jb(j)
             if (mask(jj) <= 0) then
                mask(jj) = nz
                jc(nz) = jj
                nz = nz + 1
             end if
          end do
          ic(i+1) = nz
          do j = ic(i),nz-1
             mask(jc(j)) = 0
          end do
       end do
!    end if
    nz = nz-1
  end subroutine csr_matrix_sum_pattern

  subroutine csr_matrix_symmetrize(matrix,info,graph,stat)
    ! The subroutine {\tt MC65\_MATRIX\_SYMMETRIZE} make the
    !    matrix symmetric by summing it with its transpose.
    !    If the optional argument {\tt GRAPH}
    !    is present and is set to {\tt .TRUE.}, the diagonal of the
    !    summation is not included, and whenever entry values are
    !    available, they are set to {\tt 1.0}(or {\tt 1.0D0}for
    !    {\tt HSL\_MC65\_double}.

    ! matrix: of the derived type ZD11_type, INTENT (INOUT),
    !         the sparse matrix in compressed sparse row format
    !         to be made symmetric by matrix+matrix^T
    type (zd11_type), intent (inout) :: matrix

    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed
    !       = MC65_ERR_SUM_DIM_MISMATCH if trying to symmetrize
    !          a nonsquare matrix.
    integer (kind = myint), intent (out) :: info

    ! graph: optional logical scaler. when present and is .true.,
    !        the diagonals of matrix+matrix^T will be removed,
    !        and entry values set to 1.0_myreal matrix is
    !        not pattern only.
    logical, intent (in), optional :: graph

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! matrix1: transposed of matrix
    ! matrix2: A+A^T
    type (zd11_type) :: matrix1, matrix2

    ! is_graph: whether we are generating a graph by the summation
    logical :: is_graph

    if ( present(stat) ) stat = 0

    is_graph = .false.
    if (present(graph)) is_graph = graph
    if (present(stat)) then
       call csr_matrix_transpose(matrix,matrix1,info,stat=stat)
    else
       call csr_matrix_transpose(matrix,matrix1,info)
    end if
    if (info < 0) return

    if (is_graph) then
       if (present(stat)) then
          call csr_matrix_sum(matrix,matrix1,matrix2,info,graph=.true.,&
               &stat=stat)
       else
          call csr_matrix_sum(matrix,matrix1,matrix2,info,graph=.true.)
       end if
    else
       if (present(stat)) then
          call csr_matrix_sum(matrix,matrix1,matrix2,info,stat=stat)
       else
          call csr_matrix_sum(matrix,matrix1,matrix2,info)
       end if
    end if

    if (info < 0) return

    if (present(stat)) then
       call csr_matrix_copy(matrix2,matrix,info,stat=stat)
    else
       call csr_matrix_copy(matrix2,matrix,info)
    end if

    if (info < 0) return

    if (present(stat)) then
       call csr_matrix_destruct(matrix2,info,stat=stat)
    else
       call csr_matrix_destruct(matrix2,info)
    end if

    if (info < 0) return

    if (present(stat)) then
       call csr_matrix_destruct(matrix1,info,stat=stat)
    else
       call csr_matrix_destruct(matrix1,info)
    end if

    if (info < 0) return

  end subroutine csr_matrix_symmetrize


  subroutine csr_matrix_getrow(a,i,col)

    ! get the column indices of the i-th row of matrix a

    ! a: of the derived type ZD11_type, INTENT (IN), TARGET
    !    the sparse matrix in compressed sparse row format
    type (zd11_type), intent (in), target :: a

    ! i: is an integer of intent (in), it is the
    ! the index of a row of A to be extracted.
    integer (kind = myint), intent (in) :: i

    ! col: is the array of column indices for the row
    integer (kind = myint), pointer, dimension (:) :: col

    col => a%col(a%ptr(i):a%ptr(i+1)-1)

  end subroutine csr_matrix_getrow


  subroutine csr_matrix_getrowval(a,i,val)

    ! get the values of the i-th row of matrix a

    ! a: of the derived type ZD11_type, INTENT (IN), TARGET
    !    the sparse matrix in compressed sparse row format
    type (zd11_type), intent (in), target :: a

    ! i: the row index of A which the column values are
    !     to be extracted.
    integer (kind = myint), intent (in) :: i

    ! val: the real (or double) array of
    !     values of the i-th row of the matrix
    real (kind = myreal), pointer, dimension (:) :: val

    val => a%val(a%ptr(i):a%ptr(i+1)-1)

  end subroutine csr_matrix_getrowval


  subroutine csr_matrix_is_symmetric(matrix,symmetric,info,&
       pattern,tol,stat)
    ! function csr_matrix_is_symmetric(matrix,symmetric,&
    !    info[,pattern,tol,stat])
    !
    ! The subroutine {\tt MC65\_MATRIX\_IS\_SYMMETRIC}
    !   check whether a matrix is symmetric or not.
    !   {\tt symmetric = .TRUE.} if the matrix is symmetric,
    !   and {\tt symmetric= .FALSE.} if not. When the matrix
    !   is of type ``pattern'', only structural symmetry is
    !   checked, otherwise the matrix is said to be symmetric
    !   if it is both structural symmetric
    !   and that for each entry {\tt MATRIX(I,J)}, the inequality
    !  {\tt MATRIX(I,J) - MATRIX(J,I) <= E} holds.
    !  Here {\tt E} is a tolerance set by default to
    !  {\tt E = 0.0} (or {\tt E = 0.0D0) for HSL\_MC65\_DOUBLE}.

    ! Two optional arguments are supplied. If the optional argument
    !   {\tt PATTERN} is present and is set to {\tt .TRUE.},
    !   only structural symmetry is checked. If the optional
    !   argument {\tt TOL} is present, the internal tolerance
    !   {\tt E} is set to {\tt TOL}.



    ! matrix:  is of the derived type ZD11_type with INTENT (IN).
    !     It is the sparse matrix whose symmetry is to be checked.
    type (zd11_type), intent (in) :: matrix

    ! symmetric: is logical of intent (out).
    !             It is set to {\tt .TRUE.} only in one of
    !            the following cases
    !            1) When {\tt PATTERN} is not present, or
    !               is present but {\tt PATTERN /= .TRUE.}
    !               1a) the matrix is not of type "pattern" and
    !                   is symmetric both structurally
    !                   and numerically.
    !               1b) the matrix is of type "pattern" and
    !                   is structurally symmetric.
    !            2) when {\tt PATTERN} is present and
    !               {\tt PATTERN = .TRUE.}, and
    !               the matrix is structurally symmetric
    logical, intent (out) :: symmetric


    ! info: integer scaler of INTENT (OUT).
    !      {\tt INFO = 0} if the subroutine returns successfully;
    !      {\tt INFO = MC65_ERR_MEMORY_ALLOC} if memory
    !         allocation failed; and
    !      {\tt INFO = MC65_ERR_MEMORY_DEALLOC} if memory
    !        deallocation failed
    integer (kind = myint), intent (out) :: info

    ! pattern:  is an optional logical scaler of INTENT (IN).
    !         when it is present and is {\tt .TRUE.},
    !         only structural symmetry is checked.
    logical, optional, intent (in) :: pattern

    ! tol: an optional real scaler of INTENT (IN).
    !      tol is the tolerance used to decide if two
    !      entries are the same
    real (kind = myreal), optional, intent (in) :: tol

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! matrix_trans: the transpose of matrix
    type (zd11_type) :: matrix_trans

    ! m: row dimension of matrix
    ! n: column dimension of matrix
    ! nz: number of nonzero entries in the matrix
    integer (kind = myint) :: n,m


    integer (kind = myint), dimension (:), allocatable :: mask
    integer (kind = myint) :: ierr
    real (kind = myreal), dimension (:), allocatable :: val

    ! structural: = .true. if only structural symmetry is checked
    logical :: structural

    ! e: error allowed for judging symmetry on matrix that
    !    is not pattern only.
    real (kind = myreal) :: e

    info = 0
    if (present(stat)) stat = 0

    e = real(0,myreal)
    if (present(tol)) then
       e = tol
    end if

    structural = .false.
    if (present(pattern)) then
       structural = pattern
    end if
    if (zd11_get(matrix%type) == "pattern") structural = .true.

    symmetric = .true.
    m = matrix%m
    n = matrix%n
    if (n /= m) then
       symmetric = .false.
       return
    end if

    ! transpose matrix
    if (structural) then
       if (present(stat)) then
          call csr_matrix_transpose(matrix,matrix_trans,info,&
               merge = .true.,pattern = .true., stat = stat)
       else
          call csr_matrix_transpose(matrix,matrix_trans,info,&
               merge = .true.,pattern = .true.)
       end if
    else
       if (present(stat)) then
          call csr_matrix_transpose(matrix,matrix_trans,info,&
               merge = .true., stat=stat)
       else
          call csr_matrix_transpose(matrix,matrix_trans,info,&
               merge = .true.)
       end if
    end if
    if (info < 0) return

    allocate(mask(m),stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
    end if

    if (structural) then
       symmetric = csr_matrix_is_same_pattern(m,n,&
            ia = matrix%ptr,ja = matrix%col,&
            ib = matrix_trans%ptr,jb = matrix_trans%col,mask = mask)
    else
       allocate(val(m),stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          info = MC65_ERR_MEMORY_ALLOC
       end if
       symmetric = csr_matrix_is_same_values(m,n,&
            ia = matrix%ptr,ja = matrix%col,a = matrix%val, &
            ib = matrix_trans%ptr,jb = matrix_trans%col,&
            b = matrix_trans%val, &
            mask = mask,val = val,tol = e)
       ! check only structural symmetry as well as values
       deallocate(val,stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          info = MC65_ERR_MEMORY_DEALLOC
          return
       end if
    end if

    deallocate(mask,stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
       return
    end if
    call csr_matrix_destruct(matrix_trans,info)

  end subroutine csr_matrix_is_symmetric


  function csr_matrix_is_same_pattern(m,n,ia,ja,ib,jb,mask) &
       result(thesame)
    ! check if two matrix, A=(ia,ja) and B = (ib,jb),
    ! is structurally the same. Here B is assumed to have
    ! no repeated entries. A and B is assumed to have the same row
    ! size.
    ! This is a private function called by csr_matrix_is_symmetric
    !
    ! m: row size of A
    ! n: column size of A
    ! ia: row pointer array of A
    ! ja: column indices of A
    ! ib: row pointer array of B
    ! jb: column indices of B
    ! mask: a mask which indicate if a certain column entry k
    !       has been seen in this row i (if mask(k) = i). size >= n
    ! thesame: A and B is the same pattern
    integer (kind = myint), intent (in) :: m,n,ia(*),ja(*),ib(*),jb(*)
    integer (kind = myint), intent (inout) :: mask(*)
    logical :: thesame
    !
    ! na: number of distinctive entries in a row of A
    integer (kind = myint) :: na
    integer (kind = myint) :: i,j,k,l1,l2

    thesame = .true.

    mask(1:n) = 0
    do i = 1, m
       na = 0
       do j = ia(i),ia(i+1)-1
          k = ja(j)
          if (mask(k) /= i) then
             mask(k) = i
             na = na + 1
          end if
       end do
       l1 = ib(i)
       l2 = ib(i+1) - 1
       ! make sure the number of distinctive entries
       ! of the A and B is the same. Since B is assumed to have
       ! no repeated entries, its number of distinctive entries
       ! is simply l2-l1+1
       if (na /= l2 - l1 + 1) then
          thesame = .false.
          return
       end if
       do j = l1,l2
          if (mask(jb(j)) /= i) then
             thesame = .false.
             return
          end if
       end do
    end do
  end function csr_matrix_is_same_pattern





  function csr_matrix_is_same_values(m,n,ia,ja,a,ib,jb,b,mask,&
       val,tol) result(thesame)
    ! check if two matrix, A=(ia,ja,a) and B = (ib,jb,b),
    ! is the same structurally as well as in values.
    ! Here B is assumed to have
    ! no repeated entries. A and B is assumed to have the same row
    ! size as well as column size.
    ! This is a private function called by csr_matrix_is_symmetric
    !
    ! m: row size of A
    ! n: column size of A.
    ! ia: row pointer array of A
    ! ja: column indices of A
    ! a: entry values of A
    ! ib: row pointer array of B
    ! jb: column indices of B
    ! b: entry values of B
    ! mask: a mask which indicate if a certain column entry k
    !       has been seen in this row i (if mask(k) = i). Initialised
    !       to zero. size >= n
    ! val: the entry values in a row of A. If A has repeated entries,
    !      val will contain the sum of the repeated entry values.
    ! thesame: A and B is the same pattern
    ! tol: error allowed for judging symmetry on matrix that
    !     is not pettern only.
    integer (kind = myint), intent (in) :: m,n,ia(*),ja(*),ib(*),jb(*)
    integer (kind = myint), intent (inout) :: mask(*)
    real (kind = myreal), intent (in) :: a(*),b(*)
    real (kind = myreal), intent (inout) :: val(*)
    logical :: thesame
    real (kind = myreal), intent (in) :: tol
    !
    ! na: number of distinctive entries in a row of A
    integer (kind = myint) :: na
    integer (kind = myint) :: i,j,k,l1,l2

    thesame = .true.
    mask(1:n) = 0
    do i = 1, m
       na = 0
       do j = ia(i),ia(i+1)-1
          k = ja(j)
          if (mask(k) /= i) then
             mask(k) = i
             na = na + 1
             val(k) = a(j)
          else
             val(k) = val(k) + a(j)
          end if
       end do
       l1 = ib(i)
       l2 = ib(i+1) - 1
       ! make sure the number of distinctive entries
       ! of the A and B is the same. Since B
       ! is assumed to have no repeated entries,
       ! its number of distinctive entries
       ! is simply l2-l1+1
       if (na /= l2 - l1 + 1) then
          thesame = .false.
          return
       end if
       do j = l1,l2
          k = jb(j)
          if (mask(k) /= i) then
             thesame = .false.
             return
          else
             if (abs(val(k)-b(j)) > tol) then
                thesame = .false.
                return
             end if
          end if
       end do
    end do
  end function csr_matrix_is_same_values


  subroutine csr_matrix_diff(MATRIX1,MATRIX2,diff,info,pattern,stat)
    !   subroutine csr_matrix_diff(MATRIX1,MATRIX2,diff,&
    !      info[,pattern,stat])

    ! return the difference between two matrix MATRIX1 and MATRIX2.
    !    Here MATRIX1 and MATRIX2 are assumed to have not
    !    repeated entries.
    !
    ! 1) if the dimension of the matrix or the number of entries
    !    is different, huge(0.0_myreal) is returned.
    ! 2) else if the two matrices have different patterns,
    !    huge(0.0_myreal) is returned
    ! 3) else if both matrices are not pattern only, f1 is returned
    ! here: f1=sum(abs((a-b)%val))
    ! 4) else if either are pattern only, 0.0_myreal is returned
    !
    ! If the optional argument pattern is present and is .true.,
    !   both matrices are taken as pattern only.

    ! MATRIX1,MATRIX2: of the derived type ZD11_type, INTENT (IN),
    !      the sparse matrix in compressed sparse row format
    !      Two matrices to be compared.
    type (zd11_type), intent (in) :: MATRIX1,MATRIX2

    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed
    integer (kind = myint), intent(out) :: info

    ! pattern: optional logical scaler of INTENT (IN). If present and
    !          is .true., only the difference in pattern is returned.
    logical, optional, INTENT (IN) :: pattern


    ! diff:  is a real (double precision real in HSL_MC65_double)
    !         scaler returned on successful completion of the
    !         function. It is difference in the matrices
    !         {\tt MATRIX1} and {\tt MATRIX2} defined as follows
    !   \begin{itemize}
    !   \item{} If the row or column dimension of {\tt MATRIX1}
    !           and {\tt MATRIX2} does not match,
    !           {\tt HUGE\{0.0\}} ({\tt HUGE\{0.0D0\}} for
    !           {\tt HSL_MC65_double}) is returned;
    !   \item{} Else if {\tt MATRIX1} and {\tt MATRIX2} has different
    !            pattern, {\tt HUGE\{0.0\}} ({\tt HUGE\{0.0D0\}} for
    !           {\tt HSL_MC65_double}) is returned;
    !   \item{} Else if either {\tt MATRIX1} or {\tt MATRIX2}
    !            is of type {\tt ``pattern''},
    !            0.0 (0.0D0 for {\tt HSL_MC65_double}) is returned.
    !   \item{} Else if neither {\tt MATRIX1} nor {\tt MATRIX2}
    !            is of the type
    !            {\tt ``pattern''}, the sum of the absolute value
    !             of the difference in entry value,
    !            {\tt SUM(ABS((MATRIX1\%VAL - MATRIX2\%VAL))},
    !            is returned.
    !   \end{itemize}

    real (kind = myreal), intent (out) :: diff

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat


    ! ma,ma: row dimension of a and b
    ! na,nb: column dimension of a and b
    ! nza,nzb: number of entries of a and b and c
    integer (kind = myint) :: ma,mb,na,nb,nza,nzb


    ! pattern_only: only find the difference in patterns
    logical :: pattern_only,pattern_the_same

    integer (kind = myint), allocatable :: mask(:)

    integer (kind = myint) :: ierr


    info = 0
    if (present(stat)) stat = 0

    pattern_only = .false.
    if (present(pattern)) then
       pattern_only = pattern
    end if
    if (ZD11_get(MATRIX1%type) == "pattern".or.&
         ZD11_get(MATRIX2%type) == "pattern") &
         pattern_only = .true.


    ma = MATRIX1%m
    mb = MATRIX2%m
    na = MATRIX1%n
    nb = MATRIX2%n
    nza = MATRIX1%ptr(ma+1)-1
    nzb = MATRIX2%ptr(mb+1)-1
    if (ma /= mb .or. na /= nb .or. nza /= nzb) then
       diff = huge(0.0_myreal)
       return
    end if

    allocate(mask(na),stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if
    if (pattern_only) then
       pattern_the_same = csr_matrix_is_same_pattern(m = ma,n = na,&
            ia = MATRIX1%ptr,ja = MATRIX1%col,&
            ib = MATRIX2%ptr,jb = MATRIX2%col,mask = mask)
       if (pattern_the_same) then
          diff = 0.0_myreal
       else
          diff = huge(0.0_myreal)
       end if
    else
       diff = csr_matrix_diff_values(m = ma,n = na,&
            ia = MATRIX1%ptr,ja = MATRIX1%col,a=MATRIX1%val,&
            ib = MATRIX2%ptr,jb = MATRIX2%col,b=MATRIX2%val,&
            mask = mask)
    end if


    deallocate(mask, stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
       return
    end if

  end subroutine csr_matrix_diff


  function csr_matrix_diff_values(m,n,ia,ja,a,ib,jb,b,mask) &
       result(diff)
    ! find the difference in values of two matrices,
    !   A=(ia,ja,a) and B = (ib,jb,b),
    ! If the two are of different pattern,
    !   the difference is huge(0.0_myreal).
    ! Here A and B are assumed to have
    ! no repeated entries, they are assumed to have the same row
    ! size as well as column size.
    ! This is a private function called by csr_matrix_diff
    !
    ! m: row size of A
    ! n: column size of A.
    ! ia: row pointer array of A
    ! ja: column indices of A
    ! a: entry values of A
    ! ib: row pointer array of B
    ! jb: column indices of B
    ! b: entry values of B
    ! mask: a mask which indicate if a certain column entry k
    !       has been seen in this row i (if mask(k) = i). Initialised
    !       to zero. size >= n
    ! diff: difference in values between A and B.
    !       If A and B is of different pattern,
    !       diff - huge(0.0_myreal),
    !       else diff = sum(abs(A-B))
    real (kind = myreal) :: diff


    integer (kind = myint), intent (in) :: m,n,ia(*),ja(*),ib(*),jb(*)
    integer (kind = myint), intent (inout) :: mask(*)
    real (kind = myreal), intent (in) :: a(*),b(*)

    !
    integer (kind = myint) :: i,j,k,la1,la2,lb1,lb2,jj

    mask(1:n) = 0
    diff = 0
    do i = 1, m
       la1 = ia(i)
       la2 = ia(i+1)-1
       do j = la1,la2
          k = ja(j)
          if (mask(k) == 0) then
             mask(k) = j
          end if
       end do

       ! of the A and B is the same. Since neither
       ! is assumed to have repeated entries,
       ! its number of distinctive entries
       ! is simply ia(i+1)-ia(i)
       lb1 = ib(i)
       lb2 = ib(i+1)-1
       if (la2-la1 /= lb2-lb1) then
          diff = huge(0.0_myreal)
          return
       end if
       do j = lb1,lb2
          k = jb(j)
          jj = mask(k)
          if (jj == 0) then
             diff = huge(0.0_myreal)
             return
          else
             diff = diff + abs(b(j) - a(jj))
          end if
       end do
       do j = la1,la2
          mask(ja(j)) = 0
       end do
    end do
  end function csr_matrix_diff_values





  subroutine csr_matrix_multiply(matrix1,matrix2,result_matrix,info,stat)
    ! subroutine csr_matrix_multiply(matrix1,matrix2,&
    !     result_matrix,info)
    !
    ! multiply two matrices matrix1 and matrix2,
    ! and put the resulting matrix in result_matrix
    ! The storage is allocated inside this routine for
    ! the sparse matrix object {tt RESULT\_MATRIX},
    ! and when result_matrix is no longer needed,
    ! this memory should be deallocated using
    ! {\tt MATRIX\_DESTRUCT}


    ! matrix1: is of the derived type ZD11_type, INTENT (IN),
    !         the sparse matrix in compressed sparse row format
    ! matrix2: is of the derived type ZD11_type, INTENT (IN),
    !         the sparse matrix in compressed sparse row format
    type (zd11_type), intent (in) :: matrix1,matrix2

    ! result_matrix: of the derived type ZD11_type, INTENT (INOUT)
    !                result_matrix=matrix1*matrix2
    type (zd11_type), intent (inout) :: result_matrix

    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed.
    !       = MC65_ERR_MATMUL_DIM_MISMATCH dimension mismatch
    integer (kind = myint), intent (out) :: info


    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! ================ local variables =================
    ! m: row size of the matrix1
    ! nz: number of nonzeros in the product matrix
    ! n: column side of matrix2
    integer (kind = myint) :: n,nz,m

    ! mask: an array with a size the same as the
    !       column size of matrix2,
    !       used to indicating whether an entry in the product
    !       has been seen or not.
    integer (kind = myint), allocatable, dimension(:) :: mask

    integer (kind = myint) :: ierr
    if (present(stat)) stat = 0

    info = 0

    m = matrix1%m
    n = matrix2%n

    ! check if the dimension match
    if (matrix1%n /= matrix2%m) then
       info = MC65_ERR_MATMUL_DIM_MISMATCH
       return
    end if

    allocate(mask(n), stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if

    ! now find the size
    call matmul_size(m,n,matrix1%ptr,matrix1%col,matrix2%ptr,matrix2%col,&
         nz,mask)

    ! construct the new matrix
    ! if one of the matrix is pattern only, then
    ! the result matrix has to be pettern only
    if (ZD11_get(matrix1%type) == "pattern".or.&
         ZD11_get(matrix2%type) == "pattern") then
       call csr_matrix_construct(result_matrix,m,nz,info,n=n, &
            type = "pattern",stat=ierr)
       if (present(stat)) stat = ierr
       if (info < 0) return
    else if (ZD11_get(matrix1%type) == ZD11_get(matrix2%type)) then
       call csr_matrix_construct(result_matrix,m,nz,info,n=n, &
            type = ZD11_get(matrix1%type),stat=ierr)
       if (present(stat)) stat = ierr
       if (info < 0) return
    else
       call csr_matrix_construct(result_matrix,m,nz,info,n=n, &
            type = "general",stat=ierr)
       if (present(stat)) stat = ierr
       if (info < 0) return
    end if

    if (ZD11_get(result_matrix%type) == "pattern")  then
       call matmul_noval(m,n,matrix1%ptr,matrix1%col,matrix2%ptr,matrix2%col, &
                       result_matrix%ptr,result_matrix%col,mask)
    else
       call matmul_normal(m,n,matrix1%ptr,matrix1%col,matrix1%val, &
                       matrix2%ptr,matrix2%col,matrix2%val,result_matrix%ptr, &
                       result_matrix%col,result_matrix%val,mask)
    end if

    deallocate(mask, stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
       return
    end if

  end subroutine csr_matrix_multiply


  subroutine matmul_size(m,n,ia1,ja1,ia2,ja2,nz,mask)
    ! work out the number of nonzeros in the
    ! product of two matrix A=(ia1,ja1) and B=(ia2,ja2),

    ! m: row size of A
    ! n: column size of B
    integer (kind = myint), intent (in) :: n,m
    ! ia1: row pointer of A
    ! ja1: column indices of A
    ! ia2: row pointer of B
    ! ja2: column indices of B
    integer (kind = myint), intent (in), dimension (*) :: &
         ia1,ja1,ia2,ja2

    ! nz: number of nonzeros in the product matrix
    integer (kind = myint), intent (inout) :: nz

    ! mask: working array
    integer (kind = myint), intent (inout) :: mask(*)
    ! i,j,k,neigh,icol_add: working integers
    integer (kind = myint) :: i,j,k,neigh,icol_add

    ! initialise the mask array which is an array that has
    ! value i if column index already exist in row i of
    ! the new matrix
    mask(1:n) = 0
    nz = 0
    do i=1,m
       do j = ia1(i),ia1(i+1)-1
          neigh = ja1(j)
          do k = ia2(neigh),ia2(neigh+1)-1
             icol_add = ja2(k)
             if (mask(icol_add) /= i) then
                nz = nz + 1
                mask(icol_add) = i     ! add mask
             end if
          end do
       end do
    end do
  end subroutine matmul_size


  subroutine matmul_normal(m,n,ia,ja,a,ib,jb,b,ic,jc,c,mask)
    ! calculate the product of two matrix A=(ia,ja,a) and
    ! B = (ib,jb,b).

    ! m: row size of A
    ! n: column size of B
    integer (kind = myint), intent (in) :: n,m

    ! ia: row pointer of A
    ! ja: column indices of A
    ! ib: row pointer of B
    ! jb: column indices of B
    integer (kind = myint), intent (in) :: ia(*),ib(*),ja(*),jb(*)
    ! ic: row pointer of C
    ! jc: column indices of C
    integer (kind = myint), intent (out) :: ic(*),jc(*)
    ! a: entry values of A
    ! b: entry values of B
    ! c: entry values of C
    real (kind = myreal), intent (in) :: a(*),b(*)
    real (kind = myreal), intent (out) :: c(*)
    ! working array
    integer (kind = myint), intent (inout) :: mask(*)
    ! working variables
    integer (kind = myint) :: nz,i,j,k,icol,icol_add,neigh
    real (kind = myreal) :: aij

    ! initialise the mask array which is an array that
    ! has non-zero value if the
    ! column index already exist, in which case
    ! the value is the index of that column
    mask(1:n) = 0
    nz = 0
    ic(1) = 1
    do i=1,m
       do j = ia(i),ia(i+1)-1
          aij = a(j)
          neigh = ja(j)
          do k = ib(neigh),ib(neigh+1)-1
             icol_add = jb(k)
             icol = mask(icol_add)
             if (icol == 0) then
                nz = nz + 1
                jc(nz) = icol_add
                c(nz) =  aij*b(k)
                mask(icol_add) = nz     ! add mask
             else
                c(icol) = c(icol) + aij*b(k)
             end if
          end do
       end do
       do j = ic(i),nz
          ! done this row i, so set mask to zero again
          mask(jc(j)) = 0
       end do
       ic(i+1) = nz+1
    end do
  end subroutine matmul_normal




  subroutine matmul_noval(m,n,ia,ja,ib,jb,ic,jc,mask)
    ! calculate the product of two matrix A=(ia,ja) and
    ! B = (ib,jb). Sparse patterns only is calculated.

    ! m: row size of A
    ! n: column size of B
    integer (kind = myint), intent (in) :: n,m
    ! ia: row pointer of A
    ! ja: column indices of A
    ! ib: row pointer of B
    ! jb: column indices of B
    integer (kind = myint), intent (in) :: ia(*),ib(*),ja(*),jb(*)
    ! ic: row pointer of C
    ! jc: column indices of C
    integer (kind = myint), intent (out) :: ic(*),jc(*)

    ! working array
    integer (kind = myint), intent (inout) :: mask(*)
    ! working variables
    integer (kind = myint) :: nz,i,j,k,icol,icol_add,neigh

    ! initialise the mask array which is an array
    ! that has non-zero value if the
    ! column index already exist, in which case
    ! the value is the index of that column
    mask(1:n) = 0
    nz = 0
    ic(1) = 1
    do i=1,m
       do j = ia(i),ia(i+1)-1
          neigh = ja(j)
          do k = ib(neigh),ib(neigh+1)-1
             icol_add = jb(k)
             icol = mask(icol_add)
             if (icol == 0) then
                nz = nz + 1
                jc(nz) = icol_add
                mask(icol_add) = nz     ! add mask
             else
                cycle
             end if
          end do
       end do
       do j = ic(i),nz
          ! done this row i, so set mask to zero again
          mask(jc(j)) = 0
       end do
       ic(i+1) = nz+1
    end do
  end subroutine matmul_noval

  subroutine csr_matrix_multiply_graph(matrix1,matrix2,&
       result_matrix,info,col_wgt,stat)
    ! subroutine csr_matrix_multiply_graph(matrix1,matrix2,&
    !    result_matrix,info[,col_wgt])
    !
    ! Given two matrix, find
    ! result_matrix = (\bar matrix1)*(\bar matrix2) where
    ! (\bar A) is the matrix A with all non-zero entries set to 1.
    ! The diagonal entries of the result_matrix will be discarded.
    ! the routine is used for finding the row connectivity graph
    ! A, which is (\bar A)*(\bar A)^T, with diagonal elements removed

    ! matrix1: of the derived type ZD11_type, INTENT (IN),
    !         the sparse matrix in compressed sparse row format
    ! matrix2: of the derived type ZD11_type, INTENT (IN),
    !         the sparse matrix in compressed sparse row format
    type (zd11_type), intent (in) :: matrix1,matrix2

    ! result_matrix: of the derived type ZD11_type, INTENT (INOUT)
    !                result_matrix=matrix1*matrix2
    type (zd11_type), intent (inout) :: result_matrix

    ! col_wgt: optional real array of INTENT (IN).
    !          the super-column weight for the columns of
    !          matrix1. this is used when calculating A*A^T
    !          with A having super-columns The effect is the same as
    !          result_matrix =
    !          (\bar matrix1)*DIAG(col_wgt)*(\bar matrix2)
    real (kind = myreal), dimension (matrix1%n), intent (in), &
         optional :: col_wgt

    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed.
    !       = MC65_ERR_MATMULG_DIM_MISMATCH dimension mismatch
    integer (kind = myint), intent (out), optional :: info

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! ================= local variables =================
    ! m: row size of matrix1
    ! n: column size of matrix2
    ! nz: number of nonzeros in the product matrix
    integer (kind = myint) :: n,nz,m

    ! mask: an array with a size the same as the column
    !       size of matrix2, used to indicating whether an
    !       entry in the product has been seen or not.
    integer (kind = myint), allocatable, dimension(:) :: mask

    integer (kind = myint) :: ierr

    info = 0
    if (present(stat)) stat = 0

    m = matrix1%m

    n = matrix2%n

    ! Check if dimensions match
    if ( matrix1%n /= matrix2%m) then
       info = MC65_ERR_MATMULG_DIM_MISMATCH
       return
    end if

    allocate(mask(n), stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
    end if

    ! now find the size
    call matmul_size_graph(m,n,matrix1%ptr,matrix1%col,matrix2%ptr,&
         matrix2%col,nz,mask,info)
    if (info < 0) return

    ! initialise the new matrix
    call csr_matrix_construct(result_matrix,m,nz,info,n = n,&
         type = "general",stat=ierr)
    if (present(stat)) stat = ierr
    if (info < 0) return

    if (present(col_wgt)) then
       call matmul_wgraph(m,n,matrix1%ptr,matrix1%col,matrix2%ptr, &
                  matrix2%col,result_matrix%ptr,result_matrix%col, &
                  result_matrix%val,mask,col_wgt)
    else
       call matmul_graph(m,n,matrix1%ptr,matrix1%col,matrix2%ptr, &
                  matrix2%col,result_matrix%ptr,result_matrix%col, &
                  result_matrix%val,mask)
    end if

    deallocate(mask, stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
       return
    end if

  end subroutine csr_matrix_multiply_graph


  subroutine matmul_size_graph(m,n,ia1,ja1,ia2,ja2,nz,mask,flag)
    ! work out the number of nonzeros in the
    ! product of two matrix A=(ia1,ja1) and B=(ia2,ja2),
    ! diagonal element of A*B is not counted
    ! because this routine is used in finding row graphs.
    ! (a graph is represented as a symm. matrix with no diag. entries)
    ! m: row size of A
    ! n: column size of B
    integer (kind = myint), intent (in) :: n,m
    ! ia1: row pointer of A
    ! ja1: column indices of A
    ! ia2: row pointer of B
    ! ja2: column indices of B
    integer (kind = myint), intent (in), dimension (*) :: &
         ia1,ja1,ia2,ja2
    integer, intent(inout) :: flag

    ! nz: number of nonzeros in the product matrix
    integer (kind = myint), intent (inout) :: nz

    ! mask: working array
    integer (kind = myint), intent (inout) :: mask(*)

    ! i,j,k,neigh,icol_add: working integers
    integer (kind = myint) :: i,j,k,neigh,icol_add

    ! initialise the mask array which is an array that has
    !  value i if column index already exist in row i
    !  of the new matrix
    mask(1:n) = 0
    nz = 0
    do i=1,m
       do j = ia1(i),ia1(i+1)-1
          neigh = ja1(j)
          do k = ia2(neigh),ia2(neigh+1)-1
             icol_add = ja2(k)
             if (icol_add /= i .and. mask(icol_add) /= i) then
                if(nz.eq.huge(nz)) then
                   ! Integer overflow imminent
                   flag = MC65_ERR_SMM_TOO_LARGE
                   return
                endif
                nz = nz + 1
                mask(icol_add) = i     ! add mask
             end if
          end do
       end do
    end do
  end subroutine matmul_size_graph

  subroutine matmul_graph(m,n,ia,ja,ib,jb,ic,jc,c,mask)
    ! given two matrix, A=(ia,ja) and B = (ib,jb), find
    ! C = (\bar A)*(\bar B) where
    ! (\bar A) is the matrix A with all non-zero entries set to 1.
    ! The diagonal entries of the c matrix will be discarded.
    ! the routine is mainly used for finding the row
    ! connectivity graph
    ! of a matrix A, which is (\bar A)*(\bar A)^T
    ! it is assumed that the size of arrays (ic,jc,c)
    ! used to hold C is large enough.

    ! m: row size of A
    ! n: column size of B
    integer (kind = myint), intent (in) :: n,m
    ! ia: row pointer of A
    ! ja: column indices of A
    ! ib: row pointer of B
    ! jb: column indices of B
    integer (kind = myint), intent (in), dimension (*) :: &
         ia,ib,ja,jb
    ! ic: row pointer of C
    ! jc: column indices of C
    integer (kind = myint), intent (out), dimension (*)  :: ic,jc
    ! c: entry values of C
    real (kind = myreal), intent (out), dimension (*)  :: c
    ! working array
    integer (kind = myint), intent (inout) :: mask(*)
    ! working variables
    integer (kind = myint) :: nz,i,j,k,icol,icol_add,neigh

    ! initialise the mask array which is an array
    ! that has non-zero value if the
    ! column index already exist, in which case
    ! the value is the index of that column
    mask(1:n) = 0
    nz = 0
    ic(1) = 1
    do i=1,m
       do j = ia(i),ia(i+1)-1
          neigh = ja(j)
          do k = ib(neigh),ib(neigh+1)-1
             icol_add = jb(k)
             if (icol_add /= i) then ! do not consider diagonal
                icol = mask(icol_add)
                if (icol == 0) then
                   nz = nz + 1
                   jc(nz) = icol_add
                   c(nz) =  1.0_myreal
                   mask(icol_add) = nz     ! add mask
                else
                   c(icol) = c(icol) + 1.0_myreal
                end if
             end if
          end do
       end do
       do j = ic(i),nz
          ! done this row i, so set mask to zero again
          mask(jc(j)) = 0
       end do
       ic(i+1) = nz+1
    end do
  end subroutine matmul_graph


  subroutine matmul_wgraph(m,n,ia,ja,ib,jb,ic,jc,c,mask,col_wgt)
    ! given two matrix, find
    ! C = (\bar A)*W*(\bar B) where
    ! (\bar A) is the matrix A, with all non-zero entries set to 1.
    ! W is a diagonal matrix consists of the column weights of A
    ! The diagonal entries of the c matrix will be discarded.
    ! the routine is mainly used for finding the
    ! row connectivity graph of
    ! a matrix A with column weights, which is (\bar A)*W*(\bar A)^T
    ! it is assumed that the size of arrays (ic,jc,c)
    ! used to hold C is large enough.

    ! m: row size of A
    ! n: column size of B
    integer (kind = myint), intent (in) :: n,m

    ! ia: row pointer of A
    ! ja: column indices of A
    ! ib: row pointer of B
    ! jb: column indices of B
    integer (kind = myint), intent (in), dimension (*) :: &
         ia,ib,ja,jb
    ! col_wgt: the column weight, or the diagonal matrix W
    real(kind = myreal), intent (in), dimension (*) :: col_wgt
    ! ic: row pointer of C
    ! jc: column indices of C
    integer (kind = myint), intent (out), dimension (*)  :: ic,jc
    ! c: entry values of C
    real (kind = myreal), intent (out), dimension (*)  :: c
    ! working array
    integer (kind = myint), intent (inout) :: mask(*)
    ! working variables
    integer (kind = myint) :: nz,i,j,k,icol,icol_add,neigh

    ! initialise the mask array which is an array
    ! that has non-zero value if the
    ! column index already exist, in which case
    ! the value is the index of that column
    mask(1:n) = 0
    nz = 0
    ic(1) = 1
    do i=1,m
       do j = ia(i),ia(i+1)-1
          neigh = ja(j)
          do k = ib(neigh),ib(neigh+1)-1
             icol_add = jb(k)
             if (icol_add /= i) then ! do not consider diagonal
                icol = mask(icol_add)
                if (icol == 0) then
                   nz = nz + 1
                   jc(nz) = icol_add
                   c(nz) =  col_wgt(neigh)
                   mask(icol_add) = nz     ! add mask
                else
                   c(icol) = c(icol) + col_wgt(neigh)
                end if
             end if
          end do
       end do
       do j = ic(i),nz
          ! done this row i, so set mask to zero again
          mask(jc(j)) = 0
       end do
       ic(i+1) = nz+1
    end do
  end subroutine matmul_wgraph



  subroutine csr_matrix_multiply_rvector(matrix,x,y,info,trans)
    ! subroutine csr_matrix_multiply_rvector(matrix,x,y,info)
    !
    ! y = matrix*x where x and y are real vectors. Dimension of y
    ! is checked and returned if it is smaller than the row dimension
    ! of x
    !
    ! if trans is present and == 1;
    ! y = matrix^T*x where x and y are real vectors.


    ! matrix: of the derived type ZD11_type, INTENT (IN),
    !         the sparse matrix in compressed sparse row format
    type (zd11_type), intent (in) :: matrix

    ! x: real array of intent (IN), a vector to be multiplied
    !    with the matrix
    real (kind = myreal), intent (in), dimension (*) :: x

    ! y: real array of intent (OUT), the result of matrix*x
    !    or matrix^T*x
    real (kind = myreal), intent (out), dimension (*) :: y

    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MATVEC_NOVALUE, &  if A is of type
    !         pattern only and x real.
    integer (kind = myint), intent (out) :: info

    ! trans: optional logical scalar. If present and trans = true,
    ! the transpose of the matrix is multiplied with the vector
    logical, optional, intent (in) :: trans
    ! ========================local variables=======================
    integer (kind = myint) :: m,i,l1,l2,j,n,jc
    real (kind = myreal) :: xx
    ! transpose: whether it is a matrix transpose multiplying a vector
    logical :: transpose

    transpose = .false.

    if (present(trans)) then
       if (trans) transpose = .true.
    end if

    info = 0

    m = matrix%m
    n = matrix%n

    if (ZD11_get(matrix%type) == "pattern") then
       info = MC65_ERR_MATVEC_NOVALUE
       return
    end if
    if (transpose) then
       y(1:n) = 0
       do i = 1, m
          xx = x(i)
          do j = matrix%ptr(i),matrix%ptr(i+1)-1
             jc = matrix%col(j)
             y(jc) = y(jc) + matrix%val(j)*xx
          end do
       end do
    else
       do i = 1, m
          l1 = matrix%ptr(i)
          l2 = matrix%ptr(i+1)-1
          y(i) = dot_product(matrix%val(l1:l2),x(matrix%col(l1:l2)))
       end do
    end if

  end subroutine csr_matrix_multiply_rvector


  subroutine csr_matrix_multiply_ivector(matrix,x,y,info,trans)
    ! subroutine csr_matrix_multiply_ivector(matrix,x,y,info)
    !
    ! y = matrix*x where x and y are integer vectors. Entries of
    ! matrix is assumed to be one. Dimension of y
    ! is checked and returned if it is smaller than the row dimension
    ! of x
    !
    ! if trans is present and == 1;
    ! y = matrix^T*x where x and y are integers and entries of
    ! the matrix are assumed to have the values one.

    ! matrix: of the derived type ZD11_type, INTENT (IN),
    !         the sparse matrix in compressed sparse row format
    type (zd11_type), intent (in) :: matrix

    ! x: integer array of intent (IN), a vector to be
    !    multiplied with the matrix
    integer (kind = myint), intent (in), dimension (*) :: x

    ! y: integer array of intent (OUT), the result of
    !    matrix*x or matrix^T*x
    integer (kind = myint), intent (out), dimension (*) :: y

    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    integer (kind = myint), intent (out) :: info

    ! trans: optional integer scalar. If present and trans = true,
    ! transpose of the matrix is multiplied with the vector
    logical, optional, intent (in) :: trans

    ! local ==========
    integer (kind = myint) :: m,n,i,l1,l2,j,xx,jc
    ! transpose: whether it is a matrix transpose
    !   multiplying a vector
    logical :: transpose


    info = 0

    transpose = .false.

    if (present(trans)) then
       if (trans) transpose = .true.
    end if

    m = matrix%m
    n = matrix%n

    if (transpose) then
       y(1:n) = 0
       do i = 1, m
          xx = x(i)
          do j = matrix%ptr(i),matrix%ptr(i+1)-1
             jc = matrix%col(j)
             y(jc) = y(jc) + xx
          end do
       end do
    else
       do i = 1, m
          l1 = matrix%ptr(i)
          l2 = matrix%ptr(i+1)-1
          y(i) = sum(x(matrix%col(l1:l2)))
       end do
    end if
  end subroutine csr_matrix_multiply_ivector

  subroutine csr_to_csr_matrix(matrix,m,n,ptr,col,&
       info,val,type,checking,stat)
    !   subroutine csr_to_csr_matrix(matrix,m,n,ptr,col,
    !      info[,val,type,copying,checking])
    ! convert ptr, col and a arrays into the compressed sparse row
    ! matrix format. New storage is allocated for MATRIX and
    ! the content of ptr,col (and val) is copied into MATRIX.

    ! m: is an integer of intent (in).
    !    It is the row dimension of the sparse matrix
    ! n: is an integer of intent (in).
    !    It is the column dimension of the sparse matrix
    integer (kind = myint), intent (in) :: m,n

    ! MATRIX: is of the derived type {\tt ZD11\_type}
    !     with {\tt INTENT (INOUT)},
    type (zd11_type), intent (inout) :: matrix

    ! ptr: is an integer array of intent (in) of size M+1.
    !     It is the row pointer of the sparse matrix.
    ! col: is an integer array of intent (in) of size ptr(m+1)-1.
    !     It is the array of column indices.
    integer (kind = myint), INTENT (IN)  :: ptr(m+1), col(ptr(m+1)-1)


    ! info: integer scaler of INTENT (OUT).
    !       = 0 if successful
    !       = MC65_ERR_MEMORY_ALLOC if memory allocation fails.
    !       = MC65_ERR_MEMORY_deALLOC if memory deallocation fails.
    !       = MC65_ERR_RANGE_PTR if PTR(1:M+1) is not
    !         monotonically increasing
    !       = MC65_WARN_RANGE_COL: COL is not within the
    !         range of [1,n], such entries are removed
    !       = MC65_WARN_DUP_ENTRY: duplicate entries were
    !         found when cleaning the matrix and were summed
    integer (kind = myint), intent (out) :: info

    ! val: is an optional REAL array of intent (in) of
    !    size ptr(m+1)-1.
    !    It holds the entry values of the sparse matrix.
    !    If this argument is not present, the matrix is
    !    taken as pattern only.
    real (kind = myreal),  INTENT (IN), optional :: val(ptr(m+1)-1)


    ! type: an optional character array of intent (IN).
    !       If both type and A is present,
    !       the type of the MATRIX will be set as TYPE.
    !
    character (len = *), INTENT (IN), OPTIONAL :: type


    ! checking: is an optional integer scaler of INTENT (IN).
    !           If present and is
    !           1: the input data will be checked for consistency,
    !              the matrix will be cleaned by merging duplicate
    !              entries. If a column index is out of range,
    !              the entry will be excluded in the construction
    !              of the matrix.
    !              A warning will be recorded.
    !           < 0: no checking or cleaning is done
    !           Other values: current not used and has the
    !           same effect 1
    integer (kind = myint), parameter :: CHECK_RMV = 1
    integer (kind = myint), optional, INTENT (IN) :: checking

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat


    integer (kind = myint) :: nz,nzz,i,j,icol,ierr


    ! whether the matrix is pattern only
    logical :: pattern_only

    ! whether to check input data
    integer (kind = myint) :: to_check

    nzz = ptr(m+1)-1

    info = 0
    if (present(stat)) stat = 0
    to_check = 0
    if (present(checking)) then
       if (checking == CHECK_RMV) then
          to_check = CHECK_RMV
       else if (checking >= 0) then
          to_check = CHECK_RMV
       end if
    end if


    pattern_only = .true.
    if (present(val)) then
       pattern_only = .false.
       if (present(type)) then
          if (len_trim(type)>=7) then
             if (type(1:7) == "pattern".or.type(1:7) == "PATTERN") &
                  pattern_only = .true.
          end if
       end if
    end if

    if (to_check == CHECK_RMV) then
       do i = 1,m
          if (ptr(i) > ptr(i+1)) then
             info = MC65_ERR_RANGE_PTR
             return
          end if
       end do
       nz = 0
       do i = 1, nzz
          if (col(i) <= n.and.col(i) >= 1) then
             nz = nz + 1
          end if
       end do
    else
       nz = nzz
    end if


    if (pattern_only) then
       call csr_matrix_construct(matrix,m,nz,info,n = n,&
             type = "pattern",stat=ierr)
    else
       if (present(type)) then
          call csr_matrix_construct(matrix,m,nz,info,n = n,&
               type = type,stat=ierr)
       else
          call csr_matrix_construct(matrix,m,nz,info,n = n,&
               type = "general",stat=ierr)
       end if
    end if
    if (present(stat)) stat = ierr
    if (info < 0) return

    ! column index outside the range
    matrix%ptr(1) = 1
    if (nz /= nzz.and.to_check == CHECK_RMV) then
       nz = 1
       if (.not.pattern_only) then
          do i = 1, m
             do j = ptr(i), ptr(i+1)-1
                icol = col(j)
                if (icol >= 1.and.icol <= n) then
                   matrix%col(nz) = icol
                   matrix%val(nz) = val(j)
                   nz = nz + 1
                end if
             end do
             matrix%ptr(i+1) = nz
          end do
       else
          do i = 1, m
             do j = ptr(i), ptr(i+1)-1
                icol = col(j)
                if (icol >= 1.and.icol <= n) then
                   matrix%col(nz) = icol
                   nz = nz + 1
                end if
             end do
             matrix%ptr(i+1) = nz
          end do
       end if
       call csr_matrix_clean(matrix,info,stat=ierr)
       if (present(stat)) stat = ierr
       if (info < 0) return
       ! only set info for COL out of range, since info is reset when
       ! calling csr_matrix_construct or csr_matrix_clean
       if (info == MC65_WARN_DUP_ENTRY) then
          info = MC65_WARN_ENTRIES
       else
          info =  MC65_WARN_RANGE_COL
       end if
    else if (to_check == CHECK_RMV) then
       ! column index not outside the range but cleaning is needed
       matrix%ptr(1:m+1) = ptr(1:m+1)
       matrix%col(1:nz) = col(1:nz)
       if (.not.pattern_only) matrix%val(1:nz) = val(1:nz)
       call csr_matrix_clean(matrix,info,stat=ierr)
       if (present(stat)) stat = ierr
    else
       matrix%ptr(1:M+1) = ptr(1:m+1)
       matrix%col(1:nz) = col(1:nz)
       if (.not.pattern_only) matrix%val(1:nz) = val(1:nz)
    end if


  end subroutine csr_to_csr_matrix


  subroutine coo_to_csr_format(matrix,m,n,nz,irn,jcn,&
       info,val,type,checking,stat)
    !
    ! convert coordinate format (irn,jcn,val) to CSR matrix format

    ! matrix:  is of the derived type {\tt ZD11\_type}
    !          with {\tt INTENT (INOUT)}. It is
    !          the sparse matrix to be generated from the
    !          coordinated formatted
    !          input data.
    ! m: is an INTEGER scaler of INTENT (IN). It holds the row size
    ! n: is an INTEGER scaler of INTENT (IN). It holds the
    !    column size
    ! nz:  is an INTEGER scaler. It holds the number of
    !      nonzeros in the sparse matrix
    ! irn: is an INTEGER ARRAY with INTENT (IN), of size = NZ.
    !      It holds the row indices of the matrix
    ! jcn:  is an INTEGER ARRAY with INTENT (IN), of size = NZ.
    !       It holds column indices of the matrix
    ! info:  is an {\tt INTEGER} scaler of {\tt INTENT (OUT)}.
    !       INFO = 0 if the subroutine completes successful
    !       INFO = MC65_ERR_MEMORY_ALLOC if memory allocation failed.
    !       INFO = MC65_ERR_MEMORY_DEALLOC if memory
    !              deallocation failed.
    !       {\tt INFO = MC65\_WARN\_RANGE\_IRN} if {\tt IRN}
    !           is not within the
    !           range of {\tt [1,M]}. Related entries excluded
    !       {\tt INFO = MC65\_WARN\_RANGE\_JCN} if {\tt JCN}
    !           is not within the
    !           range of {\tt [1,N]}. Related entries excluded
    !       INDO = MC65_WARN_DUP_ENTRY: duplicate entries were
    !              found when cleaning the matrix
    !              and were summed
    ! val:  is an optional REAL (double precision REAL for
    !       HSL_MC65_double)
    !       ARRAY  with INTENT (IN), of size = NZ.
    !       It holds entry values of the matrix
    integer (kind=myint), intent (in) :: m, n, nz
    type (zd11_type), intent (inout) :: matrix
    integer (kind=myint), intent (in) :: irn(nz)
    integer (kind=myint), intent (in) :: jcn(nz)
    integer (kind=myint), intent (out) :: info
    real (kind = myreal), intent (in), optional :: val(nz)

    ! type: is an OPTIONAL CHARACTER array of unspecified
    !       size with INTENT (IN).
    !       If both val and type are present,
    !       the type of the MATRIX will be set as type.
    character (len=*), intent (in), optional :: type

    ! checking: is an optional integer scaler of INTENT (IN).
    !           If present and is
    !           1: the input data will be checked for consistency,
    !              the matrix will be cleaned by merging duplicate
    !              entries.
    !              If a column index is out of range, the entry will
    !              be excluded in the construction of the matrix.
    !              A warning will be recorded.
    !           < 0: no checking or cleaning is done
    !              Other values: current not used and has the same
    !              effect as 1
    integer (kind = myint), parameter :: CHECK_RMV = 1
    integer (kind = myint), optional, INTENT (IN) :: checking

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! nzz: actual number of nonzero

    integer (kind=myint) :: ierr,nzz,i
    integer (kind = myint), dimension (:), allocatable :: nrow,iia

    ! whether the matrix is pattern only
    logical :: pattern_only

    ! whether to check input data. 0 not, /= 0 yes
    integer (kind = myint) :: to_check

    logical irn_out_range,jcn_out_range

    irn_out_range = .false.
    jcn_out_range = .false.

    info = 0
    if (present(stat)) stat = 0
    to_check = 0
    if (present(checking)) then
       if (checking == CHECK_RMV) then
          to_check = CHECK_RMV
       else if (checking >= 0) then
          to_check = CHECK_RMV
       end if
    end if

    pattern_only = .true.
    if (present(val)) then
       pattern_only = .false.
       if (present(type)) then
          if (len_trim(type)>=7) then
             if (type(1:7) == "pattern".or.type(1:7) == "PATTERN") &
                  pattern_only = .true.
          end if
       end if
    end if

    if (to_check == CHECK_RMV) then
       nzz = 0
       do i = 1, nz
          if (jcn(i) <= n.and.jcn(i) >= 1) then
             if (irn(i) <= m.and.irn(i) >= 1) then
                nzz = nzz + 1
             else
                irn_out_range = .true.
             end if
          else
             jcn_out_range = .true.
          end if
       end do
    else
       nzz = nz
    end if

    if (pattern_only) then
       call csr_matrix_construct(matrix,m,nzz,info,n = n,&
            type = "pattern",stat=ierr)
    else
       if (present(type)) then
          call csr_matrix_construct(matrix,m,nzz,info,n = n,&
               type = type,stat=ierr)
       else
          call csr_matrix_construct(matrix,m,nzz,info,n = n,&
               type = "general",stat=ierr)
       end if
    end if
    if (present(stat)) stat = ierr
    if (info < 0) return

    allocate(nrow(m),iia(m+1), stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_ALLOC
       return
    end if

    if (pattern_only) then
       call coo_to_csr_private(to_check,m,n,nz,irn,jcn,matrix%ptr,matrix%col,&
            nrow,iia,pattern_only)
    else
       call coo_to_csr_private(to_check,m,n,nz,irn,jcn,matrix%ptr,matrix%col,&
            nrow,iia,pattern_only,val = val,a = matrix%val)
    end if

    deallocate(nrow, iia, stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       info = MC65_ERR_MEMORY_DEALLOC
       return
    end if

    if (to_check == CHECK_RMV) then
       call csr_matrix_clean(matrix,info,stat=ierr)
       if (present(stat)) stat = ierr
       if (info < 0) return
       if (irn_out_range .and. info==MC65_WARN_DUP_ENTRY) then
          info = MC65_WARN_ENTRIES
          return
       end if
       if (jcn_out_range .and. info==MC65_WARN_DUP_ENTRY) then
          info = MC65_WARN_ENTRIES
          return
       end if
       if (irn_out_range) info = MC65_WARN_RANGE_IRN
       if (jcn_out_range) info = MC65_WARN_RANGE_JCN
       if (irn_out_range .and. jcn_out_range) info = MC65_WARN_RANGE_BOTH
    end if

  end subroutine coo_to_csr_format


  subroutine coo_to_csr_private(to_check,m,n,nz,irn,jcn,ia,ja,&
       nrow,iia,pattern_only,val,a)
    ! wrapper routine for coo_to_csr_format for performance
    ! to_check: whether to check input data. 0 not, /= 0 yes
    ! m,n: row/column dimension
    ! ia: row pointer
    ! ja: column pointer
    ! nrow: number of entries in a row
    ! iia: row pointer
    ! a: entry values
    integer (kind = myint) :: to_check
    integer (kind = myint), intent (in) :: n,m,nz,irn(*),jcn(*)
    integer (kind = myint), intent (out) :: ia(*),ja(*),nrow(*),iia(*)
    real (kind = myreal), intent (OUT), optional :: a(*)
    real (kind = myreal), intent (IN), optional :: val(*)
    logical :: pattern_only

    integer (kind=myint) :: i
    integer (kind = myint) :: ii,jj

    if (to_check == 0) then
       nrow(1:m) = 0
       do i = 1, nz
          nrow(irn(i)) = nrow(irn(i)) + 1
       end do
       ia (1) = 1
       do i = 1, m
          ia(i+1) = ia(i) + nrow(i)
       end do

       iia(1:m+1) = ia(1:m+1)
       if (pattern_only) then
          do i = 1, nz
             ii = irn(i)
             jj = jcn (i)
             ja(iia(ii)) = jj
             iia(ii) = iia(ii) + 1
          end do
       else
          do i = 1, nz
             ii = irn(i)
             jj = jcn (i)
             ja(iia(ii)) = jj
             a(iia(ii)) = val(i)
             iia(ii) = iia(ii) + 1
          end do
       end if
    else
       ! checking range, exclude out of range entries
       nrow(1:m) = 0
       do i = 1, nz
          ii = irn(i)
          jj = jcn(i)
          if (ii >= 1.and.ii <= m.and.jj >= 1.and.jj <= n) &
               nrow(ii) = nrow(ii) + 1
       end do
       ia (1) = 1
       do i = 1, m
          ia(i+1) = ia(i) + nrow(i)
       end do

       iia(1:m+1) = ia(1:m+1)
       if (pattern_only) then
          do i = 1, nz
             ii = irn(i)
             jj = jcn (i)
             if (ii >= 1.and.ii <= m.and.jj >= 1.and.jj <= n) then
                ja(iia(ii)) = jj
                iia(ii) = iia(ii) + 1
             end if
          end do
       else
          do i = 1, nz
             ii = irn(i)
             jj = jcn (i)
             if (ii >= 1.and.ii <= m.and.jj >= 1.and.jj <= n) then
                ja(iia(ii)) = jj
                a(iia(ii)) = val(i)
                iia(ii) = iia(ii) + 1
             end if
          end do
       end if
    end if
  end subroutine coo_to_csr_private


  subroutine csr_matrix_to_coo(matrix,m,n,nz,irn,jcn,info,val,stat)
    ! convert the ZD11_type matrix format to coordinate form.
    ! Storage space for the array pointers  {\tt IRN},
    ! {\tt JCN} and {\tt VAL}
    ! are allocated inside the subroutine, and should be deallocated
    ! by the user once these array pointers are no longer used.
    ! being used. When the matrix is of type "pattern"
    ! and VAL is present, VAL will be allocated a size of 0.

    ! matrix:  is of the derived type {\tt ZD11\_TYPE} with
    !   {\tt INTENT (IN)}.
    type (zd11_type), intent (in) :: MATRIX

    ! m: is an INTEGER scaler of INTENT (OUT). It is the row
    !    dimension
    ! n: is an INTEGER scaler of INTENT (OUT). It is the column
    !    dimension
    ! nz: is an INTEGER scaler of INTENT (OUT). It is the number
    !    of nonzeros
    integer (kind = myint), intent (out) :: m,n,nz

    ! irn: is an INTEGER allocatable array. It holds the row indices
    ! jcn:  is an INTEGER allocatable array. It holds the column indices
    ! val:  is an OPTIONAL INTEGER allocatable array. When present,
    !       and the matrix is not of type "pattern", VAL holds
    !       the entry values
    !       when present and the matrix is of type "pattern"
    !       VAL will be allocated a size of 0.
    integer (kind = myint), allocatable :: irn(:)
    integer (kind = myint), allocatable :: jcn(:)
    real (kind = myreal), optional, allocatable :: val(:)

    ! info:  is an {\tt INTEGER} scaler of {\tt INTENT (OUT)}.
    !       INFO = 0 if the subroutine completes successful
    !       INFO = MC65_ERR_MEMORY_ALLOC if memory allocation failed.
    integer (kind = myint), intent (out) :: info

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    ! working integers
    integer (kind = myint) :: ierr

    ! pattern_only: whether the matrix is pattern only
    ! entry_values: whether val array is to be allocated and filled
    logical :: pattern_only,entry_values

    info = 0
    if (present(stat)) stat = 0
    pattern_only = .false.
    entry_values = .false.
    if (ZD11_get(matrix%type) == "pattern") pattern_only = .true.
    if ((.not.pattern_only).and.present(val)) entry_values = .true.

    m = matrix%m
    n = matrix%n

    nz = matrix%ptr(m+1)-1

    if (nz < 0) return
    if (entry_values) then
       allocate (irn(1:nz),jcn(1:nz),val(1:nz),stat = ierr)
    else
       allocate (irn(1:nz),jcn(1:nz),stat = ierr)
       IF (PRESENT(VAL)) allocate(val(0),stat = ierr)
    end if
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       INFO = MC65_ERR_MEMORY_ALLOC
       return
    end if

    if (entry_values) then
       call csr_matrix_to_coo_private(m,nz,matrix%ptr,matrix%col,irn,jcn, &
                                      matrix%val,val)
    else
       call csr_matrix_to_coo_private(m,nz,matrix%ptr,matrix%col,irn,jcn)
    end if

  end subroutine csr_matrix_to_coo

  subroutine csr_matrix_to_coo_private(m,nz,ia,ja,irn,jcn,a,val)
    ! private wrapper routine called by csr_matrix_to_coo
    ! for efficient
    !
    ! m: row dimension
    ! nz: number of nonzeros
    ! ia: row pointer
    ! ja: column indices
    ! a: entry values, optional
    ! irn: row indices
    ! jcn: column indices
    ! val: entry values, optional
    integer (kind = myint), intent (in) :: m
    integer (kind = myint), intent (out) :: nz
    integer (kind = myint), dimension (*), intent (in) :: ia,ja
    real (kind = myreal), dimension (*), intent (in), optional :: a
    integer (kind = myint), dimension (*), intent (out) :: irn,jcn
    real (kind = myreal), dimension (*), intent (out), optional :: val

    integer (kind = myint) :: i,n1,i1,i2


    nz = 1
    if (present(a)) then
       do i=1,m
          i1 = ia(i)
          i2 = ia(i+1)-1
          n1 = i2-i1+1
          irn(nz:nz+n1-1) = i
          jcn(nz:nz+n1-1) = ja(i1:i2)
          val(nz:nz+n1-1) = a(i1:i2)
          nz = nz + n1
       end do
    else
       do i=1,m
          i1 = ia(i)
          i2 = ia(i+1)-1
          n1 = i2-i1+1
          irn(nz:nz+n1-1) = i
          jcn(nz:nz+n1-1) = ja(i1:i2)
          nz = nz + n1
       end do
    end if
    nz = nz -1
  end subroutine csr_matrix_to_coo_private

  subroutine csr_matrix_remove_diagonal(matrix)
    ! remove the diagonal entry of a matrix. This is used when
    ! the matrix represents a graph and there should not be
    ! diagonals in such a matrix

    ! matrix: is of the derived type {\tt ZD11\_TYPE} with
    !         {\tt INTENT (INOUT)}.
    !         It is the matrix whose diagonal is to be removed
    type (zd11_type), intent (inout) :: matrix

    ! m: row dimension
    integer (kind = myint) :: m

    m = matrix%m
    if (ZD11_get(matrix%type) /= "pattern" ) then
       call csr_matrix_remove_diag_private(m,matrix%ptr,matrix%col,matrix%val)
    else
       call csr_matrix_remove_diag_private(m,matrix%ptr,matrix%col)
    end if
  end subroutine csr_matrix_remove_diagonal

  subroutine csr_matrix_remove_diag_private(m,ia,ja,a)
    ! private  subroutine called by csr_matrix_remove_diag
    ! for performance reason
    !
    ! m: row dimension
    ! ia: row pointer
    ! ja: column indices
    ! a: entry values
    integer (kind = myint), intent (in) :: m
    integer (kind = myint), intent (inout) :: ia(*),ja(*)
    real (kind = myreal), optional, intent (inout) :: a(*)

    integer (kind = myint) :: i,j,l1,nz


    nz = 1
    l1 = 1
    if (present(a)) then
       do i = 1, m
          do j = l1, ia(i+1) - 1
             if (ja(j) /= i) then
                ja(nz) = ja(j)
                a(nz) = a(j)
                nz = nz + 1
             end if
          end do
          l1 = ia(i+1)
          ia(i+1) = nz
       end do
    else
       do i = 1, m
          do j = l1, ia(i+1) - 1
             if (ja(j) /= i) then
                ja(nz) = ja(j)
                nz = nz + 1
             end if
          end do
          l1 = ia(i+1)
          ia(i+1) = nz
       end do
    end if
  end subroutine csr_matrix_remove_diag_private


  subroutine csr_matrix_diagonal_first(matrix,info)
    ! subroutine csr_matrix_diagonal_first(matrix,info)
    !
    ! changes the storage arrange so that the diagonal of
    ! row i of the matrix is always
    ! at position matrix%ptr(i) of the matrix%col and matrix%val
    !    arrays

    ! matrix:  is of the derived type {\tt ZD11\_TYPE} with
    !    {\tt INTENT (INOUT)}.
    type (zd11_type), intent (inout) :: matrix

    ! INFO: an INTEGER scaler of INTENT (OUT).
    !       INFO = 0 if the subroutine completes successfully; and
    !       INFO = MC65_WARN_MV_DIAG_MISSING if some diagonal
    !       elements are missing.
    integer (kind = myint), intent (OUT) :: info

    integer (kind = myint) :: m

    info = 0

    m = matrix%m
    if (zd11_get(matrix%type) == "pattern") then
       call csr_matrix_diagonal_first_priv(m,matrix%ptr,matrix%col,info)
    else
       call csr_matrix_diagonal_first_priv(m,matrix%ptr,matrix%col,info, &
                                           matrix%val)
    end if
  end subroutine csr_matrix_diagonal_first

  subroutine csr_matrix_diagonal_first_priv(m,ia,ja,info,a)
    ! private routine for csr_matrix_diagonal_first for efficiency

    ! ia: row pointer to matrix
    ! ja: column indices
    integer (kind = myint), dimension (*), intent (inout) :: ia,ja
    ! a: entry values
    real (kind = myreal), dimension (*), intent (inout), optional :: a

    integer (kind = myint) :: m,i,j,jdiag,jf,info
    real (kind = myreal) :: tmp

    if (present(a)) then
       do i=1,m
          jdiag = -1
          jf = ia(i)
          do j = jf,ia(i+1)-1
             if (ja(j) == i) then
                jdiag = j
                exit
             end if
          end do
          if (jdiag < 0) then
             INFO = MC65_WARN_MV_DIAG_MISSING
             cycle
          end if
          ! swap the j-th and the jdiag-th entry in the row
          tmp = a(jdiag)
          a(jdiag) = a(jf)
          a(jf) = tmp
          ja(jdiag) = ja(jf)
          ja(jf) = i
       end do
    else
       do i=1,m
          jdiag = -1
          jf = ia(i)
          do j = jf,ia(i+1)-1
             if (ja(j) == i) then
                jdiag = j
                exit
             end if
          end do
          if (jdiag < 0) then
             INFO = MC65_WARN_MV_DIAG_MISSING
             cycle
          end if
          ja(jdiag) = ja(jf)
          ja(jf) = i
       end do
    end if
  end subroutine csr_matrix_diagonal_first_priv


  subroutine csr_matrix_write(matrix,file_name,info,form,row_ord,&
       col_ord,stat)
    ! write the matrix in the file <file_name> with
    ! various <form>. If row_ord or/and col_ord is present,
    ! the reordered matrix will be written
    !  (unless form = "unformatted"
    ! or form = "hypergraph", in which case no reordering will
    !  take place).

    ! matrix: is of the derived type {\tt ZD11\_TYPE} with
    !         {\tt INTENT (IN)}.
    !         It is the matrix to be written.
    type (zd11_type), intent (in) :: matrix

    ! file_name: is a CHARACTER array of assumed size with
    !   {\tt INTENT (IN)}.
    ! It is the file to write the matrix in.
    character (len = *), intent (in) :: file_name

    ! form: an OPTIONAL CHARACTER array of assumed size with
    !         {\tt INTENT (IN)}. It
    !         is the format in which the matrix is to be written.
    !         Not supplying <form>
    !         or a <form> that is not one of the following strings
    !         has the effect of
    !         form = "ija".
    !         In the follow let M, N and NZ be the row, column
    !         indices and the number of entries in the matrix.
    !         TYPE be the type of the matrix as a character array
    !         with trailing blanks removed.
    !         LEN_TYPE be the string length of TYPE.
    ! form =
    !       "gnuplot": the matrix is written in <file_name> and
    !                the gnuplot command in <file_name.com>,
    !                then in gnuplot, you can type
    !                "load 'file_name'" to view the matrix
    !       "hypergraph": the matrix is written in <file_name>
    !                 in hypergraph format.
    !                       N,M
    !                       row_indices_of_column_1
    !                       row_indices_of_column_2
    !                       row_indices_of_column_3
    !                       ...
    !
    !
    !       "unformatted": the matrix is written in <file_name>
    !            as unformatted data:
    !                         LEN_TYPE
    !                         TYPE
    !                         M N NZ
    !                         row_pointers
    !                         column_indices
    !                         entry_values (Only if the matrix is
    !                         not of type "pattern")
    !
    !       "ij": the matrix is written in <file_name> in
    !             coordinate format,
    !             with only row and column indices. That is
    !                         M N NZ
    !                         ....
    !                         a_row_index a_column_index
    !                         another_row_index another_column_index
    !                         ...
    !
    !       "ija" or "coordinate": the matrix is written in
    !              <file_name> in coordinate format.
    !              Note that entry values will be written only
    !              if the matrix is
    !              not of type "pattern"
    !               M N NZ
    !               ....
    !               row_index column_index a(row_index,column_index)
    !               ....
    !
    character (len = *), intent (in), optional :: form

    ! INFO: an INTEGER of INTENT (OUT).
    !       INFO = 0 if the subroutine completes successfully
    !       INFO = MC65_ERR_NO_VACANT_UNIT if no vacant unit has
    !              been found
    !              in MC65_MATRIX_WRITE
    !       INFO = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       INFO = MC65_ERR_MEMORY_DEALLOC if memory
    !              deallocation failed
    INTEGER (KIND = MYINT), INTENT (OUT) :: INFO

    ! row_ord: is an OPTIONAL INTEGER array of size M with
    !          INTENT (IN). When present, a row index
    !          I will become ROW_ORD(I) in the reordered
    !          matrix.
    ! col_ord:  is an OPTIONAL INTEGER array of size N with
    !          INTENT (IN). When present, a column index
    !          I will become COL_ORD(I) in the reordered
    !          matrix.
    integer (kind = myint), dimension (matrix%m), intent (in), &
         optional :: row_ord
    integer (kind = myint), dimension (matrix%n), intent (in), &
         optional :: col_ord

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat


    ! =============== local variables ==============

    ! pattern_only: whether the matrix is of type "pattern"
    logical :: pattern_only

    integer (kind = myint) :: m,n,nz,ierr

    if (zd11_get(matrix%type) == "pattern") then
       pattern_only = .true.
    else
       pattern_only = .false.
    end if

    info = 0;
    if (present(stat)) stat = 0

    m = matrix%m
    n = matrix%n
    nz = matrix%ptr(m+1)-1

    if (.not.present(form)) then
       goto 10
    else if (form == "gnuplot".or.form == "GNUPLOT") then
       if (present(row_ord).and.present(col_ord)) then
          call csr_matrix_write_gnuplot(file_name,m,n,matrix%ptr,matrix%col,&
               info,row_ord,col_ord)
       else if (present(row_ord)) then
          call csr_matrix_write_gnuplot(file_name,m,n,matrix%ptr,matrix%col,&
               info,row_ord = row_ord)
       else if (present(col_ord)) then
          call csr_matrix_write_gnuplot(file_name,m,n,matrix%ptr,matrix%col,&
               info,col_ord = col_ord)
       else
          call csr_matrix_write_gnuplot(file_name,m,n,matrix%ptr,matrix%col,&
               info)
       end if
       return
    else if (form == "hypergraph" .or. form == "HYPERGRAPH") then
       call csr_matrix_write_hypergraph(matrix,file_name,info,stat=ierr)
       if (present(stat)) stat = ierr
       return
    else if (form == "unformatted".or.form == "UNFORMATTED") then
       if (pattern_only) then
          call csr_matrix_write_unformatted(file_name,m,n,nz,&
               matrix%type,matrix%ptr,matrix%col,info)
       else
          call csr_matrix_write_unformatted(file_name,m,n,nz,&
               matrix%type,matrix%ptr,matrix%col,info,matrix%val)
       end if
       return
    else if (form == "ij".or.form == "IJ") then
       pattern_only = .true.
       goto 10
    else if (form == "ija".or.form == "coordinate".or.&
         form == "IJA".or.form == "COORDINATE") then
    end if

10  if (pattern_only) then
       if (present(row_ord).and.present(col_ord)) then
          CALL CSR_MATRIX_WRITE_ija(file_name,m,n,nz,matrix%ptr,matrix%col, &
                   info,row_ord = row_ord,col_ord = col_ord)
       else if (present(row_ord)) then
          CALL CSR_MATRIX_WRITE_ija(file_name,m,n,nz,matrix%ptr,matrix%col, &
                   info,row_ord = row_ord)
       else if (present(col_ord)) then
          CALL CSR_MATRIX_WRITE_ija(file_name,m,n,nz,matrix%ptr,matrix%col, &
                   info,col_ord = col_ord)
       else
          CALL CSR_MATRIX_WRITE_ija(file_name,m,n,nz,matrix%ptr,matrix%col, &
                   info)
       end if
    else
       if (present(row_ord).and.present(col_ord)) then
          CALL CSR_MATRIX_WRITE_ija(file_name,m,n,nz,matrix%ptr,matrix%col, &
                   info,matrix%val,row_ord = row_ord,col_ord = col_ord)
       else if (present(row_ord)) then
          CALL CSR_MATRIX_WRITE_ija(file_name,m,n,nz,matrix%ptr,matrix%col, &
                   info,matrix%val,row_ord = row_ord)
       else if (present(col_ord)) then
          CALL CSR_MATRIX_WRITE_ija(file_name,m,n,nz,matrix%ptr,matrix%col, &
                   info,matrix%val,col_ord = col_ord)
       else
          CALL CSR_MATRIX_WRITE_ija(file_name,m,n,nz,matrix%ptr,matrix%col, &
                   info,matrix%val)
       end if
    end if

  end subroutine csr_matrix_write


  subroutine CSR_MATRIX_WRITE_ija(file_name,m,n,nz,ia,ja,info,&
       a,row_ord,col_ord)
    ! file_name: is a CHARACTER array of assumed size with
    !            {\tt INTENT (IN)}.
    ! It is the file to write the matrix in.
    ! m: row dimension
    ! n: column dimension
    ! nz: number of nonzeros
    ! ia: row pointer
    ! ja: column indices
    ! info: flag to show whether successful or not
    ! a: entry values
    ! row_ord: row ordering. NewIndex = row_ord(OldIndex)
    ! col_ord: col ordering. NewIndex = col_ord(OldIndex)
    character (len = *), intent (in) :: file_name
    integer (kind = myint), intent (in) :: m,n,nz,ia(*),ja(*)
    integer (kind = myint), intent (inout) :: info
    real (kind = myreal), intent (in), optional :: a(*)
    integer (kind = myint), intent (in), optional :: row_ord(*),&
         col_ord(*)
    integer (kind = myint) :: file_unit
    integer (kind = myint) :: i,k

    file_unit = vacant_unit()
    if (file_unit < 0) then
       info = MC65_ERR_NO_VACANT_UNIT
       return
    end if
    open(unit = file_unit, file = file_name, form = "formatted")
    write(file_unit,"(i10,i10,i10)") m, n, nz

    if (present(row_ord).and.present(col_ord)) then
       if (present(a)) then
          do i = 1, m
             if (ia(i)>=ia(i+1)) cycle
             write(file_unit,"(2i10,g12.4)") &
                  (row_ord(i),col_ord(ja(k)),a(k),k = ia(i),ia(i+1)-1)
          end do
       else
          do i = 1, m
             if (ia(i)>=ia(i+1)) cycle
             write(file_unit,"(2i10)") &
                  (row_ord(i),col_ord(ja(k)),k = ia(i),ia(i+1)-1)
          end do
       end if
    else if (present(row_ord)) then
       if (present(a)) then
          do i = 1, m
             if (ia(i)>=ia(i+1)) cycle
             write(file_unit,"(2i10,g12.4)") &
                  (row_ord(i),ja(k),a(k),k = ia(i),ia(i+1)-1)
          end do
       else
          do i = 1, m
             if (ia(i)>=ia(i+1)) cycle
             write(file_unit,"(2i10)") &
                  (row_ord(i),ja(k),k = ia(i),ia(i+1)-1)
          end do
       end if
    else if (present(col_ord)) then
       if (present(a)) then
          do i = 1, m
             if (ia(i)>=ia(i+1)) cycle
             write(file_unit,"(2i10,g12.4)") &
                  (i,col_ord(ja(k)),a(k),k = ia(i),ia(i+1)-1)
          end do
       else
          do i = 1, m
             if (ia(i)>=ia(i+1)) cycle
             write(file_unit,"(2i10)") &
                  (i,col_ord(ja(k)),k = ia(i),ia(i+1)-1)
          end do
       end if
    else
       if (present(a)) then
          do i = 1, m
             if (ia(i)>=ia(i+1)) cycle
             write(file_unit,"(2i10,g12.4)") &
                  (i,ja(k),a(k),k = ia(i),ia(i+1)-1)
          end do
       else
          do i = 1, m
             if (ia(i)>=ia(i+1)) cycle
             write(file_unit,"(2i10)") (i,ja(k),k = ia(i),ia(i+1)-1)
          end do
       end if
    end if
    close(file_unit)

  end subroutine CSR_MATRIX_WRITE_ija

  subroutine csr_matrix_write_unformatted(file_name,m,n,nz,&
       type,ia,ja,info,a)
    ! file_name: is a CHARACTER array of assumed size with
    !  {\tt INTENT (IN)}.
    ! It is the file to write the matrix in.
    ! m: row dimension
    ! n: column dimension
    ! nz: number of nonzeros
    ! type: character pointer of matrix type
    ! ia: row pointer
    ! ja: column indices
    ! info: flag to show whether successful or not
    ! a: entry values
    character (len = *), intent (in) :: file_name
    integer (kind = myint), intent (in) :: m,n,nz,ia(*),ja(*)
    character, allocatable, dimension (:) :: type
    integer (kind = myint), intent (inout) :: info
    real (kind = myreal), intent (in), optional :: a(*)
    integer (kind = myint) :: file_unit

    file_unit = vacant_unit()
    if (file_unit < 0) then
       info = MC65_ERR_NO_VACANT_UNIT
       return
    end if
    open(unit = file_unit, file = file_name, form = "unformatted")
    write(file_unit) len_trim(zd11_get(type))
    write(file_unit) zd11_get(type)
    write(file_unit) m,n,nz
    write(file_unit) ia(1:m+1)
    if (nz >= 0) then
       write(file_unit) ja(1:nz)
       if (present(a)) write(file_unit) a(1:nz)
    end if
    close(file_unit)
  end subroutine csr_matrix_write_unformatted

  subroutine csr_matrix_write_gnuplot(file_name,m,n,ia,ja,&
       info,row_ord,col_ord)
    ! write a matrix in a gnuplot data file
    ! "file_name" and the corresponding gnuplot command
    ! to view the matrix in "file_name.com"
    ! The matrix is reordered using col_ord and row_ord
    ! before writing




    ! file_name: is a CHARACTER array of assumed size with
    !   {\tt INTENT (IN)}.
    ! It is the file to write the matrix in.
    ! m: row dimension
    ! n: column dimension
    ! ia: row pointer
    ! ja: column indices
    ! info: info tag.
    ! row_ord: row ordering. NewIndex = row_ord(OldIndex)
    ! col_ord: col ordering. NewIndex = col_ord(OldIndex)
    character (len = *), intent (in) :: file_name
    integer (kind = myint), intent (in) :: m,n,ia(*),ja(*)

    ! col_ord, row_ord: column and row ordering. if a
    !  column col_ord(i) = 1,
    ! column i will be the first column in the ordered matrix
    integer (kind = myint), dimension (*), intent (in), optional :: &
         col_ord, row_ord
    integer (kind = myint), intent (OUT) :: info

    integer (kind = myint) :: i,j
    integer (kind = myint) :: unit1,unit2
    character (len = 120):: fmt_col

    unit1 = vacant_unit()
    if (unit1 < 0) then
       info = MC65_ERR_NO_VACANT_UNIT
       return
    end if
    open(unit = unit1,file = file_name)

    unit2 = vacant_unit()
    if (unit2 < 0) then
       info = MC65_ERR_NO_VACANT_UNIT
       return
    end if
    open(unit = unit2,file = file_name/&
         &/".com")

    write(unit2,"(a,i12,a)") "set xrange [0:",n+1,"]"
    write(unit2,"(a,i12,a)") "set yrange [0:",m+1,"]"
    write(unit2,"(a,i12,a,i12,a)") 'set ytics ("1" ',&
         m,', "',m,'"  1 )'
    write(unit2,"(a)") 'set noxtics'

    ! use in formating for printing number of columns
    fmt_col = "(a,a,i"/&
         &/int2str(digit(n),digit(digit(n)))/&
         &/",a,i12,a)"
    write(unit2,fmt_col) 'set x2tics ("1" 1', &
         ', "', &
         n, &
         '" ', &
         n, &
         ' )'
    write(unit2,"(a)") 'set nolabel '
    !    write(unit2,"(a)") 'set term post portrait '
    !    write(unit2,"(a,a)") 'set out "',file_name/&
    !         &/'.ps"'
    ! to set x and y equal scale
    write(unit2,"(a)") 'set size  square'

    write(unit2,"(a,a,a)") 'plot "',file_name,&
         '" using 1:2 notitle w p ps 0.3'

    if (present(row_ord).and.present(col_ord)) then
       write(unit1,'(2i10)') ((col_ord(ja(j)), m+1-row_ord(i), &
            j=ia(i), ia(i+1)-1), i = 1, m)
    else if (present(row_ord)) then
       write(unit1,'(2i10)') ((ja(j), m+1-row_ord(i), &
            j=ia(i), ia(i+1)-1), i = 1, m)
    else if (present(col_ord)) then
       write(unit1,'(2i10)') ((col_ord(ja(j)), m+1-i, &
            j=ia(i), ia(i+1)-1), i = 1, m)
    else
       write(unit1,'(2i10)') ((ja(j), m+1-i, j=ia(i), ia(i+1)-1), &
            i = 1, m)
    end if

    close(unit1)
    close(unit2)
  end subroutine csr_matrix_write_gnuplot



  subroutine csr_matrix_write_hypergraph(matrix,file_name,info,stat)
    ! write the matrix in hypergraph format.
    ! that is,
    ! row_dimension_of_A^T column_dimension_of_A^T
    ! column_indices_of_row1_of_A^T
    ! column_indices_of_row2_of_A^T
    ! column_indices_of_row3_of_A^T
    ! .....


    ! matrix: the matrix to be written
    type (zd11_type), intent (in) :: matrix

    ! file_name: the file name to write the data into
    character (len = *), intent (in) :: file_name

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat

    integer (kind = myint) :: i,n,m,l1,l2,ierr
    integer (kind = myint) :: unit1
    type (zd11_type) :: matrix2
    character(len=80) fmt
    integer (kind = myint), intent (inout) :: info

    if (present(stat)) stat = 0

    call csr_matrix_transpose(matrix,matrix2,info,stat=ierr)
    if (present(stat)) stat = ierr
    if (info < 0) return

    unit1 = vacant_unit()
    if (unit1 < 0) then
       info = MC65_ERR_NO_VACANT_UNIT
       return
    end if
    open(unit = unit1,file = file_name)

    m = matrix%m
    n = matrix%n
    write(unit1,"(2i12)") n,m
    do i = 1, n
       l1 = matrix2%ptr(i)
       l2 = matrix2%ptr(i+1)-1
       write(fmt,"('(',i12,'i8)')") max(1,l2-l1+1)
       write(unit1,fmt) matrix2%col(l1:l2)
    end do

    call csr_matrix_destruct(matrix2,info,stat=ierr)
    if (present(stat)) stat = ierr
    if (info < 0) return
    close(unit1)
  end subroutine csr_matrix_write_hypergraph








  subroutine csr_matrix_read(matrix,file_name,info,form,stat)
    ! read the matrix as dumped by csr_matrix_write,
    !  unformatted only

    ! matrix:  is of the derived type {\tt ZD11\_TYPE}
    !  with {\tt INTENT (INOUT)}.
    type (zd11_type), intent (inout) :: matrix

    ! file_name:  is a {\tt CHARACTER} array of assumed size
    !              with {\tt INTENT (IN)}.
    !              It is the file to write the matrix in.
    character (len = *), intent (in) :: file_name

    ! INFO: is a INTEGER of INTENT (OUT).
    !       INFO = 0 if the subroutine returns successfully
    ! info = MC65_mem_alloc if memory allocation failed
    ! info = MC65_mem_dealloc if memory deallocation failed
    !       INFO = MC65_ERR_READ_WRONGFORM if in
    !              MC65_MATRIX_READ,form is present
    !              but is of an unsupported form.
    !       INFO = MC65_ERR_READ_FILE_MISS if in MC65_MATRIX_READ,
    !              the file <file_name> does not exist.
    !       INFO = MC65_ERR_READ_OPEN if in MC65_MATRIX_READ,
    !              opening of the file <file_name> returns iostat /= 0
    !       INFO = MC65_ERR_NO_VACANT_UNIT if no vacant unit
    !              has been found in MC65_MATRIX_WRITE
    integer (kind = myint), intent (out) :: INFO


    ! form:  is an {\tt OPTIONAL CHARACTER} array of
    !        assumed size with
    !       {\tt INTENT (IN)}. It is the format of the input file
    !        Only form = "unformatted" is supported. If
    !        form is not present, by default
    !        the subroutine assume that the input file is unformatted.
    !        If form is present but form != "unformatted",
    !        the subroutine will return with info =
    !        MC65_ERR_READ_WRONGFORM
    character (len = *), intent (in), optional :: form

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat


    ! file_unit: open the file in this unit
    integer (kind = myint) :: file_unit
    ! m,n: row and column dimension
    ! nz: number of nonzeros
    integer (kind = myint) :: m,n,nz,ierr

    integer (kind = myint) :: ios
    logical :: existed, opened
    integer (kind = myint), parameter :: maxlen = 2000
    character (len=maxlen) :: type
    integer (kind = myint) :: len_type
    integer (kind = myint) :: iform, UNFORMAT = 1, UNSUPPORTED = 2

    info = 0
    if (present(stat)) stat = 0

    iform = UNFORMAT
    if (present(form)) then
       if (form == "unformatted") then
          iform = UNFORMAT
          !  else if ...
          ! .... other forms comes here
       else
          iform = UNSUPPORTED
          info = MC65_ERR_READ_WRONGFORM
          return
       end if
    end if


    file_unit = vacant_unit()
    if (file_unit < 0) then
       info = MC65_ERR_NO_VACANT_UNIT
       return
    end if

    inquire(file = file_name, exist = existed, opened = opened, &
         iostat = ios)
    if (.not.existed) then
       info = MC65_ERR_READ_FILE_MISS
       return
    end if
    if (opened) then
       rewind(file_unit)
    end if
    if (ios /= 0) then
       info = MC65_ERR_READ_OPEN
    end if

    if (iform == UNFORMAT) then
       open(unit = file_unit, file = file_name, form = "unformatted")
    else
       open(unit = file_unit, file = file_name, form = "formatted")
    end if


    if (iform == UNFORMAT) then
       type = ""
       read(file_unit) len_type
       if (len_type > maxlen) then
          INFO = MC65_ERR_READ_MAXLEN
          return
       end if
       read(file_unit) type(1:len_type)
       read(file_unit) m,n,nz
       call csr_matrix_construct(matrix,m,nz,info,n=n,type=type,stat=ierr)
       if (present(stat)) stat = ierr
       if (info < 0) then
          return
       end if
       read(file_unit) matrix%ptr(1:matrix%m+1)
       if (nz >= 1) then
          read(file_unit) matrix%col(1:nz)
          if (ZD11_get(matrix%type) /= "pattern" ) &
               read(file_unit) matrix%val(1:nz)
       end if

       ! else if (...)
       ! other format will be here ...
    end if

    close(file_unit)

  end subroutine csr_matrix_read



  subroutine csr_matrix_condense(matrix,info,col_wgt_real,&
       col_wgt_int,realloc,iremove,stat)
    !   subroutine csr_matrix_condense(matrix,info[,&
    !        col_wgt_real,col_wgt_int,realloc])
    ! given a matrix, finds all columns that has
    ! <= iremove (by default 0) element and delete them, also
    ! merge columns with exactly the same pattern.
    ! it only works on matrix with pattern only.
    ! The matrix should also be cleaned using
    ! matrix_clean to agglomerate repeated
    ! entries!

    ! MATRIX is of the derived type {\tt ZD11\_TYPE} with
    !        {\tt INTENT (INOUT)}. on exit all columns that
    !        has no more than one entry are deleted;
    !        columns that have the same pattern are merged into one.
    !        The column dimension of the matrix is changed
    !        accordingly.
    type (zd11_type), intent (inout) :: matrix


    ! INFO  is an {\tt INTEGER} of {\tt INTENT (OUT)}.
    !       INFO = 0 if the subroutine completes successfully
    !       INFO = MC65_ERR_CONDENSE_NOPAT if the matrix
    !              is not of type {\tt "pattern"}
    !       INFO = MC65_ERR_MEMORY_ALLOC if memory allocation failed
    !       INFO = MC65_ERR_MEMORY_DEALLOC if memory
    !              deallocation failed.
    integer (kind = myint), intent (out) :: info

    ! col_wgt_real: is an OPTIONAL REAL array with INTENT (INOUT) of
    !          size N (the column dimension). When present,
    !          On entry, the first N elements contain the column
    !          weights of the matrix,
    !          on exit, the first NSUP elements of col_wgt
    !          holds the super-column weight of the condensed matrix.
    !          Here nsup is the new column dimension of the
    !          condensed matrix. Note that the two optional arguments
    !          col_wgt_real and col_wgt_int are supplied so that
    !          the user is free to treat column weight either as
    !          real arrays, or as integer arrays.
    !          The correct usage is therefore
    !          to supply, if appropriate, either col_wgt_real or
    !          col_wgt_int as a keyword argument
    !          ({\tt col_wgt_real = colwgt} or
    !          (\tt col_wgt_int = colwgt},
    !          depending on whether colwgt is real or integer)
    ! col_wgt_int: is an OPTIONAL INTEGER array with INTENT (INOUT)
    !          of size N  (the column dimension). When present,
    !          On entry, the first N elements contain the column
    !           weights of the matrix,
    !          on exit, the first NSUP elements of col_wgt
    !          holds the super-column weight of the condensed matrix.
    !          Here nsup is the new column dimension of the
    !          condensed matrix.
    !          Note that the two optional arguments
    !          col_wgt_real and col_wgt_int are supplied so that
    !          the user is free to treat column weight either as
    !          real arrays, or as integer arrays.
    !          The correct usage is therefore
    !          to supply, if appropriate, either col_wgt_real or
    !          col_wgt_int as a keyword argument
    !          ({\tt col_wgt_real = colwgt} or
    !          (\tt col_wgt_int = colwgt},
    !          depending on whether colwgt is real or integer).
    integer (kind = myint), dimension (matrix%n), optional, &
         intent (inout) :: col_wgt_int
    real (kind = myreal), dimension (matrix%n), optional, &
         intent (inout) :: col_wgt_real


    ! realloc:  is an optional real scaler of INTENT (IN).
    !   It is used to control the reallocation of storage.
    ! \begin{itemize}
    !  \item{} if {\tt REALLOC < 0}, no reallocation.
    !  \item{} if {\tt REALLOC == 0}, reallocation is carried out
    !  \item{} if {\tt REALLOC > 0}, reallocation iff memory
    !       saving is greater than
    !      {\tt REALLOC*100}\%. For example,
    !      if {\tt REALLOC = 0.5}, reallocation will be carried out
    !      if saving in storage is greater than 50\%
    !  \end{itemize}
    ! If {\tt REALLOC} is not present, no reallocation is carried out.
    real (kind = myreal), INTENT(IN), optional :: realloc

    ! iremove: an OPTIONAL INTEGER scalar. When present,
    !    any columns that have <= iremove
    !    entries are removed. If not present, only columns
    !    of zero entries are removed.
    integer (kind = myint), intent (in), optional :: iremove

    ! stat: is an optional integer saler of INTENT (OUT). If supplied,
    ! on exit it holds the error tag for memory allocation
    integer (kind = myint), optional, intent (out) :: stat
    ! ===================== local variables =======================

    ! col_wgt_new: working array. the new super-column weight.
    real (kind = myreal), dimension (:), allocatable :: col_wgt_new_r
    integer (kind = myint), dimension (:), allocatable :: &
         col_wgt_new_i

    ! f2c: the array which says which original column is
    !      merged into which super-column
    ! numsup: how many original columns make up the super-columns
    ! new: the new identity of a supercolumn
    ! flag: in which row the first appearance of a super-column?
    integer (kind = myint), dimension (:), allocatable :: &
         f2c,numsup,new,flag

    ! nsup: number of super-columns so far
    ! m,n: row and column size
    ! newid: new group of an old super-column
    ! i,j,jj: loop index
    ! scol: super-column id ofan column entry in the current row
    ! nz: number of nonzeros in the condensed matrix
    ! jjs: starting index of original row in the matrix
    integer (kind = myint) :: nsup,n,m,newid,i,j,jj,scol,nz,jjs,&
         nz_old,ierr

    ! number of super-columns after getting rid of columns
    ! with less than one entry
    integer (kind = myint) :: nsup_new

    ! col_count: a counter for (the number of entries - 1) in
    !            each column
    integer (kind = myint), dimension (:), allocatable :: col_count
    ! col_count_new: a counter for (the number of entries - 1)
    !                in each column in the condensed matrix
    !                (of super-columns)
    ! sup_to_sup: super-column index after condensing and that after
    ! getting rid of columns with only <= 1 entries
    integer (kind = myint), dimension (:), allocatable :: &
         col_count_new, sup_to_sup

    ! num_remove: any column of <= num_remove entries are
    !             removed. by default num_remove = 0
    integer (kind = myint) :: num_remove

    num_remove = 0
    if (present(iremove)) num_remove = iremove

    info = 0 ! by default the subroutine is successful.
    if (present(stat)) stat = 0

    n = matrix%n
    m = matrix%m

    ! check that the matrix is pattern only!
    if (ZD11_get(matrix%type) /= "pattern" ) then
       info = MC65_ERR_CONDENSE_NOPAT
       return
    end if

    ! if no column no need to work further.
    if (n <= 0) return

    ! all columns assigned as super-column 1 first
    allocate(f2c(n),numsup(n),new(n),flag(n),col_count(n),stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       INFO = MC65_ERR_MEMORY_ALLOC
       return
    end if

    f2c = 1
    numsup(1) = n
    flag(1) = 0
    nsup = 1
    col_count = 0

    ! loop over each row, assign each column entry as a new
    !    super-column
    do i = 1, m
       ! column entries in this row will change their super-column
       ! number, so reduce the number of super-columns of their
       ! old group
       do jj = matrix%ptr(i),matrix%ptr(i+1)-1
          j = matrix%col(jj)
          col_count(j) = col_count(j) + 1
          scol = f2c(j)
          numsup(scol) = numsup(scol) - 1
       end do
       ! assign new groups
       do jj = matrix%ptr(i),matrix%ptr(i+1)-1
          j = matrix%col(jj)
          scol = f2c(j)
         ! has this super-column been seen before in row i?
          if (flag(scol) < i) then
             ! the first appearance of scol in row i
             flag(scol) = i
             if (numsup(scol) > 0) then
                nsup = nsup + 1
                flag(nsup) = i
                f2c(j) = nsup
                numsup(nsup) = 1
                new(scol) = nsup
             else
                ! if zero, the old group disappear anyway, there is
                ! no need to add a new group name, just use
                ! the old one
                numsup(scol) = 1
                new(scol) = scol
             end if
          else
             newid = new(scol)
             f2c(j) = newid
             numsup(newid) = numsup(newid) + 1
          end if
       end do
    end do

    ! now get rid of columns of <= num_remove entries by modifying f2c
    allocate(col_count_new(nsup),sup_to_sup(nsup),stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       INFO = MC65_ERR_MEMORY_ALLOC
       return
    end if

    ! The following array statement can't be used, as multiple columns
    ! (with the _same_ non-zero pattern) can be assigned to each supercolumn
    ! so we need to use a loop instead
    !col_count_new(f2c(1:n)) = col_count(1:n)
    do i = 1, n
       col_count_new(f2c(i)) = col_count(i)
    end do
    nsup_new = 0
    do i = 1, nsup
       if (col_count_new(i) > num_remove) then
          nsup_new = nsup_new + 1
          sup_to_sup(i) = nsup_new
       else
          sup_to_sup(i) = -1
       end if
    end do
    f2c(1:n) = sup_to_sup(f2c(1:n))
    nsup = nsup_new

    deallocate(col_count,col_count_new,sup_to_sup,stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       INFO = MC65_ERR_MEMORY_DEALLOC
       return
    end if

    ! condense the matrix
    flag = 0
    nz = 1
    do i = 1, m
       ! loop over each row
       jjs = matrix%ptr(i)
       matrix%ptr(i) = nz
       do jj = jjs,matrix%ptr(i+1)-1
          j = matrix%col(jj)
          scol = f2c(j)
          ! forget about columns with less than num_remove entries
          if (scol < 0) cycle
          ! if this the first time this group appear?
          ! if so this column will remain
          if (flag(scol) < i) then
             flag(scol) = i
             matrix%col(nz) = scol
             nz = nz + 1
          end if
       end do
    end do
    nz_old = size(matrix%col)
    matrix%ptr(m+1) = nz
    matrix%n = nsup

    nz = nz -1
    if (present(realloc)) then
       if (realloc == 0.0_myreal.or.(realloc > 0.and.&
            nz_old > (1.0_myreal + realloc)*nz)) then
          call csr_matrix_reallocate(matrix,nz,info)
          if (info < 0) return
       end if
    end if


    ! condense the column weight
    deallocate(numsup,new,flag,stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       INFO = MC65_ERR_MEMORY_DEALLOC
       return
    end if

    if (present(col_wgt_real)) then
       allocate(col_wgt_new_r(nsup),stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          INFO = MC65_ERR_MEMORY_ALLOC
          return
       end if

       col_wgt_new_r = 0
       do i = 1, n
          scol = f2c(i)
          ! forget about columns with less than num_remove entries
          if (scol < 0) cycle
          col_wgt_new_r(scol) = col_wgt_new_r(scol) + col_wgt_real(i)
       end do
       col_wgt_real(1:nsup) = col_wgt_new_r
       deallocate(col_wgt_new_r,stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          INFO = MC65_ERR_MEMORY_DEALLOC
       end if
    end if


    if (present(col_wgt_int)) then
       allocate(col_wgt_new_i(nsup),stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          INFO = MC65_ERR_MEMORY_ALLOC
          return
       end if

       col_wgt_new_i = 0
       do i = 1, n
          scol = f2c(i)
          ! forget about columns with less than num_remove entries
          if (scol < 0) cycle
          col_wgt_new_i(scol) = col_wgt_new_i(scol) + col_wgt_int(i)
       end do
       col_wgt_int(1:nsup) = col_wgt_new_i
       deallocate(col_wgt_new_i,stat = ierr)
       if (present(stat)) stat = ierr
       if (ierr /= 0) then
          INFO = MC65_ERR_MEMORY_DEALLOC
       end if
    end if


    deallocate(f2c,stat = ierr)
    if (present(stat)) stat = ierr
    if (ierr /= 0) then
       INFO = MC65_ERR_MEMORY_DEALLOC
    end if


  end subroutine csr_matrix_condense

  function csr_matrix_is_pattern(matrix) result (pattern)
    ! check is a matrix is of type "pattern"
    ! MATRIX is of the derived type {\tt ZD11\_TYPE}
    !        with {\tt INTENT (IN)}.
    !        On entry it is the matrix whose type is to
    !        be determined
    type (zd11_type), intent (in) :: matrix
    ! pattern: logical scalar. On exit
    ! is set to true if the matrix is of type "pattern"
    !  and false if not
    logical :: pattern
    if (ZD11_get(matrix%type) == "pattern")  then
       pattern = .true.
    else
       pattern = .false.
    end if
  end function csr_matrix_is_pattern

! ======================== private routines from here =============


  function vacant_unit()  result (file_unit)
    ! utility routine to find a vacant unit and
    ! returns a unit number of a unit that exists and is
    ! not connected

    ! max_unit: maximum number of units to check
    integer (kind = myint) :: max_unit
    parameter (max_unit = 500)
    ! file_unit: the vacant unit
    integer (kind = myint) :: file_unit

    logical :: existed, opened
    integer (kind = myint) :: ios

    do file_unit = 10, max_unit
       inquire (unit = file_unit, exist = existed, &
            opened = opened, iostat = ios)
       if (existed .and. .not. opened .and. ios == 0) return
    end do

    file_unit = -1

  end function vacant_unit




  subroutine expand1(p1,upbound_new1,info,ierr)
    ! reallocate memory for an integer or real allocatable array
    !     of up to 4 dimension.
    ! usage: expand(array,new_bound_1, ...,new_bound_n)
    ! a space of size "new_bound_1 X ... X new_bound_n"
    ! will be allocated and the content of array
    ! will be copied to the beginning of this
    ! memory.
    real (kind = myreal), allocatable:: p2(:),p1(:)
    integer (kind = myint) upbound_new1
    integer (kind = myint) ub(1),lb(1),upb(1)
    integer (kind = myint) info,i,ierr
    ierr=0

    upb(1)=upbound_new1

    lb=lbound(p1)
    ub=ubound(p1)


    allocate(p2(lb(1):upb(1)),stat=ierr)
    if (ierr == 0) then
       p2=0
       do i=lb(1),min(ub(1),upb(1))
          p2(i)=p1(i)
       end do
       deallocate(p1,stat = ierr)
       allocate(p1(lb(1):upb(1)),stat=ierr)
       if (ierr == 0) then
          do i=lb(1),min(ub(1),upb(1))
             p1(i)=p2(i)
          end do
       else
          info = MC65_ERR_MEMORY_DEALLOC
          return
       end if
    else
       info = MC65_ERR_MEMORY_ALLOC
    end if


  end subroutine expand1

  ! ============ for integer (kind = myint) arrays ================

  subroutine iexpand1(p1,upbound_new1,info,ierr)
    integer (kind = myint), allocatable:: p2(:),p1(:)
    integer (kind = myint) upbound_new1
    integer (kind = myint) ub(1),lb(1),upb(1)
    integer (kind = myint) info,i,ierr

    upb(1)=upbound_new1

    lb=lbound(p1)
    ub=ubound(p1)


    allocate(p2(lb(1):upb(1)),stat=ierr)
    if (ierr == 0) then
       p2=0
       do i=lb(1),min(ub(1),upb(1))
          p2(i)=p1(i)
       end do
       deallocate(p1,stat = ierr)
       allocate(p1(lb(1):upb(1)),stat=ierr)
       if (ierr == 0) then
          do i=lb(1),min(ub(1),upb(1))
             p1(i)=p2(i)
          end do
       else
          info = MC65_ERR_MEMORY_DEALLOC
          return
       end if
    else
       info = MC65_ERR_MEMORY_ALLOC
    end if

  end subroutine iexpand1



  function int2str(i,idigit) result (the_str)
    ! converting an integer to a string.
    integer (kind = myint):: i,idigit

    character (len = idigit) :: the_str

    character (len = 20) :: fmt_str

    fmt_str = "(I                 )"

    write(fmt_str(3:19),"(I6)") idigit

    write(the_str,fmt_str) i

  end function int2str

  function digit(i)
    ! return the number of digit of an integer
    integer (kind = myint) :: i,digit

    integer (kind = myint) :: absi


    absi = abs(i)

    digit = 1

    do while (absi >= 10)

       absi = absi / 10

       digit = digit + 1

    end do

    if (i < 0) digit = digit + 1

  end function digit





!!$  subroutine csr_matrix_reset_type(matrix,type,info)
!!$    ! subroutine csr_matrix_reset_type(matrix,type,info):
!!$    ! reset the type of the matrix
!!$
!!$    ! matrix: is of the derived type ZD11_type, INTENT (INOUT).
!!$    !         This is the matrix whose type is to be changed.
!!$    type (zd11_type), intent (inout) :: matrix
!!$
!!$    ! type: is a character array of unspecified length with
!!$    !       INTENT (IN).
!!$    !       It hold the new matrix type to be set.
!!$    character (len=*), intent (in) :: type
!!$
!!$    ! info: integer scaler of INTENT (OUT).
!!$    !       = 0 if the subroutine returned successfully
!!$    !       = MC65_ERR_MEMORY_ALLOC if memory allocation failed
!!$    !       = MC65_ERR_MEMORY_DEALLOC if memory deallocation failed
!!$    integer (kind = myint), intent (out) :: info
!!$
!!$    ! =============== local variables ===============
!!$
!!$    integer (kind =  myint) :: ierr
!!$
!!$    info = 0
!!$
!!$    if (allocated(matrix%type)) deallocate(matrix%type,stat = ierr)
!!$    if (ierr /= 0) then
!!$       info = MC65_ERR_MEMORY_DEALLOC
!!$       return
!!$    end if
!!$    call zd11_put(matrix%type,type,stat = ierr)
!!$    if (ierr /= 0) then
!!$       info = MC65_ERR_MEMORY_ALLOC
!!$    end if
!!$
!!$  end subroutine csr_matrix_reset_type
!!$
!!$
!!$  subroutine csr_matrix_fill(matrix,i,row_counter,fill_entry,&
!!$       fill_value)
!!$    ! fill an entry -- fill the current
!!$    ! entry with column index fill_entry and column value
!!$    ! fill_value, in row i of the matrix.
!!$    ! row_counter is a counter given
!!$    ! for the vacant position in the rows. This subroutine
!!$    ! is used when the matrix has been allocated storage, and also
!!$    ! the row pointer has already been established, and
!!$    ! one is at the stage of filling in the entry values
!!$    ! and column indices.
!!$
!!$    ! matrix: the matrix whose entries are to be filled.
!!$    type (zd11_type), intent (inout) :: matrix
!!$
!!$    ! i: the entry is to be filled at this i-th row.
!!$    integer (kind = myint), intent (in) :: i
!!$
!!$    ! row_counter: integer array, row_counter(i)
!!$    !              is number of entries filled in row i so far.
!!$    integer (kind = myint), dimension (*), intent (inout) :: &
!!$         row_counter
!!$
!!$    ! fill_entry: column index of the current entry
!!$    integer (kind = myint), intent (in) :: fill_entry
!!$    real (kind = myreal), intent (in), optional :: fill_value
!!$
!!$    integer (kind = myint), pointer, dimension (:) :: ja
!!$    real (kind = myreal), pointer, dimension (:) :: aa
!!$
!!$
!!$    ja => csr_matrix_getrow(matrix,i)
!!$    row_counter(i) = row_counter(i) + 1
!!$    ja(row_counter(i)) = fill_entry
!!$    if (present(fill_value)) then
!!$       aa => csr_matrix_getrowval(matrix,i)
!!$       aa(row_counter(i)) = fill_value
!!$    end if
!!$  end subroutine csr_matrix_fill
!!$
!!$
!!$  subroutine csr_matrix_component(matrix,root,mask,comp_nvtx,&
!!$       comp_nz,comp_vtx_list)
!!$    !
!!$    ! matrix_component: this subroutine finds the component
!!$    ! of the graph starting from the root. This component
!!$    ! is stored in the list of vertices "comp_vtx_list",
!!$    ! with "comp_nvtx" vertices and "comp_nz"/2 edges
!!$    ! (thus comp_nz nonzeros in the matrix describing
!!$    ! the component).
!!$
!!$    ! =================== arguments =========================
!!$
!!$    ! matrix: the graph to be inspected. This must be a symmetric
!!$    ! matrix with no diagonal
!!$    type (zd11_type), intent (in) :: matrix
!!$
!!$    ! root: the root of the current component
!!$    integer (kind = myint), intent (in) :: root
!!$
!!$    ! comp_nvtx: number of vertices in this component
!!$    ! comp_nz: number of edges*2 in the component
!!$    integer (kind = myint), intent (out) :: comp_nvtx,comp_nz
!!$
!!$    ! mask: has the dimension as the number of vertices.
!!$    ! It is zero if the vertex is not yet visited,
!!$    ! nonzero if visited. When a vertex is visited the first time,
!!$    ! its mask is set to the new index of this vertex in the component
!!$    ! comp_vtx_list: a list of the vertices in the current component.
!!$    ! mask and comp_vtx_list satisfies mask(comp_vtx(i)) = i,
!!$    ! i = 1,...,comp_nvtx
!!$    integer (kind = myint), dimension (:), intent (inout) :: mask, &
!!$         comp_vtx_list
!!$
!!$    ! ===================== local variables =====================
!!$    ! front_list: this array hold the list of vertices that
!!$    !             form the front in the breadth first search
!!$    !             starting from the root
!!$    integer (kind = myint), dimension (:), allocatable :: front_list
!!$
!!$    ! front_sta: the starting position in the front_list of the
!!$    !            current front.
!!$    ! front_sto: the ending position in the front_list of the current
!!$    ! front.
!!$    integer (kind = myint) :: front_sta, front_sto
!!$
!!$    ! n: number of vertices in the graph
!!$    ! ierr: error tag
!!$    integer (kind = myint) :: n,ierr
!!$    ! v: a vertex
!!$    ! u: neighbor of v
!!$    ! i: loop index
!!$    ! j: loop index
!!$    integer (kind = myint) :: i,j,u,v
!!$
!!$    n = matrix%m
!!$
!!$    ! the first front
!!$    allocate(front_list(n),stat = ierr)
!!$    if (ierr /= 0) stop "error allocating in matrix_component"
!!$    front_sta = 1
!!$    front_sto = 1
!!$    front_list(1) = root
!!$
!!$    comp_nvtx = 1
!!$    comp_nz = 0
!!$    comp_vtx_list(1) = root ! one vertex in the component so far
!!$    mask(root) = comp_nvtx ! mask the root
!!$
!!$    do while (front_sto-front_sta >= 0)
!!$       do i = front_sta, front_sto
!!$          v = front_list(i) ! pick a vertex from the front
!!$          ! count link to all neighbors as edges
!!$          comp_nz = comp_nz + matrix%ptr(v+1)-matrix%ptr(v)
!!$          do j = matrix%ptr(v),matrix%ptr(v+1)-1
!!$             u = matrix%col(j) ! pick its neighbor
!!$             if (mask(u) /= 0) cycle
!!$             comp_nvtx = comp_nvtx + 1 ! found a unmasked vertex
!!$             mask(u) = comp_nvtx ! mask this vertex
!!$             ! add this vertex to the component
!!$             comp_vtx_list(comp_nvtx) = u
!!$             front_list(comp_nvtx) = u ! also add it to the front
!!$          end do
!!$       end do
!!$       front_sta = front_sto + 1
!!$       front_sto = comp_nvtx
!!$    end do
!!$    deallocate(front_list,stat = ierr)
!!$    if (ierr /= 0) stop "error deallocating in matrix_component"
!!$
!!$
!!$  end subroutine csr_matrix_component
!!$
!!$  subroutine csr_matrix_crop(matrix,comp_nvtx,comp_vtx_list,&
!!$       mask,submatrix,comp_nz,info)
!!$    ! matrix_crop: generate a submatrix describing a component of
!!$    ! the graph (matrix).
!!$
!!$    ! =================== arguments =========================
!!$    ! matrix: the graph to be inspected. This must be a symmetric
!!$    ! matrix with no diagonal
!!$    type (zd11_type), intent (in) :: matrix
!!$
!!$    ! comp_nvtx: number of vertices in this component
!!$    ! comp_nz: number of edges*2 in the component (optional)
!!$    integer (kind = myint), intent (in) :: comp_nvtx
!!$    integer (kind = myint), intent (in), optional :: comp_nz
!!$    integer (kind = myint), intent (out) :: info
!!$
!!$    ! mask: has the dimension as the number of vertices.
!!$    ! The mask of a vertex is set to the new index
!!$    ! of this vertex in the component it belongs
!!$    ! comp_vtx_list: a list of the vertices in the current component
!!$    integer (kind = myint), dimension (:), intent (in) :: mask, &
!!$         comp_vtx_list
!!$
!!$    ! submatrix: the submatrix describing the component
!!$    type (zd11_type), intent (inout) :: submatrix
!!$
!!$    ! ===================== local variables =====================
!!$    ! i: loop index
!!$    ! j: loop index
!!$    ! nz: number of nonzeros in the submatrix
!!$    ! n: number of rows in the submatrix
!!$    ! m: number of columns in the submatrix
!!$    ! v: a vertex in its original index
!!$    ! l1: starting index
!!$    ! l2: stopping index
!!$    ! sl1: starting index
!!$    ! sl2: stopping index
!!$    integer (kind = myint) :: i,j,nz,n,m,v,l1,l2,sl1,sl2
!!$
!!$    ! ia: row pointer of the original graph
!!$    ! ja: column indices of the original graph
!!$    ! sia: row pointer of the subgraph
!!$    ! sja: column indices of the subgraph
!!$    integer (kind = myint), dimension (:), pointer :: ia,ja,sia,sja
!!$
!!$    ! a: entry values of the original graph
!!$    ! sa: entry values of the subgraph
!!$    real (kind = myreal), dimension (:), pointer :: a,sa
!!$
!!$    info = 0
!!$    ia => matrix%ptr
!!$    ja => matrix%col
!!$    if (.not.present(comp_nz)) then
!!$       nz = 0
!!$       do i = 1, comp_nvtx
!!$          v = comp_vtx_list(i)
!!$          nz = nz + ia(v+1) - ia(v)
!!$       end do
!!$    else
!!$       nz = comp_nz
!!$    end if
!!$
!!$    n = comp_nvtx; m = n;
!!$    call csr_matrix_construct(submatrix,n,nz,info,n = m,&
!!$         type = zd11_get(matrix%type))
!!$    sia => submatrix%ptr
!!$    sja => submatrix%col
!!$    if (ZD11_get(matrix%type) /= "pattern" ) then
!!$       sa => submatrix%val
!!$       a => matrix%val
!!$    end if
!!$    sia(1) = 1
!!$    do i = 1, comp_nvtx
!!$       v = comp_vtx_list(i)
!!$       l1 = ia(v); l2 = ia(v+1)-1
!!$       sia(i+1) = sia(i) + l2 - l1 + 1
!!$       sl1 = sia(i); sl2 = sia(i+1)-1
!!$       ! convert original index to new index in the component
!!$       sja(sl1:sl2) = mask(ja(l1:l2))
!!$       if (ZD11_get(matrix%type) /= "pattern" ) then
!!$          sa(sl1:sl2) = a(l1:l2)
!!$       end if
!!$    end do
!!$  end subroutine csr_matrix_crop
!!$
!!$
!!$
!!$
!!$  subroutine csr_matrix_crop_unsym(matrix,nrow,row_list,submatrix,info)
!!$    ! matrix_crop: generate a submatrix of the whole matrix
!!$    ! by taking all the nrow rows in the row_list.
!!$    ! column size of submatrix is assigned as the same as that
!!$    ! for matrix.
!!$
!!$    ! =================== arguments =========================
!!$    ! matrix: the matrix to be inspected.
!!$    type (zd11_type), intent (in) :: matrix
!!$
!!$    ! nrow: number of vertices in this component
!!$    integer (kind = myint), intent (in) :: nrow
!!$
!!$    ! row_list: a list of the vertices in the current component
!!$    integer (kind = myint), dimension (:), intent (in) :: row_list
!!$
!!$    ! submatrix: the submatrix describing the component
!!$    type (zd11_type), intent (inout) :: submatrix
!!$    integer (kind = myint), intent (out) :: info
!!$    ! ===================== local variables =====================
!!$    ! i: loop index
!!$    ! j: loop index
!!$    ! nz: number of nonzeros in the submatrix
!!$    ! n: number of rows in the submatrix
!!$    ! m: number of columns in the submatrix
!!$    ! v: a vertex in its original index
!!$    ! l1: starting index
!!$    ! l2: stopping index
!!$    ! sl1: starting index
!!$    ! sl2: stopping index
!!$    integer (kind = myint) :: i,j,nz,n,m,v,l1,l2,sl1,sl2
!!$
!!$    ! ia: row pointer of the original matrix
!!$    ! ja: column indices of the original matrix
!!$    ! sia: row pointer of the submatrix
!!$    ! sja: column indices of the submatrix
!!$    integer (kind = myint), dimension (:), pointer :: ia,ja,sia,sja
!!$
!!$    ! a: entry values of the original matrix
!!$    ! sa: entry values of the submatrix
!!$    real (kind = myreal), dimension (:), pointer :: a,sa
!!$
!!$    info = 0
!!$    ia => matrix%ptr
!!$    ja => matrix%col
!!$    nz = 0
!!$    do i = 1, nrow
!!$       v = row_list(i)
!!$       nz = nz + ia(v+1) - ia(v)
!!$    end do
!!$
!!$    n = nrow; m = matrix%n;
!!$    call csr_matrix_construct(submatrix,n,nz,info,n = m,&
!!$         type = zd11_get(matrix%type))
!!$
!!$    sia => submatrix%ptr
!!$    sja => submatrix%col
!!$    if (ZD11_get(matrix%type) /= "pattern" ) then
!!$       sa => submatrix%val
!!$       a => matrix%val
!!$    end if
!!$    sia(1) = 1
!!$    do i = 1, nrow
!!$       v = row_list(i)
!!$       l1 = ia(v); l2 = ia(v+1)-1
!!$       sia(i+1) = sia(i) + l2 - l1 + 1
!!$       sl1 = sia(i); sl2 = sia(i+1)-1
!!$       ! convert original index to new index in the component
!!$       sja(sl1:sl2) = ja(l1:l2)
!!$       if (ZD11_get(matrix%type) /= "pattern" ) then
!!$          sa(sl1:sl2) = a(l1:l2)
!!$       end if
!!$    end do
!!$  end subroutine csr_matrix_crop_unsym
!!$
!!$

end module HSL_MC65_double




! COPYRIGHT (c) 2010 Science and Technology Facilities Council
! Original date 18 January 2011. Version 1.0.0
!
! Written by: Jonathan Hogg, John Reid, and Sue Thorne
!
! Version 1.4.1
! For version history, see ChangeLog
!
module hsl_mc69_double
   implicit none

   private
   public :: HSL_MATRIX_UNDEFINED,                             &
      HSL_MATRIX_REAL_RECT, HSL_MATRIX_CPLX_RECT,              &
      HSL_MATRIX_REAL_UNSYM, HSL_MATRIX_CPLX_UNSYM,            &
      HSL_MATRIX_REAL_SYM_PSDEF, HSL_MATRIX_CPLX_HERM_PSDEF,   &
      HSL_MATRIX_REAL_SYM_INDEF, HSL_MATRIX_CPLX_HERM_INDEF,   &
      HSL_MATRIX_CPLX_SYM,                                     &
      HSL_MATRIX_REAL_SKEW, HSL_MATRIX_CPLX_SKEW
   public :: mc69_cscl_clean, mc69_verify, mc69_print, mc69_csclu_convert, &
      mc69_coord_convert, mc69_set_values, mc69_csrlu_convert, &
      mc69_cscl_convert, mc69_cscu_convert, mc69_csru_convert, &
      mc69_csrl_convert

   integer, parameter :: wp = kind(0d0)
   real(wp), parameter :: zero = 0.0_wp

   ! matrix types : real
   integer, parameter :: HSL_MATRIX_UNDEFINED      =  0 ! undefined/unknown
   integer, parameter :: HSL_MATRIX_REAL_RECT      =  1 ! real rectangular
   integer, parameter :: HSL_MATRIX_REAL_UNSYM     =  2 ! real unsymmetric
   integer, parameter :: HSL_MATRIX_REAL_SYM_PSDEF =  3 ! real symmetric pos def
   integer, parameter :: HSL_MATRIX_REAL_SYM_INDEF =  4 ! real symmetric indef
   integer, parameter :: HSL_MATRIX_REAL_SKEW      =  6 ! real skew symmetric

   ! matrix types : complex
   integer, parameter :: HSL_MATRIX_CPLX_RECT      = -1 ! complex rectangular
   integer, parameter :: HSL_MATRIX_CPLX_UNSYM     = -2 ! complex unsymmetric
   integer, parameter :: HSL_MATRIX_CPLX_HERM_PSDEF= -3 ! hermitian pos def
   integer, parameter :: HSL_MATRIX_CPLX_HERM_INDEF= -4 ! hermitian indef
   integer, parameter :: HSL_MATRIX_CPLX_SYM       = -5 ! complex symmetric
   integer, parameter :: HSL_MATRIX_CPLX_SKEW      = -6 ! complex skew symmetric

   ! Error flags
   integer, parameter :: MC69_SUCCESS                =  0
   integer, parameter :: MC69_ERROR_ALLOCATION       = -1
   integer, parameter :: MC69_ERROR_MATRIX_TYPE      = -2
   integer, parameter :: MC69_ERROR_N_OOR            = -3
   integer, parameter :: MC69_ERROR_M_NE_N           = -4
   integer, parameter :: MC69_ERROR_PTR_1            = -5
   integer, parameter :: MC69_ERROR_PTR_MONO         = -6
   integer, parameter :: MC69_ERROR_ROW_BAD_ORDER    = -7
   integer, parameter :: MC69_ERROR_ROW_OOR          = -8
   integer, parameter :: MC69_ERROR_ROW_DUP          = -9
   integer, parameter :: MC69_ERROR_ALL_OOR          = -10
   integer, parameter :: MC69_ERROR_MISSING_DIAGONAL = -11
   integer, parameter :: MC69_ERROR_IMAG_DIAGONAL    = -12
   integer, parameter :: MC69_ERROR_MISMATCH_LWRUPR  = -13
   integer, parameter :: MC69_ERROR_UPR_ENTRY        = -14
   integer, parameter :: MC69_ERROR_VAL_MISS         = -15
   integer, parameter :: MC69_ERROR_LMAP_MISS        = -16


   ! warning flags
   integer, parameter :: MC69_WARNING_IDX_OOR          = 1
   integer, parameter :: MC69_WARNING_DUP_IDX          = 2
   integer, parameter :: MC69_WARNING_DUP_AND_OOR      = 3
   integer, parameter :: MC69_WARNING_MISSING_DIAGONAL = 4
   integer, parameter :: MC69_WARNING_MISS_DIAG_OORDUP = 5

!            Possible error returns:

! MC69_ERROR_ALLOCATION         Allocation error
! MC69_ERROR_MATRIX_TYPE        Problem with matrix_type
! MC69_ERROR_N_OOR              n < 0 or m < 0
! MC69_ERROR_PTR_1              ptr(1) < 1
! MC69_ERROR_PTR_MONO           Error in ptr (not monotonic)
! MC69_ERROR_VAL_MISS           Only one of val_in and val_out is present
! MC69_ERROR_ALL_OOR            All the variables in a column are out-of-range
! MC69_ERROR_IMAG_DIAGONAL      Hermitian case and diagonal not real
! MC69_ERROR_ROW_BAD_ORDER      Entries within a column are not sorted by
!                               increasing row index 
! MC69_ERROR_MISMATCH_LWRUPR    Symmetric, skew symmetric or Hermitian: 
!                               entries in upper and lower
!                               triangles do not match
! MC69_ERROR_MISSING_DIAGONAL   Pos def and diagonal entries missing 
! MC69_ERROR_ROW_OOR            Row contains out-of-range entries      
! MC69_ERROR_ROW_DUP            Row contains duplicate entries         
! MC69_ERROR_M_NE_N             Square matrix and m .ne. n        

!           Possible warnings:

! MC69_WARNING_IDX_OOR          Out-of-range variable indices
! MC69_WARNING_DUP_IDX          Duplicated variable indices
! MC69_WARNING_DUP_AND_OOR      out of range and duplicated indices
! MC69_WARNING_MISSING_DIAGONAL Indefinite case and diagonal entries missing
! MC69_WARNING_MISS_DIAG_OORDUP As MC69_WARNING_MISSING_DIAGONAL, and 
!                               out-of-range and/or duplicates


!!!!!!!!!!!!!!!!!!!!!!!!
! Internal types
!!!!!!!!!!!!!!!!!!!!!!!!
type dup_list
   integer :: src
   integer :: dest
   type(dup_list), pointer :: next => null()
end type dup_list

interface mc69_verify
   module procedure mc69_verify_double
end interface mc69_verify
interface mc69_print
   module procedure mc69_print_double
end interface
interface mc69_cscl_clean
   module procedure mc69_cscl_clean_double
end interface mc69_cscl_clean
interface mc69_set_values
   module procedure mc69_set_values_double
end interface mc69_set_values
interface mc69_cscl_convert
   module procedure mc69_cscl_convert_double
end interface mc69_cscl_convert
interface mc69_cscu_convert
   module procedure mc69_cscu_convert_double
end interface mc69_cscu_convert
interface mc69_csclu_convert
   module procedure mc69_csclu_convert_double
end interface mc69_csclu_convert
interface mc69_csrl_convert
   module procedure mc69_csrl_convert_double
end interface mc69_csrl_convert
interface mc69_csru_convert
   module procedure mc69_csru_convert_double
end interface mc69_csru_convert
interface mc69_csrlu_convert
   module procedure mc69_csrlu_convert_double
end interface mc69_csrlu_convert
interface mc69_coord_convert
   module procedure mc69_coord_convert_double
end interface mc69_coord_convert

contains

!
! To verify that a matrix is in HSL format, or identify why it is not
!
subroutine mc69_verify_double(lp, matrix_type, m, n, ptr, row, flag, more, val)
   integer, intent(in) :: lp ! output unit
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: m ! number of rows
   integer, intent(in) :: n ! number of columns
   integer, dimension(*), intent(in) :: ptr ! column starts
   integer, dimension(*), intent(in) :: row ! row indices.
     ! Entries within each column must be sorted in order of 
     ! increasing row index. no duplicates and/or out of range entries allowed.
   integer, intent(out) :: flag ! return code
   integer, intent(out) :: more ! futher error information (or set to 0)
   real(wp), dimension(:), optional, intent(in) :: val ! matrix values,if any

   integer :: col ! current column
   character(50)  :: context  ! Procedure name (used when printing).
   logical :: diag ! flag for detection of diagonal
   integer :: i
   integer :: j
   integer :: k
   integer :: last ! last row index
   logical :: lwronly
   integer, dimension(:), allocatable :: ptr2
   integer :: st

   context = 'mc69_verify'
   flag = MC69_SUCCESS

   more = 0 ! ensure more is not undefined.

   ! Check matrix_type
   select case(matrix_type)
   case(0)
      ! Undefined matrix. OK, do nothing
   case(1:4,6)
      ! Real matrix. OK, do nothing
   case(-6:-1)
      ! Complex matrix. Issue error
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,lp,flag)
      return
   case default
      ! Out of range value. Issue error
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,lp,flag)
      return
   end select

   ! Check m and n are valid; skip remaining tests if n=0
   if(n < 0 .or. m < 0) then
      flag = MC69_ERROR_N_OOR
      call mc69_print_flag(context,lp,flag)
      return
   end if
   if(abs(matrix_type).ne.HSL_MATRIX_REAL_RECT .and. m.ne.n) then
      flag = MC69_ERROR_M_NE_N
      call mc69_print_flag(context,lp,flag)
      return
   endif
   if(n == 0 .or. m == 0) return

   ! Check ptr(1) is valid
   if(ptr(1) < 1) then
      more = ptr(1)
      flag = MC69_ERROR_PTR_1
      call mc69_print_flag(context,lp,flag)
      return
   end if

   ! Check ptr is monotonically increasing
   do i = 1, n
      if(ptr(i+1).ge.ptr(i)) cycle ! ptr is monotonically increasing, good.
      flag = MC69_ERROR_PTR_MONO
      more = i + 1
      call mc69_print_flag(context,lp,flag)
      return
   end do

   ! Count number of entries in each row. Also:
   ! * Check ordering of entries
   ! * Check for out-of-range entries
   ! * Check for duplicate entries
   ! * Lack of diagonal entries in real pos. def. case.

   ! ptr2(k+2) is set to hold the number of entries in row k
   allocate(ptr2(m+2), stat=st)
   if(st.ne.0) goto 100
   ptr2(:) = 0

   lwronly = (abs(matrix_type).ne.HSL_MATRIX_UNDEFINED) .and. &
             (abs(matrix_type).ne.HSL_MATRIX_REAL_RECT) .and. &
             (abs(matrix_type).ne.HSL_MATRIX_REAL_UNSYM)
   do col = 1, n
      last = -1
      diag = .false.
      do j = ptr(col), ptr(col+1)-1
         k = row(j)
         ! Check out-of-range
         if(k.lt.1 .or. k.gt.m) then
            flag = MC69_ERROR_ROW_OOR
            more = j
            call mc69_print_flag(context,lp,flag)
            return
         endif
         if(lwronly .and. k.lt.col) then
            flag = MC69_ERROR_UPR_ENTRY
            more = j
            call mc69_print_flag(context,lp,flag)
            return
         endif
         if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW .and. k.eq.col) then
            flag = MC69_ERROR_UPR_ENTRY
            more = j
            call mc69_print_flag(context,lp,flag)
            return
         endif
         ! Check duplicate
         if(k.eq.last) then
            flag = MC69_ERROR_ROW_DUP
            more = j-1
            call mc69_print_flag(context,lp,flag)
            return
         endif
         ! Check order
         if(k.lt.last) then
            flag = MC69_ERROR_ROW_BAD_ORDER
            more = j
            call mc69_print_flag(context,lp,flag)
            return
         endif
         ! Check for diagonal
         diag = diag .or. (k.eq.col)
         ! Increase count for row k
         ptr2(k+2) = ptr2(k+2) + 1
         ! Store value for next loop
         last = k
      end do
      ! If marked as positive definite, check if diagonal was present
      if(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_PSDEF .and. .not.diag) then
         flag = MC69_ERROR_MISSING_DIAGONAL
         more = col
         call mc69_print_flag(context,lp,flag)
         return
      endif
   end do

   if(present(val)) then
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SYM_PSDEF)
         ! Check for positive diagonal entries
         do j = 1,n
            k = ptr(j)
            ! Note: column cannot be empty as previously checked pattern ok
            if(real(val(k))<=zero) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               more = j
               call mc69_print_flag(context,lp,flag)
               return
            end if 
         end do
      end select
   endif

   return

   100 continue ! Allocation error
   flag = MC69_ERROR_ALLOCATION
   more = st
   call mc69_print_flag(context,lp,flag)
   return

end subroutine mc69_verify_double

!****************************************

!
! Pretty prints a matrix as best it can
!
subroutine mc69_print_double(lp, lines, matrix_type, m, n, ptr, row, val, cbase)
   integer, intent(in) :: lp ! unit to print on
   integer, intent(in) :: lines ! max number of lines to use (ignored if -ive)
   integer, intent(in) :: matrix_type ! type of matrix
   integer, intent(in) :: m ! number of rows in matrix
   integer, intent(in) :: n ! number of cols in matrix
   integer, dimension(n+1), intent(in) :: ptr ! column pointers
   integer, dimension(ptr(n+1)-1), intent(in) :: row ! row indices
   real(wp), dimension(ptr(n+1)-1), optional, intent(in) :: val ! matrix vals
   logical, optional, intent(in) :: cbase ! is true, rebase for C

   integer :: col, j, k
   integer :: llines
   integer, dimension(:,:), allocatable :: dmat
   character(len=5) :: mfrmt, nfrmt, nefrmt
   character(len=12) :: negfrmt, valfrmt, emptyfrmt
   integer ::  rebase

   if(lp.lt.0) return ! invalid unit

   ! Check if we need to rebase for C consistent output
   rebase = 0
   if(present(cbase)) then
      if(cbase) rebase = 1
   endif

   ! Calculate number of lines to play with
   llines = huge(llines)
   if(lines.gt.0) llines = lines

   ! Print a summary statement about the matrix
   mfrmt = digit_format(m)
   nfrmt = digit_format(n)
   nefrmt = digit_format(ptr(n+1)-1)

   select case(matrix_type)
   case(HSL_MATRIX_UNDEFINED)
      write(lp, "(a)", advance="no") &
         "Matrix of undefined type, dimension "
   case(HSL_MATRIX_REAL_RECT)
      write(lp, "(a)", advance="no") &
         "Real rectangular matrix, dimension "
   case(HSL_MATRIX_REAL_UNSYM)
      write(lp, "(a)", advance="no") &
         "Real unsymmetric matrix, dimension "
   case(HSL_MATRIX_REAL_SYM_PSDEF)
      write(lp, "(a)", advance="no") &
         "Real symmetric positive definite matrix, dimension "
   case(HSL_MATRIX_REAL_SYM_INDEF)
      write(lp, "(a)", advance="no") &
         "Real symmetric indefinite matrix, dimension "
   case(HSL_MATRIX_REAL_SKEW)
      write(lp, "(a)", advance="no") &
         "Real skew symmetric matrix, dimension "
   case default
      write(lp, "(a,i5)") &
         "Unrecognised matrix_type = ", matrix_type
      return
   end select
   write(lp, mfrmt, advance="no") m
   write(lp, "(a)", advance="no") "x"
   write(lp, nfrmt, advance="no") n
   write(lp, "(a)", advance="no") " with "
   write(lp, nefrmt, advance="no") ptr(n+1)-1
   write(lp, "(a)") " entries."

   ! immediate return if m = 0 or n = 0
   if (m == 0 .or. n == 0) return

   if(((present(val) .and. n.lt.10) .or. (.not.present(val) .and. n.lt.24)) &
         .and. m+1.le.llines) then
      ! Print the matrix as if dense
      allocate(dmat(m, n))
      dmat(:,:) = 0
      do col = 1, n
         do j = ptr(col), ptr(col+1) - 1
            k = row(j)
            if(abs(matrix_type).ge.HSL_MATRIX_REAL_SYM_PSDEF) then
               dmat(col, k) = -j
            endif
            dmat(k, col) = j
         end do
      end do

      select case(n)
      case(:6)
         valfrmt = "(1x,es12.4)"
         negfrmt = valfrmt
         emptyfrmt = "(1x,a12)"
      case(7)
         valfrmt = "(1x,es10.2)"
         negfrmt = valfrmt
         emptyfrmt = "(1x,a10)"
      case(8:)
         valfrmt = "(1x,es8.2)"
         negfrmt = "(1x,es8.1)"
         emptyfrmt = "(1x,a8)"
      end select

      do k = 1, m
         write(lp,mfrmt,advance="no") k-rebase
         write(lp,"(':')",advance="no")
         if(present(val)) then
            do j = 1, n
               if(dmat(k,j).eq.0) then 
                  ! nothing here
                  write(lp,emptyfrmt,advance="no") '                         '
               elseif(dmat(k,j).gt.0) then
                  if(val(dmat(k,j)).gt.zero) then
                     write(lp,valfrmt,advance="no") val(dmat(k,j))
                  else
                     write(lp,negfrmt,advance="no") val(dmat(k,j))
                  endif
               else
                  ! in upper triangle
                  select case(matrix_type)
                  case(HSL_MATRIX_REAL_SYM_INDEF,HSL_MATRIX_REAL_SYM_PSDEF)
                     if(val(-dmat(k,j)).gt.zero) then
                        write(lp,valfrmt,advance="no") val(-dmat(k,j))
                     else
                        write(lp,negfrmt,advance="no") val(-dmat(k,j))
                     endif
                  case(HSL_MATRIX_REAL_SKEW)
                     if(-val(-dmat(k,j)).gt.zero) then
                        write(lp,valfrmt,advance="no") -val(-dmat(k,j))
                     else
                        write(lp,negfrmt,advance="no") -val(-dmat(k,j))
                     endif
                  end select
               endif
            end do
         else ! pattern only
            do j = 1, n
               if(dmat(k,j).eq.0) then 
                  ! nothing here
                  write(lp,"('  ')",advance="no")
               else
                  write(lp,"(1x,'x')",advance="no")
               endif
            end do
         end if
         write(lp,"()")
      end do
   else
      ! Output first x entries from each column
      llines = llines - 1 ! Discount first info line
      if(llines.le.2) return
      write(lp, "(a)") "First 4 entries in columns:"
      llines = llines - 1
      do col = 1, llines
         write(lp, "(a)", advance="no") "Col "
         write(lp, nfrmt, advance="no") col-rebase
         write(lp, "(':')", advance="no")
         do j = ptr(col), min(ptr(col+1)-1, ptr(col)+3)
            write(lp, "('  ')", advance="no")
            write(lp, mfrmt, advance="no") row(j)-rebase
            if(present(val)) then
               write(lp, "(' (',es12.4,')')", advance="no") val(j)
            endif
         end do
         write(lp, "()")
      end do
   endif
end subroutine mc69_print_double

!****************************************

character(len=5) function digit_format(x)
   integer, intent(in) :: x

   integer :: ndigit

   ndigit = int(log10(real(x))) + 1
   if(ndigit<10) then
      write(digit_format,"('(i',i1,')')") ndigit
   else
      write(digit_format,"('(i',i2,')')") ndigit
   endif
end function digit_format

!****************************************

! Convert a matrix held in lower compressed sparse column format to standard
! HSL format in-place. Duplicates are summed and out-of-range entries are
! remove.  For symmetric, skew-symmetric and Hermitian matrices, entries in 
! the upper triangle are removed and discarded.
!
! Note: this routine is in place! cscl_convert is the out of place version.
subroutine mc69_cscl_clean_double(matrix_type, m, n, ptr, row, flag, &
      val, lmap, map, lp, noor, ndup) 
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: m, n ! matrix dimensions
   integer, dimension(n+1), intent(inout) :: ptr ! column pointers
   integer, dimension(*), intent(inout) :: row ! row indices
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(inout) :: val ! values
   integer, optional, intent(out) :: lmap ! size of map
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives source: map(i) = j means val_out(i)=val(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed


   ! Local variables
   integer :: col ! current column
   character(50)  :: context  ! Procedure name (used when printing).
   integer :: i
   integer :: idiag ! number of columns with a diagonal entry
   integer :: idup ! number of duplicates summed
   integer :: ioor ! number of out-of-range entries
   integer :: j
   integer :: k
   integer :: k1
   integer :: k2
   integer :: l
   integer :: nout ! output unit (set to -1 if nout not present)
   integer :: st ! stat parameter
   integer, allocatable :: temp(:) ! work array

   context = 'mc69_cscl_clean'

   flag = MC69_SUCCESS

   nout = -1
   if(present(lp)) nout = lp

   ! ---------------------------------------------
   ! Check that restrictions are adhered to
   ! ---------------------------------------------

   ! Note: have to change this test for complex code
   if(matrix_type < 0 .or. matrix_type == 5 .or. matrix_type > 6) then
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(m < 0 .or. n < 0) then
      flag = MC69_ERROR_N_OOR
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(abs(matrix_type) > 1 .and. m /= n) then
      flag = MC69_ERROR_M_NE_N
      call mc69_print_flag(context,nout,flag)
      return
   end if
 
   if(ptr(1) < 1) then
      flag = MC69_ERROR_PTR_1
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(map).neqv.present(lmap)) then
      flag = MC69_ERROR_LMAP_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   ! ---------------------------------------------

   ! allocate work array

   allocate(temp(m),stat=st)
   if(st /= 0) then
      flag = MC69_ERROR_ALLOCATION
      call mc69_print_flag(context,lp,flag)
      return
   endif
   temp(:) = 0

   ! count duplicates and out-of-range indices
   idup = 0
   ioor = 0
   idiag = 0
   k = 0 ! last diagonal seen
   l = 1
   do col = 1, n
      if(ptr(col+1).lt.ptr(col)) then
         flag = MC69_ERROR_PTR_MONO
         call mc69_print_flag(context,nout,flag)
         return
      endif
      if(abs(matrix_type) > 2) l = col
      do i = ptr(col), ptr(col+1)-1
         j = row(i)
         if(j<l .or. j>m) then
            ioor = ioor + 1
            row(i) = m+1
         else
            if(temp(j)==col) idup = idup + 1
            temp(j) = col
         end if
         if(j.eq.col .and. k<col) then
            idiag = idiag + 1
            k = col
         endif
      end do
   end do
   if(present(ndup)) ndup = idup
   if(present(noor)) noor = ioor
   deallocate(temp,stat=st)
   

   k = 0
   l = ptr(n+1) 
   if(present(map)) then
      deallocate(map,stat=st)
      lmap = l - 1 - ioor + idup
      allocate(map(l-1+idup*2),stat=st)
      if(st /= 0) then
         flag = MC69_ERROR_ALLOCATION
         call mc69_print_flag(context,lp,flag)
         return
      endif
      do i = 1,ptr(n+1)-1
         map(i) = i
      end do
      if(present(val)) then
         do col = 1, n
            k1 = ptr(col)
            ptr(col) = k + 1
            k2 = ptr(col+1)-1
            if(k2-k1<0) cycle
            call sort (row(k1), k2-k1+1, map=map(k1:), val=val(k1))
            ! Squeeze out duplicates and out-of-range indices
            if(row(k1) /= m+1) then
               k = k + 1      
               row(k) = row(k1)
               map(k) = map(k1)
               val(k) = val(k1)
            end if
            do i = k1+1,k2
               if(row(i) == m+1) then
                  exit             
               else if(row(i)>row(i-1)) then
                  k = k + 1
                  row(k) = row(i)
                  map(k) = map(i)
                  val(k) = val(i)
               else
                  map(l) = k
                  map(l+1) = map(i)
                  val(k) = val(k) + val(i)
                  l = l + 2
               end if
            end do
         end do
      else 
         do col = 1, n
            k1 = ptr(col)
            ptr(col) = k + 1
            k2 = ptr(col+1)-1
            if(k2-k1<0) cycle
            call sort (row(k1), k2-k1+1, map=map(k1:))
            ! Squeeze out duplicates and out-of-range indices
            if(row(k1) /= m+1) then
               k = k + 1      
               row(k) = row(k1)
               map(k) = map(k1)
            end if
            do i = k1+1,k2
               if(row(i) == m+1) then
                  exit             
               else if(row(i)>row(i-1)) then
                  k = k + 1
                  row(k) = row(i)
                  map(k) = map(i)
               else
                  map(l) = k
                  map(l+1) = map(i)
                  l = l + 2
               end if
            end do
         end do
      end if
      l = ptr(n+1) - 1
      ptr(n+1) = k + 1
      ! Move duplicate pair in map forward
      do i = 1, idup*2
         map(k+i) = map(l+i)
      end do
   else if(present(val)) then
      do col = 1, n
         k1 = ptr(col)
         ptr(col) = k + 1
         k2 = ptr(col+1)-1
         if(k2-k1<0) cycle
         call sort (row(k1), k2-k1+1, val=val(k1))
         ! Squeeze out duplicates and out-of-range indices
         if(row(k1) /= m+1) then
            k = k + 1      
            row(k) = row(k1)
            val(k) = val(k1)
         end if
         do i = k1+1,k2
            if(row(i) == m+1) then
               exit             
            else if(row(i)>row(i-1)) then
               k = k + 1
               row(k) = row(i)
               val(k) = val(i)
            else
               val(k) = val(k) + val(i)
               l = l + 2
            end if
         end do
      end do
      ptr(n+1) = k + 1
   else 
      do col = 1, n
         k1 = ptr(col)
         ptr(col) = k + 1
         k2 = ptr(col+1)-1
         if(k2-k1<0) cycle
         call sort (row(k1), k2-k1+1)
         ! Squeeze out duplicates and out-of-range indices
         if(row(k1) /= m+1) then
            k = k + 1      
            row(k) = row(k1)
         end if
         do i = k1+1,k2
            if(row(i) == m+1) then
               exit             
            else if(row(i)>row(i-1)) then
               k = k + 1
               row(k) = row(i)
            end if
         end do
      end do
      ptr(n+1) = k + 1
   end if

   select case(matrix_type)
   case(HSL_MATRIX_REAL_SYM_PSDEF)
      ! Check for positive diagonal entries
      do j = 1,n
         k = ptr(j)
         ! Note: we're OK if the column is empty - row(k) is still a diagonal
         ! entry, however we must be careful that we've not gone past the
         ! end of the matrix
         if(k.ge.ptr(n+1)) exit
         if(row(k)/=j)then
            flag = MC69_ERROR_MISSING_DIAGONAL
            call mc69_print_flag(context,nout,flag)
            return
         end if
         if(present(val))then
            if(val(k)<=zero)then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               return
            end if 
         end if 
      end do
   end select

   ! Check whether a warning needs to be raised
   if(ioor > 0 .or. idup > 0 .or. idiag < n) then
     if(ioor > 0) flag = MC69_WARNING_IDX_OOR
     if(idup > 0) flag = MC69_WARNING_DUP_IDX
     if(idup > 0 .and. ioor > 0) flag = MC69_WARNING_DUP_AND_OOR
     if(abs(matrix_type) .ne. HSL_MATRIX_REAL_SKEW) then
         if(idiag < n .and. ioor > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n .and. idup > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n) then
            flag = MC69_WARNING_MISSING_DIAGONAL
         end if
      endif
      call mc69_print_flag(context,nout,flag)
   end if

end subroutine mc69_cscl_clean_double

!****************************************

!
! Converts CSC with lower entries only for symmetric, skew-symmetric and
! Hermitian matrices to HSL standard format
!
subroutine mc69_cscl_convert_double(matrix_type, m, n, ptr_in, row_in, ptr_out,&
      row_out, flag, val_in, val_out, lmap, map, lp, noor, ndup) 
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: m ! number of rows
   integer, intent(in) :: n ! number of columns
   integer, dimension(*), intent(in) :: ptr_in ! column pointers on input
   integer, dimension(*), intent(in) :: row_in ! row indices on input.
      ! These may be unordered within each column and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed

   ! Local variables
   character(50)  :: context  ! Procedure name (used when printing).
   integer :: nout ! output unit (set to -1 if nout not present)

   context = 'mc69_cscl_convert'

   nout = -1
   if(present(lp)) nout = lp

   ! Note: have to change this test for complex code
   if(matrix_type < 0 .or. matrix_type == 5 .or. matrix_type > 6) then
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,nout,flag)
      return
   end if

   call mc69_cscl_convert_main(context, 1, matrix_type, m, n, &
      ptr_in, row_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
end subroutine mc69_cscl_convert_double

!****************************************

!
! Converts CSC (with lower entries only for symmetric, skew-symmetric and
! Hermitian matrices) to HSL standard format.
! Also used for symmetric, skew-symmetric and Hermitian matrices in upper
! CSR format
!
subroutine mc69_cscl_convert_main(context, multiplier, matrix_type, m, n, &
      ptr_in, row_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
   character(50), intent(in) :: context ! Procedure name (used when printing).
   integer, intent(in) :: multiplier ! -1 or 1, differs for csc/csr
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: m ! number of rows
   integer, intent(in) :: n ! number of columns
   integer, dimension(*), intent(in) :: ptr_in ! column pointers on input
   integer, dimension(*), intent(in) :: row_in ! row indices on input.
      ! These may be unordered within each column and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed


   ! Local variables
   integer :: col ! current column
   integer :: i
   integer :: idiag
   integer :: idup
   integer :: ioor
   integer :: j
   integer :: k
   integer :: nout ! output unit (set to -1 if nout not present)
   integer :: st ! stat parameter
   integer :: minidx

   type(dup_list), pointer :: dup
   type(dup_list), pointer :: duphead

   ! ---------------------------------------------
   ! Check that restrictions are adhered to
   ! ---------------------------------------------

   nullify(dup, duphead)

   flag = MC69_SUCCESS

   nout = -1
   if(present(lp)) nout = lp

   if(n < 0 .or. m < 0) then
      flag = MC69_ERROR_N_OOR
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(ptr_in(1) < 1) then
      flag = MC69_ERROR_PTR_1
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(val_in).neqv.present(val_out)) then
      flag = MC69_ERROR_VAL_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(map).neqv.present(lmap)) then
      flag = MC69_ERROR_LMAP_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   ! ---------------------------------------------

   ! ensure output arrays are not allocated

   deallocate(row_out,stat=st)
   if(present(val_out)) deallocate(val_out,stat=st)
   if(present(map)) deallocate(map,stat=st)

   idup = 0
   ioor = 0
   idiag = 0

   allocate(row_out(ptr_in(n+1)-1),stat=st)
   if(st.ne.0) goto 100
   if(present(map)) then
      ! Allocate map for worst case where all bar one are duplicates
      allocate(map(2*ptr_in(n+1)-2),stat=st)
      k = 1 ! insert location
      do col = 1, n
         ptr_out(col) = k
         if(ptr_in(col+1).lt.ptr_in(col)) then
            flag = MC69_ERROR_PTR_MONO
            call mc69_print_flag(context,nout,flag)
            call cleanup_dup(duphead)
            return
         endif
         minidx = 1
         if(abs(matrix_type).ge.HSL_MATRIX_REAL_SYM_PSDEF) minidx = col
         if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) minidx = col + 1
         ! Loop over column, copy across while dropping any out of range entries
         do i = ptr_in(col), ptr_in(col+1)-1
            j = row_in(i)
            if(j.lt.minidx .or. j.gt.m) then
               ! out of range, ignore
               ioor = ioor + 1
               cycle
            endif
            row_out(k) = row_in(i)
            map(k) = multiplier*i
            k = k + 1
         end do
         ! Sort entries into order
         i = k - ptr_out(col)
         if(i.eq.0 .and. ptr_in(col+1)-ptr_in(col).ne.0) then
            flag = MC69_ERROR_ALL_OOR
            call mc69_print_flag(context,nout,flag)
            call cleanup_dup(duphead)
            return
         endif
         if(i.ne.0) then
            call sort(row_out(ptr_out(col):k-1), i, map=map(ptr_out(col):k-1))
            ! Loop over sorted list and drop duplicates
            i = k-1 ! last entry in column
            k = ptr_out(col)+1 ! insert position
            ! Note: we are skipping the first entry as it cannot be a duplicate
            if(row_out(ptr_out(col)).eq.col) then
               idiag = idiag + 1
            elseif(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_PSDEF) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               call cleanup_dup(duphead)
               return
            endif
            do i = ptr_out(col)+1, i
               if(row_out(i).eq.row_out(i-1)) then
                  ! duplicate, drop
                  idup = idup + 1
                  allocate(dup,stat=st)
                  if(st.ne.0) goto 100
                  dup%next => duphead
                  duphead => dup
                  dup%src = map(i)
                  dup%dest = k-1
                  cycle
               endif
               if(row_out(i).eq.col) idiag = idiag + 1
               row_out(k) = row_out(i)
               map(k) = map(i)
               k = k + 1
            end do
         elseif(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_PSDEF) then
            flag = MC69_ERROR_MISSING_DIAGONAL
            call mc69_print_flag(context,nout,flag)
            call cleanup_dup(duphead)
            return
         endif
      end do
      ptr_out(n+1) = k
      lmap = k-1
   elseif(present(val_out)) then
      allocate(val_out(ptr_in(n+1)-1),stat=st)
      if(st.ne.0) goto 100
      k = 1 ! insert location
      do col = 1, n
         ptr_out(col) = k
         if(ptr_in(col+1).lt.ptr_in(col)) then
            flag = MC69_ERROR_PTR_MONO
            call mc69_print_flag(context,nout,flag)
            return
         endif
         minidx = 1
         if(abs(matrix_type).ge.HSL_MATRIX_REAL_SYM_PSDEF) minidx = col
         if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) minidx = col + 1
         ! Loop over column, copy across while dropping any out of range entries
         select case(matrix_type)
         case(HSL_MATRIX_REAL_SKEW)
            do i = ptr_in(col), ptr_in(col+1)-1
               j = row_in(i)
               if(j.lt.minidx .or. j.gt.m) then
                  ! out of range, ignore
                  ioor = ioor + 1
                  cycle
               endif
               row_out(k) = row_in(i)
               val_out(k) = multiplier*val_in(i)
               k = k + 1
            end do
         case default
            do i = ptr_in(col), ptr_in(col+1)-1
               j = row_in(i)
               if(j.lt.minidx .or. j.gt.m) then
                  ! out of range, ignore
                  ioor = ioor + 1
                  cycle
               endif
               row_out(k) = row_in(i)
               val_out(k) = val_in(i)
               k = k + 1
            end do
         end select
         ! Sort entries into order
         i = k - ptr_out(col)
         if(i.eq.0 .and. ptr_in(col+1)-ptr_in(col).ne.0) then
            flag = MC69_ERROR_ALL_OOR
            call mc69_print_flag(context,nout,flag)
            return
         endif
         if(i.ne.0) then
            call sort(row_out(ptr_out(col):k-1), i, &
               val=val_out(ptr_out(col):k-1))
            ! Loop over sorted list and drop duplicates
            i = k-1 ! last entry in column
            k = ptr_out(col)+1 ! insert position
            ! Note: we are skipping the first entry as it cannot be a duplicate
            if(row_out(ptr_out(col)).eq.col) then
               idiag = idiag + 1
            elseif(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_PSDEF) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               return
            endif
            do i = ptr_out(col)+1, i
               if(row_out(i).eq.row_out(i-1)) then
                  ! duplicate, sum then drop from pattern
                  idup = idup + 1
                  val_out(i-1) = val_out(i-1) + val_out(i)
                  cycle
               endif
               if(row_out(i).eq.col) idiag = idiag + 1
               row_out(k) = row_out(i)
               val_out(k) = val_out(i)
               k = k + 1
            end do
         elseif(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_PSDEF) then
            flag = MC69_ERROR_MISSING_DIAGONAL
            call mc69_print_flag(context,nout,flag)
            return
         endif
      end do
      ptr_out(n+1) = k
   else ! pattern only
      k = 1 ! insert location
      do col = 1, n
         ptr_out(col) = k
         if(ptr_in(col+1).lt.ptr_in(col)) then
            flag = MC69_ERROR_PTR_MONO
            call mc69_print_flag(context,nout,flag)
            return
         endif
         minidx = 1
         if(abs(matrix_type).ge.HSL_MATRIX_REAL_SYM_PSDEF) minidx = col
         if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) minidx = col + 1
         ! Loop over column, copy across while dropping any out of range entries
         do i = ptr_in(col), ptr_in(col+1)-1
            j = row_in(i)
            if(j.lt.minidx .or. j.gt.m) then
               ! out of range, ignore
               ioor = ioor + 1
               cycle
            endif
            row_out(k) = row_in(i)
            k = k + 1
         end do
         ! Sort entries into order
         i = k - ptr_out(col)
         if(i.eq.0 .and. ptr_in(col+1)-ptr_in(col).ne.0) then
            flag = MC69_ERROR_ALL_OOR
            call mc69_print_flag(context,nout,flag)
            return
         endif
         if(i.ne.0) then
            call sort(row_out(ptr_out(col):k-1), i)
            ! Loop over sorted list and drop duplicates
            i = k-1 ! last entry in column
            k = ptr_out(col)+1 ! insert position
            ! Note: we are skipping the first entry as it cannot be a duplicate
            if(row_out(ptr_out(col)).eq.col) then
               idiag = idiag + 1
            elseif(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_PSDEF) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               return
            endif
            do i = ptr_out(col)+1, i
               if(row_out(i).eq.row_out(i-1)) then
                  ! duplicate, drop
                  idup = idup + 1
                  cycle
               endif
               if(row_out(i).eq.col) idiag = idiag + 1
               row_out(k) = row_out(i)
               k = k + 1
            end do
         elseif(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_PSDEF) then
            flag = MC69_ERROR_MISSING_DIAGONAL
            call mc69_print_flag(context,nout,flag)
            return
         end if
      end do
      ptr_out(n+1) = k
   endif

   if(present(map)) then
      ! Append duplicates to map
      do while(associated(duphead))
         idup = idup + 1
         map(lmap+1) = duphead%dest
         map(lmap+2) = duphead%src
         lmap = lmap + 2
         dup => duphead%next
         deallocate(duphead)
         duphead => dup
      end do
      if(present(val_out)) then
         allocate(val_out(ptr_out(n+1)-1), stat=st)
         if(st.ne.0) goto 100
         call mc69_set_values(matrix_type, lmap, map, val_in, ptr_out(n+1)-1, &
            val_out)
      endif
   endif

   if(present(val_out)) then
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SYM_PSDEF)
         ! Check for positive diagonal entries
         do j = 1,n
            k = ptr_out(j)
            ! ps def case - can't reach here unless all entries have diagonal
            if(real(val_out(k))<=zero) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               return
            end if 
         end do
      end select
   endif

   ! Check whether a warning needs to be raised
   if(ioor > 0 .or. idup > 0 .or. idiag < n) then
     if(ioor > 0) flag = MC69_WARNING_IDX_OOR
     if(idup > 0) flag = MC69_WARNING_DUP_IDX
     if(idup > 0 .and. ioor > 0) flag = MC69_WARNING_DUP_AND_OOR
     if(abs(matrix_type) .ne. HSL_MATRIX_REAL_SKEW) then
         if(idiag < n .and. ioor > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n .and. idup > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n) then
            flag = MC69_WARNING_MISSING_DIAGONAL
         end if
      endif
      call mc69_print_flag(context,nout,flag)
   end if

   if(present(noor)) noor = ioor
   if(present(ndup)) ndup = idup

   return

100 if(st /= 0) then
      flag = MC69_ERROR_ALLOCATION
      call mc69_print_flag(context,nout,flag)
    end if

end subroutine mc69_cscl_convert_main

!****************************************

!
! Converts CSC with only upper entries present to CSC with 
! only lower entries present and entries
! within each column ordered by increasing row index (HSL standard format)
!
subroutine mc69_cscu_convert_double(matrix_type, n, ptr_in, row_in, ptr_out, &
      row_out, flag, val_in, val_out, lmap, map, lp, noor, ndup) 
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: n ! matrix dimension
   integer, dimension(*), intent(in) :: ptr_in ! row pointers on input
   integer, dimension(*), intent(in) :: row_in ! col indices on input.
      ! These may be unordered within each row and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed

   ! Local variables
   character(50)  :: context  ! Procedure name (used when printing).
   integer :: nout ! output unit (set to -1 if nout not present)

   context = 'mc69_cscu_convert'

   nout = -1
   if(present(lp)) nout = lp

   ! Note: have to change this test for complex code
   if(matrix_type < 3 .or. matrix_type == 5 .or. matrix_type > 6) then
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,nout,flag)
      return
   end if

   call mc69_csrl_convert_main(context, -1, matrix_type, n, n, &
      ptr_in, row_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
end subroutine mc69_cscu_convert_double

!****************************************

!
! Converts CSC with both lower and upper entries present to CSC with 
! only lower entries present and entries
! within each column ordered by increasing row index (HSL standard format)
!
subroutine mc69_csclu_convert_double(matrix_type, n, ptr_in, row_in, ptr_out, &
      row_out, flag, val_in, val_out, lmap, map, lp, noor, ndup) 
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: n ! matrix dimension
   integer, dimension(*), intent(in) :: ptr_in ! column pointers on input
   integer, dimension(*), intent(in) :: row_in ! row indices on input.
      ! These may be unordered within each column and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed

   ! Local variables
   character(50)  :: context  ! Procedure name (used when printing).
   integer :: nout ! output unit (set to -1 if nout not present)

   context = 'mc69_csclu_convert'

   nout = -1
   if(present(lp)) nout = lp

   ! Note: have to change this test for complex code
   if(matrix_type < 3 .or. matrix_type == 5 .or. matrix_type > 6) then
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,nout,flag)
      return
   end if

   call mc69_csclu_convert_main(context, -1, matrix_type, n, &
      ptr_in, row_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
end subroutine mc69_csclu_convert_double

!****************************************

subroutine mc69_csclu_convert_main(context, multiplier, matrix_type, n, &
      ptr_in, row_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
   character(50), intent(in) :: context  ! Procedure name (used when printing).
   integer, intent(in) :: multiplier ! -1 for upr source, +1 for lwr
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: n ! matrix dimension
   integer, dimension(*), intent(in) :: ptr_in ! column pointers on input
   integer, dimension(*), intent(in) :: row_in ! row indices on input.
      ! These may be unordered within each column and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed


   ! Local variables
   integer :: col ! current column
   integer :: i
   integer :: idiag
   integer :: idup
   integer :: ioor
   integer :: j
   integer :: k
   integer :: nlwr ! number of strictly lower triangular entries
   integer :: npre
   integer :: nupr ! number of strictly upper triangular entries
   integer :: ne    
   integer :: nout ! output unit (set to -1 if nout not present)
   integer :: st ! stat parameter

   type(dup_list), pointer :: dup
   type(dup_list), pointer :: duphead

   nullify(dup, duphead)

   ! ---------------------------------------------
   ! Check that restrictions are adhered to
   ! ---------------------------------------------

   flag = MC69_SUCCESS

   nout = -1
   if(present(lp)) nout = lp

   if(n < 0) then
      flag = MC69_ERROR_N_OOR
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(ptr_in(1) < 1) then
      flag = MC69_ERROR_PTR_1
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(val_in).neqv.present(val_out)) then
      flag = MC69_ERROR_VAL_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(map).neqv.present(lmap)) then
      flag = MC69_ERROR_LMAP_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   ! ---------------------------------------------

   ! allocate output and work arrays

   deallocate(row_out,stat=st)
   if(present(val_out)) deallocate(val_out,stat=st)
   if(present(map)) deallocate(map,stat=st)


   ! ---------------------------------------------
   ! check for duplicates and/or out-of-range. check diagonal present.
   ! first do the case where values not present

   idup = 0
   ioor = 0
   idiag = 0
   nlwr = 0
   nupr = 0

   !
   ! First pass, count number of entries in each row of the matrix.
   ! Count is at an offset of 1 to allow us to play tricks
   ! (ie. ptr_out(i+1) set to hold number of entries in column i
   ! of expanded matrix).
   ! Excludes out of range entries. Includes duplicates.
   !
   ptr_out(1:n+1) = 0
   k = 0 ! last diagonal found
   do col = 1, n
      if(ptr_in(col+1).lt.ptr_in(col)) then
         flag = MC69_ERROR_PTR_MONO
         call mc69_print_flag(context,nout,flag)
         return
      endif
      npre = nlwr + nupr + idiag
      if(ptr_in(col+1).eq.ptr_in(col)) cycle ! no entries in column
      do i = ptr_in(col), ptr_in(col+1)-1
         j = row_in(i)
         if(j.lt.1 .or. j.gt.n) then
            ioor = ioor + 1
            cycle
         endif
         if(j.eq.col .and. abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) then
            ioor = ioor + 1
            cycle
         endif
         if(j.gt.col) then
            nlwr = nlwr + 1
            cycle
         endif
         if(j.lt.col) then
            nupr = nupr + 1
         elseif(j.ne.k) then ! diagonal entry (not second in column)
            idiag = idiag + 1
            k = col
         endif
         ptr_out(j+1) = ptr_out(j+1) + 1
      end do
      if(nlwr+nupr+idiag.eq.npre) then
         ! Column contains only out of range entries
         flag = MC69_ERROR_ALL_OOR
         call mc69_print_flag(context,nout,flag)
         return
      endif
   end do

   ! Check for missing diagonals in pos def case
   ! Note: change this test for complex case
   if(abs(matrix_type) == HSL_MATRIX_REAL_SYM_PSDEF) then
     if(idiag < n) then
         flag = MC69_ERROR_MISSING_DIAGONAL
         call mc69_print_flag(context,nout,flag)
         return
      end if
   end if

   ! Check number in lower triangle = number in upper triangle
   if(nlwr .ne. nupr) then
      flag = MC69_ERROR_MISMATCH_LWRUPR
      call mc69_print_flag(context,nout,flag)
      return
   endif

   ! Determine column starts for transposed matrix such 
   ! that column i starts at ptr_out(i+1)
   ne = 0
   ptr_out(1) = 1
   do i = 1, n
      ne = ne + ptr_out(i+1)
      ptr_out(i+1) = ptr_out(i) + ptr_out(i+1)
   end do
   do i = n,1,-1
      ptr_out(i+1) = ptr_out(i)
   end do

   !
   ! Second pass, drop entries into place for conjugate of transposed
   ! matrix
   !
   allocate(row_out(ne), stat=st)
   if(st.ne.0) goto 100
   if(present(map)) then
      ! Needs to be this big for worst case: all entries are repeat of same
      allocate(map(2*(ptr_in(n+1)-1)), stat=st)
      if(st.ne.0) goto 100
      do col = 1, n
         do i = ptr_in(col), ptr_in(col+1)-1
            j = row_in(i)
            if(j.lt.1 .or. j.gt.col) cycle ! ignore oor and lwr triangle entries
            if(j.eq.col .and. abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) cycle
            k = ptr_out(j+1)
            ptr_out(j+1) = k + 1
            row_out(k) = col
            map(k) = multiplier*i
         end do
      end do
   elseif(present(val_out)) then
      allocate(val_out(2*(ptr_in(n+1)-1)), stat=st)
      if(st.ne.0) goto 100
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SKEW)
         do col = 1, n
            do i = ptr_in(col), ptr_in(col+1)-1
               j = row_in(i)
               if(j.lt.1 .or. j.ge.col) cycle
               k = ptr_out(j+1)
               ptr_out(j+1) = k + 1
               row_out(k) = col
               val_out(k) = multiplier*val_in(i)
            end do
         end do
      case(HSL_MATRIX_REAL_SYM_PSDEF, HSL_MATRIX_REAL_SYM_INDEF)
         do col = 1, n
            do i = ptr_in(col), ptr_in(col+1)-1
               j = row_in(i)
               if(j.lt.1 .or. j.gt.col) cycle
               k = ptr_out(j+1)
               ptr_out(j+1) = k + 1
               row_out(k) = col
               val_out(k) = val_in(i)
            end do
         end do
      end select
   else ! neither val_out nor map present
      do col = 1, n
         do i = ptr_in(col), ptr_in(col+1)-1
            j = row_in(i)
            if(j.lt.1 .or. j.gt.col) cycle
            if(j.eq.col .and. abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) cycle
            k = ptr_out(j+1)
            ptr_out(j+1) = k + 1
            row_out(k) = col
         end do
      end do
   endif

   !
   ! Third pass, removal of duplicates (no sort required by construction)
   !
   if(present(map)) then
      k = 1 ! insert position
      do col = 1, n
         i = ptr_out(col)
         ptr_out(col) = k
         if(ptr_out(col+1).eq.i) cycle ! no entries
         ! Move first entry of column forward
         row_out(k) = row_out(i)
         map(k) = map(i)
         k = k + 1
         ! Loop over remaining entries
         do i = i+1, ptr_out(col+1)-1
            if(row_out(i).eq.row_out(k-1)) then
               ! Duplicate
               allocate(dup,stat=st)
               if(st.ne.0) goto 100
               dup%next => duphead
               duphead => dup
               dup%src = map(i)
               dup%dest = k-1
               cycle
            endif
            ! Pull entry forwards
            row_out(k) = row_out(i)
            map(k) = map(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
      lmap = k-1
   elseif(present(val_out)) then
      k = 1 ! insert position
      do col = 1, n
         i = ptr_out(col)
         ptr_out(col) = k
         if(ptr_out(col+1).eq.i) cycle ! no entries
         ! Move first entry of column forward
         row_out(k) = row_out(i)
         val_out(k) = val_out(i)
         k = k + 1
         ! Loop over remaining entries
         do i = i+1, ptr_out(col+1)-1
            if(row_out(i).eq.row_out(k-1)) then
               ! Duplicate
               idup = idup + 1
               val_out(k-1) = val_out(k-1) + val_out(i)
               cycle
            endif
            ! Pull entry forwards
            row_out(k) = row_out(i)
            val_out(k) = val_out(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
   else ! neither val_out nor map are present
      k = 1 ! insert position
      do col = 1, n
         i = ptr_out(col)
         ptr_out(col) = k
         if(ptr_out(col+1).eq.i) cycle ! no entries
         ! Move first entry of column forward
         row_out(k) = row_out(i)
         k = k + 1
         ! Loop over remaining entries
         do i = i+1, ptr_out(col+1)-1
            if(row_out(i).eq.row_out(k-1)) then
               ! Duplicate
               idup = idup + 1
               cycle
            endif
            ! Pull entry forwards
            row_out(k) = row_out(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
   endif

   if(present(map)) then
      ! Append duplicates to map
      do while(associated(duphead))
         idup = idup + 1
         map(lmap+1) = duphead%dest
         map(lmap+2) = duphead%src
         lmap = lmap + 2
         dup => duphead%next
         deallocate(duphead)
         duphead => dup
      end do
      if(present(val_out)) then
         allocate(val_out(ptr_out(n+1)-1), stat=st)
         if(st.ne.0) goto 100
         call mc69_set_values(matrix_type, lmap, map, val_in, ptr_out(n+1)-1, &
            val_out)
      endif
   endif

   if(present(val_out)) then
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SYM_PSDEF)
         ! Check for positive diagonal entries
         do j = 1,n
            k = ptr_out(j)
            ! ps def case - can't reach here unless all entries have diagonal
            if(real(val_out(k))<=zero) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               return
            end if 
         end do
      end select
   endif

   ! Check whether a warning needs to be raised
   if(ioor > 0 .or. idup > 0 .or. idiag < n) then
     if(ioor > 0) flag = MC69_WARNING_IDX_OOR
     if(idup > 0) flag = MC69_WARNING_DUP_IDX
     if(idup > 0 .and. ioor > 0) flag = MC69_WARNING_DUP_AND_OOR
     if(abs(matrix_type) .ne. HSL_MATRIX_REAL_SKEW) then
         if(idiag < n .and. ioor > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n .and. idup > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n) then
            flag = MC69_WARNING_MISSING_DIAGONAL
         end if
      endif
      call mc69_print_flag(context,nout,flag)
   end if

   if(present(noor)) noor = ioor
   if(present(ndup)) ndup = idup

   return

100 if(st /= 0) then
      flag = MC69_ERROR_ALLOCATION
      call mc69_print_flag(context,nout,flag)
    end if

end subroutine mc69_csclu_convert_main

!****************************************

!
! Converts CSR with only lower entries present to CSC with 
! only lower entries present and entries
! within each column ordered by increasing row index (HSL standard format)
!
subroutine mc69_csrl_convert_double(matrix_type, m, n, ptr_in, col_in, ptr_out,&
      row_out, flag, val_in, val_out, lmap, map, lp, noor, ndup)
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: m ! matrix dimension
   integer, intent(in) :: n ! matrix dimension
   integer, dimension(*), intent(in) :: ptr_in ! row pointers on input
   integer, dimension(*), intent(in) :: col_in ! col indices on input.
      ! These may be unordered within each row and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed

   ! Local variables
   character(50)  :: context  ! Procedure name (used when printing).
   integer :: nout ! output unit (set to -1 if nout not present)

   context = 'mc69_csrl_convert'

   nout = -1
   if(present(lp)) nout = lp

   ! Note: have to change this test for complex code
   if(matrix_type < 1 .or. matrix_type == 5 .or. matrix_type > 6) then
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,nout,flag)
      return
   end if

   call mc69_csrl_convert_main(context, 1, matrix_type, m, n, &
      ptr_in, col_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
end subroutine mc69_csrl_convert_double

!****************************************

subroutine mc69_csrl_convert_main(context, multiplier, matrix_type, m, n, &
      ptr_in, col_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
   character(50), intent(in) :: context  ! Procedure name (used when printing).
   integer, intent(in) :: multiplier ! 1 for lwr triangle source, -1 for upr
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: m ! matrix dimension
   integer, intent(in) :: n ! matrix dimension
   integer, dimension(*), intent(in) :: ptr_in ! row pointers on input
   integer, dimension(*), intent(in) :: col_in ! col indices on input.
      ! These may be unordered within each row and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed


   ! Local variables
   integer :: row ! current row
   integer :: col ! current col
   integer :: i
   integer :: idiag
   integer :: idup
   integer :: ioor
   integer :: j
   integer :: k
   integer :: ne    
   integer :: nout ! output unit (set to -1 if nout not present)
   integer :: npre ! number of out-of-range entries prior to this column
   integer :: st ! stat parameter
   integer :: maxv ! maximum value before out of range

   type(dup_list), pointer :: dup
   type(dup_list), pointer :: duphead

   nullify(dup, duphead)

   ! ---------------------------------------------
   ! Check that restrictions are adhered to
   ! ---------------------------------------------

   flag = MC69_SUCCESS

   nout = -1
   if(present(lp)) nout = lp

   if(n < 0 .or. m < 0) then
      flag = MC69_ERROR_N_OOR
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(ptr_in(1) < 1) then
      flag = MC69_ERROR_PTR_1
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(val_in).neqv.present(val_out)) then
      flag = MC69_ERROR_VAL_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(map).neqv.present(lmap)) then
      flag = MC69_ERROR_LMAP_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   ! ---------------------------------------------

   ! allocate output and work arrays

   deallocate(row_out,stat=st)
   if(present(val_out)) deallocate(val_out,stat=st)
   if(present(map)) deallocate(map,stat=st)


   ! ---------------------------------------------
   ! check for duplicates and/or out-of-range. check diagonal present.
   ! first do the case where values not present

   idup = 0
   ioor = 0
   idiag = 0

   !
   ! First pass, count number of entries in each col of the matrix.
   ! Count is at an offset of 1 to allow us to play tricks
   ! (ie. ptr_out(i+1) set to hold number of entries in column i
   ! of expanded matrix).
   ! Excludes out of range entries. Includes duplicates.
   !
   ptr_out(1:n+1) = 0
   k = 0 ! last diagonal found
   maxv = n
   do row = 1, m
      if(ptr_in(row+1).lt.ptr_in(row)) then
         flag = MC69_ERROR_PTR_MONO
         call mc69_print_flag(context,nout,flag)
         return
      endif
      npre = ioor
      if(abs(matrix_type).ge.HSL_MATRIX_REAL_SYM_PSDEF) maxv = row
      if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) maxv = row-1
      do i = ptr_in(row), ptr_in(row+1)-1
         j = col_in(i)
         if(j.lt.1 .or. j.gt.maxv) then
            ioor = ioor + 1
            cycle
         endif
         if(j.eq.row .and. j.ne.k) then ! diagonal entry (not second in column)
            idiag = idiag + 1
            k = row
         endif
         ptr_out(j+1) = ptr_out(j+1) + 1
      end do
      if(ioor-npre.ne.0 .and. ptr_in(row+1)-ptr_in(row).eq.ioor-npre) then
         ! Column contains only out of range entries
         flag = MC69_ERROR_ALL_OOR
         call mc69_print_flag(context,nout,flag)
         return
      endif
   end do

   ! Check for missing diagonals in pos def case
   ! Note: change this test for complex case
   if(abs(matrix_type) == HSL_MATRIX_REAL_SYM_PSDEF) then
     if(idiag < n) then
         flag = MC69_ERROR_MISSING_DIAGONAL
         call mc69_print_flag(context,nout,flag)
         return
      end if
   end if

   ! Determine column starts for matrix such 
   ! that column i starts at ptr_out(i+1)
   ne = 0
   ptr_out(1) = 1
   do i = 1, n
      ne = ne + ptr_out(i+1)
      ptr_out(i+1) = ptr_out(i) + ptr_out(i+1)
   end do
   do i = n,1,-1
      ptr_out(i+1) = ptr_out(i)
   end do

   !
   ! Second pass, drop entries into place for matrix
   !
   allocate(row_out(ne), stat=st)
   if(st.ne.0) goto 100
   if(present(map)) then
      ! Needs to be this big for worst case: all entries are repeat of same
      allocate(map(2*(ptr_in(m+1)-1)), stat=st)
      if(st.ne.0) goto 100
      maxv = n
      do row = 1, m
         if(abs(matrix_type).ge.HSL_MATRIX_REAL_SYM_PSDEF) maxv = row
         if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) maxv = row-1
         do i = ptr_in(row), ptr_in(row+1)-1
            j = col_in(i)
            if(j.lt.1 .or. j.gt.maxv) cycle ! ignore oor and upr triangle
            k = ptr_out(j+1)
            ptr_out(j+1) = k + 1
            row_out(k) = row
            map(k) = multiplier*i
         end do
      end do
   elseif(present(val_out)) then
      allocate(val_out(2*(ptr_in(m+1)-1)), stat=st)
      if(st.ne.0) goto 100
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SKEW)
         do row = 1, m
            do i = ptr_in(row), ptr_in(row+1)-1
               j = col_in(i)
               if(j.lt.1 .or. j.ge.row) cycle
               k = ptr_out(j+1)
               ptr_out(j+1) = k + 1
               row_out(k) = row
               val_out(k) = multiplier*val_in(i)
            end do
         end do
      case default
         maxv= n
         do row = 1, m
            if(abs(matrix_type).ge.HSL_MATRIX_REAL_SYM_PSDEF) maxv = row
            if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) maxv = row-1
            do i = ptr_in(row), ptr_in(row+1)-1
               j = col_in(i)
               if(j.lt.1 .or. j.gt.maxv) cycle
               k = ptr_out(j+1)
               ptr_out(j+1) = k + 1
               row_out(k) = row
               val_out(k) = val_in(i)
            end do
         end do
      end select
   else ! neither val_out nor map present
      maxv = n
      do row = 1, m
         if(abs(matrix_type).ge.HSL_MATRIX_REAL_SYM_PSDEF) maxv = row
         if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW) maxv = row-1
         do i = ptr_in(row), ptr_in(row+1)-1
            j = col_in(i)
            if(j.lt.1 .or. j.gt.maxv) cycle
            k = ptr_out(j+1)
            ptr_out(j+1) = k + 1
            row_out(k) = row
         end do
      end do
   endif

   !
   ! Third pass, removal of duplicates (no sort required by construction)
   !
   if(present(map)) then
      k = 1 ! insert position
      do col = 1, n
         i = ptr_out(col)
         ptr_out(col) = k
         if(ptr_out(col+1).eq.i) cycle ! no entries
         ! Move first entry of column forward
         row_out(k) = row_out(i)
         map(k) = map(i)
         k = k + 1
         ! Loop over remaining entries
         do i = i+1, ptr_out(col+1)-1
            if(row_out(i).eq.row_out(k-1)) then
               ! Duplicate
               allocate(dup,stat=st)
               if(st.ne.0) goto 100
               dup%next => duphead
               duphead => dup
               dup%src = map(i)
               dup%dest = k-1
               cycle
            endif
            ! Pull entry forwards
            row_out(k) = row_out(i)
            map(k) = map(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
      lmap = k-1
   elseif(present(val_out)) then
      k = 1 ! insert position
      do col = 1, n
         i = ptr_out(col)
         ptr_out(col) = k
         if(ptr_out(col+1).eq.i) cycle ! no entries
         ! Move first entry of column forward
         row_out(k) = row_out(i)
         val_out(k) = val_out(i)
         k = k + 1
         ! Loop over remaining entries
         do i = i+1, ptr_out(col+1)-1
            if(row_out(i).eq.row_out(k-1)) then
               ! Duplicate
               idup = idup + 1
               val_out(k-1) = val_out(k-1) + val_out(i)
               cycle
            endif
            ! Pull entry forwards
            row_out(k) = row_out(i)
            val_out(k) = val_out(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
   else ! neither val_out nor map are present
      k = 1 ! insert position
      do col = 1, n
         i = ptr_out(col)
         ptr_out(col) = k
         if(ptr_out(col+1).eq.i) cycle ! no entries
         ! Move first entry of column forward
         row_out(k) = row_out(i)
         k = k + 1
         ! Loop over remaining entries
         do i = i+1, ptr_out(col+1)-1
            if(row_out(i).eq.row_out(k-1)) then
               ! Duplicate
               idup = idup + 1
               cycle
            endif
            ! Pull entry forwards
            row_out(k) = row_out(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
   endif

   if(present(map)) then
      ! Append duplicates to map
      do while(associated(duphead))
         idup = idup + 1
         map(lmap+1) = duphead%dest
         map(lmap+2) = duphead%src
         lmap = lmap + 2
         dup => duphead%next
         deallocate(duphead)
         duphead => dup
      end do
      if(present(val_out)) then
         allocate(val_out(ptr_out(n+1)-1), stat=st)
         if(st.ne.0) goto 100
         call mc69_set_values(matrix_type, lmap, map, val_in, ptr_out(n+1)-1, &
            val_out)
      endif
   endif

   if(present(val_out)) then
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SYM_PSDEF)
         ! Check for positive diagonal entries
         do j = 1,n
            k = ptr_out(j)
            ! ps def case - can't reach here unless all entries have diagonal
            if(real(val_out(k))<=zero) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               return
            end if 
         end do
      end select
   endif

   ! Check whether a warning needs to be raised
   if(ioor > 0 .or. idup > 0 .or. idiag < n) then
     if(ioor > 0) flag = MC69_WARNING_IDX_OOR
     if(idup > 0) flag = MC69_WARNING_DUP_IDX
     if(idup > 0 .and. ioor > 0) flag = MC69_WARNING_DUP_AND_OOR
     if(abs(matrix_type) .ne. HSL_MATRIX_REAL_SKEW) then
         if(idiag < n .and. ioor > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n .and. idup > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n) then
            flag = MC69_WARNING_MISSING_DIAGONAL
         end if
      endif
      call mc69_print_flag(context,nout,flag)
   end if

   if(present(noor)) noor = ioor
   if(present(ndup)) ndup = idup

   return

100 if(st /= 0) then
      flag = MC69_ERROR_ALLOCATION
      call mc69_print_flag(context,nout,flag)
    end if

end subroutine mc69_csrl_convert_main

!****************************************

!
! Converts CSR with upper entries only for symmetric, skew-symmetric and
! Hermitian matrices to HSL standard format
!
subroutine mc69_csru_convert_double(matrix_type, n, ptr_in, col_in, ptr_out, &
      row_out, flag, val_in, val_out, lmap, map, lp, noor, ndup) 
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: n ! number of columns
   integer, dimension(*), intent(in) :: ptr_in ! column pointers on input
   integer, dimension(*), intent(in) :: col_in ! row indices on input.
      ! These may be unordered within each column and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed

   ! Local variables
   character(50)  :: context  ! Procedure name (used when printing).
   integer :: nout ! output unit (set to -1 if lp not present)

   context = 'mc69_csru_convert'

   nout = -1
   if(present(lp)) nout = lp

   ! Note: have to change this test for complex code
   if(matrix_type < 3 .or. matrix_type == 5 .or. matrix_type > 6) then
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,nout,flag)
      return
   end if

   call mc69_cscl_convert_main(context, -1, matrix_type, n, n, &
      ptr_in, col_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
end subroutine mc69_csru_convert_double

!****************************************

!
! Converts CSR with both lower and upper entries present to CSC with 
! only lower entries present and entries
! within each column ordered by increasing row index (HSL standard format)
!
subroutine mc69_csrlu_convert_double(matrix_type, n, ptr_in, col_in, ptr_out, &
      row_out, flag, val_in, val_out, lmap, map, lp, noor, ndup) 
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: n ! matrix dimension
   integer, dimension(*), intent(in) :: ptr_in ! row pointers on input
   integer, dimension(*), intent(in) :: col_in ! col indices on input.
      ! These may be unordered within each row and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(*), intent(out) :: ptr_out ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives src: map(i) = j means val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed

   ! Local variables
   character(50)  :: context  ! Procedure name (used when printing).
   integer :: nout ! output unit (set to -1 if nout not present)

   context = 'mc69_csrlu_convert'

   nout = -1
   if(present(lp)) nout = lp

   ! Note: have to change this test for complex code
   if(matrix_type < 3 .or. matrix_type == 5 .or. matrix_type > 6) then
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,nout,flag)
      return
   end if

   call mc69_csclu_convert_main(context, 1, matrix_type, n, &
      ptr_in, col_in, ptr_out, row_out, flag, val_in, val_out, lmap, map, &
      lp, noor, ndup) 
end subroutine mc69_csrlu_convert_double

!****************************************

!
! Converts COOR format to CSC with only lower entries present for
! (skew-)symmetric problems. Entries within each column ordered by increasing
! row index (HSL standard format)
!
subroutine mc69_coord_convert_double(matrix_type, m, n, ne, row, col, ptr_out, &
      row_out, flag, val_in, val_out, lmap, map, lp, noor, ndup) 
   integer, intent(in) :: matrix_type ! what sort of symmetry is there?
   integer, intent(in) :: m ! number of rows in matrix
   integer, intent(in) :: n ! number of columns in matrix
   integer, intent(in) :: ne ! number of input nonzero entries
   integer, dimension(:), intent(in) :: row(ne) ! row indices on input.
      ! These may be unordered within each column and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(:), intent(in) :: col(ne) ! column indices on input.
      ! These may be unordered within each column and may contain
      ! duplicates and/or out-of-range entries
   integer, dimension(:), intent(out) :: ptr_out(n+1) ! col ptr output
   integer, allocatable, dimension(:), intent(out) :: row_out ! row indices out
      ! Duplicates and out-of-range entries are dealt with and
      ! the entries within each column are ordered by increasing row index.
   integer, intent(out) :: flag ! return code
   real(wp), optional, dimension(*), intent(in) :: val_in ! values input
   real(wp), optional, allocatable, dimension(:) :: val_out
      ! values on output
   integer, optional, intent(out) :: lmap
   integer, optional, allocatable, dimension(:) :: map
      ! map(1:size(val_out)) gives source: map(i) = j means
      ! val_out(i)=val_in(j).
      ! map(size(val_out)+1:) gives pairs: map(i:i+1) = (j,k) means
      !     val_out(j) = val_out(j) + val_in(k)
   integer, optional, intent(in) :: lp ! unit for printing output if wanted
   integer, optional, intent(out) :: noor ! number of out-of-range entries
   integer, optional, intent(out) :: ndup ! number of duplicates summed


   ! Local variables
   character(50)  :: context  ! Procedure name (used when printing).
   integer :: i
   integer :: idiag
   integer :: idup
   integer :: ioor
   integer :: j
   integer :: k, l1, l2
   integer :: l
   integer :: ne_new
   integer :: nout ! output unit (set to -1 if lp not present)
   integer :: st ! stat parameter

   type(dup_list), pointer :: dup
   type(dup_list), pointer :: duphead

   nullify(dup, duphead)

   context = 'mc69_coord_convert'

   flag = MC69_SUCCESS

   nout = -1
   if(present(lp)) nout = lp

   ! ---------------------------------------------
   ! Check that restrictions are adhered to
   ! ---------------------------------------------

   ! Note: have to change this test for complex code
   if(matrix_type < 0 .or. matrix_type == 5 .or. matrix_type > 6) then
      flag = MC69_ERROR_MATRIX_TYPE
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(m < 0 .or. n < 0) then
      flag = MC69_ERROR_N_OOR
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(abs(matrix_type).ge.HSL_MATRIX_REAL_UNSYM .and. m.ne.n) then
      flag = MC69_ERROR_M_NE_N
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(val_in).neqv.present(val_out)) then
      flag = MC69_ERROR_VAL_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   if(present(map).neqv.present(lmap)) then
      flag = MC69_ERROR_LMAP_MISS
      call mc69_print_flag(context,nout,flag)
      return
   end if

   ! ---------------------------------------------

   ! allocate output and work arrays

   deallocate(row_out,stat=st)
   if(present(val_out)) deallocate(val_out,stat=st)
   if(present(map)) deallocate(map,stat=st)


   ! ---------------------------------------------
   ! check for duplicates and/or out-of-range. check diagonal present.
   ! first do the case where values not present

   idup = 0
   ioor = 0
   idiag = 0

   !
   ! First pass, count number of entries in each col of the matrix
   ! matrix. Count is at an offset of 1 to allow us to play tricks
   ! (ie. ptr_out(i+1) set to hold number of entries in column i
   ! of expanded matrix).
   ! Excludes out of range entries. Includes duplicates.
   !
   ptr_out(1:n+1) = 0
   do l = 1, ne
      i = row(l)
      j = col(l)
      if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m) then
         ioor = ioor + 1
         cycle
      endif

      if(abs(matrix_type).eq.HSL_MATRIX_REAL_SKEW .and. i.eq.j) then
         ioor = ioor + 1
         cycle
      endif
   
      select case (abs(matrix_type))
      case (HSL_MATRIX_REAL_SYM_PSDEF:)
         if(i.ge.j) then
            ptr_out(j+1) = ptr_out(j+1) + 1
         else
            ptr_out(i+1) = ptr_out(i+1) + 1
         end if
      case default
          ptr_out(j+1) = ptr_out(j+1) + 1
      end select
   end do


   ! Determine column starts for transposed expanded matrix such 
   ! that column i starts at ptr_out(i)
   ne_new = 0
   ptr_out(1) = 1
   do i = 2, n+1
      ne_new = ne_new + ptr_out(i)
      ptr_out(i) = ptr_out(i) + ptr_out(i-1)
   end do

   ! Check whether all entries out of range
   if(ne.gt.0 .and. ne_new.eq.0) then
      flag = MC69_ERROR_ALL_OOR
      call mc69_print_flag(context,nout,flag)
      return
   end if

   !
   ! Second pass, drop entries into place for conjugate of transposed
   ! expanded matrix
   !
   allocate(row_out(ne_new), stat=st)
   if(st.ne.0) goto 100
   if(present(map)) then
      if(allocated(map)) deallocate(map,stat=st)
      allocate(map(2*ne), stat=st)
      if(st.ne.0) goto 100
      map(:) = 0
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SKEW)
         do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m .or. i.eq.j) cycle
            if(i.ge.j) then
               k=ptr_out(j)
               ptr_out(j) = k+1
               row_out(k) = i
               map(k) = l
            else
               k=ptr_out(i)
               ptr_out(i) = k+1
               row_out(k) = j
               map(k) = -l
            end if
         end do

      case(HSL_MATRIX_REAL_SYM_PSDEF, HSL_MATRIX_REAL_SYM_INDEF)
         do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m) cycle
            if(i.ge.j) then
               k=ptr_out(j)
               ptr_out(j) = k+1
               row_out(k) = i
               map(k) = l
            else
               k=ptr_out(i)
               ptr_out(i) = k+1
               row_out(k) = j
               map(k) = l
            end if
         end do
      case default
         do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m) cycle
            k=ptr_out(j)
            ptr_out(j) = k+1
            row_out(k) = i
            map(k) = l
         end do
      end select
   elseif(present(val_out)) then
      allocate(val_out(ne_new), stat=st)
      if(st.ne.0) goto 100
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SKEW)
         do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m .or. i.eq.j) cycle
            if(i.ge.j) then
               k=ptr_out(j)
               ptr_out(j) = k+1
               row_out(k) = i
               val_out(k) = val_in(l)
            else
               k=ptr_out(i)
               ptr_out(i) = k+1
               row_out(k) = j
               val_out(k) = -val_in(l)
            end if
         end do

      case(HSL_MATRIX_REAL_SYM_PSDEF, HSL_MATRIX_REAL_SYM_INDEF)
         do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m) cycle
            if(i.ge.j) then
               k=ptr_out(j)
               ptr_out(j) = k+1
               row_out(k) = i
               val_out(k) = val_in(l)
            else
               k=ptr_out(i)
               ptr_out(i) = k+1
               row_out(k) = j
               val_out(k) = val_in(l)
            end if
         end do
      case default
         do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m) cycle
            k=ptr_out(j)
            ptr_out(j) = k+1
            row_out(k) = i
            val_out(k) = val_in(l)
         end do
      end select


   else
      ! neither val_out or map present
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SKEW)
         do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m .or. i.eq.j) cycle
            if(i.ge.j) then
               k=ptr_out(j)
               ptr_out(j) = k+1
               row_out(k) = i
            else
               k=ptr_out(i)
               ptr_out(i) = k+1
               row_out(k) = j
            end if
         end do

      case(HSL_MATRIX_REAL_SYM_PSDEF, HSL_MATRIX_REAL_SYM_INDEF)
          do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m) cycle
            if(i.ge.j) then
               k=ptr_out(j)
               ptr_out(j) = k+1
               row_out(k) = i
            else
               k=ptr_out(i)
               ptr_out(i) = k+1
               row_out(k) = j
            end if
         end do
      case default
         do l = 1, ne
            i = row(l)
            j = col(l)
            if(j.lt.1 .or. j.gt.n .or. i.lt.1 .or. i.gt.m) cycle
            k=ptr_out(j)
            ptr_out(j) = k+1
            row_out(k) = i
         end do
      end select
   endif

   do j=n,2,-1
      ptr_out(j) = ptr_out(j-1)
   end do
   ptr_out(1) = 1

   !
   ! Third pass, in place sort and removal of duplicates
   ! Also checks for diagonal entries in pos. def. case.
   ! Uses a modified insertion sort for best speed on already ordered data
   !
   idup=0
   if(present(map)) then
      do j = 1, n
         l1 = ptr_out(j)
         l2 = ptr_out(j+1)-1
         ! sort(row_out(l1:l2)) and permute map(l1:l2) accordingly
         l = l2-l1+1
         if(l.gt.1) call sort ( row_out(l1:l2),l, map=map(l1:l2) )
      end do

      ! work through removing duplicates
      k = 1 ! insert position      
      do j = 1, n
         l1 = ptr_out(j)
         l2 = ptr_out(j+1)-1
         ptr_out(j) = k
         ! sort(row_out(l1:l2)) and permute map(l1:l2) accordingly
         l = l2-l1+1
         if(l.eq.0) cycle ! no entries

         ! Move first entry of column forward
         if(row_out(l1).eq.j) idiag = idiag + 1
         row_out(k) = row_out(l1)
         map(k) = map(l1)
         k = k + 1
         ! Loop over remaining entries
         do i = l1+1, l2
            if(row_out(i).eq.row_out(k-1)) then
               ! Duplicate
               idup = idup + 1
               allocate(dup,stat=st)
               if(st.ne.0) goto 100
               dup%next => duphead
               duphead => dup
               dup%src = map(i)
               dup%dest = k-1
               cycle
            endif
            ! Pull entry forwards
            if(row_out(i).eq.j) idiag = idiag + 1
            row_out(k) = row_out(i)
            map(k) = map(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
      lmap = k-1
   else if(present(val_out)) then
      ! ADD
      do j = 1, n
         l1 = ptr_out(j)
         l2 = ptr_out(j+1)-1
         l = l2-l1+1
         if(l.gt.1) call sort( row_out(l1:l2),l,val=val_out(l1:l2) )
         ! ADD
      end do 

      ! work through removing duplicates
      k = 1 ! insert position      
      do j = 1, n
         l1 = ptr_out(j)
         l2 = ptr_out(j+1)-1
         ptr_out(j) = k
         ! sort(row_out(l1:l2)) and permute map(l1:l2) accordingly
         l = l2-l1+1
         if(l.eq.0) cycle ! no entries

         ! Move first entry of column forward
         if(row_out(l1).eq.j) idiag = idiag + 1
         row_out(k) = row_out(l1)
         val_out(k) = val_out(l1)
         k = k + 1
         ! Loop over remaining entries
         do i = l1+1, l2
            if(row_out(i).eq.row_out(k-1)) then
              idup = idup + 1
              val_out(k-1) = val_out(k-1)+val_out(i)
              cycle
            end if
            ! Pull entry forwards
            if(row_out(i).eq.j) idiag = idiag + 1
            row_out(k) = row_out(i)
            val_out(k) = val_out(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
   else
      do j = 1, n
         l1 = ptr_out(j)
         l2 = ptr_out(j+1)-1
         l = l2-l1+1
         if(l.gt.1)call sort ( row_out(l1:l2),l)
         ! ADD
      end do

      ! work through removing duplicates
      k = 1 ! insert position      
      do j = 1, n
         l1 = ptr_out(j)
         l2 = ptr_out(j+1)-1
         ptr_out(j) = k
         ! sort(row_out(l1:l2)) and permute map(l1:l2) accordingly
         l = l2-l1+1
         if(l.eq.0) cycle ! no entries

         ! Move first entry of column forward
         if(row_out(l1).eq.j) idiag = idiag + 1
         row_out(k) = row_out(l1)
         k = k + 1
         ! Loop over remaining entries
         do i = l1+1, l2
            if(row_out(i).eq.row_out(k-1)) then
              idup = idup + 1
              cycle
            end if
            ! Pull entry forwards
            if(row_out(i).eq.j) idiag = idiag + 1
            row_out(k) = row_out(i)
            k = k + 1
         end do
      end do
      ptr_out(n+1) = k
   
   endif


   ! Check for missing diagonals in pos def and indef cases
   ! Note: change this test for complex case
   if(abs(matrix_type) == HSL_MATRIX_REAL_SYM_PSDEF) then
      do j = 1,n
         if(ptr_out(j).lt.ptr_out(n+1)) then
            if(row_out(ptr_out(j)) .ne. j) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               return
            end if
         end if
      end do
   end if

   if(present(map)) then
      ! Append duplicates to map
      do while(associated(duphead))
         map(lmap+1) = duphead%dest
         map(lmap+2) = duphead%src
         lmap = lmap + 2
         dup => duphead%next
         deallocate(duphead)
         duphead => dup
      end do
      if(present(val_out)) then
         allocate(val_out(ptr_out(n+1)-1), stat=st)
         if(st.ne.0) goto 100
         call mc69_set_values(matrix_type, lmap, map, val_in, ptr_out(n+1)-1, &
            val_out)
      endif
   endif

   if(present(val_out)) then
      select case(matrix_type)
      case(HSL_MATRIX_REAL_SYM_PSDEF)
         ! Check for positive diagonal entries
         do j = 1,n
            k = ptr_out(j)
            ! ps def case - can't reach here unless all entries have diagonal
            if(real(val_out(k))<=zero) then
               flag = MC69_ERROR_MISSING_DIAGONAL
               call mc69_print_flag(context,nout,flag)
               return
            end if 
         end do
      end select
   endif

   ! Check whether a warning needs to be raised
   if(ioor > 0 .or. idup > 0 .or. idiag < n) then
     if(ioor > 0) flag = MC69_WARNING_IDX_OOR
     if(idup > 0) flag = MC69_WARNING_DUP_IDX
     if(idup > 0 .and. ioor > 0) flag = MC69_WARNING_DUP_AND_OOR
     if(abs(matrix_type) .ne. HSL_MATRIX_REAL_SKEW) then
         if(idiag < n .and. ioor > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n .and. idup > 0) then
            flag = MC69_WARNING_MISS_DIAG_OORDUP
         else if(idiag < n) then
            flag = MC69_WARNING_MISSING_DIAGONAL
         end if
      endif
      call mc69_print_flag(context,nout,flag)
   end if

   ! Check whether a warning needs to be raised
   if(ioor > 0 .or. idup > 0 .or. idiag < n) then
      if(ioor > 0) flag = MC69_WARNING_IDX_OOR
      if(idup > 0) flag = MC69_WARNING_DUP_IDX
      if(idup > 0 .and. ioor > 0) flag = MC69_WARNING_DUP_AND_OOR
      if(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_INDEF .and. &
            idiag<n .and. ioor>0) then
         flag = MC69_WARNING_MISS_DIAG_OORDUP
      else if(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_INDEF .and. idiag<n .and.&
            idup>0) then
         flag = MC69_WARNING_MISS_DIAG_OORDUP
      else if(abs(matrix_type).eq.HSL_MATRIX_REAL_SYM_INDEF .and. idiag<n) then
         flag = MC69_WARNING_MISSING_DIAGONAL
      end if
      call mc69_print_flag(context,nout,flag)
   end if

   if(present(noor)) noor = ioor
   if(present(ndup)) ndup = idup
   return

   100 continue
   if(st /= 0) then
      flag = MC69_ERROR_ALLOCATION
      call mc69_print_flag(context,nout,flag)
   end if
   return

end subroutine mc69_coord_convert_double

!*************************************************

!
! This subroutine will use map to translate the values of val to val_out
!
subroutine mc69_set_values_double(matrix_type, lmap, map, val, ne, val_out)
   integer, intent(in) :: matrix_type
   integer, intent(in) :: lmap
   integer, dimension(lmap), intent(in) :: map
   real(wp), dimension(*), intent(in) :: val
   integer, intent(in) :: ne
   real(wp), dimension(ne), intent(out) :: val_out

   integer :: i, j, k

   select case(matrix_type)
   case default
      !
      ! Rectangular, Unsymmetric or Symmetric Matrix
      !

      ! First set val_out using first part of map
      do i = 1, ne
         j = abs(map(i))
         val_out(i) = val(j)
      end do

      ! Second examine list of duplicates
      do i = ne+1, lmap, 2
         j = abs(map(i))
         k = abs(map(i+1))
         val_out(j) = val_out(j) + val(k)
      end do
   case(HSL_MATRIX_REAL_SKEW)
      !
      ! Skew symmetric Matrix
      !

      ! First set val_out using first part of map
      do i = 1, ne
         j = abs(map(i))
         val_out(i) = sign(1.0,real(map(i)))*val(j)
      end do

      ! Second examine list of duplicates
      do i = ne+1, lmap, 2
         j = abs(map(i))
         k = abs(map(i+1))
         val_out(j) = val_out(j) + sign(1.0,real(map(i+1)))*val(k)
      end do
   end select
end subroutine mc69_set_values_double

!*************************************************

subroutine mc69_print_flag(context,nout,flag)
   integer, intent (in) :: flag, nout
   character (len=*), optional, intent(in) :: context

   if(nout < 0) return
   if(flag < 0) then
      write (nout,'(/3a,i3)') ' Error return from ',trim(context), &
         '. Error flag = ', flag
   else
      write (nout,'(/3a,i3)') ' Warning from ',trim(context), &
         '. Warning flag = ', flag
   end if

   select case(flag)
   !
   ! Errors
   !
   case(MC69_ERROR_ALLOCATION)
      write (nout,'(a)') ' Allocation error'
   case(MC69_ERROR_MATRIX_TYPE)
       write (nout,'(a)') ' matrix_type has invalid value'
   case(MC69_ERROR_N_OOR)
      write (nout,'(a)') ' m or n is out-of-range'
   case(MC69_ERROR_ALL_OOR)
      write (nout,'(a)') ' All entries in a column out-of-range'
   case(MC69_ERROR_PTR_MONO)
      write (nout,'(a)') ' ptr not monotonic'
   case(MC69_ERROR_PTR_1)
      write (nout,'(a)') ' ptr(1) < 1'
   case(MC69_ERROR_IMAG_DIAGONAL)
      write (nout,'(a)') ' one or more diagonal entries is not real'
   case(MC69_ERROR_MISSING_DIAGONAL)
      write (nout,'(a)') ' one or more diagonal entries are not positive'
   case(MC69_ERROR_VAL_MISS)
      write (nout,'(a)') ' Only one of val and val_out is present'
   case(MC69_ERROR_LMAP_MISS)
      write (nout,'(a)') ' Only one of lmap and map is present'
   case(MC69_ERROR_UPR_ENTRY)
      write (nout,'(a)') ' Entry in upper triangle'
   case(MC69_ERROR_M_NE_N)
      write (nout,'(a)') ' m is not equal to n'
   !
   ! Warnings
   !
   case(MC69_WARNING_IDX_OOR)
      write (nout,'(a)') ' out-of-range indices detected'
   case(MC69_WARNING_DUP_IDX)
      write (nout,'(a)') ' duplicate entries detected'
   case(MC69_WARNING_DUP_AND_OOR)
      write (nout,'(a)') &
         ' out-of-range indices detected and duplicate entries detected'
   case(MC69_WARNING_MISSING_DIAGONAL)
      write (nout,'(a)') ' one or more diagonal entries is missing'
   case(MC69_WARNING_MISS_DIAG_OORDUP)
      write (nout,'(a)') ' one or more diagonal entries is missing and'
      write (nout,'(a)') ' out-of-range and/or duplicate entries detected'
   end select

end subroutine mc69_print_flag

!************************************************************************

!
!   Sort an integer array by heapsort into ascending order.
!
subroutine sort( array, n, map, val )
   integer, intent(in) :: n       ! Size of array to be sorted
   integer, dimension(n), intent(inout) :: array ! Array to be sorted
   integer, dimension(n), optional, intent(inout) :: map
   real(wp), dimension(n), optional, intent(inout) :: val ! Apply same
      ! permutation to val

   integer :: i
   integer :: temp
   real(wp) :: vtemp
   integer :: root

   if(n.le.1) return ! nothing to do

   !
   ! Turn array into a heap with largest element on top (as this will be pushed
   ! on the end of the array in the next phase)
   !
   ! We start at the bottom of the heap (i.e. 3 above) and work our way
   ! upwards ensuring the new "root" of each subtree is in the correct
   ! location
   root = n / 2
   do root = root, 1, -1
      call pushdown(root, n, array, val=val, map=map)
   end do

   !
   ! Repeatedly take the largest value and swap it to the back of the array
   ! then repeat above code to sort the array
   !
   do i = n, 2, -1
      ! swap a(i) and head of heap a(1)
      temp = array(1)
      array(1) = array(i)
      array(i) = temp
      if(present(val)) then
         vtemp = val(1)
         val(1) = val(i)
         val(i) = vtemp
      endif
      if(present(map)) then
         temp = map(1)
         map(1) = map(i)
         map(i) = temp
      endif
      call pushdown(1,i-1, array, val=val, map=map)
   end do
end subroutine sort

!****************************************

! This subroutine will assume everything below head is a heap and will
! push head downwards into the correct location for it
subroutine pushdown(root, last, array, val, map)
   integer, intent(in) :: root
   integer, intent(in) :: last
   integer, dimension(last), intent(inout) :: array
   real(wp), dimension(last), optional, intent(inout) :: val
   integer, dimension(last), optional, intent(inout) :: map

   integer :: insert ! current insert position
   integer :: test ! current position to test
   integer :: root_idx ! value of array(root) at start of iteration
   real(wp) :: root_val ! value of val(root) at start of iteration
   integer :: root_map ! value of map(root) at start of iteration

   ! NB a heap is a (partial) binary tree with the property that given a
   ! parent and a child, array(child)>=array(parent).
   ! If we label as
   !                      1
   !                    /   \
   !                   2     3
   !                  / \   / \
   !                 4   5 6   7
   ! Then node i has nodes 2*i and 2*i+1 as its children

   if(present(val) .and. present(map)) then ! both val and map
      root_idx = array(root)
      root_val = val(root)
      root_map = map(root)
      insert = root
      test = 2*insert
      do while(test.le.last)
         ! First check for largest child branch to descend
         if(test.ne.last) then
            if(array(test+1).gt.array(test)) test = test + 1
         endif
         if(array(test).le.root_idx) exit ! root gets tested here
         ! Otherwise, move on to next level down, percolating value up
         array(insert) = array(test);
         val(insert) = val(test);
         map(insert) = map(test)
         insert = test
         test = 2*insert
      end do
      ! Finally drop root value into location found
      array(insert) = root_idx
      val(insert) = root_val
      map(insert) = root_map
   elseif(present(val)) then ! val only, not map
      root_idx = array(root)
      root_val = val(root)
      insert = root
      test = 2*insert
      do while(test.le.last)
         ! First check for largest child branch to descend
         if(test.ne.last) then
            if(array(test+1).gt.array(test)) test = test + 1
         endif
         if(array(test).le.root_idx) exit ! root gets tested here
         ! Otherwise, move on to next level down, percolating value up
         array(insert) = array(test)
         val(insert) = val(test)
         insert = test
         test = 2*insert
      end do
      ! Finally drop root value into location found
      array(insert) = root_idx
      val(insert) = root_val
   elseif(present(map)) then ! map only, not val
      root_idx = array(root)
      root_map = map(root)
      insert = root
      test = 2*insert
      do while(test.le.last)
         ! First check for largest child branch to descend
         if(test.ne.last) then
            if(array(test+1).gt.array(test)) test = test + 1
         endif
         if(array(test).le.root_idx) exit ! root gets tested here
         ! Otherwise, move on to next level down, percolating mapue up
         array(insert) = array(test)
         map(insert) = map(test)
         insert = test
         test = 2*insert
      end do
      ! Finally drop root mapue into location found
      array(insert) = root_idx
      map(insert) = root_map
   else ! neither map nor val
      root_idx = array(root)
      insert = root
      test = 2*insert
      do while(test.le.last)
         ! First check for largest child branch to descend
         if(test.ne.last) then
            if(array(test+1).gt.array(test)) test = test + 1
         endif
         if(array(test).le.root_idx) exit ! root gets tested here
         ! Otherwise, move on to next level down, percolating value up
         array(insert) = array(test)
         insert = test
         test = 2*insert
      end do
      ! Finally drop root value into location found
      array(insert) = root_idx
   endif

end subroutine pushdown

!****************************************

subroutine cleanup_dup(duphead)
   type(dup_list), pointer :: duphead ! NB: can't have both intent() and pointer

   type(dup_list), pointer :: dup

   do while(associated(duphead))
      dup => duphead%next
      deallocate(duphead)
      duphead => dup
   end do
end subroutine cleanup_dup

end module hsl_mc69_double
! COPYRIGHT (c) 2001 Council for the Central Laboratory
!               of the Research Councils
! Original date 18 October 2001
!
! Version 3.3.0
! For history see ChangeLog
!

!
! This file consists of four modules:
! hsl_ma48_ma50_internal_double (based on ma50)
! hsl_ma48_ma48_internal_double (based on ma48)
! hsl_ma48_ma51_internal_double (based on ma51)
! hsl_ma48_double (the user facing module)
!

module hsl_ma48_ma50_internal_double
   use hsl_zb01_double, zb01_real_info => zb01_info
   use hsl_zb01_integer, ZB01_integer => ZB01_resize1, &
       zb01_integer_info => zb01_info
   implicit none

! This module is based on ma50 2.0.0 (29 November 2006)
!
! 3 August 2010 Version 3.0.0.  Radical change to include some
!      INTEGER*64 integers (so that restriction on number of entries is
!      relaxed.  Also use of HSL_ZB01 to allow restarting with more
!      space allocated.

   private
   ! public for user
   public :: ma50ad, ma50bd, ma50cd
   ! public for unit tests
   public :: ma50dd, ma50ed, ma50fd, ma50gd, ma50hd, ma50id

   integer, parameter :: wp = kind(0.0d0)
   integer, parameter :: long = selected_int_kind(18) ! Long integer
   integer(long), parameter :: onel = 1
   integer :: stat

contains

SUBROUTINE ma50ad(m,n,ne,la,a,irn,ljcn,jcn,iq,cntl,icntl,ip,np, &
    jfirst,lenr,lastr, &
    nextr,ifirst,lenc,lastc,nextc,multiplier,info,rinfo)

! MA50A/AD chooses a pivot sequence using a Markowitz criterion with
!     threshold pivoting.

! If  the user requires a more convenient data interface then the MA48
!     package should be used. The MA48 subroutines call the MA50
!     subroutines after checking the user's input data and optionally
!     permute the matrix to block triangular form.

  integer m, n
  integer(long) :: ne, la, ljcn, oldlen
  real(wp), allocatable :: a(:)
  real(wp) :: cntl(10)
  real(wp), intent(in) :: multiplier
  integer, allocatable :: irn(:), jcn(:)
  integer, allocatable :: iw(:)
  integer icntl(20), np, jfirst(m), lenr(m), lastr(m), nextr(m), &
    ifirst(n), lenc(n), lastc(n), nextc(n)
  integer(long) :: info(15)
  integer(long) :: iq(n), ip(m)
  real(wp) :: rinfo(10)

! M is an integer variable that must be set to the number of rows.
!      It is not altered by the subroutine.
! N is an integer variable that must be set to the number of columns.
!      It is not altered by the subroutine.
! NE is an integer variable that must be set to the number of entries
!      in the input matrix. It is not altered by the subroutine.
! LA is an integer variable that must be set to the size of A, IRN, and
!      JCN. It is not altered by the subroutine.
! A is an array that holds the input matrix on entry and is used as
!      workspace.
! IRN  is an integer array.  Entries 1 to NE must be set to the
!      row indices of the corresponding entries in A.  IRN is used
!      as workspace and holds the row indices of the reduced matrix.
! JCN  is an integer array that need not be set by the user. It is
!      used to hold the column indices of entries in the reduced
!      matrix.
! IQ is an integer array of length N. On entry, it holds pointers
!      to column starts. During execution, IQ(j) holds the position of
!      the start of column j of the reduced matrix or -IQ(j) holds the
!      column index in the permuted matrix of column j. On exit, IQ(j)
!      holds the index of the column that is in position j of the
!      permuted matrix.
! CNTL must be set by the user as follows and is not altered.
!     CNTL(1)  Full matrix processing will be used if the density of
!       the reduced matrix is MIN(CNTL(1),1.0) or more.
!     CNTL(2) determines the balance between pivoting for sparsity and
!       for stability, values near zero emphasizing sparsity and values
!       near one emphasizing stability. Each pivot must have absolute
!       value at least CNTL(2) times the greatest absolute value in the
!       same column of the reduced matrix.
!     CNTL(3) If this is set to a positive value, any entry of the
!       reduced matrix whose modulus is less than CNTL(3) will be
!       dropped.
!     CNTL(4)  Any entry of the reduced matrix whose modulus is less
!       than or equal to CNTL(4) will be regarded as zero from the
!        point of view of rank.
! ICNTL must be set by the user as follows and is not altered.
!     ICNTL(1)  must be set to the stream number for error messages.
!       A value less than 1 suppresses output.
!     ICNTL(2) must be set to the stream number for diagnostic output.
!       A value less than 1 suppresses output.
!     ICNTL(3) must be set to control the amount of output:
!       0 None.
!       1 Error messages only.
!       2 Error and warning messages.
!       3 As 2, plus scalar parameters and a few entries of array
!         parameters on entry and exit.
!       4 As 3, plus all parameters on entry and exit.
!     ICNTL(4) If set to a positive value, the pivot search is limited
!       to ICNTL(4) columns (Zlatev strategy). This may result in
!       different fill-in and execution time. If ICNTL(4) is positive,
!       the workspace arrays LASTR and NEXTR are not referenced.
!     ICNTL(5) The block size to be used for full-matrix processing.
!     ICNTL(6) The last ICNTL(6) columns of A must be the last
!       ICNTL(6) columns of the permuted matrix. A value outside the
!       range 1 to N-1 is treated as zero.
!     ICNTL(7) If given the value 1, pivots are limited to
!       the main diagonal, which may lead to a premature switch to full
!       processing if no suitable diagonal entries are available.
!       If given the value 2, IFIRST must be set so that IFIRST(i) is
!       the column in position i of the permuted matrix and IP must
!       be set so that IP(i) < IP(j) if row i is recommended to
!       precede row j in the pivot sequence.
! IP is an integer array of length M that need not be set on entry
!      unless ICNTL(7)=2 (see ICNTL(7) for details of this case).
!      During execution, IP(i) holds the position of the start of row i
!      of the reduced matrix or -IP(i) holds the row index in the
!      permuted matrix of row i. Before exit, IP(i) is made positive.
! NP is an integer variable. It need not be set on entry. On exit,
!     it will be set to the number of columns to be processed in
!     packed storage.
! JFIRST is an integer workarray of length M. JFIRST(i) is the
!      first column of the reduced matrix to have i entries or is
!      zero if no column has i entries.
! LENR is an integer workarray of length M that is used to hold the
!      numbers of entries in the rows of the reduced matrix.
! LASTR is an integer workarray of length M, used only if ICNTL(4) = 0.
!      For rows in the reduced matrix, LASTR(i) indicates the previous
!      row to i with the same number of entries. LASTR(i) is zero if
!      no such row exists.
! NEXTR is an integer workarray of length M, used only if ICNTL(4) = 0
!      or ICNTL(7)=2. If ICNTL(4)=0, for rows in the reduced matrix,
!      NEXTR(i) indicates the next row to i with the same number of
!      entries; and if row i is the last in the chain, NEXTR is
!      equal to zero. If ICNTL(7)=2, NEXTR is a copy of the value of
!      IP on entry.
! IW is an integer array of length M used as workspace and is used to
!     assist the detection of duplicate entries and the sparse SAXPY
!     operations. It is reset to zero each time round the main loop.
! IFIRST is an integer array of length N, used only if ICNTL(4) = 0
!      or ICNTL(7)=2. If ICNTL(4) = 0, it is a workarray; IFIRST(i)
!      points to the first row of the reduced matrix to have i entries
!      or is zero if no row has i entries. If ICNTL(7)=2, IFIRST
!      must be set on entry (see ICNTL(7) for details of this case).
! LENC is an integer workarray of length N that is used to hold
!      the numbers of entries in the columns of the reduced matrix.
! LASTC is an integer workarray of length N.  For columns in the reduced
!      matrix, LASTC(j) indicates the previous column to j with the same
!      number of entries.  If column j is the first in the chain,
!      LASTC(j) is equal to zero.
! NEXTC is an integer workarray of length N.  For columns in the reduced
!      matrix, NEXTC(j) indicates the next column to j with the same
!      number of entries.  If column j is the last column in the chain,
!      NEXTC(j) is zero.
! INFO need not be set on entry. On exit, it holds the following:
!    INFO(1):
!       0  Successful entry.
!      -1  M < 1 or N < 1.
!      -2  NE < 1.
!      -4  Duplicated entries.
!      -5  Faulty column permutation in IFIRST when ICNTL(7)=2.
!      -6  ICNTL(4) not equal to 1 when ICNTL(7)=2.
!      +1  Rank deficient.
!      +2  Premature switch to full processing because of failure to
!          find a stable diagonal pivot (ICNTL(7)>=1 case only).
!      +3  Both of these warnings.
!    INFO(2) Number of compresses of the arrays.
!    INFO(3) Minimum LA recommended to analyse matrix.
!    INFO(4) Minimum LFACT required to factorize matrix.
!    INFO(5) Upper bound on the rank of the matrix.
!    INFO(6) Number of entries dropped from the data structure.
!    INFO(7) Number of rows processed in full storage.
! RINFO need not be set on entry. On exit, RINFO(1) holds the number of
!    floating-point operations needed for the factorization.

  integer idamax
  external idamax
  intrinsic abs, max, min

  real(wp) :: zero, one
  parameter (zero=0d0,one=1.0d0)

  type (zb01_real_info) :: zb01info
  type (zb01_integer_info) :: zb01intinfo
  real(wp) :: alen, amult, anew, asw, au, cost, cpiv
  integer len
  integer(long) :: eye, i, idummy, iend, ifill, ifir, ii, ij, &
    ijpos, iop, ipiv, ipos, isrch, i1, i2, j, jbeg, jend, jj, jlast, jmore, &
    jnew, jpiv, jpos, j1, j2, l, lc, lenpiv, lp, lr, ist
  integer(long) :: dispc, dispr, idrop
  real(wp) :: maxent
  integer(long) :: minc, mord, mp, msrch, nc, ndrop, nefact, nepr, nered, ne1, &
    nord, nord1, nr, nullc, nulli, nullj, nullr, pivbeg, pivcol, pivend, pivot
  real(wp) :: pivr, pivrat, u

! ALEN Real(LEN-1).
! AMULT Temporary variable used to store current multiplier.
! ANEW Temporary variable used to store value of fill-in.
! ASW Temporary variable used when swopping two real quantities.
! AU Temporary variable used in threshold test.
! COST Markowitz cost of current potential pivot.
! CPIV Markowitz cost of best pivot so far found.
! DISPC is the first free location in the column file.
! DISPR is the first free location in the row file.
! EYE Running relative position when processing pivot row.
! I Temporary variable holding row number. Also used as index in DO
!     loops used in initialization of arrays.
! IDROP Temporary variable used to accumulate number of entries dropped.
! IDUMMY DO index not referenced in the loop.
! IEND Position of end of pivot row.
! IFILL is the fill-in to the non-pivot column.
! IFIR Temporary variable holding first entry in chain.
! II Running position for current column.
! IJ Temporary variable holding row/column index.
! IJPOS Position of current pivot in A/IRN.
! IOP holds a running count of the number of rows with entries in both
!     the pivot and the non-pivot column.
! IPIV Row of the pivot.
! IPOS Temporary variable holding position in column file.
! ISRCH Temporary variable holding number of columns searched for pivot.
! I1 Position of the start of the current column.
! I2 Position of the end of the current column.
! J Temporary variable holding column number.
! JBEG Position of beginning of non-pivot column.
! JEND Position of end of non-pivot column.
! JJ Running position for current row.
! JLAST Last column acceptable as pivot.
! JMORE Temporary variable holding number of locations still needed
!     for fill-in in non-pivot column.
! JNEW Position of end of changed non-pivot column.
! JPIV Column of the pivot.
! JPOS Temporary variable holding position in row file.
! J1 Position of the start of the current row.
! J2 Position of the end of the current row.
! L Loop index.
! LC Temporary variable holding previous column in sequence.
! LEN Length of column or row.
! LENPIV Length of pivot column.
! LP Unit for error messages.
! LR Temporary variable holding previous row in sequence.
! MAXENT Temporary variable used to hold value of largest entry in
!    column.
! MINC Minimum number of entries of any row or column of the reduced
!     matrix, or in any column if ICNTL(4) > 0.
! MORD Number of rows ordered, excluding null rows.
! MP Unit for diagnostic messages.
! MSRCH Number of columns to be searched.
! NC Temporary variable holding next column in sequence.
! NDROP Number of entries dropped because of being in a column all of
!   whose entries are smaller than the pivot threshold.
! NEFACT Number of entries in factors.
! NEPR Number of entries in pivot row, excluding the pivot.
! NERED Number of entries in reduced matrix.
! NE1 Temporary variable used to hold number of entries in row/column
!     and to hold temporarily value of MINC.
! NORD Number of columns ordered, excluding null columns beyond JLAST.
! NORD1 Value of NORD at start of step.
! NR Temporary variable holding next row in sequence.
! NULLC Number of structurally zero columns found before any entries
!     dropped for being smaller than CNTL(3).
! NULLR Number of structurally zero rows found before any entries
!     dropped for being smaller than CNTL(3).
! NULLI Number of zero rows found.
! NULLJ Number of zero columns found beyond column JLAST.
! PIVBEG Position of beginning of pivot column.
! PIVCOL Temporary variable holding position in pivot column.
! PIVEND Position of end of pivot column.
! PIVOT Current step in Gaussian elimination.
! PIVR ratio of current pivot candidate to largest in its column.
! PIVRAT ratio of best pivot candidate to largest in its column.
! U Used to hold local copy of CNTL(2), changed if necessary so that it
!    is in range.

  lp = icntl(1)
  if (icntl(3)<=0) lp = 0
  mp = icntl(2)
  if (icntl(3)<=1) mp = 0
  info(1) = 0
  info(2) = 0
  info(3) = ne
  info(8) = ne
  info(4) = ne
  info(9) = ne
  info(5) = 0
  info(6) = 0
  info(7) = 0
  rinfo(1) = zero
  np = 0

! Make some simple checks
!!!
! Won't of course happen in the hsl_ma48 context
! if (m<1 .or. n<1) go to 690
  if (ne<1) go to 700
  if (la<ne) go to 710
!!    oldlen = la
!!    la = multiplier*la
!!write(6,*) 'oldlen,la',oldlen,la
!!    call ZB01_resize1(a,oldlen,la,zb01info)
!!write(6,*) 'oldlen,la',oldlen,la
!!      if (zb01info%flag .lt. 0) then
!!        info(1) = -2*n
!!        return
!!      endif
!!write(6,*) 'oldlen,la',oldlen,la
!!      call ZB01_integer(irn,oldlen,la,zb01intinfo)
!!write(6,*) 'oldlen,la',oldlen,la
!!      if (zb01intinfo%flag .lt. 0) then
!!        info(1) = -2*n
!!        return
!!      endif
!!  end if

  allocate(iw(m),stat=stat)
  if (stat .ne. 0) then
    info(1) = -2*n
    return
  endif

! Initial printing
  if (mp>0 .and. icntl(3)>2) then
    write (mp,'(/2(A,I6),A,I8,A,I8/A,1P,4E10.2/A,7I4)') &
      ' Entering MA50AD with M =', m, ' N =', n, ' NE =', ne, ' LA =', la, &
      ' CNTL =', (cntl(i),i=1,4), ' ICNTL =', (icntl(i),i=1,7)
    if (n==1 .or. icntl(3)>3) then
      do 10 j = 1, n - 1
        if (iq(j)<iq(j+1)) write (mp,'(A,I5,(T13,3(1P,E12.4,I5)))') ' Column', &
          j, (a(ii),irn(ii),ii=iq(j),iq(j+1)-1)
10    continue
      if (iq(n)<=ne) write (mp,'(A,I5,(T13,3(1P,E12.4,I5)))') ' Column', n, &
        (a(ii),irn(ii),ii=iq(n),ne)
    else
      if (iq(1)<iq(2)) write (mp,'(A,I5,(T13,3(1P,E12.4,I5)))') ' Column', 1, &
        (a(ii),irn(ii),ii=iq(1),iq(2)-1)
    end if
    if (icntl(7)==2) then
      write (mp,'(A,(T10,10(I7)))') ' IP = ', ip
      write (mp,'(A,(T10,10(I7)))') ' IFIRST = ', ifirst
    end if
  end if

! Initialization of counts etc.
  minc = 1
  nered = ne
  u = min(cntl(2),one)
  u = max(u,zero)
  msrch = icntl(4)
  if (msrch==0) msrch = n
  jlast = n - icntl(6)
  if (jlast<1 .or. jlast>n) jlast = n
  nulli = 0
  nullj = 0
  mord = 0
  nord = 0
  ndrop = 0
  nefact = 0
  do 20 i = 1, n - 1
    lenc(i) = iq(i+1) - iq(i)
20 continue
  lenc(n) = ne + 1 - iq(n)

  if (cntl(3)>zero) then
! Drop small entries
    nered = 0
    do 40 j = 1, n
      i = iq(j)
      iq(j) = nered + 1
      do 30 ii = i, i + lenc(j) - 1
        if (abs(a(ii))>=cntl(3)) then
          nered = nered + 1
          a(nered) = a(ii)
          irn(nered) = irn(ii)
        else
          info(6) = info(6) + 1
        end if
30    continue
      lenc(j) = nered + 1 - iq(j)
40  continue
  end if

  if (icntl(7)==2) then
! Column order specified - copy the row ordering array
    do 50 i = 1, m
      nextr(i) = ip(i)
50  continue
! Check ICNTL(4)
    if (icntl(4)/=1) go to 740
  end if

  dispr = nered + 1
  dispc = nered + 1

! Set up row oriented storage.
  do 60 i = 1, m
    iw(i) = 0
    lenr(i) = 0
    jfirst(i) = 0
60 continue
! Calculate row counts.
  do 70 ii = 1, nered
    i = irn(ii)
    lenr(i) = lenr(i) + 1
70 continue
! Set up row pointers so that IP(i) points to position after end
!     of row i in row file.
  ip(1) = lenr(1) + 1
  do 80 i = 2, m
    ip(i) = ip(i-1) + lenr(i)
80 continue
! Generate row file.
  do 100 j = 1, n
    ist = iq(j)
    do 90 ii = ist, ist + lenc(j) - 1
      i = irn(ii)
! Check for duplicate entry.
!!! Cannot happen when called from HSL_MA48
!     if (iw(i)==j) go to 720
      iw(i) = j
      ipos = ip(i) - 1
      jcn(ipos) = j
      ip(i) = ipos
90  continue
100 continue
  do 110 i = 1, m
    iw(i) = 0
110 continue

! Check for zero rows and (unless ICNTL(4) > 0), compute chains of rows
!    with equal numbers of entries.
  if (icntl(4)<=0) then
    do 120 i = 1, n
      ifirst(i) = 0
120 continue
    do 130 i = m, 1, -1
      ne1 = lenr(i)
      if (ne1>0) then
        ifir = ifirst(ne1)
        ifirst(ne1) = i
        lastr(i) = 0
        nextr(i) = ifir
        if (ifir>0) lastr(ifir) = i
      else
        ip(i) = -m + nulli
        nulli = nulli + 1
      end if
130 continue
  else
    do 140 i = m, 1, -1
      ne1 = lenr(i)
      if (ne1==0) then
        ip(i) = -m + nulli
        nulli = nulli + 1
      end if
140 continue
  end if
! Check for zero columns and compute chains of columns with equal
!   numbers of entries.
  do 150 j = n, 1, -1
    ne1 = lenc(j)
    if (ne1==0) then
      if (icntl(7)/=2) then
        if (j<=jlast) then
          nord = nord + 1
          iq(j) = -nord
          if (nord==jlast) then
! We have ordered the first N - ICNTL(6) columns.
            nord = nord + nullj
            jlast = n
            nullj = 0
          end if
        else
          nullj = nullj + 1
          iq(j) = -(jlast+nullj)
        end if
        lastc(j) = 0
        nextc(j) = 0
      end if
    else
      ifir = jfirst(ne1)
      jfirst(ne1) = j
      nextc(j) = ifir
      lastc(j) = 0
      if (ifir>0) lastc(ifir) = j
    end if
150 continue
  if (info(6)==0) then
    nullc = nord + nullj
    nullr = nulli
  end if


! **********************************************
! ****    Start of main elimination loop    ****
! **********************************************
  do 630 pivot = 1, n
! Check to see if reduced matrix should be considered as full.
    if (nered>=(min(cntl(1),one)*(n-nord))*(m-mord)) go to 640

    if (icntl(7)==2) then
! Column order specified - choose the pivot within the column
      ipiv = 0
      j = ifirst(pivot)
      if (j<1 .or. j>n) go to 730
      if (iq(j)<0) go to 730
      len = lenc(j)
      if (len<=0) go to 320
      alen = len - 1
      i1 = iq(j)
      i2 = i1 + len - 1
! Find largest entry in column
      ii = idamax(len,a(i1),1)
      maxent = abs(a(i1+ii-1))
! Is every entry in the column below the pivot threshold?
      if (maxent<=cntl(4)) go to 320
      au = max(maxent*u,cntl(4))
! Scan column for pivot
      do 160 ii = i1, i2
        if (abs(a(ii))<au) go to 160
! Candidate satisfies threshold criterion.
        i = irn(ii)
        if (ipiv/=0) then
          if (nextr(i)>=nextr(ipiv)) go to 160
        end if
        cpiv = alen*(lenr(i)-1)
        ijpos = ii
        ipiv = i
        jpiv = j
160   continue
      go to 330
    end if

! Find the least number of entries in a row or column (column only if
!   the Zlatev strategy is in use)
    len = minc
    do 170 minc = len, m - mord
      if (jfirst(minc)/=0) go to 180
      if (icntl(4)<=0) then
        if (ifirst(minc)/=0) go to 180
      end if
170 continue

! Find the next pivot or a column whose entries are all very small.
! CPIV is the Markowitz cost of the best pivot so far and PIVRAT is the
!      ratio of its absolute value to that of the largest entry in its
!      column.
180 cpiv = m
    cpiv = cpiv*n
    pivrat = zero
! Examine columns/rows in order of ascending count.
    isrch = 0
    do 300 len = minc, m - mord
      alen = len - 1
! Jump if Markowitz count cannot be bettered.
      if (cpiv<=alen**2 .and. icntl(4)<=0) go to 310
      ij = jfirst(len)
! Scan columns with LEN entries.
      do 220 idummy = 1, n
! If no more columns with LEN entries, exit loop.
        if (ij<=0) go to 230
        j = ij
        ij = nextc(j)
        if (j>jlast) go to 220
! Column J is now examined.
! First calculate multiplier threshold level.
        maxent = zero
        i1 = iq(j)
        i2 = i1 + len - 1
        ii = idamax(len,a(i1),1)
        maxent = abs(a(i1+ii-1))
! Exit loop if every entry in the column is below the pivot threshold.
        if (maxent<=cntl(4)) go to 320
        au = max(maxent*u,cntl(4))
! If diagonal pivoting requested, look for diagonal entry.
        if (icntl(7)==1) then
          do 190 ii = i1, i2
            if (irn(ii)==j) go to 200
190       continue
          go to 220
200       i1 = ii
          i2 = ii
        end if
! Scan column for possible pivots
        do 210 ii = i1, i2
          if (abs(a(ii))<au) go to 210
! Candidate satisfies threshold criterion.
          i = irn(ii)
          cost = alen*(lenr(i)-1)
          if (cost>cpiv) go to 210
          pivr = abs(a(ii))/maxent
          if (cost==cpiv) then
            if (pivr<=pivrat) go to 210
          end if
! Best pivot so far is found.
          cpiv = cost
          ijpos = ii
          ipiv = i
          jpiv = j
          if (cpiv<=alen**2 .and. icntl(4)<=0) go to 330
          pivrat = pivr
210     continue
! Increment number of columns searched.
        isrch = isrch + 1
! Jump if we have searched the number of columns stipulated and found a
!   pivot.
        if (isrch>=msrch) then
          if (pivrat>zero) go to 330
        end if
220   continue

! Rows with LEN entries now examined.
230   if (icntl(4)>0) go to 300
      if (cpiv<=alen*(alen+1)) go to 310
      if (len>n-nord) go to 300
      ij = ifirst(len)
      do 290 idummy = 1, m
        if (ij==0) go to 300
        i = ij
        ij = nextr(ij)
        j1 = ip(i)
        j2 = j1 + len - 1
! If diagonal pivoting requested, look for diagonal entry.
        if (icntl(7)==1) then
          do 240 jj = j1, j2
            if (jcn(jj)==i) go to 250
240       continue
          go to 290
250       j1 = jj
          j2 = jj
        end if
! Scan row I.
        do 280 jj = j1, j2
          j = jcn(jj)
          if (j>jlast) go to 280
          cost = alen*(lenc(j)-1)
          if (cost>=cpiv) go to 280
! Pivot has best Markowitz count so far. Now check its suitability
!     on numerical grounds by examining other entries in its column.
          i1 = iq(j)
          i2 = i1 + lenc(j) - 1
          ii = idamax(lenc(j),a(i1),1)
          maxent = abs(a(i1+ii-1))
          do 260 ii = i1, i2 - 1
            if (irn(ii)==i) go to 270
260       continue
270       jpos = ii
! Exit loop if every entry in the column is below the pivot threshold.
          if (maxent<=cntl(4)) go to 320
          if (abs(a(jpos))<maxent*u) go to 280
! Candidate satisfies threshold criterion.
          cpiv = cost
          ipiv = i
          jpiv = j
          ijpos = jpos
          pivrat = abs(a(jpos))/maxent
          if (cpiv<=alen*(alen+1)) go to 330
280     continue

290   continue

300 continue
310 if (pivrat>zero) go to 330
! No pivot found. Switch to full matrix processing.
    info(1) = info(1) + 2
    if (mp>0) write (mp,'(A/A)') &
      ' Warning message from MA50AD: no suitable diagonal pivot', &
      ' found, so switched to full matrix processing.'
    go to 640

! Every entry in the column is below the pivot threshold.
320 ipiv = 0
    jpiv = j

! The pivot has now been found in position (IPIV,JPIV) in location
!     IJPOS in column file or all entries of column JPIV are very small
!     (IPIV=0).
! Update row and column ordering arrays to correspond with removal
!     of the active part of the matrix. Also update NEFACT.
330 nefact = nefact + lenc(jpiv)
    pivbeg = iq(jpiv)
    pivend = pivbeg + lenc(jpiv) - 1
    nord = nord + 1
    nord1 = nord
    if (nord==jlast) then
! We have ordered the first N - ICNTL(6) columns.
      nord = nord + nullj
      jlast = n
      nullj = 0
    end if
    if (icntl(4)<=0) then
! Remove active rows from their row ordering chains.
      do 340 ii = pivbeg, pivend
        i = irn(ii)
        lr = lastr(i)
        nr = nextr(i)
        if (nr/=0) lastr(nr) = lr
        if (lr==0) then
          ne1 = lenr(i)
          ifirst(ne1) = nr
        else
          nextr(lr) = nr
        end if
340   continue
    end if
    if (ipiv>0) then
! NEPR is number of entries in strictly U part of pivot row.
      nepr = lenr(ipiv) - 1
      nefact = nefact + nepr
      rinfo(1) = rinfo(1) + cpiv*2 + lenr(ipiv)
      j1 = ip(ipiv)
! Remove active columns from their column ordering chains.
      do 350 jj = j1, j1 + nepr
        j = jcn(jj)
        lc = lastc(j)
        nc = nextc(j)
        if (nc/=0) lastc(nc) = lc
        if (lc==0) then
          ne1 = lenc(j)
          jfirst(ne1) = nc
        else
          nextc(lc) = nc
        end if
350   continue
! Move pivot to beginning of pivot column.
      if (pivbeg/=ijpos) then
        asw = a(pivbeg)
        a(pivbeg) = a(ijpos)
        a(ijpos) = asw
        irn(ijpos) = irn(pivbeg)
        irn(pivbeg) = ipiv
      end if
    else
      nepr = 0
      ne1 = lenc(jpiv)
      if (cntl(3)>zero) ndrop = ndrop + ne1
      if (ne1>0) then
! Remove column of small entries from its column ordering chain.
        lc = lastc(jpiv)
        nc = nextc(jpiv)
        if (nc/=0) lastc(nc) = lc
        if (lc==0) then
          jfirst(ne1) = nc
        else
          nextc(lc) = nc
        end if
      end if
    end if

! Set up IW array so that IW(i) holds the relative position of row i
!    entry from beginning of pivot column.
    do 360 ii = pivbeg + 1, pivend
      i = irn(ii)
      iw(i) = ii - pivbeg
360 continue
! LENPIV is length of strictly L part of pivot column.
    lenpiv = pivend - pivbeg

! Remove pivot column (including pivot) from row oriented file.
    do 390 ii = pivbeg, pivend
      i = irn(ii)
      lenr(i) = lenr(i) - 1
      j1 = ip(i)
! J2 is last position in old row.
      j2 = j1 + lenr(i)
      do 370 jj = j1, j2 - 1
        if (jcn(jj)==jpiv) go to 380
370   continue
380   jcn(jj) = jcn(j2)
      jcn(j2) = 0
390 continue

! For each active column, add the appropriate multiple of the pivot
!     column to it.
! We loop on the number of entries in the pivot row since the position
!     of this row may change because of compresses.
    do 600 eye = 1, nepr
      j = jcn(ip(ipiv)+eye-1)
! Search column J for entry to be eliminated, calculate multiplier,
!     and remove it from column file.
!  IDROP is the number of nonzero entries dropped from column J
!        because these fall beneath tolerance level.
      idrop = 0
      jbeg = iq(j)
      jend = jbeg + lenc(j) - 1
      do 400 ii = jbeg, jend - 1
        if (irn(ii)==ipiv) go to 410
400   continue
410   amult = -a(ii)/a(iq(jpiv))
      a(ii) = a(jend)
      irn(ii) = irn(jend)
      lenc(j) = lenc(j) - 1
      irn(jend) = 0
      jend = jend - 1
! Jump if pivot column is a singleton.
      if (lenpiv==0) go to 600
! Now perform necessary operations on rest of non-pivot column J.
      iop = 0
! Innermost loop.
!DIR$ IVDEP
      do 420 ii = jbeg, jend
        i = irn(ii)
        if (iw(i)>0) then
! Row i is involved in the pivot column.
          iop = iop + 1
          pivcol = iq(jpiv) + iw(i)
! Flag IW(I) to show that the operation has been done.
          iw(i) = -iw(i)
          a(ii) = a(ii) + amult*a(pivcol)
        end if
420   continue

      if (cntl(3)>zero) then
!  Run through non-pivot column compressing column so that entries less
!      than CNTL(3) are not stored. All entries less than CNTL(3) are
!      also removed from the row structure.
        jnew = jbeg
        do 450 ii = jbeg, jend
          if (abs(a(ii))>=cntl(3)) then
            a(jnew) = a(ii)
            irn(jnew) = irn(ii)
            jnew = jnew + 1
          else
!  Remove non-zero entry from row structure.
            i = irn(ii)
            j1 = ip(i)
            j2 = j1 + lenr(i) - 1
            do 430 jj = j1, j2 - 1
              if (jcn(jj)==j) go to 440
430         continue
440         jcn(jj) = jcn(j2)
            jcn(j2) = 0
            lenr(i) = lenr(i) - 1
          end if
450     continue
        do 460 ii = jnew, jend
          irn(ii) = 0
460     continue
        idrop = jend + 1 - jnew
        jend = jnew - 1
        lenc(j) = lenc(j) - idrop
        nered = nered - idrop
        info(6) = info(6) + idrop
      end if

! IFILL is fill-in left to do to non-pivot column J.
      ifill = lenpiv - iop
      nered = nered + ifill
      info(3) = max(info(3),nered + lenc(j))

! Treat no-fill case
      if (ifill==0) then
!DIR$ IVDEP
        do 470 ii = pivbeg + 1, pivend
          i = irn(ii)
          iw(i) = -iw(i)
470     continue
        go to 600
      end if

! See if there is room for fill-in at end of the column.
      do 480 ipos = jend + 1, min(jend + ifill,dispc-1)
        if (irn(ipos)/=0) go to 490
480   continue
      if (ipos==jend +ifill+1) go to 540
      if (jend +ifill+1<=la+1) then
        dispc = jend + ifill + 1
        go to 540
      end if
      ipos = la
      dispc = la + 1
! JMORE more spaces for fill-in are required.
490   jmore = jend + ifill - ipos + 1
! We now look in front of the column to see if there is space for
!     the rest of the fill-in.
      do 500 ipos = jbeg - 1, max(jbeg-jmore,1_long), -1
        if (irn(ipos)/=0) go to 510
500   continue
      ipos = ipos + 1
      if (ipos==jbeg-jmore) go to 520
! Column must be moved to the beginning of available storage.
510   if (dispc+lenc(j)+ifill>la+1) then
        info(2) = info(2) + 1
! Call compress and reset pointers
        call ma50dd(a,irn,iq,n,dispc,.true.)
        jbeg = iq(j)
        jend = jbeg + lenc(j) - 1
        pivbeg = iq(jpiv)
        pivend = pivbeg + lenc(jpiv) - 1
!!!! Call to HSL_ZB01
! Was  ... go to 705
        if (dispc+lenc(j)+ifill>la+1) then
          oldlen = la
          la = multiplier*real(la,kind=wp)
          call ZB01_resize1(a,oldlen,la,zb01info)
          if (zb01info%flag .lt. 0) then
!XXX In the test deck, size(a) can be larger than (new) la
!    This will provoke an error return of -1 from HSL_ZB01
!    It can also be caused by an allocation error in HSL_ZB01
            info(1) = -2*n
            return
          endif
          call ZB01_integer(irn,oldlen,la,zb01intinfo)
          if (zb01intinfo%flag .lt. 0) then
! It can be caused by an allocation error in HSL_ZB01
            info(1) = -2*n
            return
          endif
        endif
      end if
      ipos = dispc
      dispc = dispc + lenc(j) + ifill
! Move non-pivot column J.
520   iq(j) = ipos
      do 530 ii = jbeg, jend
        a(ipos) = a(ii)
        irn(ipos) = irn(ii)
        ipos = ipos + 1
        irn(ii) = 0
530   continue
      jbeg = iq(j)
      jend = ipos - 1
! Innermost fill-in loop which also resets IW.
! We know at this stage that there are IFILL positions free after JEND.
540   idrop = 0
      do 580 ii = pivbeg + 1, pivend
        i = irn(ii)
!       info(3) = max(info(3),nered +lenr(i)+1)
        info(8) = max(info(8),nered +lenr(i)+1)
        if (iw(i)<0) then
          iw(i) = -iw(i)
          go to 580
        end if
        anew = amult*a(ii)
        if (abs(anew)<cntl(3)) then
          idrop = idrop + 1
        else
          jend = jend + 1
          a(jend) = anew
          irn(jend) = i

! Put new entry in row file.
! iend is end of row i with the fill-in included
          iend = ip(i) + lenr(i)
          if (iend<dispr) then
! Jump if can copy new entry to position iend
            if (jcn(iend)==0) go to 560
          else
            if (dispr<=ljcn) then
              dispr = dispr + 1
              go to 560
            end if
          end if
          if (ip(i)>1) then
! Check if there is a free space before the row in the row file
            if (jcn(ip(i)-1)==0) then
! Copy row forward
              iend = iend - 1
              do 545 jj = ip(i), iend
                jcn(jj-1) = jcn(jj)
545           continue
              ip(i) = ip(i) - 1
              go to 560
            end if
          end if
! The full row must be copied to end of row file storage
          if (dispr+lenr(i)>ljcn) then
! Compress row file array.
            info(2) = info(2) + 1
            call ma50dd(a,jcn,ip,m,dispr,.false.)
!!!! Call to HSL_ZB01
! Was earlier go to 705
            if (dispr+lenr(i)>ljcn) then
              oldlen = ljcn
              ljcn = 2*ljcn
              call ZB01_integer(jcn,oldlen,ljcn,zb01intinfo)
              if (zb01intinfo%flag .lt. 0) then
! It can be caused by an allocation error in HSL_ZB01
                info(1) = -2*n
                return
              endif
            endif
          end if
! Copy row to first free position.
          j1 = ip(i)
          j2 = ip(i) + lenr(i) - 1
          ip(i) = dispr
          do 550 jj = j1, j2
            jcn(dispr) = jcn(jj)
            jcn(jj) = 0
            dispr = dispr + 1
550       continue
          iend = dispr
          dispr = iend + 1
! Fill-in put in position iend in row file
560       jcn(iend) = j
          lenr(i) = lenr(i) + 1
! End of adjustment to row file.
        end if
580   continue
      info(6) = info(6) + idrop
      nered = nered - idrop
      do 590 ii = 1, idrop
        irn(jend +ii) = 0
590   continue
      lenc(j) = lenc(j) + ifill - idrop
! End of scan of pivot row.
600 continue


! Remove pivot row from row oriented storage and update column
!     ordering arrays.  Remember that pivot row no longer includes
!     pivot.
    do 610 eye = 1, nepr
      jj = ip(ipiv) + eye - 1
      j = jcn(jj)
      jcn(jj) = 0
      ne1 = lenc(j)
      lastc(j) = 0
      if (ne1>0) then
        ifir = jfirst(ne1)
        jfirst(ne1) = j
        nextc(j) = ifir
        if (ifir/=0) lastc(ifir) = j
        minc = min(minc,ne1)
      else if (icntl(7)/=2) then
        if (info(6)==0) nullc = nullc + 1
        if (j<=jlast) then
          nord = nord + 1
          iq(j) = -nord
          if (nord==jlast) then
! We have ordered the first N - ICNTL(6) columns.
            nord = nord + nullj
            jlast = n
            nullj = 0
          end if
        else
          nullj = nullj + 1
          iq(j) = -(jlast+nullj)
        end if
      end if
610 continue
    nered = nered - nepr

! Restore IW and remove pivot column from column file.
!    Record the row permutation in IP(IPIV) and the column
!    permutation in IQ(JPIV), flagging them negative so that they
!    are not confused with real pointers in compress routine.
    if (ipiv/=0) then
      lenr(ipiv) = 0
      iw(ipiv) = 0
      irn(pivbeg) = 0
      mord = mord + 1
      pivbeg = pivbeg + 1
      ip(ipiv) = -mord
    end if
    nered = nered - lenpiv - 1
    do 620 ii = pivbeg, pivend
      i = irn(ii)
      iw(i) = 0
      irn(ii) = 0
      ne1 = lenr(i)
      if (ne1==0) then
        if (info(6)==0) nullr = nullr + 1
        ip(i) = -m + nulli
        nulli = nulli + 1
      else if (icntl(4)<=0) then
! Adjust row ordering arrays.
        ifir = ifirst(ne1)
        lastr(i) = 0
        nextr(i) = ifir
        ifirst(ne1) = i
        if (ifir/=0) lastr(ifir) = i
        minc = min(minc,ne1)
      end if
620 continue
    iq(jpiv) = -nord1
630 continue
! We may drop through this loop with NULLI nonzero.

! ********************************************
! ****    End of main elimination loop    ****
! ********************************************

! Complete the permutation vectors
640 info(5) = mord + min(m-mord-nulli,n-nord-nullj)
  do 650 l = 1, min(m-mord,n-nord)
    rinfo(1) = rinfo(1) + real(m - mord - l + 1,kind=wp) +  &
                          real(m-mord-l,kind=wp)*real(n-nord-l,kind=wp)*2.0d0
650 continue
  np = nord
! Estimate of reals for subsequent factorization
!! Because we can't easily decouple real/integer with BTF structure
!! We leave info(4) to be the maximum value
!!info(4) = 2 + nefact + m*2 + (n-nord)*(m-mord)
  info(4) = 2 + nefact + m*2 + max((n-nord)*(m-mord),n-nord +m-mord)
! Estimate of integers for subsequent factorization
  info(9) = 2 + nefact + m*2 + n-nord +m-mord
  info(6) = info(6) + ndrop
  info(7) = m - mord
  do 660 l = 1, m
    if (ip(l)<0) then
      ip(l) = -ip(l)
    else
      mord = mord + 1
      ip(l) = mord
    end if
660 continue
  do 670 l = 1, n
    if (iq(l)<0) then
      lastc(l) = -iq(l)
    else
      if (nord==jlast) nord = nord + nullj
      nord = nord + 1
      lastc(l) = nord
    end if
670 continue
! Store the inverse permutation
  do 680 l = 1, n
    iq(lastc(l)) = l
680 continue

! Test for rank deficiency
  if (info(5)<min(m,n)) info(1) = info(1) + 1

  if (mp>0 .and. icntl(3)>2) then
    write (mp,'(A,I6,A,F12.1/A,7I8)') ' Leaving MA50AD with NP =', np, &
      ' RINFO(1) =', rinfo(1), ' INFO =', (info(i),i=1,7)
    if (icntl(3)>3) then
      write (mp,'(A,(T6,10(I7)))') ' IP = ', ip
      write (mp,'(A,(T6,10(I7)))') ' IQ = ', iq
    end if
  end if

  go to 750

! Error conditions.
! Can't happen if call through HSL_MA48
!690 info(1) = -1
!  if (lp>0) write (lp,'(/A/(2(A,I8)))') ' **** Error return from MA50AD ****',&
!    ' M =', m, ' N =', n
!  go to 750
700 info(1) = -2
  if (lp>0) write (lp,'(/A/(A,I10))') ' **** Error return from MA50AD ****', &
    ' NE =', ne
  go to 750
!XXX Use of hsl_ZB01 prevents this problem
!!705 info(4) = nefact + nered
!!  info(6) = info(6) + ndrop
  710 info(1) = -3
    if (lp>0) write (lp,'(/A/A,I9,A,I9)') &
      ' **** Error return from MA50AD ****', &
      ' LA  must be increased from', la, ' to at least', info(3)
    go to 750
!!!
! By this time all duplicates should have been removed but am leaving
! this in in case MA50 is tested separately.
!720 info(1) = -4
!  if (lp>0) write (lp,'(/A/(3(A,I9)))') ' **** Error return from MA50AD ****',&
!    ' Entry in row', i, ' and column', j, ' duplicated'
!  go to 750
730 info(1) = -5
  if (lp>0) write (lp,'(/A/(3(A,I9)))') ' **** Error return from MA50AD ****', &
    ' Fault in component ', pivot, ' of column permutation given in IFIRST'
  go to 750
740 info(1) = -6
  if (lp>0) write (lp,'(/A/(3(A,I9)))') ' **** Error return from MA50AD ****', &
    ' ICNTL(4) = ', icntl(4), ' when ICNTL(6) = 2'
750 end  subroutine ma50ad


SUBROUTINE ma50bd(m,n,ne,job,aa,irna,iptra,cntl,icntl,ip,iq,np,lfact,fact, &
    lirnf,irnf,iptrl,iptru,info,rinfo)
! MA50B/BD factorizes the matrix in AA/IRNA/IPTRA as P L U Q where
!     P and Q are permutations, L is lower triangular, and U is unit
!     upper triangular. The prior information that it uses depends on
!     the value of the parameter JOB.

  integer m, n, job
  integer(long) ::  ne
  real(wp) :: aa(ne)
  integer(long) :: irna(ne)
  integer(long) :: iptra(n)
  real(wp) :: cntl(10)
  integer :: icntl(20), np
  integer(long) :: ip(m), iq(*), lfact, lirnf
!! At the moment, lfact = lirnf for this to work and especially for
!! the blocking (for BTF) in ma48bd to work.  We may change this later.
  real(wp) :: fact(lfact)
  integer(long) irnf(lirnf)
  integer(long) :: iptrl(n), iptru(n)
  real(wp), allocatable :: w(:)
  integer(long), allocatable :: iw(:)
  integer(long) :: info(15)
  real(wp) :: rinfo(10)

! M is an integer variable that must be set to the number of rows.
!      It is not altered by the subroutine.
! N is an integer variable that must be set to the number of columns.
!      It is not altered by the subroutine.
! NE is an integer variable that must be set to the number of entries
!      in the input matrix.  It is not altered by the subroutine.
! JOB is an integer variable that must be set to the value 1, 2, or 3.
!     If JOB is equal to 1 and any of the first NP recommended pivots
!      fails to satisfy the threshold pivot tolerance, the row is
!      interchanged with the earliest row in the recommended sequence
!      that does satisfy the tolerance. Normal row interchanges are
!      performed in the last N-NP columns.
!     If JOB is equal to 2, then M, N, NE, IRNA, IPTRA, IP, IQ,
!      LFACT, NP, IRNF, IPTRL, and IPTRU must be unchanged since a
!      JOB=1 entry for the same matrix pattern and no interchanges are
!      performed among the first NP pivots; if ICNTL(6) > 0, the first
!      N-ICNTL(6) columns of AA must also be unchanged.
!     If JOB is equal to 3, ICNTL(6) must be in the range 1 to N-1.
!      The effect is as for JOB=2 except that interchanges are
!      performed.
!     JOB is not altered by the subroutine.
! AA is an array that holds the entries of the matrix and
!      is not altered.
! IRNA is an integer array of length NE that must be set to hold the
!      row indices of the corresponding entries in AA. It is not
!      altered.
! IPTRA is an integer array that holds the positions of the starts of
!      the columns of AA. It is not altered by the subroutine.
! CNTL  must be set by the user as follows and is not altered.
!     CNTL(2) determines the balance between pivoting for sparsity and
!       for stability, values near zero emphasizing sparsity and values
!       near one emphasizing stability.
!     CNTL(3) If this is set to a positive value, any entry whose
!       modulus is less than CNTL(3) will be dropped from the factors.
!       The factorization will then require less storage but will be
!       inaccurate.
!     CNTL(4)  Any entry of the reduced matrix whose modulus is less
!       than or equal to CNTL(4) will be regarded as zero from the
!        point of view of rank.
! ICNTL must be set by the user as follows and is not altered.
!     ICNTL(1)  must be set to the stream number for error messages.
!       A value less than 1 suppresses output.
!     ICNTL(2) must be set to the stream number for diagnostic output.
!       A value less than 1 suppresses output.
!     ICNTL(3) must be set to control the amount of output:
!       0 None.
!       1 Error messages only.
!       2 Error and warning messages.
!       3 As 2, plus scalar parameters and a few entries of array
!         parameters on entry and exit.
!       4 As 2, plus all parameters on entry and exit.
!     ICNTL(5) The block size to be used for full-matrix processing.
!       If <=0, the BLAS1 version is used.
!       If =1, the BLAS2 version is used.
!     ICNTL(6) If N > ICNTL(6) > 0, only the columns of A that
!       correspond to the last ICNTL(6) columns of the permuted matrix
!       may change prior to an entry with JOB > 1.
!     ICNTL(8) If this has value 1, there is no attempt to compute a
!       recommended value for LFACT if it is too small.
! IP is an integer array. If JOB=1, it must be set so that IP(I) < IP(J)
!      if row I is recommended to precede row J in the pivot sequence.
!      If JOB>1, it need not be set. If JOB=1 or JOB=3, IP(I) is set
!      to -K when row I is chosen for pivot K and IP is eventually
!      reset to recommend the chosen pivot sequence to a subsequent
!      JOB=1 entry. If JOB=2, IP is not be referenced.
! IQ is an integer array that must be set so that either IQ(J) is the
!      column in position J in the pivot sequence, J=1,2,...,N,
!      or IQ(1)=0 and the columns are taken in natural order.
!      It is not altered by the subroutine.
! NP is an integer variable that holds the number of columns to be
!      processed in packed storage. It is not altered by the subroutine.
! LFACT is an integer variable set to the size of FACT and IRNF.
!      It is not altered by the subroutine.
! FACT is an array that need not be set on a JOB=1 entry and must be
!      unchanged since the previous entry if JOB>1. On return, FACT(1)
!      holds the value of CNTL(3) used, FACT(2) will holds the value
!      of CNTL(4) used, FACT(3:IPTRL(N)) holds the packed part of L/U
!      by columns, and the full part of L/U is held by columns
!      immediately afterwards. U has unit diagonal entries, which are
!      not stored. In each column of the packed part, the entries of
!      U precede the entries of L; also the diagonal entries of L
!      head each column of L and are reciprocated.
! IRNF is an integer array of length LFACT that need not be set on
!      a JOB=1 entry and must be unchanged since the previous entry
!      if JOB>1. On exit, IRNF(1) holds the number of dropped entries,
!      IRNF(2) holds the number of rows MF in full storage,
!      IRNF(3:IPTRL(N)) holds the row numbers of the packed part
!      of L/U, IRNF(IPTRL(N)+1:IPTRL(N)+MF) holds the row indices
!      of the full part of L/U, and IRNF(IPTRL(N)+MF+I), I=1,2,..,N-NP
!      holds the vector IPIV output by MA50GD.
!      If JOB=2, IRNF will be unaltered.
! IPTRL is an integer array that need not be set on a JOB=1 entry and
!     must be unchanged since the previous entry if JOB>1.
!     For J = 1,..., NP, IPTRL(J) holds the position in
!     FACT and IRNF of the end of column J of L.
!     For J = NP+1,..., N, IPTRL(J) is equal to IPTRU(J).
! IPTRU is an integer array that need not be set on a JOB=1 entry and
!     must be unchanged since the previous entry if JOB>1.
!     For J = 1,..., N, IPTRU(J) holds the position in
!     FACT and IRNF of the end of the packed part of column J of U.
! W is an array of length M used as workspace for holding
!      the expanded form of a sparse vector.
! IW is an integer array of length M+2*N used as workspace.
! INFO need not be set on entry. On exit, it holds the following:
!    INFO(1) A negative value will indicate an error return and a
!       positive value a warning. Possible nonzero values are:
!      -1  M < 1 or N < 1.
!      -2  NE < 0.
!      -3  Insufficient space.
!      -4  There are duplicated entries.
!      -5  JOB < 1, 3 when ICNTL(6)=0, or > 3.
!      -6  JOB = 2, but entries were dropped in the corresponding JOB=1
!          entry.
!      -7  NP < 0 or NP > N.
!     -(7+K) Pivot too small in column K when JOB=2.
!      +1  Rank deficient.
!    INFO(4) Minimum storage required to factorize matrix
!            if INFO(1) >= 0. Recommended value for LFACT
!            if ICNTL(8) = 0 and INFO(1) = -3.
!    INFO(5) Computed rank of the matrix.
!    INFO(6) Number of entries dropped from the data structure.
!    INFO(7) Number of rows processed in full storage.
! RINFO need not be set on entry. On exit, RINFO(1) holds the number of
!    floating-point operations performed.

  real(wp) :: zero, one
  parameter (zero=0.0_wp,one=1.0_wp)
  real(wp) :: amult, asw
  integer(long) :: begcol
  logical drop
  integer(long) :: endcol, eye, eye1, i, ia1, ia2, if1, if2, ii,   &
    il1, il2, ipiv, iqpiv, &
    iu1, iu2, isw, j, jdummy, jj, lp
  real(wp) :: maxent
  integer :: k, jlast, mf, mord, mp, nf, nullc
  integer(long) :: neu
  real(wp) :: pivlim
  integer :: rank
  real(wp) :: u
! AMULT Temporary variable used to store current multiplier.
! ASW Temporary variable used when swopping two real quantities.
! BEGCOL is pointer to beginning of section of column when pruning.
! DROP True if any entries dropped from current column.
! ENDCOL is pointer to end of section of column when pruning.
! EYE Running position for current column.
! EYE1 Position of the start of second current column.
! I Temporary variable holding row number. Also used as index in DO
!     loops used in initialization of arrays.
! IA1 Position of the start of the current column in AA.
! IA2 Position of the end of the current column in AA.
! IF1 Position of the start of the full submatrix.
! IF2 Position of the end of the full submatrix.
! II Running position for current column.
! IL1 Position of the first entry of the current column of L.
! IL2 Position of the last entry of the current column of L.
! IPIV Position of the pivot in FACT and IRNF.
! IQPIV Recommended position of the pivot row in the pivot sequence.
! IU1 Position of the start of current column of U.
! IU2 Position of the end of the current column of U.
! ISW Temporary variable used when swopping two integer quantities.
! J Temporary variable holding column number.
! JDUMMY DO index not referenced in the loop.
! JJ Running position for current column.
! JLAST The lesser of NP and the last column of A for which no new
!     factorization operations are needed.
! K Temporary variable holding the current pivot step in the elimination
! LP Unit for error messages.
! MAXENT Temporary variable used to hold value of largest entry in
!    column.
! MF Number of rows in full block.
! MORD Number of rows ordered.
! MP Unit for diagnostic messages.
! NEU Number of entries omitted from U and the full block in order to
!    calculate INFO(4) (0 unless INFO(1)=-3).
! NF Number of columns in full block.
! NULLC Number of columns found null before dropping any elements.
! PIVLIM Limit on pivot size.
! RANK Value returned by MA50E/ED or MA50F/FD
! U Used to hold local copy of CNTL(2), changed if necessary so that it
!    is in range.

  intrinsic abs, max, min
! LAPACK subroutine for triangular factorization.

  info(1) = 0
  info(4) = 0
  info(5) = 0
  info(6) = 0
  info(7) = 0
  info(9) = 0
  rinfo(1) = zero
  lp = icntl(1)
  mp = icntl(2)
  if (icntl(3)<=0) lp = 0
  if (icntl(3)<=1) mp = 0

! Check input values
!!!
! Won't of course happen in hsl_ma48 context
! if (m<1 .or. n<1) then
!   info(1) = -1
!   if (lp>0) write (lp,'(/A/A,I8,A,I8)') &
!     ' **** Error return from MA50BD ****', ' M =', m, ' N =', n
!   go to 550
! end if
  if (ne<=0) then
    info(1) = -2
    if (lp>0) write (lp,'(/A/A,I6)') ' **** Error return from MA50BD ****', &
      ' NE =', ne
    go to 550
  end if
  if (np<0 .or. np>n) then
    info(1) = -7
    if (lp>0) write (lp,'(/A/A,I8,A,I8)') &
      ' **** Error return from MA50BD ****', ' NP =', np, ' N =', n
    go to 550
  end if
  if (lfact<max(m*onel,ne+2)) then
    info(4) = max(m*onel,ne+2)
    go to 520
  end if
  if (job==1) then
  else if (job==2 .or. job==3) then
    if (irnf(1)/=0) then
      info(1) = -6
      if (lp>0) write (lp,'(/A/A,I1,A)') ' **** Error return from MA50BD ***', &
        ' Call with JOB=', job, &
        ' follows JOB=1 call in which entries were dropped'
      go to 550
    end if
  else
    info(1) = -5
    if (lp>0) write (lp,'(/A/A,I2)') ' **** Error return from MA50BD ****', &
      ' JOB =', job
    go to 550
  end if

! Allocate work arrays
  allocate(w(m),stat = stat)
  if (stat .ne. 0) then
    info(1) = -2*n
    return
  endif
  allocate(iw(m+2*n),stat = stat)
  if (stat .ne. 0) then
    info(1) = -2*n
    return
  endif

! Print input data
  if (mp>0) then
    if (icntl(3)>2) write (mp, &
      '(/2(A,I6),A,I8,A,I3/A,I8,A,I7/A,1P,4E10.2/A,7I8)') &
      ' Entering MA50BD with M =', m, ' N =', n, ' NE =', ne, ' JOB =', job, &
      ' LFACT =', lfact, ' NP =', np, ' CNTL =', (cntl(i),i=1,4), ' ICNTL =', &
      (icntl(i),i=1,7)
    if (icntl(3)>3) then
      write (mp,'(A,(T6,10(I7)))') ' IP = ', ip
      if (iq(1)>0) then
        write (mp,'(A,(T6,10(I7)))') ' IQ = ', (iq(j),j=1,n)
      else
        write (mp,'(A,(T6,I7))') ' IQ = ', iq(1)
      end if
      do 10 j = 1, n - 1
        if (iptra(j)<iptra(j+1)) write (mp,'(A,I5,(T13,3(1P,E12.4,I5)))') &
          ' Column', j, (aa(ii),irna(ii),ii=iptra(j),iptra(j+1)-1)
10    continue
      if (iptra(n)<=ne) write (mp,'(A,I5,(T13,3(1P,E12.4,I5)))') ' Column', n, &
        (aa(ii),irna(ii),ii=iptra(n),ne)
    end if
  end if

! Initializations.
  jlast = 0
  nullc = 0
  if (job>1 .and. icntl(6)>0 .and. icntl(6)<n) jlast = min(np,n-icntl(6))

  u = min(cntl(2),one)
  u = max(u,zero)
  do 20 i = 1, m
    iw(i+n) = 0
    w(i) = zero
20 continue
  mord = 0
  if1 = lfact + 1
  if2 = 0
  nf = n - np
  mf = 0
  il2 = 2
  if (jlast>0) il2 = iptrl(jlast)
  neu = 0

! Jump if JOB is equal to 2.
  if (job==2) go to 370

  if (job==3) then
! Reconstruct IP and set MORD
    do 30 j = 1, np
      ia1 = iptru(j) + 1
      if (ia1>iptrl(j)) go to 30
      if (j<=jlast) then
        mord = mord + 1
        ip(irnf(ia1)) = -j
      else
        ip(irnf(ia1)) = j
      end if
30  continue
    mf = irnf(2)
    ia1 = iptrl(n)
    do 40 j = 1, mf
      ip(irnf(ia1+j)) = np + j
40  continue
  end if

! Store copies of column ends ready for pruning
  do 50 k = 1, jlast
    iw(m+n+k) = iptrl(k)
50 continue

! Each pass through this main loop processes column K.
  do 310 k = jlast + 1, n
    drop = .false.
    if (k==np+1) then
! Set up data structure for full part.
      mf = m - mord
      if1 = lfact + 1 - mf
      ii = 0
      do 60 i = 1, m
        if (ip(i)>0) then
          iw(i+n) = n
          irnf(if1+ii) = i
          ii = ii + 1
          ip(i) = np + ii
        end if
60    continue
      if1 = lfact + 1 - max(mf*nf,mf+nf)
      if2 = if1 - 1 + mf*max(0,jlast-np)
    end if
    j = k
    if (iq(1)>0) j = iq(k)
    ia1 = iptra(j)
    ia2 = ne
    if (j/=n) ia2 = iptra(j+1) - 1
    iu1 = il2 + 1
    iu2 = iu1 - 1
    il1 = if1 - 1 + ia1 - ia2
    il2 = il1 - 1
    info(4) = max(info(4),neu+lfact-il1+iu2+m+1)
    info(9) = max(info(9),neu+lfact-il1+iu2+m+1)
    if (il1-iu2<=m) then
      if (info(1)/=-3) then
        info(1) = -3
        if (icntl(8)/=0) go to 480
! Get rid of U info.
        neu = il2 + lfact + 1 - mf - if1
        if1 = lfact + 1 - mf
        if2 = if1 - 1
        il2 = 0
        eye = 0
        do 80 j = 1, min(k-1,np)
          iu2 = iptru(j)
          iptru(j) = eye
          il2 = iptrl(j)
          neu = neu + iu2 - il2
          do 70 ii = iu2 + 1, il2
            eye = eye + 1
            irnf(eye) = irnf(ii)
            fact(eye) = fact(ii)
70        continue
          iptrl(j) = eye
          iw(m+n+j) = eye
80      continue
        iu1 = eye + 1
        iu2 = eye
        il1 = if1 - 1 + ia1 - ia2
        il2 = il1 - 1
      end if
! Quit if LFACT is much too small
      if (il1-iu2<=m) go to 480
    end if
! Load column K of AA into full vector W and into the back of IRNF.
! Check for duplicates.
    eye = il1
    do 90 ii = ia1, ia2
      i = irna(ii)
!!!
! Can't happen if called from HSL_MA48
!     if (iw(i+n)==-1) go to 540
      iw(i+n) = -1
      w(i) = aa(ii)
      irnf(eye) = i
      eye = eye + 1
90  continue
! Depth first search to find topological order for triangular solve
!     and structure of column K of L/U
! IW(J) is used to hold a pointer to next entry in column J
!     during the depth-first search at stage K, J = 1,..., N.
! IW(I+N) is set to K when row I has been processed, and to N for rows
!     of the full part once column NP has been passed. It is also
!     used for backtracking, a negative value being used to point to the
!     previous row in the chain.
! IW(M+N+I) is set to the position in FACT and IRNF of the end of the
!     active part of the column after pruning.  It is initially set to
!     IPTRL(I) and is flagged negative when column has been pruned.
! Set IPTRL temporarily for column K so that special code is
!     not required to process this column.
    iptrl(k) = eye - 1
    iw(m+n+k) = eye - 1
! IW(K) is set to beginning of original column K.
    iw(k) = il1
    j = k
! The outer loop of the depth-first search is executed once for column
!      K and twice for each entry in the upper-triangular part of column
!      K (once to initiate a search in the corresponding column and
!      once when the search in the column is finished).
    do 120 jdummy = 1, 2*k
! Look through column J of L (or column K of A). All the entries
!     are entries of the filled-in column K. Store new entries of the
!     lower triangle and continue until reaching an entry of the upper
!     triangle.
      do 100 ii = iw(j), abs(iw(m+n+j))
        i = irnf(ii)
! Jump if index I already encountered in column K or is in full part.
        if (iw(i+n)>=k) go to 100
        if (ip(i)<=0) go to 110
! Entry is in lower triangle. Flag it and store it in L.
        iw(i+n) = k
        il1 = il1 - 1
        irnf(il1) = i
100   continue
      if (j==k) go to 130
! Flag J, put its row index into U, and backtrack
      iu2 = iu2 + 1
      i = irnf(iptru(j)+1)
      irnf(iu2) = i
      j = -iw(i+n)
      iw(i+n) = k
      go to 120
! Entry in upper triangle.  Move search to corresponding column.
110   iw(i+n) = -j
      iw(j) = ii + 1
      j = -ip(i)
      iw(j) = iptru(j) + 2
120 continue
! Run through column K of U in the lexicographical order that was just
!     constructed, performing elimination operations.
130 do 150 ii = iu2, iu1, -1
      i = irnf(ii)
      j = -ip(i)
! Add multiple of column J of L to column K
      eye1 = iptru(j) + 1
      if (abs(w(i))<cntl(3)) go to 150
      amult = -w(i)*fact(eye1)
! Note we are storing negative multipliers
      w(i) = amult
      do 140 eye = eye1 + 1, iptrl(j)
        i = irnf(eye)
        w(i) = w(i) + amult*fact(eye)
140   continue
      rinfo(1) = rinfo(1) + one + 2*(iptrl(j)-eye1)
150 continue

! Unload reals of column of U and set pointer
    if (cntl(3)>zero) then
      eye = iu1
      do 160 ii = iu1, iu2
        i = irnf(ii)
        if (abs(w(i))<cntl(3)) then
          info(6) = info(6) + 1
        else
          irnf(eye) = -ip(i)
          fact(eye) = w(i)
          eye = eye + 1
        end if
        w(i) = zero
160   continue
      iu2 = eye - 1
    else
      do 170 ii = iu1, iu2
        i = irnf(ii)
        irnf(ii) = -ip(i)
        fact(ii) = w(i)
        w(i) = zero
170   continue
    end if
    if (info(1)==-3) then
      neu = neu + iu2 - iu1 + 1
      iu2 = iu1 - 1
    end if
    iptru(k) = iu2
    if (k<=np) then
! Find the largest entry in the column and drop any small entries
      maxent = zero
      if (cntl(3)>zero) then
        eye = il1
        do 180 ii = il1, il2
          i = irnf(ii)
          if (abs(w(i))<cntl(3)) then
            info(6) = info(6) + 1
            w(i) = zero
            drop = .true.
          else
            irnf(eye) = i
            eye = eye + 1
            maxent = max(abs(w(i)),maxent)
          end if
180     continue
        il2 = eye - 1
      else
        do 190 ii = il1, il2
          maxent = max(abs(w(irnf(ii))),maxent)
190     continue
      end if
! Unload column of L, performing pivoting and moving indexing
!      information.
      pivlim = u*maxent
      eye = iu2
      iqpiv = m + n
      if (il1>il2) nullc = nullc + 1
      do 200 ii = il1, il2
        i = irnf(ii)
        eye = eye + 1
        irnf(eye) = i
        fact(eye) = w(i)
        w(i) = zero
! Find position of pivot
        if (abs(fact(eye))>=pivlim) then
          if (abs(fact(eye))>cntl(4)) then
            if (ip(i)<iqpiv) then
              iqpiv = ip(i)
              ipiv = eye
            end if
          end if
        end if
200   continue
      il1 = iu2 + 1
      il2 = eye
      if (il1<=il2) then
! Column is not null
        if (iqpiv==m+n) then
! All entries in the column are too small to be pivotal. Drop them all.
          if (cntl(3)>zero) info(6) = info(6) + eye - iu2
          il2 = iu2
        else
          if (il1/=ipiv) then
! Move pivot to front of L
            asw = fact(ipiv)
            fact(ipiv) = fact(il1)
            fact(il1) = asw
            isw = irnf(il1)
            irnf(il1) = irnf(ipiv)
            irnf(ipiv) = isw
          end if
! Reciprocate pivot
          info(5) = info(5) + 1
          fact(il1) = one/fact(il1)
          rinfo(1) = rinfo(1) + one
! Record pivot row
          mord = mord + 1
          ip(irnf(il1)) = -k
        end if
      end if
    else
! Treat column as full
      il2 = iptru(k)
!DIR$ IVDEP
      do 210 ii = lfact - mf + 1, lfact
        i = irnf(ii)
        if2 = if2 + 1
        fact(if2) = w(i)
        w(i) = zero
210   continue
      if (info(1)==-3) if2 = if2 - mf
    end if
    iw(m+n+k) = il2
    iptrl(k) = il2
    if (drop) go to 310
! Scan columns involved in update of column K and remove trailing block.
    do 300 ii = iu1, iu2
      i = irnf(ii)
! Jump if column already pruned.
      if (iw(m+n+i)<0) go to 300
      begcol = iptru(i) + 2
      endcol = iptrl(i)
! Scan column to see if there is an entry in the current pivot row.
      if (k<=np) then
        do 220 jj = begcol, endcol
          if (ip(irnf(jj))==-k) go to 230
220     continue
        go to 300
      end if
! Sort the entries so that those in rows already pivoted (negative IP
!    values) precede the rest.
230   do 280 jdummy = begcol, endcol
        jj = begcol
        do 240 begcol = jj, endcol
          if (ip(irnf(begcol))>0) go to 250
240     continue
        go to 290
250     jj = endcol
        do 260 endcol = jj, begcol, -1
          if (ip(irnf(endcol))<0) go to 270
260     continue
        go to 290
270     asw = fact(begcol)
        fact(begcol) = fact(endcol)
        fact(endcol) = asw
        j = irnf(begcol)
        irnf(begcol) = irnf(endcol)
        irnf(endcol) = j
        begcol = begcol + 1
        endcol = endcol - 1
280   continue
290   iw(m+n+i) = -endcol
300 continue
310 continue
  if (n==np) then
! Set up data structure for the (null) full part.
    mf = m - mord
    if1 = lfact + 1 - mf
    ii = 0
    do 320 i = 1, m
      if (ip(i)>0) then
        iw(i+n) = n
        irnf(if1+ii) = i
        ii = ii + 1
        ip(i) = np + ii
      end if
320 continue
    if1 = lfact + 1 - max(mf*nf,mf+nf)
    if2 = if1 - 1 + mf*max(0,jlast-np)
  end if
  if (info(5)==min(m,n)) then
! Restore sign of IP
    do 330 i = 1, m
      ip(i) = abs(ip(i))
330 continue
  else
! Complete IP
    mord = np
    do 340 i = 1, m
      if (ip(i)<0) then
        ip(i) = -ip(i)
      else
        mord = mord + 1
        ip(i) = mord
      end if
340 continue
  end if
  irnf(1) = info(6)
  irnf(2) = mf
  info(7) = mf
  fact(1) = cntl(3)
  fact(2) = cntl(4)
  if (info(1)==-3) go to 520
! Move full part forward
  if2 = if2 - mf*nf
  do 350 ii = 1, mf*nf
    fact(il2+ii) = fact(if1-1+ii)
350 continue
  do 360 ii = 1, mf
    irnf(il2+ii) = irnf(lfact-mf+ii)
360 continue
  if1 = il2 + 1
  go to 440

! Fast factor (JOB = 2)
! Each pass through this main loop processes column K.
370 mf = irnf(2)
  if1 = iptrl(n) + 1
  if2 = if1 - 1
  do 430 k = jlast + 1, n
    j = k
    if (iq(1)>0) j = iq(k)
    ia1 = iptra(j)
    ia2 = ne
    if (j/=n) ia2 = iptra(j+1) - 1
    iu1 = il2 + 1
    iu2 = iptru(k)
    il1 = iu2 + 1
    il2 = iptrl(k)
! Load column K of A into full vector W
    do 380 ii = ia1, ia2
      w(irna(ii)) = aa(ii)
380 continue
! Run through column K of U in lexicographical order, performing
!      elimination operations.
    do 400 ii = iu2, iu1, -1
      j = irnf(ii)
      i = irnf(iptru(j)+1)
! Add multiple of column J of L to column K
      eye1 = iptru(j) + 1
      amult = -w(i)*fact(eye1)
! Note we are storing negative multipliers
      fact(ii) = amult
      w(i) = zero
      do 390 eye = eye1 + 1, iptrl(j)
        i = irnf(eye)
        w(i) = w(i) + amult*fact(eye)
390   continue
      rinfo(1) = rinfo(1) + one + 2*(iptrl(j)-eye1)
400 continue
    if (k<=np) then
      if (il1<=il2) then
! Load column of L.
!DIR$ IVDEP
        do 410 ii = il1, il2
          i = irnf(ii)
          fact(ii) = w(i)
          w(i) = zero
410     continue
! Test pivot. Note that this is the only numerical test when JOB = 2.
        if (abs(fact(il1))<=cntl(4)) then
          go to 530
        else
! Reciprocate pivot
          info(5) = info(5) + 1
          fact(il1) = one/fact(il1)
          rinfo(1) = rinfo(1) + one
        end if
      end if
    else
! Treat column as full
      do 420 ii = if1, if1 + mf - 1
        i = irnf(ii)
        if2 = if2 + 1
        fact(if2) = w(i)
        w(i) = zero
420   continue
    end if
430 continue
  info(4) = max(if1+mf+nf-1,if2)
  info(9) = max(if1+mf+nf-1,if2)

440 if (mf>0 .and. nf>0) then
! Factorize full block
    if (icntl(5)>1) call ma50gd(mf,nf,fact(if1),mf,icntl(5),cntl(4), &
      irnf(if1+mf),rank)
    if (icntl(5)==1) call ma50fd(mf,nf,fact(if1),mf,cntl(4),irnf(if1+mf),rank)
    if (icntl(5)<=0) call ma50ed(mf,nf,fact(if1),mf,cntl(4),irnf(if1+mf),rank)
    info(5) = info(5) + rank
    do 450 i = 1, min(mf,nf)
      rinfo(1) = rinfo(1) + real(mf - i + 1,kind=wp) + &
                            real(mf-i,kind=wp)*real(nf-i,kind=wp)*2.0d0
450 continue
  end if
  if (info(5)<min(m,n)) info(1) = 1
  if (mp>0 .and. icntl(3)>2) then
    write (mp,'(A,I6,A,F12.1/A,I3,A,4I8)') ' Leaving MA50BD with IRNF(2) =', &
      irnf(2), ' RINFO(1) =', rinfo(1), ' INFO(1) =', info(1), ' INFO(4:7) =', &
      (info(j),j=4,7)
    if (icntl(3)>3) then
      if (job/=2) write (mp,'(A,(T6,10(I7)))') ' IP = ', ip
      do 460 j = 1, n
        if (j>1) then
          if (iptrl(j-1)<iptru(j)) write (mp,'(A,I5,A,(T18,3(1P,E12.4,I5)))') &
            ' Column', j, ' of U', (fact(ii),irnf(ii),ii=iptrl(j-1)+1,iptru(j) &
            )
        end if
        if (iptru(j)<iptrl(j)) write (mp,'(A,I5,A,(T18,3(1P,E12.4,I5)))') &
          ' Column', j, ' of L', (fact(ii),irnf(ii),ii=iptru(j)+1,iptrl(j))
460   continue
      write (mp,'(A)') ' Full part'
      write (mp,'((6I12))') (irnf(if1+mf+j),j=0,nf-1)
      do 470 i = 0, mf - 1
        write (mp,'(I4,1P,6E12.4:/(4X,1P,6E12.4))') irnf(if1+i), &
          (fact(if1+i+j*mf),j=0,nf-1)
470   continue
    end if
  end if
  go to 550

! Error conditions
! LFACT is much too small or ICNTL(8)/=0. Patch up IP and quit.
480 do 490 i = 1, m
    iw(i) = 0
490 continue
  do 500 i = 1, m
    if (ip(i)>0) then
      iw(ip(i)) = i
    else
      ip(i) = -ip(i)
    end if
500 continue
  do 510 i = 1, m
    if (iw(i)>0) then
      ip(iw(i)) = k
      k = k + 1
    end if
510 continue
520 info(1) = -3
  if (lp>0) then
    write (lp,'(/A)') ' **** Error return from MA50BD **** '
    if (icntl(8)==0) then
      write (lp,'(A,I7,A,I7)') ' LFACT must be increased from', lfact, &
        ' to at least', info(4)
    else
      write (lp,'(A,I7)') ' LFACT must be increased from', lfact
    end if
  end if
  go to 550
530 info(1) = -(7+k)
  if (lp>0) write (lp,'(/A/A,I6,A)') ' **** Error return from MA50BD **** ', &
    ' Small pivot found in column', k, ' of the permuted matrix.'
!  go to 550
!!!
! Again this error can only happen if MA50 is tested separately
!540 info(1) = -4
!  if (lp>0) write (lp,'(/A/(3(A,I9)))') ' **** Error return from MA50BD ****',&
!    ' Entry in row', i, ' and column', j, ' duplicated'
550 end subroutine ma50bd

SUBROUTINE ma50cd(m,n,icntl,iq,np,trans,lfact,fact,irnf,iptrl,iptru,b,x,w)
! MA50C/CD uses the factorization produced by
!     MA50B/BD to solve A x = b or (A trans) x = b.

  integer m, n, icntl(20), np
  integer(long) :: iq(*)
  logical trans
  integer(long) :: lfact
  real(wp) :: fact(lfact)
  integer(long) irnf(lfact)
  integer(long) :: iptrl(n), iptru(n)
  real(wp) :: b(*), x(*), w(*)
!!!
! integer(long) :: info(15)

! M  is an integer variable set to the number of rows.
!     It is not altered by the subroutine.
! N  is an integer variable set to the number of columns.
!     It is not altered by the subroutine.
! ICNTL must be set by the user as follows and is not altered.
!     ICNTL(1)  must be set to the stream number for error messages.
!       A value less than 1 suppresses output.
!     ICNTL(2) must be set to the stream number for diagnostic output.
!       A value less than 1 suppresses output.
!     ICNTL(3) must be set to control the amount of output:
!       0 None.
!       1 Error messages only.
!       2 Error and warning messages.
!       3 As 2, plus scalar parameters and a few entries of array
!         parameters on entry and exit.
!       4 As 2, plus all parameters on entry and exit.
!     ICNTL(5) must be set to control the level of BLAS used:
!       0 Level 1 BLAS.
!      >0 Level 2 BLAS.
! IQ is an integer array holding the permutation Q.
!     It is not altered by the subroutine.
! NP is an integer variable that must be unchanged since calling
!     MA50B/BD. It holds the number of rows and columns in packed
!     storage. It is not altered by the subroutine.
! TRANS a logical variable thatmust be set to .TRUE. if (A trans)x = b
!     is to be solved and to .FALSE. if A x = b is to be solved.
!     TRANS is not altered by the subroutine.
! LFACT is an integer variable set to the size of FACT and IRNF.
!     It is not altered by the subroutine.
! FACT is an array that must be unchanged since calling MA50B/BD. It
!     holds the packed part of L/U by columns, and the full part of L/U
!     by columns. U has unit diagonal entries, which are not stored, and
!     the signs of the off-diagonal entries are inverted.  In the packed
!     part, the entries of U precede the entries of L; also the diagonal
!     entries of L head each column of L and are reciprocated.
!     FACT is not altered by the subroutine.
! IRNF is an integer array that must be unchanged since calling
!     MA50B/BD. It holds the row numbers of the packed part of L/U, and
!     the row numbers of the full part of L/U.
!     It is not altered by the subroutine.
! IPTRL is an integer array that must be unchanged since calling
!     MA50B/BD. For J = 1,..., NP, IPTRL(J) holds the position in
!     FACT and IRNF of the end of column J of L.
!     For J = NP+1,..., N, IPTRL(J) is equal to IPTRU(J).
!     It is not altered by the subroutine.
! IPTRU is an integer array that must be unchanged since calling
!     MA50B/BD. For J = 1,..., N, IPTRU(J) holds the position in
!     FACT and IRNF of the end of the packed part of column J of U.
!     It is not altered by the subroutine.
! B is an array that must be set to the vector b.
!     It is not altered.
! X is an array that need not be set on entry. On return, it holds the
!    solution x.
! W is a work array of length max(M,N).
! INFO need not be set on entry. On exit, it holds the following:
!    INFO(1) A nonzero value will indicate an error return. Possible
!      nonzero values are:
!      -1  M < 1 or N < 1

  real(wp) :: zero
  parameter (zero=0.0_wp)
  integer(long) :: ii, ia1, if1
  integer :: i, j, mf, mp, nf
  real(wp) :: prod
! I Temporary variable holding row number.
! II Position of the current entry in IRNF.
! IA1 Position of the start of the current row or column.
! IF1 Position of the start of the full part of U.
! J Temporary variable holding column number.
! LP Unit for error messages.
! MF Number of rows held in full format.
! MP Unit for diagnostic messages.
! NF Number of columns held in full format.
! PROD Temporary variable used to accumulate inner products.

!!!
! Now lp is set but never used
! lp = icntl(1)
  mp = icntl(2)
! if (icntl(3)<=0) lp = 0
  if (icntl(3)<=1) mp = 0

! Make some simple checks
!!!
! Can't happen if called from HSL_MA48
! if (m<1 .or. n<1) go to 250

  if (mp>0 .and. icntl(3)>2) write (mp,'(/2(A,I6),A,I4,A,L2)') &
    ' Entering MA50CD with M=', m, ' N =', n, ' NP =', np, ' TRANS =', trans
  if1 = iptrl(n) + 1
  mf = irnf(2)
  nf = n - np
  if (mp>0 .and. icntl(3)>2) write (mp,'(A,I5,A,I5)') &
    ' Size of full submatrix', mf, ' by', nf
  if (mp>0 .and. icntl(3)>3) then
    do 10 j = 1, n
      if (j>1) then
        if (iptrl(j-1)<iptru(j)) write (mp,'(A,I5,A,(T18,3(1P,E12.4,I5)))') &
          ' Column', j, ' of U', (fact(ii),irnf(ii),ii=iptrl(j-1)+1,iptru(j))
      end if
      if (iptru(j)<iptrl(j)) write (mp,'(A,I5,A,(T18,3(1P,E12.4,I5)))') &
        ' Column', j, ' of L', (fact(ii),irnf(ii),ii=iptru(j)+1,iptrl(j))
10  continue
    write (mp,'(A)') ' Full part'
    write (mp,'((6I12))') (irnf(if1+mf+j),j=0,nf-1)
    do 20 i = 0, mf - 1
      write (mp,'(I4,1P,6E12.4:/(4X,1P,6E12.4))') irnf(if1+i), &
        (fact(if1+i+j*mf),j=0,nf-1)
20  continue
  end if

  if (trans) then
    if (mp>0 .and. icntl(3)>3) write (mp,'(A4,5F10.4:/(4X,5F10.4))') ' B =', &
      (b(i),i=1,n)
    if (iq(1)>0) then
      do 30 i = 1, n
        w(i) = b(iq(i))
30    continue
    else
      do 40 i = 1, n
        w(i) = b(i)
40    continue
    end if
    do 50 i = 1, m
      x(i) = zero
50  continue
! Forward substitution through packed part of (U trans).
    do 70 i = 2, n
      prod = zero
      do 60 ii = iptrl(i-1) + 1, iptru(i)
        prod = prod + fact(ii)*w(irnf(ii))
60    continue
      w(i) = w(i) + prod
70  continue
! Backsubstitute through the full part of (PL) trans.
    do 80 i = 1, nf
      x(i) = w(np+i)
80  continue
    if (mf>0 .and. nf>0) then
      call ma50hd(trans,mf,nf,fact(if1),mf,irnf(if1+mf),x,icntl(5))
    else
      do 90 i = 1, mf
        x(i) = zero
90    continue
    end if
    do 100 i = mf, 1, -1
      j = irnf(if1+i-1)
      if (j/=i) x(j) = x(i)
100 continue
! Backsubstitute through the packed part of (PL) trans.
    do 120 i = np, 1, -1
      ia1 = iptru(i) + 1
      if (ia1>iptrl(i)) go to 120
      prod = zero
      do 110 ii = ia1 + 1, iptrl(i)
        prod = prod + fact(ii)*x(irnf(ii))
110   continue
      x(irnf(ia1)) = (w(i)-prod)*fact(ia1)
120 continue
    if (mp>0 .and. icntl(3)>3) write (mp,'(A/(4X,5F10.4))') &
      ' Leaving MA50CD with X =', (x(i),i=1,m)

  else
    if (mp>0 .and. icntl(3)>3) write (mp,'(A4,5F10.4:/(4X,5F10.4))') ' B =', &
      (b(i),i=1,m)
! Forward substitution through the packed part of PL
    do 130 i = 1, m
      w(i) = b(i)
130 continue
    do 150 i = 1, np
      ia1 = iptru(i) + 1
      if (ia1<=iptrl(i)) then
        x(i) = w(irnf(ia1))*fact(ia1)
        if (x(i)/=zero) then
!DIR$ IVDEP
          do 140 ii = ia1 + 1, iptrl(i)
            w(irnf(ii)) = w(irnf(ii)) - fact(ii)*x(i)
140       continue
        end if
      end if
150 continue
! Forward substitution through the full part of PL
    if (mf>0 .and. nf>0) then
      do 160 i = 1, mf
        w(i) = w(irnf(if1+i-1))
160   continue
      call ma50hd(trans,mf,nf,fact(if1),mf,irnf(if1+mf),w,icntl(5))
      do 170 i = 1, nf
        x(np+i) = w(i)
170   continue
    else
      do 180 i = 1, nf
        x(np+i) = zero
180   continue
    end if
! Back substitution through the packed part of U
    do 200 j = n, max(2,np+1), -1
      prod = x(j)
!DIR$ IVDEP
      do 190 ii = iptrl(j-1) + 1, iptru(j)
        x(irnf(ii)) = x(irnf(ii)) + fact(ii)*prod
190   continue
200 continue
    do 220 j = np, 2, -1
      ia1 = iptru(j)
      if (ia1>=iptrl(j)) then
        x(j) = zero
      else
        prod = x(j)
!DIR$ IVDEP
        do 210 ii = iptrl(j-1) + 1, ia1
          x(irnf(ii)) = x(irnf(ii)) + fact(ii)*prod
210     continue
      end if
220 continue
    if (np>=1 .and. iptru(1)>=iptrl(1)) x(1) = zero
    if (iq(1)>0) then
!         Permute X
      do 230 i = 1, n
        w(i) = x(i)
230   continue
      do 240 i = 1, n
        x(iq(i)) = w(i)
240   continue
    end if
    if (mp>0 .and. icntl(3)>3) write (mp,'(A/(4X,5F10.4))') &
      ' Leaving MA50CD with X =', (x(i),i=1,n)
  end if
  return
!!!
! Error condition.  Can only happen if MA50 is called directly.
!250 info(1) = -1
!  if (lp>0) write (lp,'(/A/2(A,I8))') ' **** Error return from MA50CD ****', &
!    ' M =', m, ' N =', n
end subroutine ma50cd

SUBROUTINE ma50dd(a,ind,iptr,n,disp,reals)
! This subroutine performs garbage collection on the arrays A and IND.
! DISP is the position in arrays A/IND immediately after the data
!     to be compressed.
!     On exit, DISP equals the position of the first entry
!     after the compressed part of A/IND.

  integer n
  integer(long) :: disp
  real(wp) :: a(:)
  integer(long) :: iptr(n)
  logical reals
  integer :: ind(:)
! Local variables.
  integer j
  integer(long) :: k, kn
! Set the first entry in each row(column) to the negative of the
!     row(column) and hold the column(row) index in the row(column)
!     pointer.  This enables the start of each row(column) to be
!     recognized in a subsequent scan.
  do 10 j = 1, n
    k = iptr(j)
    if (k>0) then
      iptr(j) = ind(k)
      ind(k) = -j
    end if
10 continue
  kn = 0
! Go through arrays compressing to the front so that there are no
!     zeros held in positions 1 to DISP-1 of IND.
!     Reset first entry of each row(column) and the pointer array IPTR.
  do 20 k = 1, disp - 1
    if (ind(k)==0) go to 20
    kn = kn + 1
    if (reals) a(kn) = a(k)
    if (ind(k)<=0) then
! First entry of row(column) has been located.
      j = -ind(k)
      ind(k) = iptr(j)
      iptr(j) = kn
    end if
    ind(kn) = ind(k)
20 continue
  disp = kn + 1
end subroutine ma50dd


SUBROUTINE ma50ed(m,n,a,lda,pivtol,ipiv,rank)
!*
  integer m, n, rank
  integer :: lda
  real(wp) :: pivtol

  integer(long) ipiv(n)
  real(wp) :: a(lda,n)


!  Purpose
!  =======

!  MA50ED computes an LU factorization of a general m-by-n matrix A.

!  The factorization has the form
!     A = P * L * U * Q
!  where P is a permutation matrix of order m, L is lower triangular
!  of order m with unit diagonal elements, U is upper trapezoidal of
!  order m * n, and Q is a permutation matrix of order n.

!  Row interchanges are used to ensure that the entries of L do not
!  exceed 1 in absolute value. Column interchanges are used to
!  ensure that the first r diagonal entries of U exceed PIVTOL in
!  absolute value. If r < m, the last (m-r) rows of U are zero.

!  This is the Level 1 BLAS version.

!  Arguments
!  =========

!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 1.

!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 1.

!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the m by n matrix to be factored.
!          On exit, the factors L and U from the factorization
!          A = P*L*U*Q; the unit diagonal elements of L are not stored.

!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).

!  PIVTOL  (input) DOUBLE PRECISION
!          The pivot tolerance. Any entry with absolute value less
!          than or equal to PIVTOL is regarded as unsuitable to be a
!          pivot.
!*
!  IPIV    (output) INTEGER array, dimension (N)
!          The permutations; for 1 <= i <= RANK, row i of the
!          matrix was interchanged with row IPIV(i); for
!          RANK + 1 <= j <= N, column j of the
!          matrix was interchanged with column -IPIV(j).

!  RANK    (output) INTEGER
!          The computed rank of the matrix.

!  =====================================================================

  real(wp) :: one, zero
  parameter (one=1.0_wp,zero=0.0_wp)

  integer i, j, jp, k
  logical pivot
! I   Row index.
! J   Current column.
! JP  Pivot position.
! K   Main loop index.
! PIVOT True if there is a pivot in current column.

  integer idamax
  external idamax

!  external daxpy, dscal, dswap
  intrinsic abs


  j = 1
  do 30 k = 1, n

!        Update elements in column J.
    do 10 i = 1, j - 1
      if (m>i) call daxpy(m-i,-a(i,j),a(i+1,i),1,a(i+1,j),1)
10  continue

!        Find pivot.
    if (j<=m) then
      jp = j - 1 + idamax(m-j+1,a(j,j),1)
      ipiv(j) = jp
      pivot = abs(a(jp,j)) > pivtol
    else
      pivot = .false.
    end if
    if (pivot) then

!           Apply row interchange to columns 1:N+J-K.
      if (jp/=j) call dswap(n+j-k,a(j,1),lda,a(jp,1),lda)

!           Compute elements J+1:M of J-th column.
      if (j<m) call dscal(m-j,one/a(j,j),a(j+1,j),1)

!           Update J
      j = j + 1

    else

      do 20 i = j, m
        a(i,j) = zero
20    continue
!           Apply column interchange and record it.
      if (k<n) call dswap(m,a(1,j),1,a(1,n-k+j),1)
      ipiv(n-k+j) = -j

    end if

30 continue

  rank = j - 1

!     End of MA50ED

end subroutine ma50ed


SUBROUTINE ma50fd(m,n,a,lda,pivtol,ipiv,rank)

!  -- This is a variant of the LAPACK routine DGETF2 --

  integer m, n, rank
  integer :: lda
  real(wp) :: pivtol

  integer(long) ipiv(n)
  real(wp) :: a(lda,n)


!  Purpose
!  =======

!  MA50FD computes an LU factorization of a general m-by-n matrix A.

!  The factorization has the form
!     A = P * L * U * Q
!  where P is a permutation matrix of order m, L is lower triangular
!  of order m with unit diagonal elements, U is upper trapezoidal of
!  order m * n, and Q is a permutation matrix of order n.

!  Row interchanges are used to ensure that the entries of L do not
!  exceed 1 in absolute value. Column interchanges are used to
!  ensure that the first r diagonal entries of U exceed PIVTOL in
!  absolute value. If r < m, the last (m-r) rows of U are zero.

!  This is the Level 2 BLAS version.

!  Arguments
!  =========

!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 1.

!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 1.

!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the m by n matrix to be factored.
!          On exit, the factors L and U from the factorization
!          A = P*L*U*Q; the unit diagonal elements of L are not stored.

!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).

!  PIVTOL  (input) DOUBLE PRECISION
!          The pivot tolerance. Any entry with absolute value less
!          than or equal to PIVTOL is regarded as unsuitable to be a
!          pivot.
!*
!  IPIV    (output) INTEGER array, dimension (N)
!          The permutations; for 1 <= i <= RANK, row i of the
!          matrix was interchanged with row IPIV(i); for
!          RANK + 1 <= j <= N, column j of the
!          matrix was interchanged with column -IPIV(j).

!  RANK    (output) INTEGER
!          The computed rank of the matrix.

!  =====================================================================

  real(wp) :: one, zero
  parameter (one=1.0_wp,zero=0.0_wp)

  integer i, j, jp, k
  logical pivot
! I   Row index.
! J   Current column.
! JP  Pivot position.
! K   Main loop index.
! PIVOT True if there is a pivot in current column.

  integer idamax
  external idamax

!  external dgemv, dscal, dswap

  intrinsic abs


  j = 1
  do 20 k = 1, n

    if (j<=m) then
!           Update diagonal and subdiagonal elements in column J.
      call dgemv('No transpose',m-j+1,j-1,-one,a(j,1),lda,a(1,j),1,one,a(j,j), &
        1)
!          Find pivot.
      jp = j - 1 + idamax(m-j+1,a(j,j),1)
      ipiv(j) = jp
      pivot = abs(a(jp,j)) > pivtol
    else
      pivot = .false.
    end if

    if (pivot) then

!           Apply row interchange to columns 1:N+J-K.
      if (jp/=j) call dswap(n+j-k,a(j,1),lda,a(jp,1),lda)

!           Compute elements J+1:M of J-th column.
      if (j<m) call dscal(m-j,one/a(j,j),a(j+1,j),1)

      if (j<n) then
!             Compute block row of U.
        call dgemv('Transpose',j-1,n-j,-one,a(1,j+1),lda,a(j,1),lda,one, &
          a(j,j+1),lda)
      end if

!           Update J
      j = j + 1

    else

      do 10 i = j, m
        a(i,j) = zero
10    continue
!           Apply column interchange and record it.
      if (k<n) call dswap(m,a(1,j),1,a(1,n-k+j),1)
      ipiv(n-k+j) = -j

    end if

20 continue

  rank = j - 1

!     End of MA50FD

end subroutine ma50fd


SUBROUTINE ma50gd(m,n,a,lda,nb,pivtol,ipiv,rank)

!  -- This is a variant of the LAPACK routine DGETRF --

  integer m, n, nb, rank
  integer :: lda
  real(wp) :: pivtol

  integer(long) ipiv(n)
  real(wp) :: a(lda,n)


!  Purpose
!  =======

!  MA50GD computes an LU factorization of a general m-by-n matrix A.

!  The factorization has the form
!     A = P * L * U * Q
!  where P is a permutation matrix of order m, L is lower triangular
!  of order m with unit diagonal elements, U is upper trapezoidal of
!  order m * n, and Q is a permutation matrix of order n.

!  Row interchanges are used to ensure that the entries of L do not
!  exceed 1 in absolute value. Column interchanges are used to
!  ensure that the first r diagonal entries of U exceed PIVTOL in
!  absolute value. If r < m, the last (m-r) rows of U are zero.

!  This is the Level 3 BLAS version.

!  Arguments
!  =========

!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 1.

!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 1.

!  A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the m by n matrix to be factored.
!          On exit, the factors L and U from the factorization
!          A = P*L*U*Q; the unit diagonal elements of L are not stored.

!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,M).

!  NB      (input) INTEGER
!          The block size for BLAS3 processing.

!  PIVTOL  (input) DOUBLE PRECISION
!          The pivot tolerance. Any entry with absolute value less
!          than or equal to PIVTOL is regarded as unsuitable to be a
!          pivot.
!*
!  IPIV    (output) INTEGER array, dimension (N)
!          The permutations; for 1 <= i <= RANK, row i of the
!          matrix was interchanged with row IPIV(i); for
!          RANK + 1 <= j <= N, column j of the
!          matrix was interchanged with column -IPIV(j).

!  RANK    (output) INTEGER
!          The computed rank of the matrix.

!  =====================================================================

  real(wp) :: one, zero
  parameter (one=1.0_wp,zero=0.0_wp)

  integer i, j, jj, jp, j1, j2, k
  logical pivot
  real(wp) :: temp

! I   DO index for applying permutations.
! J   Current column.
! JJ  Column in which swaps occur.
! JP  Pivot position.
! J1  Column at start of current block.
! J2  Column at end of current block.
! K   Main loop index.
! PIVOT True if there is a pivot in current column.
! TEMP Temporary variable for swaps.

!  external dgemm, dgemv, dswap, dscal, dtrsm, dtrsv

  integer idamax
  external idamax

  intrinsic abs, min


  j = 1
  j1 = 1
  j2 = min(n,nb)
  do 70 k = 1, n

    if (j<=m) then

!          Update diagonal and subdiagonal elements in column J.
      call dgemv('No transpose',m-j+1,j-j1,-one,a(j,j1),lda,a(j1,j),1,one, &
        a(j,j),1)

!          Find pivot.
      jp = j - 1 + idamax(m-j+1,a(j,j),1)
      ipiv(j) = jp
      pivot = abs(a(jp,j)) > pivtol
    else
      pivot = .false.
    end if

    if (pivot) then

!           Apply row interchange to columns J1:J2
      if (jp/=j) call dswap(j2-j1+1,a(j,j1),lda,a(jp,j1),lda)

!           Compute elements J+1:M of J-th column.
      if (j<m) call dscal(m-j,one/a(j,j),a(j+1,j),1)

      if (j+1<=j2) then
!             Compute row of U within current block
        call dgemv('Transpose',j-j1,j2-j,-one,a(j1,j+1),lda,a(j,j1),lda,one, &
          a(j,j+1),lda)
      end if

!           Update J
      j = j + 1

    else

      do 10 i = j, m
        a(i,j) = zero
10    continue

!           Record column interchange and revise J2 if necessary
      ipiv(n-k+j) = -j
!           Apply column interchange.
      if (k/=n) call dswap(m,a(1,j),1,a(1,n-k+j),1)
      if (n-k+j>j2) then
!              Apply operations to new column.
        do 20 i = j1, j - 1
          jp = ipiv(i)
          temp = a(i,j)
          a(i,j) = a(jp,j)
          a(jp,j) = temp
20      continue
        if (j>j1) call dtrsv('Lower','No transpose','Unit',j-j1,a(j1,j1),lda, &
          a(j1,j),1)
      else
        j2 = j2 - 1
      end if

    end if

    if (j>j2) then
!           Apply permutations to columns outside the block
      do 40 jj = 1, j1 - 1
        do 30 i = j1, j2
          jp = ipiv(i)
          temp = a(i,jj)
          a(i,jj) = a(jp,jj)
          a(jp,jj) = temp
30      continue
40    continue
      do 60 jj = j2 + 1, n - k + j - 1
        do 50 i = j1, j2
          jp = ipiv(i)
          temp = a(i,jj)
          a(i,jj) = a(jp,jj)
          a(jp,jj) = temp
50      continue
60    continue

      if (k/=n) then
!              Update the Schur complement
        call dtrsm('Left','Lower','No transpose','Unit',j2-j1+1,n-k,one, &
          a(j1,j1),lda,a(j1,j2+1),lda)
        if (m>j2) call dgemm('No transpose','No transpose',m-j2,n-k,j2-j1+1, &
          -one,a(j2+1,j1),lda,a(j1,j2+1),lda,one,a(j2+1,j2+1),lda)
      end if

      j1 = j2 + 1
      j2 = min(j2+nb,n-k+j-1)

    end if


70 continue
  rank = j - 1

!     End of MA50GD

end subroutine ma50gd

SUBROUTINE ma50hd(trans,m,n,a,lda,ipiv,b,icntl5)

!  -- This is a variant of the LAPACK routine DGETRS --
!     It handles the singular or rectangular case.

  logical trans
  integer m, n, icntl5
  integer :: lda
  integer(long) ipiv(n)
  real(wp) :: a(lda,n), b(*)


!  Purpose
!  =======

!  Solve a system of linear equations
!     A * X = B  or  A' * X = B
!  with a general m by n matrix A using the LU factorization computed
!  by MA50ED, MA50FD, or MA50GD.

!  Arguments
!  =========

!  TRANS   (input) LOGICAL
!          Specifies the form of the system of equations.
!          = .FALSE. :  A * X = B  (No transpose)
!          = .TRUE.  :  A'* X = B  (Transpose)

!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 1.

!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 1.

!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          The factors L and U from the factorization A = P*L*U
!          as computed by MA50GD.

!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= max(1,N).

!  IPIV    (input) INTEGER array, dimension (N)
!          The permutations; for 1 <= i <= RANK, row i of the
!          matrix was interchanged with row IPIV(i); for
!          RANK + 1 <= j <= N, column j of the
!          matrix was interchanged with column -IPIV(j).

!  B       (input/output) DOUBLE PRECISION array, size max(M,N)
!          On entry, the right hand side vectors B for the system of
!          linear equations.
!          On exit, the solution vectors, X.

!  ICNTL5  (input) INTEGER
!          0 for BLAS1 or >0 for BLAS2

!  =====================================================================

  integer i, k, rank
! I    Temporary variable.
! K    Temporary variable.
! RANK Rank of matrix.

  real(wp) :: zero
  parameter (zero=0.0_wp)
  real(wp) :: temp
  intrinsic min
!  external daxpy, ddot, dtrsv
  real(wp) :: ddot

!   Find the rank
  rank = 0
  do 10 rank = min(m,n), 1, -1
    if (ipiv(rank)>0) go to 20
10 continue

20 if ( .not. trans) then

!        Solve A * X = B.

!        Apply row interchanges to the right hand side.
    do 30 i = 1, rank
      k = ipiv(i)
      temp = b(i)
      b(i) = b(k)
      b(k) = temp
30  continue

!        Solve L*X = B, overwriting B with X.
    if (icntl5>0) then
      if (rank>0) call dtrsv('L','NoTrans','Unit',rank,a,lda,b,1)
    else
      do 40 k = 1, rank - 1
        if (b(k)/=zero) call daxpy(rank-k,-b(k),a(k+1,k),1,b(k+1),1)
40    continue
    end if

!        Solve U*X = B, overwriting B with X.
    if (icntl5>0) then
      if (rank>0) call dtrsv('U','NoTrans','NonUnit',rank,a,lda,b,1)
    else
      do 50 k = rank, 2, -1
        if (b(k)/=zero) then
          b(k) = b(k)/a(k,k)
          call daxpy(k-1,-b(k),a(1,k),1,b(1),1)
        end if
50    continue
      if (rank>0) b(1) = b(1)/a(1,1)
    end if

!        Set singular part to zero
    do 60 k = rank + 1, n
      b(k) = zero
60  continue

!        Apply column interchanges to the right hand side.
    do 70 i = rank + 1, n
      k = -ipiv(i)
      temp = b(i)
      b(i) = b(k)
      b(k) = temp
70  continue

  else

!        Solve A' * X = B.

!        Apply column interchanges to the right hand side.
    do 80 i = n, rank + 1, -1
      k = -ipiv(i)
      temp = b(i)
      b(i) = b(k)
      b(k) = temp
80  continue

!        Solve U'*X = B, overwriting B with X.

    if (icntl5>0) then
      if (rank>0) call dtrsv('U','Trans','NonUnit',rank,a,lda,b,1)
    else
      if (rank>0) b(1) = b(1)/a(1,1)
      do 90 i = 2, rank
        temp = b(i) - ddot(i-1,a(1,i),1,b(1),1)
        b(i) = temp/a(i,i)
90    continue
    end if

!        Solve L'*X = B, overwriting B with X.
    if (icntl5>0) then
      if (rank>0) call dtrsv('L','Trans','Unit',rank,a,lda,b,1)
    else
      do 100 i = rank - 1, 1, -1
        b(i) = b(i) - ddot(rank-i,a(i+1,i),1,b(i+1),1)
100   continue
    end if

!        Set singular part to zero
    do 110 i = rank + 1, m
      b(i) = zero
110 continue

!        Apply row interchanges to the solution vectors.
    do 120 i = rank, 1, -1
      k = ipiv(i)
      temp = b(i)
      b(i) = b(k)
      b(k) = temp
120 continue
  end if

end subroutine ma50hd

SUBROUTINE ma50id(cntl,icntl)
! Set default values for the control arrays.

  real(wp) :: cntl(10)
  integer i, icntl(20)

  cntl(1) = 0.5_wp
  cntl(2) = 0.1_wp
  do 10 i = 3, 10
    cntl(i) = 0.0_wp
10 continue

  icntl(1) = 6
  icntl(2) = 6
  icntl(3) = 1
  icntl(4) = 3
  icntl(5) = 32
  do 20 i = 6, 20
    icntl(i) = 0
20 continue

end subroutine ma50id

end module hsl_ma48_ma50_internal_double

module hsl_ma48_ma48_internal_double
   use hsl_ma48_ma50_internal_double
   implicit none

! This module is based on ma48 2.1.0 (13th March 2007)
! 3 August 2010 Version 3.0.0.  Radical change to include some 
!      INTEGER*64 integers (so that restriction on number of entries is
!      relaxed.  Also use of HSL_ZB01 to allow restarting with more
!      space allocated.

   private
   public :: ma48ad, ma48bd, ma48cd
   public :: ma48id ! public for unit tests

   integer, parameter :: wp = kind(0.0d0)
   integer, parameter :: long = selected_int_kind(18) ! Long integer
   integer(long), parameter :: onel = 1
   integer :: stat

contains

    SUBROUTINE ma48ad(m,n,ne,job,la,a,irn,jcn,keep,cntl,icntl,info,rinfo, &
                      endcol)
! Given a sparse matrix, find its block upper triangular form, choose a
!     pivot sequence for each diagonal block, and prepare data
!     structures for actual factorization.

!     .. Arguments ..
      INTEGER m, n, job
      integer(long) :: ne, la
      real(wp) :: a(2*ne)
      real(wp), allocatable :: fact(:)
      INTEGER, allocatable ::  ifact(:), jfact(:)
      INTEGER(long) ::  irn(2*ne), jcn(ne)
      integer(long) :: keep(*)
      DOUBLE PRECISION cntl(10)
      DOUBLE PRECISION rinfo(10)
      integer, intent(in), optional :: endcol(n)
      INTEGER icntl(20)
      integer(long) :: info(20)
      integer, allocatable :: iw(:)
      real(wp) :: multiplier


! M must be set by the user to the number of rows.
!      It is not altered by the subroutine.  Restriction:  M > 0.
! N must be set by the user to the number of columns.
!      It is not altered by the subroutine.  Restriction:  N > 0.
! NE must be set by the user to the number of entries in the input
!      matrix. It is not altered by the subroutine. Restriction: NE > 0.
! JOB must be set by the user to 1 for automatic choice of pivots and
!      to 2 if the pivot sequence is specified in KEEP.  If JOB is set
!      to 3, then pivots are chosen automatically from the diagonal as
!      long as this is numerically feasible.
!      It is not altered by the subroutine.  Restriction: 1 <= JOB <= 3.
! LA must be set by the user to the size of A, IRN, and JCN.
!      It is not altered by the subroutine. Restriction LA >= 2*NE.
!      Normally a value of 3*NE will suffice.
! A must have its first NE elements set by the user to hold the matrix
!      entries. They may be in any order. If there is more than one for
!      a particular matrix position, they are accumulated. The first
!      NE entries are not altered by the subroutine. The rest is used
!      as workspace for the active submatrix.
! IRN  is an integer array. Entries 1 to NE must be set to the
!      row indices of the corresponding entries in A.  On return, the
!      leading part holds the row numbers of the permuted matrix, with
!      duplicates excluded. The permuted matrix is block upper
!      triangular with recommended pivots on its diagonal. The entries
!      of the block diagonal part are held contiguously from IRN(1)
!      and the entries of the off-diagonal part are held contiguously
!      backwards from IRN(NE) during the computation.  At the end the
!      off-diagonal blocks are held contiguously immediately after the
!      diagonal blocks.
! JCN  is an integer array. Entries 1 to NE must be set to the column
!      indices of the corresponding entries in A. On return, JCN(k)
!      holds the position in IRN that corresponds to the entry that was
!      input in A(k), k=1,NE.  Entries corresponding to out-of-range
!      indices are first set to 0 then, before exit, to NE+1.
!      If duplicates are found, the first entry of JCN is negated.
! KEEP is an integer array that need not be set on a JOB=1 or JOB=3
!      entry. On entry with JOB=2 and always
!      on a successful exit, KEEP(i) holds the position of row i in the
!      permuted matrix, I=1,M and KEEP(M+j) holds the index of the
!      column that is in position j of the permuted matrix, j=1,N.
!      The rest of the array need not be set on entry. On exit:
!        KEEP(IPTRD+j), IPTRD=M+3*N, holds the position in IRN of the
!          start of the block diagonal part of column j, J=1,N;
!        KEEP(IPTRD+N+1) holds the position that immediately follows
!          the end of the block diagonal part of column N;
!        KEEP(IPTRO+j),IPTRO=IPTRD+N+1, holds the position in IRN of
!          the start of the block off-diagonal part of column j, j=1,N;
!        KEEP(IPTRO+N+1) holds the position that immediately
!          follows the end of the block off-diagonal part of column N;
!          During the computation, the columns of the off-diagonal
!          blocks are held in reverse order and KEEP(IPTRO+N+1) points
!          to the position immediately before the off-diagonal block
!          storage.
!        KEEP(KBLOCK+3), KBLOCK=IPTRO+N+1, holds the number of
!          blocks NB in the block triangular form;
!        KEEP(NBLOCK+3*k), NBLOCK=IPTRO+N-1, holds the number of columns
!          in block k, k=1,NB; and
!        KEEP(MBLOCK+3*k), MBLOCK=IPTRO+N, is negative if block k
!          is triangular or holds the number of rows held in packed
!          storage when processing block k, k=1,NB.
!        KEEP(LBLOCK+k), LBLOCK=KBLOCK+3*NB is accessed only if ICNTL(8)
!          is not equal to 0 and will be set to the number of columns
!          in block k which are to be pivoted on last, k=1,NB.
! CNTL  is a real array of length 10 that must be set by the user
!       as follows and is not altered.
!     CNTL(1)  If this is set to a value less than or equal to one, full
!       matrix processing will be used by MA50A/AD when the density of
!       the reduced matrix reaches CNTL(1).
!     CNTL(2) determines the balance used by MA50A/AD and MA50B/BD
!       between pivoting for sparsity and for stability, values near
!       zero emphasizing sparsity and values near one emphasizing
!       stability.
!     CNTL(3) If this is set to a positive value, any entry whose
!       modulus is less than CNTL(3) will be dropped from the factors
!       calculated by MA50A/AD. The factorization will then require
!       less storage but will be inaccurate.
!     CNTL(4)  If this is set to a positive value, any entry whose
!       modulus is less than CNTL(4) will be regarded as zero from
!       the point of view of rank.
!     CNTL(5:10) are not accessed by this subroutine.
! ICNTL is an integer array of length 20 that must be set by the user
!       as follows and is not altered.
!     ICNTL(1)  must be set to the stream number for error messages.
!       A value less than 1 suppresses output.
!     ICNTL(2) must be set to the stream number for diagnostic output.
!       A value less than 1 suppresses output.
!     ICNTL(3) must be set to control the amount of output:
!       0 None.
!       1 Error messages only.
!       2 Error and warning messages.
!       3 As 2, plus scalar parameters and a few entries of array
!         parameters on entry and exit.
!       4 As 2, plus all parameters on entry and exit.
!     ICNTL(4)  If set to a positive value, the pivot search by MA50A/AD
!       is limited to ICNTL(4) columns. This may result in different
!       fill-in and execution time but could give faster execution.
!     ICNTL(5) The block size to be used for full-matrix processing.
!     ICNTL(6) is the minimum size for a block of the block triangular
!       form.
!     ICNTL(7) If not equal to 0, abort when structurally rank deficient
!       matrix found.
!     ICNTL(8) If set to a value other than zero and JOB = 1 or 3,
!       columns with IW flagged 0 are placed at
!       the end of their respective blocks in the first factorization
!       and the remaining columns are assumed unchanged in subsequent
!       factorizations. If set to a value other than zero and JOB = 2,
!       columns before the first 0 entry of IW are assumed unchanged in
!       subsequent factorizations.
!     ICNTL(9:20) are not accessed by this subroutine.
! INFO is an integer array of length 20 that need not be set on entry.
!   INFO(1)  On exit, a negative value  will indicate an error return
!      and a positive value will indicate a warning.
!      Possible nonzero values are:
!      -1  M < 1 or N < 1
!      -2  NE < 1
!      -3  Insufficient space
!      -4  ICNTL(7) not equal to 0 and the matrix is structurally rank
!          deficient.
!      -5  Faulty permutation input on JOB = 2 entry
!      -6  JOB out of range
!     -10  Failure in allocation
!      +1  Row or column number out of range (such entries are ignored)
!          and/or more than one entry for the same matrix position.
!      +2  Matrix rank deficient.  Estimated rank in INFO(5).
!          more than one entry for the same matrix position
!      +3  Combination of warnings +1 and +2.
!      +4  Premature switch to full code because of problems in choosing
!          diagonal pivots (JOB = 3 entry).
!      +5  Combination of warnings +1 and +4.
!      +6  Combination of warnings +2 and +4.
!      +7  Combination of warnings +1, +2 and +4.
!    INFO(2) Number of compresses of the files.
!    INFO(3) Minimum storage required to analyse matrix.
!    INFO(4) Minimum storage required to factorize matrix.
!    INFO(5) Upper bound on the rank of the matrix.
!    INFO(6) Number of entries dropped from the data structure.
!    INFO(7) Order of the largest nontriangular block on the diagonal
!            of the block triangular form.
!    INFO(8) Total of the orders of all the nontriangular blocks on the
!            diagonal of the block triangular form.
!    INFO(9) Total no. of entries in all the nontriangular blocks on
!            the diagonal of the block triangular form.
!    INFO(10) Structural rank.
!    INFO(11) Number of multiple entries in the input data.
!    INFO(12) Number of entries with out-of-range indices.
! RINFO is a real array that need not be set on entry. On exit,
!    RINFO(1) holds the number of floating-point operations needed for
!      the factorization.
! ENDCOL is an optional integer array of length N.
!      If ICNTL(8) is not 0, the ENDCOL must be set on entry so that
!      ENDCOL(i), i=1,N is zero for and only for the columns
!      designated to be at the end of the pivot sequence.

!     .. Local constants ..
      DOUBLE PRECISION zero
      PARAMETER (zero=0.0_wp)

!     .. Local variables ..
      DOUBLE PRECISION cntl5(10)
! These variables are integer because of calls to subroutines
      integer icntl5(20), nb, nc, nr, np, ndiag
      integer(long) :: info5(15)
      integer(long) :: eye, headc, i, ib, idummy, ips, &
        iptrd, iptro, isw, j, jay, jb, jfirst, &
        j1, j2, j3, k, kb, kblock, kd, kk, kl, ko, l, lastr, lastc, lblock
      integer(long), allocatable :: iptra(:),iptrp(:),ip(:),iq(:)
      integer, allocatable :: lastcol(:),lencol(:)
      LOGICAL ldup
      INTEGER lenc, lenp, lenr, lp, mblock, minblk, mp, nblock, &
        nextc, nextr, nxteye, ptrd, ptro
      integer(long) :: nza, nzb, nzd, ljfact
      DOUBLE PRECISION rinfo5(10), tol
! CNTL5 passed to MA50A/AD to correspond to dummy argument CNTL.
! EYE   position in arrays.
! HEADC displacement in IW. IW(HEADC+J) holds the position in A of the
!       head of the chain of entries for column J.
! I     row index.
! IB    displacement in IW. IW(IB+K) first holds the index in the
!       permuted matrix of the first column of the k-th block. Later
!       abs(IW(IB+K)) holds the number of columns in block K and is
!       negative for a triangular block.
! ICNTL5 passed to MA50A/AD to correspond to dummy argument ICNTL.
! IDUMMY do loop index not used within the loop.
! INFO5 passed to MA50A/AD to correspond to dummy argument INFO.
! IP    displacement in IW. IW(IP+I), I=1,M holds a row permutation.
! IPTRA displacement in IW. IW(IPTRA+J) holds the position in the
!       reordered matrix of the first entry of column J.
! IPTRD displacement in KEEP. See comment on KEEP.
! IPTRO displacement in KEEP. See comment on KEEP.
! IPTRP displacement in IW. IW(IP+I), I=1,N holds the column starts
!       of a permutation of the matrix, during the block triangular
!       calculation.
! IQ    displacement in IW. IW(IQ+J), J=1,N holds a column permutation.
! ISW   used for swopping two integers
! IW   is an integer array of length 6*M+3*N that is used as workspace.
! IW13  displacement in IW. IW(IW13+1) is the first entry of the
!       workarray IW of MC13DD.
! IW21  displacement in KEEP. KEEP(IW21+1) is the first entry of the
!       workarray IW of MC21AD.
! IW50  displacement in IW. IW(IW50+1) is the first entry of the
!       workarray IW of MA50A/AD.
! J     column index.
! JAY   column index.
! JB    block index.
! JFIRST displacement in IW. IW(JFIRST+1) is the first entry of the
!       workarray JFIRST of MA50A/AD.
! J1    first column index of a block.
! J2    last column index of a block.
! J3    last column index of a block ... used in printing
! K     running index for position in matrix.
! KB    block index.
! KBLOCK displacement in KEEP. See comment on KEEP.
! KD    running index for position in matrix.
! KK    running index for position in matrix.
! KL    last position in matrix of current column.
! KO    running index for position in matrix.
! L     length of a block.
! LBLOCK displacement in KEEP. See comment on KEEP.
! LASTR displacement in IW. IW(LASTR+I) holds the position of the last
!       entry encountered in row I.  Used for accumulating duplicates.
! LASTC displacement in IW. IW(LASTC+I) holds the index of the
!       last column encountered that had an entry in row I.
!       LASTC is also used to get workspace in KEEP for MA50AD.
! LDUP  logical flag used to indicate whether duplicates have been
!       found and recorded.
! LENC  displacement in IW. IW(LENC+J) holds the number of entries
!       in column J, excluding duplicates.
!       LENC is also used to get workspace in KEEP for MA50AD.
! LENP  displacement in IW. IW(LENP+J) holds the number of entries
!       in column J of the permuted matrix.
! LENR  displacement in IW. IW(LENR+1) is the first entry of the
!       workarray LENR of MA50A/AD.
! LP Unit for error messages.
! MBLOCK displacement in KEEP. See comment on KEEP.
! MINBLK Minimum size for a block.
! MP Unit for diagnostic messages.
! NB Number of blocks.
! NBLOCK displacement in KEEP. See comment on KEEP.
! NC Number of columns in block.
! NDIAG number entries placed on diagonal by MC21AD.
! NEXTC displacement in IW. IW(NEXTC+1) is the first entry of the
!       workarray NEXTC of MA50A/AD.
! NEXTR displacement in IW. IW(NEXTR+1) is the first entry of the
!       workarray NEXTR of MA50A/AD.
! NP Number of columns in packed storage.
! NR Number of rows in block.
! NXTEYE Next value of EYE.
! NZA   number of entries in the matrix, excluding duplicates.
! NZB   number of entries in the current diagonal block.
! NZD   total number of entries in the diagonal blocks.
! PTRD  displacement in IW. IW(PTRD+J) holds the position of the
!       first entry of the diagonal part of column J.
! PTRO  displacement in IW. IW(PTRO+J) holds the position of the
!       first entry of the off-diagonal part of column J.
! RINFO5 passed to MA50A/AD to correspond to dummy argument RINFO.
! TOL   pivot tolerance.  Entries less than this value are considered
!       as zero.

! MC13DD    finds permutation for block triangular form
! MC21AD    finds permutation for zero-free diagonal
! MA50A/AD factorizes non-triangular diagonal blocks
      INTRINSIC abs, max

      multiplier = cntl(6)

      allocate(iptra(n),iptrp(n),iq(n),ip(m),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        return
      endif
! The +1 because pointers point to first free position but array used
! from next position?
      allocate(iw(4*max(m,n)+2*n+1),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        deallocate(iptra,iptrp,iq,ip,stat=stat)
        return
      endif

! Assign data for columns to be operated on at end
      if (present(endcol)) iw(1:n) = endcol(1:n)
! Allocate storage for the factorization of the blocks
      ljfact = max(la/2,2*ne)
      allocate(fact(la),ifact(la),jfact(ljfact),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        deallocate(iptra,iptrp,iq,ip,iw,stat=stat)
        return
      endif

! Initializations
      DO 53 i = 1, 20
        info(i) = 0
53    CONTINUE
      info(3) = ne*2
      info(14) = ne*2
      info(4) = ne
      info(10) = min(m,n)
      DO 56 i = 1, 5
        rinfo(i) = zero
56    CONTINUE
      DO 60 i = 1, 4
        cntl5(i) = cntl(i)
        icntl5(i) = icntl(i)
60    CONTINUE
! Switch off printing from MA50A/AD
      icntl5(3) = 0
! Set BLAS control
      icntl5(5) = icntl(5)
! Default control for restricted pivoting
      icntl5(6) = 0
! Set controls if pivot sequence provided
      icntl5(7) = 0
      IF (job==2) THEN
        icntl5(7) = 2
        icntl5(4) = 1
      END IF
! Set control for diagonal pivoting
      IF (job==3) icntl5(7) = 1

! Set pivot tolerance
      tol = max(zero,cntl(4))
! Set blcok size for BTF
      minblk = max(1,icntl(6))
! Set flag for scan for duplicates
      ldup = .FALSE.

! Simple data checks (some removed because done by hsl_ma48)
! These are executed by test deck but will not be executed by hsl_ma48
! Set printer streams
      lp = icntl(1)
      mp = icntl(2)
      IF (ne<=0) THEN
        info(1) = -2
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9110) ne
        GO TO 530
      END IF
      IF (la<2*ne) THEN
        info(1) = -3
        info(3) = 2*ne
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9120) la, info(3)
        GO TO 530
      END IF
      IF (job<1 .OR. job>3) THEN
        info(1) = -6
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9130) job
        GO TO 530
      END IF
! Check input permutations
      IF (job==2) THEN
        DO 10 i = 1, max(m,n)
          iw(n+i) = 0
10      CONTINUE
! Check row permutation
        DO 20 i = 1, m
          j = keep(i)
          IF (j<1 .OR. j>m) GO TO 40
          IF (iw(n+j)==1) GO TO 40
          iw(n+j) = 1
20      CONTINUE
! Check column permutation
        DO 30 i = 1, n
          j = keep(m+i)
          IF (j<1 .OR. j>n) GO TO 40
          IF (iw(n+j)==2) GO TO 40
          iw(n+j) = 2
30      CONTINUE
        GO TO 50
40      info(1) = -5
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9140)
        GO TO 530
      END IF

50    IF (mp>0 .AND. icntl(3)>2) THEN
        WRITE (mp,'(/A/A,I7,A,I6,A,I7,A,I2,A,I7/A,1P,4D12.4/A,4I8/A,3I8)') &
          ' Entering MA48A/AD with', ' M =', m, '     N =', n, '     NE =', &
          ne, '     JOB =', job, '     LA =', la, ' CNTL (1:4) =', &
          (cntl(i),i=1,4), ' ICNTL(1:4) = ', (icntl(i),i=1,4), &
          ' ICNTL(6:8) = ', (icntl(i),i=6,8)
        IF (icntl(3)>3) THEN
          WRITE (mp,9000) (a(k),irn(k),jcn(k),k=1,ne)
9000      FORMAT (' Entries:'/3(1P,D12.4,2I6))
        ELSE
          WRITE (mp,9000) (a(k),irn(k),jcn(k),k=1,min(onel*9,ne))
        END IF
        IF (job==2) THEN
          WRITE (mp,'(A)') ' Permutations input (JOB=2)'
          IF (icntl(3)>3) THEN
            WRITE (mp,9010) (keep(i),i=1,m)
9010        FORMAT (' Positions of original rows in the permuted ma', &
              'trix'/(10I6))
            WRITE (mp,9020) (keep(m+i),i=1,n)
9020        FORMAT (' Positions of columns of permuted matrix ','in',' or', &
              'iginal matrix '/(10I6))
          ELSE
            WRITE (mp,9010) (keep(i),i=1,min(10,m))
            WRITE (mp,9020) (keep(m+i),i=1,min(10,n))
          END IF
        END IF
        IF (icntl(8)/=0) THEN
          WRITE (mp,'(A,I6)') ' Value of IW entries on call with ICNTL(8) =', &
            icntl(8)
          IF (icntl(3)>3) THEN
            WRITE (mp,9030) (iw(i),i=1,n)
9030        FORMAT (10I6)
          ELSE
            WRITE (mp,9030) (iw(i),i=1,min(10,n))
          END IF
        END IF
      END IF


! Partition KEEP
      iptrd = m + 3*n
      iptro = iptrd + n + 1
      nblock = iptro + n - 1
      mblock = nblock + 1
      kblock = mblock + 1

! Partition IW
! We assume at this point that there might be data in IW(1:N)
      headc = n + 1
      lastc = headc + n

! Initialize header array for column links.
      DO 70 j = 1, n
        iw(headc+j) = 0
70    CONTINUE
! Overwrite JCN by column links, checking that rows and column numbers
!     are within range.
      DO 80 k = 1, ne
        i = irn(k)
        j = jcn(k)
        IF (i<1 .OR. i>m .OR. j<1 .OR. j>n) THEN
          info(12) = info(12) + 1
          IF (mp>0 .AND. info(12)<=10 .AND. icntl(3)>=2) WRITE (mp, &
            '(A,I7,A,2I6)') ' Message from MA48A/AD .. indices for entry ', k, &
            ' are', i, j
          jcn(k) = 0
        ELSE
          jcn(k) = iw(headc+j)
          iw(headc+j) = k
        END IF
80    CONTINUE


      IF (minblk>=n .OR. m/=n .OR. job>1) GO TO 190

! Obtain permutations to put matrix in block triangular form.

! Note that in this part of the code we know that M is equal to N.

! Partition IW for arrays used by MC21AD and MC13DD
      lenc = lastc + n
      ib = lenc
      ips = lenc + n
      lenp = ips + n

! Initialize array LASTC
      DO 90 i = 1, n
        iw(lastc+i) = 0
90    CONTINUE

! Run through the columns removing duplicates and generating copy of
!     structure by columns.
      ldup = .TRUE.
      k = 1
      DO 120 j = 1, n
        eye = iw(headc+j)
        iptra(j) = k
        DO 100 idummy = 1, ne
          IF (eye==0) GO TO 110
          i = irn(eye)
! Check for duplicates
          IF (iw(lastc+i)/=j) THEN
            iw(lastc+i) = j
            irn(ne+k) = i
            k = k + 1
          ELSE
! Record duplicate
            info(11) = info(11) + 1
            IF (mp>0 .AND. info(11)<=10 .AND. icntl(3)>=2) WRITE (mp, &
              '(A,I7,A,2I6)') &
              ' Message from MA48A/AD .. duplicate in position ', k, &
              ' with indices', i, j
          END IF
          eye = jcn(eye)
100     CONTINUE
110     iw(lenc+j) = k - iptra(j)
120   CONTINUE

! NZA is number of entries with duplicates and out-of-range indices
!     removed.
      nza = k - 1

!   Compute permutation for zero-free diagonal
      CALL mc21ad(n,irn(ne+1),nza,iptra,iw(lenc+1),iw(ips+1),ndiag,info)
      if (info(1) .eq. -10) go to 530
! IW(IP+1) ... col permutation ... new.to.old
      info(10) = ndiag
      IF (ndiag<n) THEN
        IF (icntl(7)/=0) THEN
          info(1) = -4
          IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,'(A,A/A,I7,A,I7)') &
            ' Error return from MA48A/AD because matrix structurally ', &
            ' singular', ' order is ', n, ' and structural rank', ndiag
          GO TO 530
        END IF
        GO TO 190
      END IF
! Set pointers and column counts for permuted matrix
!DIR$ IVDEP
      DO 130 j = 1, n
        jay = iw(ips+j)
        iptrp(j) = iptra(jay)
        iw(lenp+j) = iw(lenc+jay)
130   CONTINUE

! Use Tarjan's algorithm to obtain permutation to block triangular form.
! KEEP(M+1) .. col permutation ...new.to.old
      CALL mc13dd(n,irn(ne+1),nza,iptrp,iw(lenp+1),keep(m+1),iw(ib+1),nb,info)
      if (info(1) .eq. -10) go to 530
! IW(IB+1) ... col number in permuted matrix of start of blocks

! Merge adjacent 1x1 blocks into triangular blocks
! Change block pointers to block sizes
      DO 140 jb = 2, nb
        iw(ib+jb-1) = iw(ib+jb) - iw(ib+jb-1)
140   CONTINUE
      iw(ib+nb) = n + 1 - iw(ib+nb)
      IF (iw(ib+1)==1) iw(ib+1) = -1
      kb = 1
      DO 150 jb = 2, nb
        l = iw(ib+jb)
        IF (l==1 .AND. iw(ib+kb)<=0) THEN
          iw(ib+kb) = iw(ib+kb) - 1
        ELSE
          kb = kb + 1
          IF (l==1) THEN
            iw(ib+kb) = -1
          ELSE
            iw(ib+kb) = l
          END IF
        END IF
150   CONTINUE
      nb = kb
! Merge small blocks
      kb = 1
      DO 160 jb = 2, nb
        IF (abs(iw(ib+kb))<minblk) THEN
          iw(ib+kb) = abs(iw(ib+kb)) + abs(iw(ib+jb))
        ELSE
          kb = kb + 1
          iw(ib+kb) = iw(ib+jb)
        END IF
160   CONTINUE
      nb = kb
! Set size of blocks and triangular block flags
      DO 170 jb = 1, nb
        keep(nblock+3*jb) = abs(iw(ib+jb))
        keep(mblock+3*jb) = iw(ib+jb)
170   CONTINUE
! Record permutations.
! Set KEEP to position of column that is in position j of permuted
!     matrix .... new.to.old
      DO 180 j = 1, n
        keep(keep(m+j)) = j
        keep(m+j) = iw(ips+keep(m+j))
180   CONTINUE
      GO TO 220

! Set arrays for the case where block triangular form is not computed
190   nb = 1
      IF (job==1 .OR. job==3) THEN
        DO 200 i = 1, m
          keep(i) = i
200     CONTINUE
        DO 210 i = 1, n
          keep(m+i) = i
210     CONTINUE
      END IF
! Set number of columns in block
      keep(nblock+3) = n
      keep(mblock+3) = 0

! Control for forcing columns to end.
220   IF (icntl(8)/=0) THEN
        lblock = kblock + 3*nb
        IF (job==2) THEN
! Find first column that will be changed in subsequent factorizations.
          DO 230 i = 1, n
            IF (iw(i)==0) GO TO 240
230       CONTINUE
! Set LBLOCK to number of columns from and including first one flagged
240       keep(lblock+1) = n - i + 1
        ELSE
! Within each block move columns to the end
          j = 1
          DO 270 jb = 1, nb
            keep(lblock+jb) = 0
            j2 = j + keep(nblock+3*jb) - 1
            j1 = j2
! Jump if triangular block (leave columns in situ)
            IF (keep(mblock+3*jb)<0) GO TO 260
! Run through columns in block sorting those with IW flag to end
250         IF (j==j2) GO TO 260
            IF (iw(keep(m+j))==0) THEN
! Column is put at end
              keep(lblock+jb) = keep(lblock+jb) + 1
              isw = keep(m+j2)
              keep(m+j2) = keep(m+j)
              keep(m+j) = isw
              j2 = j2 - 1
            ELSE
              j = j + 1
            END IF
            GO TO 250
260         j = j1 + 1
270       CONTINUE
        END IF
      END IF

! Run through the columns to create block-ordered form, removing
!     duplicates, changing row indices, and holding map array in JCN.
! Grab space in IW for LASTR
      lastr = lastc + m
! Initialize LASTC
      DO 280 i = 1, m
        iw(lastc+i) = 0
280   CONTINUE
      keep(kblock+3) = nb
      k = 1
      kk = ne
      j2 = 0
      DO 310 jb = 1, nb
        j1 = j2 + 1
        j2 = j1 + keep(nblock+3*jb) - 1
! Run through columns in block JB
! LASTR is used for accumulation of duplicates
! LASTC is used to identify duplicates
        DO 300 jay = j1, j2
          j = keep(m+jay)
          eye = iw(headc+j)
          keep(iptrd+jay) = k
          keep(iptro+jay) = kk
          IF (keep(mblock+3*jb)<0) THEN
! Block is triangular.
! Reserve the leading position for the diagonal entry
            iw(lastc+jay) = jay
            a(ne+k) = zero
            irn(ne+k) = jay
            iw(lastr+jay) = k
            k = k + 1
          END IF
          DO 290 idummy = 1, ne
            IF (eye==0) GO TO 300
            nxteye = jcn(eye)
            i = keep(irn(eye))
            IF (iw(lastc+i)/=jay) THEN
! Entry encountered for the first time.
              iw(lastc+i) = jay
              IF ((i>=j1 .AND. i<=j2) .OR. (m/=n)) THEN
! Entry in diagonal block.
                a(ne+k) = a(eye)
                irn(ne+k) = i
                iw(lastr+i) = k
                jcn(eye) = k
                k = k + 1
              ELSE
! Entry in off-diagonal block.
                a(ne+kk) = a(eye)
                irn(ne+kk) = i
                iw(lastr+i) = kk
                jcn(eye) = kk
                kk = kk - 1
              END IF
            ELSE
! Entry has already been encountered.
              IF ( .NOT. ldup) THEN
! Duplicates should be counted here if they were not earlier
                info(11) = info(11) + 1
                IF (mp>0 .AND. info(11)<=10 .AND. icntl(3)>=2) WRITE (mp, &
                  '(A,I7,A,2I6)') &
                  ' Message from MA48A/AD .. duplicate in position ', eye, &
                  ' with indices', irn(eye), j
              END IF
              kl = iw(lastr+i)
              jcn(eye) = kl
              a(ne+kl) = a(ne+kl) + a(eye)
            END IF
            eye = nxteye
290       CONTINUE
300     CONTINUE
310   CONTINUE
      keep(iptrd+n+1) = k
      keep(iptro+n+1) = kk
      nzd = k - 1
      DO 320 i = 1, k - 1
        irn(i) = irn(ne+i)
320   CONTINUE
      DO 325 i = kk + 1, ne
        irn(i) = irn(ne+i)
325   CONTINUE
      DO 326 i = k, kk
        irn(i) = 0
326   CONTINUE

! Repartition IW (none of previous data is needed any more)
      ptrd = 0
      jfirst =  n
      lenr = m + n
      lastr = 2*m + n
      nextr = 3*m + n
      nextc = 4*m + n
      ptro = nextc
! Use scratch space in KEEP for work arrays in MA50AD.
! Use an allocatable work array for this now
!      lastc = m + n
!      lenc = lastc + n
       allocate(lastcol(n),lencol(n),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        go to 530
      endif

! Call MA50A/AD block by block from the back.
      j1 = n + 1
! KB counts number of non-triangular blocks for calculation INFO(4)
      kb = 0
      DO 390 jb = nb, 1, -1
! NC is number of columns in block
        nc = keep(nblock+3*jb)
        j2 = j1 - 1
        j1 = j2 + 1 - nc
        IF (keep(mblock+3*jb)<0) THEN
! Action if triangular block
          DO 330 j = j1, j2
! Increment estimate of rank
            IF (abs(a(ne+keep(iptrd+j)))>tol) info(5) = info(5) + 1
            ip(j) = j
            iq(j) = j
330       CONTINUE
        ELSE
! Action if non-triangular block
! Copy block to allocatable work array, shifting indices.
          nzb = keep(iptrd+j2+1) - keep(iptrd+j1)
          kk = 0
          do k = keep(iptrd+j1), keep(iptrd+j2+1) - 1
!           irn(ne+k) = irn(k) - j1 + 1
            kk = kk + 1
            ifact(kk) = irn(k) - j1 + 1
!!!
!  In Version 3.0.0 fact(kk) was being set to a(k)
            fact(kk)  = a(ne+k)
          enddo
! Copy the column pointers, shifting them.
! K is position immediately before current block in IRN
          k = keep(iptrd+j1) - 1
          DO 350 j = j1, j2
            iq(j) = keep(iptrd+j) - k
350       CONTINUE
! NR is number of rows in block
          nr = nc
          IF (nb==1) nr = m
! Set permutations
! Set to identity because matrix has already been permuted to put
!   pivots on the diagonal.
          IF (job==2) THEN
            DO 360 j = j1, j1 + nr - 1
              ip(j) = j - j1 + 1
360         CONTINUE
            DO 370 j = j1, j2
              iw(ptrd+j) = j - j1 + 1
370         CONTINUE
          END IF
! Accumulate data on block triangular form
          info(7) = max(info(7),onel*nr)
          info(8) = info(8) + nc
          info(9) = info(9) + nzb
! Control for forcing columns to end.
          IF (icntl(8)/=0) icntl5(6) = keep(lblock+jb)
!         CALL ma50ad(nr,nc,nzb,la-ne-k,a(ne+k+1),irn(ne+k+1),jcn(ne+1), &
          CALL ma50ad(nr,nc,nzb,la,fact,ifact,ljfact,jfact, &
            iq(j1),cntl5,icntl5,ip(j1),np,iw(jfirst+1),iw(lenr+1), &
            iw(lastr+1),iw(nextr+1),iw(ptrd+j1),lencol(kb+1), &
            lastcol(kb+1),iw(nextc+1),multiplier,info5,rinfo5)
! Action if failure in allocate in ma50ad
          if (info5(1) .eq. -2*nr) then
            info(1) = -10
            go to 530
          endif
! KEEP(MBLOCK+3*JB) is number rows in packed storage
          keep(mblock+3*jb) = np
! Shift the permutations back
          DO 380 j = j1, j1 + nr - 1
            ip(j) = ip(j) + j1 - 1
380       CONTINUE
          DO 385 j = j1, j2
            iq(j) = iq(j) + j1 - 1
385       CONTINUE
! Adjust warning and error flag
          IF (info5(1)==1) THEN
            IF (info(1)==0 .OR. info(1)==4) info(1) = info(1) + 2
          END IF
          IF (info5(1)==2) THEN
            IF (info(1)==0 .OR. info(1)==2) info(1) = info(1) + 4
          END IF
          IF (info5(1)==3 .AND. info(1)>=0) info(1) = 6
!XXX not possible
!         IF (info5(1)==-3) info(1) = -3
! Accumulate number of garbage collections
          info(2) = info(2) + info5(2)
! Accumulate real space for subsequent analyse
          info(3) = max(info(3),ne+k+info5(3))
! Accumulate integer space for subsequent analyse
          info(14) = max(info(14),ne+k+info5(8))
! Accumulate estimate of rank
          info(5) = info(5) + info5(5)
! Accumulate number of dropped entries
          info(6) = info(6) + info5(6)
! Accumulate floating-point count
          rinfo(1) = rinfo(1) + rinfo5(1)
! Calculate data necessary for INFO(4)
! LENCOL(KB) holds the actual storage forecast for MA50BD entry.
          kb = kb + 1
          lencol(kb) = info5(4) - 2*nr
! LASTCOL(KB) holds the storage plus elbow room forecast
!         for MA50BD entry.
          lastcol(kb) = info5(4)
        END IF
390   CONTINUE

! Now calculate storage required for subsequent factorization.
      info(4) = ne*2
      k = ne
      do jb = kb, 1, -1
        info(4) = max(info(4),k+lastcol(jb))
        k = k + lencol(jb)
      enddo

      deallocate(lastcol,lencol,stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        go to 530
      endif

!XXX Cannot be executed .... remove?
!     IF (info(1)==-3) THEN
!       IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9120) la, info(3)
!       GO TO 530
!     END IF


! Reorder IRN(1:NE) to the revised column permutation, storing in
!     IRN(NE+k) the new position for the entry that was in position k.
! Copy IRN data back.
      DO 410 k = 1, ne
        irn(ne+k) = irn(k)
410   CONTINUE
      DO 420 j = 1, n
        iw(ptrd+j) = keep(iptrd+j)
        iw(ptro+j) = keep(iptro+j+1) + 1
420   CONTINUE
      kd = 1
      ko = nzd + 1
      DO 450 j = 1, n
        keep(iptrd+j) = kd
        jay = iq(j)
        kl = nzd
        IF (jay/=n) kl = iw(ptrd+jay+1) - 1
        DO 430 kk = iw(ptrd+jay), kl
          irn(kd) = ip(irn(ne+kk))
          irn(ne+kk) = kd
          kd = kd + 1
430     CONTINUE
        keep(iptro+j) = ko
        kl = ne
        IF (jay/=1) kl = iw(ptro+jay-1) - 1
        DO 440 kk = iw(ptro+jay), kl
          irn(ko) = ip(irn(ne+kk))
          irn(ne+kk) = ko
          ko = ko + 1
440     CONTINUE
450   CONTINUE
      keep(iptro+n+1) = ko

! Compute the product permutations
      DO 460 i = 1, m
        keep(i) = ip(keep(i))
460   CONTINUE
      DO 465 i = 1, n
        iq(i) = keep(m+iq(i))
465   CONTINUE
      DO 470 i = 1, n
        keep(m+i) = iq(i)
470   CONTINUE

! Compute (product) map
! Set IRN(NE) to deal with out-of-range indices
      iw(1) = irn(ne)
      irn(ne) = ne
      DO 480 k = 1, ne
        jcn(k) = irn(ne+jcn(k))
480   CONTINUE
! Reset IRN(NE)
      irn(ne) = iw(1)

! Warning messages
      IF (info(11)>0 .OR. info(12)>0) THEN
        info(1) = info(1) + 1
        IF (mp>0 .AND. icntl(3)>=2) THEN
          IF (info(11)>0) WRITE (mp,9150) info(11)
          IF (info(12)>0) WRITE (mp,9160) info(12)
        END IF
        IF (info(11)>0) jcn(1) = -jcn(1)
      END IF

! Set rank estimate to min of structural and INFO(5) estimate.
      IF (info(10)<info(5)) THEN
        info(5) = info(10)
        IF (info(1)/=2 .AND. info(1)/=3 .AND. info(1)<6) info(1) = info(1) + 2
      END IF

      IF (mp>0 .AND. icntl(3)>2) THEN
        WRITE (mp,'(/A/A/12I6/A,F12.1)') ' Leaving MA48A/AD with', &
          ' INFO(1:12)  =', (info(i),i=1,12), ' RINFO(1) =', rinfo(1)
        WRITE (mp,'(A)') ' Permuted matrix by blocks (IRN)'
        kb = nb
        IF (icntl(3)==3) THEN
          WRITE (mp,'(A)') ' Only first column of up to 10 blocks printed'
          kb = min(10,nb)
        END IF
        WRITE (mp,'(A)') ' Diagonal blocks'
        j1 = 1
        DO 500 jb = 1, kb
          j2 = j1 + keep(nblock+3*jb) - 1
          IF (j1<=j2) WRITE (mp,'(A,I6)') ' Block', jb
          j3 = j2
          IF (icntl(3)==3) j3 = j1
          DO 490 j = j1, j3
            WRITE (mp,'(A,I5,(T13,10I6))') ' Column', j, &
              (irn(i),i=keep(iptrd+j),keep(iptrd+j+1)-1)
490       CONTINUE
          j1 = j2 + 1
500     CONTINUE
        IF (keep(iptro+n+1)>keep(iptrd+n+1)) THEN
          WRITE (mp,'(A)') ' Off-diagonal entries'
          j1 = 1
          DO 520 jb = 1, kb
            j2 = j1 + keep(nblock+3*jb) - 1
            j3 = j2
            IF (icntl(3)==3) j3 = j1
            DO 510 j = j1, j3
              IF (keep(iptro+j+1)>keep(iptro+j)) WRITE (mp, &
                '(A,I5,(T13,10I6))') ' Column', j, (irn(i),i=keep(iptro+j), &
                keep(iptro+j+1)-1)
510         CONTINUE
            j1 = j2 + 1
520       CONTINUE
        END IF
        IF (icntl(3)>3) THEN
          WRITE (mp,9040) (jcn(k),k=1,ne)
9040      FORMAT (' JCN (MAP) ='/(6X,10I6))
          WRITE (mp,'(A)') ' Contents of KEEP array'
          WRITE (mp,9010) (keep(i),i=1,m)
          WRITE (mp,9020) (keep(m+i),i=1,n)
          WRITE (mp,'(A)') ' Pointer information from KEEP'
          WRITE (mp,9050) (keep(iptrd+j),j=1,n+1)
9050      FORMAT (' IPTRD ='/(8X,10I6))
          WRITE (mp,9060) (keep(iptro+j),j=1,n+1)
9060      FORMAT (' IPTRO ='/(8X,10I6))
          WRITE (mp,'(A)') ' Block structure information from KEEP'
          WRITE (mp,9070) (keep(nblock+3*jb),jb=1,nb)
          WRITE (mp,9080) (keep(mblock+3*jb),jb=1,nb)
9070      FORMAT (' NBLOCK (order blocks) ='/(8X,10I6))
9080      FORMAT (' MBLOCK (triangular flag and number packed rows) ='/ &
            (8X,10I6))
9090      FORMAT (' LBLOCK (number of changed columns) ='/(8X,10I6))
          IF (icntl(8)/=0) WRITE (mp,9090) (keep(lblock+jb),jb=1,nb)
        ELSE
          WRITE (mp,9040) (jcn(k),k=1,min(10*onel,ne))
          WRITE (mp,'(A)') ' Contents of KEEP array'
          WRITE (mp,9010) (keep(i),i=1,min(10,m))
          WRITE (mp,9020) (keep(m+i),i=1,min(10,n))
          WRITE (mp,'(A)') ' Pointer information from KEEP'
          WRITE (mp,9050) (keep(iptrd+j),j=1,min(10,n+1))
          WRITE (mp,9060) (keep(iptro+j),j=1,min(10,n+1))
          WRITE (mp,'(A)') ' Block structure information from KEEP'
          WRITE (mp,9070) (keep(nblock+3*jb),jb=1,min(10,nb))
          WRITE (mp,9080) (keep(mblock+3*jb),jb=1,min(10,nb))
          IF (icntl(8)/=0) WRITE (mp,9090) (keep(lblock+jb),jb=1,min(10,nb))
        END IF
      END IF

! Deallocate arrays
530   deallocate(iptra,iptrp,iq,ip,stat=stat)
      deallocate(iw,stat=stat)
      deallocate(fact,ifact,jfact,stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        return
      endif
      RETURN

9110  FORMAT (' Error return from MA48A/AD because NE =',I10)
9120  FORMAT (' Error return from MA48A/AD because LA is',I10/' and ', &
        'must be at least',I10)
9130  FORMAT (' Error return from MA48A/AD because ','JOB = ',I10)
9140  FORMAT (' Error return from MA48A/AD because ','faulty permutati', &
        'ons input when JOB = 2')
9150  FORMAT (' Message from MA48A/AD ..',I8,' duplicates found')
9160  FORMAT (' Message from MA48A/AD ..',I8,' out-of-range indices fo','und')
    END subroutine ma48ad


    SUBROUTINE ma48bd(m,n,ne,job,la,a,irn,jcn,keep,cntl,icntl,info,rinfo)
! Factorize a sparse matrix, using data provided by MA48A/AD.

!     .. Arguments ..
      INTEGER m, n, job
      integer(long) :: ne, la
      DOUBLE PRECISION a(la)
      INTEGER(long) :: irn(la), jcn(ne)
      integer(long) :: keep(*)
      DOUBLE PRECISION cntl(10)
      INTEGER icntl(20)
      real(wp), allocatable :: w(:)
      integer(long), allocatable :: iw(:)
      INTEGER(long) :: info(20)
      DOUBLE PRECISION rinfo(10)

! M must be set by the user to the number of rows.
!      It is not altered by the subroutine. Restriction: M > 0.
! N must be set by the user to the number of columns.
!      It is not altered by the subroutine. Restriction: N > 0.
! NE must be set by the user to the number of entries in the input
!      matrix. It is not altered by the subroutine. Restriction: NE > 0.
! JOB  must be set by the user to 1 for a normal entry or to 2 for a
!      fast entry. JOB is not altered by the subroutine.
!      Restriction 1 <= JOB <= 2.
! LA must be set by the user to the size of A and IRN.
!      It is not altered by the subroutine. Restriction: LA > 2*NE.
! A    must be set by the user so that the first NE elements hold the
!      matrix entries in exactly the same order as were input to
!      MA48A/AD. On return, these elements hold the permuted matrix A
!      and the rest contains the factorizations of the block diagonal
!      part (excluding blocks that are triangular).
! IRN  The first KEEP(IPTRO+N+1)-1 (<=NE) entries must be as on return
!      from MA48A/AD and hold
!      the row numbers of the permuted matrix, with duplicates excluded.
!      The permuted matrix is block upper triangular with recommended
!      pivots on its diagonal. The rest of the array need not be set on
!      entry with JOB=1. It is used for the row indices of the
!      factorizations. On entry with JOB=2, it must be unchanged
!      since the entry with JOB=1 and is not altered.
! JCN  must be as on return from MA48A/AD. abs(JCN(k)) holds the
!      position in IRN that corresponds to the entry that was input in
!      A(k),k=1,NE.  It is not altered by the subroutine.
!      If JCN(1) is negative then there are duplicates.
! KEEP must be as on return from MA48A/AD or MA48B/BD.
!      KEEP(i) holds the position of row i in the permuted
!        matrix, I=1,M;
!      KEEP(N+j) holds the index of the  column that is in position j
!        of the permuted matrix, j=1,N;
!      KEEP(IPTRL+k), IPTRL=M+N, k=1,N, need not be set on an
!        entry with JOB=1. It holds pointers, relative to the start
!        of the block, to the columns of the
!        lower-triangular part of the factorization. On entry with
!        JOB=2, it must be unchanged since the entry with JOB=1 and is
!        not altered.
!      KEEP(IPTRU+k), IPTRU=IPTRL+N, k=1,N, need not be set on an
!        entry with JOB=1. It holds pointers, relative to the start
!        of the block, to the columns of the
!        upper-triangular part of the factorization. On an entry with
!        JOB=2, it must be unchanged since the entry with JOB=1 and
!        is not altered.
!      KEEP(IPTRD+j), IPTRD=IPTRU+N, holds the position in IRN of the
!        start of the block diagonal part of column j, J=1,N;
!      KEEP(IPTRD+N+1) holds the position that immediately follows
!        the end of the block diagonal part of column N;
!      KEEP(IPTRO+j),IPTRO=IPTRD+N+1, holds the position in IRN of
!        the start of the block off-diagonal part of column j, j=1,N;
!      KEEP(IPTRO+N+1) holds the position that immediately
!        follows the end of the block off-diagonal part of column N;
!      KEEP(KBLOCK+3), KBLOCK=IPTRO+N+1, holds the number of
!        blocks NB in the block triangular form;
!      KEEP(NBLOCK+3*k), NBLOCK=IPTRO+N-1, holds the number of columns
!        in block k, k=1,NB;
!      KEEP(MBLOCK+3*k), MBLOCK=IPTRO+N, is negative if block k
!        is triangular or holds the number of rows held in packed
!        storage when processing block k, k=1,NB;
!      KEEP(KBLOCK+3*k), k=2,NB need not be set on an entry with
!        JOB=1; on return it holds zero for a triangular block and for
!        a non-triangular block holds the position in A(NEWNE+1) and
!        IRN(NEWNE+1) of the start of the factorization of the block.
!        KEEP(LBLOCK+k), LBLOCK=KBLOCK+3*NB is accessed only if ICNTL(8)
!          is not 0 and holds the number of columns in
!          block k which are to be pivoted on last, k=1,NB.
!      On an entry with JOB=2, KEEP must be unchanged since the entry
!      with JOB=1 and is not altered.
! CNTL  must be set by the user as follows and is not altered.
!     CNTL(2) determines the balance used by MA50A/AD and MA50B/BD
!       between pivoting for sparsity and for stability, values near
!       zero emphasizing sparsity and values near one emphasizing
!       stability.
!     CNTL(3) If this is set to a positive value, any entry whose
!       modulus is less than CNTL(3) will be dropped from the factors
!       calculated by MA50A/AD. The factorization will then require
!       less storage but will be inaccurate.
!     CNTL(4)  If this is set to a positive value, any entry whose
!       modulus is less than CNTL(4) will be regarded as zero from
!       the point of view of rank.
!     CNTL(5:10) are not referenced by the subroutine.
! ICNTL must be set by the user as follows and is not altered.
!     ICNTL(1)  must be set to the stream number for error messages.
!       A value less than 1 suppresses output.
!     ICNTL(2) must be set to the stream number for diagnostic output.
!       A value less than 1 suppresses output.
!     ICNTL(3) must be set to control the amount of output:
!       0 None.
!       1 Error messages only.
!       2 Error and warning messages.
!       3 As 2, plus scalar parameters and a few entries of array
!         parameters on entry and exit.
!       4 As 2, plus all parameters on entry and exit.
!     ICNTL(4)  If set to a positive value, the pivot search by MA50A/AD
!       is limited to ICNTL(4) columns. This may result in different
!       fill-in and execution time.
!     ICNTL(5) The block size to be used for full-matrix processing.
!     ICNTL(6) is not referenced by the subroutine.
!     ICNTL(8) If set to a value other than zero and JOB = 2 or 3,
!       it is assumed that only the last KEEP(LBLOCK+JB), JB = 1,NB
!       columns have changed since the last factorization.
!     ICNTL(9) is not referenced by the subroutine.
!     ICNTL(10) has default value 0. If set to 1, there is an immediate
!       return from MA48B/BD if LA is too small, without continuing the
!       decomposition to compute the size necessary.
!     ICNTL(11) has default value 0. If set to 1 on a JOB=2 call to
!       MA48B/BD and the entries in one of the blocks on the diagonal
!       are unsuitable for the pivot sequence chosen on the previous
!       call, the block is refactorized as on a JOB=1 call.
!     ICNTL(12:20) are not referenced by the subroutine.

! W    is a workarray.
! IW   is a workarray.
! INFO(1) is an integer variable that need not be set on entry. On exit,
!      a nonzero value of INFO(1) will indicate an error return.
!      Possible nonzero values are:
!      -1  M < 1 or N < 1
!      -2  NE < 0
!      -3  Insufficient space
!      -6  JOB out of range or JOB = 2 or 3 after factorization in which
!          entries were dropped.
!      -7  On a call with JOB=2, the matrix entries are numerically
!          unsuitable
!      +2  Matrix is structurally rank deficient. Estimated rank in
!          INFO(5).
! INFO(4) is set to the minimum size required for a further
!      factorization on a matrix with the same pivot sequence.
! INFO(5) is set to computed rank of the matrix.
! INFO(6) is set to number of entries dropped from structure.
! RINFO need not be set on entry. On exit, RINFO(1) holds the number of
!    floating-point operations performed.

!     .. Local constants ..
      DOUBLE PRECISION zero
      PARAMETER (zero=0.0_wp)

!     .. Local variables ..
      DOUBLE PRECISION cntl5(10)
      integer icntl5(20), job5, nb, nr, nc, np
      integer(long) :: i, info5(15), iptrd, iptrl, iptro, iptru, iqb(1), &
        itry, j, jb, j1, j2, j3, k, kb, kblock, kk, lblock, lp, mblock, &
        mp, nblock, newne, nrf, nzb
      DOUBLE PRECISION rinfo5(10), tol
      LOGICAL trisng
! I Temporary DO index.
! ICNTL5 passed to MA50B/BD to correspond to dummy argument ICNTL.
! INFO5 passed to MA50B/BD to correspond to dummy argument INFO.
! IPTRD displacement in KEEP. See comment on KEEP.
! IPTRL displacement in KEEP. See comment on KEEP.
! IPTRO displacement in KEEP. See comment on KEEP.
! IPTRU displacement in KEEP. See comment on KEEP.
! IQB   passed to MA50B/BD to indicate that no column permutation is
!       required.
! ITRY  Loop index for retrying the factorization of a block.
! J     column index.
! JB    block index.
! JOB5  passed to MA50B/BD to correspond to dummy argument JOB
! J1    first column index of a block.
! J2    last column index of a block.
! J3    used in prints to hold last column index of block.
! K     running index for position in matrix.
! KB  number of blocks ... used in printing
! KBLOCK displacement in KEEP. See comment on KEEP.
! KK    running index for position in matrix.
! LBLOCK displacement in KEEP. See comment on KEEP.
! LP Unit for error messages.
! MBLOCK displacement in KEEP. See comment on KEEP.
! MP Unit for diagnostic messages.
! NBLOCK displacement in KEEP. See comment on KEEP.
! NB  number of blocks
! NC    number of columns in block
! NEWNE number of entries in original matrix with duplicates and
!       out-of-range indices removed
! NP Number of columns in packed storage.
! NR    number of rows in block
! NRF   is number of rows in full form for current block.
! NZB   number of entries in current diagonal block
! RINFO5 passed to MA50B/BD to correspond to dummy argument RINFO.
! TOL   pivot tolerance
! TRISNG is flag to indicate singularity in triangular block.

!     .. Externals ..
      INTRINSIC max

      lp = icntl(1)
      mp = icntl(2)
! Simple data checks
!!!
! Although these will not happen when called from HSL_MA48
! They are tested in internal calls from current test deck
      IF (m<=0 .OR. n<=0) THEN
        info(1) = -1
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9160) m, n
        GO TO 240
      END IF
      IF (ne<=0) THEN
        info(1) = -2
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9170) ne
        GO TO 240
      END IF
      IF (la<2*ne) THEN
        info(1) = -3
        info(4) = 2*ne
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9180) la, info(4)
        GO TO 240
      END IF
      IF (job<1 .OR. job>3) THEN
        info(1) = -6
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9190) job
        GO TO 240
      END IF
      info(1) = 0
      DO 10 i = 1, 4
        cntl5(i) = cntl(i)
        icntl5(i) = icntl(i)
10    CONTINUE
! Switch off printing from MA50B/BD
      icntl5(3) = 0
! Set BLAS control
      icntl5(5) = icntl(5)
! Initialize restricted pivoting control
      icntl5(6) = 0
      icntl5(7) = 0
      icntl5(8) = icntl(10)
      allocate(w(m),iw(2*m+2*n),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        return
      endif
! Partition KEEP and A
      iptrl = m + n
      iptru = iptrl + n
      iptrd = iptru + n
      iptro = iptrd + n + 1
      nblock = iptro + n - 1
      mblock = nblock + 1
      kblock = mblock + 1
      nb = keep(kblock+3)
      lblock = kblock + 3*nb
      newne = keep(iptro+n+1) - 1

      IF (mp>0 .AND. icntl(3)>2) THEN
        WRITE (mp,'(/A/3(A,I8),A,I2,A,I8/A,1P,3D12.4/A,3I8/A,I8/A,I8)') &
          ' Entering MA48B/BD with', ' M =', m, '     N =', n, '     NE =', &
          ne, '     JOB =', job, '     LA =', la, ' CNTL (2:4) =', &
          (cntl(i),i=2,4), ' ICNTL(1:3) =', (icntl(i),i=1,3), ' ICNTL(5)   =', &
          icntl(5), ' ICNTL(8)   =', icntl(8)
        IF (icntl(3)>3) THEN
          WRITE (mp,9000) (a(k),k=1,ne)
        ELSE
          WRITE (mp,9000) (a(k),k=1,min(10*onel,ne))
        END IF
9000    FORMAT (' A ='/(4X,1P,5D12.4))
        WRITE (mp,'(A)') ' Indices for permuted matrix by blocks'
        kb = nb
        IF (icntl(3)==3) THEN
          WRITE (mp,'(A)') ' Only first column of up to 10 blocks printed'
          kb = min(10,nb)
        END IF
        WRITE (mp,'(A)') ' Diagonal blocks'
        j1 = 1
        DO 30 jb = 1, kb
          WRITE (mp,'(A,I6)') ' Block', jb
          j2 = j1 + keep(nblock+3*jb) - 1
          j3 = j2
          IF (icntl(3)==3) j3 = j1
          DO 20 j = j1, j3
            WRITE (mp,'(A,I5,(T13,10I6))') ' Column', j, &
              (irn(i),i=keep(iptrd+j),keep(iptrd+j+1)-1)
20        CONTINUE
          j1 = j2 + 1
30      CONTINUE
        IF (keep(iptro+n+1)>keep(iptrd+n+1)) THEN
          WRITE (mp,'(A)') ' Off-diagonal entries'
          j1 = 1
          DO 50 jb = 1, kb
            j2 = j1 + keep(nblock+3*jb) - 1
            j3 = j2
            IF (icntl(3)==3) j3 = j1
            DO 40 j = j1, j3
              IF (keep(iptro+j+1)>keep(iptro+j)) WRITE (mp, &
                '(A,I5,(T13,10I6))') ' Column', j, (irn(i),i=keep(iptro+j), &
                keep(iptro+j+1)-1)
40          CONTINUE
            j1 = j2 + 1
50        CONTINUE
        END IF
        IF (icntl(3)>3) THEN
          WRITE (mp,9010) (jcn(k),k=1,ne)
9010      FORMAT (' JCN (MAP) ='/(6X,10I6))
          WRITE (mp,'(A)') ' Contents of KEEP array'
          WRITE (mp,9020) (keep(i),i=1,m)
          WRITE (mp,9030) (keep(m+i),i=1,n)
9020      FORMAT (' Positions of original rows in the permuted matrix'/(10I6))
9030      FORMAT (' Positions of columns of permuted matrix ','in ', &
            'original matrix '/(10I6))
          WRITE (mp,'(A)') ' Pointer information from KEEP'
          WRITE (mp,9040) (keep(iptrd+j),j=1,n+1)
9040      FORMAT (' IPTRD ='/(8X,10I6))
          WRITE (mp,9050) (keep(iptro+j),j=1,n+1)
9050      FORMAT (' IPTRO ='/(8X,10I6))
          IF (job>1) THEN
            WRITE (mp,9060) (keep(iptrl+j),j=1,n)
9060        FORMAT (' IPTRL ='/(8X,10I6))
            WRITE (mp,9070) (keep(iptru+j),j=1,n)
9070        FORMAT (' IPTRU ='/(8X,10I6))
          END IF
          WRITE (mp,'(A)') ' Block structure information from KEEP'
          WRITE (mp,9080) (keep(nblock+3*jb),jb=1,nb)
          WRITE (mp,9090) (keep(mblock+3*jb),jb=1,nb)
9080      FORMAT (' NBLOCK (order blocks) ='/(8X,10I6))
9090      FORMAT (' MBLOCK (triangular flag and number packed rows) ='/ &
            (8X,10I6))
9100      FORMAT (' KBLOCK (position of beginning of block) ='/(8X,10I6))
9110      FORMAT (' LBLOCK (number of changed columns) ='/(8X,10I6))
          IF (job>1) THEN
            WRITE (mp,9100) (keep(kblock+3*jb),jb=1,nb)
            IF (icntl(8)/=0) WRITE (mp,9110) (keep(lblock+jb),jb=1,nb)
          END IF
        ELSE
          WRITE (mp,9010) (jcn(k),k=1,min(10*onel,ne))
          WRITE (mp,'(A)') ' Contents of KEEP array'
          WRITE (mp,9020) (keep(i),i=1,min(10,m))
          WRITE (mp,9030) (keep(m+i),i=1,min(10,n))
          WRITE (mp,'(A)') ' Pointer information from KEEP'
          WRITE (mp,9040) (keep(iptrd+j),j=1,min(10,n+1))
          WRITE (mp,9050) (keep(iptro+j),j=1,min(10,n+1))
          IF (job>1) THEN
            WRITE (mp,9060) (keep(iptrl+j),j=1,min(10,n))
            WRITE (mp,9070) (keep(iptru+j),j=1,min(10,n))
          END IF
          WRITE (mp,'(A)') ' Block structure information from KEEP'
          WRITE (mp,9080) (keep(nblock+3*jb),jb=1,min(10,nb))
          WRITE (mp,9090) (keep(mblock+3*jb),jb=1,min(10,nb))
          IF (job>1) THEN
            WRITE (mp,9100) (keep(kblock+3*jb),jb=1,min(10,nb))
            IF (icntl(8)/=0) WRITE (mp,9110) (keep(lblock+jb),jb=1,min(10,nb))
          END IF
        END IF
      END IF

! Initialize INFO and RINFO
      info(4) = ne
      info(5) = 0
      info(6) = 0
      rinfo(1) = zero
! Set pivot tolerance
      tol = max(zero,cntl(4))

! Use map to sort the new values into A.
! Mapping into first NEWNE locations in array A
      IF (jcn(1)>0) THEN
        DO 60 k = 1, ne
          a(ne+k) = a(k)
60      CONTINUE
!DIR$ IVDEP
        DO 70 k = 1, ne
          a(jcn(k)) = a(ne+k)
70      CONTINUE
      ELSE
! Duplicates exist
        DO 80 k = 1, ne
          a(ne+k) = a(k)
          a(k) = zero
80      CONTINUE
        a(-jcn(1)) = a(ne+1)
        DO 90 k = 2, ne
          kk = jcn(k)
          a(kk) = a(kk) + a(ne+k)
90      CONTINUE
      END IF

! Call MA50B/BD block by block.
      iqb(1) = 0
      kk = 0
      j2 = 0
      job5 = job
      DO 150 jb = 1, nb
        nc = keep(nblock+3*jb)
        j1 = j2 + 1
        j2 = j1 + nc - 1
        keep(kblock+3*jb) = 0
        IF (keep(mblock+3*jb)<0) THEN
! Action if triangular block
          trisng = .FALSE.
          DO 100 j = j1, j2
            IF (abs(a(keep(iptrd+j)))<=tol) trisng = .TRUE.
            keep(iptrl+j) = 0
            keep(iptru+j) = 0
100       CONTINUE
          IF ( .NOT. trisng) THEN
            info(5) = info(5) + nc
            GO TO 150
          END IF
! Block is singular. Treat as non-triangular.
          IF (job==2) THEN
            info(1) = -7
!!!
! The write statement is switched off by HSL_MA48 call so not tested
!           IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,'(A)') &
!             ' Error return from MA48B/BD with JOB=2 because ', &
!             ' the matrix is incompatible with expectations'
            GO TO 240
          ELSE
            keep(mblock+3*jb) = nc
          END IF
        END IF
! Action if non-triangular block
        DO 145 itry = 1, 2
! The second iteration of this loop is used only if JOB=2,
!   ICNTL(11)=1, and the call to MA50B with JOB=1 fails.
          nr = nc
          IF (nb==1) nr = m
          nzb = keep(iptrd+j2+1) - keep(iptrd+j1)
          IF (icntl(8)/=0) icntl5(6) = keep(lblock+jb)
! Shift the indices and pointers to local values.
          DO 110 k = keep(iptrd+j1), keep(iptrd+j2+1) - 1
            irn(k) = irn(k) - j1 + 1
110       CONTINUE
          k = keep(iptrd+j1) - 1
          DO 115 j = j1, j1 + nc - 1
            keep(iptrd+j) = keep(iptrd+j) - k
115       CONTINUE
          DO 120 j = j1, j1 + nr - 1
            iw(j) = j - j1 + 1
120       CONTINUE
          np = keep(mblock+3*jb)
!!!!!!!!!!!!!!!!!!! MA50BD !!!!!!!!!!!!!!!!!!!!!!!
          CALL ma50bd(nr,nc,nzb,job5,a(k+1),irn(k+1),keep(iptrd+j1),cntl5, &
            icntl5,iw(j1),iqb,np,la-newne-kk,a(newne+kk+1),  &
            la-newne-kk,irn(newne+kk+1), &
            keep(iptrl+j1),keep(iptru+j1),info5,rinfo5)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Action if failure in allocate in ma50ad
          if (info5(1) .eq. -2*nr) then
            info(1) = -10
            GO TO 240
          endif
! Restore the indices and pointers
          DO 130 j = j1, j2
            keep(iptrd+j) = keep(iptrd+j) + k
130       CONTINUE
          DO 140 k = keep(iptrd+j1), keep(iptrd+j2+1) - 1
            irn(k) = irn(k) + j1 - 1
140       CONTINUE
! Set warning and error returns
!!!
!XXX This return cannot happen on hsl_ma48 call as "fast" is only
!    allowed if there are no dropped entries.
!         IF (info5(1)==-6) THEN
!           info(1) = -6
!           IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,'(A)') &
!             ' Error return from MA48B/BD with JOB greater than 1', &
!             ' and entries dropped during previous factorization'
!           GO TO 240
!         END IF
          IF (info5(1)<-7) THEN
            IF (icntl(11)==1 .AND. job==2) THEN
              job5 = 1
              IF (lp>0 .AND. icntl(3)>=2) WRITE (lp,'(A,2(A,I4))') &
                ' Warning from MA48B/BD. Switched from JOB=2 to JOB=1', &
                ' in block', jb, ' of ', nb
              info(1) = info(1) + 1
              GO TO 145
            END IF
            info(1) = -7
!!!
! However, this is actually tested in the internal MA48 call in test deck
            IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,'(A)') &
              ' Error return from MA48B/BD with JOB=2 because ', &
              ' the matrix is incompatible with expectations'
            GO TO 240
          ELSE
            GO TO 147
          END IF
145     CONTINUE
147     IF (info5(1)==-3) THEN
          info(1) = -3
          IF (icntl(10)==1) THEN
            keep(kblock+3) = nb
!!!
! However, this is actually tested in the internal MA48 call in test deck
            IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,'(A,2(A,I4))') &
              ' Error return from MA48B/BD because LA is too small.', &
              ' In block', jb, ' of ', nb
            GO TO 240
          END IF
        END IF
        IF (info(1)==-3) THEN
          info(4) = info(4) + info5(4)
          kk = 0
        ELSE
          info(4) = max(info(4),kk+newne+info5(4))
          nrf = irn(newne+kk+2)
! Set pointer to first entry in block JB in A(NEWNE+1), IRN(NEWNE+1)
          keep(kblock+3*jb) = kk + 1
          kk = kk + keep(iptrl+j2) + max((nc-keep(mblock+ &
            3*jb))*(nrf),(nc-keep(mblock+3*jb))+(nrf))
        END IF
! Is matrix rank deficient?
        IF (info5(1)==1) THEN
          IF (info(1)/=-3) info(1) = min(info(1)+2,3*onel)
        END IF
! Accumulate stats
        rinfo(1) = rinfo(1) + rinfo5(1)
        info(5) = info(5) + info5(5)
        info(6) = info(6) + info5(6)
150   CONTINUE

      info(4) = max(ne*2,info(4))
      keep(kblock+3) = nb

      IF (info(1)==-3) THEN
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9180) la, info(4)
        GO TO 240
      END IF

      IF (mp>0 .AND. icntl(3)>2) THEN
        WRITE (mp,'(/A/A,I6/A,3I6/A,F12.1)') ' Leaving MA48B/BD with', &
          ' INFO(1)   = ', info(1), ' INFO(4:6) = ', (info(i),i=4,6), &
          ' RINFO(1)     =', rinfo(1)
        WRITE (mp,'(A)') ' Permuted matrix by blocks'
        kb = nb
        IF (icntl(3)==3) THEN
          WRITE (mp,'(A)') ' Only first column of up to 10 blocks printed'
          kb = min(10,nb)
        END IF
        WRITE (mp,'(A)') ' Diagonal blocks'
        j1 = 1
        DO 170 jb = 1, kb
          j2 = j1 + keep(nblock+3*jb) - 1
          IF (j1<=j2) WRITE (mp,'(A,I6)') ' Block', jb
          j3 = j2
          IF (icntl(3)==3) j3 = min(j1,j2)
          DO 160 j = j1, j3
            WRITE (mp,'(A,I5,(T13,3(1PD12.4,I5)))') ' Column', j, &
              (a(i),irn(i),i=keep(iptrd+j),keep(iptrd+j+1)-1)
160       CONTINUE
          j1 = j2 + 1
170     CONTINUE
        IF (keep(iptro+n+1)>keep(iptrd+n+1)) THEN
          WRITE (mp,'(A)') ' Off-diagonal entries'
          j1 = 1
          DO 190 jb = 1, kb
            j2 = j1 + keep(nblock+3*jb) - 1
            j3 = j2
            IF (icntl(3)==3) j3 = min(j1,j2)
            DO 180 j = j1, j3
              IF (keep(iptro+j+1)>keep(iptro+j)) WRITE (mp, &
                '(A,I5,(T13,3(1P,D12.4,I5)))') ' Column', j, &
                (a(i),irn(i),i=keep(iptro+j),keep(iptro+j+1)-1)
180         CONTINUE
            j1 = j2 + 1
190       CONTINUE
        END IF
        WRITE (mp,'(A)') ' Factorized matrix by blocks'
        j1 = 1
        DO 230 jb = 1, kb
          j2 = j1 + keep(nblock+3*jb) - 1
! Jump if triangular block
          IF (keep(mblock+3*jb)<0) GO TO 220
          nc = j2 - j1 + 1
          nr = nc
          IF (kb==1) nr = m
          WRITE (mp,'(A,I6)') ' Block', jb
          k = newne
          IF (jb>1) k = keep(kblock+3*jb) + newne - 1
          IF (keep(iptrl+j1)>keep(iptru+j1)) WRITE (mp, &
            '(A,I5,A,(T18,3(1P,D12.4,I5)))') ' Column', j1, ' of L', &
            (a(k+i),irn(k+i),i=keep(iptru+j1)+1,keep(iptrl+j1))
          IF (icntl(3)==3) GO TO 210
          DO 200 j = j1 + 1, j2
            IF (keep(iptru+j)>keep(iptrl+j-1)) WRITE (mp, &
              '(A,I5,A,(T18,3(1P,D12.4,I5)))') ' Column', j, ' of U', &
              (a(k+i),irn(k+i),i=keep(iptrl+j-1)+1,keep(iptru+j))
            IF (keep(iptru+j)<keep(iptrl+j)) WRITE (mp, &
              '(A,I5,A,(T18,3(1P,D12.4,I5)))') ' Column', j, ' of L', &
              (a(k+i),irn(k+i),i=keep(iptru+j)+1,keep(iptrl+j))
200       CONTINUE
! Full blocks
210       WRITE (mp,'(A)') ' Full block'
          WRITE (mp,'(A)') ' Row indices'
          nrf = irn(k+2)
          k = k + keep(iptrl+j2)
          IF (icntl(3)>3) THEN
            WRITE (mp,9120) (irn(k+i),i=1,nrf)
            WRITE (mp,'(A)') ' Column pivoting information'
            WRITE (mp,9120) (irn(k+i),i=nrf+1,nrf+nc-keep(mblock+3*jb))
            WRITE (mp,'(A)') ' Reals by columns'
            WRITE (mp,9130) (a(k+i),i=1,(nrf)*(nc-keep(mblock+3*jb)))
9120        FORMAT (10I6)
9130        FORMAT (1P,5D12.4)
          ELSE
            WRITE (mp,9120) (irn(k+i),i=1,min(10*onel,nrf))
            WRITE (mp,'(A)') ' Column pivoting information'
            WRITE (mp,9120) (irn(k+i),i=nrf+1,nrf+min(10*onel,nc-keep(mblock+ &
              3*jb)))
            WRITE (mp,'(A)') ' Reals by columns'
            WRITE (mp,9130) &
               (a(k+i),i=1,min(10*onel,(nrf)*(nc-keep(mblock+3*jb))))
          END IF
220       j1 = j2 + 1
230     CONTINUE
        IF (job==1 .OR. job==3) THEN
          WRITE (mp,'(A)') ' Contents of KEEP array'
          IF (icntl(3)>3) THEN
            WRITE (mp,9020) (keep(i),i=1,m)
            WRITE (mp,9030) (keep(m+i),i=1,n)
            WRITE (mp,'(A)') ' Pointer information from KEEP'
            WRITE (mp,9140) (keep(iptrl+j),j=1,n)
9140        FORMAT (' IPTRL ='/(8X,10I6))
            WRITE (mp,9150) (keep(iptru+j),j=1,n)
9150        FORMAT (' IPTRU ='/(8X,10I6))
          ELSE
            WRITE (mp,9020) (keep(i),i=1,min(10,m))
            WRITE (mp,9030) (keep(m+i),i=1,min(10,n))
            WRITE (mp,'(A)') ' Pointer information from KEEP'
            WRITE (mp,9140) (keep(iptrl+j),j=1,min(10,n))
            WRITE (mp,9150) (keep(iptru+j),j=1,min(10,n))
          END IF
          WRITE (mp,'(A)') ' Block structure information from KEEP'
          WRITE (mp,9100) (keep(kblock+3*jb),jb=1,kb)
        END IF
      END IF

240   deallocate(w,iw,stat=stat)
      RETURN

9160  FORMAT (' Error return from MA48B/BD because M =',I10,' and N =',I10)
9170  FORMAT (' Error return from MA48B/BD because NE =',I10)
9180  FORMAT (' Error return from MA48B/BD because LA is',I10/' and mu', &
        'st be at least',I10)
9190  FORMAT (' Error return from MA48B/BD because ','JOB = ',I10)
    END  subroutine ma48bd


    SUBROUTINE ma48cd(m,n,trans,job,la,a,irn,keep,cntl,icntl,rhs,x,error, &
        info)

! Solve linear system, using data provided by MA48B/BD.

!     .. Arguments ..
      INTEGER m, n, job
      LOGICAL trans
      integer(long) :: la
      DOUBLE PRECISION a(la)
      INTEGER(long) irn(la)
      integer(long) :: keep(*)
      DOUBLE PRECISION cntl(10)
      INTEGER icntl(20)
      DOUBLE PRECISION rhs(*), x(*), error(3)
      real(wp), allocatable :: w(:)
      integer, allocatable :: iw(:)
      INTEGER(long) :: info(20)

! M must be set by the user to the number of rows in the matrix.
!      It is not altered by the subroutine. Restriction: M > 0.
! N must be set by the user to the number of columns in the matrix.
!      It is not altered by the subroutine. Restriction: N > 0.
! TRANS must be set by the user to indicate whether coefficient matrix
!      is A (TRANS=.FALSE.) or A transpose (TRANS=.TRUE.).
!      It is not altered by the subroutine.
! JOB  must be set by the user to control the solution phase.
!      Restriction: 1 <= JOB <= 4
!      Possible values are:
!       =1 Returns solution only.
!       =2 Returns solution and estimate of backward error.
!       =3 Performs iterative refinement and returns estimate of
!          backward error.
!       =4 As for 3 plus an estimate of the error in the solution.
!      It is not altered by the subroutine.
! LA must be set by the user to the size of arrays A and IRN.
!      It is not altered by the subroutine.
! A    must be set left unchanged from the last call to MA48B/BD.
!      It holds the original matrix in permuted form and the
!      factorization of the block diagonal part (excluding
!      any triangular blocks). It is not altered by the subroutine.
! IRN  must be set left unchanged from the last call to MA48B/BD.
!      It holds the row indices of the factorization in A and
!      the row indices of the original matrix in permuted form.
!      It is not altered by the subroutine.
! KEEP must be as on return from MA48B/BD.
!      It is not altered by the subroutine.
! CNTL  must be set by the user as follows and is not altered.
!     CNTL(I), I=1,4 not accessed by subroutine.
!     CNTL(5) is used in convergence test for termination of iterative
!     refinement.  Iteration stops if successive omegas do not decrease
!     by at least this factor.
! ICNTL must be set by the user as follows and is not altered.
!     ICNTL(1)  must be set to the stream number for error messages.
!       A value less than 1 suppresses output.
!     ICNTL(2) must be set to the stream number for diagnostic output.
!       A value less than 1 suppresses output.
!     ICNTL(3) must be set to control the amount of output:
!       0 None.
!       1 Error messages only.
!       2 Error and warning messages.
!       3 As 2, plus scalar parameters and a few entries of array
!         parameters on entry and exit.
!       4 As 2, plus all parameters on entry and exit.
!     ICNTL(I), I=4,8 not accessed by subroutine
!     ICNTL(9) is maximum number of iterations allowed in iterative
!         refinement.
! RHS  must be set by the user to contain the right-hand side of the
!      equations to be solved. If TRANS is .FALSE., RHS has length M;
!      otherwise, it has length N. It is used as workspace.
! X    need not be set by the user.  On exit, it will contain the
!      solution vector. If TRANS is .FALSE., X has length N; otherwise,
!      it has length M.
! ERROR is a real array of length 3 that need not be set by the user.
!      On exit with JOB >=2 ERROR(1) and ERROR(2) give estimates of
!      backward errors OMEGA1 and OMEGA2.  On exit with JOB = 4,
!      ERROR(3) holds an estimate of the infinity norm in the relative
!      error in the solution.
! IW   is a workarray.
! INFO need not be set on entry. On exit, it holds the following:
!    INFO(1) A nonzero value will indicate an error return. Possible
!      nonzero values are:
!      -1  M or N < 1
!      -6  JOB out of range
!      -8  Nonconvergence of iterative refinement
!      -9  Failure in MC71A/AD

!     .. Local constants ..
      real(wp) zero
      PARAMETER (zero=0.0_wp)

!     .. Local variables ..
      real(wp) cond(2), ctau, dxmax
      integer icntl5(20), kase, lp, mp, nb, nc, neq, nrf, nvar, iblock
      INTEGER(long) :: i, iptrd, iptrl, iptro, iptru, iqb(1), j, jb, jj, &
        j1, j2, j3, k, kb, kblock, kk
      INTEGER(i4) :: keep71(5)
      LOGICAL lcond(2)
      INTEGER(long) :: mblock, nblock, ne
      real(wp) oldomg(2), omega(2), om1, om2, tau
! COND  Arioli, Demmel, and Duff condition number
! CTAU is a real variable used to control the splitting of the equations
!     into two categories. This is constant in Arioli, Demmel, and Duff
!     theory.
! DXMAX max-norm of current solution estimate
! I     row index and DO loop variable
! ICNTL5 passed to MA50C/CD to correspond to dummy argument ICNTL.
! IPTRD displacement in KEEP. See comment on KEEP.
! IPTRL displacement in KEEP. See comment on KEEP.
! IPTRO displacement in KEEP. See comment on KEEP.
! IPTRU displacement in KEEP. See comment on KEEP.
! IQB   is passed to MA50C/CD to indicate that no column permutation
!       is used.
! J     column index
! JB    is current block.
! JJ    running index for column.
! J1    is index of first column in block.
! J2    is index of last column in block.
! J3    is index of last column in block used in printing diagnostics.
! K     iteration counter and DO loop variable
! KASE  control for norm calculating routine MC71A/AD
! KB    used in prints to hold number of blocks or less if ICNTL(3)
!       equal to 3.
! KBLOCK displacement in KEEP. See comment on KEEP.
! KEEP71 workspace to preserve MC71A/AD's locals between calls
! KK    DO loop variable
! LCOND LCOND(k) is set to .TRUE. if there are equations in category
!       k, k=1,2
! LP Unit for error messages.
! MBLOCK displacement in KEEP. See comment on KEEP.
! MP Unit for diagnostic messages.
! NB    number of diagonal blocks
! NBLOCK displacement in KEEP. See comment on KEEP.
! NC    is number of columns in packed form for current block.
! NE    is set to the displacement in A/ICN for the beginning of
!       information on the factors.
! NEQ   number of equations in system
! NRF   is number of rows in full form for current block.
! NVAR  number of variables in system
! OLDOMG value of omega from previous iteration. Kept in case it is
!       better.
! OMEGA backward error estimates.
! OM1   value of OMEGA(1)+OMEGA(2) from previous iteration
! OM2   value of OMEGA(1)+OMEGA(2) from current iteration
! TAU   from Arioli, Demmel, and Duff .. used to divide equations

!     .. Externals ..
      EXTERNAL mc71ad
      real(wp) eps
! EPS is the largest real such that 1+EPS is equal to 1.
! MA48D/DD solves block triangular system
! MA50C/CD solves non-blocked system
! MC71A/AD estimates norm of matrix
      INTRINSIC abs, max

! The amount allocated to w can be dependent on input parameters
      allocate(w(4*max(m,n)),iw(max(m,n)),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        return
      endif
! Set streams for errors and warnings
      lp = icntl(1)
      mp = icntl(2)

! Simple data checks
      IF (n<=0 .OR. m<=0) THEN
        info(1) = -1
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9140) m, n
        GO TO 380
      END IF
      IF (job>4 .OR. job<1) THEN
        info(1) = -6
        IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9150) job
        GO TO 380
      END IF
      info(1) = 0

! Partition KEEP and A
      iptrl = m + n
      iptru = iptrl + n
      iptrd = iptru + n
      iptro = iptrd + n + 1
      nblock = iptro + n - 1
      mblock = nblock + 1
      kblock = mblock + 1
      nb = keep(kblock+3)

      ne = keep(iptro+n+1) - 1

      omega(1) = zero
      omega(2) = zero
      error(3) = zero
! Initialize EPS
      eps = epsilon(eps)
! CTAU ... 1000 eps (approx)
      ctau = 1000.*eps

      iqb(1) = 0

      DO 10 i = 1, 7
        icntl5(i) = 0
10    CONTINUE
! Set control for use of BLAS
      icntl5(5) = icntl(5)

      IF (mp>0 .AND. icntl(3)>2) THEN
        WRITE (mp,'(/A/3(A,I8),A,I2/A,L2,A,I7/A,1P,E12.4/A,3I6,2(/A,I6))') &
          ' Entering MA48C/CD with', ' M =', m, '     N =', n, '     LA =', &
          la, '      JOB =', job, '   TRANS =', trans, &
          '      No. of blocks =', nb, '   CNTL(5)    = ', cntl(5), &
          '   ICNTL(1:3) = ', (icntl(i),i=1,3), '   ICNTL(5)   = ', icntl(5), &
          '   ICNTL(9)   = ', icntl(9)
        WRITE (mp,'(A)') ' Permuted matrix by blocks'
        kb = nb
        IF (icntl(3)==3) THEN
          WRITE (mp,'(A)') ' Only first column of up to 10 blocks printed'
          kb = min(10,nb)
        END IF
        WRITE (mp,'(A)') ' Diagonal blocks'
        j1 = 1
        DO 30 jb = 1, kb
          j2 = j1 + keep(nblock+3*jb) - 1
          IF (j1<=j2) WRITE (mp,'(A,I6)') ' Block', jb
          j3 = j2
          IF (icntl(3)==3) j3 = min(j1,j2)
          DO 20 j = j1, j3
            WRITE (mp,'(A,I5,(T13,3(1P,E12.4,I5)))') ' Column', j, &
              (a(i),irn(i),i=keep(iptrd+j),keep(iptrd+j+1)-1)
20        CONTINUE
          j1 = j2 + 1
30      CONTINUE
        IF (keep(iptro+n+1)>keep(iptrd+n+1)) THEN
          WRITE (mp,'(A)') ' Off-diagonal entries'
          j1 = 1
          DO 50 jb = 1, kb
            j2 = j1 + keep(nblock+3*jb) - 1
            j3 = j2
            IF (icntl(3)==3) j3 = min(j1,j2)
            DO 40 j = j1, j3
              IF (keep(iptro+j+1)>keep(iptro+j)) WRITE (mp, &
                '(A,I5,(T13,3(1P,E12.4,I5)))') ' Column', j, &
                (a(i),irn(i),i=keep(iptro+j),keep(iptro+j+1)-1)
40          CONTINUE
            j1 = j2 + 1
50        CONTINUE
        END IF
        WRITE (mp,'(A)') ' Factorized matrix by blocks'
        j1 = 1
        DO 90 jb = 1, kb
          j2 = j1 + keep(nblock+3*jb) - 1
! Jump if triangular block
          IF (keep(mblock+3*jb)<0) GO TO 80
          nc = j2 - j1 + 1
          WRITE (mp,'(A,I6)') ' Block', jb
          k = ne
          IF (jb>1) k = keep(kblock+3*jb) + ne - 1
          IF (keep(iptrl+j1)>keep(iptru+j1)) WRITE (mp, &
            '(A,I5,A,(T18,3(1P,E12.4,I5)))') ' Column', j1, ' of L', &
            (a(k+i),irn(k+i),i=keep(iptru+j1)+1,keep(iptrl+j1))
          IF (icntl(3)==3) GO TO 70
          DO 60 j = j1 + 1, j2
            IF (keep(iptru+j)>keep(iptrl+j-1)) WRITE (mp, &
              '(A,I5,A,(T18,3(1P,E12.4,I5)))') ' Column', j, ' of U', &
              (a(k+i),irn(k+i),i=keep(iptrl+j-1)+1,keep(iptru+j))
            IF (keep(iptru+j)<keep(iptrl+j)) WRITE (mp, &
              '(A,I5,A,(T18,3(1P,E12.4,I5)))') ' Column', j, ' of L', &
              (a(k+i),irn(k+i),i=keep(iptru+j)+1,keep(iptrl+j))
60        CONTINUE
! Full blocks
70        WRITE (mp,'(A)') ' Full block'
          WRITE (mp,'(A)') ' Row indices'
          nrf = irn(k+2)
          k = k + keep(iptrl+j2)
          IF (icntl(3)>3) THEN
            WRITE (mp,9000) (irn(k+i),i=1,nrf)
            WRITE (mp,'(A)') ' Column pivoting information'
            WRITE (mp,9000) (irn(k+i),i=nrf+1,nrf+nc-keep(mblock+3*jb))
            WRITE (mp,'(A)') ' Reals by columns'
            WRITE (mp,9010) (a(k+i),i=1,(nrf)*(nc-keep(mblock+3*jb)))
9000        FORMAT (10I6)
9010        FORMAT (1P,5D12.4)
          ELSE
            WRITE (mp,9000) (irn(k+i),i=1,min(10,nrf))
            WRITE (mp,'(A)') ' Column pivoting information'
            WRITE (mp,9000) (irn(k+i),i=nrf+1,nrf+min(10*onel,nc-keep(mblock+ &
              3*jb)))
            WRITE (mp,'(A)') ' Reals by columns'
            WRITE (mp,9010) &
               (a(k+i),i=1,min(10*onel,(nrf)*(nc-keep(mblock+3*jb))))
          END IF
80        j1 = j2 + 1
90      CONTINUE
        IF (icntl(3)>3) THEN
          WRITE (mp,'(A)') ' Contents of KEEP array'
          WRITE (mp,9020) (keep(i),i=1,m)
          WRITE (mp,9030) (keep(m+i),i=1,n)
9020      FORMAT (' Positions of original rows in the permuted matrix'/(10I6))
9030      FORMAT (' Positions of columns of permuted matrix ','in or','ig', &
            'inal matrix '/(10I6))
          WRITE (mp,'(A)') ' Pointer information from KEEP'
          WRITE (mp,9040) (keep(iptrd+j),j=1,n+1)
9040      FORMAT (' IPTRD ='/(8X,10I6))
          WRITE (mp,9050) (keep(iptro+j),j=1,n+1)
9050      FORMAT (' IPTRO ='/(8X,10I6))
          WRITE (mp,9060) (keep(iptrl+j),j=1,n)
9060      FORMAT (' IPTRL ='/(8X,10I6))
          WRITE (mp,9070) (keep(iptru+j),j=1,n)
9070      FORMAT (' IPTRU ='/(8X,10I6))
          WRITE (mp,'(A)') ' Block structure information from KEEP'
          WRITE (mp,9080) (keep(nblock+3*jb),jb=1,nb)
          WRITE (mp,9090) (keep(mblock+3*jb),jb=1,nb)
          WRITE (mp,9100) (keep(kblock+3*jb),jb=1,nb)
9080      FORMAT (' NBLOCK (order blocks) ='/(8X,10I6))
9090      FORMAT (' MBLOCK (triangular flag and number packed rows) ='/ &
            (8X,10I6))
9100      FORMAT (' KBLOCK (position of beginning of block) ='/(8X,10I6))
          IF (trans) THEN
            WRITE (mp,9110) (rhs(i),i=1,n)
9110        FORMAT (' RHS =  ',1P,5D12.4/(8X,5D12.4))
          ELSE
            WRITE (mp,9110) (rhs(i),i=1,m)
          END IF
        ELSE
          WRITE (mp,'(A)') ' Contents of KEEP array'
          WRITE (mp,9020) (keep(i),i=1,min(10,m))
          WRITE (mp,9030) (keep(m+i),i=1,min(10,n))
          WRITE (mp,'(A)') ' Pointer information from KEEP'
          WRITE (mp,9040) (keep(iptrd+k),k=1,min(10,n+1))
          WRITE (mp,9050) (keep(iptro+k),k=1,min(10,n+1))
          WRITE (mp,9060) (keep(iptrl+j),j=1,min(10,n))
          WRITE (mp,9070) (keep(iptru+j),j=1,min(10,n))
          WRITE (mp,'(A)') ' Block structure information from KEEP'
          WRITE (mp,9080) (keep(nblock+3*jb),jb=1,kb)
          WRITE (mp,9090) (keep(mblock+3*jb),jb=1,kb)
          WRITE (mp,9100) (keep(kblock+3*jb),jb=1,kb)
          IF (trans) THEN
            WRITE (mp,9110) (rhs(i),i=1,min(10,n))
          ELSE
            WRITE (mp,9110) (rhs(i),i=1,min(10,m))
          END IF
        END IF
      END IF

! Apply global permutation to incoming right-hand side
!     and set NEQ and NVAR
      IF (trans) THEN
        neq = n
        nvar = m
        DO 100 i = 1, neq
          w(i) = rhs(keep(m+i))
100     CONTINUE
      ELSE
        neq = m
        nvar = n
        DO 110 i = 1, neq
          w(keep(i)) = rhs(i)
110     CONTINUE
      END IF


! Straight solution requested with no iterative refinement or error
!     estimate.
      IF (job==1) THEN

! Solve system using MA48D/DD or MA50C/CD.
        IF (nb==1 .AND. keep(mblock+3)>=0) THEN
          iblock = keep(mblock+3)
          CALL ma50cd(m,n,icntl5,iqb,iblock,trans,la-ne,a(ne+1), &
            irn(ne+1),keep(iptrl+1),keep(iptru+1),w,x,w(neq+1))
        ELSE
          CALL ma48dd(n,ne,la-ne,a(ne+1),a,irn(ne+1),irn,keep(iptrd+1), &
            keep(iptro+1),nb,keep(nblock+3),keep(iptrl+1),keep(iptru+1),w,x, &
            trans,icntl5,info)
          if (info(1) .eq. -10) go to 380
        END IF
        GO TO 340
      END IF

! Prepare for iterative refinement.

! Set initial estimate of solution to zero
      DO 120 i = 1, nvar
        x(i) = zero
120   CONTINUE
! Save permuted right-hand side for residual calculation
      DO 130 i = 1, neq
        rhs(i) = w(i)
130   CONTINUE


! Iterative refinement loop
! Initialize OM1 in case of problems with optimizing compiler
      om1 = zero
      DO 260 k = 1, icntl(9)

! Solve system using MA48D/DD or MA50C/CD.
        IF (nb==1 .AND. keep(mblock+3)>=0) THEN
          iblock = keep(mblock+3)
          CALL ma50cd(m,n,icntl5,iqb,iblock,trans,la-ne,a(ne+1), &
            irn(ne+1),keep(iptrl+1),keep(iptru+1),w,w(neq+1),w(m+n+1))
        ELSE
          CALL ma48dd(n,ne,la-ne,a(ne+1),a,irn(ne+1),irn,keep(iptrd+1), &
            keep(iptro+1),nb,keep(nblock+3),keep(iptrl+1),keep(iptru+1),w, &
            w(neq+1),trans,icntl5,info)
          if (info(1) .eq. -10) go to 380
        END IF
! Update solution
        DO 140 i = 1, nvar
          x(i) = x(i) + w(neq+i)
140     CONTINUE

! Calculate residual using information in A,IRN

        DO 150 i = 1, neq
! Residual  .. b-Ax
          w(i) = rhs(i)
! |A||x|
          w(neq+i) = zero
! Sum |a  |, j=1,N (= ||A  ||        )
!       ij               i.  infinity
          w(2*neq+i) = zero
150     CONTINUE
        IF (trans) THEN
          DO 180 j = 1, n
!DIR$ IVDEP
            DO 160 jj = keep(iptrd+j), keep(iptrd+j+1) - 1
              i = irn(jj)
              w(j) = w(j) - a(jj)*x(i)
              w(neq+j) = w(neq+j) + abs(a(jj)*x(i))
              w(2*neq+j) = w(2*neq+j) + abs(a(jj))
160         CONTINUE
!DIR$ IVDEP
            DO 170 jj = keep(iptro+j), keep(iptro+j+1) - 1
              i = irn(jj)
              w(j) = w(j) - a(jj)*x(i)
              w(neq+j) = w(neq+j) + abs(a(jj)*x(i))
              w(2*neq+j) = w(2*neq+j) + abs(a(jj))
170         CONTINUE
180       CONTINUE
        ELSE
          DO 210 j = 1, n
!DIR$ IVDEP
            DO 190 jj = keep(iptrd+j), keep(iptrd+j+1) - 1
              i = irn(jj)
              w(i) = w(i) - a(jj)*x(j)
              w(neq+i) = w(neq+i) + abs(a(jj)*x(j))
              w(2*neq+i) = w(2*neq+i) + abs(a(jj))
190         CONTINUE
!DIR$ IVDEP
            DO 200 jj = keep(iptro+j), keep(iptro+j+1) - 1
              i = irn(jj)
              w(i) = w(i) - a(jj)*x(j)
              w(neq+i) = w(neq+i) + abs(a(jj)*x(j))
              w(2*neq+i) = w(2*neq+i) + abs(a(jj))
200         CONTINUE
210       CONTINUE
        END IF
! Calculate max-norm of solution
        dxmax = zero
        DO 220 i = 1, nvar
          dxmax = max(dxmax,abs(x(i)))
220     CONTINUE
! Calculate also omega(1) and omega(2)
! tau is (||A  ||         ||x||   + |b| )*n*1000*epsilon
!            i.  infinity      max     i
        omega(1) = zero
        omega(2) = zero
        DO 230 i = 1, neq
          tau = (w(2*neq+i)*dxmax+abs(rhs(i)))*nvar*ctau
          IF ((w(neq+i)+abs(rhs(i)))>tau) THEN
! |Ax-b| /(|A||x| + |b|)
!       i               i
            omega(1) = max(omega(1),abs(w(i))/(w(neq+i)+abs(rhs(i))))
            iw(i) = 1
          ELSE
! TAU will be zero if all zero row in A, for example
            IF (tau>zero) THEN
! |Ax-b| /(|A||x| + ||A  ||        ||x||   )
!       i        i     i.  infinity     max
              omega(2) = max(omega(2),abs(w(i))/(w(neq+i)+w(2*neq+i)*dxmax))
            END IF
            iw(i) = 2
          END IF
230     CONTINUE

! Exit if iterative refinement not being performed
        IF (job==2) GO TO 340

!  Stop the calculations if the backward error is small

        om2 = omega(1) + omega(2)
! Jump if converged
! Statement changed because IBM SP held quantities in registers
!        IF ((OM2+ONE).LE.ONE) GO TO 270
        IF (om2<=eps) GO TO 270

!  Check the convergence.

        IF (k>1 .AND. om2>om1*cntl(5)) THEN
!  Stop if insufficient decrease in omega.
          IF (om2>om1) THEN
! Previous estimate was better ... reinstate it.
            omega(1) = oldomg(1)
            omega(2) = oldomg(2)
            DO 240 i = 1, nvar
              x(i) = w(3*neq+i)
240         CONTINUE
          END IF
          GO TO 270
        END IF
! Hold current estimate in case needed later
        DO 250 i = 1, nvar
          w(3*neq+i) = x(i)
250     CONTINUE
        oldomg(1) = omega(1)
        oldomg(2) = omega(2)
        om1 = om2
260   CONTINUE
! End of iterative refinement loop.
!!!
! Can only happen when IR fails ... have eyeballed this and
! tested it in practice.
      info(1) = -8
      IF (lp>0 .AND. icntl(3)>=1) WRITE (lp,9170) info(1), icntl(9)
      GO TO 340

270   IF (job<=3) GO TO 340
      IF (m/=n) GO TO 340

! Calculate condition numbers and estimate of the error.

!  Condition numbers obtained through use of norm estimation
!     routine MC71A/AD.

!  Initializations

      lcond(1) = .FALSE.
      lcond(2) = .FALSE.
      DO 280 i = 1, neq
        IF (iw(i)==1) THEN
          w(i) = w(neq+i) + abs(rhs(i))
! |A||x| + |b|
          w(neq+i) = zero
          lcond(1) = .TRUE.
        ELSE
! |A||x| + ||A  ||        ||x||
!             i.  infinity     max

          w(neq+i) = w(neq+i) + w(2*neq+i)*dxmax
          w(i) = zero
          lcond(2) = .TRUE.
        END IF
280   CONTINUE

!  Compute the estimate of COND

      kase = 0
      DO 330 k = 1, 2
        IF (lcond(k)) THEN
! MC71A/AD has its own built in limit to the number of iterations
!    allowed. It is this limit that will be used to terminate the
!    following loop.
          DO 310 kk = 1, 40
! MC71A/AD calculates norm of matrix
! We are calculating the infinity norm of INV(A).W
            CALL mc71ad(n,kase,w(3*neq+1),cond(k),rhs,iw,keep71)

!  KASE = 0........ Computation completed
!  KASE = 1........ W * INV(TRANSPOSE(A)) * Y
!  KASE = 2........ INV(A) * W * Y
!                   W is W/W(NEQ+1) .. Y is W(3*NEQ+1)

            IF (kase==0) GO TO 320
            IF (kase==1) THEN
! Solve system using MA48D/DD or MA50C/CD.
              IF (nb==1 .AND. keep(mblock+3)>=0) THEN
          iblock = keep(mblock+3)
                CALL ma50cd(m,n,icntl5,iqb,iblock, .NOT. trans,la-ne, &
                  a(ne+1),irn(ne+1),keep(iptrl+1),keep(iptru+1),w(3*neq+1), &
                  w(2*neq+1),rhs)
              ELSE
                CALL ma48dd(n,ne,la-ne,a(ne+1),a,irn(ne+1),irn,keep(iptrd+1), &
                  keep(iptro+1),nb,keep(nblock+3),keep(iptrl+1),keep(iptru+1), &
                  w(3*neq+1),w(2*neq+1), .NOT. trans,icntl5,info)
                 if (info(1) .eq. -10) go to 380
              END IF

              DO 290 i = 1, m
                w(3*neq+i) = w((k-1)*neq+i)*w(2*neq+i)
290           CONTINUE
            END IF
            IF (kase==2) THEN
              DO 300 i = 1, n
                w(2*neq+i) = w((k-1)*neq+i)*w(3*neq+i)
300           CONTINUE
! Solve system using MA48D/DD or MA50C/CD.
              IF (nb==1 .AND. keep(mblock+3)>=0) THEN
          iblock = keep(mblock+3)
                CALL ma50cd(m,n,icntl5,iqb,iblock,trans,la-ne,a(ne+1), &
                  irn(ne+1),keep(iptrl+1),keep(iptru+1),w(2*neq+1),w(3*neq+1), &
                  rhs)
              ELSE
                CALL ma48dd(n,ne,la-ne,a(ne+1),a,irn(ne+1),irn,keep(iptrd+1), &
                  keep(iptro+1),nb,keep(nblock+3),keep(iptrl+1),keep(iptru+1), &
                  w(2*neq+1),w(3*neq+1),trans,icntl5,info)
                 if (info(1) .eq. -10) go to 380
              END IF
            END IF
310       CONTINUE
!!!
! Can only happen when MC71 does not converge in 40 iterations.
! Have eyeballed this but never invoked it.
          info(1) = -9
          IF (lp/=0 .AND. icntl(3)>=1) WRITE (lp,9160)
          GO TO 340
320       IF (dxmax>zero) cond(k) = cond(k)/dxmax
          error(3) = error(3) + omega(k)*cond(k)
        END IF
330   CONTINUE

! Permute solution vector
340   DO 350 i = 1, nvar
        w(i) = x(i)
350   CONTINUE
      IF ( .NOT. trans) THEN
        DO 360 i = 1, nvar
          x(keep(m+i)) = w(i)
360     CONTINUE
      ELSE
        DO 370 i = 1, nvar
          x(i) = w(keep(i))
370     CONTINUE
      END IF
      IF (job>=2) THEN
        error(1) = omega(1)
        error(2) = omega(2)
      END IF

      IF (mp>0 .AND. icntl(3)>2) THEN
        WRITE (mp,'(/A,I6)') ' Leaving MA48C/CD with INFO(1) =', info(1)
        IF (job>1) THEN
          k = 2
          IF (job==4 .AND. info(1)/=-9) k = 3
          WRITE (mp,9120) (error(i),i=1,k)
9120      FORMAT (' ERROR =',1P,3D12.4)
        END IF
        IF (icntl(3)>3) THEN
          WRITE (mp,9130) (x(i),i=1,nvar)
9130      FORMAT (' X =    ',1P,5D12.4:/(8X,5D12.4))
        ELSE
          WRITE (mp,9130) (x(i),i=1,min(10,nvar))
        END IF
      END IF
380   deallocate(w,iw,stat=stat)
      RETURN

9140  FORMAT (' Error return from MA48C/CD because M =',I10,' and N =',I10)
9150  FORMAT (' Error return from MA48C/CD because ','JOB = ',I10)
9160  FORMAT (' Error return from MA48C/CD because of ','error in MC71', &
        'A/AD'/' ERROR(3) not calculated')
9170  FORMAT (' Error return from MA48C/CD because of ','nonconvergenc', &
        'e of iterative refinement'/' Error INFO(1) = ',I2,'  wit','h ICNTL', &
        '(9) = ',I10)
    END subroutine ma48cd


    SUBROUTINE ma48dd(n,ne,la,a,aa,irn,irna,iptrd,iptro,nb,iblock,iptrl,iptru, &
        rhs,x,trans,icntl5,info)
! Solve linear system, using data provided by MA48B/BD.

!     .. Arguments ..
      INTEGER n, nb
      integer(long) :: ne, la
      integer (long) :: info(20)
      real(wp) a(la), aa(ne)
      INTEGER(long) :: irn(la), irna(ne)
      integer(long) :: iptrd(n+1), iptro(n+1)
      integer(long) :: iblock(3,nb)
      integer(long) :: iptrl(n), iptru(n)
      real(wp) rhs(n), x(n)
      LOGICAL trans
      INTEGER icntl5(20)
      real(wp), allocatable :: w(:)

! N must be set by the user to the number of columns in the matrix.
!      It is not altered by the subroutine.
! NE must be set by the user to the size of arrays AA and IRNA.
!      It is not altered by the subroutine.
! LA must be set by the user to the size of arrays A and IRN.
!      It is not altered by the subroutine.
! A    must be set left unchanged from the last call to MA48B/BD.
!      It holds the factorization of the block diagonal part
!      (excluding triangular blocks).
!      It is not altered by the subroutine.
! AA   must be set left unchanged from the last call to MA48B/BD.
!      It holds the original matrix in permuted form.
!      It is not altered by the subroutine.
! IRN  must be set left unchanged from the last call to MA48B/BD.
!      It holds the row indices of the factorization in A.
!      It is not altered by the subroutine.
! IRNA must be set left unchanged from the last call to MA48B/BD.
!      It holds the row indices of the original matrix in permuted form.
!      It is not altered by the subroutine.
! IPTRD must be as on return from MA48B/BD. IPTRD(j) holds the position
!      in IRNA of the start of the block diagonal part of column j.
!      IPTRD(n+1) holds the position immediately after the end of
!      column n.
!      It is not altered by the subroutine.
! IPTRO must be as on return from MA48A/AD. IPTRO(j) holds the position
!      in IRNA of the start of the off block diagonal part of column j.
!      IPTRO(n+1) holds the position immediately after the end of
!      column n.
!      It is not altered by the subroutine.
! NB must be set by the user to the second dimension of IBLOCK.
!      It is not altered by the subroutine.
! IBLOCK must be as on return from MA48B/BD.  IBLOCK(1,k) holds the
!      order of diagonal block k, k=1,2,...  IBLOCK(2,k) holds the
!      number of rows held in packed storage when
!      processing block k, or a negative value for triangular blocks.
!      IBLOCK(3,1) holds the number of blocks and IBLOCK(3,k) holds the
!      position in the factorization of the start of block k, k =
!      2,3,...  IBLOCK is not altered by the subroutine.
! IPTRL must be unchanged since the last call to MA48B/BD.
!      It holds pointers to the
!      columns of the lower-triangular part of the factorization.
!      It is not altered by the subroutine.
! IPTRU must be unchanged since the last call to MA48B/BD.
!      It holds pointers to the
!      columns of the upper-triangular part of the factorization.
!      It is not altered by the subroutine.
! RHS  must be set by the user to contain the right-hand side of
!      the equations to be solved.
!      It is used as workspace.
! X    need not be set by the user.  On exit, it will contain the
!      solution vector.
! TRANS must be set by the user to indicate whether coefficient matrix
!      is A (TRANS=.FALSE.) or A transpose (TRANS=.TRUE.).
!      It is not altered by the subroutine.
! ICNTL5 passed to MA50C/CD to correspond to dummy argument ICNTL.
! W    is a workarray.


!     .. Local variables ..
      integer :: nc, np
      integer(long) :: i, iqb(1), j, jb, jj, j1, k1, k2, numb
! I     row index
! IFLAG error flag from MA50CD .. will never be set
! IQB   is passed to MA50C/CD to indicate that no column permutation
!       is used.
! J     column index
! JB    block index.
! JJ    running index for column.
! J1    position of beginning of block
! K1    index of first column in block
! K2    index of last column in block
! NC    number of columns in block
! NUMB  number of diagonal blocks

!     .. Externals ..

      allocate(w(n),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        return
      endif

      iqb(1) = 0
      numb = iblock(3,1)
      IF ( .NOT. trans) THEN
! Solve system using block structure information and calls to MA50C
!     for each diagonal block.
! System is block upper triangular.
        k1 = n + 1
        DO 50 jb = numb, 1, -1
          nc = iblock(1,jb)
          k2 = k1 - 1
          k1 = k1 - nc
          IF (iblock(2,jb)<0) THEN
! Process triangular block
            DO 20 j = k2, k1, -1
              x(j) = rhs(j)/aa(iptrd(j))
!DIR$ IVDEP
              DO 10 jj = iptrd(j) + 1, iptrd(j+1) - 1
                i = irna(jj)
                rhs(i) = rhs(i) - aa(jj)*x(j)
10            CONTINUE
20          CONTINUE
          ELSE
            j1 = 1
            IF (jb>1) j1 = iblock(3,jb)
            np = iblock(2,jb)
            CALL ma50cd(nc,nc,icntl5,iqb,np,trans,la+1-j1,a(j1), &
              irn(j1),iptrl(k1),iptru(k1),rhs(k1),x(k1),w)
          END IF
          IF (jb==1) GO TO 50
! Substitution using off-diagonal block
          DO 40 j = k1, k2
!DIR$ IVDEP
            DO 30 jj = iptro(j), iptro(j+1) - 1
              i = irna(jj)
              rhs(i) = rhs(i) - aa(jj)*x(j)
30          CONTINUE
40        CONTINUE
50      CONTINUE
      ELSE
! Solve system using block structure information and calls to MA50C
!     for each diagonal block.
! System is block lower triangular.
        k2 = 0
        DO 100 jb = 1, numb
          nc = iblock(1,jb)
          k1 = k2 + 1
          k2 = k2 + nc
          IF (jb>1) THEN
! Substitution using off-diagonal block
            DO 70 j = k1, k2
              DO 60 jj = iptro(j), iptro(j+1) - 1
                i = irna(jj)
                rhs(j) = rhs(j) - aa(jj)*x(i)
60            CONTINUE
70          CONTINUE
          END IF
          IF (iblock(2,jb)<0) THEN
! Process triangular block
            DO 90 j = k1, k2
              DO 80 jj = iptrd(j) + 1, iptrd(j+1) - 1
                i = irna(jj)
                rhs(j) = rhs(j) - aa(jj)*x(i)
80            CONTINUE
              x(j) = rhs(j)/aa(iptrd(j))
90          CONTINUE
          ELSE
            j1 = 1
            IF (jb>1) j1 = iblock(3,jb)
            np = iblock(2,jb)
            CALL ma50cd(nc,nc,icntl5,iqb,np,trans,la+1-j1,a(j1), &
              irn(j1),iptrl(k1),iptru(k1),rhs(k1),x(k1),w)
          END IF
100     CONTINUE
      END IF

      deallocate(w,stat=stat)

      RETURN
    END subroutine ma48dd

    SUBROUTINE ma48id(cntl,icntl)
! Set default values for the control arrays.

      real(wp) cntl(10)
      INTEGER icntl(20)

! CNTL  is a real array of length 10.
!     CNTL(1)  If this is set to a value less than or equal to one, full
!       matrix processing will be used by MA50A/AD  when the density of
!       the reduced matrix reaches CNTL(1).
!     CNTL(2) determines the balance used by MA50A/AD and MA50B/BD
!       between pivoting for sparsity and for stability, values near
!       zero emphasizing sparsity and values near one emphasizing
!       stability.
!     CNTL(3) If this is set to a positive value, any entry whose
!       modulus is less than CNTL(3) will be dropped from the factors
!       calculated by MA50A/AD. The factorization will then require
!       less storage but will be inaccurate.
!     CNTL(4)  If this is set to a positive value, any entry whose
!       modulus is less than CNTL(4) will be regarded as zero from
!       the point of view of rank.
!     CNTL(5) is used in convergence test for termination of iterative
!       refinement.  Iteration stops if successive omegas do not
!       decrease by at least this factor.
!     CNTL(6) is set to the factor by which storage is increased if
!       arrays have to be reallocated.
!     CNTL(7:10) are not used.
! ICNTL is an integer array of length 20.
!     ICNTL(1)  must be set to the stream number for error messages.
!       A value less than 1 suppresses output.
!     ICNTL(2) must be set to the stream number for diagnostic output.
!       A value less than 1 suppresses output.
!     ICNTL(3) must be set to control the amount of output:
!       0 None.
!       1 Error messages only.
!       2 Error and warning messages.
!       3 As 2, plus scalar parameters and a few entries of array
!         parameters on entry and exit.
!       4 As 2, plus all parameters on entry and exit.
!     ICNTL(4)  If set to a positive value, the pivot search by MA50A/AD
!       is limited to ICNTL(4) columns. This may result in different
!       fill-in and execution time but could give faster execution.
!     ICNTL(5) The block size to be used for full-matrix processing.
!     ICNTL(6) is the minimum size for a block of the block triangular
!       form.
!     ICNTL(7) If not equal to 0, abort when structurally rank deficient
!       matrix found.
!     ICNTL(8) If set to a value other than zero and JOB = 1 or 3 on
!       entry to MA48A/AD, columns with IW flagged 0 are placed at
!       the end of their respective blocks in the first factorization
!       and the remaining columns are assumed unchanged in subsequent
!       factorizations. If set to a value other than zero and JOB = 2,
!       columns before the first 0 entry of IW are assumed unchanged in
!       subsequent factorizations.  On entry to MA48B/BD, the number
!       of columns that can change in each block is held in array KEEP.
!     ICNTL(9) is the limit on the number of iterative refinements
!        allowed by MA48C/CD
!     ICNTL(10) has default value 0. If set to 1, there is an immediate
!       return from MA48B/BD if LA is too small, without continuing the
!       decomposition to compute the size necessary.
!     ICNTL(11) has default value 0. If set to 1 on a JOB=2 call to
!       MA48B/BD and the entries in one of the blocks on the diagonal
!       are unsuitable for the pivot sequence chosen on the previous
!       call, the block is refactorized as on a JOB=1 call.
!     ICNTL(12:20) are not used.

      INTEGER i

      DO 10 i = 3, 10
        cntl(i) = 0.0D0
10    CONTINUE
      cntl(1) = 0.5D0
      cntl(2) = 0.1D0
      cntl(5) = 0.5D0
      cntl(6) = 2.0D0
      icntl(1) = 6
      icntl(2) = 6
      icntl(3) = 2
      icntl(4) = 3
      icntl(5) = 32
      icntl(6) = 1
      icntl(7) = 1
      icntl(8) = 0
      icntl(9) = 10
      DO 20 i = 10, 20
        icntl(i) = 0
20    CONTINUE

    END subroutine ma48id

! COPYRIGHT (c) 1977 AEA Technology
! Original date 8 Oct 1992
!######8/10/92 Toolpack tool decs employed.
!######8/10/92 D version created by name change only.
! 13/3/02 Cosmetic changes applied to reduce single/double differences
!
! 12th July 2004 Version 1.0.0. Version numbering added.

      SUBROUTINE mc21ad(N,ICN,LICN,IP,LENR,IPERM,NUMNZ,info)
!     .. Scalar Arguments ..
      INTEGER(i4) :: N,NUMNZ
      INTEGER(long) :: LICN,ICN(LICN)
!     ..
!     .. Array Arguments ..
      INTEGER IPERM(N),LENR(N)
      INTEGER(long) :: IP(N),info(20)
!     ..
!     .. External Subroutines ..
!     ..
!     .. Executable Statements ..
      CALL mc21bd(N,ICN,LICN,IP,LENR,IPERM,NUMNZ,info)
      RETURN
!
      END SUBROUTINE
      SUBROUTINE mc21bd(N,ICN,LICN,IP,LENR,IPERM,NUMNZ,info)
!   PR(I) IS THE PREVIOUS ROW TO I IN THE DEPTH FIRST SEARCH.
! IT IS USED AS A WORK ARRAY IN THE SORTING ALGORITHM.
!   ELEMENTS (IPERM(I),I) I=1, ... N  ARE NON-ZERO AT THE END OF THE
! ALGORITHM UNLESS N ASSIGNMENTS HAVE NOT BEEN MADE.  IN WHICH CASE
! (IPERM(I),I) WILL BE ZERO FOR N-NUMNZ ENTRIES.
!   CV(I) IS THE MOST RECENT ROW EXTENSION AT WHICH COLUMN I
! WAS VISITED.
!   ARP(I) IS ONE LESS THAN THE NUMBER OF NON-ZEROS IN ROW I
! WHICH HAVE NOT BEEN SCANNED WHEN LOOKING FOR A CHEAP ASSIGNMENT.
!   OUT(I) IS ONE LESS THAN THE NUMBER OF NON-ZEROS IN ROW I
! WHICH HAVE NOT BEEN SCANNED DURING ONE PASS THROUGH THE MAIN LOOP.

!   INITIALIZATION OF ARRAYS.
!     .. Scalar Arguments ..
      INTEGER(i4) :: N,NUMNZ
      INTEGER(long) :: LICN,ICN(LICN),info(20)
!     ..
!     .. Array Arguments ..
      INTEGER IPERM(N),LENR(N)
      INTEGER(long) :: IP(N)
!     ..
!     .. Local Scalars ..
      INTEGER I,IOUTK,J,J1,JORD,K,KK
      integer stat
      INTEGER(long) :: II,IN1,IN2

      integer,allocatable :: PR(:),ARP(:),CV(:),OUT(:)

      allocate(pr(n),arp(n),cv(n),out(n),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        return
      endif
!     ..
!     .. Executable Statements ..
      DO 10 I = 1,N
        ARP(I) = LENR(I) - 1
        CV(I) = 0
        IPERM(I) = 0
   10 CONTINUE
      NUMNZ = 0


!   MAIN LOOP.
!   EACH PASS ROUND THIS LOOP EITHER RESULTS IN A NEW ASSIGNMENT
! OR GIVES A ROW WITH NO ASSIGNMENT.
      DO 100 JORD = 1,N
        J = JORD
        PR(J) = -1
        DO 70 K = 1,JORD
! LOOK FOR A CHEAP ASSIGNMENT
          IN1 = ARP(J)
          IF (IN1.LT.0) GO TO 30
          IN2 = IP(J) + LENR(J) - 1
          IN1 = IN2 - IN1
          DO 20 II = IN1,IN2
            I = ICN(II)
            IF (IPERM(I).EQ.0) GO TO 80
   20     CONTINUE
!   NO CHEAP ASSIGNMENT IN ROW.
          ARP(J) = -1
!   BEGIN LOOKING FOR ASSIGNMENT CHAIN STARTING WITH ROW J.
   30     CONTINUE
          OUT(J) = LENR(J) - 1
! INNER LOOP.  EXTENDS CHAIN BY ONE OR BACKTRACKS.
          DO 60 KK = 1,JORD
            IN1 = OUT(J)
            IF (IN1.LT.0) GO TO 50
            IN2 = IP(J) + LENR(J) - 1
            IN1 = IN2 - IN1
! FORWARD SCAN.
            DO 40 II = IN1,IN2
              I = ICN(II)
              IF (CV(I).EQ.JORD) GO TO 40
!   COLUMN I HAS NOT YET BEEN ACCESSED DURING THIS PASS.
              J1 = J
              J = IPERM(I)
              CV(I) = JORD
              PR(J) = J1
              OUT(J1) = IN2 - II - 1
              GO TO 70

   40       CONTINUE

!   BACKTRACKING STEP.
   50       CONTINUE
            J = PR(J)
            IF (J.EQ.-1) GO TO 100
   60     CONTINUE

   70   CONTINUE

!   NEW ASSIGNMENT IS MADE.
   80   CONTINUE
        IPERM(I) = J
        ARP(J) = IN2 - II - 1
        NUMNZ = NUMNZ + 1
        DO 90 K = 1,JORD
          J = PR(J)
          IF (J.EQ.-1) GO TO 100
          II = IP(J) + LENR(J) - OUT(J) - 2
          I = ICN(II)
          IPERM(I) = J
   90   CONTINUE

  100 CONTINUE

!   IF MATRIX IS STRUCTURALLY SINGULAR, WE NOW COMPLETE THE
! PERMUTATION IPERM.
      IF (NUMNZ.EQ.N) GO TO 200
      DO 110 I = 1,N
        ARP(I) = 0
  110 CONTINUE
      K = 0
      DO 130 I = 1,N
        IF (IPERM(I).NE.0) GO TO 120
        K = K + 1
        OUT(K) = I
        GO TO 130

  120   CONTINUE
        J = IPERM(I)
        ARP(J) = I
  130 CONTINUE
      K = 0
      DO 140 I = 1,N
        IF (ARP(I).NE.0) GO TO 140
        K = K + 1
        IOUTK = OUT(K)
        IPERM(IOUTK) = I
  140 CONTINUE
  
  200 deallocate(cv,out,pr,arp,stat=stat)

      RETURN

      END  subroutine
! COPYRIGHT (c) 1976 AEA Technology
! Original date 21 Jan 1993
!       Toolpack tool decs employed.
! Double version of MC13D (name change only)
! 10 August 2001 DOs terminated with CONTINUE
! 13/3/02 Cosmetic changes applied to reduce single/double differences
!
! 12th July 2004 Version 1.0.0. Version numbering added.

      SUBROUTINE mc13dd(N,ICN,LICN,IP,LENR,IOR,IB,NUM,info)
!     .. Scalar Arguments ..
      INTEGER N,NUM
      INTEGER(long) :: LICN,ICN(LICN),info(20)

!     .. Array Arguments ..
      INTEGER IB(N),LENR(N)
! IOR is only long because of calling program (keep)
      INTEGER(long) :: IP(N),IOR(N)

!     .. Executable Statements ..
      CALL mc13ed(N,ICN,LICN,IP,LENR,IOR,IB,NUM,info)
      RETURN

      END SUBROUTINE
      SUBROUTINE mc13ed(N,ICN,LICN,IP,LENR,ARP,IB,NUM,info)
!
! ARP(I) IS ONE LESS THAN THE NUMBER OF UNSEARCHED EDGES LEAVING
!     NODE I.  AT THE END OF THE ALGORITHM IT IS SET TO A
!     PERMUTATION WHICH PUTS THE MATRIX IN BLOCK LOWER
!     TRIANGULAR FORM.
! IB(I) IS THE POSITION IN THE ORDERING OF THE START OF THE ITH
!     BLOCK.  IB(N+1-I) HOLDS THE NODE NUMBER OF THE ITH NODE
!     ON THE STACK.
! LOWL(I) IS THE SMALLEST STACK POSITION OF ANY NODE TO WHICH A PATH
!     FROM NODE I HAS BEEN FOUND.  IT IS SET TO N+1 WHEN NODE I
!     IS REMOVED FROM THE STACK.
! NUMB(I) IS THE POSITION OF NODE I IN THE STACK IF IT IS ON
!     IT, IS THE PERMUTED ORDER OF NODE I FOR THOSE NODES
!     WHOSE FINAL POSITION HAS BEEN FOUND AND IS OTHERWISE ZERO.
! PREV(I) IS THE NODE AT THE END OF THE PATH WHEN NODE I WAS
!     PLACED ON THE STACK.


!   ICNT IS THE NUMBER OF NODES WHOSE POSITIONS IN FINAL ORDERING HAVE
!     BEEN FOUND.
!     .. Scalar Arguments ..
      INTEGER N,NUM
      INTEGER(long) :: LICN,ICN(LICN),info(20)
!     ..
!     .. Array Arguments ..
      INTEGER IB(N),LENR(N)
      INTEGER(long) :: IP(N),ARP(N)
!     ..
!     .. Local Scalars ..
      INTEGER DUMMY,I,I1,I2,ICNT,II,ISN,IST,IST1,IV,IW,J,K,LCNT,NNM1,STP

      integer,allocatable :: lowl(:),numb(:),prev(:)
      integer :: stat
!     ..
!     .. Intrinsic Functions ..
      INTRINSIC MIN
!     ..
!     .. Executable Statements ..

      allocate(lowl(n),numb(n),prev(n),stat=stat)
      if (stat .ne. 0) then
        info(1) = -10
        return
      endif
      ICNT = 0
! NUM IS THE NUMBER OF BLOCKS THAT HAVE BEEN FOUND.
      NUM = 0
      NNM1 = N + N - 1

! INITIALIZATION OF ARRAYS.
      DO 20 J = 1,N
        NUMB(J) = 0
        ARP(J) = LENR(J) - 1
   20 CONTINUE


      DO 120 ISN = 1,N
! LOOK FOR A STARTING NODE
        IF (NUMB(ISN).NE.0) GO TO 120
        IV = ISN
! IST IS THE NUMBER OF NODES ON THE STACK ... IT IS THE STACK POINTER.
        IST = 1
! PUT NODE IV AT BEGINNING OF STACK.
        LOWL(IV) = 1
        NUMB(IV) = 1
        IB(N) = IV

! THE BODY OF THIS LOOP PUTS A NEW NODE ON THE STACK OR BACKTRACKS.
        DO 110 DUMMY = 1,NNM1
          I1 = ARP(IV)
! HAVE ALL EDGES LEAVING NODE IV BEEN SEARCHED.
          IF (I1.LT.0) GO TO 60
          I2 = IP(IV) + LENR(IV) - 1
          I1 = I2 - I1
!
! LOOK AT EDGES LEAVING NODE IV UNTIL ONE ENTERS A NEW NODE OR
!     ALL EDGES ARE EXHAUSTED.
          DO 50 II = I1,I2
            IW = ICN(II)
! HAS NODE IW BEEN ON STACK ALREADY.
            IF (NUMB(IW).EQ.0) GO TO 100
! UPDATE VALUE OF LOWL(IV) IF NECESSARY.
            LOWL(IV) = MIN(LOWL(IV),LOWL(IW))
   50     CONTINUE
!
! THERE ARE NO MORE EDGES LEAVING NODE IV.
          ARP(IV) = -1
! IS NODE IV THE ROOT OF A BLOCK.
   60     IF (LOWL(IV).LT.NUMB(IV)) GO TO 90

! ORDER NODES IN A BLOCK.
          NUM = NUM + 1
          IST1 = N + 1 - IST
          LCNT = ICNT + 1
! PEEL BLOCK OFF THE TOP OF THE STACK STARTING AT THE TOP AND
!     WORKING DOWN TO THE ROOT OF THE BLOCK.
          DO 70 STP = IST1,N
            IW = IB(STP)
            LOWL(IW) = N + 1
            ICNT = ICNT + 1
            NUMB(IW) = ICNT
            IF (IW.EQ.IV) GO TO 80
   70     CONTINUE
   80     IST = N - STP
          IB(NUM) = LCNT
! ARE THERE ANY NODES LEFT ON THE STACK.
          IF (IST.NE.0) GO TO 90
! HAVE ALL THE NODES BEEN ORDERED.
          IF (ICNT.LT.N) GO TO 120
          GO TO 130

! BACKTRACK TO PREVIOUS NODE ON PATH.
   90     IW = IV
          IV = PREV(IV)
! UPDATE VALUE OF LOWL(IV) IF NECESSARY.
          LOWL(IV) = MIN(LOWL(IV),LOWL(IW))
          GO TO 110

! PUT NEW NODE ON THE STACK.
  100     ARP(IV) = I2 - II - 1
          PREV(IW) = IV
          IV = IW
          IST = IST + 1
          LOWL(IV) = IST
          NUMB(IV) = IST
          K = N + 1 - IST
          IB(K) = IV
  110   CONTINUE

  120 CONTINUE


! PUT PERMUTATION IN THE REQUIRED FORM.
  130 DO 140 I = 1,N
        II = NUMB(I)
        ARP(II) = I
  140 CONTINUE


      deallocate(lowl,numb,prev,stat=stat)

      RETURN

      END subroutine
end module hsl_ma48_ma48_internal_double

module hsl_ma48_ma51_internal_double
   implicit none

! This module is based on ma51 1.0.0 (12 July 2004)

   private
   public :: ma51ad, ma51cd
   public :: ma51bd, ma51dd ! public for unit tests

   integer, parameter :: wp = kind(0.0d0)
   integer, parameter :: long = selected_int_kind(18) ! Long integer

contains

    SUBROUTINE ma51ad(m,n,la,irn,keep,rank,rows,cols,w)

!     This is for use in conjunction with the MA48 routines
!     for solving full sets of linear equations. It must follow
!     a call of MA48B/BD, and the values of the arguments
!     M,N,LA,IRN,KEEP must be unchanged.
!     It identifies which equations are ignored when solving Ax = b
!     and which solution components are always set to zero.
!     There are such equations and/or components in the singular or
!     rectangular case.


!     .. Arguments ..
      integer(long) :: la, keep(*), irn(la)
      integer :: m, n, rank, rows(m), cols(n), w(max(m,n))

! M must be set by the user to the number of rows in the matrix.
!      It is not altered by the subroutine. Restriction: M > 0.
! N must be set by the user to the number of columns in the matrix.
!      It is not altered by the subroutine. Restriction: N > 0.
! LA must be set by the user to the size of array IRN.
!      It is not altered by the subroutine.
! IRN  must be left unchanged from the last call to MA48B/BD.
!      It holds the row indices of the factorization in A and
!      the row indices of the original matrix in permuted form.
!      It is not altered by the subroutine.
! KEEP must be as on return from MA48B/BD.
!      It is not altered by the subroutine.
! RANK is an integer variable that need not be set on input.
!     On exit, it holds the rank computed by MA50.
! ROWS is an integer array that need not be set on input.
!      On exit, it holds a permutation. The indices of the rows that
!      are taken into account when solving Ax = b are ROWS(i),
!      i <= RANK.
! COLS is an integer array that need not be set on input.
!      On exit, it holds a permutation. The indices of the columns that
!      are taken into account when solving Ax = b are COLS(j),
!      j <= RANK.
! W is an integer workarray of length max(M,N).

!     .. Local variables ..
      integer :: i, iqb(1), j, jb, j1, k1, k2, &
        nb, nc, np, nr, rankb
      integer(long) :: iptrd, iptrl, iptro, iptru, &
        kblock, mblock, nblock, ne

      iqb(1) = 0

! Partition KEEP
      iptrl = m + n
      iptru = iptrl + n
      iptrd = iptru + n
      iptro = iptrd + n + 1
      nblock = iptro + n - 1
      mblock = nblock + 1
      kblock = mblock + 1
      nb = keep(kblock+3)
      ne = keep(iptro+n+1) - 1


      k2 = 0
      rank = 0
      DO 20 jb = 1, nb
        nc = keep(nblock+3*jb)
        nr = nc
        IF (nb==1) nr = m
        k1 = k2 + 1
        k2 = k2 + nc
        np = keep(mblock+3*jb)
        IF (np<0) THEN
! Triangular block
          DO 10 j = k1, k2
            rows(j) = 1
            cols(j) = 1
10        CONTINUE
          rank = rank + nc
        ELSE
          j1 = 1
          IF (jb>1) j1 = keep(kblock+3*jb)
          CALL ma51zd(nr,nc,iqb,np,la+1-ne-j1,irn(ne+j1),keep(iptrl+k1), &
            keep(iptru+k1),rankb,rows(k1),cols(k1),w)
          rank = rank + rankb
        END IF
20    CONTINUE

! Construct final row permutation
      DO 30 i = 1, m
        w(i) = rows(keep(i))
30    CONTINUE
      k1 = 1
      k2 = m
      DO 40 i = 1, m
        IF (w(i)==1) THEN
          rows(k1) = i
          k1 = k1 + 1
        ELSE
          rows(k2) = i
          k2 = k2 - 1
        END IF
40    CONTINUE

! Construct final column permutation
      DO 50 i = 1, n
        w(keep(m+i)) = cols(i)
50    CONTINUE
      k1 = 1
      k2 = n
      DO 60 i = 1, n
        IF (w(i)==1) THEN
          cols(k1) = i
          k1 = k1 + 1
        ELSE
          cols(k2) = i
          k2 = k2 - 1
        END IF
60    CONTINUE

    END subroutine ma51ad

    SUBROUTINE ma51bd(m,n,iq,np,lfact,irnf,iptrl,iptru,rank,rows,cols,w)

!  Purpose
!  =======
!     This is for use in conjunction with the MA50 routines
!     for solving full sets of linear equations. It must follow
!     a call of MA50B/BD, and the values of the arguments
!     M,N,IQ,NP,LFACT,IRNF,IPTRL,IPTRU must be unchanged.
!     It identifies which equations are ignored when solving Ax = b
!     and which solution components are always set to zero.
!     There are such equations and/or components in the singular or
!     rectangular case.

      integer  :: m, n, np, iq(*)
      integer(long) :: lfact, iptrl(n), iptru(n), irnf(lfact)
      integer :: rank, rows(m), cols(n), w(max(m,n))

! M  is an integer variable set to the number of rows.
!     It is not altered by the subroutine.
! N  is an integer variable set to the number of columns.
!     It is not altered by the subroutine.
! IQ is an integer array holding the permutation Q.
!     It is not altered by the subroutine.
! NP is an integer variable holding the number of rows and columns in
!     packed storage. It is not altered by the subroutine.
! LFACT is an integer variable set to the size of FACT and IRNF.
!     It is not altered by the subroutine.
! IRNF is an integer array holding the row numbers of the packed part
!     of L/U, and the row numbers of the full part of L/U.
!     It is not altered by the subroutine.
! IPTRL is an integer array. For J = 1,..., NP, IPTRL(J) holds the
!     position in FACT and IRNF of the end of column J of L.
!     For J = NP+1,..., N, IPTRL(J) is equal to IPTRU(J).
!     It is not altered by the subroutine.
! IPTRU is an integer array. For J = 1,..., N, IPTRU(J) holds the
!     position in FACT and IRNF of the end of the packed part of
!     column J of U. It is not altered by the subroutine.
! RANK is an integer variable that need not be set on input.
!     On exit, it holds the rank computed by MA50.
! ROWS is an integer array that need not be set on input.
!      On exit, it holds a permutation. The indices of the rows that
!      are taken into account when solving Ax = b are ROWS(i),
!      i <= RANK.
! COLS is an integer array that need not be set on input.
!      On exit, it holds a permutation. The indices of the columns that
!      are taken into account when solving Ax = b are COLS(j),
!      j <= RANK.
! W is an integer workarray of length max(M,N).


! Local variables
!  =========


      INTEGER i, k1, k2
! I Temporary variable holding row or column number.
! K1 Position of next row or column of the significant part.
! K2 Position of next row or column of the insignificant part.

      CALL ma51zd(m,n,iq,np,lfact,irnf,iptrl,iptru,rank,rows,cols,w)

! Construct final permutations
      DO 10 i = 1, m
        w(i) = rows(i)
10    CONTINUE
      k1 = 1
      k2 = m
      DO 20 i = 1, m
        IF (w(i)==1) THEN
          rows(k1) = i
          k1 = k1 + 1
        ELSE
          rows(k2) = i
          k2 = k2 - 1
        END IF
20    CONTINUE
      DO 30 i = 1, n
        w(i) = cols(i)
30    CONTINUE
      k1 = 1
      k2 = n
      DO 40 i = 1, n
        IF (w(i)==1) THEN
          cols(k1) = i
          k1 = k1 + 1
        ELSE
          cols(k2) = i
          k2 = k2 - 1
        END IF
40    CONTINUE
    END subroutine ma51bd

    SUBROUTINE ma51cd(m,n,la,a,irn,keep,sgndet,logdet,w)
!     This is for use in conjunction with the MA48 routines
!     for solving sparse sets of linear equations. It must follow
!     a call of MA48B/BD, and the values of the arguments
!     M,N,LA,A,IRN,KEEP must be unchanged.
!     It computes the determinant.

      INTEGER m, n
      integer(long) la
      real(wp) a(la)
      INTEGER sgndet
      INTEGER(long) irn(la)
      integer(long) keep(*)
      real(wp) logdet
      integer w(n)
      real(wp) zero
      PARAMETER (zero=0.0_wp)

! M must be set by the user to the number of rows in the matrix.
!      It is not altered by the subroutine.
! N must be set by the user to the number of columns in the matrix.
!      It is not altered by the subroutine.
! LA must be set by the user to the size of array IRN.
!      It is not altered by the subroutine.
! A must be left unchanged from the last call to MA48B/BD.
!      It holds the factorized matrix.
!      It is not altered by the subroutine.
! IRN  must be left unchanged from the last call to MA48B/BD.
!      It holds the row indices of the factorization in A and
!      the row indices of the original matrix in permuted form.
!      It is not altered by the subroutine.
! KEEP must be as on return from MA48B/BD.
!      It is not altered by the subroutine.
! SGNDET is an integer output variable that returns the
!      sign of the determinant or zero if the determinant is zero.
! LOGDET is a double precision output variable that returns the
!      LOG of the abslute value of the determinant or zero if the
!      determinant is zero.
! W is an integer work array.

!     .. Local variables ..
      INTEGER i, iqb(1), j, jb, j1, k, k1, k2, &
        l, nb, nc, np, nr, sgndt
      integer(long) :: iptrd, iptrl, iptro, iptru, &
        kblock, mblock, nblock, ne
      real(wp) piv, logdt

      iqb(1) = 0

! Partition KEEP
      iptrl = m + n
      iptru = iptrl + n
      iptrd = iptru + n
      iptro = iptrd + n + 1
      nblock = iptro + n - 1
      mblock = nblock + 1
      kblock = mblock + 1
      nb = keep(kblock+3)
      ne = keep(iptro+n+1) - 1

      logdet = zero
      sgndet = 1

! Check for rectangular case
      IF (m/=n) THEN
        sgndet = 0
        RETURN
      END IF

      DO 10 i = 1, n
        w(i) = 1
10    CONTINUE

! Compute sign of row permutation, leaving W=0
      DO 40 i = 1, n
        k = keep(i)
        IF (w(k)==1) THEN
          DO 30 j = 1, n
            l = keep(k)
            w(k) = 0
            IF (k==i) GO TO 40
            sgndet = -sgndet
            k = l
30        CONTINUE
        END IF
40    CONTINUE

! Compute sign of column permutation
      DO 60 i = 1, n
        k = keep(n+i)
        IF (w(k)==0) THEN
          DO 50 j = 1, n
            l = keep(n+k)
            w(k) = 1
            IF (k==i) GO TO 60
            sgndet = -sgndet
            k = l
50        CONTINUE
        END IF
60    CONTINUE

      k2 = 0
      DO 80 jb = 1, nb
        nc = keep(nblock+3*jb)
        nr = nc
        IF (nb==1) nr = m
        k1 = k2 + 1
        k2 = k2 + nc
        np = keep(mblock+3*jb)
        IF (np<0) THEN
! Triangular block
          DO 70 j = k1, k2
            piv = a(keep(iptrd+j))
            IF (piv<zero) THEN
              sgndet = -sgndet
              logdet = logdet + log(-piv)
            ELSE
              logdet = logdet + log(piv)
            END IF
70        CONTINUE
        ELSE
          j1 = 1
          IF (jb>1) j1 = keep(kblock+3*jb)
          CALL ma51dd(nr,nc,iqb,np,la+1-j1-ne,a(ne+j1),irn(ne+j1), &
            keep(iptrl+k1),keep(iptru+k1),sgndt,logdt,w)
          sgndet = sgndet*sgndt
          logdet = logdet + logdt
          IF (sgndet==0) THEN
            logdet = 0
            RETURN
          END IF
        END IF
80    CONTINUE

    END subroutine ma51cd

    SUBROUTINE ma51dd(m,n,iq,np,lfact,fact,irnf,iptrl,iptru,sgndet,logdet,w)
!  Computes the determinant of a factorized n-by-n matrix.
      INTEGER k, l, m, n, np, iq(*)
      integer(long) ::  lfact, irnf(lfact)
      real(wp) fact(lfact)
      INTEGER sgndet, w(n)
      integer(long) ::  iptrl(n), iptru(n)
      real(wp) logdet
! M is an integer variable that must be set to the number of rows.
!      It is not altered by the subroutine.
! N is an integer variable that must be set to the number of columns.
!      It is not altered by the subroutine.
! IQ is an integer array of length N holding the column permutation Q
!     or an array of length 1 with the value 0 if there is no column
!     permutation. It is not altered by the subroutine.
! NP is an integer variable that must be unchanged since calling
!     MA50B/BD. It holds the number of rows and columns in packed
!     storage. It is not altered by the subroutine.
! LFACT is an integer variable set to the size of FACT and IRNF.
!     It is not altered by the subroutine.
! FACT is an array that must be unchanged since calling MA50B/BD. It
!     holds the packed part of L/U by columns, and the full part of L/U
!     by columns. U has unit diagonal entries, which are not stored, and
!     the signs of the off-diagonal entries are inverted.  In the packed
!     part, the entries of U precede the entries of L; also the diagonal
!     entries of L head each column of L and are reciprocated.
!     FACT is not altered by the subroutine.
! IRNF is an integer array that must be unchanged since calling
!     MA50B/BD. It holds the row numbers of the packed part of L/U, and
!     the row numbers of the full part of L/U.
!     It is not altered by the subroutine.
! IPTRL is an integer array that must be unchanged since calling
!     MA50B/BD. For J = 1,..., NP, IPTRL(J) holds the position in
!     FACT and IRNF of the end of column J of L.
!     For J = NP+1,..., N, IPTRL(J) is equal to IPTRU(J).
!     It is not altered by the subroutine.
! IPTRU is an integer array that must be unchanged since calling
!     MA50B/BD. For J = 1,..., N, IPTRU(J) holds the position in
!     FACT and IRNF of the end of the packed part of column J of U.
!     It is not altered by the subroutine.
! SGNDET is an integer output variable that returns the
!      sign of the determinant or zero if the determinant is zero.
! LOGDET is a double precision output variable that returns the
!      LOG of the abslute value of the determinant or zero if the
!      determinant is zero.
! W is an integer work array.

      real(wp) a
      INTEGER i, j, mf, nf
      integer(long) :: ia1, if1
      real(wp) zero
      PARAMETER (zero=0.0_wp)
! A Pivot value.
! I Temporary variable.
! IA1 Position of the start of the current row or column.
! IF1 Position of the start of the full part of U.
! J Temporary variable.
! MF Number of rows held in full format.
! NF Number of columns held in full format.

      if1 = iptrl(n) + 1
      mf = irnf(2)
      nf = n - np
      logdet = 0
      sgndet = 1

! Find the determinant of the full part
      IF (mf>0) THEN
! Check for rank-deficient case
        IF (m/=n .OR. mf/=nf .OR. irnf(if1+mf+nf-1)<0) THEN
          sgndet = 0
          RETURN
        END IF
        CALL ma51xd(mf,fact(if1),mf,irnf(if1+mf),sgndet,logdet)
      END IF

! Find row permutation and compute LOGDET
      DO 10 i = 1, np
        ia1 = iptru(i) + 1
        a = fact(ia1)
        IF (a<zero) THEN
          sgndet = -sgndet
          logdet = logdet - log(-a)
        ELSE
          logdet = logdet - log(a)
        END IF
        w(i) = irnf(ia1)
10    CONTINUE
      DO 20 i = 1, mf
        w(np+i) = irnf(if1+i-1)
20    CONTINUE

! Compute sign of row permutation, leaving W=0
      DO 40 i = 1, n
        k = w(i)
        IF (k>0) THEN
          DO 30 j = 1, n
            l = w(k)
            w(k) = 0
            IF (k==i) GO TO 40
            sgndet = -sgndet
            k = l
30        CONTINUE
        END IF
40    CONTINUE
      IF (iq(1)<=0) RETURN

! Compute sign of column permutation
      DO 60 i = 1, n
        k = iq(i)
        IF (w(k)==0) THEN
          DO 50 j = 1, n
            l = iq(k)
            w(k) = 1
            IF (k==i) GO TO 60
            sgndet = -sgndet
            k = l
50        CONTINUE
        END IF
60    CONTINUE

    END subroutine ma51dd



    SUBROUTINE ma51xd(n,a,lda,ipiv,sgndet,logdet)
      IMPLICIT NONE
      INTEGER n
      integer :: lda
      real(wp) a(lda,n)
      INTEGER sgndet
      integer(long) ipiv(n)
      real(wp) logdet
!  Computes the determinant of a factorized n-by-n matrix A.

!  The factorization has the form
!     A = P * L * U
!  where P is a permutation matrix of order n, L is lower triangular
!  of order n with unit diagonal elements, U is upper triangular of
!  order n, and Q is a permutation matrix of order n.

!  N       (input) INTEGER
!          Order of the matrix A.  N >= 1.

!  A       (input) DOUBLE PRECISION array, dimension (LDA,N)
!          On entry, the m by n matrix to be factored.
!          Holds the factors L and U of the factorization
!          A = P*L*U; the unit diagonal elements of L are not stored.

!  LDA     (input) INTEGER
!          The leading dimension of the array A.  LDA >= N.

!  IPIV    (input) INTEGER array, dimension (N)
!          The permutations; for 1 <= i <= N, row i of the
!          matrix was interchanged with row IPIV(i).

!  SGNDET  (output) INTEGER
!          The sign of the determinant.

!  LOGDET  (output) DOUBLE PRECISION
!          LOG of the determinant.

      INTEGER j
      real(wp) zero
      PARAMETER (zero=0.0_wp)
      INTRINSIC log

      sgndet = 1
      logdet = zero
      DO 30 j = 1, n
        IF (ipiv(j)/=j) sgndet = -sgndet
        IF (a(j,j)<zero) THEN
          sgndet = -sgndet
          logdet = logdet + log(-a(j,j))
        ELSE
          logdet = logdet + log(a(j,j))
        END IF
30    CONTINUE

    END subroutine ma51xd



    SUBROUTINE ma51yd(m,n,ipiv,rank,rows,cols)

!  Purpose
!  =======
!     This is for use in conjunction with the MA50 routines
!     for solving full sets of linear equations. It must follow
!     a call of MA50E/ED, MA50F/FD, or MA50G/GD.
!     It identifies which equations are ignored when solving Ax = b
!     and which solution components are always set to zero.
!     There are such equations and/or components in the singular or
!     rectangular case.

      INTEGER m, n, rank, rows(m), cols(n)
      integer (long) ipiv(n)

!  Arguments
!  =========

!  M       (input) INTEGER
!          The number of rows of the matrix A.  M >= 1.

!  N       (input) INTEGER
!          The number of columns of the matrix A.  N >= 1.

!  IPIV    (input) INTEGER array, dimension (N)
!          The permutations; for 1 <= i <= RANK, row i of the
!          matrix was interchanged with row IPIV(i); for
!          RANK + 1 <= j <= N, column j of the
!          matrix was interchanged with column -IPIV(j).

!  RANK    (output) INTEGER
!          On exit, the rank computed by MA50.

!  ROWS    (output) INTEGER array, dimension (M)
!          On exit, ROWS(i) = 0 if row i is ignored and
!          ROWS(i) = 1 otherwise.

!  COLS    (output) INTEGER array, dimension (N)
!          On exit, COLS(j) = 0 if component j is set to zero
!          always and COLS(j) = 1 otherwise.


! Local variables
!  =========

      INTEGER i, j, k
! I    Temporary variable.
! J    Temporary variable.
! K    Temporary variable.

! Find rank
      DO 10 k = 1, n
        IF (ipiv(k)<0) GO TO 20
        rows(k) = 1
        cols(k) = 1
10    CONTINUE
20    rank = k - 1

! Set singular parts to zero
      DO 30 k = rank + 1, m
        rows(k) = 0
30    CONTINUE
      DO 40 k = rank + 1, n
        cols(k) = 0
40    CONTINUE

! Apply interchanges.
      DO 50 i = rank + 1, n
        k = -ipiv(i)
        j = cols(i)
        cols(i) = cols(k)
        cols(k) = j
50    CONTINUE
      DO 60 i = rank, 1, -1
        k = ipiv(i)
        j = rows(i)
        rows(i) = rows(k)
        rows(k) = j
60    CONTINUE

    END subroutine ma51yd


    SUBROUTINE ma51zd(m,n,iq,np,lfact,irnf,iptrl,iptru,rank,rows,cols,w)

!  Purpose
!  =======
!     This is for use in conjunction with the MA50 routines
!     for solving full sets of linear equations. It must follow
!     a call of MA50B/BD, and the values of the arguments
!     M,N,IQ,NP,LFACT,IRNF,IPTRL,IPTRU must be unchanged.
!     It identifies which equations are ignored when solving Ax = b
!     and which solution components are always set to zero.
!     There are such equations and/or components in the singular or
!     rectangular case.

      integer  :: m, n, np, iq(*)
      integer(long) :: lfact, iptrl(n), iptru(n), irnf(lfact)
      integer :: rank, rows(m), cols(n), w(*)

! M  is an integer variable set to the number of rows.
!     It is not altered by the subroutine.
! N  is an integer variable set to the number of columns.
!     It is not altered by the subroutine.
! IQ is an integer array holding the permutation Q.
!     It is not altered by the subroutine.
! NP is an integer variable holding the number of rows and columns in
!     packed storage. It is not altered by the subroutine.
! LFACT is an integer variable set to the size of FACT and IRNF.
!     It is not altered by the subroutine.
! IRNF is an integer array holding the row numbers of the packed part
!     of L/U, and the row numbers of the full part of L/U.
!     It is not altered by the subroutine.
! IPTRL is an integer array. For J = 1,..., NP, IPTRL(J) holds the
!     position in FACT and IRNF of the end of column J of L.
!     For J = NP+1,..., N, IPTRL(J) is equal to IPTRU(J).
!     It is not altered by the subroutine.
! IPTRU is an integer array. For J = 1,..., N, IPTRU(J) holds the
!     position in FACT and IRNF of the end of the packed part of
!     column J of U. It is not altered by the subroutine.
! RANK is an integer variable that need not be set on input.
!     On exit, it holds the rank computed by MA50.
! ROWS is an integer array that need not be set on input.
!      On exit, ROWS(i) = 0 if row i is ignored and
!          ROWS(i) = 1 otherwise.
! COLS is an integer array that need not be set on input.
!      On exit, COLS(j) = 0 if component j is set to zero
!          always and COLS(j) = 1 otherwise.
! W is an integer workarray of length max(M,N).


! Local variables
!  =========


      INTEGER i, j, mf, nf
      integer(long) :: ia1, if1
! I Temporary variable holding row number.
! IA1 Position of the start of the current row or column.
! IF1 Position of the start of the full part of U.
! J Temporary variable holding column number.
! MF Number of rows held in full format.
! NF Number of columns held in full format.

      if1 = iptrl(n) + 1
      mf = irnf(2)
      nf = n - np

      IF (mf>0 .AND. nf>0) THEN
        CALL ma51yd(mf,nf,irnf(if1+mf),rank,w,cols(np+1))
      ELSE
        rank = 0
        DO 10 i = 1, mf
          w(i) = 0
10      CONTINUE
        DO 20 i = 1, nf
          cols(np+i) = 0
20      CONTINUE
      END IF

      DO 30 i = 1, m
        rows(i) = 1
30    CONTINUE


      DO 40 i = mf, 1, -1
        j = irnf(if1+i-1)
        rows(j) = w(i)
40    CONTINUE

      rank = rank + m - mf

      DO 220 j = np, 1, -1
        ia1 = iptru(j)
        IF (ia1>=iptrl(j)) THEN
          cols(j) = 0
        ELSE
          cols(j) = 1
        END IF
220   CONTINUE
      IF (iq(1)>0) THEN
! Permute COLS
        DO 230 i = 1, n
          w(i) = cols(i)
230     CONTINUE
        DO 240 i = 1, n
          cols(iq(i)) = w(i)
240     CONTINUE
      END IF

    END subroutine ma51zd

end module hsl_ma48_ma51_internal_double


module hsl_ma48_double
   use hsl_ma48_ma48_internal_double
   use hsl_ma48_ma51_internal_double
   use hsl_zd11_double
   implicit none

   private
   public :: ma48_factors,ma48_control,ma48_ainfo,ma48_finfo,ma48_sinfo, &
             ma48_initialize,ma48_analyse,ma48_factorize,ma48_solve, &
             ma48_finalize, ma48_get_perm,ma48_special_rows_and_cols, &
             ma48_determinant

   integer, parameter :: wp = kind(0.0d0)
   integer, parameter :: long = selected_int_kind(18) ! Long integer

   interface ma48_initialize
      module procedure ma48_initialize_double
   end interface

   interface ma48_analyse
      module procedure ma48_analyse_double
   end interface

   interface ma48_factorize
      module procedure ma48_factorize_double
   end interface

   interface ma48_solve
      module procedure ma48_solve_double
   end interface

   interface  ma48_finalize
      module procedure  ma48_finalize_double
   end interface

   interface ma48_get_perm
      module procedure ma48_get_perm_double
   end interface

   interface ma48_special_rows_and_cols
      module procedure ma48_special_rows_and_cols_double
   end interface

   interface ma48_determinant
      module procedure ma48_determinant_double
   end interface

   type ma48_factors
      integer(long), allocatable :: keep(:)
!! Must be long because used for mapping vectors
      integer(long), allocatable :: irn(:)
      integer(long), allocatable :: jcn(:)
      real(wp), allocatable :: val(:)
      integer :: m       ! Number of rows in matrix
      integer :: n       ! Number of columns in matrix
!! For the moment lirnreq = lareq because of BTF structure
      integer(long) :: lareq   ! Size of real array for further factorization
      integer(long) :: lirnreq ! Size of integer array for further 
                               ! factorization
      integer :: partial ! Number of columns kept to end for partial
                         ! factorization
      integer(long) :: ndrop   ! Number of entries dropped from data structure
      integer :: first   ! Flag to indicate whether it is first call to
                         ! factorize after analyse (set to 1 in analyse).
   end type ma48_factors

   type ma48_control
      real(wp) :: multiplier ! Factor by which arrays sizes are to be
                        ! increased if they are too small
      real(wp) :: u     ! Pivot threshold
      real(wp) :: switch ! Density for switch to full code
      real(wp) :: drop   ! Drop tolerance
      real(wp) :: tolerance ! anything less than this is considered zero
      real(wp) :: cgce  ! Ratio for required reduction using IR
      real(wp) :: reduce ! Only kept for compatibility with earlier
!                         version of hsl_ma48
      integer :: la     ! Only kept for compatibility with earlier
!                         version of hsl_ma48
      integer :: maxla  ! Only kept for compatibility with earlier
!                         version of hsl_ma48
      integer :: lp     ! Unit for error messages
      integer :: wp     ! Unit for warning messages
      integer :: mp     ! Unit for monitor output
      integer :: ldiag  ! Controls level of diagnostic output
      integer :: btf    ! Minimum block size for BTF ... >=N to avoid
      logical :: struct ! Control to abort if structurally singular
      integer :: maxit ! Maximum number of iterations
      integer :: factor_blocking ! Level 3 blocking in factorize
      integer :: solve_blas ! Switch for using Level 1 or 2 BLAS in solve.
      integer :: pivoting  ! Controls pivoting:
!                 Number of columns searched.  Zero for Markowitz
      logical :: diagonal_pivoting  ! Set to 0 for diagonal pivoting
      integer :: fill_in ! Initially fill_in * ne space allocated for factors
      logical :: switch_mode ! Whether to switch to slow when fast mode
!               given unsuitable pivot sequence.
   end type ma48_control

   type ma48_ainfo
      real(wp) :: ops = 0.0   ! Number of operations in elimination
      integer :: flag = 0  ! Flags success or failure case
      integer :: more = 0   ! More information on failure
      integer(long) :: lena_analyse  = 0! Size for analysis (main arrays)
      integer(long) :: lenj_analyse  = 0! Size for analysis (integer aux array)
      integer(long) :: len_analyse  = 0! Only kept for compatibility
!                      with earlier version of hsl_ma48. Set to maximum
!                      of lena_analyse and lenj_analyse
!! For the moment leni_factorize = lena_factorize because of BTF structure
      integer(long) :: lena_factorize  = 0 ! Size for factorize (real array)
      integer(long) :: leni_factorize  = 0 ! Size for factorize (integer array)
      integer(long) :: len_factorize  = 0! Only kept for compatibility
!                      with earlier version of hsl_ma48. Set to maximum
!                      of lena_factorize and leni_factorize
      integer :: ncmpa   = 0 ! Number of compresses in analyse
      integer :: rank   = 0  ! Estimated rank
      integer(long) :: drop   = 0  ! Number of entries dropped
      integer :: struc_rank  = 0! Structural rank of matrix
      integer(long) :: oor   = 0   ! Number of indices out-of-range
      integer(long) :: dup   = 0   ! Number of duplicates
      integer :: stat   = 0  ! STAT value after allocate failure
      integer :: lblock  = 0 ! Size largest non-triangular block
      integer :: sblock  = 0 ! Sum of orders of non-triangular blocks
      integer(long) :: tblock  = 0 ! Total entries in all non-triangular blocks
   end type ma48_ainfo

   type ma48_finfo
      real(wp) :: ops  = 0.0  ! Number of operations in elimination
      integer :: flag   = 0 ! Flags success or failure case
      integer :: more   = 0  ! More information on failure
      integer(long) :: size_factor   = 0! Number of words to hold factors
!! For the moment leni_factorize = lena_factorize because of BTF structure
      integer(long) :: lena_factorize  = 0 ! Size for factorize (real array)
      integer(long) :: leni_factorize  = 0 ! Size for factorize (integer array)
      integer(long) :: len_factorize  = 0! Only kept for compatibility
!                      with earlier version of hsl_ma48. Set to maximum
!                      of lena_factorize and leni_factorize
      integer(long) :: drop   = 0 ! Number of entries dropped
      integer :: rank   = 0  ! Estimated rank
      integer :: stat   = 0  ! STAT value after allocate failure
   end type ma48_finfo

   type ma48_sinfo
      integer :: flag   = 0 ! Flags success or failure case
      integer :: more   = 0  ! More information on failure
      integer :: stat   = 0  ! STAT value after allocate failure
   end type ma48_sinfo

contains

   SUBROUTINE ma48_initialize_double(factors,control)
      type(ma48_factors), intent(out), optional :: factors
      type(ma48_control), intent(out), optional :: control

      if (present(factors)) then
        factors%n = 0
        factors%first = 0
        factors%partial = 0
      end if
      if (present(control)) then
          control%switch = 0.5d0
          control%u      = 0.01d0
          control%drop   = 0.0d0
          control%tolerance = 0.0d0
          control%cgce      = 0.5d0
          control%lp = 6
          control%wp = 6
          control%mp = 6
          control%ldiag = 2
          control%pivoting = 3
          control%diagonal_pivoting = .false.
          control%fill_in = 3
          control%maxit = 10
          control%struct = .false.
          control%factor_blocking = 32
          control%solve_blas  = 2
          control%btf = 1
          control%multiplier = 2.0d0
          control%switch_mode = .false.
      end if
    end subroutine ma48_initialize_double

   SUBROUTINE ma48_analyse_double(matrix,factors,control,ainfo,finfo, &
                                  perm,endcol)
      type(zd11_type), Intent(in) :: matrix
      type(ma48_factors), intent(inout) :: factors
      type(ma48_control), intent(in) :: control
      type(ma48_ainfo), intent(out) :: ainfo
      type(ma48_finfo), intent(out), optional :: finfo
      integer, intent(in), optional :: perm(matrix%m+matrix%n) ! Input perm
      integer, intent(in), optional :: endcol(matrix%n) ! Define last cols

      integer, allocatable :: iwork(:)
      integer :: i,job,k,lkeep,m,n,stat,icntl(20)
      integer(long) :: la,ne,info(20)
      integer(long), parameter :: lone = 1
      real(wp):: rinfo(10),cntl(10)

      cntl(1) = control%switch
      cntl(2) = control%u
      cntl(3) = control%drop
      cntl(4) = control%tolerance
! cntl(6) set so that storage is always increased
      cntl(6) = max(1.2_wp,control%multiplier)
      icntl(1) = -1
      icntl(2) = -1
      if (control%ldiag.gt.2) icntl(2) = control%mp
      icntl(3) = control%ldiag
      icntl(4) = control%pivoting
      icntl(5) = control%factor_blocking
      icntl(6) = control%btf
      if (control%struct) then
! Abort run if matrix singular
        icntl(7) = 1
      else
        icntl(7) = 0
      end if

      m = matrix%m
      n = matrix%n
      ne = matrix%ne

      if(matrix%m .lt. 1) then
         ainfo%flag = -1
         ainfo%more = matrix%m
         if (control%ldiag>0 .and. control%lp>=0 ) &
         write (control%lp,'(/a,i3/a,i12)') &
         'Error return from MA48_ANALYSE with ainfo%flag = ',ainfo%flag, &
         'MATRIX%M has the value', matrix%m
       return
      end if

      if(matrix%n .lt. 1) then
         if (control%ldiag>0 .and. control%lp>=0 ) &
         ainfo%flag = -2
         ainfo%more = matrix%n
         write (control%lp,'(/a,i3/a,i12)') &
         'Error return from MA48_ANALYSE with ainfo%flag = ',ainfo%flag, &
         'MATRIX%N has the value', matrix%n
       return
      end if

      if(matrix%ne .lt. 0) then
         if (control%ldiag>0 .and. control%lp>=0 ) &
         ainfo%flag = -3
         ainfo%more = matrix%ne
         write (control%lp,'(/a,i3/a,i12)') &
         'Error return from MA48_ANALYSE with ainfo%flag = ',ainfo%flag, &
         'MATRIX%NE has the value', matrix%ne
       return
      end if

      ainfo%flag = 0
      ainfo%more = 0
      ainfo%stat = 0

      if(matrix%ne .eq. 0) then
        ainfo%ops = 0.0d0
        ainfo%rank = 0
        ainfo%drop = 0
        factors%ndrop = 0
        ainfo%oor = 0
        ainfo%dup = 0
        ainfo%lena_analyse = 0
        ainfo%len_analyse = 0
        ainfo%lena_factorize = 0
        ainfo%len_factorize = 0
        ainfo%struc_rank = 0
        ainfo%rank = 0
        ainfo%ncmpa = 0
        factors%first = 1
        factors%lareq = 0
        factors%lirnreq = 0
        factors%partial = 0
        factors%m = m
        factors%n = n
        if (control%struct) then
          ainfo%flag = -5
           if (control%ldiag>0 .and. control%lp>=0 ) &
                 write (control%lp,'(/a,i3/a,i5)') &
         'Error return from MA48_ANALYSE with ainfo%flag = ',ainfo%flag, &
                 'Matrix is structurally singular with rank ',ainfo%struc_rank
        else
          ainfo%flag = 4
          if (control%ldiag>1 .and. control%wp>=0) &
          write (control%wp,'(/a/a,i5)') &
              'Warning from MA48_ANALYSE: ', &
              'ainfo%flag is equal to ',ainfo%flag
        endif
        return
      endif

      lkeep = m+5*n+4*n/icntl(6)+7

      if(allocated(factors%keep)) then
!!! Problem with Fortran 95 extension
!        if(size(factors%keep,kind=long)/=lkeep) then
         if(size(factors%keep)*lone/=lkeep) then
            deallocate(factors%keep,stat=stat)
            allocate(factors%keep(lkeep),stat=stat)
            if (stat/=0) go to 100
         end if
      else
         allocate(factors%keep(lkeep),stat=stat)
         if (stat/=0) go to 100
      end if

      la = max(2*ne,(control%fill_in+0_long)*ne)

!! Can allocate to different lengths
      if(allocated(factors%val)) then
!!!! Same problem
!        if(la /= size(factors%val,kind=long)) then
         if(la /= size(factors%val)*lone) then
            deallocate(factors%irn,factors%jcn,factors%val,stat=stat)
            allocate(factors%irn(2*ne),factors%jcn(ne),factors%val(2*ne), &
               stat=stat)
            if (stat/=0) go to 100
         end if
      else
         allocate(factors%irn(2*ne),factors%jcn(ne),factors%val(2*ne),stat=stat)
         if (stat/=0) go to 100
      end if

      if (present(perm)) then
! Check permutation
         allocate (iwork(max(m,n)),stat=stat)
         if (stat/=0) go to 100

         iwork = 0
         do i = 1,m
           k = perm(i)
           if (k.gt.m .or. k.lt.0 .or. iwork(k) .ne. 0) then
             ainfo%flag = -6
             ainfo%more = i
             if (control%ldiag>0 .and. control%lp>=0 ) &
               write (control%lp,'(/a,i3/a,i12,a,i12)') &
         'Error return from MA48_ANALYSE with ainfo%flag = ',ainfo%flag, &
         'Invalid row permutation'
               deallocate (iwork,stat=stat)
             return
           end if
           iwork(k) = i
         end do

         iwork = 0
         do i = 1,n
           k = perm(m+i)
           if (k.gt.n .or. k.lt.0 .or. iwork(k) .ne. 0) then
             ainfo%flag = -6
             ainfo%more = i
             if (control%ldiag>0 .and. control%lp>=0 ) &
               write (control%lp,'(/a,i3/a,i12,a,i12)') &
         'Error return from MA48_ANALYSE with ainfo%flag = ',ainfo%flag, &
         'Invalid column permutation'
               deallocate (iwork,stat=stat)
             return
           end if
           iwork(k) = i
         end do

         deallocate (iwork,stat=stat)
         if (stat/=0) go to 100

         job = 2
      else
         job = 1
      end if

      if (control%diagonal_pivoting) job = 3

      icntl(8) = 0
      if (present(endcol)) then
        icntl(8) = 1
        factors%partial = count(endcol(1:n) == 0)
      end if

      if (present(perm)) factors%keep(1:m+n) = perm(1:m+n)

      factors%irn(1:ne) = matrix%row(1:ne)
      factors%jcn(1:ne) = matrix%col(1:ne)
      factors%val(1:ne) = matrix%val(1:ne)

!!!!!!!!!!!!!!!  Call to MA48AD !!!!!!!!!!!!!!!!!!!!!!
      if (present(endcol)) then
        call ma48ad(m,n,ne,job,la,factors%val,factors%irn,factors%jcn, &
                    factors%keep,cntl,icntl,info,rinfo,endcol)
      else
        call ma48ad(m,n,ne,job,la,factors%val,factors%irn,factors%jcn, &
                    factors%keep,cntl,icntl,info,rinfo)
      endif
! Jump if failure in allocations in MA48/MA50
       if (info(1).eq.-10) go to 100
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      if (info(1).eq.-4) then
        ainfo%flag = -5
        ainfo%struc_rank = info(10)

        if (control%ldiag>0 .and. control%lp>=0 ) &
              write (control%lp,'(/a,i3/a,i5)') &
         'Error return from MA48_ANALYSE with ainfo%flag = ',ainfo%flag, &
                 'Matrix is structurally singular with rank ',info(10)
        return
      endif

      if (info(1).gt.0) then
        if (info(1).eq.1 .and. info(11).gt.0) ainfo%flag = ainfo%flag + 2
        if (info(1).eq.1 .and. info(12).gt.0) ainfo%flag = ainfo%flag + 1
        if (info(1).eq.2) ainfo%flag = ainfo%flag + 4
        if (info(1).eq.4) ainfo%flag = ainfo%flag + 8
      endif

      if (ainfo%flag.gt.0) then
        if (control%ldiag>1 .and. control%wp>=0) &
          write (control%wp,'(/a/a,i5)') &
              'Warning from MA48_ANALYSE: ', &
              'ainfo%flag is equal to ',ainfo%flag
      end if

      factors%m = m
      factors%n = n
!! Both the same because of data structure in case of BTF
      factors%lareq = info(4)
      factors%lirnreq = info(4)
      factors%first = 1

      ainfo%ops    = rinfo(1)
      ainfo%rank   = info(5)
      ainfo%drop   = info(6)
      factors%ndrop   = info(6)
      ainfo%oor    = info(12)
      ainfo%dup    = info(11)
      ainfo%lena_analyse = info(3)
      ainfo%lenj_analyse = info(14)
      ainfo%len_analyse  = max(ainfo%lena_analyse,ainfo%lenj_analyse)
!! Both the same because of data structure in case of BTF
      ainfo%lena_factorize = info(4)
      ainfo%leni_factorize = info(4)
      ainfo%len_factorize  = max(ainfo%lena_factorize,ainfo%leni_factorize)
      ainfo%lblock = info(7)
      ainfo%sblock = info(8)
      ainfo%tblock = info(9)
      ainfo%struc_rank = info(10)
      ainfo%ncmpa  = info(2)

      if (present(finfo)) then
        call MA48_factorize(matrix,factors,control,finfo)
        if (finfo%flag<0) ainfo%flag = -7
      endif

      return

  100  ainfo%flag = -4
       ainfo%stat = stat
       if (control%ldiag>0 .and. control%lp>=0 ) &
         write (control%lp,'(/a,i3/a,i12)') &
         'Error return from MA48_ANALYSE with ainfo%flag = ',ainfo%flag, &
         'Allocate failed with STAT =',stat

   end subroutine ma48_analyse_double

   SUBROUTINE ma48_get_perm_double(factors,perm)
      type(ma48_factors), intent(in), optional :: factors
      integer, intent(out) :: perm(:)
      integer m,n

      m = factors%m
      n = factors%n

      perm(1:m+n) = factors%keep(1:m+n)

    end subroutine ma48_get_perm_double

   SUBROUTINE ma48_factorize_double(matrix,factors,control,finfo,fast,partial)
      type(zd11_type), intent(in) :: matrix
      type(ma48_factors), intent(inout) :: factors
      type(ma48_control), intent(in) :: control
      type(ma48_finfo), intent(out) :: finfo
      integer, optional, intent(in) :: fast,partial

      integer :: job,m,n
      integer(long) :: la,ne,info(20)
      integer stat  ! stat value in allocate statements

      integer(long), parameter :: lone = 1

      integer icntl(20)
      real(wp) multiplier,cntl(10),rinfo(10)

      integer (long), allocatable :: itemp(:)

! Check whether this has been preceded by a call to ma48_analyse
      if (factors%first .le. 0) then
         finfo%flag = -10
         write (control%lp,'(/a,i3/a,i12)') &
         'Error return from MA48_FACTORIZE with finfo%flag = ',finfo%flag, &
         'No prior call to MA48_ANALYSE'
         return
      endif

! Storage must be increased if ma48bd fails so effective value of 
!     multiplier is set greater than one
      multiplier = max(1.2_wp,control%multiplier)
      m = matrix%m
      n = matrix%n
      ne = matrix%ne

      if(factors%m/=matrix%m) then
       finfo%flag = -1
       finfo%more = matrix%m
       if (control%ldiag>0 .and. control%lp>=0 ) &
         write (control%lp,'(/a,i3/a,i12,a,i12)') &
         'Error return from MA48_FACTORIZE with finfo%flag = ',finfo%flag, &
         'MATRIX%M has the value', matrix%m,' instead of',factors%m
       return
      end if

      if(factors%n/=matrix%n) then
        finfo%flag = -2
        finfo%more = matrix%n
          if (control%ldiag>0 .and. control%lp>=0 ) &
            write (control%lp,'(/a,i3/a,i12,a,i12)') &
           'Error return from MA48_FACTORIZE with finfo%flag = ',finfo%flag, &
           'MATRIX%N has the value', matrix%n,' instead of',factors%n
        return
      end if

      if(matrix%ne .lt. 0) then
         finfo%flag = -3
         finfo%more = matrix%ne
         if (control%ldiag>0 .and. control%lp>=0 ) &
            write (control%lp,'(/a,i3/a,i12)') &
           'Error return from MA48_FACTORIZE with finfo%flag = ',finfo%flag, &
           'MATRIX%NE has the value', matrix%ne
       return
      end if

      finfo%flag = 0
      finfo%more = 0
      finfo%stat = 0

      if(matrix%ne .eq. 0) then
        finfo%ops = 0.0d0
        finfo%rank = 0
        finfo%drop = 0
        finfo%lena_factorize = 0
        finfo%leni_factorize = 0
        finfo%len_factorize = 0
        finfo%size_factor = 0
        factors%first = 2
        factors%lareq = 0
        factors%lirnreq = 0
        factors%partial = 0
        finfo%flag = 4
        if (control%ldiag>1 .and. control%wp>=0) &
          write (control%wp,'(/a/a,i5)') &
          'Warning from MA48_FACTORIZE: ', &
          'finfo%flag is equal to ',finfo%flag
        return
      endif

! Check length of main array

!!! Problem with Fortran extension
!     la = size(factors%val,kind=long)
      la = size(factors%val)*lone

      if (la<factors%lareq) then
            la = factors%lareq
            deallocate (factors%val,stat=stat)
            allocate (factors%val(la),stat=stat)
            if (stat/=0) go to 100
! Copy irn
            allocate (itemp(la),stat=stat)
            if (stat/=0) go to 100
            itemp(1:ne) = factors%irn(1:ne)
            deallocate (factors%irn,stat=stat)
            allocate (factors%irn(la),stat=stat)
            if (stat/=0) go to 100
            factors%irn(1:ne) = itemp(1:ne)
            deallocate (itemp,stat=stat)
      endif

      cntl(1) = control%switch
      cntl(2) = control%u
      cntl(3) = control%drop
      cntl(4) = control%tolerance
! Switch off error message printing from ma48bd
      icntl(1) = -1
      icntl(2) = -1
      if (control%ldiag.gt.2) icntl(2) = control%mp
      icntl(3) = control%ldiag
      icntl(4) = control%pivoting
      icntl(5) = control%factor_blocking
      icntl(6) = control%btf
! Immediate return from MA48B/BD if LA is too small.
! Will make this not operate
      icntl(10) = 1
! Switch to slow mode if necessary?
      icntl(11) = 0
      if (control%switch_mode) icntl(11) = 1

      job = 1
! Can only have job=2 if there was a previous factorize with no dropping
      if (present(fast) .and. factors%ndrop==0 .and. factors%first.gt.1) &
          job = 2
      icntl(8) = 0
      if (present(partial) .and. factors%ndrop==0) then
        if(factors%partial.gt.0) then ! Note: can't test on above line as
                                      ! may not have been set.
          job = 3
          icntl(8) = 1
        endif
      endif

! Copy matrix for factorization
 101  factors%val(1:ne) = matrix%val(1:ne)

!!!!!!!!!!!!!!!  Call to MA48BD !!!!!!!!!!!!!!!!!!!!!!
      call ma48bd(factors%m,factors%n,ne,job,la,factors%val, &
                  factors%irn,factors%jcn, &
                  factors%keep,cntl,icntl, &
                  info,rinfo)
! Jump if failure in allocations in MA48/MA50
      if (info(1).eq.-10) go to 100
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

      if (info(1)==-3) then
! Increase size for factors and return with job = 1 call
         la = real(la,kind=wp)*multiplier
         deallocate (factors%val,stat=stat)
         allocate (factors%val(la),stat=stat)
         if (stat/=0) go to 100
! Copy irn
         allocate (itemp(la),stat=stat)
         if (stat/=0) go to 100
         itemp(1:ne) = factors%irn(1:ne)
         deallocate (factors%irn,stat=stat)
         allocate (factors%irn(la),stat=stat)
         if (stat/=0) go to 100
         factors%irn(1:ne) = itemp(1:ne)
         deallocate (itemp,stat=stat)

         job = 1
         goto 101

      end if

      if (info(1)==-7) then
         finfo%flag = -11
         if (control%ldiag>0 .and. control%lp>=0 ) &
            write (control%lp,'(/a,i3/a,i12)') &
            'Error return from MA48_FACTORIZE with finfo%flag = ',&
            finfo%flag,' Matrix entries unsuitable for fast factorization'
         return
      end if

      if (info(1).eq.2)    finfo%flag = finfo%flag + 4

      if (info(1)>=0) then
        finfo%lena_factorize = info(4)
        finfo%leni_factorize = info(4)
        finfo%len_factorize = info(4)
        factors%lareq = info(4)
        factors%lirnreq = info(4)
        finfo%rank   = info(5)
        finfo%drop   = info(6)
        finfo%ops    = rinfo(1)
        call nonzer(m,n,factors%keep,info)
        finfo%size_factor = info(2)+info(3)+info(4)
        factors%first = 2
      end if

      if (finfo%flag.gt.0) then
        if (control%ldiag>1 .and. control%wp>=0) &
          write (control%wp,'(/a/a,i5)') &
              'Warning from MA48_FACTORIZE: ', &
              'finfo%flag is equal to ',finfo%flag
      end if

      return

  100  finfo%flag = -4
       finfo%stat = stat
       if (control%ldiag>0 .and. control%lp>=0 ) &
         write (control%lp,'(/a,i3/a,i12)') &
         'Error return from MA48_FACTORIZE with finfo%flag = ',finfo%flag, &
         'Allocate failed with STAT =',stat

   end subroutine ma48_factorize_double

   SUBROUTINE ma48_solve_double(matrix,factors,rhs,x,control,sinfo,trans, &
                         resid,error)
      type(zd11_type), intent(in) :: matrix
      type(ma48_factors), intent(in) :: factors
      real(wp), intent(in) :: rhs(:)
      real(wp), intent(out) :: x(:)
      type(ma48_control), intent(in) :: control
      type(ma48_sinfo), intent(out) :: sinfo
      integer, optional, intent(in) :: trans
      real(wp), optional, intent(out) :: resid(2)
      real(wp), optional, intent(out) :: error
      integer icntl(20),job,m,n,stat
      integer(long) :: lasolve,info(20)
      integer(long), parameter :: lone = 1
      real(wp) cntl(10),err(3)
      logical trans48

      integer, allocatable :: iwork(:)
      real(wp), allocatable :: work(:)
      real(wp), allocatable :: rhswork(:)

! Check whether this has been preceded by a call to ma48_factorize
      if (factors%first .le. 1) then
         sinfo%flag = -10
         if (control%ldiag>0 .and. control%lp>=0 ) &
         write (control%lp,'(/a,i3/a,i12)') &
         'Error return from MA48_SOLVE with sinfo%flag = ',sinfo%flag, &
         'No prior call to MA48_FACTORIZE'
         return
      endif

      m = matrix%m
      n = matrix%n

      if(factors%m/=matrix%m) then
         sinfo%flag = -1
         sinfo%more = matrix%m
         if (control%ldiag>0 .and. control%lp>=0 ) &
           write (control%lp,'(/a,i3/a,i12,a,i12)') &
          'Error return from MA48_SOLVE with sinfo%flag = ',sinfo%flag, &
          'MATRIX%M has the value', matrix%m,' instead of',factors%m
       return
      end if

      if(factors%n/=matrix%n) then
         sinfo%flag = -2
         sinfo%more = matrix%n
         if (control%ldiag>0 .and. control%lp>=0 ) &
           write (control%lp,'(/a,i3/a,i12,a,i12)') &
          'Error return from MA48_SOLVE with sinfo%flag = ',sinfo%flag, &
          'MATRIX%N has the value', matrix%n,' instead of',factors%n
       return
      end if

      if(matrix%ne .lt. 0) then
         sinfo%flag = -3
         sinfo%more = matrix%ne
         if (control%ldiag>0 .and. control%lp>=0 ) &
         write (control%lp,'(/a,i3/a,i12)') &
          'Error return from MA48_SOLVE with sinfo%flag = ',sinfo%flag, &
          'MATRIX%NE has the value', matrix%ne
       return
      end if


      sinfo%flag = 0
      sinfo%more = 0
      sinfo%stat = 0

      if(matrix%ne .eq. 0) then
        x = 0.0d0
        if (present(resid)) resid = 0.0d0
        if (present(error)) error = 0.0d0
        return
      endif

      trans48 = present(trans)

      allocate (iwork(max(m,n)),work(max(3*m+n,3*n+m)),stat=stat)
      if (stat/=0) go to 100

      cntl(5)  = control%cgce
      icntl(1) = -1
      icntl(2) = -1
      if (control%ldiag.gt.2) icntl(2) = control%mp
      icntl(3) = control%ldiag
      icntl(5) = 0
      if (control%solve_blas.gt.1) icntl(5) = 2
      icntl(9) = control%maxit
      stat = 0

      job = 1
      if (control%maxit .gt. 0) then
        if (present(resid)) then
          if (present(error)) then
            job = 4
          else
            if (control%maxit == 1) then
              job = 2
            else
              job = 3
            end if
          end if
        end if
      end if

      if (trans48) then
        allocate (rhswork(n),stat=stat)
        if (stat/=0) go to 100
        rhswork = rhs(1:n)
      else
        allocate (rhswork(m),stat=stat)
        if (stat/=0) go to 100
        rhswork = rhs(1:m)
      endif

!!! Problem with kind = long is size statement
      lasolve = size(factors%val)*lone
      call ma48cd(factors%m,factors%n,trans48,job,  &
                  lasolve,factors%val, &
                  factors%irn,factors%keep,cntl,icntl,rhswork,   &
                  x,err,info)
! Jump if failure in allocations in MA48/MA50
       if (info(1).eq.-10) go to 100

      sinfo%flag = info(1)

!!!
! Only invoked if error return -8 or -9 from ma48cd
      if(sinfo%flag .lt. 0) then
         if (control%ldiag>0 .and. control%lp>=0 ) &
         write (control%lp,'(/a,i3)') &
          'Error return from MA48_SOLVE with sinfo%flag = ',sinfo%flag
       return
      end if

      if (job>1) resid(1) = err(1)
      if (job>1) resid(2) = err(2)
      if (job>3) error    = err(3)

      deallocate (iwork,work,rhswork,stat=stat)
      return

  100  sinfo%flag = -4
       sinfo%stat = stat
       if (control%ldiag>0 .and. control%lp>=0 ) &
         write (control%lp,'(/a,i3/a,i12)') &
         'Error return from MA48_SOLVE with sinfo%flag = ',sinfo%flag, &
         'Allocate failed with STAT =',stat

   end subroutine ma48_solve_double

   SUBROUTINE ma48_finalize_double(factors,control,info)
      type(ma48_factors), intent(inout) :: factors
      type(ma48_control), intent(in) :: control
      integer, intent(out) :: info

      info = 0

      if (allocated(factors%keep)) deallocate(factors%keep,stat=info)
      if (info==0 .and. allocated(factors%val))  deallocate &
                       (factors%irn,factors%jcn,factors%val,stat=info)
      if (info==0) return

      if (control%ldiag>0 .and. control%lp>=0 ) write (control%lp,'(/2a,i5)') &
         'Error return from MA48_finalize: ',&
         'deallocate failed with STAT =',info

    end subroutine ma48_finalize_double

      SUBROUTINE nonzer(M,N,KEEP,INFO)
!     NONZER should be called after MA48BD ..
! M,N,KEEP .. the same as for that call
! INFO(1)  Number of original entries excluding duplicates and out-of-range
! INFO(2)  Number of entries in off-diagonal blocks of block triangular form
! INFO(3)  Number of entries in triangular blocks on diagonal
! INFO(4)  Number of entries in L/U decomp of non-triangular blocks on diagonal
! INFO(3) and INFO(4) are separate because they are stored separately .. the
! INFO(3) entries are also used to calculate residuals.
      INTEGER M,N
      integer(long) :: keep(*)
      INTEGER(LONG) :: INFO(4)
! Declare internal variables
      INTEGER IPTRL,IPTRU,IPTRD,IPTRO,NBLOCK,MBLOCK,KBLOCK
      INTEGER NB,KB,JB,J1,J2,NC,NR,LC
! Pointers for KEEP array
      IPTRL = M+N
      IPTRU = IPTRL + N
      IPTRD = IPTRU + N
      IPTRO = IPTRD + N + 1
      NBLOCK = IPTRO + N - 1
      MBLOCK = NBLOCK + 1
      KBLOCK = MBLOCK + 1

      NB = KEEP(KBLOCK+3)

! Number of entries in original matrix with dups and o-o-r omitted
      INFO(1) = KEEP(IPTRO+N+1) - 1

! Number entries in off-diagonal blocks
      INFO(2) = KEEP(IPTRO+N+1) - KEEP(IPTRO+1)

! Number of entries in triangular diagonal blocks
      INFO(3) = 0
      J2 = 0
      LC = 0
      DO 100 JB = 1,NB
! NC is number of columns in block
        NC = KEEP(NBLOCK+3*JB)
        J1 = J2 + 1
        J2 = J1 + NC - 1
! MBLOCK negative flags triangular block
        IF (KEEP(MBLOCK+3*JB).LT.0) THEN
          INFO(3) = INFO(3) + KEEP(IPTRD+J2+1) - KEEP(IPTRD+J1)
        ELSE
! Recording information on last non-triangular block
          KB = JB
          NR = NC
          LC = J2
        ENDIF
  100 CONTINUE

! Compute number of entries in factors of non-triangular blocks
      IF (LC.EQ.0) THEN
! No non-triangular blocks
        INFO(4) = 0
      ELSE
        NC = NR
        IF (NB.EQ.1) THEN
! Only one block ...  matrix may be rectangular
          NR = M
          INFO(4) = 0
        ELSE
! Set to total number of entries in previous non-triangular blocks
          INFO(4) = KEEP(KBLOCK+3*KB) - 1
        ENDIF
! Add number of entries for last non-triangular block
! Sparse and full part
        INFO(4) = INFO(4) + KEEP(IPTRL+LC) +  &
                  MAX(((NC-KEEP(MBLOCK+3*KB))+(NR-KEEP(MBLOCK+3*KB))), &
                      ((NC-KEEP(MBLOCK+3*KB))*(NR-KEEP(MBLOCK+3*KB))))
      ENDIF

      end subroutine nonzer


  SUBROUTINE ma48_special_rows_and_cols_double(factors,rank,rows,cols,  &
                                               control,info)
      type(ma48_factors), intent(in) :: factors
      integer,intent(out) :: rank,info
      integer,intent(out),dimension(factors%m) :: rows
      integer,intent(out),dimension(factors%n) :: cols
      type(ma48_control), intent(in) :: control
      integer(long) :: la
      integer(long), parameter :: lone=1
      integer, allocatable :: iwork(:)

      allocate (iwork(max(factors%m,factors%n)),stat=info)
      if (info/=0) then
        info = -1

      if (control%ldiag>0 .and. control%lp>=0 ) write (control%lp,'(/2a,i5)') &
         'Error return from MA48_finalize: ',&
         'allocate failed with STAT =',info

        return
      end if
!!!!!
!     la = size(factors%val,kind=long)
      la = size(factors%val)*lone
      call ma51ad(factors%m,factors%n,la,factors%irn,factors%keep,rank, &
                  rows,cols,iwork)
      deallocate (iwork, stat=info)
   end subroutine ma48_special_rows_and_cols_double

   SUBROUTINE ma48_determinant_double(factors,sgndet,logdet,control,info)
      type(ma48_factors), intent(in) :: factors
      integer,intent(out) :: sgndet,info
      real(wp),intent(out) :: logdet
      type(ma48_control), intent(in) :: control
      integer(long) :: la
      integer(long), parameter :: lone = 1
      integer, allocatable :: iwork(:)
      allocate (iwork(factors%n),stat=info)
      if (info/=0) then
        info = -1

      if (control%ldiag>0 .and. control%lp>=0 ) write (control%lp,'(/2a,i5)') &
         'Error return from MA48_finalize: ',&
         'allocate failed with STAT =',info

        return
      end if
!!!!!
!     la = size(factors%val,kind=long)
      la = size(factors%val)*lone
      call ma51cd(factors%m,factors%n,la,factors%val,factors%irn, &
                  factors%keep,sgndet,logdet,iwork)
      deallocate (iwork, stat=info)
  end subroutine ma48_determinant_double

end module hsl_ma48_double
! COPYRIGHT (c) 2014 Science and Technology Facilities Council
! Original date 1 July 14, Version 1.0.0

!-*-*-*-*-*-*-*-*-*  H S L _ M I 3 2  double  M O D U L E  *-*-*-*-*-*-*-*-*-*

MODULE HSL_MI32_DOUBLE
      IMPLICIT NONE

!  --------------------------------------------------------------------
!
!  Solve the symmetric linear system
!
!     subject to       A x = b
!
!  using the MINRES method. A need not be definite
!
!  Tyrone Rees
!  June 2014
!
!  --------------------------------------------------------------------

!  Double precision version

      PRIVATE
      PUBLIC :: MI32_MINRES, MI32_FINALIZE

!  Define the working precision to be double

      INTEGER(i4), PARAMETER :: working = KIND( 1.0D+0 )

!  Paremeter definitions

      REAL ( KIND = working ), PARAMETER :: zero = 0.0_working
      REAL ( KIND = working ), PARAMETER :: one = 1.0_working

!  Derived type definitions

      TYPE, PUBLIC :: MI32_CONTROL
         REAL ( KIND = working ) :: stop_relative = sqrt(epsilon(1.0_working))
         REAL ( KIND = working ) :: stop_absolute = 0.0_working
         INTEGER(i4) :: out = -1
         INTEGER(i4) :: error = 6
         INTEGER(i4) :: itmax = -1
         INTEGER(i4) :: conv_test_norm = 1
         LOGICAL :: precondition = .true.
         LOGICAL :: own_stopping_rule = .false.
      END TYPE

      TYPE, PUBLIC :: MI32_INFO
         INTEGER(i4) :: st
         REAL ( KIND = working ) :: rnorm
         INTEGER(i4) :: iter
      END TYPE

      TYPE, PUBLIC :: MI32_KEEP
         PRIVATE
         INTEGER(i4) :: itmax
         INTEGER(i4) :: vold, vnew, wnew, wold, rold, rnew, zold, znew, gold, gnew
         REAL ( KIND = working ) :: rstop, stop_relative
         REAL ( KIND = working ) :: eta, diag, subd, tiny
         REAL ( KIND = working ), ALLOCATABLE, DIMENSION( : , : ) :: V
         REAL ( KIND = working ), ALLOCATABLE, DIMENSION( : , : ) :: W
         REAL ( KIND = working ), ALLOCATABLE, DIMENSION( : , : ) :: Z
         ! and ones I've added...
         REAL ( KIND = working ), DIMENSION( 2 ) :: co, si, gamma
         REAL ( KIND = working ), ALLOCATABLE :: R(:) !hold residual (if needed)
         REAL ( KIND = working ), ALLOCATABLE :: AW(:,:) ! Aw_0 and Aw_1
      END TYPE

   CONTAINS

!-*-*-*-*-*-  H S L _ M I 3 2 _ M I N R E S   S U B R O U T I N E   -*-*-*-*-*-

      SUBROUTINE MI32_MINRES( action, n, X, V_in, V_out, keep, control, info )

! =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
!
!  . Main MINRES iteration for A x = b .
!
!  Arguments:
!  =========
!
!   action  RCI action to complete. This must be set to 1 on initial
!                    entry and the residual vector A x - b placed in V_in.
!                    On exit, the value of status requires the following
!                    action from the user:
!           status = 0, the solution has been found
!           status = 2, the preconditioner must be applied to V_out,
!              with the result returned in V_in, and the subroutine
!              re-entered with all other arguments unchanged
!           status = 3, the product A * V_out must be formed, with
!              the result returned in V_in and the subroutine
!              re-entered with all other arguments unchanged
!           status = -1, n is not positive
!           status = -2, the iteration limit has been exceeded
!           status = -3, the system appears to be inconsistent
!           status = -4, an allocation error has occured. The
!              allocation status returned by ALLOCATE has the value
!              info%st
!   n       number of unknowns
!   X       the vector of unknowns. On entry, an initial estimate of the
!           solution, on exit, the best value found so far
!   V_in    see action = 1, 2, and 3
!   V_out   see action = 2, and 3
!   data    private internal data
!   control
!   info    a structure containing information. Components are
!            iter    the number of iterations performed
!            st      status of the most recent (de)allocation
!            rnorm   the M-norm of the residual
!
! =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

!-----------------------------------------------
!   D u m m y   A r g u m e n t s
!-----------------------------------------------

      INTEGER, INTENT( INOUT ) :: action
      INTEGER, INTENT( IN ) :: n
      REAL ( KIND = working ), INTENT( INOUT ), DIMENSION( n ) :: X, V_in
      REAL ( KIND = working ), POINTER, DIMENSION( : ) :: V_out
      TYPE ( MI32_KEEP ), TARGET, INTENT( INOUT ) :: keep
      TYPE ( MI32_CONTROL ), INTENT( IN ) :: control
      TYPE ( MI32_INFO ), INTENT( INOUT ) :: info

!-----------------------------------------------
!   L o c a l   V a r i a b l e s
!-----------------------------------------------

      INTEGER(i4) :: i
      REAL ( KIND = working ) :: delta = zero
      REAL ( KIND = working ) :: alp(4), ialp2
      LOGICAL :: reallocate
      CHARACTER ( LEN = 6 ) :: bad_alloc

!-----------------------------------------------
!   E x t e r n a l   P r o c e d u r e s
!-----------------------------------------------

!      EXTERNAL DLAEV2

!  Branch to appropriate part of the code

      SELECT CASE ( action )
      CASE ( 1 )  ! initialization
         GO TO 100
      CASE ( 2 )  ! after applying preconditioner
         GO TO 200
      CASE ( 3 )  ! after applying matrix-vector product
         GO TO 300
      CASE ( 4 )  ! after users' stopping rule
         GO TO 250
      END SELECT

!  On initial entry, set constants

  100 CONTINUE

!  Set initial values

      info%iter = 0
      info%st = 0

!  Ensure that n is positive

      IF ( n <= 0 ) THEN
         IF ( control%out >= 0 ) WRITE( control%out, 2040 )
         action = - 1
         GO TO 920
      END IF

!  Ensure that input parameters are in the right range

      keep%itmax = control%itmax
      IF ( keep%itmax < 0 ) keep%itmax = 2 * n! + 1
      keep%stop_relative =                                                    &
           MIN( ONE, MAX( control%stop_relative, EPSILON( one ) ) )

      if ( ( control%conv_test_norm < 1 ).or.( control%conv_test_norm > 2)) then
         IF ( control%out >= 0 ) WRITE( control%out, 2060 )
         action = -5
         GO TO 920
      end if

!  Allocate Q, W and S
      reallocate = .TRUE.
      IF ( ALLOCATED( keep%Z ) ) THEN
         IF ( SIZE( keep%Z, 1 ) < n .OR.                                      &
              SIZE( keep%Z, 2 ) < 2 ) THEN
              DEALLOCATE( keep%Z )
         ELSE
         reallocate = .FALSE.
         END IF
      END IF
      IF ( reallocate ) THEN
         ALLOCATE( keep%Z( n, 2 ), STAT = info%st )
         IF ( info%st /= 0 ) THEN
         bad_alloc = 'Z'
         GO TO 910
         END IF
      END IF

      reallocate = .TRUE.
      IF ( ALLOCATED( keep%W ) ) THEN
         IF ( SIZE( keep%W, 1 ) < n .OR.                                      &
              SIZE( keep%W, 2 ) < 2 ) THEN
              DEALLOCATE( keep%W )
         ELSE
         reallocate = .FALSE.
         END IF
      END IF
      IF ( reallocate ) THEN
         ALLOCATE( keep%W( n, 2 ), STAT = info%st )
         IF ( info%st /= 0 ) THEN
         bad_alloc = 'W'
         GO TO 910
         END IF
      END IF

      reallocate = .TRUE.
      IF ( ALLOCATED( keep%V ) ) THEN
         IF ( SIZE( keep%V, 1 ) < n .OR.                                      &
              SIZE( keep%V, 2 ) < 2 ) THEN
              DEALLOCATE( keep%V )
         ELSE
         reallocate = .FALSE.
         END IF
      END IF
      IF ( reallocate ) THEN
         ALLOCATE( keep%V( n, 2 ), STAT = info%st )
         IF ( info%st /= 0 ) THEN
         bad_alloc = 'V'
         GO TO 910
         END IF
      END IF
      keep%V = zero
      keep%W = zero

      if ( control%conv_test_norm == 1 ) then
         ! do nothing....
         continue
      elseif ( control%conv_test_norm == 2 ) then
         ALLOCATE( keep%AW( n, 3 ), STAT = info%st )
         IF ( info%st /= 0 ) THEN
            bad_alloc = 'AW'
            GO TO 910
         END IF
         keep%AW = zero
         ALLOCATE( keep%R( n ), STAT = info%st )
         IF ( info%st /= 0 ) THEN
            bad_alloc = 'R'
            GO TO 910
         END IF
         keep%R = zero
      end if



!      info%rnorm = SQRT( DOT_PRODUCT( V_in, V_in ) )
      if ( control%conv_test_norm == 2 ) then
         info%rnorm = SQRT( DOT_PRODUCT( V_in, V_in ) )
         keep%R = V_in
!     else
!        info%rnorm = SQRT( DOT_PRODUCT( V_in, V_in ) )
      end if

!  Set other initial values

      keep%wnew = 1
      keep%wold = 2
      keep%wnew = 1
      keep%wold = 2
      keep%vnew = 1
      keep%vold = 2
      keep%rnew = 1
      keep%rold = 2
      keep%gnew = 1
      keep%gold = 2

      keep%gamma = one

!      keep%Z( 1 ) = one ; keep%Z( 2 ) = zero
      keep%tiny = EPSILON( one )

      keep%V( : , keep%vnew ) = -V_in

!  ===========================
!  Start of the main iteration
!  ===========================

  190 CONTINUE

!  Return to obtain the product of M(inverse) with t

      IF ( control%precondition ) THEN
         V_out => keep%V( : , keep%vnew )
         action = 2
         RETURN
      ELSE
         V_in = keep%V( : , keep%vnew )
      END IF

!  Compute the off-diagonal of the Lanczos tridiagonal

  200 CONTINUE

      keep%gamma(keep%gold) = &
           SQRT( DOT_PRODUCT( V_in , keep%V( : , keep%vnew ) ) ) ! sqrt(z1'v1)

      i = keep%gnew
      keep%gnew = keep%gold
      keep%gold = i

      keep%Z( : , keep%vnew ) = V_in

      inital_iterate: IF ( info%iter == 0 ) THEN

         keep%eta = keep%gamma(keep%gnew)

         if ( control%conv_test_norm == 1 ) then
            info%rnorm = keep%eta ! use the initial M^{-1}-norm
         end if

         keep%si = zero
         keep%co = one

         !  Compute the stopping tolerence

         keep%rstop = MAX( info%rnorm * keep%stop_relative,   &
                           control%stop_absolute,             &
                           keep%tiny) ! include this so that immediate
                                      ! convergence can be detected



         IF ( control%out >= 0 ) WRITE( control%out, 2000 ) keep%rstop


      ELSE
         alp(1) = keep%co( keep%rnew ) * delta - &
                   keep%co(keep%rold) * keep%si( keep%rnew) * &
                   keep%gamma(keep%gold)
         alp(2) = sqrt( alp(1)**2 + keep%gamma(keep%gnew)**2 )
         ialp2 = one / alp(2)
         alp(3) = keep%si( keep%rnew ) * delta + &
                   keep%co( keep%rold ) * keep%co( keep%rnew ) * &
                   keep%gamma(keep%gold)
         alp(4) = keep%si(keep%rold) * keep%gamma(keep%gold)
         i = keep%rnew
         keep%rnew = keep%rold
         keep%rold = i

         keep%co( keep%rnew ) = alp(1)*ialp2
         keep%si( keep%rnew ) = keep%gamma(keep%gnew)*ialp2

         keep%W( : , keep%wold ) = keep%Z( : , keep%vold) - &
                               alp(4) * keep%W( : , keep%wold) - &
                               alp(3) * keep%W( : , keep%wnew)
         if (control%conv_test_norm == 2) then
            ! check....
            keep%AW( : , keep%wold ) = keep%AW( : , 3 ) - &
                 alp(4) * keep%AW( : , keep%wold ) - &
                 alp(3) * keep%AW( : , keep%wnew )
         end if
         i = keep%wnew
         keep%wnew = keep%wold
         keep%wold = i

         keep%W( : , keep%wnew ) = keep%W( : , keep%wnew ) * ialp2
         X = X + ( keep%co( keep%rnew ) * keep%eta ) * keep%W( : , keep%wnew )
         if (control%conv_test_norm == 2) then
            keep%AW( : , keep%wnew ) = keep%AW( : , keep%wnew ) * ialp2
            keep%R = keep%R + &
                     keep%co( keep%rnew ) * keep%eta * keep%AW(:,keep%wnew)
         end if


         keep%eta = - keep%si( keep%rnew ) * keep%eta
         if (control%conv_test_norm == 1) then
            info%rnorm = abs( keep%eta )
         else
            ! form \|r\|_2
            info%rnorm = sqrt(dot_product(keep%R,keep%R))
         end if

      END IF inital_iterate


!  Allow the user to check for termination

      stop: IF ( control%own_stopping_rule ) THEN
         action = 4
         RETURN

!  Check for termination

      ELSE
         IF ( info%rnorm <= keep%rstop ) THEN
            action = 0
            IF ( info%iter == 0 .AND. control%out >= 0 )                      &
                 WRITE( control%out, 2020 )                                   &
                    info%iter, info%rnorm, keep%gamma
            GO TO 900
         END IF
      END IF stop

! Since we haven't converged, test for singularity

      IF ( keep%gamma(keep%gnew) < keep%tiny ) THEN

         IF ( control%out >= 0 ) WRITE( control%out, 2050 )
         action = - 3
         GO TO 920

      END If


  250 CONTINUE

      !  Start a new iteration

      info%iter = info%iter + 1


      IF ( info%iter >= keep%itmax ) THEN
         IF ( control%out >= 0 ) WRITE( control%out, 2030 )
         action = - 2
         GO TO 920
      END IF


      keep%Z( : , keep%vnew ) = keep%Z( : , keep%vnew ) / keep%gamma(keep%gnew)

      !  Return to obtain the product of H with q

      V_out => keep%Z( : , keep%vnew )
      action = 3
      RETURN

  300 CONTINUE

      delta = dot_product ( V_in , keep%Z( : , keep%vnew ) )
      keep%V( : , keep%vold ) = V_in - &
                            ( delta/keep%gamma(keep%gnew) ) * &
                            keep%V ( : , keep%vnew ) - &
                            ( keep%gamma(keep%gnew)/keep%gamma(keep%gold) ) * &
                              keep%V ( : , keep%vold )

      i = keep%vnew
      keep%vnew = keep%vold
      keep%vold = i

      if ( control%conv_test_norm == 2 ) then
         keep%AW(:,3) = V_in ! store AZ in AW_3
      end if
      GO TO 190

!  Terminal returns

  900 CONTINUE
      RETURN

!  Unsuccessful returns

  910 CONTINUE
      action = - 4
      IF ( control%error > 0 ) WRITE( control%error, 2900 ) bad_alloc

  920 CONTINUE
      RETURN

!  Non-executable statements

 2000 FORMAT( ' stopping tolerence =' , ES12.4, //,                           &
              ' iter     rnorm       diag       subdiag   pivot ' )
! 2010 FORMAT( I6, 3ES12.4, L4 )
 2020 FORMAT( I6, ES12.4, '      -     ', ES12.4, L4 )
 2030 FORMAT( /, ' Iteration limit exceeded ' )
 2040 FORMAT( /, ' n not positive ' )
 2050 FORMAT( /, ' Singularity encountered ' )
 2060 FORMAT( /, 'Unsupported control%conv_test_norm supplied; must be 1 or 2' )
 2900 FORMAT( /, ' ** Message from -MI32_MINRES-', /,                         &
              '    Allocation error for array ', A6 )

   END SUBROUTINE MI32_MINRES

!*-*-*-*-*-  H S L _ M I 3 2 _ F I N A L I Z E   S U B R O U T I N E   -*-*-*-*-

   SUBROUTINE MI32_FINALIZE( keep )
      TYPE ( MI32_KEEP ), INTENT( INOUT ) :: keep

      INTEGER(i4) :: st

      ! Deallocate the arrays Z, W and V
      DEALLOCATE( keep%Z, STAT = st )
      DEALLOCATE( keep%W, STAT = st )
      DEALLOCATE( keep%V, STAT = st )

   END SUBROUTINE MI32_FINALIZE

END MODULE HSL_MI32_DOUBLE