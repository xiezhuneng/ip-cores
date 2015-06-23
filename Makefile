##############################################################################################
#  In order to create a new project, change the first three macros in this file, the content #
#		of the UCF file and the name and content of the VHD files in src	     #
#	Don't forget to execute "source bin/load_modules" manual from the shell		     #
##############################################################################################

TOP=processor_E#change to the name of the TOP-Entity
DEVICE=3s50tq144-4
#DEVICE=xc3s4000-fg676-4#change to the device id found on the chip
#VHDLSYNFILES=src/cpu_types.vhd src/components.vhd src/processor_E.vhd src/processor.model.vhd src/ram.vhd src/rom.vhd #reference model for simulation
#VHDLSYNFILES=src/cpu_types.vhd src/components.vhd src/processor_E.vhd src/processor_E_backan.vhd src/ram.vhd src/rom.vhd#backannotated simulation after synthesis with Precision
#VHDLSYNFILES=src/cpu_types.vhd src/components.vhd src/processor_E.vhd src/processor_E_backannotated.vhd src/ram.vhd src/rom.vhd#backannotated simulation after synthesis with XST
VHDLSYNFILES=src/cpu_types.vhd src/alu.vhd src/control.vhd src/pc.vhd src/ram_control.vhd src/reg.vhd src/components.vhd src/processor_E.vhd src/ram.vhd src/rom.vhd #synthesis and pre-synthesis simulation

OPTMODE=Speed
OPTLEVEL=1
EFFORT=high
UCF=src/$(TOP).ucf
SCRIPTFILE=$(TOP).scr
PROJECTFILE=$(TOP).prj
LOGFILE=$(TOP).log
TOPSIM=$(TOP)_tb
DOFILE=src/$(TOP).do
BITGEN=src/$(TOP).ut
ALLFILES=$(VHDLSYNFILES) src/$(TOPSIM).vhd
SHELL=/bin/bash

all: help

help:
	@echo
	@echo " make help			: prints this help menu "
	@echo " make use-vsim			: simulate with Modelsim in batch mode, use >>do it<< to reload"
	@echo " make use-vsim-gui		: simulate with Modelsim and GUI"
	@echo " make use-xst			: synthesize with xst "
	@echo " make implement			: final step"
	@echo " make ml			: prints loaded modules. Use source bin/load_modules if modules are not loaded "
	@echo " make files			: prints info about the used files "
	@echo " make vsim-help			: prints appropriate steps for simulation"
	@echo " make warnings-xst		: prints warnings and info from the XST log file"
	@echo " make warnings-implement		: prints warnings and info from the PAR log file" 
	@echo " make clear			: clears all XST output files"
	@echo

use-xst: $(VHDLSYNFILES)
	@rm -f $(SCRIPTFILE)
	@rm -f $(LOGFILE)
	@rm -f $(PROJECTFILE)
	@for i in $(VHDLSYNFILES); do bin/xstvhdl $$i >> $(PROJECTFILE); done
	@echo run -ifn $(PROJECTFILE) -ifmt vhdl -ofn $(TOP).ngc -ofmt NGC -p $(DEVICE) -opt_mode $(OPTMODE) -opt_level $(OPTLEVEL) -top $(TOP) -rtlview yes > $(SCRIPTFILE)
	@xst -ifn $(SCRIPTFILE) -ofn $(LOGFILE)

