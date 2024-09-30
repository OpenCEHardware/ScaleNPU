targets += autococo

syntax2autococo := mk/scripts/syntax2autococo.py

define target/autococo/rules
  .PHONY: $$(rule_top_path)/autococo
  $$(rule_top_path)/autococo: $$(obj)/autococo.yaml

  $$(obj)/syntax.json &: $$(top_stamp)
	$$(call run,SYNTAX) $$(VERIBLE_SYNTAX) \
		--printtree --export_json -- \
  		$$(call require_core_paths,$$(rule_top),rtl_files) \
		>$$@

  $$(obj)/autococo.yaml: $$(obj)/syntax.json $$(syntax2autococo)
	$$(call run,YAML) \
		exec >>$$@ && \
		echo "output_dir: $$(obj)" && \
		echo "" && \
		echo "# Module and dependencies" && \
		echo "verilog_sources_and_include_dirs:" && \
		echo " - verilog_sources:" && \
		echo "   - specific_files:" && \
		for file in $$(foreach dep,$$(dep_tree/$$(rule_top)),$$(call core_paths,$$(dep),rtl_files)); do \
		echo "     - $$$$file"; \
		done && \
		echo "   - load_all_from:" && \
		for dir in $$(foreach dep,$$(dep_tree/$$(rule_top)),$$(call core_paths,$$(dep),rtl_dirs)); do \
		echo "     - $$$$dir"; \
		done && \
		echo " - verilog_include_dirs:" && \
		echo "   - specific_files:" && \
		echo "   - load_all_from:" && \
		for dir in $$(foreach dep,$$(dep_tree/$$(rule_top)),$$(call core_paths,$$(dep),rtl_include_dirs)); do \
		echo "     - $$$$dir"; \
		done && \
		echo "" && \
		echo "# Possible simulators are 'verilator' and 'questa'" && \
		echo "simulator: verilator" && \
		echo "timescale_timeprecision: 1ns/1ps" && \
		echo "DUT_name: $$(call require_core_var,$$(rule_top),rtl_top)" && \
		echo "template_name: tb_$$(rule_top)" && \
		$$(PYTHON3) $$(syntax2autococo) --top $$(call require_core_var,$$(rule_top),rtl_top) $$<

  $(call target_entrypoint,$$(rule_top_path)/autococo)
endef
