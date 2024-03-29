# Quick start examples for integrating [Banuba SDK for IOS](https://docs.banuba.com/face-ar-sdk/ios/ios_overview/) in C++ apps

> **Important**
>
>[master](../../tree/master) branch is always compatible with latest SDK version. Please use [v0.x](../../tree/v0.x) branch for SDK version 0.x (e.g. v0.38).

## Getting Started

1. Get the latest Banuba SDK with C API archive for IOS and the client token. Please fill out our form at [form at banuba.com](https://www.banuba.com/face-filters-sdk) website, or contact us via [info@banuba.com](mailto:info@banuba.com).
2. Extract BNBEffectPlayerC-iosXCFrameworksArchive archive into the `OEP_ios_c_api/bnb_sdk_c_api` dir:
    `BNBEffectPlayerC-iosXCFrameworksArchive` => `OEP_ios_c_api/bnb_sdk_c_api`
3. Donwload desired effects from [here](https://docs.banuba.com/face-ar-sdk-v1/overview/demo_face_filters) and put them into the following folder: `OEP_ios_c_api/resources/effects`.
4. Generate project files by executing the following commands:

    ```sh
        cd $path_to_repository
        git submodule update --init --recursive
        mkdir build
        cd build
        cmake -G Xcode ..
    ```

5. The previous step will generate a Xcode project. Open the OEP_ios_c_api project in the Xcode.
6. Copy and Paste your client token into the appropriate section of `OEP_ios_c_api/ViewController.swift`. Add the downloaded effect's name in the same file.
7. Select target `example_ios_c_api`.
8. Drag&Drop BNBEffectPlayerC.framework from the Xcode Navigator to the `Project Settings->General->Frameworks, Libraries and Embedded Content` section of the target.
9. Add you sign into the `Project Settings->Signing & Capabilities` section of the target.
10. Run build.

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

# Sample structure

- **OEP-module** - is a submodule of the offscreen effect player.
- **offscreen_render_target** - is an implementation option for the offscreen_render_target interface. Allows to prepare OpenGLES framebuffers and textures for receiving a frame from gpu, receive bytes of the processed frame from the gpu and pass them to the cpu, as well as, if necessary, set the orientation for the received frame.
- **libraries**
    - **utils**
        - **ogl_utils** - contains helper classes to work with Open GL
        - **utils** - сontains common helper classes such as thread_pool
- **oep_framework** - contains build rules banuba_oep framework and BNBOffscreenEffectPlayer, which is a class for working with the effect player 
- **ViewController.swift** - contains a pipeline of frames received from the camera and sent for processing the effect and the subsequent receipt of processed frames

## How to change an effect

1. Open `OEP_ios_c_api/ViewController.swift`
2. Find function `loadEffect()`:

   ```swift
    private func loadEffect() {
        loadingEffect = true
        effectPlayer?.loadEffect("test_BG")
    }
   ```

3. Write the effect name that you want to run.

*Note:* The effect must be in `OEP_ios_c_api/resources/effects`.
