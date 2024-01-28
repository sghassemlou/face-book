import UIKit
import SwiftUI
import AVFoundation
import Vision

let FUDGE_FACTOR = 0.21 // there's some offset to one of the transforms I can't quite figure out.
                        // This compensates for that. Obviously not good for production, but it
                        // should be fine for a hackathon.

let SCALE_FACTOR = 2.4
let SCALE_FACTOR_FRONT = 1.9

var last_time_photo_taken = 0.0
let MIN_PHOTO_INTERVAL = 0.3 // seconds (increase when testing with aws)

class CameraViewController: UIViewController,
                            AVCaptureVideoDataOutputSampleBufferDelegate,
                            AVCapturePhotoCaptureDelegate {
    private var permissionGranted = false // Flag for permission
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil            // For view dimensions
    var dimensions: CMVideoDimensions! = nil // For underlying camera dimensions
    var frontCam: Bool = false
    
    // Detector
    private var videoOutput = AVCaptureVideoDataOutput()
    var requests = [VNDetectFaceRectanglesRequest]()
    var detectionLayer: CALayer! = nil

    var camera_idx: Int = -1 // increment when pressing camera button


    override func viewDidLoad() {
        checkPermission()
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()

            DispatchQueue.main.async { [weak self] in
                self!.detectionLayer = CALayer()
                self!.detectionLayer.frame = self!.view.frame
                self!.view.layer.addSublayer(self!.detectionLayer)
            }

            self.requests = [VNDetectFaceRectanglesRequest(completionHandler: detectionDidComplete)]

            self.captureSession.startRunning()
        }
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            // Permission has been granted before
            case .authorized:
                permissionGranted = true

            // Permission has not been requested yet, pause initialization and request it
            case .notDetermined:
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                    self.permissionGranted = granted
                    self.sessionQueue.resume()
                }

            default:
                permissionGranted = false
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
        dimensions = videoDevice.activeFormat.formatDescription.dimensions

        print("initialising with camera: ", videoDevice.localizedName)

        frontCam = videoDevice.position == .front

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
        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.addOutput(photoOutput)

        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.previewLayer.frame = self!.view.frame
            self!.screenRect = self!.view.frame
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }

    func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.extractDetections(results)
            }
        })
    }


    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:]) // Create handler to perform request on the buffer

        do {
            try imageRequestHandler.perform(self.requests) // Schedules vision requests to be performed
        } catch {
            print(error)
        }
    }


    func extractDetections(_ results: [VNObservation]) {
        detectionLayer.sublayers = nil

        // fall out if we're not intitialized
        if (CGFloat(dimensions.width) == 0 || CGFloat(dimensions.height) == 0 || screenRect.size.width == 0 || screenRect.size.height == 0) { return }

        var aspect = CGFloat(dimensions.width) / CGFloat(dimensions.height)
        if (dimensions.height > dimensions.width) { aspect = 1.0 / aspect }
        let tWidth = max(screenRect.size.width, screenRect.size.height / aspect)
        let tHeight = max(screenRect.size.height, screenRect.size.width * aspect)

        for observation in results {
            guard let faceObservation = observation as? VNFaceObservation else { continue }

            var x1 = faceObservation.boundingBox.minY
            let y1 = faceObservation.boundingBox.minX - FUDGE_FACTOR
            var x2 = faceObservation.boundingBox.maxY
            let y2 = faceObservation.boundingBox.maxX - FUDGE_FACTOR
            if (frontCam) { // mirror'd video compensation
                x1 = 1 - x1
                x2 = 1 - x2
            }

            let s = frontCam ? SCALE_FACTOR_FRONT : SCALE_FACTOR
            let xc = (x1 + x2) / 2
            let yc = (y1 + y2) / 2
            let xl = xc + (x1 - xc) * s
            let xr = xc + (x2 - xc) * s
            let yl = yc + (y1 - yc) * s
            let yr = yc + (y2 - yc) * s

            let boxLayer = CALayer()
            boxLayer.frame = CGRect(
                x: xl * tWidth,
                y: yl * tHeight,
                width: (xr - xl) * tWidth,
                height: (yr - yl) * tHeight
            )
            boxLayer.borderWidth = 3.0
            boxLayer.borderColor = CGColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            boxLayer.cornerRadius = 10
            detectionLayer.addSublayer(boxLayer)
            photoCrop = faceObservation.boundingBox
            
            // only take and upload a photo if more than MIN_PHOTO_INTERVAL has passed
            let current_time = CACurrentMediaTime()
            if (current_time - last_time_photo_taken > MIN_PHOTO_INTERVAL) {
                last_time_photo_taken = current_time
                capturePhoto()
            }
        }
    }

    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()

        if let firstAvailablePreviewPhotoPixelFormatTypes = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: firstAvailablePreviewPhotoPixelFormatTypes]
        }

        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    var photoCrop: CGRect! = nil

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }

        // crop to correct subsection
        let xc = (photoCrop.minX + photoCrop.maxX) / 2
        let yc = 1.0 - (photoCrop.minY + photoCrop.maxY) / 2
        let w = max(photoCrop.maxY - photoCrop.minY, photoCrop.maxX - photoCrop.minX) * (frontCam ? SCALE_FACTOR_FRONT : SCALE_FACTOR)

        let cgImage: CGImage! = UIImage(data: data)?.cgImage?.cropping(to: CGRect(
            x: (xc - w / 2) * CGFloat(dimensions.width),
            y: (yc - w / 2) * CGFloat(dimensions.height),
            width: w * CGFloat(dimensions.width),
            height: w * CGFloat(dimensions.height)
        ))
                
        let image = UIImage(cgImage: cgImage!, scale: 1.0, orientation: .right)
        
        personView.image = image
        
        
        // @HENRI @SAN @SORAYA here just use
        // image.pngData()
        // or
        // image.jpegData(compressionQuality: ..., )
    }
}


// global variable marking the currently active view controller
var vc: CameraViewController! = nil;

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        vc = CameraViewController()
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
