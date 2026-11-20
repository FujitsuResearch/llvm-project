! Verify that flang_rt.quadmath and libquadmath are only linked when they are
! found.

! RUN: %flang -### --target=x86_64-unknown-linux-gnu %S/Inputs/hello.f90 \
! RUN:     -resource-dir=%S/Inputs/resource_dir \
! RUN:     --sysroot=%S/Inputs/quadmath_linux_tree 2>&1 \
! RUN:   | FileCheck %s --check-prefixes=CHECK,NONE

! RUN: %flang -### --target=x86_64-unknown-linux-gnu %S/Inputs/hello.f90 \
! RUN:     -resource-dir=%S/Inputs/resource_dir_with_flang_rt_quadmath \
! RUN:     --sysroot=%S/Inputs/basic_cross_linux_tree 2>&1 \
! RUN:   | FileCheck %s --check-prefixes=CHECK,FLANGRT

! RUN: %flang -### --target=x86_64-unknown-linux-gnu %S/Inputs/hello.f90 \
! RUN:     -resource-dir=%S/Inputs/resource_dir_with_flang_rt_quadmath \
! RUN:     --sysroot=%S/Inputs/quadmath_linux_tree 2>&1 \
! RUN:   | FileCheck %s --check-prefixes=CHECK,LIBQUADMATH

! CHECK-LABEL: "{{.*}}ld{{(\.exe)?}}"

! NONE-NOT:  "-lflang_rt.quadmath"
! NONE-NOT:  "-lquadmath"
! NONE:      "-lflang_rt.runtime" "-lm"

! FLANGRT-SAME:  "-lflang_rt.quadmath" "-lflang_rt.runtime" "-lm"

! LIBQUADMATH-SAME: "-lflang_rt.quadmath" "--as-needed" "-lquadmath" "--no-as-needed" "-lflang_rt.runtime" "-lm"
