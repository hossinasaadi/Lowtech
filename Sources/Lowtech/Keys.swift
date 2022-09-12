//
//  Keys.swift
//
//
//  Created by Alin Panaitiu on 21.01.2022.
//

import Combine
import Defaults
import Foundation
import Magnet
import Sauce
import SwiftUI

// MARK: - KeysManager

public class KeysManager: ObservableObject {
    // MARK: Lifecycle

    init() {
        if !primaryKeyModifiers.isEmpty, !primaryKeyModifiers.sideIndependentModifiers.contains(.option) {
            altKeyModifiers = primaryKeyModifiers + [.ralt]
        }

        if !primaryKeyModifiers.isEmpty, !primaryKeyModifiers.sideIndependentModifiers.contains(.shift) {
            rightShiftKeyModifiers = primaryKeyModifiers + [.rshift]
            leftShiftKeyModifiers = primaryKeyModifiers + [.lshift]
        }

        if !secondaryKeyModifiers.isEmpty, !secondaryKeyModifiers.sideIndependentModifiers.contains(.option) {
            secondaryAltKeyModifiers = secondaryKeyModifiers + [.ralt]
        }

        if !secondaryKeyModifiers.isEmpty, !secondaryKeyModifiers.sideIndependentModifiers.contains(.shift) {
            secondaryRightShiftKeyModifiers = secondaryKeyModifiers + [.rshift]
            secondaryLeftShiftKeyModifiers = secondaryKeyModifiers + [.lshift]
        }

        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { notification in
                self.recheckFlags()
            }.store(in: &observers)
    }

    // MARK: Open

    @Published open var primaryHotkeysRegistered = false
    @Published open var secondaryHotkeysRegistered = false

    @Published open var altHotkeysRegistered = false
    @Published open var rightShiftHotkeysRegistered = false
    @Published open var leftShiftHotkeysRegistered = false

    @Published open var secondaryAltHotkeysRegistered = false
    @Published open var secondaryRightShiftHotkeysRegistered = false
    @Published open var secondaryLeftShiftHotkeysRegistered = false

    @Published open var specialHotkeyRegistered = false

    open var initialized = false {
        didSet {
            guard initialized else { return }
            computeKeyModifiers()
        }
    }

    open func flagsChanged(modifierFlags: NSEvent.ModifierFlags) {
        KM.lastModifierFlags = modifierFlags

        KM.rcmd = modifierFlags.contains(.rightCommand)
        KM.ralt = modifierFlags.contains(.rightOption)
        KM.rshift = modifierFlags.contains(.rightShift)
        KM.rctrl = modifierFlags.contains(.rightControl)

        KM.lcmd = modifierFlags.contains(.leftCommand)
        KM.lalt = modifierFlags.contains(.leftOption)
        KM.lshift = modifierFlags.contains(.leftShift)
        KM.lctrl = modifierFlags.contains(.leftControl)

        KM.fn = modifierFlags.contains(.fn)
        KM.flags = modifierFlags.triggerKeys

        if specialKeyModifiers.allPressed {
            registerSpecialHotkey()
        } else {
            unregisterSpecialHotkey()
        }
        if primaryKeyModifiers.allPressed {
            registerPrimaryHotkeys()
        } else {
            unregisterPrimaryHotkeys()
        }
        if secondaryKeyModifiers.allPressed {
            registerSecondaryHotkeys()
        } else {
            unregisterSecondaryHotkeys()
        }
        if altKeyModifiers.allPressed {
            registerAltHotkeys()
        } else {
            unregisterAltHotkeys()
        }
        if rightShiftKeyModifiers.allPressed {
            registerRightShiftHotkeys()
        } else {
            unregisterRightShiftHotkeys()
        }
        if leftShiftKeyModifiers.allPressed {
            registerLeftShiftHotkeys()
        } else {
            unregisterLeftShiftHotkeys()
        }

        if secondaryAltKeyModifiers.allPressed {
            registerSecondaryAltHotkeys()
        } else {
            unregisterSecondaryAltHotkeys()
        }
        if secondaryRightShiftKeyModifiers.allPressed {
            registerSecondaryRightShiftHotkeys()
        } else {
            unregisterSecondaryRightShiftHotkeys()
        }
        if secondaryLeftShiftKeyModifiers.allPressed {
            registerSecondaryLeftShiftHotkeys()
        } else {
            unregisterSecondaryLeftShiftHotkeys()
        }

        guard !KM.flags.isEmpty else { return }
        if let taps = KM.multiTap[KM.flags], let tapTime = KM.multiTapTime[KM.flags], timeSince(tapTime) <= KeysManager.MULTI_TAP_THRESHOLD_INTERVAL {
            KM.multiTap[KM.flags] = taps + 1
            KM.multiTapPublisher.send((KM.flags, taps + 1))
        } else {
            KM.multiTap[KM.flags] = 1
            KM.multiTapPublisher.send((KM.flags, 1))
        }
        KM.multiTapTime[KM.flags] = Date()

        onFlagsChanged?(modifierFlags)
    }

