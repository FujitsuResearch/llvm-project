#===-- cmake/modules/FlangCommon.txt ----------------------------===#
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===------------------------------------------------------------------------===#
#
# CMake definitions shared between Flang and Flang-RT
#
#===------------------------------------------------------------------------===#

include(CheckIncludeFile)
include(CMakePushCheckState)

# Discover the GCC installation, when the build compiler is Clang,
# and try to find quadmath.h there. Set FLANG_INCLUDE_QUADMATH_H
# to the path to quadmath.h, if found.
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  if (NOT DEFINED FLANG_GCC_RESOURCE_DIR)
    set(FLANG_GCC_RESOURCE_DIR "FLANG_GCC_RESOURCE_DIR-NOTFOUND")
    # Prepare CMAKE_CXX_FLAGS so that they can be passed to execute_process
    # as separate flags.
    separate_arguments(flags UNIX_COMMAND "${CMAKE_CXX_FLAGS}")
    execute_process(
      COMMAND "${CMAKE_CXX_COMPILER}" ${flags} -v "-###"
      ERROR_FILE "${CMAKE_CURRENT_BINARY_DIR}/clang_gcc_root_result"
    )
    file(STRINGS "${CMAKE_CURRENT_BINARY_DIR}/clang_gcc_root_result" _errorresult)
    foreach (_line IN LISTS _errorresult)
      string(REGEX MATCH
        "^Selected GCC installation: (.+)$"
        _match
        "${_line}")
      if (CMAKE_MATCH_1)
        set(FLANG_GCC_RESOURCE_DIR "${CMAKE_MATCH_1}")
        message(STATUS "Found GCC installation selected by Clang: ${FLANG_GCC_RESOURCE_DIR}")
        break()
      endif ()
    endforeach ()
    set(FLANG_GCC_RESOURCE_DIR "${FLANG_GCC_RESOURCE_DIR}" CACHE INTERNAL "Path to GCC's resource dir selected by Clang" FORCE)
  endif ()
endif ()

check_include_file("quadmath.h" FOUND_QUADMATH_H)
if (FOUND_QUADMATH_H)
  message(STATUS "quadmath.h found without additional include paths")
  set(FLANG_INCLUDE_QUADMATH_H "<quadmath.h>")
elseif (FLANG_GCC_RESOURCE_DIR)
  cmake_push_check_state()
    list(APPEND CMAKE_REQUIRED_INCLUDES "${FLANG_GCC_RESOURCE_DIR}/include")
    check_include_file("quadmath.h" FOUND_GCC_QUADMATH_H)
  cmake_pop_check_state()
  if (FOUND_GCC_QUADMATH_H)
    message(STATUS "quadmath.h found in Clang's selected GCC installation")
    set(FLANG_INCLUDE_QUADMATH_H "\"${FLANG_GCC_RESOURCE_DIR}/include/quadmath.h\"")
  endif ()
endif ()
