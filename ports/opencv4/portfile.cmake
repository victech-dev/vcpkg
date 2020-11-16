if (EXISTS "${CURRENT_INSTALLED_DIR}/share/opencv2")
  message(FATAL_ERROR "OpenCV 2 is installed, please uninstall and try again:\n    vcpkg remove opencv2")
endif()

if (EXISTS "${CURRENT_INSTALLED_DIR}/share/opencv3")
  message(FATAL_ERROR "OpenCV 3 is installed, please uninstall and try again:\n    vcpkg remove opencv3")
endif()

set(OPENCV_VERSION "4.3.0")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO opencv/opencv
    REF ${OPENCV_VERSION}
    SHA512 ac22b41fffa3e3138701fa0df0d19900b3ce72e168f4478ecdc593c5c9fd004b4b1b26612d62c25b681db99a8720db7a11b5b224e576e595624965fa79b0f383
    HEAD_REF master
    PATCHES
      0001-disable-downloading.patch
      0002-install-options.patch
      0003-force-package-requirements.patch
      0004-fix-policy-CMP0057.patch
      0006-jpeg2000_getref.patch
      0009-fix-uwp.patch
      0010-fix-interface_link_libraries.patch # Remove this patch when the next update
)

file(REMOVE "${SOURCE_PATH}/cmake/FindCUDNN.cmake")

string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "static" BUILD_WITH_STATIC_CRT)

set(ADE_DIR ${CURRENT_INSTALLED_DIR}/share/ade CACHE PATH "Path to existing ADE CMake Config file")

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
 "ade"      WITH_ADE
 "contrib"  WITH_CONTRIB
 "cuda"     WITH_CUDA
 "cuda"     WITH_CUBLAS
 "eigen"    WITH_EIGEN
 "ffmpeg"   WITH_FFMPEG
 "gdcm"     WITH_GDCM
 "halide"   WITH_HALIDE
 "jasper"   WITH_JASPER
 "jpeg"     WITH_JPEG
 "nonfree"  OPENCV_ENABLE_NONFREE
 "openexr"  WITH_OPENEXR
 "opengl"   WITH_OPENGL
 "png"      WITH_PNG
 "qt"       WITH_QT
 "sfm"      BUILD_opencv_sfm
 "tiff"     WITH_TIFF
 "webp"     WITH_WEBP
 "world"    BUILD_opencv_world
)

# Cannot use vcpkg_check_features() for "dnn", ipp", "openmp", "ovis", "tbb", and "vtk".
# As the respective value of their variables can be unset conditionally.
set(BUILD_opencv_dnn OFF)
if("dnn" IN_LIST FEATURES)
  if(NOT VCPKG_TARGET_IS_ANDROID)
    set(BUILD_opencv_dnn ON)
  else()
    message(WARNING "The dnn module cannot be enabled on Android")
  endif()
endif()

set(WITH_IPP OFF)
if("ipp" IN_LIST FEATURES)
  set(WITH_IPP ON)
endif()

set(WITH_OPENMP OFF)
if("openmp" IN_LIST FEATURES)
  if(NOT VCPKG_TARGET_IS_OSX)
    set(WITH_OPENMP ON)
  else()
    message(WARNING "The OpenMP feature is not supported on macOS")
  endif()
endif()

set(BUILD_opencv_ovis OFF)
if("ovis" IN_LIST FEATURES)
  set(BUILD_opencv_ovis ON)
endif()

set(WITH_TBB OFF)
if("tbb" IN_LIST FEATURES)
  set(WITH_TBB ON)
endif()

set(WITH_VTK OFF)
if("vtk" IN_LIST FEATURES)
  set(WITH_VTK ON)
endif()

if("dnn" IN_LIST FEATURES)
  vcpkg_download_distfile(TINYDNN_ARCHIVE
    URLS "https://github.com/tiny-dnn/tiny-dnn/archive/v1.0.0a3.tar.gz"
    FILENAME "opencv-cache/tiny_dnn/adb1c512e09ca2c7a6faef36f9c53e59-v1.0.0a3.tar.gz"
    SHA512 5f2c1a161771efa67e85b1fea395953b7744e29f61187ac5a6c54c912fb195b3aef9a5827135c3668bd0eeea5ae04a33cc433e1f6683e2b7955010a2632d168b
  )
endif()