    open func registerSpecialHotkey() {
        onRegisterSpecialHotkey?()

        guard let specialHotkey = specialHotkey, !specialHotkeyRegistered, !SWIFTUI_PREVIEW else { return }
        specialHotkey.register()
        specialHotkeyRegistered = true
    }

    open func unregisterSpecialHotkey() {
        onUnregisterSpecialHotkey?()

        guard let specialHotkey = specialHotkey, specialHotkeyRegistered else { return }
        specialHotkey.unregister()
        specialHotkeyRegistered = false
    }

    open func registerPrimaryHotkeys() {
        onRegisterPrimaryHotkeys?()

        guard !primaryHotkeys.isEmpty, !primaryHotkeysRegistered, !SWIFTUI_PREVIEW else { return }
        debug("registerPrimaryHotkeys")
        primaryHotkeys.forEach { $0.register() }
        primaryHotkeysRegistered = true
    }

    open func unregisterPrimaryHotkeys() {
        onUnregisterPrimaryHotkeys?()

        guard !primaryHotkeys.isEmpty, primaryHotkeysRegistered else { return }
        debug("unregisterPrimaryHotkeys")
        primaryHotkeys.forEach { $0.unregister() }
        primaryHotkeysRegistered = false
    }

    open func registerSecondaryHotkeys() {
        onRegisterSecondaryHotkeys?()

        guard !secondaryHotkeys.isEmpty, !secondaryHotkeysRegistered, !SWIFTUI_PREVIEW else { return }
        secondaryHotkeys.forEach { $0.register() }
        secondaryHotkeysRegistered = true
    }

    open func unregisterSecondaryHotkeys() {
        onUnregisterSecondaryHotkeys?()

        guard !secondaryHotkeys.isEmpty, secondaryHotkeysRegistered else { return }
        secondaryHotkeys.forEach { $0.unregister() }
        secondaryHotkeysRegistered = false
    }

    open func registerRightShiftHotkeys() {
        onRegisterRightShiftHotkeys?()

        guard !rightShiftHotkeys.isEmpty, !rightShiftHotkeysRegistered, !rightShiftHotkeys.isEmpty, !SWIFTUI_PREVIEW else { return }
        rightShiftHotkeys.forEach { $0.register() }
        rightShiftHotkeysRegistered = true
    }

    open func unregisterRightShiftHotkeys() {
        onUnregisterRightShiftHotkeys?()

        guard !rightShiftHotkeys.isEmpty, rightShiftHotkeysRegistered else { return }
        rightShiftHotkeys.forEach { $0.unregister() }
        rightShiftHotkeysRegistered = false
    }

    open func registerLeftShiftHotkeys() {
        onRegisterLeftShiftHotkeys?()

        guard !leftShiftHotkeys.isEmpty, !leftShiftHotkeysRegistered, !leftShiftHotkeys.isEmpty, !SWIFTUI_PREVIEW else { return }
        leftShiftHotkeys.forEach { $0.register() }
        leftShiftHotkeysRegistered = true
    }

    open func unregisterLeftShiftHotkeys() {
        onUnregisterLeftShiftHotkeys?()

        guard !leftShiftHotkeys.isEmpty, leftShiftHotkeysRegistered else { return }
        leftShiftHotkeys.forEach { $0.unregister() }
        leftShiftHotkeysRegistered = false
    }

    open func registerAltHotkeys() {
        onRegisterAltHotkeys?()

        guard !altHotkeys.isEmpty, !altHotkeysRegistered, !altHotkeys.isEmpty, !SWIFTUI_PREVIEW else { return }
        altHotkeys.forEach { $0.register() }
        altHotkeysRegistered = true
    }

    open func unregisterAltHotkeys() {
        onUnregisterAltHotkeys?()

        guard !altHotkeys.isEmpty, altHotkeysRegistered else { return }
        altHotkeys.forEach { $0.unregister() }
        altHotkeysRegistered = false
    }

    open func registerSecondaryRightShiftHotkeys() {
        onRegisterSecondaryRightShiftHotkeys?()

        guard !secondaryRightShiftHotkeys.isEmpty, !secondaryRightShiftHotkeysRegistered, !secondaryRightShiftHotkeys.isEmpty, !SWIFTUI_PREVIEW else { return }
        secondaryRightShiftHotkeys.forEach { $0.register() }
        secondaryRightShiftHotkeysRegistered = true
    }

    open func unregisterSecondaryRightShiftHotkeys() {
        onUnregisterSecondaryRightShiftHotkeys?()

        guard !secondaryRightShiftHotkeys.isEmpty, secondaryRightShiftHotkeysRegistered else { return }
        secondaryRightShiftHotkeys.forEach { $0.unregister() }
        secondaryRightShiftHotkeysRegistered = false
    }

    open func registerSecondaryLeftShiftHotkeys() {
        onRegisterSecondaryLeftShiftHotkeys?()

        guard !secondaryLeftShiftHotkeys.isEmpty, !secondaryLeftShiftHotkeysRegistered, !secondaryLeftShiftHotkeys.isEmpty, !SWIFTUI_PREVIEW else { return }
        secondaryLeftShiftHotkeys.forEach { $0.register() }
        secondaryLeftShiftHotkeysRegistered = true
    }

