#===-- cmake/modules/FlangRTFloat128.cmake ----------------------===#
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===------------------------------------------------------------------------===#

include(CheckCSourceCompiles)

set(FLANG_RUNTIME_F128_MATH_LIB "" CACHE STRING
  "Specifies the target library used for implementing IEEE-754 128-bit float \
  math in F18 runtime, e.g. it might be libquadmath for targets where \
  REAL(16) is mapped to __float128, or libm for targets where REAL(16) \
  is mapped to long double, etc."
  )
if (FLANG_RUNTIME_F128_MATH_LIB)
  add_compile_definitions(FLANG_RUNTIME_F128_MATH_LIB="${FLANG_RUNTIME_F128_MATH_LIB}")
endif()

# Check if 128-bit float computations can be done via long double
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
