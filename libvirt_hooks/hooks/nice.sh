#!/usr/bin/env bash

#
# Author: Danny Lin <danny@kdrag0n.dev>
#
# This hook sets the CFS "nice level" of the vCPU threads to the configured
# value. This can be useful as a replacement for using the real-time FIFO
# scheduling policy (SCHED_FIFO) through libvirt since it causes lockups on
# some systems. It can improve VM responsiveness when CPU load on the host is
# high by making the CFS scheduler prioritize runnable vCPU threads over other
# miscellaneous processes which are "nicer".
#
# Note that this is primarily intended for setups where QEMU is not running as
# its own dedicated user as otherwise it is preferred to use udev rules to
# set the user's default nice level instead. Some setups necessitate running
# QEMU as another user for PulseAudio or other reasons, which is where this
# script is useful.
#
# Target file location: $SYSCONFDIR/hooks/qemu.d/vm_name/started/begin/nice.sh
# $SYSCONFDIR is usually /etc/libvirt.
#

# Ranges from 20 (lowest priority) to -20 (highest priority)
TARGET_NICE="-1"

VM_NAME="$1"

# Set the nice of all vCPUs
for grp in /sys/fs/cgroup/cpu/machine.slice/machine-qemu*$VM_NAME.scope/vcpu*
do
    echo "libvirt-qemu nice: Setting $(basename $grp)'s nice level to $TARGET_NICE" > /dev/kmsg
    for pid in $(cat $grp/tasks)
    do
        renice -n "$TARGET_NICE" -p "$pid" 2> /dev/null
    done
done

echo "libvirt-qemu nice: Prioritized vCPU threads of VM '$VM_NAME'" > /dev/kmsg