    open func unregisterSecondaryLeftShiftHotkeys() {
        onUnregisterSecondaryLeftShiftHotkeys?()

        guard !secondaryLeftShiftHotkeys.isEmpty, secondaryLeftShiftHotkeysRegistered else { return }
        secondaryLeftShiftHotkeys.forEach { $0.unregister() }
        secondaryLeftShiftHotkeysRegistered = false
    }

    open func registerSecondaryAltHotkeys() {
        onRegisterSecondaryAltHotkeys?()

        guard !secondaryAltHotkeys.isEmpty, !secondaryAltHotkeysRegistered, !secondaryAltHotkeys.isEmpty, !SWIFTUI_PREVIEW else { return }
        secondaryAltHotkeys.forEach { $0.register() }
        secondaryAltHotkeysRegistered = true
    }

    open func unregisterSecondaryAltHotkeys() {
        onUnregisterSecondaryAltHotkeys?()

        guard !secondaryAltHotkeys.isEmpty, secondaryAltHotkeysRegistered else { return }
        secondaryAltHotkeys.forEach { $0.unregister() }
        secondaryAltHotkeysRegistered = false
    }

    // MARK: Public

    public var onFlagsChanged: ((NSEvent.ModifierFlags) -> Void)?
    public var onSpecialHotkey: (() -> Void)?
    public var onPrimaryHotkey: ((String) -> Void)?
    public var onSecondaryHotkey: ((String) -> Void)?

    public var onAltHotkey: ((String) -> Void)?
    public var onRightShiftHotkey: ((String) -> Void)?
    public var onLeftShiftHotkey: ((String) -> Void)?

    public var onSecondaryAltHotkey: ((String) -> Void)?
    public var onSecondaryRightShiftHotkey: ((String) -> Void)?
    public var onSecondaryLeftShiftHotkey: ((String) -> Void)?

    public var onRegisterSpecialHotkey: (() -> Void)?
    public var onUnregisterSpecialHotkey: (() -> Void)?
    public var onRegisterPrimaryHotkeys: (() -> Void)?
    public var onUnregisterPrimaryHotkeys: (() -> Void)?
    public var onRegisterSecondaryHotkeys: (() -> Void)?
    public var onUnregisterSecondaryHotkeys: (() -> Void)?

    public var onRegisterRightShiftHotkeys: (() -> Void)?
    public var onUnregisterRightShiftHotkeys: (() -> Void)?
    public var onRegisterLeftShiftHotkeys: (() -> Void)?
    public var onUnregisterLeftShiftHotkeys: (() -> Void)?
    public var onRegisterAltHotkeys: (() -> Void)?
    public var onUnregisterAltHotkeys: (() -> Void)?

    public var onRegisterSecondaryRightShiftHotkeys: (() -> Void)?
    public var onUnregisterSecondaryRightShiftHotkeys: (() -> Void)?
    public var onRegisterSecondaryLeftShiftHotkeys: (() -> Void)?
    public var onUnregisterSecondaryLeftShiftHotkeys: (() -> Void)?
    public var onRegisterSecondaryAltHotkeys: (() -> Void)?
    public var onUnregisterSecondaryAltHotkeys: (() -> Void)?

    @Published public var rcmd = false
    @Published public var ralt = false
    @Published public var rshift = false
    @Published public var rctrl = false
    @Published public var lcmd = false
    @Published public var lalt = false
    @Published public var lctrl = false
    @Published public var lshift = false
    @Published public var fn = false
    @Published public var flags = [TriggerKey]()
    @Published public var lastModifierFlags: NSEvent.ModifierFlags = NSEvent.modifierFlags

    @Published public var testKeyHandler: (() -> Void)? = nil
    @Published public var testKeyCombo: KeyCombo? = nil
    @Published public var testKeyPressed = false
    @Published public var testKeyForward = false

    @Published public var multiTap = [[TriggerKey]: Int]()
    @Published public var multiTapTime = [[TriggerKey]: Date]()
    public var multiTapPublisher = PassthroughSubject<([TriggerKey], Int), Never>()

    public lazy var specialKeyIdentifier = "SPECIAL_KEY\(specialKey)"

    public var primaryKeys: [String] = []
    public var secondaryKeys: [String] = []

    public var altKeys: [String] = []
    public var rightShiftKeys: [String] = []
    public var leftShiftKeys: [String] = []

    public var secondaryAltKeys: [String] = []
    public var secondaryRightShiftKeys: [String] = []
    public var secondaryLeftShiftKeys: [String] = []

    public var globalEventMonitor: GlobalEventMonitor!
    public var localEventMonitor: LocalEventMonitor!
    public var observers: Set<AnyCancellable> = []

    @Published public var disabledAltKeys = false
    @Published public var disabledRightShiftKeys = false
    @Published public var disabledLeftShiftKeys = false

