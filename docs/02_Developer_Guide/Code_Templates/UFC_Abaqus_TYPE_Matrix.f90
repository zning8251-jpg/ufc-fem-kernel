!===============================================================================
! UFC Abaqus Complete TYPE Mapping Matrix                        [Reference v1.0]
! 
! This file is a DOCUMENTATION REFERENCE only — not compiled.
! It records the complete mapping from Abaqus user subroutines to UFC TYPE
! four-piece kits (Desc / State / Algo / Ctx) across the three active layers.
!
! Architecture Summary:
!   L3_MD  (Model Description)  — What:  Desc types (immutable config)
!   L4_PH  (Physical Compute)   — How:   State + Algo types (runtime physics)
!   L5_RT  (Runtime Execution)  — When:  Domain Ctx types (call aggregator)
!
! Zero-copy time chain:
!   RT_XXX_Domain_Ctx%com_ctx -> RT_Com_Base_Ctx%global_ctx -> RT_Global_Ctx
!   (time_current / dtime / kstep / kinc accessed via pointer, no data copy)
!
! pnewdt convention (bare REAL(wp) INTENT(INOUT)):
!   < 1.0 => Cut increment (ABAQUS retries with smaller step)
!   > 1.0 => Suggest larger next step
!   = 1.0 => No change (use RT_PNEWDT_NO_CHANGE = 1.0_wp)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 1: MATERIAL — MD_Mat / PH_Mat / RT_Mat                             ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! Abaqus Subroutine → UFC Types
! ─────────────────────────────────────────────────────────────────────────────
! UMAT          → MD_Mat_Base_Desc (ABSTRACT, extends per model)
!                 MD_Mat_Base_State (ABSTRACT, stress/strain/energy history)
!                 MD_Mat_Base_Algo  (integration scheme, tangent flags)
!                 PH_Mat_Base_Ctx   (dstran, dfgrd1, temp at integration pt)
!                 RT_Mat_Domain_Ctx (com_ctx pointer + ph_ctx + ph_state)
!
! VUMAT         → MD_Mat_Base_Desc  (+ mat_family = MAT_FAMILY_VUMAT)
!                 MD_Mat_Base_State (same base; VUMAT has nblock)
!                 MD_Mat_Base_Algo
!                 PH_Mat_VUMAT_Ctx  (nblock, dstran_blk, dfgrd1_blk, temp_blk)
!                 RT_Mat_Domain_Ctx (mat_family = MAT_FAMILY_VUMAT)
!
! CREEP         → MD_Mat_CREEP_Desc (A_creep, n_creep, Q_creep, R_gas)
!                 PH_Mat_CREEP_State (decra, deswa, creep_strain, peeq_cr)
!                 RT_Mat_Domain_Ctx (mat_family = MAT_FAMILY_CREEP)
!
! UEXPAN        → MD_Mat_UEXPAN_Desc (alpha_iso, alpha_aniso, is_anisotropic)
!                 PH_Mat_UEXPAN_State (expan, dexpan)
!                 RT_Mat_Domain_Ctx (mat_family = MAT_FAMILY_UEXPAN)
!
! UHARD         → MD_Mat_UHARD_Desc  (sigma_y0, H_iso, H_kin, peeq_max)
!                 PH_Mat_UHARD_State  (syield, hard(3), peeq, eqplasrt)
!                 RT_Mat_Domain_Ctx (mat_family = MAT_FAMILY_UHARD)
!
! UHYPER        → MD_Mat_UHYPER_Desc (C10, C01, D1, hyper_order)
!                 PH_Mat_Base_State  (standard stress/tangent outputs)
!                 RT_Mat_Domain_Ctx (mat_family = MAT_FAMILY_UHYPER)
!
! UANISOHYPER_INV → MD_Mat_UANISOHYPER_INV_Desc (n_fib_fam, k1, k2, kappa_fib)
!                   RT_Mat_Domain_Ctx (mat_family = MAT_FAMILY_UANISOHYPER_INV)
!
! UMULLINS      → MD_Mat_UMULLINS_Desc (eta_inf, r_mul, m_mul, beta_mul)
!                 RT_Mat_Domain_Ctx (mat_family = MAT_FAMILY_UMULLINS)
!
! Source files:
!   MD_Mat_Types.f90  (L3, v3.2)    PH_Mat_Types.f90  (L4, v3.2)
!   RT_Domain_Types.f90 :: RT_Mat_Domain_Ctx  (L5, v1.0)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 2: ELEMENT — MD_Elem / PH_Elem / RT_Elem                           ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! UEL           → MD_Elem_Base_Desc (ndofel, nrhs, nsvars, props, coords desc)
!                 PH_Elem_Base_Ctx  (coords, du, predef, adlmag + mat_ctx embed)
!                 PH_Elem_Base_State (rhs, amatrx, svars, energy, u/v/a)
!                 RT_Elem_Domain_Ctx (elem_family = ELEM_FAMILY_UEL)
!
! VUEL          → MD_Elem_VUEL_Desc  (nblock, mass_scale, bulk_visc)
!                 PH_Elem_VUEL_Ctx   (nblock, coords_blk, du_blk, vel_blk,
!                                     accel_blk, char_length, mass_scale)
!                 PH_Elem_VUEL_State (f_int, f_ext, amass, dmass, svars_blk,
!                                     energy_blk, hg_force, dt_stable)
!                 RT_Elem_Domain_Ctx (elem_family = ELEM_FAMILY_VUEL)
!
! UELMAT        → MD_Elem_UELMAT_Desc (embed_mat_id, embed_mat_name)
!                 PH_Elem_UELMAT_Ctx  (mat_ctx, jtype, compute_* flags)
!                 RT_Elem_Domain_Ctx (elem_family = ELEM_FAMILY_UELMAT)
!
! Source files:
!   MD_Elem_Types.f90 (L3, v3.2)    PH_Elem_Types.f90 (L4, v4.1)
!   RT_Domain_Types.f90 :: RT_Elem_Domain_Ctx (L5, v1.0)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 3: LOAD — MD_Load / PH_Load / RT_Load                              ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! DLOAD/VDLOAD  → MD_Load_Base_Desc (load_family, amplitude_id, load_type)
!                 PH_Load_Base_Ctx  (coords, time, elem_id, face_id, sname)
!                 PH_Load_Base_State (value, value_vec, d_value)
!                 PH_Load_Base_Algo  (max_iter, tolerance, pnewdt_*)
!                 RT_Load_Domain_Ctx (load_family = LOAD_FAMILY_DLOAD)
!
! DFLUX/VDFLUX  → MD_Load_DFLUX_Desc (flux_type, flux_ref, film_coeff)
!                 PH_Load_DFLUX_Ctx  (temp, coords, jltyp, sname, noel, npt)
!                 RT_Load_Domain_Ctx (load_family = LOAD_FAMILY_DFLUX)
!
! FILM/VFILM    → MD_Load_FILM_Desc  (h_ref, temp_sink_ref, film_table_id)
!                 PH_Load_FILM_Ctx   (temp, coords, jltyp, sname, noel, npt,
!                                     h_film[OUT], temp_sink[OUT],
!                                     dh_dtemp[OUT], dsink_dtemp[OUT])
!                 RT_Load_Domain_Ctx (load_family = LOAD_FAMILY_FILM)
!
! HETVAL        → MD_Load_HETVAL_Desc (heat_gen_ref, activation_energy)
!                 PH_Load_HETVAL_Ctx  (temp, dtemp, statev, cmname,
!                                      flux[OUT], dflux_dtemp[OUT])
!                 RT_Load_Domain_Ctx (load_family = LOAD_FAMILY_HETVAL)
!
! UWAVE         → MD_Load_UWAVE_Desc  (wave_theory, water_depth, gravity)
!                 RT_Load_Domain_Ctx (load_family = LOAD_FAMILY_WAVE)
!
! Source files:
!   MD_Load_Types.f90 (L3, v1.1)    PH_Load_Types.f90 (L4, v1.1)
!   RT_Domain_Types.f90 :: RT_Load_Domain_Ctx (L5, v1.0)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 4: BOUNDARY CONDITION — MD_BC / PH_BC / RT_BC                     ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! DISP/VDISP    → MD_BC_Base_Desc  (bc_family, amplitude_id, dof_label)
!                 PH_BC_Base_Ctx   (node_id, dof_number, doflab, time, step/inc)
!                 PH_BC_Base_State (disp_val, d_disp)
!                 PH_BC_Base_Algo  (max_iter, tolerance, pnewdt_*)
!                 RT_BC_Domain_Ctx (bc_family = BC_FAMILY_DISP)
!
! UPOT          → MD_BC_UPOT_Desc  (dof_type: TEMP/EPOT/POR)
!                 PH_BC_UPOT_Ctx   (node_id, dof_id, doflab, time,
!                                   pot_val[OUT], d_pot[OUT])
!                 RT_BC_Domain_Ctx (bc_family = BC_FAMILY_UPOT)
!
! UTEMP         → MD_BC_UTEMP_Desc  (temp_ref, temp_table_id)
!                 PH_BC_UTEMP_Ctx   (node_id, coords, time,
!                                    temp_val[OUT], d_t[OUT])
!                 RT_BC_Domain_Ctx (bc_family = BC_FAMILY_UTEMP)
!
! UMASFL        → MD_BC_UMASFL_Desc (masfl_ref)
!                 PH_BC_UMASFL_Ctx  (node_id, dof_id, doflab, time,
!                                    masfl_val[OUT], d_masfl[OUT])
!                 RT_BC_Domain_Ctx (bc_family = BC_FAMILY_UMASFL)
!
! Source files:
!   MD_BC_Types.f90 (L3, v1.1)    PH_BC_Types.f90 (L4, v1.1)
!   RT_Domain_Types.f90 :: RT_BC_Domain_Ctx (L5, v1.0)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 5: CONTACT — MD_Contact / PH_Contact / RT_Contact                  ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! UINTER        → MD_Contact_Base_Desc (contact_family, nstatv, props)
!                 PH_Contact_Base_Ctx  (gap, slip1/2, pressure, temp, coords,
!                                       elem_id, integ_pt, tang1/2)
!                 PH_Contact_Base_State (traction_n/t1/t2, Jacobians, svars)
!                 PH_Contact_Base_Algo  (max_iter, tolerance, stabilization)
!                 RT_Contact_Domain_Ctx (contact_family = CONTACT_FAMILY_UINTER)
!
! VUINTER       → PH_Contact_VUINTER_Ctx (nblock, gap/slip/pres/temp_blk,
!                                          coords_blk, svars_blk)
!                 RT_Contact_Domain_Ctx (contact_family = CONTACT_FAMILY_VUINTER)
!
! GAPCON        → MD_Contact_GAPCON_Desc (cond_ref, pressure_dep)
!                 PH_Contact_GAPCON_Ctx  (gap, pressure, temp1, temp2, coords,
!                                         cond[OUT], dcond_dgap[OUT])
!                 RT_Contact_Domain_Ctx (contact_family = CONTACT_FAMILY_GAPCON)
!
! GAPELECTR     → MD_Contact_GAPELECTR_Desc (elec_cond_ref)
!                 RT_Contact_Domain_Ctx (contact_family = CONTACT_FAMILY_GAPELEC)
!
! Source files:
!   MD_Contact_Types.f90 (L3, v1.1)    PH_Contact_Types.f90 (L4, v1.1)
!   RT_Domain_Types.f90 :: RT_Contact_Domain_Ctx (L5, v1.0)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 6: FRICTION — MD_Friction / PH_Friction / RT_Friction              ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! FRIC          → MD_Fric_Base_Desc  (fric_law, mu_ref, tau_limit, elastic_slip)
!                 MD_Fric_Base_State (slip1/2_accum, tau1/2_prev, mu_eff, svars)
!                 MD_Fric_Base_Algo  (algorithm flags)
!                 PH_Fric_Base_Ctx   (slip1/2, dslip1/2, pressure, temp,
!                                     tau_max, coords, elem_id, svars)
!                 PH_Fric_Base_State (tau1/2, Jacobians, svars, is_sliding)
!                 PH_Fric_Base_Algo  (elastic_slip_tol, tau_tol, max_iter)
!                 RT_Fric_Domain_Ctx (fric_family = FRIC_SUBRT_FRIC)
!
! VFRIC         → PH_Fric_VFRIC_Ctx  (nblock, slip1/2_blk, dslip_blk,
!                                      pres_blk, temp_blk, tau_max_blk, svars_blk)
!                 RT_Fric_Domain_Ctx (fric_family = FRIC_SUBRT_VFRIC)
!
! FRIC_COEF     → MD_Fric_Coef_Desc  (mu_table_id, velocity_dep, temp_dep)
!                 PH_Fric_Coef_Ctx   (slip1/2, slip_rate, pressure, temp,
!                                     mu[OUT], dmu_dp[OUT], dmu_dT[OUT])
!                 RT_Fric_Domain_Ctx (fric_family = FRIC_SUBRT_FRIC_COEF)
!
! VFRIC_COEF    → PH_Fric_Coef_Ctx (with nblock, slip_rate_blk, mu_blk)
!                 RT_Fric_Domain_Ctx (fric_family = FRIC_SUBRT_VFRIC_COEF)
!
! Source files:
!   MD_Friction_Types.f90 (L3, v1.0)    PH_Friction_Types.f90 (L4, v1.0)
!   RT_Domain_Types.f90 :: RT_Fric_Domain_Ctx (L5, v1.0)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 7: CONSTRAINT — MD_Constraint / PH_Constraint / RT_Constraint      ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! UMPC          → MD_Constr_Base_Desc  (constr_type, n_constrained_dof)
!                 MD_Constr_MPC_Desc   (n_indep_nodes, dof_mask)
!                 PH_Constr_MPC_Ctx    (ndofc, jdof, node_c, u_ind, node_ind,
!                                       a[OUT], an[OUT], rhs_val[OUT])
!                 PH_Constr_Base_State (coeff_a, rhs, lmult, jac)
!                 PH_Constr_Base_Algo  (method, penalty_factor, tolerance)
!                 RT_Constr_Domain_Ctx (constr_family = CONSTR_FAMILY_MPC)
!
! UMESHMOTION   → MD_Constr_Orient_Desc (or separate ALE desc)
!                 PH_Constr_MeshMotion_Ctx (node_id, coords, disp_mat,
!                                           vel_mat, normal,
!                                           vel_mesh[OUT], weight[OUT])
!                 RT_Constr_Domain_Ctx (constr_family = CONSTR_FAMILY_MESHMOTION)
!
! Source files:
!   MD_Constraint_Types.f90 (L3, v1.0)    PH_Constraint_Types.f90 (L4, v1.0)
!   RT_Domain_Types.f90 :: RT_Constr_Domain_Ctx (L5, v1.0)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 8: FIELD VARIABLE — MD_Field / PH_Field / RT_Field                 ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! USDFLD        → MD_Field_Base_Desc   (nfield, nstatv, field_init, cmname)
!                 MD_Field_Base_State  (field_prev, dfield, statev)
!                 MD_Field_Base_Algo   (algorithm flags)
!                 PH_Field_Base_Ctx    (elem_id, integ_pt, cmname, nfield,
!                                       nstatv, field_prev, statev, temp, coords)
!                 PH_Field_Base_State  (field_val[OUT], statev[OUT],
!                                       stress/strain/peeq/triax cache)
!                 PH_Field_Base_Algo   (GETVRM flags, max_iter, tolerance)
!                 RT_Field_Domain_Ctx  (field_family = FIELD_FAMILY_USDFLD)
!
! VUSDFLD       → PH_Field_VUSDFLD_Ctx (nblock, temp_blk, coords_blk,
!                                        field_blk[IO], statev_blk[IO])
!                 RT_Field_Domain_Ctx  (field_family = FIELD_FAMILY_VUSDFLD)
!
! UFIELD        → PH_Field_UFIELD_Ctx  (node_id, coords, nfield,
!                                        field_val[OUT])
!                 RT_Field_Domain_Ctx  (field_family = FIELD_FAMILY_UFIELD)
!
! SDVINI        → MD_Field_SDVINI_Desc (sdv_init_type)
!                 PH_Field_SDVINI_Ctx  (elem_id, integ_pt, cmname, nstatv,
!                                        coords, statev_init[OUT])
!                 RT_Field_Domain_Ctx  (field_family = FIELD_FAMILY_SDVINI)
!
! SIGINI        → MD_Field_SIGINI_Desc (ntens, sigma_init, init_type,
!                                        gravity_dir, gravity_mag, rho_ref)
!                 RT_Field_Domain_Ctx  (field_family = FIELD_FAMILY_SIGINI)
!
! Source files:
!   MD_Field_Def.f90 (L3)            PH_Field_Def.f90 (L4)
!   RT_Domain_Types.f90 :: RT_Field_Domain_Ctx (L5, v1.0)
!
!===============================================================================
!
! ╔══════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 9: ANALYSIS CONTROL — MD_Analysis / PH_Analysis / RT_Analysis      ║
! ╚══════════════════════════════════════════════════════════════════════════════╝
!
! UEXTERNALDB   → MD_Analy_Base_Desc   (event_flags, file_config)
!                 MD_Analy_Base_State  (lop_state, is_initialized)
!                 MD_Analy_Base_Algo   (algorithm flags)
!                 PH_Analy_Base_Ctx    (lop, lrestart, time, kstep/kinc,
!                                       jobname, outdir, noel, nnode)
!                 PH_Analy_Base_State  (event_handled, files_open,
!                                       data_written, data_read)
!                 PH_Analy_Base_Algo   (call_on_* flags, max_files, output_every)
!                 RT_Analy_Domain_Ctx  (analy_family = ANALY_FAMILY_UEXTDB)
!
! UAMP          → MD_Analy_UAMP_Desc   (amp_name, amp_type, amp_ref)
!                 PH_Analy_UAMP_Ctx    (ampname, time, dtime, period,
!                                       amp_prev, d_amp_prev,
!                                       amp_val[OUT], d_amp[OUT], d2_amp[OUT])
!                 RT_Analy_Domain_Ctx  (analy_family = ANALY_FAMILY_UAMP)
!
! VUAMP         → PH_Analy_UAMP_Ctx    (with is_explicit=.TRUE., nblock,
!                                        time_blk, amp_blk[OUT], d_amp_blk[OUT])
!                 RT_Analy_Domain_Ctx  (analy_family = ANALY_FAMILY_VUAMP)
!
! UVARM         → MD_Analy_UVARM_Desc  (nuvarm, var_names)
!                 PH_Analy_UVARM_Ctx   (elem_id, integ_pt, cmname, nuvarm,
!                                       nstatv, stress/strain/peeq cache,
!                                       statev, coords, uvarm[OUT])
!                 RT_Analy_Domain_Ctx  (analy_family = ANALY_FAMILY_UVARM)
!
! Source files:
!   MD_Analysis_Types.f90 (L3, v1.0)    PH_Analysis_Types.f90 (L4, v1.0)
!   RT_Domain_Types.f90 :: RT_Analy_Domain_Ctx (L5, v1.0)
!
!===============================================================================
!
! COMPLETE TYPE COUNT SUMMARY
! ─────────────────────────────────────────────────────────────────────────────
! Domain          | L3_MD Types       | L4_PH Types            | L5_RT Ctx
! ─────────────────────────────────────────────────────────────────────────────
! Material (Mat)  | Base×3 + 6 ext    | Base×2 + 4 spec        | 1
! Element (Elem)  | Base×3 + 2 ext    | Base×2 + 2 spec        | 1
! Load            | Base×3 + 4 ext    | Base×3 + 3 spec        | 1
! BC              | Base×3 + 3 ext    | Base×3 + 3 spec        | 1
! Contact         | Base×3 + 2 ext    | Base×3 + 2 spec        | 1
! Friction        | Base×3 + 1 ext    | Base×3 + 2 spec        | 1
! Constraint      | Base×3 + 2 ext    | Base×3 + 2 spec        | 1
! Field           | Base×3 + 2 ext    | Base×3 + 3 spec        | 1
! Analysis        | Base×3 + 2 ext    | Base×3 + 2 spec        | 1
! Special (NEW)   | —                 | DFLOW/HARDINI/RSURFU/  | 1
!                 |                   | UCORR/UGENS ×3each     |
! Fluid (NEW)     | —                 | 8 subroutines ×3 each  | 1
! Misc (NEW)      | —                 | 8 subroutines ×3 each  | 1
! CFD (NEW)       | —                 | 2 subroutines ×3 each  | 1
! ─────────────────────────────────────────────────────────────────────────────
! Global/Common   | —                 | —                      | RT_Global_Ctx
!                 |                   |                        | RT_Com_Base_Ctx
! ─────────────────────────────────────────────────────────────────────────────
! TOTAL (v2.0)    | ~54 L3 types      | ~153 L4 types          | 13 L5 types
!                                                    GRAND TOTAL ≈ 526 types
!
! Note: "Base×3" = Desc + State + Algo; "spec" = subroutine-specific extensions
! Note: v2.0 adds Special(15)+Fluid(24)+Misc(24)+CFD(6)+Explicit-ext(30) = +99
!
!===============================================================================
!
! FILE INVENTORY (templates directory)
! ─────────────────────────────────────────────────────────────────────────────
!
! ╔════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 10: SPECIAL STANDARD — PH_Special / RT_Special                      ║
! ╚════════════════════════════════════════════════════════════════════════════╝
!
! DFLOW         → PH_Spec_DFLOW_Ctx    (coords, pore, amagc, time, noel, npt)
!                 PH_Spec_DFLOW_State  (seep_vel[3]: O  VELSEEP)
!                 PH_Spec_DFLOW_Algo   (use_darcy, permeability_ref)
!                 RT_Special_Domain_Ctx (spec_family = SPEC_FAMILY_DFLOW=1)
!
! HARDINI       → PH_Spec_HARDINI_Ctx  (peeq0, coords, noel, npt, cmname)
!                 PH_Spec_HARDINI_State (sigma_y0: O  initial yield stress)
!                 PH_Spec_HARDINI_Algo  (hardening_type, sigma_y_tol)
!                 RT_Special_Domain_Ctx (spec_family = SPEC_FAMILY_HARDINI=2)
!
! RSURFU        → PH_Spec_RSURFU_Ctx   (kframe, time, noel, faceid)
!                 PH_Spec_RSURFU_State  (xs[3], t1[3], t2[3]: O  surface frame)
!                 PH_Spec_RSURFU_Algo   (frame_update_mode)
!                 RT_Special_Domain_Ctx (spec_family = SPEC_FAMILY_RSURFU=3)
!
! UCORR         → PH_Spec_UCORR_Ctx    (freq, phase, node_i, node_j)
!                 PH_Spec_UCORR_State   (corr_val: O  correlation function value)
!                 PH_Spec_UCORR_Algo    (psd_type, correlation_model)
!                 RT_Special_Domain_Ctx (spec_family = SPEC_FAMILY_UCORR=4)
!
! UGENS         → PH_Spec_UGENS_Ctx    (ngens, coords, noel, orient)
!                 PH_Spec_UGENS_State   (gs[ngens*ngens]: O  section stiffness)
!                 PH_Spec_UGENS_Algo    (section_type, integration_order)
!                 RT_Special_Domain_Ctx (spec_family = SPEC_FAMILY_UGENS=5)
!
! Source files:
!   PH_Special_Types.f90 (L4, v1.0)  +15 TYPE
!   RT_Domain_Types.f90 :: RT_Special_Domain_Ctx (L5, v2.0)
!
!===============================================================================
!
! ╔════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 11: FLUID/ELECTROMAGNETIC — PH_Fluid / RT_Fluid                     ║
! ╚════════════════════════════════════════════════════════════════════════════╝
!
! UDECURRENT    → PH_Fluid_UDECURRENT_Ctx   (coords, normal, time, props)
!                 PH_Fluid_UDECURRENT_State  (current_dens[3]: O  DC current)
!                 PH_Fluid_UDECURRENT_Algo   (analysis_mode, ref_conductivity)
!                 RT_Fluid_Domain_Ctx (fluid_family = FLUID_FAMILY_UDECURRENT=1)
!
! UDEMPOTENTIAL → PH_Fluid_UDEMPOTENTIAL_Ctx  (node_id, coords, dof_type)
!                 PH_Fluid_UDEMPOTENTIAL_State (potential_val: O  electric potential)
!                 PH_Fluid_UDEMPOTENTIAL_Algo  (bc_type, reference_potential)
!                 RT_Fluid_Domain_Ctx (fluid_family = FLUID_FAMILY_UDEMPOTENTIAL=2)
!
! UDSECURRENT   → PH_Fluid_UDSECURRENT_Ctx    (coords, normal, time, props)
!                 PH_Fluid_UDSECURRENT_State   (charge_dens: O  surface charge)
!                 PH_Fluid_UDSECURRENT_Algo    (frequency, phase_shift)
!                 RT_Fluid_Domain_Ctx (fluid_family = FLUID_FAMILY_UDSECURRENT=3)
!
! UFLUID        → PH_Fluid_UFLUID_Ctx    (pressure, temp, time, nprops, props)
!                 PH_Fluid_UFLUID_State   (density, bulk_mod, viscosity,
!                                          d_rho_dp, d_bulk_dp: O fluid EOS)
!                 PH_Fluid_UFLUID_Algo    (eos_type, fluid_model, bulk_tol)
!                 RT_Fluid_Domain_Ctx (fluid_family = FLUID_FAMILY_UFLUID=4)
!
! UFLUIDCONNECTORLOSS → PH_Fluid_UFLUIDCONNECTORLOSS_Ctx   (pressure_drop, flow,
!                                                             temp, props)
!                        PH_Fluid_UFLUIDCONNECTORLOSS_State  (dp_loss: O)
!                        PH_Fluid_UFLUIDCONNECTORLOSS_Algo   (loss_model)
!                 RT_Fluid_Domain_Ctx (fluid_family = FLUID_FAMILY_CONNLOSS=5)
!
! UFLUIDCONNECTORVALVE → PH_Fluid_UFLUIDCONNECTORVALVE_Ctx
!                         PH_Fluid_UFLUIDCONNECTORVALVE_State (valve_coeff: O)
!                         PH_Fluid_UFLUIDCONNECTORVALVE_Algo  (valve_model)
!                 RT_Fluid_Domain_Ctx (fluid_family = FLUID_FAMILY_CONNVALVE=6)
!
! UFLUIDLEAKOFF → PH_Fluid_UFLUIDLEAKOFF_Ctx   (pressure, time, coords)
!                 PH_Fluid_UFLUIDLEAKOFF_State   (leakoff_rate: O  m/s)
!                 PH_Fluid_UFLUIDLEAKOFF_Algo    (leakoff_model, pore_pressure_ref)
!                 RT_Fluid_Domain_Ctx (fluid_family = FLUID_FAMILY_LEAKOFF=7)
!
! UFLUIDPIPEFRICTION → PH_Fluid_UFLUIDPIPEFRICTION_Ctx  (vel, dh, rho, mu)
!                       PH_Fluid_UFLUIDPIPEFRICTION_State  (friction_factor: O)
!                       PH_Fluid_UFLUIDPIPEFRICTION_Algo   (roughness_model)
!                 RT_Fluid_Domain_Ctx (fluid_family = FLUID_FAMILY_PIPEFRICTION=8)
!
! Source files:
!   PH_Fluid_Types.f90 (L4, v1.0)  +24 TYPE
!   RT_Domain_Types.f90 :: RT_Fluid_Domain_Ctx (L5, v2.0)
!
!===============================================================================
!
! ╔════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 12: MISCELLANEOUS STANDARD — PH_Misc / RT_Misc                       ║
! ╚════════════════════════════════════════════════════════════════════════════╝
!
! UMOTION       → PH_Misc_UMOTION_Ctx    (rbody_id, coords, vel, omega, time)
!                 PH_Misc_UMOTION_State   (disp[3], rot[3]: O  prescribed motion)
!                 PH_Misc_UMOTION_Algo    (motion_type, amplitude_id)
!                 RT_Misc_Domain_Ctx (misc_family = MISC_FAMILY_UMOTION=1)
!
! UPOREP        → PH_Misc_UPOREP_Ctx     (coords, noel, npt, cmname)
!                 PH_Misc_UPOREP_State    (pore_pressure_init: O  initial pore)
!                 PH_Misc_UPOREP_Algo     (consolidation_coeff, gamma_w)
!                 RT_Misc_Domain_Ctx (misc_family = MISC_FAMILY_UPOREP=2)
!
! UPRESS        → PH_Misc_UPRESS_Ctx     (jltyp, coords, time, noel, sname)
!                 PH_Misc_UPRESS_State    (press_val: O  normal pressure [Pa])
!                 PH_Misc_UPRESS_Algo     (distribution_type, amplitude_ref)
!                 RT_Misc_Domain_Ctx (misc_family = MISC_FAMILY_UPRESS=3)
!
! UPSD          → PH_Misc_UPSD_Ctx       (freq, node_i, dof_i, node_j, dof_j)
!                 PH_Misc_UPSD_State      (psd_value: O  power spectral density)
!                 PH_Misc_UPSD_Algo       (psd_type, normalization)
!                 RT_Misc_Domain_Ctx (misc_family = MISC_FAMILY_UPSD=4)
!
! UDMGINI       → PH_Misc_UDMGINI_Ctx    (stress[6], strain[6], eqplas,
!                                          triaxiality, lode_angle, strainrate)
!                 PH_Misc_UDMGINI_State   (dmg_indicator: O  damage onset [0..1],
!                                          is_initiated)
!                 PH_Misc_UDMGINI_Algo    (criterion_type, dmg_tol, alpha_factor)
!                 RT_Misc_Domain_Ctx (misc_family = MISC_FAMILY_UDMGINI=5)
!
! UXFEMNONLOCALWEIGHT → PH_Misc_UXFEMNONLOCALWEIGHT_Ctx  (coords, crk_coords[3,2],
!                                                           level_set_phi, level_set_psi)
!                        PH_Misc_UXFEMNONLOCALWEIGHT_State (weight_func: O)
!                        PH_Misc_UXFEMNONLOCALWEIGHT_Algo  (kernel_type, bandwidth)
!                 RT_Misc_Domain_Ctx (misc_family = MISC_FAMILY_UXFEM=6)
!
! VOIDRI        → PH_Misc_VOIDRI_Ctx     (coords, noel, npt, cmname)
!                 PH_Misc_VOIDRI_State    (void_ratio_init: O  initial void ratio)
!                 PH_Misc_VOIDRI_Algo     (soil_model, e_ref)
!                 RT_Misc_Domain_Ctx (misc_family = MISC_FAMILY_VOIDRI=7)
!
! UTRSNETWORK   → PH_Misc_UTRSNETWORK_Ctx    (temp, dtemp, time, npts, props)
!                 PH_Misc_UTRSNETWORK_State    (tau_network[npts]: O  relaxation mod.)
!                 PH_Misc_UTRSNETWORK_Algo     (network_model, n_branches)
!                 RT_Misc_Domain_Ctx (misc_family = MISC_FAMILY_UTRSNETWORK=8)
!
! Source files:
!   PH_Misc_Types.f90 (L4, v1.0)  +24 TYPE
!   RT_Domain_Types.f90 :: RT_Misc_Domain_Ctx (L5, v2.0)
!
!===============================================================================
!
! ╔════════════════════════════════════════════════════════════════════════════╗
! ║  DOMAIN 13: CFD — PH_CFD / RT_CFD                                             ║
! ╚════════════════════════════════════════════════════════════════════════════╝
!
! Note: SMACfdUserPressureBC / SMACfdUserVelocityBC are C-interface subroutines.
!       UFC provides Fortran TYPE wrappers as equivalent data carriers.
!
! SMACfdUserPressureBC → PH_CFD_PressureBC_Ctx   (coords, normal, time, density,
!                                                   temp_fluid, pressure_ref,
!                                                   velocity[3], bc_type, props)
!                         PH_CFD_PressureBC_State  (pressure_bc: O  prescribed P,
!                                                   dp_dt, dp_dv[3]: O  Jacobian)
!                         PH_CFD_PressureBC_Algo   (pressure_type, compressible,
!                                                   provide_jacobians, p_tol)
!                         RT_CFD_Domain_Ctx (cfd_family = CFD_FAMILY_PRESSURE_BC=1)
!
! SMACfdUserVelocityBC → PH_CFD_VelocityBC_Ctx   (coords, normal, time, density,
!                                                   pressure, temp_fluid,
!                                                   vel_current[3], bc_type, props)
!                         PH_CFD_VelocityBC_State  (velocity_bc[3]: O  prescribed V,
!                                                   dv_dt[3], dv_dp[3]: O Jacobian)
!                         PH_CFD_VelocityBC_Algo   (velocity_type, turbulence_model,
!                                                   provide_jacobians, v_tol)
!                         RT_CFD_Domain_Ctx (cfd_family = CFD_FAMILY_VELOCITY_BC=2)
!
! Source files:
!   PH_CFD_Types.f90 (L4, v1.0)  +6 TYPE
!   RT_Domain_Types.f90 :: RT_CFD_Domain_Ctx (L5, v2.0)
!
!===============================================================================
!
! DOMAIN 10-12 EXPLICIT EXTENSIONS (appended to PH_Explicit_Types.f90)
! ─────────────────────────────────────────────────────────────────────────────
! VEXTERNALDB      → PH_Expl_VEXTERNALDB_Ctx/State/Algo  (lop, nblock, timing)
! VFABRIC          → PH_Expl_VFABRIC_Ctx/State/Algo      (nblock, fabric tensor)
! VUCHARLENGTH     → PH_Expl_VUCHARLENGTH_Ctx/State/Algo (nblock, char length)
! VUCREEPNETWORK   → PH_Expl_VUCREEPNETWORK_Ctx/State/Algo (nblock, network)
! VUEOS            → PH_Expl_VUEOS_Ctx/State/Algo         (nblock, EOS params)
! VUFLUIDEXCH      → PH_Expl_VUFLUIDEXCH_Ctx/State/Algo  (nblock, fluid exch)
! VUFLUIDEXCHEFFAREA→ PH_Expl_VUFLUIDEXCHEFFAREA_Ctx/State/Algo (nblock, area)
! VUTRS            → PH_Expl_VUTRS_Ctx/State/Algo        (nblock, TRS Explicit)
! VUVISCOSITY      → PH_Expl_VUVISCOSITY_Ctx/State/Algo  (nblock, artificial visc)
! VWAVE            → PH_Expl_VWAVE_Ctx/State/Algo        (nblock, wave kinematics)
!
! Source file:
!   PH_Explicit_Types.f90 (L4, v2.0)  +30 TYPE (appended in this-round)
!
!===============================================================================
!
! FILE INVENTORY (templates directory)
! ─────────────────────────────────────────────────────────────────────────────
! L3_MD Layer:
!   MD_Mat_Types.f90        v3.2  — Material (UMAT/VUMAT/CREEP/UEXPAN/UHARD...)
!   MD_Elem_Types.f90       v3.2  — Element  (UEL/VUEL/UELMAT)
!   MD_Load_Types.f90       v1.1  — Load     (DLOAD/DFLUX/FILM/HETVAL/WAVE)
!   MD_BC_Types.f90         v1.1  — BC       (DISP/UPOT/UTEMP/UMASFL)
!   MD_Contact_Types.f90    v1.1  — Contact  (UINTER/VUINTER/GAPCON/GAPELECTR)
!   MD_Friction_Types.f90   v1.0  — Friction (FRIC/FRIC_COEF/VFRIC/VFRIC_COEF)
!   MD_Constraint_Types.f90 v1.0  — Constraint (UMPC/UMESHMOTION/ORIENT)
!   MD_Field_Types.f90      v1.0  — Field    (USDFLD/VUSDFLD/UFIELD/SDVINI/SIGINI)
!   MD_Analysis_Types.f90   v1.0  — Analysis (UEXTERNALDB/UAMP/VUAMP/UVARM)
!
! L4_PH Layer:
!   PH_Mat_Types.f90        v3.2  — Material (UMAT/VUMAT/CREEP/UEXPAN/UHARD)
!   PH_Elem_Types.f90       v4.1  — Element  (UEL/VUEL/UELMAT)
!   PH_Load_Types.f90       v1.1  — Load     (DLOAD/DFLUX/FILM/HETVAL)
!   PH_BC_Types.f90         v1.1  — BC       (DISP/UPOT/UTEMP/UMASFL)
!   PH_Contact_Types.f90    v1.1  — Contact  (UINTER/VUINTER/GAPCON)
!   PH_Friction_Types.f90   v1.0  — Friction (FRIC/VFRIC/FRIC_COEF/VFRIC_COEF)
!   PH_Constraint_Types.f90 v1.0  — Constraint (UMPC/UMESHMOTION)
!   PH_Field_Def.f90        v1.0  — Field    (USDFLD/VUSDFLD/UFIELD/SDVINI)
!   PH_Analysis_Types.f90   v1.0  — Analysis (UEXTERNALDB/UAMP/VUAMP/UVARM)
!   PH_Thermal_Types.f90    v1.0  — Thermal  (UMATHT + coupled-temperature)
!   PH_Explicit_Types.f90   v2.0  — Explicit (VDISP/VDLOAD/VUMAT/... +10 ext)
!   PH_Special_Types.f90    v1.0  — Special  (DFLOW/HARDINI/RSURFU/UCORR/UGENS)
!   PH_Fluid_Types.f90      v1.0  — Fluid/EM (UDECURRENT/.../UFLUIDPIPEFRICTION)
!   PH_Misc_Types.f90       v1.0  — Misc     (UMOTION/UDMGINI/UTRSNETWORK/...)
!   PH_CFD_Types.f90        v1.0  — CFD      (SMACfdUserPressureBC/VelocityBC)
!
! L5_RT Layer:
!   RT_Global_Types.f90     v1.0  — Global singleton (time/step/convergence)
!   RT_Com_Types.f90        v4.0  — Common context (global_ctx pointer + LFLAGS)
!   RT_Domain_Types.f90     v2.0  — 13 domain Ctx aggregators (9 orig + 4 new)
!   UFC_Populate_Template.f90 v1.0 — Populate phase subroutine templates
!   UFC_Memory_Strategy.f90 v1.0  — Memory lifecycle strategy + SafeDealloc
!
!===============================================================================
END  ! (intentional — this file is Fortran comment documentation only)
