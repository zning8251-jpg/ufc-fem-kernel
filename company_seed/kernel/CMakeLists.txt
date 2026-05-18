cmake_minimum_required(VERSION 3.20)
project(FKernel VERSION 0.1.0 LANGUAGES C Fortran)

# ── Compiler Settings ──────────────────────────────────
if(CMAKE_Fortran_COMPILER_ID MATCHES "GNU")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -Wall -Wextra -fcheck=all -std=f2018")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -warn all -check all -stand f18")
endif()

# ── Layer Subdirectories ──────────────────────────────
# Build in strict dependency order
add_subdirectory(src/L0_Global)
add_subdirectory(src/L1_Infra)
add_subdirectory(src/L2_Numeric)
add_subdirectory(src/L3_Model)
add_subdirectory(src/L4_Physics)
add_subdirectory(src/L5_Runtime)
add_subdirectory(src/L6_App)

# ── Tests ─────────────────────────────────────────────
enable_testing()
add_subdirectory(${CMAKE_SOURCE_DIR}/../tests)
