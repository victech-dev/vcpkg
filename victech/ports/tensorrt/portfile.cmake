# This package doesn't install TensorRT. It instead verifies that TensorRT is installed.
# Other packages can depend on this package to declare a dependency on TensorRT.
# If this package is installed, we assume that TensorRT is properly installed.

#note: this port must be kept in sync with CUDA/CUDNN port: every time one is upgraded, the other must be too
set(TensorRT_REQUIRED_VERSION "7.1.3")

if (VCPKG_TARGET_IS_WINDOWS)
  find_path(TensorRT_INCLUDE_DIR NvInfer.h
    HINTS ENV CUDA_PATH ENV CUDA_PATH_V11_1 ENV CUDA_PATH_V11_0 ENV CUDA_PATH_V10_2 ENV CUDA_PATH_V10_1
    PATH_SUFFIXES cuda/include include)
elseif (VCPKG_TARGET_IS_LINUX)
  find_path(TensorRT_INCLUDE_DIR NvInfer.h
    HINTS /usr/local/include /usr/include 
    PATH_SUFFIXES cuda/include include)
endif()

if(EXISTS "${TensorRT_INCLUDE_DIR}/NvInferVersion.h")
  file(READ ${TensorRT_INCLUDE_DIR}/NvInferVersion.h TensorRT_VERSION_HEADER_CONTENTS)

# Sample 
# #define NV_TENSORRT_MAJOR 7 //!< TensorRT major version.
# #define NV_TENSORRT_MINOR 1 //!< TensorRT minor version.
# #define NV_TENSORRT_PATCH 3 //!< TensorRT patch version.
# #define NV_TENSORRT_BUILD 0 //!< TensorRT build number.

  string(REGEX MATCH "define NV_TENSORRT_MAJOR * +([0-9]+)"
               TensorRT_VERSION_MAJOR "${TensorRT_VERSION_HEADER_CONTENTS}")
  string(REGEX REPLACE "define NV_TENSORRT_MAJOR * +([0-9]+)" "\\1"
               TensorRT_VERSION_MAJOR "${TensorRT_VERSION_MAJOR}")
  string(REGEX MATCH "define NV_TENSORRT_MINOR * +([0-9]+)"
               TensorRT_VERSION_MINOR "${TensorRT_VERSION_HEADER_CONTENTS}")
  string(REGEX REPLACE "define NV_TENSORRT_MINOR * +([0-9]+)" "\\1"
               TensorRT_VERSION_MINOR "${TensorRT_VERSION_MINOR}")
  string(REGEX MATCH "define NV_TENSORRT_PATCH * +([0-9]+)"
               TensorRT_VERSION_PATCH "${TensorRT_VERSION_HEADER_CONTENTS}")
  string(REGEX REPLACE "define NV_TENSORRT_PATCH * +([0-9]+)" "\\1"
                 TensorRT_VERSION_PATCH "${TensorRT_VERSION_PATCH}")
  if(NOT TensorRT_VERSION_MAJOR)
    set(TensorRT_VERSION "?")
  else()
    set(TensorRT_VERSION "${TensorRT_VERSION_MAJOR}.${TensorRT_VERSION_MINOR}.${TensorRT_VERSION_PATCH}")
  endif()
else()
  message(FATAL_ERROR "Required TensorRT version ${TensorRT_REQUIRED_VERSION} not found")
endif()


message(STATUS "Found TensorRT: ${TensorRT_VERSION}")
if (TensorRT_VERSION VERSION_LESS TensorRT_REQUIRED_VERSION)
  message(FATAL_ERROR "Required TensorRT version ${TensorRT_REQUIRED_VERSION} not found")
endif()

SET(VCPKG_POLICY_EMPTY_PACKAGE enabled)