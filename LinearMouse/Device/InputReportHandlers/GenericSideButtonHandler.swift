// MIT License
// Copyright (c) 2021-2026 LinearMouse

import Foundation

/// Handles side button fixes for devices that report only 3 buttons in HID descriptor
/// but actually have side buttons (button 3 and 4).
///
/// Supported devices:
/// - Mi Dual Mode Wireless Mouse Silent Edition (0x2717:0x5014)
/// - Delux M729DB mouse (0x248A:0x8266)
struct GenericSideButtonHandler: InputReportHandler {
    private struct Product {
        let vendorID: Int
        let productID: Int
        var excludedProductNames: Set<String> = []
    }

    private static let supportedProducts: [Product] = [
        .init(vendorID: 0x2717, productID: 0x5014), // Mi Silent Mouse
        // The Delux's product string is not documented upstream, so the rule is an exclusion: the
        // Sanwa 400-MABT156 ring mouse reports the same IDs and must not get this quirk.
        // A device that reports no product name keeps the quirk.
        .init(vendorID: 0x248A, productID: 0x8266, excludedProductNames: ["GMABT156BK6-1"]) // Delux M729DB mouse
    ]

    private let emit: MouseButtonEmitter

    init(emit: @escaping MouseButtonEmitter = SyntheticMouseButtonEventEmitter.postHIDButton) {
        self.emit = emit
    }

    func matches(vendorID: Int, productID: Int) -> Bool {
        matches(vendorID: vendorID, productID: productID, productName: nil)
    }

    func matches(vendorID: Int, productID: Int, productName: String?) -> Bool {
        Self.supportedProducts.contains {
            $0.vendorID == vendorID && $0.productID == productID
                && !($0.excludedProductNames.contains(productName ?? ""))
        }
    }

    func handleReport(_ context: InputReportContext, next: (InputReportContext) -> Void) {
        defer { next(context) }

        guard context.report.count >= 2 else {
            return
        }

        // Report format: | Button 0 (1 bit) | ... | Button 4 (1 bit) | Not Used (3 bits) |
        // We only care about bits 3 and 4 (side buttons)
        let buttonStates = context.report[1] & 0x18
        let toggled = context.lastButtonStates ^ buttonStates

        guard toggled != 0 else {
            return
        }

        for button in 3 ... 4 {
            guard toggled & (1 << button) != 0 else {
                continue
            }
            let down = buttonStates & (1 << button) != 0
            emit(button, down)
        }

        context.lastButtonStates = buttonStates
    }

    func releasePressedButtons(_ context: InputReportContext) {
        for button in 3 ... 4 where context.lastButtonStates & (1 << button) != 0 {
            emit(button, false)
        }
        context.lastButtonStates &= ~0x18
    }
}
