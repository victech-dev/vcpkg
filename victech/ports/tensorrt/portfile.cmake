include(vcpkg_common_functions)

if(VCPKG_TARGET_IS_UWP OR VCPKG_TARGET_IS_OSX)
  message(FATAL_ERROR "This port is only for Windows Desktop or Linux")
endif()

if(NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "x64" AND NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
  message(FATAL_ERROR "This port is only for x64 or arm64 architectures")
endif()

vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY ONLY_DYNAMIC_CRT)

#note: this port must be kept in sync with CUDA,cudnn port: every time one is upgraded, the other must be too
set(TENSORRT_VERSION "7.1.3")

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
  # original download
  # https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/

  set(TENSORRT_FULL_VERSION "${TENSORRT_VERSION}-cuda11.0")

  if(VCPKG_TARGET_IS_WINDOWS)
    set(TENSORRT_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_tensorrt/tensorrt/windows10.x86_x64/tensorrt-${TENSORRT_FULL_VERSION}.win.tar.gz")
    set(SHA512_TENSORRT "234effd23aae0db204602310356106e8c98ec807440f23544bccbf812fb44bb26344015623441a39400a4097709a480216bf0fefede397a1b35c52944f95b788")
    set(TENSORRT_OS "windows")
  elseif(VCPKG_TARGET_IS_LINUX)
    set(TENSORRT_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_tensorrt/tensorrt/amd64/tensorrt-${TENSORRT_FULL_VERSION}.amd64.tar.gz")
    set(SHA512_TENSORRT "8b0967d3ef91a883f564cc0f99b4b961fc2da7959a3fe7ed91d09e896fa3ec26fabe69ec8782a4996d53c9fcd531dab4033fdccc48a5c62f4941c0c73b340523")
    set(TENSORRT_OS "linux")
  endif()
else()
  set(TENSORRT_FULL_VERSION "${TENSORRT_VERSION}-cuda10.2") # for cuda of jetpack 4.4

  if(VCPKG_TARGET_IS_WINDOWS)
    message(FATAL_ERROR "This port is only for Linux")
  elseif(VCPKG_TARGET_IS_LINUX)
    set(TENSORRT_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_tensorrt/tensorrt/arm64/tensorrt-${TENSORRT_FULL_VERSION}.arm64.tar.gz")
    set(SHA512_TENSORRT "7616dd6ecb915755a03de989527db518f34efa8bfc6a83fbda716114fa0f89b6012196c1c51883a806aec126e5f0896fc2b7f8ba2d0ad874a7a488060999dd8f")
    set(TENSORRT_OS "linux")
  endif()
endif()

vcpkg_download_distfile(ARCHIVE
  URLS ${TENSORRT_DOWNLOAD_LINK}
  FILENAME "tensorrt-${TENSORRT_FULL_VERSION}-${VCPKG_TARGET_ARCHITECTURE}-${TENSORRT_OS}.tar.gz"
  SHA512 ${SHA512_TENSORRT}
)

vcpkg_extract_source_archive_ex(
  OUT_SOURCE_PATH SOURCE_PATH
  ARCHIVE ${ARCHIVE}
  # NO_REMOVE_ONE_LEVEL
)

if(VCPKG_TARGET_IS_WINDOWS)
  file(GLOB LIB_FILES "${SOURCE_PATH}/lib/*.lib")
  file(GLOB DLL_FILES "${SOURCE_PATH}/lib/*.dll")
  file(GLOB INCLUDE_FILES "${SOURCE_PATH}/include/*.h")
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
  file(INSTALL ${DLL_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
  file(INSTALL ${DLL_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
  file(INSTALL ${INCLUDE_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/include)
elseif(VCPKG_TARGET_IS_LINUX)
  file(GLOB LIB_FILES "${SOURCE_PATH}/lib/*")
  file(GLOB INCLUDE_FILES "${SOURCE_PATH}/include/*")
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
  file(INSTALL ${INCLUDE_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/include)
endif()

file(INSTALL "${SOURCE_PATH}/copyright" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/FindTensorRT.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
