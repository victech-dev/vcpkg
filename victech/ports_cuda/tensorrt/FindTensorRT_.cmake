# Distributed under the OSI-approved BSD 3-Clause License.

#.rst:
# FindTensorRT
# --------
#
# Result Variables
# ^^^^^^^^^^^^^^^^
#
# This module will set the following variables in your project::
#
#  ``TensorRT_FOUND``
#    True if TensorRT found on the local system
#
#  ``TensorRT_INCLUDE_DIRS``
#    Location of TensorRT header files.
#
#  ``TensorRT_LIBRARIES``
#    The TensorRT libraries.
#
#  ``TensorRT::TensorRT``
#    The TensorRT target
#

include(FindPackageHandleStandardArgs)

if(NOT TensorRT_INCLUDE_DIR)
  find_path(TensorRT_INCLUDE_DIR NvInfer.h
    HINTS ${CUDA_HOME} ${CUDA_TOOLKIT_ROOT_DIR}
    PATH_SUFFIXES cuda/include include)
endif()

if(NOT TensorRT_LIBRARY)
  find_library(TensorRT_LIBRARY nvinfer_static
    HINTS ${CUDA_HOME} ${CUDA_TOOLKIT_ROOT_DIR}
    PATH_SUFFIXES lib lib64 cuda/lib cuda/lib64 lib/x64)
endif()
if(NOT TensorRT_LIBRARY)
  find_library(TensorRT_LIBRARY nvinfer
    HINTS ${CUDA_HOME} ${CUDA_TOOLKIT_ROOT_DIR}
    PATH_SUFFIXES lib lib64 cuda/lib cuda/lib64 lib/x64)
endif()

if(NOT TensorRT_PLUGIN_LIBRARY)
  find_library(TensorRT_PLUGIN_LIBRARY nvinfer_plugin_static
    HINTS ${CUDA_HOME} ${CUDA_TOOLKIT_ROOT_DIR}
    PATH_SUFFIXES lib lib64 cuda/lib cuda/lib64 lib/x64)
endif()
if(NOT TensorRT_PLUGIN_LIBRARY)
  find_library(TensorRT_PLUGIN_LIBRARY nvinfer_plugin
    HINTS ${CUDA_HOME} ${CUDA_TOOLKIT_ROOT_DIR}
    PATH_SUFFIXES lib lib64 cuda/lib cuda/lib64 lib/x64)
endif()

if(EXISTS "${TensorRT_INCLUDE_DIR}/NvInferVersion.h")
  file(READ ${TensorRT_INCLUDE_DIR}/NvInferVersion.h TensorRT_VERSION_HEADER_CONTENTS)

# Sample 
# #define NV_TENSORRT_MAJOR 6 //!< TensorRT major version.
# #define NV_TENSORRT_MINOR 0 //!< TensorRT minor version.
# #define NV_TENSORRT_PATCH 1 //!< TensorRT patch version.
# #define NV_TENSORRT_BUILD 5 //!< TensorRT build number.

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
endif()

set(TensorRT_INCLUDE_DIRS ${TensorRT_INCLUDE_DIR})
set(TensorRT_LIBRARIES ${TensorRT_LIBRARY} ${TensorRT_PLUGIN_LIBRARY})
mark_as_advanced(TensorRT_LIBRARY TensorRT_PLUGIN_LIBRARY TensorRT_INCLUDE_DIR)

find_package_handle_standard_args(TensorRT
      REQUIRED_VARS  TensorRT_INCLUDE_DIR TensorRT_LIBRARY TensorRT_PLUGIN_LIBRARY
      VERSION_VAR    TensorRT_VERSION
)

if(WIN32)
  set(TensorRT_DLL_DIR ${TensorRT_INCLUDE_DIR})
  list(TRANSFORM TensorRT_DLL_DIR APPEND "/../lib")
  find_file(TensorRT_LIBRARY_DLL NAMES nvinfer.dll PATHS ${TensorRT_DLL_DIR})
  find_file(TensorRT_PLUGIN_LIBRARY_DLL NAMES nvinfer_plugin.dll PATHS ${TensorRT_DLL_DIR})
endif()

if( TensorRT_FOUND AND NOT TARGET TensorRT::TensorRT )
  if( EXISTS "${TensorRT_LIBRARY_DLL}" )
    add_library( TensorRT::TensorRT        SHARED IMPORTED )
    set_target_properties( TensorRT::TensorRT PROPERTIES
      IMPORTED_LOCATION                 "${TensorRT_LIBRARY_DLL}"
      IMPORTED_IMPLIB                   "${TensorRT_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES     "${TensorRT_INCLUDE_DIR}"
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX" )

    add_library( TensorRT::TensorRT_PLUGIN SHARED IMPORTED )
    set_target_properties( TensorRT::TensorRT_PLUGIN PROPERTIES
      IMPORTED_LOCATION                 "${TensorRT_PLUGIN_LIBRARY_DLL}"
      IMPORTED_IMPLIB                   "${TensorRT_PLUGIN_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES     "${TensorRT_INCLUDE_DIR}"
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX" )
  else()
    add_library( TensorRT::TensorRT        UNKNOWN IMPORTED )
    set_target_properties( TensorRT::TensorRT PROPERTIES
      IMPORTED_LOCATION                 "${TensorRT_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES     "${TensorRT_INCLUDE_DIR}"
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX" )

    add_library( TensorRT::TensorRT_PLUGIN UNKNOWN IMPORTED )
    set_target_properties( TensorRT::TensorRT_PLUGIN PROPERTIES
      IMPORTED_LOCATION                 "${TensorRT_PLUGIN_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES     "${TensorRT_INCLUDE_DIR}"
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX" )
  endif()
endif()
