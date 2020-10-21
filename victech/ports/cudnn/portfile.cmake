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
  set(CUDNN_FULL_VERSION "${CUDNN_VERSION}-cuda11.0")

  if(VCPKG_TARGET_IS_WINDOWS)
    set(CUDNN_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_cudnn/cudnn/windows10.x86_x64/cudnn-${CUDNN_FULL_VERSION}.tar.gz")
    set(SHA512_CUDNN "e9552d61f6e004aebae4da6166f64242ac8553ae283a2c9fdd3b39b3741f9bf8f24b1f5e4c052b8e5ef72a107a8012c0d99105389798cddc77bf1bc0993cf589")
    set(CUDNN_OS "windows")
  elseif(VCPKG_TARGET_IS_LINUX)
    set(CUDNN_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_cudnn/cudnn/amd64/cudnn-${CUDNN_FULL_VERSION}.tar.gz")
    set(SHA512_CUDNN "30f4909cdfd82f4c97d3b8577b5d71a62ec4c12254099bd4d44a6b79c1d2cc37a67d16a796885f008cb504449e0bd2fc4d277926f0569f236a4961efb1171ae0")
    set(CUDNN_OS "linux")
  endif()
else()
  # assume jetpack 4.4
  set(CUDNN_VERSION "8.0.0")
  set(CUDNN_FULL_VERSION "${CUDNN_VERSION}-cuda10.2")

  set(CUDNN_DOWNLOAD_LINK "http://race.victech.io:8082/download/vcpkg_cudnn/cudnn/arm64/cudnn-${CUDNN_FULL_VERSION}.tar.gz")
  set(SHA512_CUDNN "ca544f780e9d4ea7b0a3703d2209152827179b0138315bf75cb9cf107a9cdc82e002c4fa2e18d5caa1113b498a365bdccb0c47f60c22e512df196f5b97782918")
  set(CUDNN_OS "linux")
endif()

vcpkg_download_distfile(ARCHIVE
    URLS ${CUDNN_DOWNLOAD_LINK}
    FILENAME "cudnn-${CUDNN_FULL_VERSION}-${VCPKG_TARGET_ARCHITECTURE}-${CUDNN_OS}.tar.gz"
    SHA512 ${SHA512_CUDNN}
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    # NO_REMOVE_ONE_LEVEL
)

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
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/FindCUDNN.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
