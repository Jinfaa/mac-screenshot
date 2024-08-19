import Cocoa
import ScreenCaptureKit

class MyStreamOutput: NSObject, SCStreamOutput {
    private var capturedImage: CGImage?
    private let captureRect: NSRect
    
    init(captureRect: NSRect) {
        self.captureRect = captureRect
    }
    
    func captureImage() async throws -> CGImage {
        while capturedImage == nil {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        return capturedImage!
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen, let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        if let ioSurface = CVPixelBufferGetIOSurface(imageBuffer)?.takeUnretainedValue() {
            let ciImage = CIImage(ioSurface: ioSurface)
            let context = CIContext(options: [.useSoftwareRenderer: false, .highQualityDownsample: true, .outputColorSpace: CGColorSpaceCreateDeviceRGB(), .workingColorSpace: CGColorSpaceCreateDeviceRGB()])
            if let fullImage = context.createCGImage(ciImage, from: ciImage.extent) {
                capturedImage = fullImage.cropping(to: captureRect)
            }
        }
    }
}
