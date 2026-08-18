for i in 1...10 {
    let t0 = Date()
    session.startRunning()
    // wait for first frame via delegate, record time-to-first-frame
    // ...
    session.stopRunning()
    let t1 = Date()
    print("iteration \(i): startup_to_frame_ms=\((t1.timeIntervalSince(t0))*1000)")
}