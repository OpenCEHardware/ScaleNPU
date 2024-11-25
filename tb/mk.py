from mk import *

tb_hs_npu             = CocotbTestPackage('tb_hs_npu')
tb_hs_npu_fifo_keeper = CocotbTestPackage('tb_hs_npu_fifo_keeper')
tb_hs_npu_inference   = CocotbTestPackage('tb_hs_npu_inference')
tb_hs_npu_mm_unit     = CocotbTestPackage('tb_hs_npu_mm_unit')
tb_hs_npu_systolic    = CocotbTestPackage('tb_hs_npu_systolic')

hs_npu = find_package('hs_npu')

tb_hs_npu_fifo_keeper.requires       (hs_npu)
tb_hs_npu_fifo_keeper.rtl            ('fifo_keeper/hs_npu_fifo_keeper_test.sv')
tb_hs_npu_fifo_keeper.top            ('hs_npu_fifo_keeper_test')
tb_hs_npu_fifo_keeper.cocotb_paths   (['./fifo_keeper'])
tb_hs_npu_fifo_keeper.cocotb_modules (['tb_hs_npu_fifo_keeper'])

tb_hs_npu_inference.requires       (hs_npu)
tb_hs_npu_inference.top            ('hs_npu_inference')
tb_hs_npu_inference.cocotb_paths   (['./inference'])
tb_hs_npu_inference.cocotb_modules (['tb_hs_npu_inference'])

tb_hs_npu_mm_unit.requires       (hs_npu)
tb_hs_npu_mm_unit.top            ('hs_npu_mm_unit')
tb_hs_npu_mm_unit.cocotb_paths   (['./mm_unit'])
tb_hs_npu_mm_unit.cocotb_modules (['tb_hs_npu_mm_unit'])

tb_hs_npu_systolic.requires       (hs_npu)
tb_hs_npu_systolic.top            ('hs_npu_systolic')
tb_hs_npu_systolic.cocotb_paths   (['./systolic'])
tb_hs_npu_systolic.cocotb_modules (['tb_hs_npu_systolic'])

tb_hs_npu.requires       (hs_npu)
tb_hs_npu.rtl            ('npu/hs_npu_test.sv')
tb_hs_npu.top            ('hs_npu_top_flat')
tb_hs_npu.cocotb_paths   (['./npu'])
tb_hs_npu.cocotb_modules (['tb_hs_npu'])
