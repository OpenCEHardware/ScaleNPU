cores := tb_hs_npu_systolic

define core/tb_hs_npu_systolic
  $(this)/deps := hs_npu_systolic
  $(this)/targets := test

  $(this)/rtl_top := hs_npu_systolic

  $(this)/cocotb_paths := .
  $(this)/cocotb_modules := tb_hs_npu_systolic

endef
