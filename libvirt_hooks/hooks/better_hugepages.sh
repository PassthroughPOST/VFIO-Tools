#!/usr/bin/env bash
#
# Author: SharkWipf (https://github.com/SharkWipf)
#
# This file depends on the PassthroughPOST hook helper script found here:
# https://github.com/PassthroughPOST/VFIO-Tools/tree/master/libvirt_hooks
# This hook only needs to run on `prepare/begin`, not on stop.
# Place this script in this directory:
# $SYSCONFDIR/libvirt/hooks/qemu.d/your_vm/prepare/begin/
# $SYSCONFDIR usually is /etc/libvirt.
#
# This hook will help free and compact memory to ease THP allocation.
# QEMU VMs will use THP (Transparent HugePages) by default if enough
# unfragmented memory can be found on startup. If your memory is very
# fragmented, this may cause a slow VM startup (like a slowly responding 
# VM start button/command), and may cause QEMU to fall back to regular
# memory pages, slowing down VM performance.
# If you (suspect you) suffer from this, this hook will help ease THP
# allocation so you don't need to resort to misexplained placebo scripts.
#
# Don't use the old hugepages.sh script in this repo. It's useless.
# It's only kept in for archival reasons and offers no benefits.
#


# Finish writing any outstanding writes to disk.
sync
# Drop all filesystem caches to free up more memory.
echo 3 > /proc/sys/vm/drop_caches
# Do another run of writing any possible new outstanding writes.
sync
# Tell the kernel to "defragment" memory where possible.
echo 1 > /proc/sys/vm/compact_memory
