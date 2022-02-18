set(include_dirs
    ${CMAKE_CURRENT_SOURCE_DIR}/include/
)

set(module_interfaces
    ${CMAKE_SOURCE_DIR}/OEP-module/
)
file(GLOB_RECURSE srcs
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h
)

add_library(offscreen_rt STATIC ${srcs})

target_include_directories(offscreen_rt PUBLIC
    ${include_dirs}
    ${module_interfaces}
)

target_include_directories(offscreen_rt PUBLIC ${PROJECT_SOURCE_DIR})

target_link_libraries(offscreen_rt
    # glad
    ogl_utils
    GLESv3
    EGL
)

target_include_directories(offscreen_rt PRIVATE "${PROJECT_SOURCE_DIR}/bnb_sdk_c_api/BNBEffectPlayerC.xcframework/ios-arm64/BNBEffectPlayerC.framework/Headers")
set_target_properties(offscreen_rt PROPERTIES XCODE_ATTRIBUTE_OTHER_LIBTOOLFLAGS "-logl_utils -L${CMAKE_BINARY_DIR}/libraries/utils/ogl_utils/$(CONFIGURATION)-iphoneos")
