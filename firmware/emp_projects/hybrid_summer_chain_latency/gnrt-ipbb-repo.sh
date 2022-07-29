#!/bin/sh
# This script creates the ipbb proj structure and the vivado project

ipbb init work
cd work

# Clone with Kerberos
ipbb add git https://:@gitlab.cern.ch:8443/mriggire/emp-fwk.git -b v0_7_0a_mriggire_patch
ipbb add git https://github.com/apollo-lhc/CM_FPGA_FW -b v1.2.2
ipbb add git https://gitlab.cern.ch/ttc/legacy_ttc.git -b v2.1
ipbb add git https://:@gitlab.cern.ch:8443/cms-tcds/cms-tcds2-firmware.git -b v0_1_1
ipbb add git https://gitlab.cern.ch/HPTD/tclink.git -r fda0bcf
ipbb add git https://github.com/ipbus/ipbus-firmware -b v1.9
ipbb add git https://github.com/cms-L1TK/l1tk-for-emp.git

L1TK_EMP_FIRM_DIR='src/l1tk-for-emp/tracklet/firmware/'

mv $L1TK_EMP_FIRM_DIR'hdl/emp_payload.vhd' $L1TK_EMP_FIRM_DIR'hdl/emp_payload.vhd.bak'
cp $L1TK_EMP_FIRM_DIR'cfg/serenity.dep' $L1TK_EMP_FIRM_DIR'cfg/serenity.dep.bak'

cp ./../latency_on_pin_fsm.vhd $L1TK_EMP_FIRM_DIR'hdl/'
cp ./../emp_payload.vhd $L1TK_EMP_FIRM_DIR'hdl/'

echo 'src latency_on_pin_fsm.vhd' >> $L1TK_EMP_FIRM_DIR'cfg/serenity.dep'

ipbb proj create vivado tracklet l1tk-for-emp:tracklet 'serenity.dep'