if("cuda" IN_LIST FEATURES)
  vcpkg_download_distfile(OCV_DOWNLOAD
      URLS "https://github.com/NVIDIA/NVIDIAOpticalFlowSDK/archive/79c6cee80a2df9a196f20afd6b598a9810964c32.zip"
      FILENAME "opencv-cache/nvidia_optical_flow/ca5acedee6cb45d0ec610a6732de5c15-79c6cee80a2df9a196f20afd6b598a9810964c32.zip"
      SHA512 d80cdedec588dafaad4ebb8615349f842ecdc64d3ca9480fee7086d606e6f2362606a9a2ce273c5cf507be2840ec24bbcbe32c2962672c3bcfb72d31428ef73d
  )
endif()

# Build image quality module when building with 'contrib' feature and not UWP.
set(BUILD_opencv_quality OFF)
if("contrib" IN_LIST FEATURES)
  if (VCPKG_TARGET_IS_UWP)
    set(BUILD_opencv_quality OFF)
    message(WARNING "The image quality module (quality) does not build for UWP, the module has been disabled.")
    # The hdf module is silently disabled by OpenCVs buildsystem if HDF5 is not detected.
    message(WARNING "The hierarchical data format module (hdf) depends on HDF5 which doesn't support UWP, the module has been disabled.")
  else()
    set(BUILD_opencv_quality CMAKE_DEPENDS_IN_PROJECT_ONLY)
  endif()

  vcpkg_from_github(
    OUT_SOURCE_PATH CONTRIB_SOURCE_PATH
    REPO opencv/opencv_contrib
    REF ${OPENCV_VERSION}
    SHA512 cfeda06a9f86ccaedbca9521c35bf685c3d8d3a182fb943f9378a7ecd1949d6e2e9df1673f0e3e9686840ca4c9e5a8e8cf2ac962a33b6e1f88f8278abd8c37e5
    HEAD_REF master
    PATCHES
      0005-add-missing-stdexcept-include.patch
  )
  set(BUILD_WITH_CONTRIB_FLAG "-DOPENCV_EXTRA_MODULES_PATH=${CONTRIB_SOURCE_PATH}/modules")

  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/34e4206aef44d50e6bbcd0ab06354b52e7466d26/boostdesc_bgm.i"
    FILENAME "opencv-cache/xfeatures2d/boostdesc/0ea90e7a8f3f7876d450e4149c97c74f-boostdesc_bgm.i"
    SHA512 5c8702a60314fac4ebb6dafb62a603948ec034058d1a582fcb89a063b51511802c02e192eadfc0b233b1f711f4c74cabab6d9ebe8a50c3554ea0ccdbef87dc5c
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/34e4206aef44d50e6bbcd0ab06354b52e7466d26/boostdesc_bgm_bi.i"
    FILENAME "opencv-cache/xfeatures2d/boostdesc/232c966b13651bd0e46a1497b0852191-boostdesc_bgm_bi.i"
    SHA512 b28ba2b615e0755ff0f6733b567682800fb9e7d522250aa498075cc1b8927f4177cacdcb0cfdf712539a29c4773232dc714931b6d292292b091b5cf170b203a6
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/34e4206aef44d50e6bbcd0ab06354b52e7466d26/boostdesc_bgm_hd.i"
    FILENAME "opencv-cache/xfeatures2d/boostdesc/324426a24fa56ad9c5b8e3e0b3e5303e-boostdesc_bgm_hd.i"
    SHA512 c214045c3730a1d9dfc594f70895edf82d2fd3058a3928908627014371e02460d052cbaedf41bb96cf76460c0a8b4b01b7b0ac7d269ec5d3f17f2a46c9f0091b
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/34e4206aef44d50e6bbcd0ab06354b52e7466d26/boostdesc_binboost_064.i"
    FILENAME "opencv-cache/xfeatures2d/boostdesc/202e1b3e9fec871b04da31f7f016679f-boostdesc_binboost_064.i"
    SHA512 f32240a7b975233d2bbad02fdb74c6e29ed71ed6f0c08172ca33eb1e69a7a7f6d6964adf41422213a0452121a9c4bb2effe3d7b9d6743c9bf58d4bc8c9b1db36
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/34e4206aef44d50e6bbcd0ab06354b52e7466d26/boostdesc_binboost_128.i"
    FILENAME "opencv-cache/xfeatures2d/boostdesc/98ea99d399965c03d555cef3ea502a0b-boostdesc_binboost_128.i"
    SHA512 f58e2bebfaa690d324691a6c2067d9a1e5267037ea0f2b397966289253b9efd27d8238aff6206e95262086e1fcddf01ae1a1c49f066a8bbac3aa7908214b9a8f
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/34e4206aef44d50e6bbcd0ab06354b52e7466d26/boostdesc_binboost_256.i"
    FILENAME "opencv-cache/xfeatures2d/boostdesc/e6dcfa9f647779eb1ce446a8d759b6ea-boostdesc_binboost_256.i"
    SHA512 351ee07b9714a379c311f293d96e99f001c894393c911a421b4c536345d43c02ba2d867e9f657eac104841563045ab8c8edab878e5ffeb1e1a7494375ef58987
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/34e4206aef44d50e6bbcd0ab06354b52e7466d26/boostdesc_lbgm.i"
    FILENAME "opencv-cache/xfeatures2d/boostdesc/0ae0675534aa318d9668f2a179c2a052-boostdesc_lbgm.i"
    SHA512 7fa12e2207ff154acf2433bbb4f3f47aa71d1fa8789493b688d635d20586b7ead30ee8dcd3b3753992ebbe98062cbde44d02683db1c563d52e35aefd7912a4f2
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/fccf7cd6a4b12079f73bbfb21745f9babcd4eb1d/vgg_generated_48.i"
    FILENAME "opencv-cache/xfeatures2d/vgg/e8d0dcd54d1bcfdc29203d011a797179-vgg_generated_48.i"
    SHA512 2403e9119738261a05a3116ca7e5c9e11da452c422f8670cd96ad2cb5bf970f76172e23b9913a3172adf06f2b31bee956f605b66dbccf3d706c4334aff713774
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/fccf7cd6a4b12079f73bbfb21745f9babcd4eb1d/vgg_generated_64.i"
    FILENAME "opencv-cache/xfeatures2d/vgg/7126a5d9a8884ebca5aea5d63d677225-vgg_generated_64.i"
    SHA512 2c954223677905f489b01988389ac80a8caa33bdb57adb3cb9409075012b5e2f472f14966d8be75d75c90c9330f66d59c69539dc6b5a5e265a4d98ff5041f0ea
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/fccf7cd6a4b12079f73bbfb21745f9babcd4eb1d/vgg_generated_80.i"
    FILENAME "opencv-cache/xfeatures2d/vgg/7cd47228edec52b6d82f46511af325c5-vgg_generated_80.i"
    SHA512 9931ad1d1bd6d11951ca5357ab0a524f6ff9b33f936ceeafebc0dafb379ec7e2105e467443e9f424f60a0f2f445bdff821ed9e42330abed883227183ebad4a9e
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/fccf7cd6a4b12079f73bbfb21745f9babcd4eb1d/vgg_generated_120.i"
    FILENAME "opencv-cache/xfeatures2d/vgg/151805e03568c9f490a5e3a872777b75-vgg_generated_120.i"
    SHA512 ad7c1d2b159ab5790c898815663bb90549f1cf7ade3c82d939d381608b26d26c5b2af01eb1ba21f4d114ced74586ab3fc83f14e2d8cfe4e6faac538aa0e7e255
  )
  vcpkg_download_distfile(OCV_DOWNLOAD
    URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/8afa57abc8229d611c4937165d20e2a2d9fc5a12/face_landmark_model.dat"
    FILENAME "opencv-cache/data/7505c44ca4eb54b4ab1e4777cb96ac05-face_landmark_model.dat"
    SHA512 c16e60a6c4bb4de3ab39b876ae3c3f320ea56f69c93e9303bd2dff8760841dcd71be4161fff8bc71e8fe4fe8747fa8465d49d6bd8f5ebcdaea161f4bc2da7c93
  )
