import SwiftUI
import UIKit

// MARK: - Toolbar: Stats/Info buttons and conditional warning items (notifications off, pump timezone)

extension Home.RootView {
    @ToolbarContentBuilder var homeToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                state.showModal(for: .statistics)
            } label: {
                Label(
                    String(localized: "Stats", comment: "Stats icon in main view"),
                    systemImage: statsIconString
                )
            }
        }
        // Warnings render in the fixed-height navigation bar, so showing or
        // hiding them can never reflow the dashboard below.
        ToolbarItem(placement: .principal) {
            HStack(spacing: 16) {
                if notificationsDisabled {
                    notificationsOffWarning
                }
                if let badgeImage = state.pumpStatusBadgeImage, let badgeColor = state.pumpStatusBadgeColor {
                    pumpTimezoneWarning(badgeImage, badgeColor)
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                state.isLegendPresented.toggle()
            } label: {
                Label(
                    String(localized: "Info", comment: "Info icon in main view"),
                    systemImage: "info.circle"
                )
            }
        }
    }

    /// Safety notifications are disabled; tapping opens the app's iOS settings.
    private var notificationsOffWarning: some View {
        Button {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        } label: {
            Image(systemName: "bell.slash.fill")
                .foregroundStyle(Color.red)
        }
        .accessibilityLabel(String(localized: "Safety Notifications are OFF. Fix now by turning Notifications ON."))
    }

    /// The pump's clock differs from the phone's; tapping opens pump settings.
    private func pumpTimezoneWarning(_ badgeImage: UIImage, _ badgeColor: Color) -> some View {
        Button {
            if state.pumpDisplayState != nil {
                // sends user to pump settings
                state.shouldDisplayPumpSetupSheet.toggle()
            }
        } label: {
            Image(uiImage: badgeImage.withRenderingMode(.alwaysTemplate))
                .colorMultiply(badgeColor)
        }
        .accessibilityLabel(String(localized: "Time Change Detected", comment: ""))
    }
}
