import Vision
import AVFoundation
import UIKit

extension ViewController {
    
    func setupDetector() {
        self.requests = [VNDetectFaceRectanglesRequest(completionHandler: detectionDidComplete)]
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
        
        if (CGFloat(dimensions.width) == 0 || CGFloat(dimensions.height) == 0 || screenRect.size.width == 0 || screenRect.size.height == 0) { return }
        
//        // Transformations
//        let aspect = CGFloat(dimensions.height) / CGFloat(dimensions.width)
//        var tWidth: CGFloat = 0, tHeight: CGFloat = 0
//        
//        if (aspect < screenRect.size.height / screenRect.size.width) {
//            tWidth = screenRect.size.width
//            tHeight = screenRect.size.width * aspect
//        } else {
//            tWidth = screenRect.size.height / aspect
//            tHeight = screenRect.size.height
//        }
        
        for observation in results {
            guard let faceObservation = observation as? VNFaceObservation else { continue }
//            let tWidth = max(screenRect.size.width, screenRect.size.height * CGFloat(dimensions.width) / CGFloat(dimensions.height))
//            let tHeight = max(screenRect.size.height, screenRect.size.width * CGFloat(dimensions.height) / CGFloat(dimensions.width))
            
            let x1 = faceObservation.boundingBox.minY
            let y1 = faceObservation.boundingBox.minX
            let x2 = faceObservation.boundingBox.maxY
            let y2 = faceObservation.boundingBox.maxX
                        
//            let tWidth = max(screenRect.size.width, screenRect.size.height * CGFloat(dimensions.width / dimensions.height))
//            let tHeight = max(screenRect.size.height, screenRect.size.width * CGFloat(dimensions.height / dimensions.width))
            let tWidth = screenRect.size.width
            let tHeight = screenRect.size.height
                        
            let transformedBounds = CGRect(
                x: x1 * tWidth,
                y: y1 * tHeight,
                width: (x2 - x1) * tWidth,
                height: (y2 - y1) * tHeight
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
