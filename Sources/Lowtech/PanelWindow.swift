import Cocoa
import Foundation
import SwiftUI

// MARK: - PanelWindow

open class PanelWindow: LowtechWindow {
    // MARK: Lifecycle

    public convenience init(swiftuiView: AnyView, screen: NSScreen? = nil, corner: ScreenCorner? = nil) {
        self.init(contentViewController: NSHostingController(rootView: swiftuiView))

        screenPlacement = screen
        screenCorner = corner

        level = .floating
        setAccessibilityRole(.popover)
        setAccessibilitySubrole(.unknown)

        backgroundColor = .clear
        contentView?.bg = .clear
        isOpaque = false
        hasShadow = false
        styleMask = [.fullSizeContentView]
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
    }

    // MARK: Open

    override open var canBecomeKey: Bool { true }

    open func show(at point: NSPoint? = nil, animate: Bool = false, activate: Bool = true, corner: ScreenCorner? = nil, screen: NSScreen? = nil) {
        if let corner = corner {
            moveToScreen(screen, corner: corner, animate: animate)
        } else if let point = point {
            withAnim(animate: animate) { w in w.setFrameOrigin(point) }
        } else {
            withAnim(animate: animate) { w in w.center() }
        }

        wc.showWindow(nil)
        makeKeyAndOrderFront(nil)
        orderFrontRegardless()
        if activate {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
