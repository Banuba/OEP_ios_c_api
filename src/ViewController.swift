import UIKit
import AVFoundation
import VideoToolbox

enum ImageFormat: String {
    case i420 = "i420"
    case NV12 = "NV12"
};

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    private var session = AVCaptureSession()
    private var effectPlayer: BNBOffscreenEffectPlayer?
    private let output = AVCaptureVideoDataOutput()
    private var input: AVCaptureDeviceInput?
    private var error: NSError?
    // NOTE: .portrait and .portraitUpsideDown are not optimal better performance in landscape mode
    private let outputVideoOrientation: AVCaptureVideoOrientation = .landscapeRight // .landscapeLeft is default for output if not configured
    private let cameraPosition: AVCaptureDevice.Position = .front
    private let cameraPreset: AVCaptureSession.Preset = .hd1280x720
    private var renderWidth: UInt = 720
    private var renderHeight: UInt = 1280
    private var loadingEffect = true
    private var imageFormat = ImageFormat.i420
    //private var resultedImageOrientation: bnb::oep::interfaces::rotation = .deg0
    private var uiOrientation: UIInterfaceOrientation = .portrait
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initBNBOffscreenEffectPlayer(
            width: renderWidth,
            height: renderHeight,
            manualAudio: false
        )
        rotateBNBOffscreenEffectPlayer()
        loadEffect()
        setUpCamera()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition(in: imageView, animation: { (UIViewControllerTransitionCoordinatorContext) in
            self.rotateBNBOffscreenEffectPlayer()
        }, completion: nil)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        //deallocate effect player when app was closed
        effectPlayer = nil;
    }

    private func rotateBNBOffscreenEffectPlayer() {
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            uiOrientation = .portrait
            effectPlayer?.surfaceChanged(renderWidth, withHeight: renderHeight)
        case .portraitUpsideDown: // Impossible case, at least no such event raised
            uiOrientation = .portraitUpsideDown
            effectPlayer?.surfaceChanged(renderWidth, withHeight: renderHeight)
        case .landscapeLeft:
            uiOrientation = .landscapeLeft
            effectPlayer?.surfaceChanged(renderHeight, withHeight: renderWidth)
        case .landscapeRight:
            uiOrientation = .landscapeRight
            effectPlayer?.surfaceChanged(renderHeight, withHeight: renderWidth)
        default:
            break
        }
    }
    
    private func initBNBOffscreenEffectPlayer(width: UInt, height: UInt, manualAudio: Bool) {
        let dirs = [ Bundle.main.bundlePath + "/effects", Bundle.main.bundlePath + "/Frameworks/BNBEffectPlayerC.framework/bnb-resources"]
        
        effectPlayer = BNBOffscreenEffectPlayer.init(width: width, height: height, manualAudio: manualAudio, token: <#Place your banuba token here#>, resourcePaths: dirs)
    }
    
    private func loadEffect() {
        if(loadingEffect) {
            effectPlayer?.loadEffect("blur_bg")
        }
    }
    
    private func setUpCamera() {
        session.beginConfiguration()
        session.sessionPreset = cameraPreset
        
        guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: AVMediaType.video,
                position: cameraPosition) else { return }
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        guard let input = self.input else { return }
        
        if error == nil && session.canAddInput(input) {
            session.addInput(input)
        }
        
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] as [String : Any]
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        session.addOutput(output)
        
        if let captureConnection = output.connection(with: .video) {
            captureConnection.videoOrientation = outputVideoOrientation
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
    
    private func getImageOrientation() -> EPOrientation {
        if outputVideoOrientation == .landscapeRight {
            if uiOrientation == .portrait {
                return cameraPosition == .front ? .angles270 : .angles90
            }
            else if uiOrientation == .portraitUpsideDown {
                return cameraPosition == .front ? .angles90 : .angles270
            }
            else if uiOrientation == .landscapeRight {
                return .angles0
            }
            // .landscapeRight
            return .angles180
        }
        else if outputVideoOrientation == .landscapeLeft {
            if uiOrientation == .portrait {
                return cameraPosition == .front ? .angles90 : .angles270
            }
            else if uiOrientation == .portraitUpsideDown {
                return cameraPosition == .front ? .angles270 : .angles90
            }
            else if uiOrientation == .landscapeRight {
                return .angles180
            }
            // .landscapeRight
            return .angles0
        }
        else if outputVideoOrientation == .portrait {
            if uiOrientation == .portrait {
                return .angles0
            }
            else if uiOrientation == .portraitUpsideDown {
                return .angles180
            }
            else if uiOrientation == .landscapeRight {
                return cameraPosition == .front ? .angles90 : .angles270
            }
            // .landscapeRight
            return cameraPosition == .front ? .angles270 : .angles90
        }
        else { // .portraitUpsideDown
            if uiOrientation == .portrait {
                return .angles180
            }
            else if uiOrientation == .portraitUpsideDown {
                return .angles0
            }
            else if uiOrientation == .landscapeRight {
                return cameraPosition == .front ? .angles270 : .angles90
            }
            // .landscapeRight
            return cameraPosition == .front ? .angles90 : .angles270
        }
    }

    func paintPixelBuffer(_ pixelBuffer: CVPixelBuffer?) {
        autoreleasepool{
            if let resultPixelBuffer = pixelBuffer {
                var cgImage: CGImage?

                VTCreateCGImageFromCVPixelBuffer(resultPixelBuffer, nil, &cgImage)

                guard let cgImageSafe = cgImage else { return }

                let image = UIImage(cgImage: cgImageSafe, scale: 1.0, orientation: .left)

                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard var imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        if(imageFormat == ImageFormat.i420) {
            let converter = Converter();
            imageBuffer = converter.convertTo420(imageBuffer).takeUnretainedValue();
        }
        
        if (self.loadingEffect) {
            let orientation = getImageOrientation()
            effectPlayer?.processImage(imageBuffer, imageFormat: imageFormat.rawValue, inputOrientation: orientation,
                                       completion: { [weak self] (resPixelBuffer) in
                self?.paintPixelBuffer(resPixelBuffer)
            })
        } else {
            paintPixelBuffer(imageBuffer)
        }
    }
}


