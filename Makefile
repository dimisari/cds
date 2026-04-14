
lbin=$(HOME)/.local/bin
bashrc=$(HOME)/.bashrc

cds_bin=$(lbin)/cds
cds_dir=$(HOME)/.local/share/cds

nns_path=$(cds_dir)/dir_nicknames
ba=bashrc_append.sh
bash_append_file=$(cds_dir)/$(ba)
paths_file=$(cds_dir)/paths_file
help_file=$(cds_dir)/help_files/help.txt
add_help_file=$(cds_dir)/help_files/add_help.txt
SHELL := /bin/bash

all: $(cds_bin) $(bash_append_file)
	source ~/.bashrc

$(cds_bin): cds
	mkdir -p $(lbin) ; cp $< $(lbin)

install: $(cds_bin) $(bash_append_file) $(cds_dir)
	cp -r help_files $(cds_dir) ; touch $(nns_path)

$(bash_append_file): $(paths_file) $(ba)
	cat $^ > $@

bash_append: $(bash_append_file)
	if ! grep $(bash_append_file) $(bashrc); then \
		echo "\nsource $<" >> $(bashrc); \
	fi

cds: cds.hs
	ghc -no-keep-hi-files -no-keep-o-files $<

$(paths_file): $(cds_dir)
	echo cds_bin=$(cds_bin) > $(paths_file)
	echo lbin=$(lbin) >> $(paths_file)
	echo cds_dir=$(cds_dir) >> $(paths_file)
	echo nns_path=$(nns_path) >> $(paths_file)
	echo help_file=$(help_file) >> $(paths_file)
	echo add_help_file=$(add_help_file) >> $(paths_file)

$(cds_dir):
	mkdir -p $@

uninstall:
	rm -rf $(cds_bin) $(cds_dir);
	./del_bashrc_lines.sh $(bash_append_file) $(bashrc)

clean:
	$(RM) cds