    @Published public var disabledSecondaryAltKeys = false
    @Published public var disabledSecondaryRightShiftKeys = false
    @Published public var disabledSecondaryLeftShiftKeys = false

    @Published public var testHotkey: HotKey? = nil {
        didSet {
            if let testHotkey = testHotkey, oldValue == nil {
                testHotkey.register()
            }
            if let oldValue = oldValue, testHotkey == nil {
                oldValue.unregister()
            }
        }
    }

    @Published public var altKeyModifiers: [TriggerKey] = [] {
        didSet {
            disabledAltKeys = altKeyModifiers.isEmpty
        }
    }

    @Published public var rightShiftKeyModifiers: [TriggerKey] = [] {
        didSet {
            disabledRightShiftKeys = rightShiftKeyModifiers.isEmpty
        }
    }

    @Published public var leftShiftKeyModifiers: [TriggerKey] = [] {
        didSet {
            disabledLeftShiftKeys = leftShiftKeyModifiers.isEmpty
        }
    }

    @Published public var secondaryAltKeyModifiers: [TriggerKey] = [] {
        didSet {
            disabledSecondaryAltKeys = secondaryAltKeyModifiers.isEmpty
        }
    }

    @Published public var secondaryRightShiftKeyModifiers: [TriggerKey] = [] {
        didSet {
            disabledSecondaryRightShiftKeys = secondaryRightShiftKeyModifiers.isEmpty
        }
    }

    @Published public var secondaryLeftShiftKeyModifiers: [TriggerKey] = [] {
        didSet {
            disabledSecondaryLeftShiftKeys = secondaryLeftShiftKeyModifiers.isEmpty
        }
    }

    @Published public var primaryKeyModifiers: [TriggerKey] = [] {
        didSet {
            reinitHotkeys()
        }
    }

    @Published public var secondaryKeyModifiers: [TriggerKey] = [] {
        didSet {
            reinitHotkeys()
        }
    }

    @Published public var specialKeyModifiers: [TriggerKey] = [.ralt, .rshift] {
        didSet {
            reinitHotkeys()
        }
    }

    @Published public var specialKey = "" {
        didSet {
            reinitHotkeys()
        }
    }

    public var primaryHotkeys: [HotKey] = [] {
        didSet {
            guard initialized else { return }
            oldValue.forEach { $0.unregister() }
        }
    }

    public var secondaryHotkeys: [HotKey] = [] {
        didSet {
            guard initialized else { return }
            oldValue.forEach { $0.unregister() }
        }
    }

    public var altHotkeys: [HotKey] = [] {
        didSet {
            guard initialized else { return }
            oldValue.forEach { $0.unregister() }
        }
    }

    public var rightShiftHotkeys: [HotKey] = [] {
        didSet {
            guard initialized else { return }
            oldValue.forEach { $0.unregister() }
        }
    }

    public var leftShiftHotkeys: [HotKey] = [] {
        didSet {
            guard initialized else { return }
            oldValue.forEach { $0.unregister() }
        }
    }

    public var secondaryAltHotkeys: [HotKey] = [] {
        didSet {
            guard initialized else { return }
            oldValue.forEach { $0.unregister() }
        }
    }

    public var secondaryRightShiftHotkeys: [HotKey] = [] {
        didSet {
            guard initialized else { return }
            oldValue.forEach { $0.unregister() }
        }
    }

    public var secondaryLeftShiftHotkeys: [HotKey] = [] {
        didSet {
            guard initialized else { return }
            oldValue.forEach { $0.unregister() }
        }
    }

    public var specialHotkey: HotKey? {
        didSet {
            guard initialized else { return }
            oldValue?.unregister()
        }
    }

    public func reinitHotkeys() {
        guard initialized else { return }
        unregisterPrimaryHotkeys()
        unregisterSecondaryHotkeys()

        unregisterAltHotkeys()
        unregisterRightShiftHotkeys()
        unregisterLeftShiftHotkeys()

        unregisterSecondaryAltHotkeys()
        unregisterSecondaryRightShiftHotkeys()
        unregisterSecondaryLeftShiftHotkeys()

        unregisterSpecialHotkey()
        computeKeyModifiers()
        specialKeyIdentifier = "SPECIAL_KEY\(specialKey)"
        initHotkeys()
    }

    public func computeKeyModifiers() {
        if !primaryKeyModifiers.isEmpty, !primaryKeyModifiers.sideIndependentModifiers.contains(.option) {
            altKeyModifiers = primaryKeyModifiers + [.ralt]
        } else {
            altKeyModifiers = []
        }

        if !primaryKeyModifiers.isEmpty, !primaryKeyModifiers.sideIndependentModifiers.contains(.shift) {
            rightShiftKeyModifiers = primaryKeyModifiers + [.rshift]
            leftShiftKeyModifiers = primaryKeyModifiers + [.lshift]
        } else {
            rightShiftKeyModifiers = []
            leftShiftKeyModifiers = []
        }

        if !secondaryKeyModifiers.isEmpty, !secondaryKeyModifiers.sideIndependentModifiers.contains(.option) {
            secondaryAltKeyModifiers = secondaryKeyModifiers + [.ralt]
        } else {
            secondaryAltKeyModifiers = []
        }

        if !secondaryKeyModifiers.isEmpty, !secondaryKeyModifiers.sideIndependentModifiers.contains(.shift) {
            secondaryRightShiftKeyModifiers = secondaryKeyModifiers + [.rshift]
            secondaryLeftShiftKeyModifiers = secondaryKeyModifiers + [.lshift]
        } else {
            secondaryRightShiftKeyModifiers = []
            secondaryLeftShiftKeyModifiers = []
        }
    }