endif()

if(WITH_IPP)
  if(VCPKG_TARGET_IS_OSX)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
      vcpkg_download_distfile(OCV_DOWNLOAD
        URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/a56b6ac6f030c312b2dce17430eef13aed9af274/ippicv/ippicv_2020_mac_intel64_20191018_general.tgz"
        FILENAME "opencv-cache/ippicv/1c3d675c2a2395d094d523024896e01b-ippicv_2020_mac_intel64_20191018_general.tgz"
        SHA512 454dfaaa245e3a3b2f1ffb1aa8e27e280b03685009d66e147482b14e5796fdf2d332cac0f9b0822caedd5760fda4ee0ce2961889597456bbc18202f10bf727cd
    )
    else()
      message(WARNING "This target architecture is not supported IPPICV")
      set(WITH_IPP OFF)
    endif()
  elseif(VCPKG_TARGET_IS_LINUX)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
      vcpkg_download_distfile(OCV_DOWNLOAD
        URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/a56b6ac6f030c312b2dce17430eef13aed9af274/ippicv/ippicv_2020_lnx_intel64_20191018_general.tgz"
        FILENAME "opencv-cache/ippicv/7421de0095c7a39162ae13a6098782f9-ippicv_2020_lnx_intel64_20191018_general.tgz"
        SHA512 de6d80695cd6deef359376476edc4ff85fdddcf94972b936e0017f8a48aaa5d18f55c4253ae37deb83bff2f71410f68408063c88b5f3bf4df3c416aa93ceca87
      )
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
      vcpkg_download_distfile(OCV_DOWNLOAD
        URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/a56b6ac6f030c312b2dce17430eef13aed9af274/ippicv/ippicv_2020_lnx_ia32_20191018_general.tgz"
        FILENAME "opencv-cache/ippicv/ad189a940fb60eb71f291321322fe3e8-ippicv_2020_lnx_ia32_20191018_general.tgz"
        SHA512 5ca9dafc3a634e2a5f83f6a498611c990ef16d54358e9b44574b01694e9d64b118d46d6e2011506e40d37e5a9865f576f790e37ff96b7c8b503507633631a296
      )
    else()
      message(WARNING "This target architecture is not supported IPPICV")
      set(WITH_IPP OFF)
    endif()
  elseif(VCPKG_TARGET_IS_WINDOWS)
    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
      vcpkg_download_distfile(OCV_DOWNLOAD
        URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/a56b6ac6f030c312b2dce17430eef13aed9af274/ippicv/ippicv_2020_win_intel64_20191018_general.zip"
        FILENAME "opencv-cache/ippicv/879741a7946b814455eee6c6ffde2984-ippicv_2020_win_intel64_20191018_general.zip"
        SHA512 50c4af4b7fe2161d652264230389dad2330e8c95b734d04fb7565bffdab855c06d43085e480da554c56b04f8538087d49503538d5943221ee2a772ee7be4c93c
      )
    elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
      vcpkg_download_distfile(OCV_DOWNLOAD
        URLS "https://raw.githubusercontent.com/opencv/opencv_3rdparty/a56b6ac6f030c312b2dce17430eef13aed9af274/ippicv/ippicv_2020_win_ia32_20191018_general.zip"
        FILENAME "opencv-cache/ippicv/cd39bdf0c2e1cac9a61101dad7a2413e-ippicv_2020_win_ia32_20191018_general.zip"
        SHA512 058d00775d9f16955c7a557d554b8c2976ab9dbad4ba3fdb9823c0f768809edbd835e4397f01dc090a9bc80d81de834375e7006614d2a898f42e8004de0e04bf
      )
    else()
      message(WARNING "This target architecture is not supported IPPICV")
      set(WITH_IPP OFF)
    endif()
  else()
    message(WARNING "This target architecture is not supported IPPICV")
    set(WITH_IPP OFF)
  endif()
