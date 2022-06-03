#!/bin/sh
# This script creates the ipbb proj structure and the vivado project

ipbb init dummy-latency-work
cd dummy-latency-work

ipbb add git https://gitlab.cern.ch/p2-xware/firmware/emp-fwk.git -b v0.6.8
ipbb add git https://gitlab.cern.ch/ttc/legacy_ttc.git -b v2.1
ipbb add git https://gitlab.cern.ch/cms-tcds/cms-tcds2-firmware.git -b v0_1_1
ipbb add git https://gitlab.cern.ch/HPTD/tclink.git -r fda0bcf
ipbb add git https://github.com/ipbus/ipbus-firmware -b v1.9

mkdir -p src/dummy-latency-repo/dummy-latency/
cp -r ./../firmware/ "$_"

cp src/emp-fwk/projects/examples/serenity/dc_ku15p/firmware/hdl/sm1/emp_project_decl.vhd src/dummy-latency-repo/dummy-latency/firmware/hdl/.

ipbb proj create vivado dummy_latency dummy-latency-repo:dummy-latency top.dep
