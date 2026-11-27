! Test predefined macros for the availability of the extended REAL kinds

! RUN: %if x86-registered-target %{ %flang_fc1 -triple x86_64-unknown-linux-gnu -cpp -E %s | FileCheck %s --check-prefixes=REAL10,REAL16 %}
! RUN: %if x86-registered-target %{ %flang_fc1 -triple x86_64-unknown-linux-gnu -fdisable-real-10 -cpp -E %s | FileCheck %s --check-prefixes=NOREAL10,REAL16 %}
! RUN: %if aarch64-registered-target %{ %flang_fc1 -triple aarch64-unknown-linux-gnu -cpp -E %s | FileCheck %s --check-prefixes=NOREAL10,REAL16 %}
! RUN: %if nvptx-registered-target %{ %flang_fc1 -triple nvptx64-nvidia-cuda -cpp -E %s | FileCheck %s --check-prefixes=NOREAL10,NOREAL16 %}

! REAL10: integer :: real10 = 1
! NOREAL10: integer :: real10 = 0
! REAL16: integer :: real16 = 1
! NOREAL16: integer :: real16 = 0

#if __GFC_REAL_10__
  integer :: real10 = __GFC_REAL_10__
#else
  integer :: real10 = 0
#endif
#if __GFC_REAL_16__
  integer :: real16 = __GFC_REAL_16__
#else
  integer :: real16 = 0
#endif
end program
