# This package doesn't install CUDNN. It instead verifies that CUDNN is installed.
# Other packages can depend on this package to declare a dependency on CUDNN.
# If this package is installed, we assume that CUDNN is properly installed.

#note: this port must be kept in sync with CUDA port: every time one is upgraded, the other must be too
set(CUDNN_REQUIRED_VERSION "8.0.0")

if (VCPKG_TARGET_IS_WINDOWS)
  find_path(CUDNN_INCLUDE_DIR cudnn.h
    HINTS ENV CUDA_PATH ENV CUDA_PATH_V11_1 ENV CUDA_PATH_V11_0 ENV CUDA_PATH_V10_2 ENV CUDA_PATH_V10_1
    PATH_SUFFIXES cuda/include include)
elseif (VCPKG_TARGET_IS_LINUX)
  find_path(CUDNN_INCLUDE_DIR cudnn.h
    HINTS "/usr/local/cuda-11.1" "/usr/local/cuda-11.0" "/usr/local/cuda-10.2" "/usr/local/cuda-10.1" "/usr/local/cuda"
    PATH_SUFFIXES cuda/include include)
endif()

if(EXISTS "${CUDNN_INCLUDE_DIR}/cudnn.h")
  file(READ ${CUDNN_INCLUDE_DIR}/cudnn.h CUDNN_HEADER_CONTENTS)
  if(EXISTS "${CUDNN_INCLUDE_DIR}/cudnn_version.h")
    file(READ "${CUDNN_INCLUDE_DIR}/cudnn_version.h" CUDNN_VERSION_H_CONTENTS)
    string(APPEND CUDNN_HEADER_CONTENTS "${CUDNN_VERSION_H_CONTENTS}")
    unset(CUDNN_VERSION_H_CONTENTS)
  endif()
    string(REGEX MATCH "define CUDNN_MAJOR * +([0-9]+)"
                 CUDNN_VERSION_MAJOR "${CUDNN_HEADER_CONTENTS}")
    string(REGEX REPLACE "define CUDNN_MAJOR * +([0-9]+)" "\\1"
                 CUDNN_VERSION_MAJOR "${CUDNN_VERSION_MAJOR}")
    string(REGEX MATCH "define CUDNN_MINOR * +([0-9]+)"
                 CUDNN_VERSION_MINOR "${CUDNN_HEADER_CONTENTS}")
    string(REGEX REPLACE "define CUDNN_MINOR * +([0-9]+)" "\\1"
                 CUDNN_VERSION_MINOR "${CUDNN_VERSION_MINOR}")
    string(REGEX MATCH "define CUDNN_PATCHLEVEL * +([0-9]+)"
                 CUDNN_VERSION_PATCH "${CUDNN_HEADER_CONTENTS}")
    string(REGEX REPLACE "define CUDNN_PATCHLEVEL * +([0-9]+)" "\\1"
                 CUDNN_VERSION_PATCH "${CUDNN_VERSION_PATCH}")
  if(NOT CUDNN_VERSION_MAJOR)
    set(CUDNN_VERSION "?")
  else()
    set(CUDNN_VERSION "${CUDNN_VERSION_MAJOR}.${CUDNN_VERSION_MINOR}.${CUDNN_VERSION_PATCH}")
  endif()
else()
  message(FATAL_ERROR "Required CUDNN version ${CUDNN_REQUIRED_VERSION} not found")
endif()

message(STATUS "Found CUDNN: ${CUDNN_VERSION}")
if (CUDNN_VERSION VERSION_LESS CUDNN_REQUIRED_VERSION)
  message(FATAL_ERROR "Required CUDNN version ${CUDNN_REQUIRED_VERSION} not found")
endif()

SET(VCPKG_POLICY_EMPTY_PACKAGE enabled)
