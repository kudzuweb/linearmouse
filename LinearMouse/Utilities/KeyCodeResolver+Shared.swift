// MIT License
// Copyright (c) 2021-2026 LinearMouse

import KeyKit

extension KeyCodeResolver {
    /// Observes input source changes, so one instance serves the whole app.
    static let shared = KeyCodeResolver()
}
