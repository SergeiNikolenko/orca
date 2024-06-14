#!/bin/bash

mkdir -p orca
cd orca

gdown 1zaxVrtc6rcZi_qSprxwZuwayuW_oZ3vA
gdown 1jnE6rkfWVLsL-UpEDrzzbcisUd3-XD5F
gdown 1ZU-OXuC8Hr89eXNlgATIqcL85jSmiwdG

xz -d -k -T 0 orca_5_0_4_linux_x86-64_openmpi411_part1.tar.xz
tar -xf orca_5_0_4_linux_x86-64_openmpi411_part1.tar

xz -d -k -T 0 orca_5_0_4_linux_x86-64_openmpi411_part2.tar.xz
tar -xf orca_5_0_4_linux_x86-64_openmpi411_part2.tar

xz -d -k -T 0 orca_5_0_4_linux_x86-64_openmpi411_part3.tar.xz
tar -xf orca_5_0_4_linux_x86-64_openmpi411_part3.tar


mv orca_5_0_4_linux_x86-64_openmpi411_part1/* ./
mv orca_5_0_4_linux_x86-64_openmpi411_part2/* ./
mv orca_5_0_4_linux_x86-64_openmpi411_part3/* ./

rm -r orca_5_0_4_linux_x86-64_openmpi411_part*