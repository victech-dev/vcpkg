include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ceccocats/tkDNN
    REF 38106a9495438465118f8e36021126f5fbcbb57d
    SHA512 748e3d0439837fb6c1c4e58040240b5794ba271e5f7d25bfd59e2cdc9c63dc64f2e59e03735d56a96037be8472bb502134a52eafa251d444d49e2eb70d07c1e2
    HEAD_REF master
    PATCHES
      renew_cmakelist_for_vcpkg.patch
      clean_up_include.patch
      fix-windows-build.patch
)

#make sure we don't use any integrated pre-built library nor any unnecessary CMake module
file(REMOVE ${SOURCE_PATH}/cmake/FindCUDNN.cmake)

if (NOT VCPKG_CMAKE_SYSTEM_NAME AND NOT ENV{CUDACXX})
  #CMake looks for nvcc only in PATH and CUDACXX env vars for the Ninja generator. Since we filter path on vcpkg and CUDACXX env var is not set by CUDA installer on Windows, CMake cannot find CUDA when using Ninja generator, so we need to manually enlight it if necessary (https://gitlab.kitware.com/cmake/cmake/issues/19173). Otherwise we could just disable Ninja and use MSBuild, but unfortunately CUDA installer does not integrate with some distributions of MSBuild (like the ones inside Build Tools), making CUDA unavailable otherwise in those cases, which we want to avoid
  set(ENV{CUDACXX} "$ENV{CUDA_PATH}/bin/nvcc.exe")
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
  set(BUILD_SHARED_LIBS ON)
else()
  set(BUILD_SHARED_LIBS OFF)
endif()

vcpkg_configure_cmake(
  SOURCE_PATH ${SOURCE_PATH}
  DISABLE_PARALLEL_CONFIGURE
  OPTIONS -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
  PREFER_NINJA
)

vcpkg_install_cmake()

#install cmake for debug
file(COPY "${CURRENT_PACKAGES_DIR}/debug/share/${PORT}/tkDNNTargets-debug.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# remove debug directories
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/tools")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
# enable/disable DLL header
file(READ ${CURRENT_PACKAGES_DIR}/include/tkDNN/dll.h DLL_H)
if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    string(REPLACE "#ifdef tkDNN_DLL" "#if 1" DLL_H "${DLL_H}")
else()
    string(REPLACE "#ifdef tkDNN_DLL" "#if 0" DLL_H "${DLL_H}")
endif()
file(WRITE ${CURRENT_PACKAGES_DIR}/include/tkDNN/dll.h "${DLL_H}")


# use victech's tkDNNConfig.cmake
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/tkDNNConfig.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})

# install license
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
