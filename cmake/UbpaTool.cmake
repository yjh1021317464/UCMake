# [ Interface ]
#
# ----------------------------------------------------------------------------
#
# Ubpa_AddSubDirsRec(<path>)
# - add all subdirectories recursively in <path>
#
# ----------------------------------------------------------------------------
#
# Ubpa_GroupSrcs(PATH <path> SOURCES <sources-list>
# - create filters (relative to <path>) for sources
#
# ----------------------------------------------------------------------------
#
# Ubpa_GlobGroupSrcs(RST <rst> PATHS <paths-list>)
# - recursively glob all sources in <paths-list>
#   and call Ubpa_GroupSrcs(PATH <path> SOURCES <rst>) for each path in <paths-list>
# - regex : .+\.(h|hpp|inl|in|c|cc|cpp|cxx)
#
# ----------------------------------------------------------------------------
#
# Ubpa_GetTargetName(<rst> <targetPath>)
# - get target name at <targetPath>
#
# ----------------------------------------------------------------------------
#
# Ubpa_AddTarget_GDR(MODE <mode> [QT <qt>] [SOURCES <sources-list>]
#     [LIBS_GENERAL <libsG-list>] [LIBS_DEBUG <libsD-list>] [LIBS_RELEASE <libsR-list>])
# - mode         : EXE / LIB / DLL
# - libsG-list   : auto add DEBUG_POSTFIX for debug mode
# - sources-list : if sources is empty, call Ubpa_GlobGroupSrcs for currunt path
# - auto set target name, folder, target prefix and some properties
#
# ----------------------------------------------------------------------------
#
# Ubpa_AddTarget(MODE <mode> [QT <qt>] [SOURCES <sources-list>] [LIBS <libs-list>])
# - call Ubpa_AddTarget(MODE <mode> SOURCES <sources-list> LIBS_GENERAL <libs-list>)
#
# ----------------------------------------------------------------------------

message(STATUS "include UbpaTool.cmake")

include(UbpaQt)

