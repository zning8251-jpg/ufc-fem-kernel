# ============================================================================
# CMakeLists.txt - Phase 4 KeyWord 补强项目单元测试配置
# ============================================================================
# Purpose:
#   配置 pFUnit 测试框架，编译并运行单元测试
#
# 使用方式:
#   mkdir build
#   cd build
#   cmake .. -GNinja
#   ninja
#   ctest
#
# ============================================================================

CMAKE_MINIMUM_REQUIRED(VERSION 3.16)

PROJECT(UFC_KeyWord_Tests Fortran)

# ============================================================================
# 编译器设置
# ============================================================================

SET(CMAKE_Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/mod)
SET(CMAKE_Fortran_FLAGS_DEBUG "-g -O0 -std=f2003 -Wall -Wextra")
SET(CMAKE_Fortran_FLAGS_RELEASE "-O2 -std=f2003")

# 默认为 Debug 模式
IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Debug)
ENDIF()

# ============================================================================
# 路径配置
# ============================================================================

SET(UFC_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")
SET(UFC_CORE "${UFC_ROOT}/ufc_core")
SET(UFC_BUILD "${UFC_ROOT}/build")
SET(L3_MD_DIR "${UFC_CORE}/L3_MD/KeyWord")

# ============================================================================
# 依赖项配置
# ============================================================================

# 查找 gfortran 编译模块
SET(MOD_DIRS
  ${UFC_BUILD}/mod
  ${CMAKE_BINARY_DIR}/mod
)

# 包含路径
INCLUDE_DIRECTORIES(${MOD_DIRS})

# ============================================================================
# 源文件配置
# ============================================================================

# L3_MD KeyWord 核心模块
SET(L3_MD_SOURCES
  ${L3_MD_DIR}/MD_KeyWord_Parser_Types.f90
  ${L3_MD_DIR}/MD_KeyWord_Parser_Recursive.f90
)

# 测试源文件
SET(TEST_SOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/L3_MD_KeyWord_Tests.f90
)

# ============================================================================
# 目标配置
# ============================================================================

# 添加可执行文件
ADD_EXECUTABLE(keywordtest_runner 
  ${L3_MD_SOURCES}
  ${TEST_SOURCES}
)

# 设置模块输出目录
SET_TARGET_PROPERTIES(keywordtest_runner PROPERTIES
  Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/mod
)

# 编译选项
TARGET_COMPILE_OPTIONS(keywordtest_runner PRIVATE
  -std=f2003
  -fsyntax-only
  -I${UFC_BUILD}/mod
)

# ============================================================================
# 测试配置
# ============================================================================

ENABLE_TESTING()

# 注册 pFUnit 测试
ADD_TEST(
  NAME KeyWord_Parser_Tests
  COMMAND keywordtest_runner
)

# ============================================================================
# 输出信息
# ============================================================================

MESSAGE(STATUS "UFC KeyWord 单元测试框架配置完成")
MESSAGE(STATUS "编译类型: ${CMAKE_BUILD_TYPE}")
MESSAGE(STATUS "Fortran 编译器: ${CMAKE_Fortran_COMPILER}")
MESSAGE(STATUS "模块目录: ${CMAKE_Fortran_MODULE_DIRECTORY}")
MESSAGE(STATUS "")
MESSAGE(STATUS "编译命令:")
MESSAGE(STATUS "  mkdir -p build")
MESSAGE(STATUS "  cd build")
MESSAGE(STATUS "  cmake .. -G\"Unix Makefiles\"")
MESSAGE(STATUS "  make")
MESSAGE(STATUS "")
MESSAGE(STATUS "测试运行:")
MESSAGE(STATUS "  ctest")
MESSAGE(STATUS "  或运行: ./keywordtest_runner")
