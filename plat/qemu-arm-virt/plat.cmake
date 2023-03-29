#
# Copyright (C) 2022, HENSOLDT Cyber GmbH
#

# The seL4 default for QEMU is 1 GiB of RAM, which is usually enough for native
# systems. However, for running VMs with a generous memory layout even 2 GiB
# might not be enough. The catch is, that seL4 is built with a configurable
# QEMU memory size, but when running the test on a QEMU, it must provide at
# least the same amount of memory. Test are currently hard-coded to use 2 GiB,
# there is a patch that makes them provide 3 GiB. There is still some automation
# missing, which adjusts the memory automatically.
set(QEMU_MEMORY "3048M")


# Allow access to timers
set(KernelArmExportPCNTUser ON CACHE BOOL "" FORCE)
set(KernelArmExportPTMRUser ON CACHE BOOL "" FORCE)