    public func initHotkeys() {
        initSpecialHotkeys()
        initPrimaryHotkeys()
        initSecondaryHotkeys()

        initAltHotkeys()
        initRightShiftHotkeys()
        initLeftShiftHotkeys()

        initSecondaryAltHotkeys()
        initSecondaryRightShiftHotkeys()
        initSecondaryLeftShiftHotkeys()
    }

    public func initSpecialHotkeys() {
        if !specialKey.isEmpty, !specialKeyModifiers.isEmpty {
            specialHotkey = HotKey(
                identifier: specialKeyIdentifier,
                keyCombo: KeyCombo(
                    key: .init(character: specialKey, virtualKeyCode: nil)!,
                    cocoaModifiers: specialKeyModifiers.sideIndependentModifiers
                )!,
                actionQueue: .main,
                detectKeyHold: false,
                handler: handleSpecialHotkey
            )
        } else {
            specialHotkey = nil
        }
    }

    public func initPrimaryHotkeys() {
        if !primaryKeys.isEmpty, !primaryKeyModifiers.isEmpty {
            primaryHotkeys = buildHotkeys(
                for: primaryKeys,
                modifiers: primaryKeyModifiers.sideIndependentModifiers,
                detectKeyHold: false,
                action: handlePrimaryHotkey
            )
        } else {
            primaryHotkeys = []
        }
    }

    public func initSecondaryHotkeys() {
        if !secondaryKeys.isEmpty, !secondaryKeyModifiers.isEmpty {
            secondaryHotkeys = buildHotkeys(
                for: secondaryKeys,
                modifiers: secondaryKeyModifiers.sideIndependentModifiers,
                identifier: "secondary-",
                detectKeyHold: false,
                action: handleSecondaryHotkey
            )
        } else {
            secondaryHotkeys = []
        }
    }

    public func initAltHotkeys() {
        if !altKeys.isEmpty, !primaryKeyModifiers.isEmpty, !primaryKeyModifiers.sideIndependentModifiers.contains(.option) {
            altHotkeys = buildHotkeys(
                for: altKeys,
                modifiers: altKeyModifiers.sideIndependentModifiers,
                identifier: "alt-",
                detectKeyHold: false,
                action: handleAltHotkey
            )
        } else {
            altHotkeys = []
        }
    }

    public func initRightShiftHotkeys() {
        if !rightShiftKeys.isEmpty, !primaryKeyModifiers.isEmpty, !primaryKeyModifiers.sideIndependentModifiers.contains(.shift) {
            rightShiftHotkeys = buildHotkeys(
                for: rightShiftKeys,
                modifiers: rightShiftKeyModifiers.sideIndependentModifiers,
                identifier: "rshift-",
                detectKeyHold: false,
                action: handleRightShiftHotkey
            )
        } else {
            rightShiftHotkeys = []
        }
    }

    public func initLeftShiftHotkeys() {
        if !leftShiftKeys.isEmpty, !primaryKeyModifiers.isEmpty, !primaryKeyModifiers.sideIndependentModifiers.contains(.shift) {
            leftShiftHotkeys = buildHotkeys(
                for: leftShiftKeys,
                modifiers: leftShiftKeyModifiers.sideIndependentModifiers,
                identifier: "lshift-",
                detectKeyHold: false,
                action: handleLeftShiftHotkey
            )
        } else {
            leftShiftHotkeys = []
        }
    }

    public func initSecondaryAltHotkeys() {
        if !secondaryAltKeys.isEmpty, !secondaryKeyModifiers.isEmpty, !secondaryKeyModifiers.sideIndependentModifiers.contains(.option) {
            secondaryAltHotkeys = buildHotkeys(
                for: secondaryAltKeys,
                modifiers: secondaryAltKeyModifiers.sideIndependentModifiers,
                identifier: "secondary-alt-",
                detectKeyHold: false,
                action: handleSecondaryAltHotkey
            )
        } else {
            secondaryAltHotkeys = []
        }
    }

    public func initSecondaryRightShiftHotkeys() {
        if !secondaryRightShiftKeys.isEmpty, !secondaryKeyModifiers.isEmpty, !secondaryKeyModifiers.sideIndependentModifiers.contains(.shift) {
            secondaryRightShiftHotkeys = buildHotkeys(
                for: secondaryRightShiftKeys,
                modifiers: secondaryRightShiftKeyModifiers.sideIndependentModifiers,
                identifier: "secondary-rshift-",
                detectKeyHold: false,
                action: handleSecondaryRightShiftHotkey
            )
        } else {
            secondaryRightShiftHotkeys = []
        }
    }

