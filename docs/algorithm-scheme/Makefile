.SILENT:
GE=graph-easy
GE_OPTS=--as=boxart

all: graphs

graphs: create-raid create-lvm delete-lvm delete-raid

create-raid: create-raid.txt
	$(GE) $(GE_OPTS) < $<

create-lvm: create-lvm.txt
	$(GE) $(GE_OPTS) < $<

delete-lvm: delete-lvm.txt
	$(GE) $(GE_OPTS) < $<

delete-raid: delete-raid.txt
	$(GE) $(GE_OPTS) < $<
