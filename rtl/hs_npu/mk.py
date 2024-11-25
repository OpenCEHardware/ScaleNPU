from mk import *

hs_npu                 = RtlPackage('hs_npu')
hs_npu_pkg             = RtlPackage('hs_npu_pkg')
hs_npu_top_flat        = RtlPackage('hs_npu_top_flat')
hs_npu_ctrlstatus_regs = RdlPackage('hs_npu_ctrlstatus_regs')
hs_npu_altera_ip       = QuartusQsysLibraryPackage('hs_npu_altera_ip') # Platform Designer library

if_common = find_package('if_common')
rtl       = find_files('**/*.sv')

hs_npu.requires (hs_npu_pkg)
hs_npu.requires (hs_npu_ctrlstatus_regs)
hs_npu.rtl      (rtl)
hs_npu.top      ()

hs_npu_pkg.requires (if_common)
hs_npu_pkg.rtl      (rtl.take('hs_npu_pkg.sv'))

hs_npu_top_flat.requires (hs_npu)
hs_npu_top_flat.rtl      (rtl.take('hs_npu_top_flat.sv'))
hs_npu_top_flat.top      ()

hs_npu_ctrlstatus_regs.rdl           ('hs_npu_ctrlstatus_regs.rdl')
hs_npu_ctrlstatus_regs.top           ()
hs_npu_ctrlstatus_regs.args          (['--default-reset', 'arst_n'])
hs_npu_ctrlstatus_regs.cpu_interface ('axi4-lite')

hs_npu_altera_ip.requires (hs_npu_top_flat)
hs_npu_altera_ip.hw_tcl   ('hs_npu_hw.tcl')
hs_npu_altera_ip.top      ('hs_npu_top_flat')
