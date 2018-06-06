#!/bin/bash

# Variables
sequence=`seq 1 100`;
this="KaminariKernel";

# Set up the cross-compiler (pt. 1)
export ARCH=arm;
export SUBARCH=arm;
export PATH=$HOME/Toolchains/Linaro-5.5-Generic/bin:$PATH;
export CROSS_COMPILE=arm-linux-gnueabihf-;

# Clear the screen
clear;

# Variables for bold & normal text
bold=`tput bold`;
normal=`tput sgr0`;

# Let's start...
echo -e "Building KaminariKernel (Stock)...\n";

devicestr="Which device do you want to build for?
1. Moto G5 (cedric)
2. Moto G5 Plus (potter) 
3. Moto G5S (montana)
4. Moto G5S Plus (sanders) ";

cleanstr="Do you want to remove everything from the last build? (Y/N)

You ${bold}MUST${normal} do this if you have changed toolchains and/or hotplugs. ";

selstr="Do you want to force SELinux to stay in Permissive mode?
Only say Yes if you're aware of the security risks this may introduce! (Y/N) ";

# Select which device the kernel should be built for
while read -p "$devicestr" dev; do
	case $dev in
		"1")
			echo -e "Selected device: Moto G5 (cedric)\n"
			device="cedric";
			break;;
		"2")
			echo -e "Selected device: Moto G5 Plus (potter)\n"
			device="potter";
			break;;
		"3")
			echo -e "Selected device: Moto G5S (montana)\n"
			device="montana";
			break;;
		"4")
			echo -e "Selected device: Moto G5S Plus (sanders)\n"
                        device="sanders";
                        break;;	
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;	

# Clean everything via `make mrproper`.
# Recommended if there were extensive changes to the source code or if building for a different device.
while read -p "$cleanstr" clean; do
	case $clean in
		"y" | "Y" | "yes" | "Yes")
			echo -e "Cleaning everything...\n";
			make --quiet mrproper && \ 
			find . -iname "*.dtb" -exec rm -f {} \; && \ 
				echo -e "Done!\n";
			break;;
		"n" | "N" | "no" | "No" | "" | " ")
			echo -e "Not cleaning anything.\n";
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;

# (Optional) Specify a release number.
# A "Testing" label will be used if this is left blank.
while read -p "Do you want to specify a release/version number? (Just press enter if you don't.) " rel; do
	if [[ `echo $rel | gawk --re-interval "/^R/"` != "" ]]; then
		for i in $sequence; do
			if [ `echo $rel | gawk --re-interval "/^R$i/"` ]; then
				echo -e "Release number: $rel\n";
				export LOCALVERSION="-Kaminari-$rel";
				version=$rel;
			fi;
		done;
	elif [[ `echo $rel | gawk --re-interval "/^v/"` ]]; then
		echo -e "Version number: $rel\n";
		export LOCALVERSION="-Kaminari-$rel";
		version=$rel;
	else
		case $rel in
			"" | " " )
				echo -e "No release number was specified. Labelling this build as testing/nightly.\n";
				export LOCALVERSION="-Kaminari-Testing";
				version=`date --utc "+%Y%m%d.%H%M%S"`;
				break;;
			*)
				echo -e "Localversion set as: $rel\n";
				export LOCALVERSION="-Kaminari-$rel";
				version=$rel;
				break;;
		esac;
	fi;
	break;
done;
	
# Tell exactly when the build started
echo -e "Build started on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
starttime=`date +"%s"`;
			
# Build the kernel
make "$device"_defconfig;

# 2x no. of CPU cores
make -j$((`nproc --all` * 2));

if [[ -f arch/arm/boot/zImage-dtb ]]; then
	echo -e "Code compilation finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
	maketime=`date +"%s"`;
	makediff=$(($maketime - $starttime));
	echo -e "Code compilation took: $(($makediff / 60)) minute(s) and $(($makediff % 60)) second(s).\n";
else
	echo -e "zImage not found. Kernel build failed. Aborting.\n";
	exit 1;
fi;

# Define directories (zip, out)
maindir=$HOME/Kernel/zip/stock;
outdir=$HOME/Kernel/out/stock/$device;
devicedir=$maindir/$device;

# Make the zip and out dirs if they don't exist
if [ ! -d $maindir ] || [ ! -d $outdir ]; then
	mkdir -p $maindir && mkdir -p $outdir;
fi;

# Copy zImage & generate dt.img
echo -e "Copying zImage...\n";
cp -rf arch/arm/boot/zImage $devicedir/;
echo -e "Compiling device tree...\n";
./dtbTool -o $devicedir/dt.img arch/arm/boot/dts/qcom/ -s 2048 -p scripts/dtc/;

# Copy modules
mkdir -p $devicedir/modules/system/lib/modules/pronto;
find . -type f -name "*.ko" -exec cp {} $devicedir/modules/system/lib/modules/ \;
mv $devicedir/modules/system/lib/modules/wlan.ko $devicedir/modules/system/lib/modules/pronto/pronto_wlan.ko;

# Set the zip's name
zipname="kaminari_"$version"_"`echo "${device}"`;

# Zip the stuff we need & finish
echo -e "Creating flashable ZIP...\n";
echo -e $device > $devicedir/device.txt;
echo -e "Version: $version" > $devicedir/version.txt;
cd $maindir/common;
zip -r9 $outdir/$zipname.zip . > /dev/null;
cd $devicedir;
zip -r9 $outdir/$zipname.zip * > /dev/null;
echo -e "Done!"
# Tell exactly when the build finished
echo -e "Build finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
finishtime=`date +"%s"`;
finishdiff=$(($finishtime - $starttime));
echo -e "This build took: $(($finishdiff / 60)) minute(s) and $(($finishdiff % 60)) second(s).\n";
