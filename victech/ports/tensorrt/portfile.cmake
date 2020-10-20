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
    set(SHA512_TENSORRT "e934ebcf53c118c9b86a73849fbeacd5bba94bbad5dfd2d4765011ca8083d0518cc026ef56924ff5030cfd1cb0bcd8a404dc961572bf7c54d4bbd22499bf8687")
    set(TENSORRT_OS "linux")
  endif()
else()
  # arm64 xavier 
  # files are gathered from jetpack 4.3

  set(TENSORRT_FULL_VERSION "${TENSORRT_VERSION}-cuda10.2") # for cuda of jetpack 4.4

  if(VCPKG_TARGET_IS_WINDOWS)
    message(FATAL_ERROR "This port is only for Linux")
  elseif(VCPKG_TARGET_IS_LINUX)
    set(TENSORRT_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_tensorrt/tensorrt/arm64/tensorrt-${TENSORRT_FULL_VERSION}.arm64.tar.gz")
    set(SHA512_TENSORRT "4048b77754351d96092f76679472e1bd7f2dbbe7fa9caf58e1a99e51c7150f5a248eb52a519d4cb7e4bebf19396f760149a14d7ffd69f34b2741ddfbc43d2282")
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
