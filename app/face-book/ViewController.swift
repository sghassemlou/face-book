import UIKit
import SwiftUI
import AVFoundation
import Vision


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false // Flag for permission
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil // For view dimensions
    
    // Detector
    private var videoOutput = AVCaptureVideoDataOutput()
    var requests = [VNRequest]()
    var detectionLayer: CALayer! = nil
    var camera_idx: Int = -1
    
      
    override func viewDidLoad() {
        checkPermission()
        setup()
    }
    
    public func setup() {
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
            case .authorized:
                permissionGranted = true
                
            // Permission has not been requested yet
            case .notDetermined:
                requestPermission()
                    
            default:
                permissionGranted = false
            }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func setupCaptureSession() {
        // Camera input
        // guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video, position: .back) else { return }
        // use the default camera
        // guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }

        // list all devices
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [
            .builtInDualCamera, .builtInTripleCamera, .builtInTelephotoCamera, .builtInDualWideCamera,
            .builtInUltraWideCamera, .builtInWideAngleCamera
        ], mediaType: .video, position: .unspecified).devices
        if devices.isEmpty { return }
        camera_idx = (camera_idx + 1) % devices.count
        let videoDevice = devices[camera_idx]
        print("initialising with camera ", camera_idx)

//        // debug print all device names
//        for device in devices {
//            print(device.localizedName)
//            print(device.description)
//        }

        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
           
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
                         
        // Preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // Detector
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
        
        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.previewLayer.frame = self!.view.frame
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
}

var vc: ViewController! = nil;

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        vc = ViewController()
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
