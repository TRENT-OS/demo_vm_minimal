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
set(LibUtilsDefaultZfLogLevel 2 CACHE STRING "")

# Kernel settings
set(KernelArmHypervisorSupport ON CACHE BOOL "" FORCE)
set(KernelArmVtimerUpdateVOffset OFF CACHE BOOL "" FORCE)
set(KernelArmDisableWFIWFETraps ON CACHE BOOL "" FORCE)
set(LibUSB OFF CACHE BOOL "" FORCE)
set(VmInitRdFile ON CACHE BOOL "" FORCE)
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

AddToFileServer("linux" "${VM_IMG_LINUX}")
AddToFileServer("linux-initrd" "${VM_IMG_ROOTFS}")
AddToFileServer("linux-dtb" "${VM_IMG_DTB_PATCHED}" DEPENDS target_dtb_gen)
get_target_property(FS_FILES vm_fserver_config FILES)
get_target_property(FS_DEPS vm_fserver_config DEPS)
include(cpio)
MakeCPIO("file_server_archive.o" "${FS_FILES}" DEPENDS "${FS_DEPS}")
add_library(fileserver_cpio STATIC EXCLUDE_FROM_ALL "file_server_archive.o")
set_property(TARGET fileserver_cpio PROPERTY LINKER_LANGUAGE C)
ExtendCAmkESComponentInstance(FileServer fileServer LIBS fileserver_cpio)


#-------------------------------------------------------------------------------
os_sdk_create_CAmkES_system("vm_minimal.camkes")
