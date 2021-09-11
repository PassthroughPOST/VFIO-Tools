#! /bin/bash
#
# Author: Stefsinn (https://github.com/Stefsinn)
#
# This hook automatically un-allocates static HugePages when stopping a VM.
# This file depends on the PassthroughPOST hook helper script found here:
# https://github.com/PassthroughPOST/VFIO-Tools/tree/master/libvirt_hooks
# Place this script in BOTH these directories (or symlink it):
# $SYSCONFDIR/libvirt/hooks/qemu.d/your_vm/prepare/begin/
# $SYSCONFDIR/libvirt/hooks/qemu.d/your_vm/release/end/
# $SYSCONFDIR usually is /etc/libvirt.
# 
# ================ 2021-09-11 update by SharkWipf:
# You probably don't need this script. Any QEMU version since like 2012 has
# been using THP (Transparent HugePages) by default on pretty much every
# distro out there. While static hugepages offer some minor benefits over
# dynamic hugepages, "dynamic" hugepages as this script allocates has none
# of those additional benefits. The only thing this script adds is that
# your VM will refuse to start if no hugepages can be allocated, whereas
# THP would simply fall back to regular pages (and take ages to start, you
# would quickly notice this being the case).
# Basically, this script only re-implements something that QEMU already
# does by default in a more complicated manner. It'll cause more issues
# than it fixes and won't give you any additional performance benefits.
# There's pretty much zero reason to use it nowadays.
#
# If you're still not convinced, just `grep /proc/hugepages -e Huge` while
# your VM is running, you'll see how `AnonHugePages` get allocated
# automatically.
# ================
# 
# Get inputs from libvirt
GUEST_NAME="$1"
GUEST_ACTION="$2/$3"
# Get path to guest XML
XML_PATH="/etc/libvirt/qemu/$GUEST_NAME.xml"
# Get guest HugePage size
HPG_SIZE=$(grep '<page size' "$XML_PATH" | grep -ohE '[[:digit:]]+')
# Set path to HugePages
HPG_PATH="/sys/devices/system/node/node0/hugepages/hugepages-${HPG_SIZE}kB/nr_hugepages"
# Get current number of HugePages
HPG_CURRENT=$(cat "${HPG_PATH}")
# Get amount of memory used by the guest
GUEST_MEM=$(grep '<memory unit' "$XML_PATH" | grep -ohE '[[:digit:]]+')

# Define a function used for logging later
function kmessageNotify {
  MESSAGE="$1"
  while read -r line; do
    echo "libvirt_qemu hugepages: ${line}" > /dev/kmsg 2>&1
  done < <(echo "${MESSAGE}")
}

# We define functions here named for each step libvirt calls the hook against
#   respectively. These will be ran after checks pass at the end of the script.
function prepare/begin {
  # Allocate HugePages
  (( HPG_NEW = HPG_CURRENT + GUEST_MEM / HPG_SIZE ))
  echo "$HPG_NEW" > "$HPG_PATH"
  kmessageNotify "Allocating ${GUEST_MEM}kB of HugePages for VM ${GUEST_NAME}"
}

function release/end {
  # Unallocate HugePages
  (( HPG_NEW = HPG_CURRENT - GUEST_MEM / HPG_SIZE ))
  echo "$HPG_NEW" > "$HPG_PATH"
  kmessageNotify "Releasing ${GUEST_MEM}kB of HugePages for VM ${GUEST_NAME}"
}

# Do some checks before continuing
if [[ $HPG_SIZE -eq 0 ]]; then
  # Break if HugePage size is 0
  echo "ERROR: HugePage size cannot be 0." >&2
  exit 1
elif [[ -z $GUEST_MEM ]]; then
  echo "ERROR: Can't determine guest's memory allocation" >&2
  exit 1
elif [[ ! -f "$HPG_PATH"  ]]; then
  # Break if HugePages path doesn't exist
  echo "ERROR: ${HPG_PATH} does not exist. (HugePages disabled in kernel?)" >&2
  exit 1
elif [[ -z $HPG_SIZE ]]; then
  # This exits silently if HugePages appear disabled for a guest
  exit 0
fi

# All checks passed, continue
${GUEST_ACTION}
