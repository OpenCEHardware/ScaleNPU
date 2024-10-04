cores := tb_hs_npu_mm_unit

define core/tb_hs_npu_mm_unit
  $(this)/deps := hs_npu_mm_unit
  $(this)/targets := test

  $(this)/rtl_top := hs_npu_mm_unit

  $(this)/cocotb_paths := .
  $(this)/cocotb_modules := tb_hs_npu_mm_unit

endef
