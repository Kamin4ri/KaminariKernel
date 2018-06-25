OBJS = bbm.o fc8180.o fc8180_bb.o fc8180_i2c.o fc8180_isr.o fc8180_ppi.o fc8180_spi.o fc8180_spib.o fc8180_tun.o fci_bypass.o fci_hal.o fci_hpi.o fci_i2c.o fci_oal.o fci_ringbuffer.o fci_tun.o

EXTRA_CFLAGS += -I$(PWD)/../inc
KDIR = /home/mv4412/src/mv4412-kernel-3.0.15
ODIR = $(PWD)/../

obj-m = isdbt.o
isdbt-objs = $(OBJS)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules
	mv *.ko			$(ODIR)
	mv *.o $(ODIR)
	mv isdbt.mod.c $(ODIR)
	mv Module.symvers $(ODIR)
	mv modules.order $(ODIR)
	mv .*.o.cmd $(ODIR)
	mv .*.ko.cmd $(ODIR)
	rm -rf $(ODIR)*.o
	rm -rf $(ODIR)isdbt.mod.c
	rm -rf $(ODIR)Module.symvers
	rm -rf $(ODIR)modules.order
	rm -rf $(ODIR).*.o.cmd
	rm -rf $(ODIR).*.ko.cmd


clean:
	rm -rf ../*.ko
	rm -rf *.o
	rm -rf isdbt.mod.c
	rm -rf Module.symvers
	rm -rf modules.order
	rm -rf .*.o.cmd
	rm -rf .*.ko.cmd
