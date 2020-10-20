# This package doesn't install CUDA. It instead verifies that CUDA is installed.
# Other packages can depend on this package to declare a dependency on CUDA.
# If this package is installed, we assume that CUDA is properly installed.

#note: this port must be kept in sync with CUDNN port: every time one is upgraded, the other must be too
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(error_code 1)
    execute_process(
        COMMAND dpkg-query --show nvidia-l4t-core
        OUTPUT_VARIABLE NVIDIA_L4T_CORE_OUTPUT
        RESULT_VARIABLE error_code)
    if (error_code)
        message(FATAL_ERROR "Could not execute dpkg-query command to get L4T version")
    endif()

    # SampleOutput: nvidia-l4t-core 32.4.3-20200625213407
    string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" L4T_VERSION ${NVIDIA_L4T_CORE_OUTPUT})
    message(STATUS "NVIDIA L4T Core: ${L4T_VERSION}")

    if (L4T_VERSION VERSION_LESS "32.4.3")
        # for jetpack 4.3
        set(CUDA_REQUIRED_VERSION "10.0.0")
    else()
        # for jetpack 4.4
        set(CUDA_REQUIRED_VERSION "10.2.0")
    endif()
else()
    set(CUDA_REQUIRED_VERSION "11.0.0")
endif()

set(CUDA_PATHS 
        ENV CUDA_PATH
        ENV CUDA_BIN_PATH
        ENV CUDA_PATH_V11_0
        ENV CUDA_PATH_V10_2
        ENV CUDA_PATH_V10_1)

if (VCPKG_TARGET_IS_WINDOWS)
    find_program(NVCC
        NAMES nvcc.exe
        PATHS
        ${CUDA_PATHS}
        PATH_SUFFIXES bin bin64
        DOC "Toolkit location."
        NO_DEFAULT_PATH
    )
else()
    if (VCPKG_TARGET_IS_LINUX)
        set(platform_base "/usr/local/cuda-")
    else()
        set(platform_base "/Developer/NVIDIA/CUDA-")
    endif()
    
    file(GLOB possible_paths "${platform_base}*")
    set(FOUND_PATH )
    foreach (p ${possible_paths})
        # Extract version number from end of string
        string(REGEX MATCH "[0-9][0-9]?\\.[0-9]$" p_version ${p})
        if (IS_DIRECTORY ${p} AND p_version)
            if (p_version VERSION_GREATER_EQUAL CUDA_REQUIRED_VERSION)
                set(FOUND_PATH ${p})
                break()
            endif()
        endif()
    endforeach()
    
    find_program(NVCC
        NAMES nvcc
        PATHS
        ${CUDA_PATHS}
        PATHS ${FOUND_PATH}
        PATH_SUFFIXES bin bin64
        DOC "Toolkit location."
        NO_DEFAULT_PATH
    )
endif()

set(error_code 1)
if (NVCC)
    execute_process(
        COMMAND ${NVCC} --version
        OUTPUT_VARIABLE NVCC_OUTPUT
        RESULT_VARIABLE error_code)
endif()


if (error_code)
    message(STATUS "Executing ${NVCC} --version resulted in error: ${error_code}")
    message(FATAL_ERROR "Could not find CUDA. Before continuing, please download and install CUDA (v${CUDA_REQUIRED_VERSION} or higher) from:"
                        "\n    https://developer.nvidia.com/cuda-downloads\n")
endif()

# Sample output:
# NVIDIA (R) Cuda compiler driver
# Copyright (c) 2005-2016 NVIDIA Corporation
# Built on Sat_Sep__3_19:05:48_CDT_2016
# Cuda compilation tools, release 8.0, V8.0.44
string(REGEX MATCH "V([0-9]+\\.[0-9]+\\.[0-9]+)" CUDA_VERSION ${NVCC_OUTPUT})
set(CUDA_VERSION ${CMAKE_MATCH_1})
message(STATUS "Found CUDA: ${CUDA_VERSION}")

if (CUDA_VERSION VERSION_LESS CUDA_REQUIRED_VERSION)
    message(FATAL_ERROR "CUDA ${CUDA_VERSION} found, but v${CUDA_REQUIRED_VERSION} is required. Please download and install a more recent version of CUDA from:"
                        "\n    https://developer.nvidia.com/cuda-downloads\n")
endif()

SET(VCPKG_POLICY_EMPTY_PACKAGE enabled)
