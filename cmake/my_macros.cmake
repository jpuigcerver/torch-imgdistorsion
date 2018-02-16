OPTION(BUILD_STATIC_LIBS "Build static libraries" OFF)
OPTION(BUILD_SHARED_LIBS "Build shared libraries" ON)

MACRO(CREATE_CONDITIONAL_LIST output_var)
  SET(${output_var})
  SET(_cond_var)
  SET(_cond_found FALSE)
  FOREACH(_arg ${ARGN})
    IF("x${_arg}x" STREQUAL "xCONDx")
      SET(_cond_found TRUE)
      SET(_cond_var)
      CONTINUE()
    ENDIF()
    IF(_cond_found)
      IF(NOT _cond_var)
	SET(_cond_var "${_arg}")
	CONTINUE()
      ELSEIF(${_cond_var})
	LIST(APPEND ${output_var} "${_arg}")
      ENDIF()
    ELSE()
      LIST(APPEND ${output_var} "${_arg}")
    ENDIF()
  ENDFOREACH()
ENDMACRO(CREATE_CONDITIONAL_LIST)

MACRO(SPLIT_ARGS_SRCS_AND_LIBS var_srcs var_libs)
  SET(_libs_found FALSE)
  SET(_srcs)
  SET(_libs)

  FOREACH(_arg ${ARGN})
    IF("x${_arg}x" STREQUAL "xLIBRARIESx")
      SET(_libs_found TRUE)
      CONTINUE()
    ENDIF()
    IF (_libs_found)
      LIST(APPEND _libs "${_arg}")
    ELSE()
      LIST(APPEND _srcs "${_arg}")
    ENDIF()
  ENDFOREACH()

  CREATE_CONDITIONAL_LIST(${var_srcs} "${_srcs}")
  CREATE_CONDITIONAL_LIST(${var_libs} "${_libs}")
ENDMACRO(SPLIT_ARGS_SRCS_AND_LIBS)

MACRO(MY_ADD_LIBRARY name)
  SPLIT_ARGS_SRCS_AND_LIBS(_srcs _libs ${ARGN})

  IF(BUILD_STATIC_LIBS OR BUILD_SHARED_LIBS)
    ADD_LIBRARY(${name}_obj OBJECT "${_srcs}")
  ENDIF(BUILD_STATIC_LIBS OR BUILD_SHARED_LIBS)

  IF(BUILD_STATIC_LIBS)
    ADD_LIBRARY(${name}_static STATIC $<TARGET_OBJECTS:${name}_obj>)
    SET_TARGET_PROPERTIES(${name}_static PROPERTIES OUTPUT_NAME imgdistort_${name})
    TARGET_LINK_LIBRARIES(${name}_static "${_libs}")
  ENDIF(BUILD_STATIC_LIBS)

  IF(BUILD_SHARED_LIBS)
    ADD_LIBRARY(${name} SHARED $<TARGET_OBJECTS:${name}_obj>)
    SET_TARGET_PROPERTIES(${name} PROPERTIES OUTPUT_NAME imgdistort_${name})
    TARGET_LINK_LIBRARIES(${name} "${_libs}")
  ENDIF(BUILD_SHARED_LIBS)
ENDMACRO(MY_ADD_LIBRARY)

MACRO(MY_CUDA_ADD_LIBRARY name)
  SPLIT_ARGS_SRCS_AND_LIBS(_srcs _libs ${ARGN})

  IF(BUILD_STATIC_LIBS OR BUILD_SHARED_LIBS)
    CUDA_COMPILE(objs_ "${_srcs}")
  ENDIF(BUILD_STATIC_LIBS OR BUILD_SHARED_LIBS)

  IF(BUILD_STATIC_LIBS)
    CUDA_ADD_LIBRARY(${name}_static STATIC ${objs_})
    SET_TARGET_PROPERTIES(${name}_static PROPERTIES OUTPUT_NAME imgdistort_${name})
    TARGET_LINK_LIBRARIES(${name}_static "${_libs}")
  ENDIF(BUILD_STATIC_LIBS)

  IF(BUILD_SHARED_LIBS)
    CUDA_ADD_LIBRARY(${name} SHARED ${objs_})
    SET_TARGET_PROPERTIES(${name} PROPERTIES OUTPUT_NAME imgdistort_${name})
    TARGET_LINK_LIBRARIES(${name} "${_libs}")
  ENDIF(BUILD_SHARED_LIBS)
ENDMACRO(MY_CUDA_ADD_LIBRARY)

FIND_PROGRAM(IWYU_PATH NAMES include-what-you-use iwyu)
MACRO(ADD_IWYU_TO_TARGET)
  IF(WITH_IWYU AND IWYU_PATH AND CMAKE_VERSION VERSION_GREATER "3.2")
    FOREACH(_a ${ARGN})
      SET_PROPERTY(TARGET ${_a} PROPERTY CXX_INCLUDE_WHAT_YOU_USE ${IWYU_PATH})
    ENDFOREACH()
  ENDIF()
ENDMACRO(ADD_IWYU_TO_TARGET)