    public func initSecondaryLeftShiftHotkeys() {
        if !secondaryLeftShiftKeys.isEmpty, !secondaryKeyModifiers.isEmpty, !secondaryKeyModifiers.sideIndependentModifiers.contains(.shift) {
            secondaryLeftShiftHotkeys = buildHotkeys(
                for: secondaryLeftShiftKeys,
                modifiers: secondaryLeftShiftKeyModifiers.sideIndependentModifiers,
                identifier: "secondary-lshift-",
                detectKeyHold: false,
                action: handleSecondaryLeftShiftHotkey
            )
        } else {
            secondaryLeftShiftHotkeys = []
        }
    }

    @MainActor
    public func initFlagsListener() {
        globalEventMonitor = GlobalEventMonitor(mask: .flagsChanged) { [self] event in
            guard let event = event else { return }
            flagsChanged(modifierFlags: event.modifierFlags.filterUnsupportModifiers())
        }
        globalEventMonitor.start()

        localEventMonitor = LocalEventMonitor(mask: .flagsChanged) { [self] event in
            flagsChanged(modifierFlags: event.modifierFlags.filterUnsupportModifiers())
            return event
        }
        localEventMonitor.start()
    }

    public func buildHotkeys(
        for keys: [String],
        modifiers: NSEvent.ModifierFlags,
        identifier: String = "",
        detectKeyHold: Bool = false,
        ignoredKeys: Set<String>? = nil,
        action: @escaping (HotKey) -> Void
    ) -> [HotKey] {
        guard modifiers.isNotEmpty else { return [] }

        var keys = Set(keys)
        if let ignoredKeys = ignoredKeys { keys.subtract(ignoredKeys) }

        return keys.compactMap { ch in
            guard let key = Key(character: ch, virtualKeyCode: nil), let combo = KeyCombo(key: key, cocoaModifiers: modifiers)
            else { return nil }

            return HotKey(
                identifier: "\(identifier)\(ch)",
                keyCombo: combo,
                actionQueue: .main,
                detectKeyHold: detectKeyHold,
                handler: action
            )
        }
    }

    @objc public func testKeyComboPressedShouldStop(hotkey: HotKey) -> Bool {
        guard let combo = KM.testKeyCombo, hotkey.keyCombo == combo else {
            return false
        }
        KM.testKeyPressed = true

        KM.testKeyHandler?()
        KM.testKeyHandler = nil

        return !KM.testKeyForward
    }

    @objc public func handleSpecialHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard specialKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onSpecialHotkey?()
    }

    @objc public func handlePrimaryHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard primaryKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onPrimaryHotkey?(hotkey.identifier)
    }

    @objc public func handleSecondaryHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard secondaryKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onSecondaryHotkey?(hotkey.identifier.suffix(1).s)
    }

    @objc public func handleAltHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard altKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onAltHotkey?(hotkey.identifier.suffix(1).s)
    }

    @objc public func handleRightShiftHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard rightShiftKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onRightShiftHotkey?(hotkey.identifier.suffix(1).s)
    }

    @objc public func handleLeftShiftHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard leftShiftKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onLeftShiftHotkey?(hotkey.identifier.suffix(1).s)
    }

    @objc public func handleSecondaryAltHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard secondaryAltKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onSecondaryAltHotkey?(hotkey.identifier.suffix(1).s)
    }

    @objc public func handleSecondaryRightShiftHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard secondaryRightShiftKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onSecondaryRightShiftHotkey?(hotkey.identifier.suffix(1).s)
    }

    @objc public func handleSecondaryLeftShiftHotkey(_ hotkey: HotKey) {
        #if DEBUG
            print(hotkey.identifier)
        #endif
        guard secondaryLeftShiftKeyModifiers.allPressed else {
            hotkey.forwardNextEvent = true
            return
        }

        guard !testKeyComboPressedShouldStop(hotkey: hotkey) else { return }
        onSecondaryLeftShiftHotkey?(hotkey.identifier.suffix(1).s)
    }

    // MARK: Internal

    static var MULTI_TAP_THRESHOLD_INTERVAL: TimeInterval = 0.4

    func recheckFlags() {
        guard lastModifierFlags.isNotEmpty else { return }

        let flags = NSEvent.modifierFlags.filterUnsupportModifiers()
        if flags.isEmpty || !lastModifierFlags.contains(flags) {
            flagsChanged(modifierFlags: flags)
        }
    }
}

public let KM = KeysManager()

