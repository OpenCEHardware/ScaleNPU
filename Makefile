top := hs_npu
core_dirs := rtl target tb

.PHONY: all

all: test

include mk/top.mk
