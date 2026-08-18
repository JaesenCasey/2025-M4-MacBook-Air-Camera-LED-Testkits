import AVFoundation
import Foundation

final class LEDTimingTester: NSObject {
    let session = AVCaptureSession()
    var logHandle: FileHandle?

    func log(_ s: String) {
        print(s)
        if let handle = logHandle, let d = (s + "\n").data(using: .utf8) {
            handle.write(d)
        }
    }

    let output = AVCaptureVideoDataOutput()

    func configure() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            log("ERROR: no camera device found")
            exit(1)
        }
        log("using device: \(device.localizedName)")
        session.addInput(input)
        // An output must be attached for the capture pipeline to fully
        // engage the sensor -- an input-only session may not reliably
        // power the camera. We don't need a delegate; just attaching
        // the output is enough to give the session a real consumer.
        session.addOutput(output)
    }

    // Throwaway cycles to warm the session (per prior findings: first
    // startRunning() call is much slower than subsequent ones).
    func warmUp(cycles: Int) {
        log("=== warm-up phase: \(cycles) cycles ===")
        for i in 1...cycles {
            let t0 = Date()
            session.startRunning()
            Thread.sleep(forTimeInterval: 0.2)
            session.stopRunning()
            log("warmup cycle \(i) took \((Date().timeIntervalSince(t0))*1000)ms total")
            Thread.sleep(forTimeInterval: 1.0)
        }
    }

    // Reaction-time calibration: NOT camera related. Prints a line at a
    // random delay, measures time until the user presses Enter.
    func calibrate(trials: Int) -> Double {
        log("=== calibration phase: \(trials) trials ===")
        var times: [Double] = []
        for i in 1...trials {
            let delay = Double.random(in: 1.5...4.0)
            Thread.sleep(forTimeInterval: delay)
            let t0 = Date()
            log("calibration trial \(i): press Enter NOW")
            _ = readLine()
            let reaction = Date().timeIntervalSince(t0) * 1000
            log("calibration trial \(i): reaction_ms=\(reaction)")
            times.append(reaction)
        }
        let avg = times.reduce(0, +) / Double(times.count)
        log("calibration baseline (avg reaction time) = \(avg)ms")
        return avg
    }

    // Actual timed test: hold the session open for durationMs, stop it,
    // then measure time until the user reports the LED going off.
    func runTrial(index: Int, durationMs: Double, baseline: Double) {
        let t0 = Date()
        session.startRunning()
        Thread.sleep(forTimeInterval: durationMs / 1000.0)
        session.stopRunning()
        let stopReturned = Date()

        log("trial \(index): duration_requested_ms=\(durationMs) stop_called_at_offset_ms=\((stopReturned.timeIntervalSince(t0))*1000)")
        log("trial \(index): press Enter the INSTANT you see the LED go off")

        let tStop = Date()
        _ = readLine()
        let rawMs = Date().timeIntervalSince(tStop) * 1000
        let adjusted = rawMs - baseline

        log("trial \(index): raw_ms=\(rawMs) baseline_ms=\(baseline) adjusted_led_off_latency_ms=\(adjusted)")
        Thread.sleep(forTimeInterval: 1.5) // brief gap before next trial
    }
}

// ---- main ----

let args = CommandLine.arguments
guard args.count > 4 else {
    print("usage: ./ledtest <calibrationTrials> <trialsPerDuration> <durationsMs comma-separated> <outputPrefix>")
    print("example: ./ledtest 5 3 100,200,300,500 run1")
    exit(1)
}
guard let calibrationTrials = Int(args[1]),
      let trialsPerDuration = Int(args[2]) else {
    print("bad numeric arguments")
    exit(1)
}
let durations = args[3].split(separator: ",").compactMap { Double($0) }
guard !durations.isEmpty else {
    print("no valid durations parsed")
    exit(1)
}
let prefix = args[4]

let logPath = "\(prefix)_led_timing_log.txt"
FileManager.default.createFile(atPath: logPath, contents: nil)
guard let logHandle = FileHandle(forWritingAtPath: logPath) else {
    print("could not open log file")
    exit(1)
}

let tester = LEDTimingTester()
tester.logHandle = logHandle
tester.configure()

tester.log("=== LED timing test run \(Date()) ===")
tester.log("calibrationTrials=\(calibrationTrials) trialsPerDuration=\(trialsPerDuration) durations=\(durations) prefix=\(prefix)")

tester.warmUp(cycles: 3)
let baseline = tester.calibrate(trials: calibrationTrials)

tester.log("=== test phase ===")
var trialIndex = 1
for d in durations {
    for _ in 1...trialsPerDuration {
        tester.runTrial(index: trialIndex, durationMs: d, baseline: baseline)
        trialIndex += 1
    }
}

tester.log("=== test complete ===")