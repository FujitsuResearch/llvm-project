# Determine whether the Fortran compiler supports real(16)/quadmath types
#
# Implementation notes:
#
#  * FORTRAN_SUPPORTS_REAL16 can be set externally to override the detection.
#
#  * The compiler is not probed because in a bootstrapping-runtimes build,
#    CMAKE_Fortran_COMPILER is fakeflang which cannot answer compiler probes.
#    Instead, assume REAL(16) support for the architectures for which Flang's
#    frontend enables it, i.e. the LLVM backend can lower fp128 (see
#    flang/include/flang/Tools/TargetSetup.h). This also keeps the result
#    consistent between bootstrapping and standalone builds.
#
function (check_fortran_quadmath_support)
  if (DEFINED FORTRAN_SUPPORTS_REAL16)
    return ()
  endif ()

  if ("${LLVM_DEFAULT_TARGET_TRIPLE}" MATCHES "^(x86_64|amd64|i[3-9]86|aarch64|arm64|powerpc|ppc|riscv64|s390x|systemz|sparc|loongarch64)")
    set(_supports_real16 1)
    message(STATUS "Assuming REAL(16) support for ${LLVM_DEFAULT_TARGET_TRIPLE}")
  else ()
    set(_supports_real16 "")
    message(STATUS "Assuming no REAL(16) support for ${LLVM_DEFAULT_TARGET_TRIPLE}")
  endif ()
  set(FORTRAN_SUPPORTS_REAL16 "${_supports_real16}" CACHE INTERNAL
    "Whether the Fortran compiler supports REAL(16)")
endfunction ()
