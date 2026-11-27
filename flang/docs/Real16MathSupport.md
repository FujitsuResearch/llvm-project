<!--===- docs/Real16MathSupport.md

   Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
   See https://llvm.org/LICENSE.txt for license information.
   SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

-->

# Flang support for REAL(16) math intrinsics

To support most `REAL(16)` (i.e. 128-bit float) math intrinsics Flang relies
on third-party libraries providing the implementation. Flang-RT provides the
math entry points in `libflang_rt.quadmath` which forward to one of the
following implementations, selected by the `FLANG_RUNTIME_F128_MATH_LIB` CMake
option:

 * `NO` (or any other CMake false value): `libflang_rt.quadmath` is not built.
 * `libquadmath`: GCC's `libquadmath` (functions with `q` suffix). Its header
   file `quadmath.h` must be available to the build compiler.
 * `"long double"`: `libm` functions for `long double` (functions with `l`
   suffix). Requires `long double` to have 113 significand bits
   (`LDBL_MANT_DIG == 113`).
 * `float128`: `libm` functions for `_Float128` (functions with `f128`
   suffix), as provided by glibc 2.26 or later.

If not set explicitly, the first available of `"long double"`, `float128`, and
`libquadmath` is selected, otherwise `NO`. The same setting is used by Flang
for the constant folding of `REAL(16)` math intrinsics.

The Flang driver links `libflang_rt.quadmath` if it finds it next to the other
Flang-RT libraries, and additionally links `libquadmath` (as needed) if it
finds it in the toolchain's library paths, such as the GCC installation.
Otherwise, programs that require its functions must be linked with
`-lquadmath` explicitly, which implies that `libquadmath` library has to be
available in the library search paths, so that linker can find it. The `libquadmath` library installation into Flang project
distribution is not automatic in CMake currently.

For MSVC targets, the sources are instead included in `flang_rt.runtime` and no
separate quadmath archive is built.

Testing shows that `libquadmath` versions before GCC-9.3.0 have
accuracy issues, so it is recommended to distribute the Flang
package with later versions of `libquadmath`.

Care must be taken by the distributors of a Flang package built
with `REAL(16)` support via `libquadmath` because of its licensing
under the GNU Library General Public License. Moreover, static linking
of `libquadmath` to the Flang users' programs may imply some
restrictions/requirements. This document is not intended to give
any legal advice on distributing such a Flang compiler.

Flang considers `REAL(16)` available when the LLVM backend reports that the
target's 128-bit floating-point type is legal, or provides libcall names for
addition, subtraction, multiplication, and division. This check is independent
of the availability of libraries implementing `REAL(16)` math intrinsics.
Libcall names do not guarantee that the corresponding implementations exist.
If `REAL(16)` is available, Flang predefines the preprocessor macro
`__GFC_REAL_16__` (and `__GFC_REAL_10__` for `REAL(10)`), like gfortran.
Flang-RT uses it to include `REAL(16)` in its intrinsic modules.

As a result, `REAL(16)` variables and arithmetic operations may be accepted
even when no library support for `REAL(16)` math intrinsics is available.
In such cases, references to math intrinsic functions can result in linker
errors rather than frontend diagnostics. For example:

```
FIRModule:(.text+0x97): undefined reference to `_FortranASinF128'
```

In such configurations, basic arithmetic operations such as addition,
subtraction, multiplication, and division may still work if they are
supported by the LLVM backend, while math intrinsics such as `SIN`, `COS`, `EXP`,
and `LOG` will require additional runtime library support.

This distinction can affect programs that use `SELECTED_REAL_KIND` to
determine whether `REAL(16)` is available. For example:

```Fortran
function test(x)
  integer, parameter :: k = merge(16, 4, selected_real_kind(p=33) .eq. 16)
  real(kind=k) :: x
  test = sin(x)
end function
```

When `SELECTED_REAL_KIND(p=33)` is evaluated during constant folding, it may
produce `16` if `REAL(16)` type support is available, even when the
corresponding math intrinsic library support is unavailable. In such cases
the program may compile successfully but fail to link because the required
`REAL(16)` math intrinsic implementations cannot be found.

Users who want to prevent any use of `REAL(16)` regardless of backend
support can use the `-fdisable-real-16` option.
