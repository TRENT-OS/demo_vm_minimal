#
# Demo VM minimal
#
# Copyright (C) 2022, HENSOLDT Cyber GmbH
#

cmake_minimum_required(VERSION 3.8.2)

project(demo_vm_minimal C)

#-------------------------------------------------------------------------------
# use the SDK
find_package(os-sdk REQUIRED)
os_sdk_set_defaults()

# Kernel settings
set(KernelArmHypervisorSupport ON CACHE BOOL "" FORCE)
set(KernelArmVtimerUpdateVOffset OFF CACHE BOOL "" FORCE)
set(KernelArmDisableWFIWFETraps ON CACHE BOOL "" FORCE)

# VMM Feature Settings Kernel settings
set(LibUSB OFF CACHE BOOL "" FORCE)
set(VmPCISupport OFF CACHE BOOL "" FORCE)
set(VmVirtioConsole OFF CACHE BOOL "" FORCE)
set(VmVirtUart OFF CACHE BOOL "" FORCE)
set(VmVirtUartPL011 ON CACHE BOOL "" FORCE)

# if("${PLATFORM}" STREQUAL "qemu-arm-virt")
#     set(KernelArmExportPCNTUser ON CACHE BOOL "" FORCE)
#     set(KernelArmExportPTMRUser ON CACHE BOOL "" FORCE)
# endif()

# Allow platform to overwrite settings
include("plat/${PLATFORM}/plat.cmake")
os_sdk_setup()
CAmkESAddCPPInclude("plat/${PLATFORM}")
os_sdk_import_camkes_vm()
os_sdk_import_from_global_components("components/FileServer")


#-------------------------------------------------------------------------------
# config
AddCamkesCPPFlag(cpp_flags CONFIG_VARS VmEmmc2NoDMA)

if(NOT KernelPlatformQEMUArmVirt)
    AddCamkesCPPFlag(cpp_flags CONFIG_VARS VmVUSB)
endif()

if(KernelPlatformTK1)
    AddCamkesCPPFlag(cpp_flags CONFIG_VARS Tk1DeviceFwd Tk1Insecure)
endif()


#-------------------------------------------------------------------------------
# VM Images

list(
    APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_LIST_DIR}/camkes-vm-images"
    "${CMAKE_CURRENT_LIST_DIR}/camkes-vm-linux"
)
find_package(camkes-vm-images REQUIRED)
find_package(camkes-vm-linux REQUIRED)
include("${CAMKES_VM_LINUX_HELPERS_PATH}")

# images for the selected platform
set(VM_IMG_LINUX "${CAMKES_VM_IMAGES_DIR}/${PLATFORM}/linux")
set(VM_IMG_ROOTFS "${CAMKES_VM_IMAGES_DIR}/${PLATFORM}/rootfs.cpio.gz")
set(VM_IMG_DTB "${CAMKES_VM_IMAGES_DIR}/${PLATFORM}/linux-dtb")

# patch DTB to use proper 'initrd-start' and 'initrd-end'
UpdateDtbFromInitrd(
    "${VM_IMG_DTB}"
    "${VM_IMG_ROOTFS}"
    "0x4d700000" # initrd start
    target_dtb_gen
    VM_IMG_DTB_PATCHED
)

DefineCAmkESVMFileServer(
    INSTANCE "fileServer"
    FILES
        "linux:${VM_IMG_LINUX}"
        "linux-initrd:${VM_IMG_ROOTFS}"
        "linux-dtb:${VM_IMG_DTB_PATCHED}"
    DEPENDS
        target_dtb_gen
)


#-------------------------------------------------------------------------------
os_sdk_create_CAmkES_system("vm_minimal.camkes")
