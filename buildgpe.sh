#!/bin/bash

# Variables
sequence=`seq 1 100`;
numjobs=0;
this="KaminariKernel";

# Set up the cross-compiler
export PATH=$HOME/Toolchains/Linaro-4.9-A7/bin:$PATH;
export ARCH=arm;
export SUBARCH=arm;
export CROSS_COMPILE=arm-cortex_a7-linux-gnueabihf-;

# Clone the custom anykernel repo
if [ ! -d ../Custom_AnyKernel ]; then
	echo -e "Custom AnyKernel not detected. Cloning git repository...\n";	
	git clone -q -b $device https://github.com/Kamin4ri/Custom_AnyKernel ../Custom_AnyKernel;
else
	cd ../Custom_AnyKernel;
	git checkout -q falcon_gpe;
	cd ../$this;
fi;

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
			if [ `echo $1 | gawk --re-interval "/v/"` != "" ]; then
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
if [ ! -d ../zip_falcon_gpe ]; then 
	mkdir ../zip_falcon_gpe;
	cp -rf ../Custom_AnyKernel/* ../zip_falcon_gpe;
fi;

# Make the modules dir if it doesn't exist
if [ ! -d ../zip_falcon_gpe/modules ]; then mkdir ../zip_falcon_gpe/modules; fi;

# Make the release dir if it doesn't exist
if [ ! -d ../release_falcon_gpe ]; then mkdir ../release_falcon_gpe; fi;

# Remove previous modules
if [ -d ../zip_falcon_gpe/modules ]; then rm -rf ../zip_falcon_gpe/modules/*; fi;

# Make wi-fi module dir
if [ ! -d ../zip_falcon_gpe/modules/pronto ]; then mkdir ../zip_falcon_gpe/modules/pronto; fi;

# Modules
find ./ -type f -name '*.ko' -exec cp -f {} ../zip_falcon_gpe/modules/ \;
mv ../zip_falcon_gpe/modules/wlan.ko ../zip_falcon_gpe/modules/pronto/pronto_wlan.ko;

# Copy zImage-dtb
cp -f arch/arm/boot/zImage-dtb ../zip_falcon_gpe/;
ls -l ../zip_falcon_gpe/zImage-dtb;
cd ../zip_falcon_gpe;

# Set zip name
if [ $version ] && [ "$version" != "" ]; then
	zipname="Kaminari_v"$version"_FalconGPE";
else
	zipname="Kaminari_"$builddate"_FalconGPE";
fi;

# Make the zip
if [ $version ] && [ "$version" != "" ]; then
	echo -e "Version: $version" > version.txt && echo -e "Build date and time: $builddate_full" > builddate.txt;
else
	echo -e "* Build date and time: $builddate_full" > builddate.txt;
fi;
zip -r9 $zipname.zip * > /dev/null;
mv $zipname.zip ../release_falcon_gpe;
