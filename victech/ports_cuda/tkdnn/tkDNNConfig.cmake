# ===================================================================================
#  The tkDNN CMake configuration file
#
#  Usage from an external project:
#    In your CMakeLists.txt, add these lines:
#
#    find_package(tkDNN REQUIRED)
#    include_directories(${tkDNN_INCLUDE_DIRS})
#    target_link_libraries(MY_TARGET_NAME ${tkDNN_LIBRARIES})
#
#    This file will define the following variables:
#      - tkDNN_LIBRARIES             : The list of all imported targets for OpenCV modules.
#      - tkDNN_INCLUDE_DIRS          : The tkDNN include directories.
#      ### TODO version vars
#      - tkDNN_VERSION               : The version of this tkDNN build: "4.1.1"
#      - tkDNN_VERSION_MAJOR         : Major version part of tkDNN_VERSION: "4"
#      - tkDNN_VERSION_MINOR         : Minor version part of tkDNN_VERSION: "1"

get_filename_component(tkDNN_CMAKE_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
list(APPEND CMAKE_MODULE_PATH "${tkDNN_CMAKE_DIR}")

include(CMakeFindDependencyMacro)
find_dependency(CUDA)
find_dependency(OpenCV)
find_dependency(CUDNN)
find_dependency(Eigen3)
find_dependency(TensorRT)

# Our library dependencies (contains definitions for IMPORTED targets)
include("${tkDNN_CMAKE_DIR}/tkDNNTargets.cmake")
include("${tkDNN_CMAKE_DIR}/tkDNNConfigVersion.cmake")

# Compute include dir
set(tkDNN_INCLUDE_DIRS "${tkDNN_CMAKE_DIR}/../../include")

# These are IMPORTED targets created by tkDNNTargets.cmake
set(tkDNN_LIBRARIES "tkDNN")

