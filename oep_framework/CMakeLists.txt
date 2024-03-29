set(FRAMEWORK_NAME "banuba_oep") 

set(CMAKE_XCODE_GENERATE_SCHEME YES)

file(GLOB_RECURSE srcs
    ${CMAKE_CURRENT_LIST_DIR}/oep/*.cpp
    ${CMAKE_CURRENT_LIST_DIR}/oep/*.m
    ${CMAKE_CURRENT_LIST_DIR}/oep/*.mm
    ${CMAKE_CURRENT_LIST_DIR}/oep/*.hpp
    ${CMAKE_CURRENT_LIST_DIR}/oep/*.h
)

add_library(${FRAMEWORK_NAME} STATIC
    ${srcs}
)

target_link_libraries(${FRAMEWORK_NAME}
    bnb_oep_pixel_buffer_target
    bnb_oep_image_processing_result_target
    bnb_oep_offscreen_effect_player_target
    offscreen_rt
)

target_link_libraries(${FRAMEWORK_NAME}
    bnb_effect_player
)
set_target_properties(${FRAMEWORK_NAME} PROPERTIES XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES")

set(public_headers ${CMAKE_CURRENT_LIST_DIR}/oep/BNBOffscreenEffectPlayer.h)

# get_target_property(SDK_COMMON_FOLDER bnb_effect_player INTERFACE_BIN_DIR)
# target_include_directories(${FRAMEWORK_NAME} PRIVATE debug "${SDK_COMMON_FOLDER}/debug/BanubaEffectPlayer.framework/Headers")
# target_include_directories(${FRAMEWORK_NAME} PRIVATE optimized "${SDK_COMMON_FOLDER}/release/BanubaEffectPlayer.framework/Headers")

target_include_directories(${FRAMEWORK_NAME} PRIVATE "${PROJECT_SOURCE_DIR}/bnb_sdk_c_api/BNBEffectPlayerC.xcframework/ios-arm64/BNBEffectPlayerC.framework/Headers")
# target_include_directories(${FRAMEWORK_NAME} PRIVATE "${PROJECT_SOURCE_DIR}/bnb_sdk/BNBEffectPlayerC.xcframework/ios-arm64/BNBEffectPlayerC.framework/PrivateHeaders")
