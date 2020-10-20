include(vcpkg_common_functions)

if(VCPKG_TARGET_IS_UWP OR VCPKG_TARGET_IS_OSX)
  message(FATAL_ERROR "This port is only for Windows Desktop or Linux")
endif()

if(NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "x64" AND NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
  message(FATAL_ERROR "This port is only for x64 or arm64 architectures")
endif()

vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY ONLY_DYNAMIC_CRT)

#note: this port must be kept in sync with CUDA port: every time one is upgraded, the other must be too
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
  set(CUDNN_VERSION "8.0.4")
  set(CUDNN_FULL_VERSION "${CUDNN_VERSION}-cuda11.0_0")

  if(VCPKG_TARGET_IS_WINDOWS)
    set(CUDNN_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_cudnn/cudnn/windows10.x86_x64/cudnn-${CUDNN_FULL_VERSION}.tar.gz")
    set(SHA512_CUDNN "5b14f397b0df35e4f2d8b50ac4c08090f906aa97a7bf6b96d06389836f6d37229cef09d57d8d0a3ee80c392745057b426d078861edd736ca5d4f3d29205234e2")
    set(CUDNN_OS "windows")
  elseif(VCPKG_TARGET_IS_LINUX)
    set(CUDNN_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_cudnn/cudnn/amd64/cudnn-${CUDNN_FULL_VERSION}.tar.gz")
    set(SHA512_CUDNN "6d5404ac9da28dd5e97e650c3fc8bceb70f5a5c35f6af8d474a9a473985498cbaa6af725125821e337561f82b6aa08069d4d44ac165c2dc3e263939aa54fd21f")
    set(CUDNN_OS "linux")
  endif()

  vcpkg_download_distfile(ARCHIVE
      URLS ${CUDNN_DOWNLOAD_LINK}
      FILENAME "cudnn-${CUDNN_FULL_VERSION}-${CUDNN_OS}.tar.gz"
      SHA512 ${SHA512_CUDNN}
  )

  vcpkg_extract_source_archive_ex(
      OUT_SOURCE_PATH SOURCE_PATH
      ARCHIVE ${ARCHIVE}
      NO_REMOVE_ONE_LEVEL
  )
else()
  # arm64 xavier jetpack 4.3 or 4.4
  # assume build on xaiver dev-kit itself
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
      set(CUDNN_VERSION "7.6.3")
      set(INCLUDE_PATH "/usr/include")
      set(SOURCE_PATH "/usr/lib/aarch64-linux-gnu")
  else()
      # for jetpack 4.4
      set(CUDNN_VERSION "8.0.0")
      set(INCLUDE_PATH "/usr/include")
      set(SOURCE_PATH "/usr/lib/aarch64-linux-gnu")
  endif()
endif()

string(REPLACE "." ";" VERSION_LIST ${CUDNN_VERSION})
list(GET VERSION_LIST 0 CUDNN_VERSION_MAJOR)
list(GET VERSION_LIST 1 CUDNN_VERSION_MINOR)
list(GET VERSION_LIST 2 CUDNN_VERSION_PATCH)

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
  if(VCPKG_TARGET_IS_WINDOWS)
    FILE( GLOB H_FILES  ${SOURCE_PATH}/include/*.h )
    FILE( GLOB LIB_FILES  ${SOURCE_PATH}/lib/x64/*.lib )
    FILE( GLOB DLL_FILES  ${SOURCE_PATH}/bin/*.dll )
    file(INSTALL ${H_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/include)
    file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(INSTALL ${DLL_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
    file(INSTALL ${DLL_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
  elseif(VCPKG_TARGET_IS_LINUX)
    FILE( GLOB H_FILES  ${SOURCE_PATH}/include/*.h )
    FILE( GLOB LIB_FILES  ${SOURCE_PATH}/lib/* )
    file(INSTALL ${H_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/include)
    file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
  endif()

  file(INSTALL "${SOURCE_PATH}/LICENSE.txt" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
else()
  FILE( GLOB H_FILES ${INCLUDE_PATH}/cudnn*.h )
  FILE( GLOB LIB_FILES  ${SOURCE_PATH}/libcudnn* )
  file(INSTALL ${H_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/include)
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
  file(INSTALL ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)

  file(INSTALL "/usr/share/doc/cuda-license-10-2/copyright" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/FindCUDNN.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
