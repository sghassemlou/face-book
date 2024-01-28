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
        setup()
    }
    
    public func setup() {
        checkPermission()
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            self.setupLayers()
            self.setupDetector()
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
    
    func setupVideoInput() {
        
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [
            .builtInDualCamera, .builtInTripleCamera, .builtInTelephotoCamera, .builtInDualWideCamera,
            /*.builtInUltraWideCamera,*/ .builtInWideAngleCamera
        ], mediaType: .video, position: .unspecified).devices
        if devices.isEmpty { return }
        camera_idx = (camera_idx + 1) % devices.count
        let videoDevice = devices[camera_idx]
        
        print("initialising with camera: ", videoDevice.localizedName)

        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
    }
    
    func setupCaptureSession() {
        // Camera input
        setupVideoInput()
                         
        // Preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // Detector
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)

        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.previewLayer.frame = self!.view.frame
            self!.screenRect = self!.view.frame
            self!.view.layer.addSublayer(self!.previewLayer)
            print(self!.view.layer.sublayers!)
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
