set(tensorflow_cc_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/../../include")

message(WARNING "Tensorflow has vendored dependencies. You may need to manually include files from tensorflow-external")
set(tensorflow_cc_INCLUDE_DIRS
	${tensorflow_cc_INCLUDE_DIR}
	${tensorflow_cc_INCLUDE_DIR}/tensorflow-external/
	${tensorflow_cc_INCLUDE_DIR}/tensorflow-external/tensorflow/
)

if(CMAKE_HOST_WIN32)
	add_library(tensorflow_cc::tensorflow_cc SHARED IMPORTED)
	set_target_properties(tensorflow_cc::tensorflow_cc
		PROPERTIES 
		IMPORTED_IMPLIB_RELEASE ${CMAKE_CURRENT_LIST_DIR}/../../lib/liblibtensorflow_cc.so.2.2.0.ifso
		IMPORTED_LOCATION_RELEASE ${CMAKE_CURRENT_LIST_DIR}/../../lib/libtensorflow_cc.so.2.2.0
		INTERFACE_INCLUDE_DIRECTORIES "${tensorflow_cc_INCLUDE_DIRS}"
	)

	set(tensorflow_cc_FOUND TRUE)
else()
	add_library(tensorflow_cc::tensorflow_framework SHARED IMPORTED)
	set_target_properties(tensorflow_cc::tensorflow_framework 
		PROPERTIES
		IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/../../lib/libtensorflow_framework.so.2.2.0
		INTERFACE_INCLUDE_DIRECTORIES "${tensorflow_cc_INCLUDE_DIRS}"
	)
	
	add_library(tensorflow_cc::tensorflow_cc SHARED IMPORTED)
	set_target_properties(tensorflow_cc::tensorflow_cc
		PROPERTIES 
		IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/../../lib/libtensorflow_cc.so.2.2.0
		INTERFACE_INCLUDE_DIRECTORIES "${tensorflow_cc_INCLUDE_DIRS}"
	)

	set(tensorflow_cc_FOUND TRUE)
	set(tensorflow_framework_FOUND TRUE)
endif()

get_filename_component( TENSORFLOW_CC_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/../../lib/libtensorflow_cc.so.2.2.0 ABSOLUTE )
