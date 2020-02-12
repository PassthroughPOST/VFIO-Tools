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
# Get path to guest XML
XML_PATH="/etc/libvirt/qemu/${1}.xml"
# Get guest HugePage size
HPG_SIZE=$(grep '<page size' "$XML_PATH" | grep -ohE '[[:digit:]]+')
# Set path to HugePages
HPG_PATH="/sys/devices/system/node/node0/hugepages"

function unallocPages {
	# VM memory to be allocated
	MEM_GUEST=$(grep '<memory unit' "$XML_PATH" | grep -ohE '[[:digit:]]+')
	# Current number of HugePages
	HPG_CURRENT=$(cat "${HPG_PATH}/hugepages-${HPG_SIZE}kB/nr_hugepages")

	# Unallocate HugePages
	((HPG_NEW = HPG_CURRENT - MEM_GUEST / HPG_SIZE ))
	echo "$HPG_NEW" > "$HPG_PATH"
}

# Call function to unallocate HugePages if HugePage count is greater than 0
if [[ HPG_SIZE -gt 0 ]]; then
	unallocPages
fi
