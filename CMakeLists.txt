#
# Demo VM minimal
#
# Copyright (C) 2022-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: BSD-2-Clause
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

set(CapDLLoaderMaxObjects 8192 CACHE STRING "" FORCE)

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
set(VM_IMG_DTB "${CAMKES_VM_IMAGES_DIR}/${PLATFORM}/linux-dtb")

DefineCAmkESVMFileServer(
    INSTANCE "fileServer"
    FILES
        "linux:${VM_IMG_LINUX}"
        "linux-dtb:${VM_IMG_DTB}"
)


#-------------------------------------------------------------------------------
os_sdk_create_CAmkES_system("vm_minimal.camkes")
