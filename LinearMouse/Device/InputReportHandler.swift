// MIT License
// Copyright (c) 2021-2026 LinearMouse

import CoreGraphics
import Foundation

typealias MouseButtonEmitter = (_ button: Int, _ down: Bool) -> Void

enum SyntheticMouseButtonEventEmitter {
    static func post(button: Int, down: Bool) {
        post(button: button, down: down, isHIDButton: false)
    }

    static func postHIDButton(button: Int, down: Bool) {
        post(button: button, down: down, isHIDButton: true)
    }

    private static func post(button: Int, down: Bool, isHIDButton: Bool) {
        guard let location = CGEvent(source: nil)?.location,
              let event = makeEvent(
                  button: button,
                  down: down,
                  location: location,
                  flags: ModifierState.normalize(ModifierState.shared.currentFlags),
                  isHIDButton: isHIDButton
              ) else {
            return
        }
        event.post(tap: .cghidEventTap)
    }

    static func makeEvent(
        button: Int, down: Bool, location: CGPoint, flags: CGEventFlags, isHIDButton: Bool
    ) -> CGEvent? {
        guard let buttonNumber = UInt32(exactly: button),
              let mouseButton = CGMouseButton(rawValue: buttonNumber),
              let event = CGEvent(
                  mouseEventSource: nil,
                  mouseType: down ? .otherMouseDown : .otherMouseUp,
                  mouseCursorPosition: location,
                  mouseButton: mouseButton
              ) else {
            return nil
        }

        event.flags = flags
        event.setIntegerValueField(.mouseEventButtonNumber, value: Int64(button))
        if isHIDButton {
            event.isLinearMouseHIDButtonEvent = true
        } else {
            event.isLinearMouseSyntheticEvent = true
        }
        return event
    }
}

/// Context passed through the handler chain
class InputReportContext {
    let report: Data
    var lastButtonStates: UInt8

    init(report: Data, lastButtonStates: UInt8) {
        self.report = report
        self.lastButtonStates = lastButtonStates
    }
}

protocol InputReportHandler {
    /// Check if this handler should be used for the given device
    func matches(vendorID: Int, productID: Int) -> Bool

    /// Check if this handler should be used when the product name is needed to tell apart
    /// devices that share a vendor and product ID. Handlers that do not care about the name
    /// keep the default, which ignores it.
    func matches(vendorID: Int, productID: Int, productName: String?) -> Bool

    /// Whether report observation is needed regardless of button count
    /// Most devices only need observation when buttonCount == 3
    func alwaysNeedsReportObservation() -> Bool

    /// Handle input report and simulate button events as needed
    /// Call `next(context)` to pass control to the next handler in the chain
    func handleReport(_ context: InputReportContext, next: (InputReportContext) -> Void)

    /// Release synthetic buttons before report processing is suspended or the
    /// device disappears. Native HID buttons are not represented here.
    func releasePressedButtons(_ context: InputReportContext)
}

extension InputReportHandler {
    func matches(vendorID: Int, productID: Int, productName _: String?) -> Bool {
        matches(vendorID: vendorID, productID: productID)
    }

    func alwaysNeedsReportObservation() -> Bool {
        false
    }
}

enum InputReportHandlerRegistry {
    static let handlers: [InputReportHandler] = [
        GenericSideButtonHandler(),
        KensingtonSlimbladeHandler(),
        ElecomTrackballHandler()
    ]

    static func handlers(for vendorID: Int, productID: Int, productName: String? = nil) -> [InputReportHandler] {
        handlers.filter { $0.matches(vendorID: vendorID, productID: productID, productName: productName) }
    }
}