implement: $(TOP).ngc
	@mv -f src/*.ucf $(UCF)TMP 
	@mv -f $(UCF)TMP $(UCF)
	@mv -f src/*.ut $(BITGEN)TMP
	@mv -f $(BITGEN)TMP $(BITGEN)
	bin/route_ngc $(TOP) $(UCF) $(DEVICE) $(EFFORT) $(BITGEN)

ml:
	@/home/4all/packages/modules-2.0/sun5/bin/modulecmd tcsh list

use-vsim: it $(ALLFILES)
	@rm -f it
	@for i in $(ALLFILES); do bin/vscript $$i >> it0; done
	@echo restart > it1
	@echo run -all > it2
	@cat it0 it1 it2 > it
	@rm -f it0 it1 it2
	@vmap -del work
	@rm -rf modelsim/
	@mkdir modelsim
	@vlib modelsim/work
	@vmap work modelsim/work
	@vcom -93 -check_synthesis -work work $(VHDLSYNFILES)
	@vcom -93 -work work src/$(TOPSIM).vhd
	@mv -f src/*.do $(DOFILE)TMP
	@mv -f $(DOFILE)TMP $(DOFILE)
	vsim -c work.$(TOPSIM) -do $(DOFILE)

use-vsim-gui: $(ALLFILES)
	@rm -f it
	@for i in $(ALLFILES); do bin/vscript $$i >> it0; done
	@echo restart > it1
	@echo run 1000 ns > it2
	@cat it0 it1 it2 > it
	@rm -f it0 it1 it2
	@vmap -del work
	@rm -rf modelsim/
	@mkdir modelsim
	@vlib modelsim/work
	@vmap work modelsim/work
	@vcom -93 -check_synthesis -work work $(VHDLSYNFILES)
	@vcom -93 -work work src/$(TOPSIM).vhd
	@mv -f src/*.do $(DOFILE)TMP
	@mv -f $(DOFILE)TMP $(DOFILE)
	vsim -gui work.$(TOPSIM) -do it &
#	vsim -sdftyp /processor_e_tb/u_cpu=src/processor_E_backan.sdf -gui work.$(TOPSIM) -do it & 

use-vsim-cov: $(ALLFILES)
	vmap -del work
	rm -rf modelsim
	mkdir modelsim
	vlib modelsim/work
	vmap work modelsim/work
	vcom -cover bcst -f coverage.file
	vsim -coverage -gui work.$(TOPSIM)
# load the rtl_a architecture in the tb file 

clear:
	@rm -f $(TOP).ngr $(TOP).msd $(TOP).msk $(TOP).rbt $(TOP).twr $(TOP).xpi $(TOP)_pad.csv $(TOP)_pad.txt $(TOP).bld
	@rm -f $(TOP).ngc $(TOP).ncd $(TOP).ngd $(TOP).rba $(TOP).rbd $(TOP).rbb netlist.lst $(TOP).mrp $(TOP).ll $(TOP).bit
	@rm -f $(TOP).lso $(TOP).ngm $(TOP).ngr $(TOP).pad $(TOP).par $(TOP).pcf transcript vsim.wlf $(TOP).log $(TOP).bgn *.twr *.xml *.map *.unroutes
	@rm -f $(SCRIPTFILE)
	@rm -f $(LOGFILE)
	@rm -f $(PROJECTFILE)

files:
	@echo
	@echo $(TOP)".ngc	: netlist output from XST"
	@echo $(TOP)".ngr	: netlist output from XST for RTL and Technology viewers"
	@echo $(TOP)".scr	: script file for XST, generated by Makefile"
	@echo $(TOP)".prj	: contains the vhdl source files, generated by Makefile."
	@echo $(TOP)".log	: log file, output from XST"
	@echo $(TOP)".ucf	: user constraints file with pins description, write yourself"
	@echo $(TOP)".ut	: config. script for BITGEN, write yourself"
	@echo "it		: do-script for Modelsim in batchmode, write yourself"
	@echo $(TOP)".do	: do-script for Modelsim in GUI-mode, write yourself"
	@echo $(TOP)".par	: PAR report file, generated by make implement"
	@echo

vsim-help:
	@echo
	@echo " mkdir modelsim						: create main directoriy for simulation"
	@echo " vlib modelsim/work					: create work library for simulation"
	@echo " vmap							: prints all logical mapped librarys"
	@echo " vmap -del work						: delete actual mapping for work library"
	@echo " vmap work modelsim/work				: map logical library work to modelsim/work"
	@echo " vcom -93 -check_synthesis  -work work <vhdl_files>	: compile source vhdl files"
	@echo " vcom -93 -work work <tb_vhdl_files>			: compile top level testbench"	
	@echo " do it		: use in batch mode to recompile the testbench and the top entity and to restart the simulation"
	@echo	

warnings-xst:
	@grep -n -i warning *.log
	@grep -n -i info *.log

warnings-implement:
	@grep -n -i warning *.par *.twr
	@grep -n -i info *.par *.twr
