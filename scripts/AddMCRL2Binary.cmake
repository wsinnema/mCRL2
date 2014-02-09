if(WINDOWS)
  set(MCRL2_RUNTIME_PATH ${CMAKE_INSTALL_PREFIX})
  set(MCRL2_LIBRARY_PATH ${CMAKE_INSTALL_PREFIX})
  set(MCRL2_ARCHIVE_PATH ${CMAKE_INSTALL_PREFIX}/lib)
  set(MCRL2_INCLUDE_PATH ${CMAKE_INSTALL_PREFIX}/include)
elseif(APPLE)
  set(MCRL2_RUNTIME_PATH ${CMAKE_INSTALL_PREFIX}/bin/mcrl2-gui.app/Content/MacOS)
  set(MCRL2_LIBRARY_PATH ${CMAKE_INSTALL_PREFIX}/lib)
  set(MCRL2_ARCHIVE_PATH ${CMAKE_INSTALL_PREFIX}/lib)
  set(MCRL2_INCLUDE_PATH ${CMAKE_INSTALL_PREFIX}/include)
  set(MCRL2_BUNDLE_PATH ${CMAKE_INSTALL_PREFIX}/bin)

  set(CMAKE_MACOSX_RPATH ON)
  set(CMAKE_INSTALL_RPATH "@loader_path/../Frameworks")
  set(CMAKE_SKIP_BUILD_RPATH FALSE)
  set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
  set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)
else() # Assume *NIX
  set(MCRL2_RUNTIME_PATH ${CMAKE_INSTALL_PREFIX}/bin)
  set(MCRL2_LIBRARY_PATH ${CMAKE_INSTALL_PREFIX}/lib)
  set(MCRL2_ARCHIVE_PATH ${CMAKE_INSTALL_PREFIX}/share/mcrl2/lib)
  set(MCRL2_INCLUDE_PATH ${CMAKE_INSTALL_PREFIX}/include)
endif()

