# Authors: Jeroen Keiren
# Copyright: see the accompanying file COPYING or copy at
# https://github.com/mCRL2org/mCRL2/blob/master/COPYING
#
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
# http://www.boost.org/LICENSE_1_0.txt)

# This script generates toolset documentation

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/source/user_manual/downloads-nightly.inc.template"
               "${CMAKE_CURRENT_BINARY_DIR}/_temp/source/user_manual/downloads-nightly.inc" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/source/user_manual/downloads-release.inc.template"
               "${CMAKE_CURRENT_BINARY_DIR}/_temp/source/user_manual/downloads-release.inc" @ONLY)

if(CMAKE_RUNTIME_OUTPUT_DIRECTORY)
  set(BIN_PATH ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
else()
  set(BIN_PATH ${CMAKE_BINARY_DIR})
endif()

set(MCRL2_GENERATE_DOC_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/generate.py)
set(MCRL2_GENERATE_DOC_COMMAND ${MCRL2_GENERATE_DOC_SCRIPT} --version ${MCRL2_VERSION} --path=${BIN_PATH}
  --temp=${CMAKE_CURRENT_BINARY_DIR}/_temp --out=${CMAKE_CURRENT_BINARY_DIR}/html)

if(MCRL2_PACKAGE_RELEASE)
  set(MCRL2_GENERATE_DOC_COMMAND ${MCRL2_GENERATE_DOC_COMMAND} -r)
endif()

add_custom_target(doc
  COMMAND ${MCRL2_GENERATE_DOC_COMMAND} -ddc
  COMMENT "(Re)-generating mCRL2 documentation (regenerates all cached documentation)" VERBATIM
)

add_custom_target(fastdoc 
  COMMAND ${MCRL2_GENERATE_DOC_COMMAND} -dd
  COMMENT "Generating mCRL2 documentation (does not regenerate cached PDF, manual pages and Doxygen documentation)" VERBATIM
)
