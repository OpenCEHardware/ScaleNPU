cores := tb_hs_npu_inference

define core/tb_hs_npu_inference
  $(this)/deps := hs_npu_inference
  $(this)/targets := test

  $(this)/rtl_top := hs_npu_inference

  $(this)/cocotb_paths := .
  $(this)/cocotb_modules := tb_hs_npu_inference

endef
