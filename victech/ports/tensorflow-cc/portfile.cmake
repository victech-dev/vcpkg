include(vcpkg_common_functions)

message(WARNING "This tensorflow port currently is experimental on Windows and Linux platforms.")

if (VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
    message(FATAL_ERROR "TensorFlow does not support 32bit system.")
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO tensorflow/tensorflow
    REF v2.3.1
    SHA512 e497ef4564f50abf9f918be4522cf702f4cf945cb1ebf83af1386ac4ddc7373b3ba70c7f803f8ca06faf2c6b5396e60b1e0e9b97bfbd667e733b08b6e6d70ef0
    HEAD_REF master
    PATCHES
        file-exists.patch # required or otherwise it cant find python lib path on windows
        fix-build-error.patch # Fix namespace error
        add_io_bazel_rules_docker.patch
        add_custom_export_symbols.patch
        fix-windows-tensorrt.patch
)

vcpkg_find_acquire_program(BAZEL3_2_0)
set(BAZEL ${BAZEL3_2_0})
get_filename_component(BAZEL_DIR "${BAZEL}" DIRECTORY)
vcpkg_add_to_path(PREPEND ${BAZEL_DIR})
set(ENV{BAZEL_BIN_PATH} "${BAZEL}")

# TODO Tensorflow2.0 cannot built with python-embed 
#vcpkg_find_acquire_program(PYTHON3)
if(CMAKE_HOST_WIN32)
    set(PYTHON3 "$ENV{LOCALAPPDATA}/Programs/Python/Python37/python.exe")
else()
    set(PYTHON3 "/usr/bin/python3")
endif()
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path(PREPEND ${PYTHON3_DIR})
set(ENV{PYTHON_BIN_PATH} "${PYTHON3}")

function(tensorflow_try_remove_recurse_wait PATH_TO_REMOVE)
    file(REMOVE_RECURSE ${PATH_TO_REMOVE})
    if (EXISTS "${PATH_TO_REMOVE}")
        execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 5)
        file(REMOVE_RECURSE ${PATH_TO_REMOVE})
    endif()
endfunction()

