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
)

#make sure we don't use any integrated pre-built library nor any unnecessary CMake module
file(REMOVE ${SOURCE_PATH}/cmake/FindCUDNN.cmake)

vcpkg_configure_cmake(
  SOURCE_PATH ${SOURCE_PATH}
  DISABLE_PARALLEL_CONFIGURE
  PREFER_NINJA
)

vcpkg_install_cmake()

#install cmake for debug
file(COPY "${CURRENT_PACKAGES_DIR}/debug/share/${PORT}/tkDNNTargets-debug.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# remove debug directories
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/tools")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# use victech's tkDNNConfig.cmake
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/tkDNNConfig.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})

# install license
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
