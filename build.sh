#!/bin/bash

# Variables
sequence=`seq 1 100`;
this="KaminariKernel";

# Set up the cross-compiler (pt. 1)
export ARCH=arm;
export SUBARCH=arm;
export PATH=$HOME/Toolchains/Linaro-4.9-Generic/bin:$PATH;
export CROSS_COMPILE=arm-linux-gnueabihf-;

# Clear the screen
clear;

# Variables for bold & normal text
bold=`tput bold`;
normal=`tput sgr0`;

# Let's start...
echo -e "Building KaminariKernel...\n";

devicestr="Which device do you want to build for?
1. Moto G (falcon)
2. Moto G 4G (peregrine) 
3. Moto G 2014 (titan)
4. Moto G 2014 LTE (thea) ";

cleanstr="Do you want to remove everything from the last build? (Y/N)

You ${bold}MUST${normal} do this if you have changed toolchains and/or hotplugs. ";

selstr="Do you want to force SELinux to stay in Permissive mode?
Only say Yes if you're aware of the security risks this may introduce! (Y/N) ";

# Select which device the kernel should be built for
while read -p "$devicestr" dev; do
	case $dev in
		"1")
			echo -e "Selected device: Moto G (falcon)\n"
			device="falcon";
			break;;
		"2")
			echo -e "Selected device: Moto G 4G (peregrine)\n"
			device="peregrine";
			break;;
		"3")
			echo -e "Selected device: Moto G 2014 (titan)\n"
			device="titan";
			break;;
		"4")
			echo -e "Selected device: Moto G 2014 LTE (thea)\n"
                        device="thea";
                        break;;	
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;	

# Clean everything via `make clean` or `make mrproper`.
# Recommended if there were extensive changes to the source code.
while read -p "$cleanstr" clean; do
	case $clean in
		"y" | "Y" | "yes" | "Yes")
			echo -e "Cleaning everything...\n";
			make --quiet mrproper && echo -e "Done!\n";
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

# Determine if we should force SELinux permissive mode
while read -p "$selstr" forceperm; do
	case $forceperm in
		"y" | "Y" | "yes" | "Yes")
			echo -e "${bold}WARNING: SELinux will stay in Permissive mode at all times. You won't be able to change it to Enforcing.\nBe careful.\n${normal}";
			forceperm="Y";
			break;;
		"n" | "N" | "no" | "No" | "" | " ")
			echo -e "SELinux will remain configurable (Android will always default it to Enforcing).\n";
			forceperm="N";			
			break;;
		*)
			echo -e "\nInvalid option. Try again.\n";;
	esac;
done;
	
# Tell exactly when the build started
echo -e "Build started on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
starttime=`date +"%s"`;
			
# Build the kernel
if [[ $device != "thea" ]]; then
	make "$device"_defconfig;
else
	make titan_defconfig;
fi;

# Permissive selinux? Edit .config
if [[ $forceperm = "Y" ]]; then
	sed -i s/"# CONFIG_SECURITY_SELINUX_FORCE_PERMISSIVE is not set"/"CONFIG_SECURITY_SELINUX_FORCE_PERMISSIVE=y"/ .config;
fi;

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
maindir=$HOME/Kernel/Zip_AOSP;
outdir=$HOME/Kernel/Out_AOSP/$device;
devicedir=$maindir/$device;

# Make the zip and out dirs if they don't exist
if [ ! -d $maindir ] || [ ! -d $outdir ]; then
	mkdir -p $maindir && mkdir -p $outdir;
fi;

# Use zImage-dtb since AK officially supports it now
echo -e "Copying zImage-dtb...";
cp -f arch/arm/boot/zImage-dtb $devicedir/;

# Set the zip's name
if [[ $forceperm = "Y" ]]; then
	zipname="Kaminari_"$version"_"`echo "${device^}"`"_SELinuxForcePerm";
else
	zipname="Kaminari_"$version"_"`echo "${device^}"`;
fi;

# Zip the stuff we need & finish
echo -e "Creating flashable ZIP...\n";
echo -e $device > $devicedir/device.txt;
echo -e "Version: $version" > $devicedir/version.txt;
cd $maindir/common;
zip -r9 $outdir/$zipname.zip . > /dev/null;
cd $maindir/std;
zip -r9 $outdir/$zipname.zip * > /dev/null;
cd $devicedir;
zip -r9 $outdir/$zipname.zip * > /dev/null;
echo -e "Done!"
# Tell exactly when the build finished
echo -e "Build finished on:\n`date +"%A, %d %B %Y @ %H:%M:%S %Z (GMT %:z)"`\n`date --utc +"%A, %d %B %Y @ %H:%M:%S %Z"`\n";
finishtime=`date +"%s"`;
finishdiff=$(($finishtime - $starttime));
echo -e "This build took: $(($finishdiff / 60)) minute(s) and $(($finishdiff % 60)) second(s).\n";