macro(add_icon_resource TARGET_NAME ICON SOURCE_FILES)
  if(MSVC)
    set(RC_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}_icon.rc)
    set(ICOFILE ${CMAKE_SOURCE_DIR}/build/packaging/icons/${ICON}.ico ABSOLUTE)
    configure_file(${CMAKE_SOURCE_DIR}/build/packaging/icon.rc.in ${RC_FILE} @ONLY NEWLINE_STYLE WIN32)
    set(${SOURCE_FILES} ${${SOURCE_FILES}} ${RC_FILE} PARENT_SCOPE)
  endif()
  if(APPLE)
    set(ICNS_FILE ${CMAKE_SOURCE_DIR}/build/packaging/icons/${ICON}.icns)
    #message(STATUS "Setting bundle icon to ${ICNS_FILE}")
    set_source_files_properties(${ICNS_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set(${SOURCE_FILES} ${${SOURCE_FILES}} ${ICNS_FILE})
  endif()
endmacro()

macro(add_desktop_file TARGET_NAME TOOLNAME DESCRIPTION ICON)
  if(UNIX AND NOT APPLE)
    set(DESKTOP_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.desktop)
    set(COMMANDLINE ${TARGET_NAME})
    configure_file(${CMAKE_SOURCE_DIR}/build/packaging/desktop.in ${DESKTOP_FILE} @ONLY)
    install(FILES ${DESKTOP_FILE} DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications)
  elseif(APPLE)
    set_target_properties(${TARGET_NAME} PROPERTIES
      MACOSX_BUNDLE_BUNDLE_NAME ${TOOLNAME}
      MACOSX_BUNDLE_ICON_FILE ${ICON}.icns)
  endif()
endmacro()

function(add_mcrl2_binary TARGET_NAME TARGET_TYPE)
  set(KW_LIST "SOURCEDIR" "INCLUDEDIR" "COMPONENT" "DESCRIPTION" "MENUNAME" "ICON" "SOURCES" "DEPENDS" "INCLUDE" "INSTALL_HEADERS")
  set(LIST_KW "SOURCES" "DEPENDS" "INCLUDE")
  set(FILEVAR "SOURCES")
  foreach(ARG ${ARGN})
    list(FIND KW_LIST ${ARG} IS_KW)
    if(IS_KW GREATER -1)
      set(FILEVAR ${ARG})
    else()
      list(FIND LIST_KW ${FILEVAR} IS_LIST)
      if(IS_LIST GREATER -1)
        set(${FILEVAR} ${${FILEVAR}} ${ARG})
      else()
        set(${FILEVAR} ${ARG})
      endif()
    endif()
  endforeach()

  if(INSTALL_COMPONENT)
    string(TOLOWER ${INSTALL_COMPONENT} ${INSTALL_COMPONENT_LC})
    if((${INSTALL_COMPONENT_LC} STREQUAL "experimental" AND NOT MCRL2_ENABLE_EXPERIMENTAL) OR
       (${INSTALL_COMPONENT_LC} STREQUAL "deprecated" AND NOT MCRL2_ENABLE_DEPRECATED) OR
       (${INSTALL_COMPONENT_LC} STREQUAL "developer"))
      unset(INSTALL_COMPONENT)
    endif()
  else()
    set(INSTALL_COMPONENT ${CMAKE_INSTALL_DEFAULT_COMPONENT_NAME})
  endif()

  if(INCLUDEDIR)
    file(GLOB_RECURSE TARGET_INCLUDE_FILES ${INCLUDEDIR}/*.h)
    if(TARGET_INCLUDE_FILES)
      add_custom_target(${TARGET_NAME}_headers SOURCES ${TARGET_INCLUDE_FILES})
      set(INCLUDE ${INCLUDEDIR} ${INCLUDE})
    endif()
  endif()

  if(NOT SOURCEDIR)
    set(SOURCEDIR ".")
  endif()

  set(DEPENDS_UNFILTERED ${DEPENDS} "SENTINEL")
  unset(DEPENDS)
  unset(IS_GUI_BINARY)
  foreach(DEP ${DEPENDS_UNFILTERED})
    if(${DEP} STREQUAL "HEADER_ONLY")
      set(HEADER_DEPENDS ${HEADER_DEPENDS} ${LASTDEP}_headers)
      unset(LASTDEP)
    else()
      if(LASTDEP)
        set(DEPENDS ${DEPENDS} ${LASTDEP})
      endif()
      set(LASTDEP ${DEP})
      string(REGEX REPLACE "Qt(.*)" "\\1" QT_LIB ${DEP})
      if(NOT ${QT_LIB} STREQUAL ${DEP})
        set(QT_LIBS ${QT_LIBS} ${QT_LIB})
        unset(LASTDEP)
        if(${QT_LIB} STREQUAL "Widgets")
          set(IS_GUI_BINARY TRUE)
        endif()
      else()
        string(REGEX REPLACE "^mcrl2_(.*)" "\\1" MCRL2_LIB ${DEP})
        if(NOT ${MCRL2_LIB} STREQUAL ${DEP})
          set(INCLUDE ${INCLUDE} ${CMAKE_SOURCE_DIR}/libraries/${MCRL2_LIB}/include)
        endif()
      endif()
    endif()
  endforeach()

  set(SOURCES_UNFILTERED ${SOURCES})
  unset(SOURCES)
  foreach(SRC ${SOURCES_UNFILTERED})
    get_filename_component(SRC_ABS ${SRC} ABSOLUTE)
    if(NOT ${SRC_ABS} STREQUAL ${SRC})
      get_filename_component(SRC_ABS ${SOURCEDIR}/${SRC} ABSOLUTE)
    endif()
    get_filename_component(SRC_EXT ${SRC_ABS} EXT)
    if("${SRC_EXT}" STREQUAL ".g")
      # This is a grammar file. Generate a .c file using DParser
      get_filename_component(SRC_BASE ${SRC_ABS} NAME_WE)
      file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/source)
      set(PARSER_CODE ${CMAKE_CURRENT_BINARY_DIR}/source/${SRC_BASE}.c)
      string(REGEX REPLACE "(.*)_syntax" "\\1" GRAMMAR_IDENT ${SRC_BASE})
      add_custom_command(
          OUTPUT ${PARSER_CODE}
          COMMAND make_dparser -A -H0 -i${GRAMMAR_IDENT} -o${PARSER_CODE} ${SRC_ABS}
          DEPENDS make_dparser ${SRC_ABS}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          COMMENT "Generating ${GRAMMAR_IDENT} parser"
        )
      add_custom_target(${LIBNAME}_${SRC_BASE} SOURCES ${SRC_ABS})
      set(SRC_ABS ${PARSER_CODE})
      set(DEPENDS ${DEPENDS} dparser)
      set(INCLUDE ${INCLUDE} ${CMAKE_SOURCE_DIR}/3rd-party/dparser)
    elseif("${SRC_EXT}" STREQUAL ".ui")
      qt5_wrap_ui(SRC_ABS ${SRC_ABS})
    elseif("${SRC_EXT}" STREQUAL ".qrc")
      qt5_add_resources(SRC_ABS ${SRC_ABS})
    endif()
    set(SOURCES ${SRC_ABS} ${SOURCES})
  endforeach()

  if(ICON)
    add_icon_resource(${TARGET_NAME} ${ICON} SOURCES)
  endif()

  if((NOT IS_GUI_BINARY OR MCRL2_ENABLE_GUI_TOOLS) AND INSTALL_COMPONENT)

  if(SOURCES)
    include_directories(${INCLUDE})
    if(QT_LIBS AND TARGET_INCLUDE_FILES)
      # If we are using Qt, include the header files as sources, so automoc can find them.
      set(SOURCES ${SOURCES} ${TARGET_INCLUDE_FILES})
    endif()
    if(${TARGET_TYPE} STREQUAL "LIBRARY")
      add_library(${TARGET_NAME} ${SOURCES})
      set_target_properties(${TARGET_NAME} PROPERTIES FRAMEWORK TRUE)
      install(TARGETS ${TARGET_NAME}
              LIBRARY DESTINATION ${MCRL2_LIBRARY_PATH}
              ARCHIVE DESTINATION ${MCRL2_ARCHIVE_PATH}
              FRAMEWORK DESTINATION ${MCRL2_LIBRARY_PATH}
              COMPONENT ${INSTALL_COMPONENT})
      if(INSTALL_HEADERS)
        if(APPLE)
          foreach(HEADER ${TARGET_INCLUDE_FILES})
            get_filename_component(HEADER_ABS "${HEADER}" ABSOLUTE)
            file(RELATIVE_PATH RELPATH "${CMAKE_CURRENT_SOURCE_DIR}" "${HEADER_ABS}")
            set_source_files_properties(${HEADER} PROPERTIES MACOSX_PACKAGE_LOCATION Headers/${RELPATH})
          endforeach()
        else()
          install(DIRECTORY ${INCLUDEDIR}/mcrl2 DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
        endif()
      endif()
    elseif(${TARGET_TYPE} STREQUAL "EXECUTABLE")
      add_executable(${TARGET_NAME} ${SOURCES})
      set(INSTALL_PATH ${MCRL2_RUNTIME_PATH})
      if(IS_GUI_BINARY)
        set_target_properties(${TARGET_NAME} PROPERTIES MACOSX_BUNDLE TRUE)
      endif()
      install(TARGETS ${TARGET_NAME}
              RUNTIME DESTINATION ${MCRL2_RUNTIME_PATH}
              BUNDLE DESTINATION ${MCRL2_BUNDLE_PATH}
              COMPONENT ${INSTALL_COMPONENT})
    endif()
    if(DEPENDS)
      target_link_libraries(${TARGET_NAME} ${DEPENDS})
    endif()
    if(HEADER_DEPENDS)
      add_dependencies(${TARGET_NAME} ${HEADER_DEPENDS})
    endif()
    if(QT_LIBS)
      qt5_use_modules(${TARGET_NAME} ${QT_LIBS})
      set_target_properties(${TARGET_NAME} PROPERTIES AUTOMOC TRUE)
    endif()
  endif()

  if(MENUNAME)
    add_desktop_file(${TARGET_NAME} "${MENUNAME}" "${DESCRIPTION}" "${ICON}")
  endif()

  if(TARGET_INCLUDE_FILES)
    if(DEPENDS)
      add_dependencies(${TARGET_NAME}_headers ${DEPENDS})
    endif()
    if(HEADER_DEPENDS)
      add_dependencies(${TARGET_NAME}_headers ${HEADER_DEPENDS})
    endif()
  endif()

  endif()
endfunction()

function(add_mcrl2_library LIBNAME)
  add_mcrl2_binary(mcrl2_${LIBNAME} LIBRARY
    SOURCEDIR "source"
    INCLUDEDIR "include"
    ${ARGN}
    COMPONENT "Libraries")
endfunction()

function(add_mcrl2_tool TOOLNAME)
  add_mcrl2_binary(${TOOLNAME} EXECUTABLE
    SOURCEDIR "."
    INCLUDEDIR "."
    ${ARGN})
endfunction()
