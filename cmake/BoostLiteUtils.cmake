if(BoostLiteUtilsIncluded)
  return()
endif()
set(BoostLiteUtilsIncluded ON)

# Returns a path with forward slashes replaced with backslashes on WIN32
function(NativisePath outvar)
  list(REMOVE_AT ARGV 0)
  if(WIN32)
    string(REPLACE "/" "\\" new ${ARGV})
  else()
    set(new ${ARGV})
  endif()
  set(${outvar} ${new} PARENT_SCOPE)
endfunction()

# Add generator expressions to appendvar expanding at build time any remaining parameters
# if the <condition> is true at build time
function(expand_at_build_if condition appendvar)
  set(ret ${${appendvar}})
  set(items ${ARGN})
  separate_arguments(items)
  foreach(item ${items})
    list(APPEND ret $<${condition}:${item}>)
  endforeach()
  set(${appendvar} ${ret} PARENT_SCOPE)
endfunction()

# Emulate list(FILTER list INCLUDE|EXCLUDE REGEX regex) on cmake < 3.6
function(list_filter listname op regexqualifer regex)
  if(CMAKE_VERSION VERSION_GREATER 3.59)
    list(FILTER ${ARGV})
  else()
    set(out)
    foreach(item ${${listname}})
      string(REGEX MATCH "${regex}" match ${item})
      if("${op}" STREQUAL "INCLUDE")
        if(match)
          list(APPEND out ${item})
        endif()
      else()
        if(NOT match)
          list(APPEND out ${item})
        endif()
      endif()
    endforeach()
    set(${listname} ${out} PARENT_SCOPE)
  endif()
endfunction()

# Escape a string into a regex matching that string
function(escape_string_into_regex outvar)
  string(REGEX REPLACE "(\\^|\\$|\\.|\\[|\\]|\\*|\\+|\\?|\\(|\\)|\\\\)" "\\\\1" out ${ARGN})
  set(${outvar} ${out} PARENT_SCOPE)
endfunction()


# We expect a header file with macros like
# #define BOOST_AFIO_VERSION_MAJOR    2
# 
# The first macros with _MAJOR, _MINOR, _PATCH and _REVISION at their end are parsed
function(ParseProjectVersionFromHpp hppfile outvar)
  file(READ ${hppfile} HPPFILE)
  string(REGEX MATCH "#[ \t]*define[ \t].*_MAJOR[ \t]+([0-9]+)" MAJORVER "${HPPFILE}")
  set(MAJORVER ${CMAKE_MATCH_1})
  string(REGEX MATCH "#[ \t]*define[ \t].*_MINOR[ \t]+([0-9]+)" MINORVER "${HPPFILE}")
  set(MINORVER ${CMAKE_MATCH_1})
  string(REGEX MATCH "#[ \t]*define[ \t].*_PATCH[ \t]+([0-9]+)" PATCHVER "${HPPFILE}")
  set(PATCHVER ${CMAKE_MATCH_1})
  string(REGEX MATCH "#[ \t]*define[ \t].*_REVISION[ \t]+([0-9]+)" REVISIONVER "${HPPFILE}")
  set(REVISIONVER ${CMAKE_MATCH_1})
  set(${outvar} ${MAJORVER}.${MINORVER}.${PATCHVER}.${REVISIONVER} PARENT_SCOPE)
endfunction()