# we currently only support the release version
tensorflow_try_remove_recurse_wait(${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
file(GLOB SOURCES ${SOURCE_PATH}/*)
file(COPY ${SOURCES} DESTINATION ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)

if(CMAKE_HOST_WIN32)
    vcpkg_acquire_msys(MSYS_ROOT PACKAGES unzip patch diffutils git)
    set(BASH ${MSYS_ROOT}/usr/bin/bash.exe)
    set(ENV{BAZEL_SH} ${MSYS_ROOT}/usr/bin/bash.exe)
    vcpkg_add_to_path(PREPEND ${MSYS_ROOT}/usr/bin)

    set(ENV{BAZEL_VS} $ENV{VSInstallDir})
    set(ENV{BAZEL_VC} $ENV{VCInstallDir})
    #set(ENV{BAZEL_VS} "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\")
    #set(ENV{BAZEL_VC} "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC")
    message (BAZEL_VS=$ENV{BAZEL_VS})
    message (BAZEL_VC=$ENV{BAZEL_VC})
endif()

# tensorflow has long file names, which will not work on windows
set(ENV{TEST_TMPDIR} ${CURRENT_BUILDTREES_DIR}/../.bzl)

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
set(ENV{TF_NEED_NGRAPH} 0)
set(ENV{TF_NEED_IGNITE} 0)
set(ENV{TF_NEED_ROCM} 0)
set(ENV{TF_SET_ANDROID_WORKSPACE} 0)
set(ENV{TF_DOWNLOAD_CLANG} 0)
set(ENV{NCCL_INSTALL_PATH} "")
if (VCPKG_TARGET_IS_WINDOWS)
    set(ENV{CC_OPT_FLAGS} "/arch:AVX")
else()
    set(ENV{CC_OPT_FLAGS} "-march=native -Wno-sign-compare")
endif()
set(ENV{TF_NEED_CUDA} 1)
set(ENV{TF_CONFIGURE_IOS} 0)
set(ENV{TF_NCCL_VERSION} "")
set(ENV{TF_NEED_TENSORRT} 1) # need tensorrt
set(ENV{TF_TENSORRT_VERSION} 7.1.3) # tensorrt version
if (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64") # assum Jetson Xavier with JetPack 4.4
    set(ENV{TF_CUDA_VERSION} 10.2)
    set(ENV{TF_CUDNN_VERSION} 8.0.0)
    set(ENV{TF_CUDA_PATHS} "/usr/local/cuda,/usr")
endif()
set(ENV{TF_CUDA_CLANG} 0)
set(ENV{GCC_HOST_COMPILER_PATH} "/usr/bin/gcc")
set(ENV{TF_CUDA_COMPUTE_CAPABILITIES} "5.3,7.2,7.5") # Jetson Xavier:7.2, RTX 2080 Ti:7.5, GTX 1650:7.5

message(STATUS "Configuring TensorFlow")

vcpkg_execute_required_process(
    COMMAND ${PYTHON3} ${SOURCE_PATH}/configure.py --workspace "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel"
    WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
    LOGNAME config-${TARGET_TRIPLET}-rel
)
message(STATUS "Warning: Building TensorFlow can take an hour or more.")

if(CMAKE_HOST_WIN32)
    # NOTE : noaws, nogcp, nonccl not required here, since these are opt-out by default and bazel spits out error
    # NOTE : --copt=-DTHRUST_IGNORE_CUB_VERSION_CHECK https://github.com/tensorflow/tensorflow/issues/41803
    vcpkg_execute_build_process(
        COMMAND ${BASH} --noprofile --norc -c "${BAZEL} build \
            --verbose_failures \
            -c opt --config=opt --define=no_tensorflow_py_deps=true --copt=-DTHRUST_IGNORE_CUB_VERSION_CHECK --define=override_eigen_strong_inline=true \
            ///tensorflow:libtensorflow_cc.so ///tensorflow:install_headers"
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
        LOGNAME build-${TARGET_TRIPLET}-rel
    )
else()
    # NOTE : --config=noaws added explicitly because of compile error in arm64-linux (Jetson Xavier)
    vcpkg_execute_build_process(
        COMMAND ${BAZEL} build 
            --verbose_failures --config=noaws --config=nogcp --config=nonccl
            -c opt --config=opt --define=no_tensorflow_py_deps=true
            //tensorflow:libtensorflow_cc.so //tensorflow:install_headers
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
        LOGNAME build-${TARGET_TRIPLET}-rel
    )
endif()

file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/include/ DESTINATION ${CURRENT_PACKAGES_DIR}/include/tensorflow-external)

if(CMAKE_HOST_WIN32)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_cc.so.2.3.1 DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_cc.so.2 DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/liblibtensorflow_cc.so.2.3.1.ifso DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_cc.so.2.3.1 DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_cc.so.2 DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/liblibtensorflow_cc.so.2.3.1.ifso DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
else()
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_cc.so.2.3.1 DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_framework.so.2.3.1 DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_cc.so.2 DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_framework.so.2 DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_cc.so.2.3.1 DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_framework.so.2.3.1 DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_cc.so.2 DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
    file(COPY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/bazel-bin/tensorflow/libtensorflow_framework.so.2 DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
endif()

file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/tensorflow-cc)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/tensorflow-cc/LICENSE ${CURRENT_PACKAGES_DIR}/share/tensorflow-cc/copyright)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/TensorflowCCConfig.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/unofficial-tensorflow-cc)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/unofficial-tensorflow-cc/TensorflowCCConfig.cmake ${CURRENT_PACKAGES_DIR}/share/unofficial-tensorflow-cc/unofficial-tensorflow-cc-config.cmake)
