cc_srcs = $(call core_paths,$(1),cc_files)
ld_objs = $(call cc_srcs_to_objs,$(1),$(call cc_srcs,$(1))) $(call core_objs,$(1),ld_extra)
cc_srcs_to_objs = $(addsuffix .o,$(addprefix $(obj)/cc/$(1)/,$(basename $(notdir $(2)))))

define hooks/cc
  define obj_rules
    cc_binary := $$(call require_core_objs,$(1),ld_binary)

    $$(cc_binary): | $$(obj)/cc/$(1)
    $$(cc_binary): $$(foreach dep,$$(dep_tree/$(1)),$$(call ld_objs,$$(dep))) $$(obj_deps)
		$$(call run,LD,$$@) $$(core_info/$(1)/cross)gcc \
			$$(core_info/$(1)/cc_flags) $$(core_info/$(1)/ld_flags) \
			$$(foreach dep,$$(dep_tree/$(1)),$$(call ld_objs,$$(dep))) -o $$@

    $$(foreach dep,$$(dep_tree/$(1)),$$(obj)/cc/$$(dep)): $$(obj)
		@mkdir -p $$@
  endef

  $$(eval $$(call add_obj_rules,$(1)))

  $$(foreach dep,$$(dep_tree/$(1)), \
    $$(foreach src,$$(call cc_srcs,$$(dep)), \
      $$(eval $$(call cc_unit_rule,$(1),$$(dep),$$(src),$$(call cc_srcs_to_objs,$$(dep),$$(src))))))
endef

define cc_unit_rule
  define obj_rules
    $(4): | $$(obj)/cc/$(2)
    $(4): $(3) $$(obj_deps)
		$$(call run,CC,$$<) $(core_info/$(1)/cross)gcc $(core_info/$(1)/cc_flags) -MMD -c $$< -o $$@
  endef

  $$(eval $$(call add_obj_rules,$(1)))

  -include $$(patsubst %.o,%.d,$(4))
endef