# We expect a header file like this:
#   // Comment
#   #define BOOST_AFIO_PREVIOUS_COMMIT_REF    x
#   #define BOOST_AFIO_PREVIOUS_COMMIT_DATE   "x"
#   #define BOOST_AFIO_PREVIOUS_COMMIT_UNIQUE x
# Lines 2, 3 and 4 need their ending rewritten
function(UpdateRevisionHppFromGit hppfile)
  set(gitdir "${CMAKE_CURRENT_SOURCE_DIR}/.git")
  if(NOT IS_DIRECTORY "${gitdir}")
    file(READ "${gitdir}" pathtogitdir)
    # This will have the form:
    # gitdir: ../../../../.git/modules/include/boost/afio/boost-lite
    string(SUBSTRING "${pathtogitdir}" 8 -1 pathtogitdir)
    string(STRIP "${pathtogitdir}" pathtogitdir)
    set(gitdir "${CMAKE_CURRENT_SOURCE_DIR}/${pathtogitdir}")
  endif()
  # Read .git/HEAD and the SHA and timestamp
  #message(STATUS "gitdir is ${gitdir}")
  file(READ "${gitdir}/HEAD" HEAD)
  string(SUBSTRING "${HEAD}" 5 -1 HEAD)
  string(STRIP "${HEAD}" HEAD)
  #message(STATUS "head is '${HEAD}'")
  if(EXISTS "${gitdir}/${HEAD}")
    file(READ "${gitdir}/${HEAD}" HEADSHA)
    string(STRIP "${HEADSHA}" HEADSHA)
    file(TIMESTAMP "${gitdir}/${HEAD}" HEADSTAMP "%Y-%m-%d %H:%M:%S +00:00" UTC)
    #message(STATUS "Last commit was ${HEADSHA} at ${HEADSTAMP}")
    string(SUBSTRING "${HEADSHA}" 0 8 HEADUNIQUE)

    file(READ "${hppfile}" HPPFILE)
    string(REGEX MATCH "(.*\n.* )([a-f0-9]+)([\r\n]+.* \")(.*)(\"[\r\n]+.* )([a-f0-9]+)([\r\n]+.*)" txt1 "${HPPFILE}")
    set(txt1 "${CMAKE_MATCH_1}")
    set(OLDSHA "${CMAKE_MATCH_2}")
    set(txt2 "${CMAKE_MATCH_3}")
    set(OLDSTAMP "${CMAKE_MATCH_4}")
    set(txt3 "${CMAKE_MATCH_5}")
    set(OLDUNIQUE "${CMAKE_MATCH_6}")
    set(txt4 "${CMAKE_MATCH_7}")
    if(NOT HEADSHA STREQUAL OLDSHA)
      set(HPPFILE "${txt1}${HEADSHA}${txt2}${HEADSTAMP}${txt3}${HEADUNIQUE}${txt4}")
      file(WRITE "${hppfile}" "${HPPFILE}")
    endif()
  endif()
endfunction()

# Finds a Boostish library
#
# Boostish libraries can be located via these means in order of preference:
# 1) "../${library-dir}"
# 2) "./include/${PROJECT_DIR}/${library-name}"
# 3) <${library-dir}/${library-name}>
function(find_boostish_library library version)
  # Convert namespaced library name into path
  string(REPLACE "--" "/" librarydir "${library}")
  get_filename_component(libraryname "${librarydir}" NAME)
  string(REPLACE "--" "/" PROJECT_DIR ${PROJECT_NAMESPACE})
  set(PROJECT_DIR ${PROJECT_DIR}${PROJECT_NAME})
  # Prefer sibling editions of dependencies to embedded editions
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../${librarydir}/.boostish")
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../${librarydir}"
      "${CMAKE_CURRENT_BINARY_DIR}/${librarydir}"
      EXCLUDE_FROM_ALL
    )
    # One of the only uses of a non-target specific cmake command anywhere,
    # but this is local to the calling CMakeLists.txt and is the correct
    # thing to use. We use the fake directory "_" instead of the current
    # project to prevent accidental pickup of files in the current project.
    get_filename_component(path "${CMAKE_CURRENT_SOURCE_DIR}/../_" ABSOLUTE)
    include_directories(SYSTEM "${path}")
  elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_DIR}/${libraryname}/.boostish")
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_DIR}/${libraryname}"
      EXCLUDE_FROM_ALL
    )
    # If we are using an embedded dependency, for any unit tests make the
    # dependencies appear as if at the same location as for the headers
    include_directories(SYSTEM "${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_DIR}/_")
  else()
    list(FIND ARGN "QUIET" quiet_idx)
    if(${quiet_idx} EQUAL -1)
      message(WARNING "WARNING: Boostish library ${library} depended upon by ${PROJECT_NAMESPACE}${PROJECT_NAME} not found")
      message(STATUS "Tried: ")
      message(STATUS "  ${CMAKE_CURRENT_SOURCE_DIR}/../${librarydir}/.boostish")
      message(STATUS "  ${CMAKE_CURRENT_SOURCE_DIR}/include/${PROJECT_DIR}/${libraryname}/.boostish")
    endif()
    list(FIND ARGN "REQUIRED" required_idx)
    if(${required_idx} GREATER -1)
      message(FATAL_ERROR "FATAL: Boostish library ${library} required by ${PROJECT_NAMESPACE}${PROJECT_NAME} not found")
    endif()
  endif()
endfunction()