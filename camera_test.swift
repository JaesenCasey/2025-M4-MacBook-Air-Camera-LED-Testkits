import AVFoundation
import Foundation
import CoreImage
import AppKit

class FrameGrabber: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()
    var outputPath = ""
    var captured = false
    let ciContext = CIContext()

    func run(path: String, durationMs: Double) {
        outputPath = path

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("RESULT capture=false reason=no_device")
            exit(1)
        }

        session.addInput(input)
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "framequeue"))
        session.addOutput(output)

        let t0 = Date()
        session.startRunning()
        let t1 = Date()
        print("session_start_offset_ms=\(t1.timeIntervalSince(t0)*1000)")

        DispatchQueue.main.asyncAfter(deadline: .now() + durationMs / 1000.0) { [weak self] in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(t0) * 1000
            if !self.captured {
                print("RESULT capture=false elapsed_ms=\(elapsed) requested_ms=\(durationMs)")
            }
            self.session.stopRunning()
            exit(self.captured ? 0 : 2)
        }

        RunLoop.main.run()
    }

    func captureOutput(_ output: AVCaptureOutput,
                        didOutput sampleBuffer: CMSampleBuffer,
                        from connection: AVCaptureConnection) {
        guard !captured, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .jpeg, properties: [:]) else { return }

        try? data.write(to: URL(fileURLWithPath: outputPath))
        captured = true
        print("RESULT capture=true path=\(outputPath)")
    }
}

let args = CommandLine.arguments
guard args.count > 2, let durationMs = Double(args[2]) else {
    print("usage: ./grab <output.jpg> <duration_ms>")
    exit(1)
}
let grabber = FrameGrabber()
grabber.run(path: args[1], durationMs: durationMs)