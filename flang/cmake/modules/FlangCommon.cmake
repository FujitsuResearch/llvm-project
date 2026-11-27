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

include(CheckCSourceCompiles)
include(CheckCXXSourceCompiles)
include(CheckIncludeFile)
include(CheckLibraryExists)
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

# Check availability of the implementations of IEEE-754 128-bit float math
# functions.

# 'long double' versions of libm functions (*l suffix).
# Note that '-nostdinc++' might be implied when this code kicks in
# (see 'runtimes/CMakeLists.txt'), so we cannot use 'cfloat' C++ header
# file in the test below.
# Compile it as C.
check_c_source_compiles(
  "#include <float.h>
   #if LDBL_MANT_DIG != 113
   #error LDBL_MANT_DIG != 113
   #endif
   int main() { return 0; }
  "
  HAVE_LDBL_MANT_DIG_113)
if (HAVE_LDBL_MANT_DIG_113)
  check_library_exists(m sinl "" FLANG_HAVE_LIBM_LDBL128)
endif ()

# _Float128 versions of libm functions (*f128 suffix), e.g. glibc >= 2.26.
cmake_push_check_state()
  list(APPEND CMAKE_REQUIRED_LIBRARIES m)
  check_cxx_source_compiles(
    "#define __STDC_WANT_IEC_60559_TYPES_EXT__ 1
     #include <math.h>
     int main(int argc, char **argv) {
       _Float128 x = argc;
       return sinf128(x) > 0;
     }
    "
    FLANG_HAVE_LIBM_F128)
cmake_pop_check_state()

# GCC's libquadmath (*q suffix).
if (FLANG_INCLUDE_QUADMATH_H)
  cmake_push_check_state()
    list(APPEND CMAKE_REQUIRED_LIBRARIES quadmath)
    check_c_source_compiles(
      "#include ${FLANG_INCLUDE_QUADMATH_H}
       int main(int argc, char **argv) { return sinq(argc) > 0; }
      "
      FLANG_HAVE_LIBQUADMATH)
  cmake_pop_check_state()
endif ()

if (HAVE_LDBL_MANT_DIG_113 AND FLANG_HAVE_LIBM_LDBL128)
  set(FLANG_RUNTIME_F128_MATH_LIB_default "long double")
elseif (FLANG_HAVE_LIBM_F128)
  set(FLANG_RUNTIME_F128_MATH_LIB_default "float128")
elseif (FLANG_HAVE_LIBQUADMATH)
  set(FLANG_RUNTIME_F128_MATH_LIB_default "libquadmath")
else ()
  set(FLANG_RUNTIME_F128_MATH_LIB_default "NO")
endif ()

# The out of tree builds of the compiler and the Fortran runtime
# must use the same setting of FLANG_RUNTIME_F128_MATH_LIB
# to be composable. Failure to synchronize this setting may result
# in linking errors or fatal failures in F128 runtime functions.
set(FLANG_RUNTIME_F128_MATH_LIB "${FLANG_RUNTIME_F128_MATH_LIB_default}" CACHE STRING
  "Specifies the implementation of IEEE-754 128-bit float math functions \
  used for REAL(16) intrinsics: NO (libflang_rt.quadmath is not built), \
  libquadmath (GCC's libquadmath), \"long double\" (libm functions for a \
  long double with 113 significand bits), or float128 (libm functions for \
  _Float128)."
  )
set_property(CACHE FLANG_RUNTIME_F128_MATH_LIB PROPERTY STRINGS
  NO libquadmath "long double" float128)

if (NOT FLANG_RUNTIME_F128_MATH_LIB)
  # REAL(16) math functions not available
elseif (FLANG_RUNTIME_F128_MATH_LIB STREQUAL "libquadmath")
  if (NOT FLANG_HAVE_LIBQUADMATH)
    message(FATAL_ERROR "FLANG_RUNTIME_F128_MATH_LIB=libquadmath requires "
      "quadmath.h and libquadmath to be available")
  endif ()
elseif (FLANG_RUNTIME_F128_MATH_LIB STREQUAL "long double")
  if (NOT HAVE_LDBL_MANT_DIG_113 OR NOT FLANG_HAVE_LIBM_LDBL128)
    message(FATAL_ERROR "FLANG_RUNTIME_F128_MATH_LIB=\"long double\" requires "
      "long double to have 113 significand bits and libm to provide its "
      "functions")
  endif ()
elseif (FLANG_RUNTIME_F128_MATH_LIB STREQUAL "float128")
  if (NOT FLANG_HAVE_LIBM_F128)
    message(FATAL_ERROR "FLANG_RUNTIME_F128_MATH_LIB=float128 requires "
      "libm to provide _Float128 functions")
  endif ()
else ()
  message(FATAL_ERROR "Unsupported value FLANG_RUNTIME_F128_MATH_LIB="
    "\"${FLANG_RUNTIME_F128_MATH_LIB}\"; must be one of NO, libquadmath, "
    "\"long double\", float128")
endif ()
