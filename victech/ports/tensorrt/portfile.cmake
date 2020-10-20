include(vcpkg_common_functions)

if(VCPKG_TARGET_IS_UWP OR VCPKG_TARGET_IS_OSX)
  message(FATAL_ERROR "This port is only for Windows Desktop or Linux")
endif()

if(NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "x64" AND NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
  message(FATAL_ERROR "This port is only for x64 or arm64 architectures")
endif()

vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY ONLY_DYNAMIC_CRT)

#note: this port must be kept in sync with CUDA,cudnn port: every time one is upgraded, the other must be too
set(TENSORRT_VERSION "6.0.1")

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
  # original download
  # https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/

  set(TENSORRT_FULL_VERSION "${TENSORRT_VERSION}-cuda10.1")

  if(VCPKG_TARGET_IS_WINDOWS)
    set(TENSORRT_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_tensorrt/tensorrt/windows10.x86_x64/tensorrt-${TENSORRT_VERSION}.win.tar.gz")
    set(SHA512_TENSORRT "7596a2776baa071b5e8a74bdf4102429b25455be1e5519644daeae5d3a3060dd98d8ff4594549b16c3d0a3b38cba71edcc9b7e2a3ace8ff2a215ebce7064cf9e")
    set(TENSORRT_OS "windows")
  elseif(VCPKG_TARGET_IS_LINUX)
    set(TENSORRT_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_tensorrt/tensorrt/amd64/tensorrt-${TENSORRT_VERSION}.amd64.tar.gz")
    set(SHA512_TENSORRT "9caf5cae5b16c6fa087de9ce791d1bbc93ebbc3cd5c90e293747808c4cc25a35f5b57a1f13e2a7c421ec0784cb47aa9919ec0f4b84e86c5949a36248dad85875")
    set(TENSORRT_OS "linux")
  endif()
else()
  # arm64 xavier 
  # files are gathered from jetpack 4.3

  set(TENSORRT_FULL_VERSION "${TENSORRT_VERSION}-cuda10.0") # note jetpack doesn't support 10.1

  if(VCPKG_TARGET_IS_WINDOWS)
    message(FATAL_ERROR "This port is only for Linux")
  elseif(VCPKG_TARGET_IS_LINUX)
    set(TENSORRT_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_tensorrt/tensorrt/arm64/tensorrt-${TENSORRT_VERSION}.arm64.tar.gz")
    set(SHA512_TENSORRT "c1ba9146507f1b9a99a4e24dfe56e2d8ca5fcb287ffc2687481d5237a46c35423e6cff5c6e729cae87c04de9118c0c0c13ea710a862c98bab5b731aa2e260435")
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

string(REPLACE "." ";" VERSION_LIST ${TENSORRT_VERSION})
list(GET VERSION_LIST 0 TENSORRT_VERSION_MAJOR)
list(GET VERSION_LIST 1 TENSORRT_VERSION_MINOR)
list(GET VERSION_LIST 2 TENSORRT_VERSION_PATCH)

if(VCPKG_TARGET_IS_WINDOWS)
  file(GLOB LIB_FILES "${SOURCE_PATH}/lib/*.lib")
  file(GLOB DLL_FILES "${SOURCE_PATH}/lib/*.dll")
  file(GLOB INCLUDE_FILES "${SOURCE_PATH}/include/*.h")
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
  file(INSTALL ${DLL_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
  file(INSTALL ${DLL_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
  file(INSTALL ${INCLUDE_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/include)
  file(INSTALL "${SOURCE_PATH}/copyright" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
elseif(VCPKG_TARGET_IS_LINUX)
  file(GLOB LIB_FILES "${SOURCE_PATH}/lib/*.a")
  file(GLOB INCLUDE_FILES "${SOURCE_PATH}/include/*.h")
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
  file(INSTALL ${INCLUDE_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/include)
  file(INSTALL "${SOURCE_PATH}/copyright" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/FindTensorRT.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
