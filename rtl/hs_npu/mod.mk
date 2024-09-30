cores := hs_npu_pkg hs_npu_systolic

define core/hs_npu_systolic
  $(this)/deps := hs_npu_pkg

  $(this)/rtl_top := hs_npu_systolic
  $(this)/rtl_files := \
    hs_npu_systolic.sv \
    hs_npu_mac.sv
endef

define core/hsv_core_pkg
  $(this)/deps := if_common hs_utils

  $(this)/rtl_files := hs_npu_pkg.sv
endef
