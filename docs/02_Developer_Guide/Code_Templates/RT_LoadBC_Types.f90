!===============================================================================
! Template Note: RT_LoadBC_Types.f90                           [DEPRECATED NOTE]
! Layer:  L5_RT
! Domain: LoadBC runtime templates
!
! STATUS:
!   Do NOT copy this historical combined LoadBC quartet into new code.
!   The runtime layer has converged to a split + support architecture.
!
! CURRENT CANONICAL RUNTIME LAYOUT:
!   Load canonical:
!     - RT_Load_Def.f90
!     - RT_Load_Impl_Def.f90
!     - RT_Load_Impl.f90
!     - RT_Load_Brg.f90
!
!   BC canonical:
!     - RT_BC_Def.f90
!     - RT_BC_Impl_Def.f90
!     - RT_BC_Impl.f90
!     - RT_BC_Brg.f90
!     - RT_BC_ReactionForce.f90
!
!   LoadBC umbrella / support:
!     - RT_LoadBC_Proc.f90
!     - RT_LoadBC_ConstApply.f90
!     - RT_LoadBC_Core.f90   (LEGACY compatibility only)
!
! TEMPLATE MIGRATION RULES:
!   1. New Load-family _Proc templates must use RT_Load_Impl_Def (or the
!      appropriate split Load runtime types), not RT_LoadBC_Types.
!   2. New BC-family _Proc templates must use RT_BC_Impl_Def (or the
!      appropriate split BC runtime types), not RT_LoadBC_Types.
!   3. Constraint / Material / other runtime templates must define or reference
!      their own dedicated runtime quartet / dispatch types; do not borrow
!      LoadBC runtime types as a shortcut.
!   4. Generic support facades may keep the RT_LoadBC_* umbrella naming, but
!      they must route into split canonical implementations instead of reviving
!      a mixed RT_LoadBC_Desc / State / Algo / Ctx source of truth.
!
! OLD → NEW MAPPING:
!   RT_LoadBC_Desc   -> RT_Load_Desc + RT_BC_Desc, or impl desc pair
!   RT_LoadBC_State  -> RT_Load_State + RT_BC_State, or impl state pair
!   RT_LoadBC_Algo   -> RT_Load_Algo + RT_BC_Algo, or impl algo pair
!   RT_LoadBC_Ctx    -> RT_Load_Ctx + RT_BC_Ctx, or impl ctx pair
!
! NOTES FOR TEMPLATE AUTHORS:
!   - Prefer IF_Err_Brg over legacy IF_Err_API imports in new templates.
!   - Prefer *_Arg structured IO bundles in _Proc templates.
!   - Treat RT_LoadBC_Core as compatibility/support only, never as the
!     canonical owner of L5 runtime quartet definitions.
!===============================================================================
