#===-- lib/quadmath/CMakeLists.txt -----------------------------------------===#
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===------------------------------------------------------------------------===#

# FortranFloat128 implements IEEE-754 128-bit float math functions.
# It is a thin wapper and it currently relies on third-party
# libraries available for the target.
# It is distributed as a static library only.
# Fortran programs/libraries that end up linking any of the provided
# will have a dependency on the third-party library that is being
# used for building this libflang_rt.quadmath library.

set(sources
  acos.cpp
  acosh.cpp
  asin.cpp
  asinh.cpp
  atan.cpp
  atan2.cpp
  atanh.cpp
  ceil.cpp
  complex-math.c
  cos.cpp
  cosh.cpp
  erf.cpp
  erfc.cpp
  exp.cpp
  exponent.cpp
  floor.cpp
  fma.cpp
  fraction.cpp
  hypot.cpp
  j0.cpp
  j1.cpp
  jn.cpp
  lgamma.cpp
  llround.cpp
  log.cpp
  log10.cpp
  lround.cpp
  mod-real.cpp
  modulo-real.cpp
  nearest.cpp
  nearbyint.cpp
  norm2.cpp
  pow.cpp
  random.cpp
  remainder.cpp
  round.cpp
  rrspacing.cpp
  scale.cpp
  set-exponent.cpp
  sin.cpp
  sinh.cpp
  spacing.cpp
  sqrt.cpp
  tan.cpp
  tanh.cpp
  tgamma.cpp
  trunc.cpp
  y0.cpp
  y1.cpp
  yn.cpp
  )

include_directories(AFTER "${CMAKE_CURRENT_SOURCE_DIR}/..")
add_library(FortranFloat128MathILib INTERFACE)
target_include_directories(FortranFloat128MathILib INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/..>
  )

# FLANG_RUNTIME_F128_MATH_LIB is validated by FlangCommon.cmake.
if (NOT FLANG_RUNTIME_F128_MATH_LIB)
  message(STATUS "Not building flang_rt.quadmath: "
    "FLANG_RUNTIME_F128_MATH_LIB=${FLANG_RUNTIME_F128_MATH_LIB}")
  return ()
elseif (FLANG_RUNTIME_F128_MATH_LIB STREQUAL "libquadmath")
  target_compile_definitions(FortranFloat128MathILib INTERFACE
    HAS_QUADMATHLIB
    )
  message(STATUS "Building flang_rt.quadmath using libquadmath")
elseif (FLANG_RUNTIME_F128_MATH_LIB STREQUAL "long double")
  # HAS_LDBL128 is defined by flang/Common/float128.h.
  message(STATUS "Building flang_rt.quadmath using libm's long double functions")
elseif (FLANG_RUNTIME_F128_MATH_LIB STREQUAL "float128")
  target_compile_definitions(FortranFloat128MathILib INTERFACE
    HAS_LIBMF128
    )
  message(STATUS "Building flang_rt.quadmath using libm's _Float128 functions")
endif ()

if (MSVC)
  # The Flang driver does not link flang_rt.quadmath for MSVC targets.
  # Instead, add the sources to flang_rt.runtime.
  target_sources(FortranFloat128MathILib INTERFACE ${sources})
else()
  add_flangrt_library(flang_rt.quadmath STATIC INSTALL_WITH_TOOLCHAIN
    ${sources})
  target_include_directories(flang_rt.quadmath PRIVATE
    "${FLANG_RT_SOURCE_DIR}/lib/flang_rt"
    )
  target_link_libraries(flang_rt.quadmath PRIVATE FortranFloat128MathILib)
endif()
