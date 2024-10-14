define core
  $(this)/deps := peakrdl_intfs

  $(this)/rtl_files := \
    axib_if.sv \
    axil_if.sv \
    axil2regblock_if.sv \
    if_beats.sv \
    if_pkts.sv \
    if_rst_sync.sv \
    if_shake.sv \
    if_tap.sv
endef
