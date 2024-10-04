cores := hs_npu_pkg hs_npu_systolic hs_npu_fifo_keeper hs_npu_mm_unit hs_npu_accumulator hs_npu_inference

define core/hs_npu_systolic
  $(this)/deps := hs_npu_pkg

  $(this)/rtl_top := hs_npu_systolic
  $(this)/rtl_files := \
    hs_npu_pkg.sv \
    hs_npu_systolic.sv \
    hs_npu_mac.sv 
endef

define core/hs_npu_mm_unit
  $(this)/deps := hs_npu_systolic hs_utils

  $(this)/rtl_top := hs_npu_mm_unit
  $(this)/rtl_files := \
    hs_npu_gatekeeper.sv \
    hs_npu_mm_unit.sv 
endef

define core/hs_npu_accumulator
  $(this)/deps := hs_npu_pkg

  $(this)/rtl_top := hs_npu_accumulator
  $(this)/rtl_files := \
    hs_npu_accumulator.sv
endef

define core/hs_npu_inference
  $(this)/deps := hs_npu_systolic hs_utils hs_npu_pkg hs_npu_mm_unit

  $(this)/rtl_top := hs_npu_inference
  $(this)/rtl_files := \
    hs_npu_accumulator.sv \
    hs_npu_activation.sv \
    hs_npu_inference.sv
endef

define core/hs_npu_fifo_keeper
  $(this)/deps := hs_npu_pkg hs_utils

  $(this)/rtl_top := hs_npu_fifo_keeper
  $(this)/rtl_files := \
    hs_npu_pkg.sv \
    hs_npu_gatekeeper.sv \
    hs_npu_fifo_keeper.sv
endef

define core/hsv_core_pkg
  $(this)/deps := 

  $(this)/rtl_files := hs_npu_pkg.sv
endef
