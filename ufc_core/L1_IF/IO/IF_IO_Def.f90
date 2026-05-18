!===============================================================================
! MODULE: IF_IO_Def
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Def — Desc + Ctx + State + Algo + Arg TYPEs for IO domain
! BRIEF:  Four-type definitions: IO_Desc (config), IO_Ctx (call context),
!         IO_State (runtime), IO_Algo (buffer/format settings).
!         Arg types: IF_IO_OpenFile_Arg, IF_IO_Filter_Arg.
!
! Status: FOUR-TYPE+ARG | Last verified: 2026-04-29
!===============================================================================
MODULE IF_IO_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: IF_IO_Desc
    INTEGER(i4)        :: unit_min     = 10
    INTEGER(i4)        :: unit_max     = 99
    CHARACTER(LEN=256) :: default_path = ""
  END TYPE IF_IO_Desc

  TYPE, PUBLIC :: IF_IO_Ctx
    INTEGER(i4)        :: current_unit = 0
    LOGICAL            :: unit_open    = .FALSE.
    CHARACTER(LEN=256) :: current_file = ""
  END TYPE IF_IO_Ctx

  !-- State: mutable runtime state --
  TYPE, PUBLIC :: IF_IO_State
    INTEGER(i4) :: files_open   = 0_i4
    INTEGER(i4) :: total_reads  = 0_i4
    INTEGER(i4) :: total_writes = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  END TYPE IF_IO_State

  !-- Algo: buffer / format configuration --
  TYPE, PUBLIC :: IF_IO_Algo
    INTEGER(i4) :: buffer_size    = 8192_i4   ! default 8 KB
    INTEGER(i4) :: default_format = 0_i4      ! 0=text, 1=binary
  END TYPE IF_IO_Algo

  !-- Cfg: IO domain configuration (used by IF_IO_Mgr) --
  TYPE, PUBLIC :: IF_IO_Cfg_Type
    INTEGER(i4) :: bufferSize   = 65536_i4
    LOGICAL     :: enBuffered   = .TRUE.
    LOGICAL     :: enCompressed = .FALSE.
  END TYPE IF_IO_Cfg_Type

  !-----------------------------------------------------------------------------
  ! TYPE: IF_IO_OpenFile_Arg (Arg — OpenFile input bundle)  [Phase 3F]
  !   Bundles >=6 params of IF_IO_OpenFile into a single Arg.
  !   mode/format use sentinel 0 = use default (matches IF_IO_MODE_UNSPECIFIED).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_IO_OpenFile_Arg
    CHARACTER(LEN=512) :: filename = ""
    INTEGER(i4)        :: mode     = 0_i4   ! 0=default(read); IF_IO_MODE_*
    INTEGER(i4)        :: format   = 0_i4   ! 0=default(text); IF_IO_FORMAT_*
  END TYPE IF_IO_OpenFile_Arg

  !-----------------------------------------------------------------------------
  ! TYPE: IF_IO_Filter_Arg (Arg — Filter procedure scalar bundle)  [Phase 3F]
  !   Bundles scalar params of IF_IO_Filter_* procs.
  !   Arrays (input/output buffers) remain as separate arguments.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_IO_Filter_Arg
    INTEGER(i4) :: input_size  = 0_i4   ! IN:  number of bytes in input buffer
    INTEGER(i4) :: output_size = 0_i4   ! OUT: number of bytes written to output
    INTEGER(i4) :: io_flags    = 0_i4   ! IN:  IF_IO_FILTER_FLAG_*
  END TYPE IF_IO_Filter_Arg

END MODULE IF_IO_Def