#if os(macOS)
    import Cocoa

    public enum TriggerKey: Int, Codable, Defaults.Serializable, Comparable, Identifiable {
        case lshift
        case lctrl
        case lalt
        case lcmd
        case rcmd
        case ralt
        case rctrl
        case rshift

        // MARK: Public

        public var id: Int { rawValue }
        public var modifier: NSEvent.ModifierFlags {
            switch self {
            case .rcmd:
                return .rightCommand
            case .ralt:
                return .rightOption
            case .lcmd:
                return .leftCommand
            case .lalt:
                return .leftOption
            case .lctrl:
                return .leftControl
            case .lshift:
                return .leftShift
            case .rshift:
                return .rightShift
            case .rctrl:
                return .rightControl
            }
        }

        public var sideIndependentModifier: NSEvent.ModifierFlags {
            switch self {
            case .rcmd:
                return .command
            case .ralt:
                return .option
            case .lcmd:
                return .command
            case .lalt:
                return .option
            case .lctrl:
                return .control
            case .lshift:
                return .shift
            case .rshift:
                return .shift
            case .rctrl:
                return .control
            }
        }

        public var directionalStr: String {
            switch self {
            case .rcmd:
                return "⌘⃗"
            case .ralt:
                return "⌥⃗"
            case .lcmd:
                return "⌘⃖"
            case .lalt:
                return "⌥⃖"
            case .lctrl:
                return "^⃖"
            case .lshift:
                return "⇧⃖"
            case .rshift:
                return "⇧⃗"
            case .rctrl:
                return "^⃗"
            }
        }

        public var str: String {
            switch self {
            case .rcmd:
                return "⌘"
            case .ralt:
                return "⌥"
            case .lcmd:
                return "⌘"
            case .lalt:
                return "⌥"
            case .lctrl:
                return "^"
            case .lshift:
                return "⇧"
            case .rshift:
                return "⇧"
            case .rctrl:
                return "^"
            }
        }

        public var readableStr: String {
            switch self {
            case .rcmd:
                return "Right Command"
            case .ralt:
                return "Right Option"
            case .lcmd:
                return "Left Command"
            case .lalt:
                return "Left Option"
            case .lctrl:
                return "Left Control"
            case .lshift:
                return "Left Shift"
            case .rshift:
                return "Right Shift"
            case .rctrl:
                return "Right Control"
            }
        }

        public var shortReadableStr: String {
            switch self {
            case .rcmd:
                return "rcmd"
            case .ralt:
                return "ralt"
            case .lcmd:
                return "lcmd"
            case .lalt:
                return "lalt"
            case .lctrl:
                return "lctrl"
            case .lshift:
                return "lshift"
            case .rshift:
                return "rshift"
            case .rctrl:
                return "rctrl"
            }
        }

        public var pressed: Bool {
            switch self {
            case .rcmd:
                return KM.rcmd
            case .ralt:
                return KM.ralt
            case .lcmd:
                return KM.lcmd
            case .lalt:
                return KM.lalt
            case .lctrl:
                return KM.lctrl
            case .lshift:
                return KM.lshift
            case .rshift:
                return KM.rshift
            case .rctrl:
                return KM.rctrl
            }
        }

        public static func < (lhs: TriggerKey, rhs: TriggerKey) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public extension Array where Element == TriggerKey {
        static func == (lhs: Self, rhs: Self) -> Bool {
            Set(lhs) == Set(rhs)
        }

        var withoutShift: [TriggerKey] { filter { $0 != .lshift && $0 != .rshift } }
        var modifiers: NSEvent.ModifierFlags {
            NSEvent.ModifierFlags(map(\.modifier))
        }

        var sideIndependentModifiers: NSEvent.ModifierFlags {
            NSEvent.ModifierFlags(map(\.sideIndependentModifier))
        }

        var str: String { map(\.str).joined() }
        var directionalStr: String { map(\.directionalStr).joined() }
        var readableStr: String { map(\.readableStr).joined(separator: "+") }
        var shortReadableStr: String { map(\.shortReadableStr).joined(separator: "+") }

        var allPressed: Bool { allSatisfy(\.pressed) }

        func toggling(key: TriggerKey, on: Bool? = nil) -> [TriggerKey] {
            if on ?? !contains(key) {
                var keys = self
                if !contains(key) {
                    keys = keys + [key]
                }
                switch key {
                case .rcmd:
                    return keys.toggling(key: TriggerKey.lcmd, on: false)
                case .ralt:
                    return keys.toggling(key: TriggerKey.lalt, on: false)
                case .lcmd:
                    return keys.toggling(key: TriggerKey.rcmd, on: false)
                case .lalt:
                    return keys.toggling(key: TriggerKey.ralt, on: false)
                case .rshift:
                    return keys.toggling(key: TriggerKey.lshift, on: false)
                case .lshift:
                    return keys.toggling(key: TriggerKey.rshift, on: false)
                case .rctrl:
                    return keys.toggling(key: TriggerKey.lctrl, on: false)
                case .lctrl:
                    return keys.toggling(key: TriggerKey.rctrl, on: false)
                }
            } else {
                let newTriggers = filter { $0 != key }
                return newTriggers.withoutShift.isEmpty ? [] : newTriggers
            }
        }
    }

    extension NSEvent.ModifierFlags {
        var triggerKeys: [TriggerKey] {
            var flags = [TriggerKey]()
            if contains(.leftShift) { flags.append(.lshift) }
            if contains(.leftControl) { flags.append(.lctrl) }
            if contains(.leftOption) { flags.append(.lalt) }
            if contains(.leftCommand) { flags.append(.lcmd) }
            if contains(.rightCommand) { flags.append(.rcmd) }
            if contains(.rightOption) { flags.append(.ralt) }
            if contains(.rightControl) { flags.append(.rctrl) }
            if contains(.rightShift) { flags.append(.rshift) }

            return flags
        }
    }

    public struct DirectionalModifierView: View {
        // MARK: Lifecycle

        public init(triggerKeys: Binding<[TriggerKey]>, disabled: Binding<Bool>, spacing: CGFloat = 3, noFG: Bool = false) {
            _triggerKeys = triggerKeys
            _disabled = disabled
            _spacing = spacing.state
            _noFG = State(initialValue: noFG)
        }

        // MARK: Public

        @Environment(\.isEnabled) public var isEnabled

        public var body: some View {
            let rcmdTrigger = Binding<Bool>(
                get: { self.triggerKeys.contains(.rcmd) },
                set: {
                    triggerKeys = triggerKeys.toggling(key: TriggerKey.rcmd, on: $0)
                }
            )
            let raltTrigger = Binding<Bool>(
                get: { self.triggerKeys.contains(.ralt) },
                set: {
                    triggerKeys = triggerKeys.toggling(key: TriggerKey.ralt, on: $0)
                }
            )

            let lcmdTrigger = Binding<Bool>(
                get: { self.triggerKeys.contains(.lcmd) },
                set: {
                    triggerKeys = triggerKeys.toggling(key: TriggerKey.lcmd, on: $0)
                }
            )
            let laltTrigger = Binding<Bool>(
                get: { self.triggerKeys.contains(.lalt) },
                set: {
                    triggerKeys = triggerKeys.toggling(key: TriggerKey.lalt, on: $0)
                }
            )
            let lctrlTrigger = Binding<Bool>(
                get: { self.triggerKeys.contains(.lctrl) },
                set: {
                    triggerKeys = triggerKeys.toggling(key: TriggerKey.lctrl, on: $0)
                }
            )

            let lshiftTrigger = Binding<Bool>(
                get: { self.triggerKeys.contains(.lshift) },
                set: {
                    triggerKeys = triggerKeys.toggling(key: TriggerKey.lshift, on: $0)
                }
            )
            let rshiftTrigger = Binding<Bool>(
                get: { self.triggerKeys.contains(.rshift) },
                set: {
                    triggerKeys = triggerKeys.toggling(key: TriggerKey.rshift, on: $0)
                }
            )
            let rctrlTrigger = Binding<Bool>(
                get: { self.triggerKeys.contains(.rctrl) },
                set: {
                    triggerKeys = triggerKeys.toggling(key: TriggerKey.rctrl, on: $0)
                }
            )

            HStack(spacing: spacing) {
                Button("⇧") {
                    triggerKeys = triggerKeys.toggling(key: .lshift)
                }.buttonStyle(ToggleButton(isOn: lshiftTrigger, noFG: noFG))
                Button("⌃") {
                    triggerKeys = triggerKeys.toggling(key: .lctrl)
                }.buttonStyle(ToggleButton(isOn: lctrlTrigger, noFG: noFG))
                Button("⌥") {
                    triggerKeys = triggerKeys.toggling(key: .lalt)
                }.buttonStyle(ToggleButton(isOn: laltTrigger, noFG: noFG))
                Button("⌘") {
                    triggerKeys = triggerKeys.toggling(key: .lcmd)
                }.buttonStyle(ToggleButton(isOn: lcmdTrigger, noFG: noFG))
                Button("    ⎵    ") {}
                    .buttonStyle(ToggleButton(isOn: .constant(false), noFG: noFG))
                    .opacity(0.9)
                    .disabled(true)
                Button("⌘") {
                    triggerKeys = triggerKeys.toggling(key: .rcmd)
                }.buttonStyle(ToggleButton(isOn: rcmdTrigger, noFG: noFG))
                Button("⌥") {
                    triggerKeys = triggerKeys.toggling(key: .ralt)
                }.buttonStyle(ToggleButton(isOn: raltTrigger, noFG: noFG))
                Button("⌃") {
                    triggerKeys = triggerKeys.toggling(key: .rctrl)
                }.buttonStyle(ToggleButton(isOn: rctrlTrigger, noFG: noFG))
                Button("⇧") {
                    triggerKeys = triggerKeys.toggling(key: .rshift)
                }.buttonStyle(ToggleButton(isOn: rshiftTrigger, noFG: noFG))
            }.disabled(disabled).opacity(isEnabled ? 1 : 0.6)
        }

        // MARK: Internal

        @Binding var triggerKeys: [TriggerKey]
        @Binding var disabled: Bool
        @State var spacing: CGFloat = 3
        @State var noFG = false
    }

#endif
