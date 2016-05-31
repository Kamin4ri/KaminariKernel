#!/bin/bash

# Variables
sequence=`seq 1 100`;
numjobs=0;
this="KaminariKernel";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/GNU-5.3-CortexA7/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-cortex_a7-linux-gnueabihf-;

# Output some basic info
echo -e "Building KaminariKernel...";

if [ $1 ]; then
	case $1 in
		"clean")
			echo -e "All compiled files from previous builds will be removed.\n";
			make clean;
			if [ $2 ]; then
				for i in $sequence; do
					if [ $2 = $i ]; then
						numjobs=$2;
					fi;
				done;
			fi;				
			;;
		"clean_full" | "cleanfull" | "clean_all" | "cleanall" ) 
			echo -e "The configuration file, dependencies and all compiled files from previous builds will be removed.\n";
			make mrproper;
			if [ $2 ]; then
				for i in $sequence; do
					if [ $2 = $i ]; then
						numjobs=$2;
					fi;
				done;
			fi;
			;;
		*)
			if [[ `echo $1 | gawk --re-interval "/v/"` != "" ]]; then
				version=`echo $1 | cut -d"v" -f2`;
				if [ $2 ]; then
					case $2 in
						"clean")
							echo -e "All compiled files from previous builds will be removed.\n";
							make clean;
							;;
						"clean_full" | "cleanfull" | "clean_all" | "cleanall" ) 
							echo -e "The configuration file, dependencies and all compiled files from previous builds will be removed.\n";
							make mrproper;
							;;
						*)
							for i in $sequence; do
								if [ $2 = $i ]; then
									numjobs=$2;
								fi;
							done;
							;;
					esac;
					if [ $3 ]; then
						for i in $sequence; do
							if [ $3 = $i ]; then
								numjobs=$3;
							fi;
						done;
					fi;
				fi;
			else
				for i in $sequence; do
					if [ $1 = $i ]; then
						numjobs=$1;
					fi;
				done;
			fi;
			;;				
	esac;
fi;

if [ $version ] && [ "$version" != "" ]; then
	echo -e "Version: $version\n";
fi;
	

echo -e "Build started on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`";
[ $numjobs != 0 ] && echo -e "Number of parallel jobs: $numjobs";
			
# Build the kernel
make falcon_defconfig;

if [ $numjobs ] && [ $numjobs != 0 ]; then
	make -j$numjobs;
else
	make -j4;
fi;

# Tell when the build was finished
echo -e "Build finished on: `date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n";
	
# Set the build date & time after it has been completed
builddate=`date +%Y%m%d.%H%M%S`;
builddate_full=`date +"%d %b %Y | %H:%M:%S %Z"`;

# Make the zip dir if it doesn't exist
if [ ! -d ../Zip_CustomMM_Falcon ]; then 
	mkdir ../Zip_CustomMM_Falcon;
	cp -rf ../Custom_AnyKernel/* ../Zip_CustomMM_Falcon;
fi;

# Make the modules dir if it doesn't exist
if [ ! -d ../Zip_CustomMM_Falcon/modules ]; then mkdir ../Zip_CustomMM_Falcon/modules; fi;

# Make the release dir if it doesn't exist
if [ ! -d ../Out_CustomMM_Falcon ]; then mkdir ../Out_CustomMM_Falcon; fi;

# Remove previous modules
if [ -d ../Zip_CustomMM_Falcon/modules ]; then rm -rf ../Zip_CustomMM_Falcon/modules/*; fi;

# Make wi-fi module dir
if [ ! -d ../Zip_CustomMM_Falcon/modules/pronto ]; then mkdir ../Zip_CustomMM_Falcon/modules/pronto; fi;

# Modules
find ./ -type f -name '*.ko' -exec cp -f {} ../Zip_CustomMM_Falcon/modules/ \;
mv ../Zip_CustomMM_Falcon/modules/wlan.ko ../Zip_CustomMM_Falcon/modules/pronto/pronto_wlan.ko;

# Copy zImage-dtb
cp -f arch/arm/boot/zImage-dtb ../Zip_CustomMM_Falcon/;
ls -l ../Zip_CustomMM_Falcon/zImage-dtb;
cd ../Zip_CustomMM_Falcon;

# Set zip name
if [ $version ] && [ "$version" != "" ]; then
	zipname="KaminariMM_v"$version"_Falcon";
else
	zipname="KaminariMM_"$builddate"_Falcon";
fi;

# Make the zip
if [ $version ] && [ "$version" != "" ]; then
	echo -e "Version: $version" > version.txt && echo -e "Build date and time: $builddate_full" > builddate.txt;
else
	[ -e version.txt ] && rm version.txt;	
	echo -e "Build date and time: $builddate_full" > builddate.txt;
fi;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../Out_CustomMM_Falcon;