endif()

set(WITH_MSMF ON)
if(NOT VCPKG_TARGET_IS_WINDOWS OR VCPKG_TARGET_IS_UWP)
  set(WITH_MSMF OFF)
endif()

if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
  if (WITH_TBB)
    message(WARNING "TBB is currently unsupported in this build configuration, turning it off")
    set(WITH_TBB OFF)
  endif()

  if (WITH_VTK)
    message(WARNING "VTK is currently unsupported in this build configuration, turning it off")
    set(WITH_VTK OFF)
  endif()

  if (VCPKG_TARGET_IS_WINDOWS AND BUILD_opencv_ovis)
    message(WARNING "OVIS is currently unsupported in this build configuration, turning it off")
    set(BUILD_opencv_ovis OFF)
  endif()
endif()

if("ffmpeg" IN_LIST FEATURES)
  if(VCPKG_TARGET_IS_UWP)
    set(VCPKG_C_FLAGS "/sdl- ${VCPKG_C_FLAGS}")
    set(VCPKG_CXX_FLAGS "/sdl- ${VCPKG_CXX_FLAGS}")
  endif()
endif()

if("qt" IN_LIST FEATURES)
  list(APPEND ADDITIONAL_BUILD_FLAGS "-DCMAKE_AUTOMOC=ON")
endif()

