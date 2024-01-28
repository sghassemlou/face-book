import Vision
import AVFoundation
import UIKit

extension ViewController {
    
    func setupDetector() {
        let modelURL = YOLOv3Int8LUT.urlOfModelInThisBundle

        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
            self.requests = [recognitions]
        } catch let error {
            print(error)
        }
    }
    
    func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.extractDetections(results)
            }
        })
    }
    
    func extractDetections(_ results: [VNObservation]) {
        detectionLayer.sublayers = nil
        
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            
            // Transformations
            let tWidth = max(screenRect.size.width, screenRect.size.height * CGFloat(dimensions.width / dimensions.height))
            let tHeight = max(screenRect.size.height, screenRect.size.width * CGFloat(dimensions.height / dimensions.width))
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(tWidth), Int(tHeight))
            
            let transformedBounds = CGRect(
                x: objectBounds.minX,
                y: objectBounds.minY,
                width: objectBounds.maxX - objectBounds.minX,
                height: objectBounds.maxY - objectBounds.minY
            )
            
            let boxLayer = self.drawBoundingBox(transformedBounds)

            detectionLayer.addSublayer(boxLayer)
        }
    }
    
    func setupLayers() {
        DispatchQueue.main.async { [weak self] in
            self!.detectionLayer = CALayer()
            self!.detectionLayer.frame = CGRect(x: 0, y: 0, width: self!.view.frame.size.width, height: self!.view.frame.size.height)
            self!.view.layer.addSublayer(self!.detectionLayer)
        }
    }
    
    func drawBoundingBox(_ bounds: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = bounds
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = CGColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        boxLayer.cornerRadius = 10
        return boxLayer
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
}
