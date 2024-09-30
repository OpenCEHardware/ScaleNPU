targets += lint

define target/lint/rules
  explicit_rtl := $$(call core_paths,$$(rule_top),rtl_files)

  rtl := \
    $$(filter %.sv, \
      $$(explicit_rtl) \
      $$(filter-out $$(explicit_rtl), \
        $$(foreach rtl_dir,$$(call core_paths,$$(rule_top),rtl_dirs) $$(call core_paths,$$(rule_top),rtl_include_dirs), \
          $$(wildcard $$(rtl_dir)/*))))

  .PHONY: $$(rule_top_path)/lint
  $$(rule_top_path)/lint: $$(strip $$(rtl))
	$$(call run_no_err,LINT) $$(VERIBLE_LINT) $$^

  $(call target_entrypoint,$$(rule_top_path)/lint)
endef
