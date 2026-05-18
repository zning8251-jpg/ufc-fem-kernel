!===============================================================================
! MODULE: IF_Mem_Def
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Def — Desc + State TYPEs for Memory domain
! BRIEF:  IF_Memory_Desc (pool config), IF_Memory_State (alloc statistics).
!===============================================================================
MODULE IF_Mem_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: IF_Memory_Desc
    INTEGER(i4) :: max_pool_size = 0      ! 0=unlimited
    LOGICAL     :: track_leaks   = .TRUE.
  END TYPE IF_Memory_Desc

  TYPE, PUBLIC :: IF_Memory_State
    INTEGER(i4) :: total_alloc_bytes = 0
    INTEGER(i4) :: peak_alloc_bytes  = 0
    INTEGER(i4) :: alloc_count       = 0
    INTEGER(i4) :: dealloc_count     = 0
  END TYPE IF_Memory_State

  !-- Algo: allocation strategy configuration --
  TYPE, PUBLIC :: IF_Memory_Algo
    INTEGER(i4) :: alignment_bytes  = 64_i4    ! AVX-512 default
    INTEGER(i4) :: growth_factor    = 2_i4     ! arena doubling
    LOGICAL     :: use_arena        = .TRUE.   ! arena vs system malloc
  END TYPE IF_Memory_Algo

  !-- Ctx: call-level allocation context --
  TYPE, PUBLIC :: IF_Memory_Ctx
    INTEGER(i4) :: caller_domain = 0_i4        ! IF_MEM_DOMAIN_*
    INTEGER(i4) :: request_bytes = 0_i4
  END TYPE IF_Memory_Ctx

END MODULE IF_Mem_Def
