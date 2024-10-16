cores := tb_hs_npu

define core/tb_hs_npu
  $(this)/deps := hs_npu_top_flat
  $(this)/targets := test

  $(this)/rtl_top := hs_npu_top_flat

  $(this)/cocotb_paths := .
  $(this)/cocotb_modules := tb_hs_npu

endef
