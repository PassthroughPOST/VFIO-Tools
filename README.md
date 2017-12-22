# VFIO-Tools
A collection of tools and scripts that aim to make PCI passthrough a little easier.

## libvirt_hooks

### QEMU hook helper
This contains a hook-helper for libvirt which allows easier per-VM hooks.  
Simply drop the `qemu` file in `$SYSCONFDIR/libvirt/hooks/` (usually `/etc/libvirt/hooks`) and you're ready to add hooks.  
You can have a virtually limitless number of hook scripts per VM and per hook call, just keep in mind that a failed hook will prevent a VM from starting.  
The way to add hooks is as follows:  
- Create a file in a path matching this structure:
```
$SYSCONFDIR/libvirt/hooks/qemu.d/vm_name/hook_name/state_name/yourhook.conf
```
- You can put anything you like in the hook, as long as you make sure you start your hook with a hashbang (i.e. `#!/bin/bash`).
- When you're done setting up your hook, run `chmod +x` on your hook file to make it executable.
- If you've added the `qemu` hook helper file for the first time, you need to restart libvirt in order for it to be detected.

### switch_displays.sh
This hook allows you to automatically switch your monitor input to your VM's display.  
To achieve this you need to have `ddcutil` installed and working and you need a DDC/CI capable monitor.  
For a more detailed explanation and write-up, check out https://passthroughpo.st

