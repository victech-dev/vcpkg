set(TensorFlow_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/../../include")

if(CMAKE_HOST_WIN32)
	add_library( Tensorflow::Tensorflow_Framework SHARED IMPORTED )
	set_target_properties( Tensorflow::Tensorflow_Framework PROPERTIES
		IMPORTED_LOCATION                 ${CMAKE_CURRENT_LIST_DIR}/../../lib/tensorflow_framework.dll
		IMPORTED_IMPLIB                   ${CMAKE_CURRENT_LIST_DIR}/../../lib/tensorflow_framework.lib
		INTERFACE_INCLUDE_DIRECTORIES     "${TensorFlow_INCLUDE_DIRS}"
		IMPORTED_LINK_INTERFACE_LANGUAGES "C" )

	add_library( Tensorflow::Tensorflow SHARED IMPORTED )
	set_target_properties( Tensorflow::Tensorflow PROPERTIES
		IMPORTED_LOCATION                 ${CMAKE_CURRENT_LIST_DIR}/../../lib/tensorflow.dll
		IMPORTED_IMPLIB                   ${CMAKE_CURRENT_LIST_DIR}/../../lib/tensorflow.lib
		INTERFACE_INCLUDE_DIRECTORIES     "${TensorFlow_INCLUDE_DIRS}"
		IMPORTED_LINK_INTERFACE_LANGUAGES "C" )
	
	set(TensorFlow_FOUND TRUE)
	set(TensorFlow_Framework_FOUND TRUE)
else()
	add_library(Tensorflow::Tensorflow_Framework SHARED IMPORTED)
	set_target_properties(Tensorflow::Tensorflow_Framework 
		PROPERTIES
		IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/../../lib/libtensorflow_framework.so.2.3.1
		INTERFACE_INCLUDE_DIRECTORIES "${TensorFlow_INCLUDE_DIRS}"
	)
	
	add_library(Tensorflow::Tensorflow SHARED IMPORTED)
	set_target_properties(Tensorflow::Tensorflow
		PROPERTIES 
		IMPORTED_LOCATION ${CMAKE_CURRENT_LIST_DIR}/../../lib/libtensorflow.so.2.3.1
		INTERFACE_INCLUDE_DIRECTORIES "${TensorFlow_INCLUDE_DIRS}"
	)

	set(TensorFlow_FOUND TRUE)
	set(TensorFlow_Framework_FOUND TRUE)
endif()