vcpkg_configure_cmake(
    PREFER_NINJA
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        ###### ocv_options
        -DOpenCV_INSTALL_BINARIES_PREFIX=
        -DOPENCV_BIN_INSTALL_PATH=bin
        -DOPENCV_INCLUDE_INSTALL_PATH=include
        -DOPENCV_LIB_INSTALL_PATH=lib
        -DOPENCV_3P_LIB_INSTALL_PATH=lib
        -DOPENCV_CONFIG_INSTALL_PATH=share/opencv
        -DINSTALL_TO_MANGLED_PATHS=OFF
        -DOPENCV_FFMPEG_USE_FIND_PACKAGE=FFMPEG
        -DCMAKE_DEBUG_POSTFIX=d
        -DOPENCV_DLLVERSION=
        -DOPENCV_DEBUG_POSTFIX=d
        -DOPENCV_GENERATE_SETUPVARS=OFF
        # Do not build docs/examples
        -DBUILD_DOCS=OFF
        -DBUILD_EXAMPLES=OFF
        -Dade_DIR=${ADE_DIR}
        ###### Disable build 3rd party libs
        -DBUILD_JASPER=OFF
        -DBUILD_JPEG=OFF
        -DBUILD_OPENEXR=OFF
        -DBUILD_PNG=OFF
        -DBUILD_TIFF=OFF
        -DBUILD_WEBP=OFF
        -DBUILD_ZLIB=OFF
        -DBUILD_TBB=OFF
        -DBUILD_IPP_IW=OFF
        -DBUILD_ITT=OFF
        ###### Disable build 3rd party components
        -DBUILD_PROTOBUF=OFF
        ###### OpenCV Build components
        -DBUILD_opencv_apps=OFF
        -DBUILD_opencv_java=OFF
        -DBUILD_opencv_js=OFF
        -DBUILD_ANDROID_PROJECT=OFF
        -DBUILD_ANDROID_EXAMPLES=OFF
        -DBUILD_PACKAGE=OFF
        -DBUILD_PERF_TESTS=OFF
        -DBUILD_TESTS=OFF
        -DBUILD_WITH_DEBUG_INFO=ON
        -DBUILD_WITH_STATIC_CRT=${BUILD_WITH_STATIC_CRT}
        -DBUILD_JAVA=OFF
        -DCURRENT_INSTALLED_DIR=${CURRENT_INSTALLED_DIR}
        ###### PROTOBUF
        -DPROTOBUF_UPDATE_FILES=${BUILD_opencv_dnn}
        -DUPDATE_PROTO_FILES=${BUILD_opencv_dnn}
        ###### PYLINT/FLAKE8
        -DENABLE_PYLINT=OFF
        -DENABLE_FLAKE8=OFF
        # CMAKE
        -DCMAKE_DISABLE_FIND_PACKAGE_Git=ON
        -DCMAKE_DISABLE_FIND_PACKAGE_JNI=ON
        # ENABLE
        -DENABLE_CXX11=ON
        ###### OPENCV vars
        "-DOPENCV_DOWNLOAD_PATH=${DOWNLOADS}/opencv-cache"
        ${BUILD_WITH_CONTRIB_FLAG}
        -DOPENCV_OTHER_INSTALL_PATH=share/opencv
        ###### customized properties
        ## Options from vcpkg_check_features()
        ${FEATURE_OPTIONS}
        -DHALIDE_ROOT_DIR=${CURRENT_INSTALLED_DIR}
        -DCMAKE_DISABLE_FIND_PACKAGE_Halide=ON
        -DWITH_IPP=${WITH_IPP}
        -DWITH_MSMF=${WITH_MSMF}
        -DWITH_OPENMP=${WITH_OPENMP}
        -DWITH_PROTOBUF=${BUILD_opencv_dnn}
        -DWITH_TBB=${WITH_TBB}
        -DWITH_VTK=${WITH_VTK}
        -DWITH_GTK=ON
        -DWITH_OPENJPEG=OFF
        ###### WITH PROPERTIES explicitly disabled, they have problems with libraries if already installed by user and that are "involuntarily" found during install
        -DWITH_LAPACK=OFF
        ###### BUILD_options (mainly modules which require additional libraries)
        -DBUILD_opencv_ovis=${BUILD_opencv_ovis}
        -DBUILD_opencv_dnn=${BUILD_opencv_dnn}
        ###### The following modules are disabled for UWP
        -DBUILD_opencv_quality=${BUILD_opencv_quality}
        ###### The following module is disabled because it's broken #https://github.com/opencv/opencv_contrib/issues/2307
        -DBUILD_opencv_rgbd=OFF
        ###### Additional build flags
        ${ADDITIONAL_BUILD_FLAGS}
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH "share/opencv" TARGET_PATH "share/opencv")
vcpkg_copy_pdbs()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
  file(READ ${CURRENT_PACKAGES_DIR}/share/opencv/OpenCVModules.cmake OPENCV_MODULES)
  set(DEPS_STRING "include(CMakeFindDependencyMacro)
find_dependency(protobuf CONFIG)
if(protobuf_FOUND)
  if(TARGET protobuf::libprotobuf)
    add_library (libprotobuf INTERFACE IMPORTED)
    set_target_properties(libprotobuf PROPERTIES
      INTERFACE_LINK_LIBRARIES protobuf::libprotobuf
    )
  else()
    add_library (libprotobuf UNKNOWN IMPORTED)
    set_target_properties(libprotobuf PROPERTIES
      IMPORTED_LOCATION \"${Protobuf_LIBRARY}\"
      INTERFACE_INCLUDE_DIRECTORIES \"${Protobuf_INCLUDE_DIR}\"
      INTERFACE_SYSTEM_INCLUDE_DIRECTORIES \"${Protobuf_INCLUDE_DIR}\"
    )
  endif()
endif()
find_dependency(Threads)")
  if("tiff" IN_LIST FEATURES)
    string(APPEND DEPS_STRING "\nfind_dependency(TIFF)")
  endif()
  if("cuda" IN_LIST FEATURES)
    string(APPEND DEPS_STRING "\nfind_dependency(CUDA)")
  endif()
  if(BUILD_opencv_quality)
    string(APPEND DEPS_STRING "
# C language is required for try_compile tests in FindHDF5
enable_language(C)
find_dependency(HDF5)
find_dependency(Tesseract)")
  endif()
  if(WITH_TBB)
    string(APPEND DEPS_STRING "\nfind_dependency(TBB)")
  endif()
  if(WITH_VTK)
    string(APPEND DEPS_STRING "\nfind_dependency(VTK)")
  endif()
  if("sfm" IN_LIST FEATURES)
    string(APPEND DEPS_STRING "\nfind_dependency(gflags CONFIG)\nfind_dependency(Ceres CONFIG)")
  endif()
  if("eigen" IN_LIST FEATURES)
    string(APPEND DEPS_STRING "\nfind_dependency(Eigen3 CONFIG)")
  endif()
  if("openexr" IN_LIST FEATURES)
    string(APPEND DEPS_STRING "\nfind_dependency(OpenEXR CONFIG)")
  endif()
  if(WITH_OPENMP)
    string(APPEND DEPS_STRING "\nfind_dependency(OpenMP CONFIG)")
  endif()
  if(BUILD_opencv_ovis)
    string(APPEND DEPS_STRING "\nfind_dependency(Ogre)\nfind_dependency(Freetype)")
  endif()
  if("qt" IN_LIST FEATURES)
    string(APPEND DEPS_STRING "
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
find_dependency(Qt5 COMPONENTS OpenGL Concurrent Test)")
  endif()
  if("ade" IN_LIST FEATURES)
    string(APPEND DEPS_STRING "\nfind_dependency(ade)")
  endif()
  if("gdcm" IN_LIST FEATURES)
    string(APPEND DEPS_STRING "\nfind_dependency(GDCM)")
  endif()

  string(REPLACE "set(CMAKE_IMPORT_FILE_VERSION 1)"
                 "set(CMAKE_IMPORT_FILE_VERSION 1)\n${DEPS_STRING}" OPENCV_MODULES "${OPENCV_MODULES}")

  if(WITH_OPENMP)
    string(REPLACE "set_target_properties(opencv_core PROPERTIES
  INTERFACE_LINK_LIBRARIES \""
                   "set_target_properties(opencv_core PROPERTIES
  INTERFACE_LINK_LIBRARIES \"\$<LINK_ONLY:OpenMP::OpenMP_CXX>;" OPENCV_MODULES "${OPENCV_MODULES}")
  endif()

  if(BUILD_opencv_ovis)
    string(REPLACE "OgreGLSupportStatic"
                   "OgreGLSupport" OPENCV_MODULES "${OPENCV_MODULES}")
  endif()

  file(WRITE ${CURRENT_PACKAGES_DIR}/share/opencv/OpenCVModules.cmake "${OPENCV_MODULES}")

  file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE ${CURRENT_PACKAGES_DIR}/LICENSE)
file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/LICENSE)

if(VCPKG_TARGET_IS_ANDROID)
  file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/README.android)
  file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/README.android)
endif()

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
