import Vision
import AVFoundation
import UIKit

let FUDGE_FACTOR = 0.21 // there's some offset to one of the transforms I can't quite figure out.
                        // This compensates for that. Obviously not good for production, but it
                        // should be fine for a hackathon.

let SCALE_FACTOR = 2.4

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
        
        var aspect = CGFloat(dimensions.width) / CGFloat(dimensions.height)

        if (dimensions.height > dimensions.width) { aspect = 1.0 / aspect }
            
        let tWidth = max(screenRect.size.width, screenRect.size.height / aspect)
        let tHeight = max(screenRect.size.height, screenRect.size.width * aspect)
        
        for observation in results {
            guard let faceObservation = observation as? VNFaceObservation else { continue }
//            let tWidth = max(screenRect.size.width, screenRect.size.height * CGFloat(dimensions.width) / CGFloat(dimensions.height))
//            let tHeight = max(screenRect.size.height, screenRect.size.width * CGFloat(dimensions.height) / CGFloat(dimensions.width))
            
            let x1 = faceObservation.boundingBox.minY
            let y1 = faceObservation.boundingBox.minX - FUDGE_FACTOR
            let x2 = faceObservation.boundingBox.maxY
            let y2 = faceObservation.boundingBox.maxX - FUDGE_FACTOR
            
            let xc = (x1 + x2) / 2
            let yc = (y1 + y2) / 2
            let xl = xc + (x1 - xc) * SCALE_FACTOR
            let xr = xc + (x2 - xc) * SCALE_FACTOR
            let yl = yc + (y1 - yc) * SCALE_FACTOR
            let yr = yc + (y2 - yc) * SCALE_FACTOR
                        
//            let tWidth = max(screenRect.size.width, screenRect.size.height * CGFloat(dimensions.width / dimensions.height))
//            let tHeight = max(screenRect.size.height, screenRect.size.width * CGFloat(dimensions.height / dimensions.width))
            
            print("A:", faceObservation.boundingBox.minX + 0.25)
            print("B:", tWidth)
            print("C:", screenRect.size.width)

            let transformedBounds = CGRect(
                x: xl * tWidth,
                y: yl * tHeight,
                width: (xr - xl) * tWidth,
                height: (yr - yl) * tHeight
            )
            
            let boxLayer = self.drawBoundingBox(transformedBounds)
            

            detectionLayer.addSublayer(boxLayer)
        }
    }
    
    func setupLayers() {
        DispatchQueue.main.async { [weak self] in
            self!.detectionLayer = CALayer()
            self!.detectionLayer.frame = self!.view.frame
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
