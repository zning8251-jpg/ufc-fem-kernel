# Phase6 experimental driver + harness-linked tests (default OFF; does not alter ufc_core object libs).
option(UFC_BUILD_PHASE6_DRIVER "Build Phase6 harness-linked driver smoke executables" OFF)

if(NOT UFC_BUILD_PHASE6_DRIVER)
  return()
endif()

set(_UFC_ROOT "${CMAKE_CURRENT_LIST_DIR}/../..")
set(_PHASE6_LINK_TOOL "${_UFC_ROOT}/tools/phase6_link_build.py")

if(NOT EXISTS "${_PHASE6_LINK_TOOL}")
  message(WARNING "UFC: Phase6 link tool missing: ${_PHASE6_LINK_TOOL}")
  return()
endif()

find_program(PYTHON3_EXECUTABLE NAMES python3 python)
if(NOT PYTHON3_EXECUTABLE)
  message(WARNING "UFC: PYTHON not found; UFC_BUILD_PHASE6_DRIVER disabled")
  return()
endif()

message(STATUS "UFC: UFC_BUILD_PHASE6_DRIVER=ON — Phase6 profiles built via phase6_link_build.py")

add_custom_target(ufc_phase6_driver_rt_drv
  COMMAND "${PYTHON3_EXECUTABLE}" "${_PHASE6_LINK_TOOL}" --profile rt_drv
  WORKING_DIRECTORY "${_UFC_ROOT}"
  COMMENT "Phase6: build+run test_RT_RunModel_Ctx_model_def"
  VERBATIM
)

# WIP: production RT_Step_Exec + prod driver — expand compile list until link is green (see phase6_link_chains.json rt_drv_prod).
add_custom_target(ufc_phase6_driver_rt_drv_prod
  COMMAND "${PYTHON3_EXECUTABLE}" "${_PHASE6_LINK_TOOL}" --profile rt_drv_prod --build-only
  WORKING_DIRECTORY "${_UFC_ROOT}"
  COMMENT "Phase6: compile-only rt_drv_prod (production RT_Step_Exec closure)"
  VERBATIM
)

add_custom_target(ufc_phase6_driver_arclen
  COMMAND "${PYTHON3_EXECUTABLE}" "${_PHASE6_LINK_TOOL}" --profile arclen_linked
  WORKING_DIRECTORY "${_UFC_ROOT}"
  COMMENT "Phase6: build+run test_RT_NLSolver_ArcLen_min (linked)"
  VERBATIM
)

add_custom_target(ufc_phase6_driver_l6_bridge
  COMMAND "${PYTHON3_EXECUTABLE}" "${_PHASE6_LINK_TOOL}" --profile l6_bridge
  WORKING_DIRECTORY "${_UFC_ROOT}"
  COMMENT "Phase6: build+run test_Brg_AP_Job_L5_bridge"
  VERBATIM
)

add_custom_target(ufc_phase6_driver_matstate
  COMMAND "${PYTHON3_EXECUTABLE}" "${_PHASE6_LINK_TOOL}" --profile matstate_linked
  WORKING_DIRECTORY "${_UFC_ROOT}"
  COMMENT "Phase6: build+run test_MD_MatState_snapshot (linked)"
  VERBATIM
)

add_custom_target(ufc_phase6_driver ALL
  DEPENDS
    ufc_phase6_driver_rt_drv
    ufc_phase6_driver_arclen
    ufc_phase6_driver_l6_bridge
    ufc_phase6_driver_matstate
)
