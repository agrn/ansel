set(CPACK_PACKAGE_NAME "${CMAKE_PROJECT_NAME}")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "The digital darkroom")
set(CPACK_PACKAGE_CONTACT "https://ansel.photos/")
set(CPACK_PACKAGE_VENDOR "The Ansel project")

set(CPACK_SOURCE_IGNORE_FILES
   "/.gitignore"
   "${CMAKE_BINARY_DIR}/"
   "/.git/"
   "/.deps/"
   "/.build/"
)
set(CPACK_PACKAGE_EXECUTABLES ansel)
set(CPACK_SOURCE_GENERATOR "TGZ")
set(CPACK_GENERATOR "TGZ")
SET(CPACK_SOURCE_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}")

if("${CMAKE_BUILD_TYPE}" MATCHES "Release")
	set(CPACK_STRIP_FILES TRUE)
endif("${CMAKE_BUILD_TYPE}" MATCHES "Release")

# Set package for unix
if(UNIX)
	# Try to find architecture
	execute_process(COMMAND uname -m OUTPUT_VARIABLE CPACK_PACKAGE_ARCHITECTURE)
	string(STRIP "${CPACK_PACKAGE_ARCHITECTURE}" CPACK_PACKAGE_ARCHITECTURE)
	# Try to find distro name and distro-specific arch
	execute_process(COMMAND lsb_release -is OUTPUT_VARIABLE LSB_ID)
	execute_process(COMMAND lsb_release -rs OUTPUT_VARIABLE LSB_RELEASE)
	string(STRIP "${LSB_ID}" LSB_ID)
	string(STRIP "${LSB_RELEASE}" LSB_RELEASE)
	set(LSB_DISTRIB "${LSB_ID}${LSB_RELEASE}")
	if(NOT LSB_DISTRIB)
		set(LSB_DISTRIB "unix")
	endif(NOT LSB_DISTRIB)

	if("${LSB_DISTRIB}" MATCHES "Fedora|Mandriva")
		make_directory(${CMAKE_BINARY_DIR}/packaging/rpm)
		set(CPACK_GENERATOR "RPM")
		set(CPACK_RPM_PACKAGE_ARCHITECTURE ${CPACK_PACKAGE_ARCHITECTURE})
		set(CPACK_RPM_PACKAGE_RELEASE "1")

	endif("${LSB_DISTRIB}" MATCHES "Fedora|Mandriva")



endif(UNIX)

# Set package peoperties for Windows
if(WIN32)
  set(CPACK_GENERATOR "NSIS")
  set(CPACK_PACKAGE_EXECUTABLES "ansel" "ansel")
  set(CPACK_PACKAGE_INSTALL_DIRECTORY "${CMAKE_PROJECT_NAME}")
  # There is a bug in NSIS that does not handle full unix paths properly. Make
  # sure there is at least one set of four (4) backlasshes.
  #SET(CPACK_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/data/pixmaps/256x256/ansel.png")
  SET(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_SOURCE_DIR}/data/pixmaps/dt_logo_128x128.ico")
  SET(CPACK_NSIS_MUI_UNIICON "${CMAKE_CURRENT_SOURCE_DIR}/data/pixmaps/dt_logo_128x128.ico")
  SET(CPACK_NSIS_INSTALLED_ICON_NAME "bin\\\\${CMAKE_PROJECT_NAME}.exe")
  SET(CPACK_NSIS_DISPLAY_NAME "Ansel")
  SET(CPACK_NSIS_HELP_LINK "https://ansel.photos/en/doc/install")
  SET(CPACK_NSIS_URL_INFO_ABOUT "https://ansel.photos")
  SET(CPACK_NSIS_MODIFY_PATH OFF)
  SET(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)

  set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")

  # register dt in the Windows registry. this is needed for GIMP to find dt.
  SET(CPACK_NSIS_EXTRA_INSTALL_COMMANDS "
      WriteRegStr HKLM 'SOFTWARE\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\App Paths\\\\ansel.exe' '' '$INSTDIR\\\\bin\\\\ansel.exe'
      WriteRegStr HKLM 'SOFTWARE\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\App Paths\\\\ansel-cli.exe' '' '$INSTDIR\\\\bin\\\\ansel-cli.exe'
      WriteRegStr HKLM 'SOFTWARE\\\\Classes\\\\Applications\\\\ansel.exe\\\\shell\\\\open\\\\command' '' '\\\"$INSTDIR\\\\bin\\\\ansel.exe\\\" \\\"%1\\\"'
   ")
  SET(CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS "
      DeleteRegKey HKLM 'SOFTWARE\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\App Paths\\\\ansel.exe'
      DeleteRegKey HKLM 'SOFTWARE\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\App Paths\\\\ansel-cli.exe'
      DeleteRegKey HKLM 'SOFTWARE\\\\Classes\\\\Applications\\\\ansel.exe'
  ")

  # also associate dt with all the supported image file types
  foreach(EXTENSION ${DT_SUPPORTED_EXTENSIONS})
    SET(CPACK_NSIS_EXTRA_INSTALL_COMMANDS "${CPACK_NSIS_EXTRA_INSTALL_COMMANDS}
      WriteRegStr HKLM 'SOFTWARE\\\\Classes\\\\.${EXTENSION}\\\\OpenWithList\\\\ansel.exe' '' ''
    ")
    SET(CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS "${CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS}
      DeleteRegKey HKLM 'SOFTWARE\\\\Classes\\\\.${EXTENSION}\\\\OpenWithList\\\\ansel.exe'
    ")
  endforeach(EXTENSION)

endif(WIN32)

include(CPack)

# More descriptive names for each of the components
CPACK_ADD_COMPONENT(DTApplication DISPLAY_NAME "ansel main application" REQUIRED)
CPACK_ADD_COMPONENT(DTDebugSymbols DISPLAY_NAME "Debug symbols" REQUIRED)
CPACK_ADD_COMPONENT(DTDocuments DISPLAY_NAME "Documentation and help files")

ADD_CUSTOM_TARGET(pkgsrc
  COMMAND ${CMAKE_COMMAND} -E copy ${DARKTABLE_BINDIR}/version_gen.c ${CMAKE_SOURCE_DIR}/src/version_gen.c
  COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target package_source
  COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_SOURCE_DIR}/src/version_gen.c
)

add_dependencies(pkgsrc generate_version)
