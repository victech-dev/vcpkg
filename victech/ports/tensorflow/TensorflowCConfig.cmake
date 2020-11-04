set(tensorflow_c_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/../../include")

if(CMAKE_HOST_WIN32)
	add_library( tensorflow_c::tensorflow_c SHARED IMPORTED )
	set_target_properties( tensorflow_c::tensorflow_c PROPERTIES
		IMPORTED_LOCATION                 ${CMAKE_CURRENT_LIST_DIR}/../../lib/tensorflow.dll
		IMPORTED_IMPLIB                   ${CMAKE_CURRENT_LIST_DIR}/../../lib/tensorflow.lib
		INTERFACE_INCLUDE_DIRECTORIES     "${tensorflow_c_INCLUDE_DIRS}"
		IMPORTED_LINK_INTERFACE_LANGUAGES "C" )
	add_library( tensorflow_c::tensorflow_framework SHARED IMPORTED )
	set_target_properties( tensorflow_c::tensorflow_framework PROPERTIES
		IMPORTED_LOCATION                 ${CMAKE_CURRENT_LIST_DIR}/../../lib/tensorflow_framework.dll
		IMPORTED_IMPLIB                   ${CMAKE_CURRENT_LIST_DIR}/../../lib/tensorflow_framework.lib
		INTERFACE_INCLUDE_DIRECTORIES     "${tensorflow_c_INCLUDE_DIRS}"
		IMPORTED_LINK_INTERFACE_LANGUAGES "C" )
	
	set(tensorflow_c_FOUND TRUE)
	set(tensorflow_framework_FOUND TRUE)
else()
	add_library(tensorflow_c::tensorflow_framework SHARED IMPORTED)
	set_target_properties(tensorflow_c::tensorflow_framework 
		PROPERTIES
		IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/../../lib/libtensorflow_framework.so.2.3.1
		INTERFACE_INCLUDE_DIRECTORIES "${tensorflow_c_INCLUDE_DIRS}"
	)
	
	add_library(tensorflow_c::tensorflow_c SHARED IMPORTED)
	set_target_properties(tensorflow_c::tensorflow_c
		PROPERTIES 
		IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/../../lib/libtensorflow.so.2.3.1
		INTERFACE_INCLUDE_DIRECTORIES "${tensorflow_c_INCLUDE_DIRS}"
	)

	set(tensorflow_c_FOUND TRUE)
	set(tensorflow_framework_FOUND TRUE)
endif()

