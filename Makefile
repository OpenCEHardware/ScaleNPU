top := hs_npu_systolic
core_dirs := rtl target tb

.PHONY: all

all: test

include mk/top.mk
