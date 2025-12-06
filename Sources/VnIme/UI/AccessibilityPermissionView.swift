import AppKit
import Combine
import SwiftUI

/// View explaining accessibility permission requirements
struct AccessibilityPermissionView: View {
    @ObservedObject var viewModel: AccessibilityPermissionViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header icon
            Image(systemName: "hand.raised.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.orange)

            // Title
            Text("Accessibility Permission Required")
                .font(.title2)
                .fontWeight(.bold)

            // Description
            VStack(alignment: .leading, spacing: 12) {
                Text("VnIme needs accessibility permissions to:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    PermissionReasonRow(
                        icon: "keyboard",
                        text: "Intercept keyboard events for Vietnamese input"
                    )
                    PermissionReasonRow(
                        icon: "character.cursor.ibeam",
                        text: "Send text to applications"
                    )
                    PermissionReasonRow(
                        icon: "arrow.left.arrow.right",
                        text: "Switch between Vietnamese and English modes"
                    )
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Status indicator
            HStack {
                Circle()
                    .fill(viewModel.isPermissionGranted ? .green : .red)
                    .frame(width: 10, height: 10)
                Text(viewModel.isPermissionGranted ? "Permission Granted" : "Permission Required")
                    .foregroundStyle(viewModel.isPermissionGranted ? .green : .red)
            }

            // Buttons
            VStack(spacing: 12) {
                Button(action: viewModel.openSystemSettings) {
                    Label("Open System Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if viewModel.isPermissionGranted {
                    Button(action: viewModel.dismiss) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button(action: viewModel.checkPermission) {
                        Text("Check Permission Status")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }

            // Help text
            Text("Go to System Settings → Privacy & Security → Accessibility,\nthen enable VnIme in the list.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(width: 400)
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}

/// Row showing a reason for needing permission
private struct PermissionReasonRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
    }
}

/// View model for accessibility permission handling
@MainActor
final class AccessibilityPermissionViewModel: ObservableObject {
    @Published var isPermissionGranted: Bool = false

    private var timer: Timer?
    var onPermissionGranted: (() -> Void)?
    var onDismiss: (() -> Void)?

    init() {
        checkPermission()
    }

    func checkPermission() {
        isPermissionGranted = AXIsProcessTrusted()
        if isPermissionGranted {
            onPermissionGranted?()
        }
    }

    func openSystemSettings() {
        // Open Accessibility settings in System Settings
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func startMonitoring() {
        // Check permission status periodically
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPermission()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func dismiss() {
        onDismiss?()
    }
}

/// Window controller for presenting the permission dialog
@MainActor
final class AccessibilityPermissionWindowController {
    private var window: NSWindow?
    private var viewModel: AccessibilityPermissionViewModel?

    static let shared = AccessibilityPermissionWindowController()

    private init() {}

    /// Show the permission dialog
    /// - Parameters:
    ///   - onGranted: Callback when permission is granted
    func show(onGranted: @escaping () -> Void) {
        // Don't show if already granted
        guard !AXIsProcessTrusted() else {
            onGranted()
            return
        }

        let viewModel = AccessibilityPermissionViewModel()
        self.viewModel = viewModel

        viewModel.onPermissionGranted = { [weak self] in
            self?.close()
            onGranted()
        }

        viewModel.onDismiss = { [weak self] in
            self?.close()
            if AXIsProcessTrusted() {
                onGranted()
            }
        }

        let contentView = AccessibilityPermissionView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "VnIme - Permission Required"
        window.styleMask = [.titled, .closable]
        window.level = .floating
        window.center()

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Close the permission dialog
    func close() {
        window?.close()
        window = nil
        viewModel?.stopMonitoring()
        viewModel = nil
    }

    /// Check if permission is granted without showing UI
    static func checkPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Request permission with prompt (shows system dialog)
    static func requestPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}

#Preview {
    AccessibilityPermissionView(viewModel: AccessibilityPermissionViewModel())
}
