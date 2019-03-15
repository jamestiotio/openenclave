# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# This script requires the variables SOURCE_DIR, BUILD_DIR, and
# PREFIX_DIR to be defined:
#
#     cmake -DSOURCE_DIR=~/openenclave -DBUILD_DIR=~/openenclave/build -DPREFIX_DIR=/opt/openenclave -P ~/openenclave/samples/test-samples.cmake

# The samples cannot run in simulation mode.
if ($ENV{OE_SIMULATION})
  message(WARNING "Samples tests skipped due to OE_SIMULATION=$ENV{OE_SIMULATION}!")
  # This is not a failure condition, so we return with a success status.
  return()
endif ()

# Install the SDK from current build to a known location in the build tree.
execute_process(COMMAND ${CMAKE_COMMAND} -E env DESTDIR=${BUILD_DIR}/install ${CMAKE_COMMAND} --build ${BUILD_DIR} --target install)

# The prefix is appended to the value given to DESTDIR, e.g. build/install/opt/openenclave/...
set(INSTALL_DIR ${BUILD_DIR}/install${PREFIX_DIR})

# TODO: Add the rest of the samples.
foreach (SAMPLE data-sealing)
  set(SAMPLE_BUILD_DIR ${BUILD_DIR}/samples/${SAMPLE})
  set(SAMPLE_SOURCE_DIR ${INSTALL_DIR}/share/openenclave/samples/${SAMPLE})

  # Delete and re-create a clean build directory for the sample, used
  # as the working directory in the next steps.
  execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${SAMPLE_BUILD_DIR})
  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${SAMPLE_BUILD_DIR})

  # Configure, build, and run the installed sample with CMake.
  execute_process(
    COMMAND ${CMAKE_COMMAND} -DCMAKE_PREFIX_PATH=${INSTALL_DIR} ${SAMPLE_SOURCE_DIR}
    WORKING_DIRECTORY ${SAMPLE_BUILD_DIR})

  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${SOURCE_DIR}/${SAMPLE}
    WORKING_DIRECTORY ${SAMPLE_BUILD_DIR})

  execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${SAMPLE_BUILD_DIR} --target run
    RESULT_VARIABLE TEST_RESULT)

  # The prior common cannot succeed unless all commands before also
  # succeeded, so testing only the result of this is sufficient.
  #
  # TODO: An unfortunate side-effect of this placement is that a
  # failed sample will cause the rest of the samples to be skipped.
  if (TEST_RESULT)
    message(FATAL_ERROR "Samples test '${SAMPLE}' failed!")
  endif ()

  # TODO: Build the sample with GNU Make.
endforeach ()