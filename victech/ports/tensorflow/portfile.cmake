#vcpkg_fail_port_install(ON_ARCH "x86" "arm" ON_TARGET "UWP")

set(TF_VERSION 2.3.1)
set(TF_VERSION_SHORT 2.3)

vcpkg_find_acquire_program(BAZEL)
get_filename_component(BAZEL_DIR "${BAZEL}" DIRECTORY)
vcpkg_add_to_path(PREPEND ${BAZEL_DIR})
set(ENV{BAZEL_BIN_PATH} "${BAZEL}")

function(tensorflow_try_remove_recurse_wait PATH_TO_REMOVE)
	file(REMOVE_RECURSE ${PATH_TO_REMOVE})
	if(EXISTS "${PATH_TO_REMOVE}")
		vcpkg_execute_required_process(COMMAND ${CMAKE_COMMAND} -E sleep 5 WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR} LOGNAME prerequesits-sleep-${TARGET_TRIPLET})
		file(REMOVE_RECURSE ${PATH_TO_REMOVE})
	endif()
endfunction()

vcpkg_find_acquire_program(GIT)
get_filename_component(GIT_DIR "${GIT}" DIRECTORY)
vcpkg_add_to_path(PREPEND ${GIT_DIR})

if(CMAKE_HOST_WIN32)
	vcpkg_acquire_msys(MSYS_ROOT PACKAGES bash unzip patch diffutils libintl gzip coreutils mingw-w64-x86_64-python-numpy)
	vcpkg_add_to_path(${MSYS_ROOT}/usr/bin)
	vcpkg_add_to_path(${MSYS_ROOT}/mingw64/bin)
	set(BASH ${MSYS_ROOT}/usr/bin/bash.exe)

	set(ENV{BAZEL_SH} ${MSYS_ROOT}/usr/bin/bash.exe)
	set(ENV{BAZEL_VC} $ENV{VCInstallDir})
	set(ENV{BAZEL_VC_FULL_VERSION} $ENV{VCToolsVersion})

	set(PYTHON3 "${MSYS_ROOT}/mingw64/bin/python3.exe")
	vcpkg_execute_required_process(COMMAND ${PYTHON3} -c "import site; print(site.getsitepackages()[0])" WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR} LOGNAME prerequesits-pypath-${TARGET_TRIPLET} OUTPUT_VARIABLE PYTHON_LIB_PATH)
else()
	vcpkg_find_acquire_program(PYTHON3)
	get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
	vcpkg_add_to_path(PREPEND ${PYTHON3_DIR})

	vcpkg_execute_required_process(COMMAND ${PYTHON3} -m pip install --user -U numpy WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR} LOGNAME prerequesits-pip-${TARGET_TRIPLET})
	vcpkg_execute_required_process(COMMAND ${PYTHON3} -c "import site; print(site.getusersitepackages())" WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR} LOGNAME prerequesits-pypath-${TARGET_TRIPLET} OUTPUT_VARIABLE PYTHON_LIB_PATH)
endif()
set(ENV{PYTHON_BIN_PATH} "${PYTHON3}")
set(ENV{PYTHON_LIB_PATH} "${PYTHON_LIB_PATH}")

# check if numpy can be loaded
vcpkg_execute_required_process(COMMAND ${PYTHON3} -c "import numpy" WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR} LOGNAME prerequesits-numpy-${TARGET_TRIPLET})

# tensorflow has long file names, which will not work on windows
set(ENV{TEST_TMPDIR} ${BUILDTREES_DIR}/.bzl)

set(ENV{USE_DEFAULT_PYTHON_LIB_PATH} 1)
set(ENV{TF_NEED_KAFKA} 0)
set(ENV{TF_NEED_OPENCL_SYCL} 0)
set(ENV{TF_NEED_AWS} 0)
set(ENV{TF_NEED_GCP} 0)
set(ENV{TF_NEED_HDFS} 0)
set(ENV{TF_NEED_S3} 0)
set(ENV{TF_ENABLE_XLA} 0)
set(ENV{TF_NEED_GDR} 0)
set(ENV{TF_NEED_VERBS} 0)
set(ENV{TF_NEED_OPENCL} 0)
set(ENV{TF_NEED_MPI} 0)
set(ENV{TF_NEED_TENSORRT} 0)
set(ENV{TF_NEED_NGRAPH} 0)
set(ENV{TF_NEED_IGNITE} 0)
set(ENV{TF_NEED_ROCM} 0)
set(ENV{TF_SET_ANDROID_WORKSPACE} 0)
set(ENV{TF_DOWNLOAD_CLANG} 0)
set(ENV{TF_NCCL_VERSION} ${TF_VERSION_SHORT})
set(ENV{NCCL_INSTALL_PATH} "")
set(ENV{CC_OPT_FLAGS} "/arch:AVX")
set(ENV{TF_NEED_CUDA} 0)
set(ENV{TF_CONFIGURE_IOS} 0)
# VICTECH: enable GPU
set(ENV{TF_NEED_CUDA} 1)
if (VCPKG_TARGET_IS_WINDOWS)
    set(ENV{CC_OPT_FLAGS} "/arch:AVX")
