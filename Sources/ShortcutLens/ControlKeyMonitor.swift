import AppKit
import CoreGraphics

final class ControlKeyMonitor {
    var onControlChanged: ((Bool) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var triggerIsDown = false
    private var releaseWatchdog: Timer?

    var hasInputMonitoringPermission: Bool {
        CGPreflightListenEventAccess()
    }

    @discardableResult
    func requestInputMonitoringPermission() -> Bool {
        CGRequestListenEventAccess()
    }

    func start() {
        guard eventTap == nil else { return }

        if !CGPreflightListenEventAccess() {
            _ = CGRequestListenEventAccess()
        }

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<ControlKeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            monitor.handle(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: context
        )

        guard let eventTap else { return }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    func stop() {
        stopReleaseWatchdog()
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: false) }
        runLoopSource = nil
        eventTap = nil
    }

    private func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return
        }

        let trigger = TriggerKey.selected
        guard event.getIntegerValueField(.keyboardEventKeycode) == trigger.keyCode else { return }
        let isDown = event.flags.contains(trigger.eventFlag)
        publishControlState(isDown)
    }

    private func publishControlState(_ isDown: Bool) {
        guard isDown != triggerIsDown else { return }
        triggerIsDown = isDown
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if isDown {
                self.startReleaseWatchdog()
            } else {
                self.stopReleaseWatchdog()
            }
            self.onControlChanged?(isDown)
        }
    }

    private func startReleaseWatchdog() {
        stopReleaseWatchdog()
        let timer = Timer(timeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self else { return }
            let flags = CGEventSource.flagsState(.combinedSessionState)
            if !flags.contains(TriggerKey.selected.eventFlag) {
                self.publishControlState(false)
            }
        }
        timer.tolerance = 0.01
        RunLoop.main.add(timer, forMode: .common)
        releaseWatchdog = timer
    }

    private func stopReleaseWatchdog() {
        releaseWatchdog?.invalidate()
        releaseWatchdog = nil
    }
}
