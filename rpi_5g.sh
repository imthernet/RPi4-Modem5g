#!/bin/bash


#Requirements
## wget https://raw.githubusercontent.com/raspberrypi/linux/rpi-5.10.y/drivers/net/usb/qmi_wwan.c
## wget https://raw.githubusercontent.com/raspberrypi/linux/rpi-5.10.y/drivers/usb/serial/option.c
## wget https://raw.githubusercontent.com/raspberrypi/linux/rpi-5.10.y/drivers/usb/serial/usb-wwan.h

source /ramdisk/environment
DIR=$(pwd)
mod_src=$DIR/src/
qmi_path=/lib/modules/$(uname -r)/kernel/drivers/net/usb/
option_path=/lib/modules/$(uname -r)/kernel/drivers/usb/serial/

[[ -z $(modinfo option | grep 0801) || -z $(modinfo qmi_wwan | grep 0801) ]] || { echo "** Modules for supported 5g modems are ok **"; exit 1; }

if [[ -f "$mod_src/option.c" && -f "$mod_src/qmi_wwan.c" && -f "$mod_src/usb-wwan.h" ]]; then
	
	mkdir $RAMDISK/5gmod && cd "$_"; cp $mod_src/{qmi_wwan.c,option.c,usb-wwan.h} .
	echo "** Applying new patches for qmi_wwan/option **"; patch < $mod_src/../qmi.patch; patch < $mod_src/../option.patch
        echo "** Creating Makefile for option and qmi_wwan **"
        echo "obj-m += option.o qmi_wwan.o" > Makefile
        echo "** Making new modules **"
        make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
        [[ $? != 0 ]] && exit 1 || { echo "** Moving modules to kernel modules **"; mv qmi_wwan.ko $qmi_path; mv option.ko $option_path; }
        echo "** Updating file to load modules at boot time **"
        grep -q '^qmi_wwan' /etc/modules && sed -i 's/^qmi_wwan.*/qmi_wwan/' /etc/modules || echo 'qmi_wwan' >> /etc/modules
	grep -q '^option' /etc/modules && sed -i 's/^option.*/option/' /etc/modules || echo 'option' >> /etc/modules
	(rm *.mod*; rm .*; rm *.o) 2>/dev/null
	echo "** Reboot machine **"
else

        echo "Missing files. Check if option,qmi_wwan or usb-wwan exist in directory"
fi

