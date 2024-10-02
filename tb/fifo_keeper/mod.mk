cores := tb_hs_npu_fifo_keeper

define core/tb_hs_npu_fifo_keeper
  $(this)/deps := hs_npu_fifo_keeper
  $(this)/targets := test

  $(this)/rtl_top := hs_npu_fifo_keeper

  $(this)/cocotb_paths := .
  $(this)/cocotb_modules := tb_hs_npu_fifo_keeper

endef
