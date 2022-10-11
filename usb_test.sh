#!/usr/bin/env bash

usb_3_hub_vendor="0424"
usb_3_hub_product="5534"

usb_3_drive_vendor="0781"
usb_3_drive_product="5591"

usb_2_hub_vendor="0424"
usb_2_hub_product="2134"

usb_2_drive_vendor="048d"
usb_2_drive_product="1234"


# USB 3.0 hub
if lsusb -d $usb_3_hub_vendor:$usb_3_hub_product | grep -q Bus
then
    usb_3_drives=$(lsusb -d $usb_3_drive_vendor:$usb_3_drive_product | grep -c Bus);
    echo "USB 3.0 Hub detected with $usb_3_drives drive(s)"
else
    echo "USB 3.0 Hub not found. Exiting."
    exit
fi

# USB 2.0 hub
if lsusb -d $usb_2_hub_vendor:$usb_2_hub_product | grep -q Bus
then
    usb_2_drives=$(lsusb -d $usb_2_drive_vendor:$usb_2_drive_product | grep -c Bus);
    echo "USB 2.0 Hub detected with $usb_2_drives drive(s)"
else
    echo "USB 2.0 Hub not found. Exiting."
    exit
fi

for BLOCK in $(ls /dev | grep "^sd[a-z]$")
do
    echo "------------------------------------";
    # Check vendor and product ID of each /dev/sd* device to determine
    # if it is the drives we are looking for
    vendor=$(udevadm info --query=all /dev/$BLOCK | grep -oP 'ID_VENDOR_ID=\K\w+')
    product=$(udevadm info --query=all /dev/$BLOCK | grep -oP 'ID_MODEL_ID=\K\w+')

    # Test USB 3.0 drives
    if [ $vendor = $usb_3_drive_vendor ]
    then
        if [ $product = $usb_3_drive_product ]
        then
            echo "USB 3.0 drive /dev/$BLOCK:";

            write=$(sudo dd if=/dev/zero of=/dev/$BLOCK bs=32M count=5 2>&1)          
            write=$(echo ${write##*s,})

            sudo /sbin/sysctl -w vm.drop_caches=3 > /dev/null

            read=$(sudo dd if=/dev/$BLOCK of=/dev/zero bs=32M count=5 2>&1)
            read=$(echo ${read##*s,})

            sudo /sbin/sysctl -w vm.drop_caches=3 > /dev/null

            echo "    Read: $read, Write: $write";
        fi
    fi

    # Test USB 2.0 drives
    if [ $vendor = $usb_2_drive_vendor ]
    then
        if [ $product = $usb_2_drive_product ]
        then
            echo "USB 2.0 drive /dev/$BLOCK:";

            read=$(sudo dd if=/dev/$BLOCK of=/dev/null bs=32M count=5 conv=fdatasync 2>&1)
            read=$(echo ${read##*s,})

            sudo /sbin/sysctl -w vm.drop_caches=3 > /dev/null

            write=$(sudo dd if=/dev/zero of=/dev/$BLOCK bs=32M count=5 conv=fdatasync 2>&1)          
            write=$(echo ${write##*s,})

            sudo /sbin/sysctl -w vm.drop_caches=3 > /dev/null
            echo "    Read: $read, Write: $write";
        fi
    fi

done

exit;
