import AVFoundation
import Foundation
import CoreImage
import AppKit

final class WarmStartTester: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()
    let ciContext = CIContext()
    let lock = NSLock()

    var captured = false
    var frameCount = 0
    var skipFrames = 5
    var currentOutputPath = ""
    var frameSemaphore = DispatchSemaphore(value: 0)
    var logHandle: FileHandle?

    func log(_ s: String) {
        print(s)
        if let handle = logHandle, let d = (s + "\n").data(using: .utf8) {
            handle.write(d)
        }
    }

    func configure() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            log("ERROR: no camera device found")
            exit(1)
        }
        log("using device: \(device.localizedName)")
        session.addInput(input)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "framequeue"))
        session.addOutput(output)
    }

    func runIteration(_ index: Int, path: String, skip: Int, timeoutMs: Double) {
        lock.lock()
        captured = false
        frameCount = 0
        skipFrames = skip
        currentOutputPath = path
        lock.unlock()

        frameSemaphore = DispatchSemaphore(value: 0)

        let t0 = Date()
        session.startRunning()
        let startOffset = Date().timeIntervalSince(t0) * 1000
        log("iteration \(index): startRunning() call returned after \(startOffset)ms")

        let waitResult = frameSemaphore.wait(timeout: .now() + timeoutMs / 1000.0)
        let elapsed = Date().timeIntervalSince(t0) * 1000

        if waitResult == .success {
            log("iteration \(index): RESULT capture=true elapsed_ms=\(elapsed) path=\(path)")
        } else {
            log("iteration \(index): RESULT capture=false elapsed_ms=\(elapsed) (timeout)")
        }

        let tStop0 = Date()
        session.stopRunning()
        let stopElapsed = Date().timeIntervalSince(tStop0) * 1000
        log("iteration \(index): stopRunning() call took \(stopElapsed)ms")
    }

    func captureOutput(_ output: AVCaptureOutput,
                        didOutput sampleBuffer: CMSampleBuffer,
                        from connection: AVCaptureConnection) {
        lock.lock()
        if captured {
            lock.unlock()
            return
        }
        frameCount += 1
        if frameCount <= skipFrames {
            lock.unlock()
            return
        }
        lock.unlock()

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .jpeg, properties: [:]) else { return }

        lock.lock()
        if captured {
            lock.unlock()
            return
        }
        captured = true
        lock.unlock()

        try? data.write(to: URL(fileURLWithPath: currentOutputPath))
        frameSemaphore.signal()
    }
}

// ---- main ----

let args = CommandLine.arguments
guard args.count > 4 else {
    print("usage: ./warmtest <iterations> <skipFrames> <pauseSeconds> <outputPrefix>")
    exit(1)
}
guard let iterations = Int(args[1]),
      let skipFrames = Int(args[2]),
      let pauseSeconds = Double(args[3]) else {
    print("bad arguments")
    exit(1)
}
let prefix = args[4]

let logPath = "\(prefix)_warmstart_log.txt"
FileManager.default.createFile(atPath: logPath, contents: nil)
guard let logHandle = FileHandle(forWritingAtPath: logPath) else {
    print("could not open log file")
    exit(1)
}

let tester = WarmStartTester()
tester.logHandle = logHandle
tester.configure()

tester.log("=== warm-start test run \(Date()) ===")
tester.log("iterations=\(iterations) skipFrames=\(skipFrames) pauseSeconds=\(pauseSeconds)")

for i in 1...iterations {
    let path = "\(prefix)_iter\(i).jpg"
    tester.runIteration(i, path: path, skip: skipFrames, timeoutMs: 5000)

    tester.log("--- pausing \(pauseSeconds)s before next iteration ---")
    Thread.sleep(forTimeInterval: pauseSeconds)

    print("During that pause, did the LED turn fully OFF, stay ON continuously, or something else (blink/flicker)?")
    print("Type: off / on / blink / other, then press enter:")
    let response = readLine() ?? "no_response"
    tester.log("iteration \(i) -> pause_observation=\(response)")
}

tester.log("=== test complete ===")