function(Ubpa_AddSubDirsRec path)
	message(STATUS "----------")
	file(GLOB_RECURSE children LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/${path}/*)
	set(dirs "")
	foreach(item ${children})
		if(IS_DIRECTORY ${item} AND EXISTS "${item}/CMakeLists.txt")
			list(APPEND dirs ${item})
		endif()
	endforeach()
	Ubpa_List_Print(TITLE "directories:" PREFIX "- " STRS ${dirs})
	foreach(dir ${dirs})
		add_subdirectory(${dir})
	endforeach()
endfunction()

function(Ubpa_GroupSrcs)
	cmake_parse_arguments("ARG" "" "PATH" "SOURCES" ${ARGN})
	
	set(headerFiles ${ARG_SOURCES})
	list(FILTER headerFiles INCLUDE REGEX ".+\.(h|hpp|inl|in)$")
	
	set(sourceFiles ${ARG_SOURCES})
	list(FILTER sourceFiles INCLUDE REGEX ".+\.(c|cc|cpp|cxx)$")
	
	set(qtFiles ${ARG_SOURCES})
	list(FILTER qtFiles INCLUDE REGEX ".+\.(qrc|ui)$")
	
	foreach(header ${headerFiles})
		get_filename_component(headerPath "${header}" PATH)
		file(RELATIVE_PATH headerPathRel ${ARG_PATH} "${headerPath}")
		if(MSVC)
			string(REPLACE "/" "\\" headerPathRelMSVC "${headerPathRel}")
			set(headerPathRel "Header Files\\${headerPathRelMSVC}")
		endif()
		source_group("${headerPathRel}" FILES "${header}")
	endforeach()
	
	foreach(source ${sourceFiles})
		get_filename_component(sourcePath "${source}" PATH)
		file(RELATIVE_PATH sourcePathRel ${ARG_PATH} "${sourcePath}")
		if(MSVC)
			string(REPLACE "/" "\\" sourcePathRelMSVC "${sourcePathRel}")
			set(sourcePathRel "Source Files\\${sourcePathRelMSVC}")
		endif()
		source_group("${sourcePathRel}" FILES "${source}")
	endforeach()
	
	foreach(qtFile ${qtFiles})
		get_filename_component(qtFilePath "${qtFile}" PATH)
		file(RELATIVE_PATH qtFilePathRel ${ARG_PATH} "${qtFilePath}")
		if(MSVC)
			string(REPLACE "/" "\\" qtFilePathRelMSVC "${qtFilePathRel}")
			set(qtFilePathRel "Qt Files\\${qtFilePathRelMSVC}")
		endif()
		source_group("${qtFilePathRel}" FILES "${qtFile}")
	endforeach()
endfunction()

function(Ubpa_GlobGroupSrcs)
	cmake_parse_arguments("ARG" "" "RST" "PATHS" ${ARGN})
	set(sources "")
	foreach(path ${ARG_PATHS})
		file(GLOB_RECURSE pathSources
			"${path}/*.h"
			"${path}/*.hpp"
			"${path}/*.inl"
			"${path}/*.in"
			"${path}/*.c"
			"${path}/*.cc"
			"${path}/*.cpp"
			"${path}/*.cxx"
			"${path}/*.qrc"
			"${path}/*.ui"
		)
		list(APPEND sources ${pathSources})
		Ubpa_GroupSrcs(PATH ${path} SOURCES ${pathSources})
	endforeach()
	set(${ARG_RST} ${sources} PARENT_SCOPE)
endfunction()

function(Ubpa_GetTargetName rst targetPath)
	file(RELATIVE_PATH targetRelPath "${PROJECT_SOURCE_DIR}/src" "${targetPath}")
	string(REPLACE "/" "_" targetName "${PROJECT_NAME}/${targetRelPath}")
	set(${rst} ${targetName} PARENT_SCOPE) 
endfunction()

function(Ubpa_AddTarget_GDR)
    # https://www.cnblogs.com/cynchanpin/p/7354864.html
	# https://blog.csdn.net/fuyajun01/article/details/9036443
	cmake_parse_arguments("ARG" "" "MODE;QT" "SOURCES;LIBS_GENERAL;LIBS_DEBUG;LIBS_RELEASE" ${ARGN})
	file(RELATIVE_PATH targetRelPath "${PROJECT_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/..")
	set(folderPath "${PROJECT_NAME}/${targetRelPath}")
	Ubpa_GetTargetName(targetName ${CMAKE_CURRENT_SOURCE_DIR})
	
	list(LENGTH ARG_SOURCES sourceNum)
	if(${sourceNum} EQUAL 0)
		Ubpa_GlobGroupSrcs(RST ARG_SOURCES PATHS ${CMAKE_CURRENT_SOURCE_DIR})
		list(LENGTH ARG_SOURCES sourceNum)
		if(sourcesNum EQUAL 0)
			message(WARNING "Target [${targetName}] has no source")
			return()
		endif()
	endif()
	
	message(STATUS "----------")
	message(STATUS "- name: ${targetName}")
	message(STATUS "- folder : ${folderPath}")
	message(STATUS "- mode: ${ARG_MODE}")
	Ubpa_List_Print(STRS ${ARG_SOURCES}
		TITLE  "- sources:"
		PREFIX "    ")
	
	list(LENGTH ARG_LIBS_GENERAL generalLibNum)
	list(LENGTH ARG_LIBS_DEBUG debugLibNum)
	list(LENGTH ARG_LIBS_RELEASE releaseLibNum)
	if(${debugLibNum} EQUAL 0 AND ${releaseLibNum} EQUAL 0)
		if(NOT ${generalLibNum} EQUAL 0)
		Ubpa_List_Print(STRS ${ARG_LIBS_GENERAL}
			TITLE  "- lib:"
			PREFIX "    ")
		endif()
	else()
		message(STATUS "- libs:")
		Ubpa_List_Print(STRS ${ARG_LIBS_GENERAL}
			TITLE  "  - general:"
			PREFIX "      ")
		Ubpa_List_Print(STRS ${ARG_LIBS_DEBUG}
			TITLE  "  - debug:"
			PREFIX "      ")
		Ubpa_List_Print(STRS ${ARG_LIBS_RELEASE}
			TITLE  "  - release:"
			PREFIX "      ")
	endif()
	
	# add target
	
	if(${ARG_QT})
		Ubpa_QtBegin()
	endif()
	
	if(${ARG_MODE} STREQUAL "EXE")
		add_executable(${targetName} ${ARG_SOURCES})
		if(MSVC)
			set_target_properties(${targetName} PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/bin")
		endif()
		set_target_properties(${targetName} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
	elseif(${ARG_MODE} STREQUAL "LIB")
		add_library(${targetName} ${ARG_SOURCES})
		# 无需手动设置
		#set_target_properties(${targetName} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
	elseif(${ARG_MODE} STREQUAL "DLL")
		add_library(${targetName} SHARED ${ARG_SOURCES})
	else()
		message(FATAL_ERROR "mode [${ARG_MODE}] is not supported")
		return()
	endif()
	
	# folder
	set_target_properties(${targetName} PROPERTIES FOLDER ${folderPath})
	
	foreach(lib ${ARG_LIBS_GENERAL})
		target_link_libraries(${targetName} general ${lib})
	endforeach()
	foreach(lib ${ARG_LIBS_DEBUG})
		target_link_libraries(${targetName} debug ${lib})
	endforeach()
	foreach(lib ${ARG_LIBS_RELEASE})
		target_link_libraries(${targetName} optimized ${lib})
	endforeach()
	install(TARGETS ${targetName}
		RUNTIME DESTINATION "bin"
		ARCHIVE DESTINATION "lib"
		LIBRARY DESTINATION "lib")
	
	if(${ARG_QT})
		Ubpa_QtEnd()
	endif()
endfunction()

function(Ubpa_AddTarget)
    # https://www.cnblogs.com/cynchanpin/p/7354864.html
	# https://blog.csdn.net/fuyajun01/article/details/9036443
	cmake_parse_arguments("ARG" "" "MODE;QT" "SOURCES;LIBS" ${ARGN})
	Ubpa_AddTarget_GDR(MODE ${ARG_MODE} QT ${ARG_QT} SOURCES ${ARG_SOURCES} LIBS_GENERAL ${ARG_LIBS})
endfunction()
