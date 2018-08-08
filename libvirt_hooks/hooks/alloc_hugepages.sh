#! /bin/bash
#
# Author: 
#
# This hook automatically (un-)allocates static HugePages when starting/stopping a VM.
# This file depends on the Passthrough POST hook helper script found in this repo.
# Place this script in BOTH these directories (or symlink it): 
# $SYSCONFDIR/libvirt/hooks/qemu.d/your_vm/prepare/begin/
# $SYSCONFDIR/libvirt/hooks/qemu.d/your_vm/release/end/
# $SYSCONFDIR usually is /etc/libvirt.
# Set the files as executable through `chmod +x`.
#
# Also make sure to configure your VM's XML file and /etc/fstab or this script won't work.

# Get size of VM-Memory and HugePages
XML_PATH=/etc/libvirt/qemu/$1.xml
MEM_HOST=$(grep 'MemAvailable' /proc/meminfo | grep -ohE '[[:digit:]]+')    # Available host memory
MEM_GUEST=$(grep '<memory unit' $XML_PATH    | grep -ohE '[[:digit:]]+')    # VM memory to be allocated
HPG_SIZE=$(grep '<page size' $XML_PATH       | grep -ohE '[[:digit:]]+')    # HugePage size

function allocPages {
    # Define path and current amount of HugePages
    HPG_PATH=/sys/devices/system/node/node0/hugepages/hugepages-"$HPG_SIZE"kB/nr_hugepages
    HPG_CURRENT=$(cat $HPG_PATH)

    # Allocate HugePages
    ((HPG_NEW = HPG_CURRENT + MEM_GUEST / HPG_SIZE ))
    echo $HPG_NEW > $HPG_PATH
}

function prepMemory {
    # Prepare memory for allocation
    echo 1 > /proc/sys/vm/compact_memory
}

# If VM fits into memory, then allocate HugePages
if (($MEM_GUEST < $MEM_HOST)); then
    allocPages
fi
