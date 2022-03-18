cmake_minimum_required(VERSION 3.9)

project(oep_ios_c_api LANGUAGES C CXX OBJC OBJCXX Swift)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_MACOSX_BUNDLE YES)

set(BNB_RESOURCES_FOLDER ${CMAKE_CURRENT_LIST_DIR}/resources)

# Set to OFF to disable ffmpeg dependency (SDK should be built with disabled video_player also)
set(BNB_VIDEO_PLAYER ON)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/utils.cmake)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/bnb_sdk_c_api)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/libraries)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/OEP-module)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/offscreen_render_target)

option(DEPLOY_BUILD "Build for deployment" OFF)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/oep_framework)
# some magic to add these files to copy phase
set(SDK_FRAMEWORK_PATH "${CMAKE_CURRENT_LIST_DIR}/bnb_sdk_c_api")
set(FullEPFrameworkPath "${SDK_FRAMEWORK_PATH}/BNBEffectPlayerC.xcframework/ios-arm64/BNBEffectPlayerC.framework")
add_custom_command(OUTPUT "${FullEPFrameworkPath}" COMMAND "")

set(BANUBA_OEP_FRAMEWORK banuba_oep)


set(APP_NAME "example_ios_c_api") 

set(CMAKE_XCODE_ATTRIBUTE_SWIFT_OBJC_BRIDGING_HEADER "${PROJECT_SOURCE_DIR}/BNBObjCHeaders.h")
set(CMAKE_XCODE_ATTRIBUTE_SWIFT_OBJC_INTERFACE_HEADER_NAME "MySwiftInterfaceHeader.h")

set(APP_HEADER_FILES
    ./BNBObjCHeaders.h
)

set(APP_SOURCE_FILES
    src/AppDelegate.swift
    src/ViewController.swift
)

set(RESOURCES
    ${BNB_RESOURCES_FOLDER}/Main.storyboard
    ${BNB_RESOURCES_FOLDER}/LaunchScreen.storyboard
    ${BNB_RESOURCES_FOLDER}/bnb_viewer.icns
    ${BNB_RESOURCES_FOLDER}/effects
    ${BNB_RESOURCES_FOLDER}/bnb-resources
)

set(CMAKE_XCODE_GENERATE_SCHEME YES)

add_executable(${APP_NAME}
    MACOSX_BUNDLE
    ${APP_HEADER_FILES}
    ${APP_SOURCE_FILES}
    ${RESOURCES}
    ${FullEPFrameworkPath}
)

# foreach(assetItem ${RESOURCES})
#   set_source_files_properties(${assetItem} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)   
# endforeach()
# set_source_files_properties(${FullEPFrameworkPath} PROPERTIES MACOSX_PACKAGE_LOCATION Frameworks)

add_dependencies(${APP_NAME} ${BANUBA_OEP_FRAMEWORK})

# set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES")
set(EXAMPLE_BUNDLE_NAME "Banuba Offscreen Rendering Example") # This name can contain up to 15 characters according to Apple's documentation
set(EXAMPLE_COPYRIGHT "© 2021 Banuba. All rights reserved.")
set(EXAMPLE_INFO "Banuba Offscreen Rendering Example.")
set(CMAKE_XCODE_ATTRIBUTE_DEBUG_INFORMATION_FORMAT "dwarf-with-dsym")

set(CMAKE_XCODE_ATTRIBUTE_ARCHS "arm64")
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "12.0")
set(CMAKE_XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS "iphonesimulator iphoneos")
set(CMAKE_XCODE_ATTRIBUTE_SDKROOT "iphoneos")
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "No")

set_target_properties(${APP_NAME} PROPERTIES
    OUTPUT_NAME ${EXAMPLE_BUNDLE_NAME}
    RESOURCE "${RESOURCES}"
    MACOSX_BUNDLE TRUE
    # The same as stadrard MacOSXBundleInfo.plist.in from CMake but with camera permissions added
    XCODE_ATTRIBUTE_INFOPLIST_FILE ${BNB_RESOURCES_FOLDER}/Info.plist
    MACOSX_BUNDLE_BUNDLE_NAME           ${EXAMPLE_BUNDLE_NAME}                # Sets CFBundleName
    MACOSX_BUNDLE_COPYRIGHT             ${EXAMPLE_COPYRIGHT}                  # Sets NSHumanReadableCopyright
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER        "com.banuba.sdk.offsceen.ios-c-api.sample"  # Sets CFBundleIdentifier
    MACOSX_BUNDLE_ICON_FILE             bnb_viewer.icns                       # Sets CFBundleIconFile
    MACOSX_BUNDLE_INFO_STRING           ${EXAMPLE_INFO}                       # Sets CFBundleGetInfoString

    XCODE_ATTRIBUTE_SDKROOT "iphoneos"
    MACOSX_DEPLOYMENT_TARGET "12.0"
)

target_link_libraries(${APP_NAME}
    "-framework ${BANUBA_OEP_FRAMEWORK}"
    bnb_effect_player
    "-framework Accelerate"
    "-framework UIKit"
    "-framework Foundation"
    "-framework CoreMedia"
    "-framework CoreVideo"
    "-framework VideoToolbox"
)

set_target_properties(${APP_NAME} PROPERTIES XCODE_ATTRIBUTE_FRAMEWORK_SEARCH_PATHS "${FullEPFrameworkPath}")
set_target_properties(${APP_NAME} PROPERTIES XCODE_ATTRIBUTE_HEADER_SEARCH_PATHS "$<TARGET_FILE_DIR:${BANUBA_OEP_FRAMEWORK}>/ios-arm64/${BANUBA_OEP_FRAMEWORK}.framework/Headers")
set_target_properties(${APP_NAME} PROPERTIES XCODE_ATTRIBUTE_OTHER_LDFLAGS "-F$<TARGET_FILE_DIR:${BANUBA_OEP_FRAMEWORK}>-iphoneos -lc++")
set_target_properties(${APP_NAME} PROPERTIES XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES")

 target_link_libraries(${APP_NAME} ${OTHER_LDFLAGS})
