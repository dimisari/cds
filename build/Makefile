
include Makefile.paths

SHELL := /bin/bash

GHC_flags := -no-keep-hi-files -no-keep-o-files

GHC := ghc $(GHC_flags) -i$(src)

MKDIR = @mkdir -p $(@D)

install: \
	$(local_bin_cds) $(share_dir_files) $(bashrc) $(nicknames_path) $(cd_info_path)

$(local_bin_cds): $(wildcard $(src)/*.hs)
	$(MKDIR); $(GHC) $(src)/Main.hs -o $@

$(bashrc): $(bash_append_file)
	if ! grep $(bash_append_file) $(bashrc); then \
		echo -e "\nsource $(bash_append_file)" >> $(bashrc); \
	fi

$(nicknames_path):
	$(MKDIR); touch $(nicknames_path)

$(cd_info_path):
	$(MKDIR); touch $(cd_info_path)

$(share_dir)/%: $(repo_share_dir)/%
	$(MKDIR); cp $< $@

uninstall:
	rm -rf $(local_bin_cds) $(share_dir)
	./del_bashrc_lines.sh $(bash_append_file) $(bashrc)

clean: uninstall

test: $(bashrc)

test1: $(bash_append_file)
