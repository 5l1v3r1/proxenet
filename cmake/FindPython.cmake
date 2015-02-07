#
#  PYTHON_EXECUTABLE   = full path to the python binary
#  PYTHON_INCLUDE_PATH = path to where python.h can be found
#  PYTHON_LIBRARY = path to where libpython.so* can be found
#  PYTHON_LFLAGS = python compiler options for linking


if(ENABLE_PYTHON3)
  find_program(PYTHON_EXECUTABLE
    NAMES python3.4 python3.3 python3.2 python3.1 python3.0 python3 python2.7 python2.6 python2.5 python
    PATHS /usr/bin /usr/local/bin /usr/pkg/bin
    )
else()
  find_program(PYTHON_EXECUTABLE
    NAMES python2.7 python2.6 python2.5 python
    PATHS /usr/bin /usr/local/bin /usr/pkg/bin
    )
endif()

if(PYTHON_EXECUTABLE)
  execute_process(
    COMMAND ${PYTHON_EXECUTABLE} -c "import sys; from distutils.sysconfig import *; sys.stdout.write(get_config_var('INCLUDEPY'))"
    OUTPUT_VARIABLE PYTHON_INC_DIR
    )

  execute_process(
    COMMAND ${PYTHON_EXECUTABLE} -c "import sys; from distutils.sysconfig import *; sys.stdout.write(get_config_var('LIBPL'))"
    OUTPUT_VARIABLE PYTHON_POSSIBLE_LIB_PATH
    )

  execute_process(
    COMMAND ${PYTHON_EXECUTABLE} -c "import sys; from distutils.sysconfig import *; sys.stdout.write(get_config_var('LINKFORSHARED'))"
    OUTPUT_VARIABLE PYTHON_LFLAGS
    )

  find_path(PYTHON_INCLUDE_PATH
    NAMES Python.h
    HINTS ${PYTHON_INC_DIR}
    )
  if(ENABLE_PYTHON3)
    find_library(PYTHON_LIBRARY
      NAMES python3.4 python3.3 python3.2 python3.1 python3.0 python3 python2.7 python2.6 python2.5 python
      HINTS ${PYTHON_POSSIBLE_LIB_PATH}
      )
  else()
    find_library(PYTHON_LIBRARY
      NAMES python2.7 python2.6 python2.5 python
      HINTS ${PYTHON_POSSIBLE_LIB_PATH}
      )
  endif()

  if(PYTHON_LIBRARY AND PYTHON_INCLUDE_PATH)
    execute_process(
      COMMAND ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write(sys.version[:3])"
      OUTPUT_VARIABLE PYTHON_VERSION
      )
    execute_process(
      COMMAND ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write(str(sys.version_info < (2,5)))"
      OUTPUT_VARIABLE PYTHON_OLD_VERSION
      )
    if(${PYTHON_OLD_VERSION} STREQUAL "True")
      message("Python >= 2.5 is needed to build python plugin, version found: ${PYTHON_VERSION}")
    else()
      execute_process(
        COMMAND ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write(str(sys.version_info[0]))"
        OUTPUT_VARIABLE _PYTHON_MAJOR_
        )

      execute_process(
        COMMAND ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write(str(sys.version_info[1]))"
        OUTPUT_VARIABLE _PYTHON_MINOR_
        )

      set(PYTHON_FOUND TRUE)
    endif()
  endif()

  mark_as_advanced(
    PYTHON_EXECUTABLE
    PYTHON_INCLUDE_PATH
    PYTHON_LIBRARY
    PYTHON_LFLAGS

    _PYTHON_MAJOR _PYTHON_MINOR
    )

endif()