else()
    set(ENV{CC_OPT_FLAGS} "-march=native -Wno-sign-compare")
endif()
set(ENV{TF_NCCL_VERSION} "")
set(ENV{TF_NEED_TENSORRT} 1) # need tensorrt
set(ENV{TF_TENSORRT_VERSION} 7.1.3) # tensorrt version
set(ENV{TF_CUDA_CLANG} 0)
set(ENV{GCC_HOST_COMPILER_PATH} "/usr/bin/gcc")
set(ENV{TF_CUDA_COMPUTE_CAPABILITIES} "5.3,7.2,7.5") # Jetson Xavier:7.2, RTX 2080 Ti:7.5, GTX 1650:7.5
# VICTECH: (end)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO tensorflow/tensorflow
    REF "v${TF_VERSION}"
    SHA512 e497ef4564f50abf9f918be4522cf702f4cf945cb1ebf83af1386ac4ddc7373b3ba70c7f803f8ca06faf2c6b5396e60b1e0e9b97bfbd667e733b08b6e6d70ef0
    HEAD_REF master
    PATCHES
        file-exists.patch # required or otherwise it cant find python lib path on windows
        fix-build-error.patch # Fix namespace error
        fix-windows-tensorrt.patch
        fix-cuda-configure.patch
)

# borrows from vcpkg/ports/tensorflow-cc/portfile.cmake, but using only release/dynamic
foreach(BUILD_TYPE rel)
    tensorflow_try_remove_recurse_wait(${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${BUILD_TYPE})
    file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${BUILD_TYPE})
    file(GLOB SOURCES ${SOURCE_PATH}/*)
    file(COPY ${SOURCES} DESTINATION ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${BUILD_TYPE})
    
	message(STATUS "Configuring TensorFlow (${BUILD_TYPE})")
	vcpkg_execute_required_process(
		COMMAND ${PYTHON3} ${SOURCE_PATH}/configure.py --workspace "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${BUILD_TYPE}"
		WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${BUILD_TYPE}
		LOGNAME config-${TARGET_TRIPLET}-${BUILD_TYPE}
	)

	message(STATUS "Warning: Building TensorFlow can take an hour or more.")
	set(COPTS)
	set(CXXOPTS)
	set(LINKOPTS)
	if(VCPKG_TARGET_IS_WINDOWS)
		set(PLATFORM_COMMAND WINDOWS_COMMAND)
	else()
		set(PLATFORM_COMMAND UNIX_COMMAND)
    endif()

    if(TRUE) # for release
        set(BUILD_OPTS "--compilation_mode=opt")
        separate_arguments(VCPKG_C_FLAGS ${PLATFORM_COMMAND} ${VCPKG_C_FLAGS})
        separate_arguments(VCPKG_C_FLAGS_RELEASE ${PLATFORM_COMMAND} ${VCPKG_C_FLAGS_RELEASE})
        foreach(OPT IN LISTS VCPKG_C_FLAGS VCPKG_C_FLAGS_RELEASE)
            list(APPEND COPTS "--copt='${OPT}'")
        endforeach()
        separate_arguments(VCPKG_CXX_FLAGS ${PLATFORM_COMMAND} ${VCPKG_CXX_FLAGS})
        separate_arguments(VCPKG_CXX_FLAGS_RELEASE ${PLATFORM_COMMAND} ${VCPKG_CXX_FLAGS_RELEASE})
        foreach(OPT IN LISTS VCPKG_CXX_FLAGS VCPKG_CXX_FLAGS_RELEASE)
            list(APPEND CXXOPTS "--cxxopt='${OPT}'")
        endforeach()
        separate_arguments(VCPKG_LINKER_FLAGS ${PLATFORM_COMMAND} ${VCPKG_LINKER_FLAGS})
        separate_arguments(VCPKG_LINKER_FLAGS_RELEASE ${PLATFORM_COMMAND} ${VCPKG_LINKER_FLAGS_RELEASE})
        foreach(OPT IN LISTS VCPKG_LINKER_FLAGS VCPKG_LINKER_FLAGS_RELEASE)
            list(APPEND LINKOPTS "--linkopt='${OPT}'")
        endforeach()
    endif()

    if(TRUE) # for dynamic library
        if(VCPKG_TARGET_IS_WINDOWS)
            # NOTE : --copt=-DTHRUST_IGNORE_CUB_VERSION_CHECK https://github.com/tensorflow/tensorflow/issues/41803
            list(APPEND COPTS "--copt=-DTHRUST_IGNORE_CUB_VERSION_CHECK")
            list(JOIN COPTS " " COPTS)
            list(JOIN CXXOPTS " " CXXOPTS)
            list(JOIN LINKOPTS " " LINKOPTS)
            vcpkg_execute_build_process(
                COMMAND ${BASH} --noprofile --norc -c "'${BAZEL}' build --verbose_failures ${BUILD_OPTS} ${COPTS} ${CXXOPTS} ${LINKOPTS} --python_path='${PYTHON3}' --define=no_tensorflow_py_deps=true ///tensorflow/tools/lib_package:libtensorflow"
                WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${BUILD_TYPE}
                LOGNAME build-${TARGET_TRIPLET}-${BUILD_TYPE}
            )
        else()
            # NOTE : --config=noaws added explicitly because of compile error in arm64-linux (Jetson Xavier)
            vcpkg_execute_build_process(
                COMMAND ${BAZEL} build --verbose_failures --config=noaws --config=nogcp --config=nonccl ${BUILD_OPTS} --python_path=${PYTHON3} ${COPTS} ${CXXOPTS} ${LINKOPTS} --define=no_tensorflow_py_deps=true //tensorflow/tools/lib_package:libtensorflow
                WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${BUILD_TYPE}
                LOGNAME build-${TARGET_TRIPLET}-${BUILD_TYPE}
            )
        endif()
    endif()
endforeach()

# extract .../bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz
SET(OUT_ARCHIVE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz)
SET(OUT_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/tools/lib_package/libtensorflow)
file(REMOVE_RECURSE ${OUT_DIRECTORY})
file(MAKE_DIRECTORY ${OUT_DIRECTORY})
vcpkg_execute_required_process(
    ALLOW_IN_DOWNLOAD_MODE
    COMMAND ${CMAKE_COMMAND} -E tar xjf ${OUT_ARCHIVE}
    WORKING_DIRECTORY ${OUT_DIRECTORY}
    LOGNAME extract
)

file(COPY ${OUT_DIRECTORY}/include/tensorflow DESTINATION ${CURRENT_PACKAGES_DIR}/include)

if(CMAKE_HOST_WIN32)
    set(TF_DLLS ${OUT_DIRECTORY}/lib/tensorflow.dll ${OUT_DIRECTORY}/lib/tensorflow_framework.dll)
    file(COPY ${TF_DLLS} DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow.dll.ifso DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_framework.dll.ifso DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(RENAME ${CURRENT_PACKAGES_DIR}/lib/libtensorflow.dll.ifso ${CURRENT_PACKAGES_DIR}/lib/tensorflow.lib)
    file(RENAME ${CURRENT_PACKAGES_DIR}/lib/libtensorflow_framework.dll.ifso ${CURRENT_PACKAGES_DIR}/lib/tensorflow_framework.lib)
    file(COPY ${TF_DLLS} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow.dll.ifso DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_framework.dll.ifso DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/libtensorflow.dll.ifso ${CURRENT_PACKAGES_DIR}/debug/lib/tensorflow.lib)
    file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib/libtensorflow_framework.dll.ifso ${CURRENT_PACKAGES_DIR}/debug/lib/tensorflow_framework.lib)
else()
    file(COPY ${OUT_DIRECTORY}/lib/libtensorflow.so DESTINATION ${CURRENT_PACKAGES_DIR}/lib FOLLOW_SYMLINK_CHAIN)
    file(COPY ${OUT_DIRECTORY}/lib/libtensorflow_framework.so DESTINATION ${CURRENT_PACKAGES_DIR}/lib FOLLOW_SYMLINK_CHAIN)
    file(COPY ${OUT_DIRECTORY}/lib/libtensorflow.so DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib FOLLOW_SYMLINK_CHAIN)
    file(COPY ${OUT_DIRECTORY}/lib/libtensorflow_framework.so DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib FOLLOW_SYMLINK_CHAIN)
endif()

file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/tensorflow)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/tensorflow/LICENSE ${CURRENT_PACKAGES_DIR}/share/tensorflow/copyright)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/TensorflowConfig.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/tensorflow)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/tensorflow/TensorflowConfig.cmake ${CURRENT_PACKAGES_DIR}/share/tensorflow/tensorflow-config.cmake)
