import CoreData
import SwiftDate
import SwiftUI

// MARK: - Zone E: bottom controls (adjustment panel / bolus progress)

extension Home.RootView {
    /// One fixed slot for both states, so swapping is a crossfade, not a reflow.
    @ViewBuilder func bottomControls() -> some View {
        Group {
            if let progress = state.bolusProgress {
                bolusView(progress)
            } else {
                adjustmentView()
            }
        }
        .frame(height: HomeLayout.bottomPanelHeight)
        .animation(.easeInOut(duration: 0.2), value: state.bolusProgress != nil)
        .padding(.top, HomeLayout.bottomZoneTopPadding)
        .padding(.bottom, HomeLayout.bottomZoneBottomPadding)
    }

    // MARK: Formatters

    var bolusProgressFormatter: NumberFormatter {
        let fractionDigits: Int = switch state.settingsManager.preferences.bolusIncrement {
        case 0.1: 1
        case 0.025: 3
        default: 2
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimum = 0
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        formatter.allowsFloats = true
        formatter.roundingIncrement = Double(state.settingsManager.preferences.bolusIncrement) as NSNumber
        return formatter
    }

    private var fetchedTargetFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if state.units == .mmolL {
            formatter.maximumFractionDigits = 1
        } else { formatter.maximumFractionDigits = 0 }
        return formatter
    }

    // MARK: Active-adjustment descriptions

    var overrideString: String? {
        guard let latestOverride = latestOverride.first else {
            return nil
        }

        guard let settingsManager = state.settingsManager else {
            return nil
        }

        let percent = latestOverride.percentage
        let percentString = percent == 100 ? "" : "\(percent.formatted(.number)) %"

        let unit = state.units
        var target = (latestOverride.target ?? 0) as Decimal
        target = unit == .mmolL ? target.asMmolL : target

        var targetString = target == 0 ? "" : (fetchedTargetFormatter.string(from: target as NSNumber) ?? "") + " " + unit
            .rawValue
        if tempTargetString != nil {
            targetString = ""
        }

        let duration = latestOverride.duration ?? 0
        let addedMinutes = Int(truncating: duration)
        let date = latestOverride.date ?? Date()
        let newDuration = max(
            Decimal(Date().distance(to: date.addingTimeInterval(addedMinutes.minutes.timeInterval)).minutes),
            0
        )
        let indefinite = latestOverride.indefinite
        var durationString = ""

        if !indefinite {
            if newDuration >= 1 {
                durationString = formatHrMin(Int(newDuration))
            } else if newDuration > 0 {
                durationString = "\(Int(newDuration * 60)) s"

            } else {
                /// Do not show the Override anymore
                Task {
                    guard let objectID = self.latestOverride.first?.objectID else { return }
                    await state.cancelOverride(withID: objectID)
                }
            }
        }

        let smbScheduleString = latestOverride
            .smbIsScheduledOff && ((latestOverride.start?.stringValue ?? "") != (latestOverride.end?.stringValue ?? ""))
            ? " \(formatTimeRange(start: latestOverride.start?.stringValue, end: latestOverride.end?.stringValue))"
            : ""

        let smbToggleString = latestOverride.smbIsOff || latestOverride
            .smbIsScheduledOff ? String(localized: "SMBs Off\(smbScheduleString)") : ""

        var smbMinuteString: String = ""
        var uamMinuteString: String = ""

        if !latestOverride.smbIsOff, latestOverride.advancedSettings {
            if let smbMinutes = latestOverride.smbMinutes,
               smbMinutes.decimalValue != settingsManager.preferences.maxSMBBasalMinutes
            {
                smbMinuteString = "SMB\u{00A0}\(smbMinutes)\u{00A0}" +
                    String(localized: "m", comment: "Abbreviation for Minutes")
            }

            if let uamMinutes = latestOverride.uamMinutes,
               uamMinutes.decimalValue != settingsManager.preferences.maxUAMSMBBasalMinutes
            {
                uamMinuteString = "UAM\u{00A0}\(uamMinutes)\u{00A0}" +
                    String(localized: "m", comment: "Abbreviation for Minutes")
            }
        }

        let components = [durationString, percentString, targetString, smbToggleString, smbMinuteString, uamMinuteString]
            .filter { !$0.isEmpty }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    var tempTargetString: String? {
        guard let latestTempTarget = latestTempTarget.first else {
            return nil
        }
        let duration = latestTempTarget.duration
        let addedMinutes = Int(truncating: duration ?? 0)
        let date = latestTempTarget.date ?? Date()
        let newDuration = max(
            Decimal(Date().distance(to: date.addingTimeInterval(addedMinutes.minutes.timeInterval)).minutes),
            0
        )
        var durationString = ""
        var percentageString = ""
        var target = (latestTempTarget.target ?? 100) as Decimal
        // Use TempTargetCalculations to get effective HBT (handles both custom and auto-adjusted standard TT)
        let effectiveHBT = TempTargetCalculations.computeEffectiveHBT(
            tempTargetHalfBasalTarget: latestTempTarget.halfBasalTarget?.decimalValue,
            settingHalfBasalTarget: state.settingHalfBasalTarget,
            target: target,
            autosensMax: state.autosensMax
        ) ?? state.settingHalfBasalTarget
        var showPercentage = false
        if target > 100, state.isExerciseModeActive || state.highTTraisesSens { showPercentage = true }
        if target < 100, state.lowTTlowersSens, state.autosensMax > 1 { showPercentage = true }
        if showPercentage {
            percentageString =
                " \(Int(TempTargetCalculations.computeAdjustedPercentage(halfBasalTarget: effectiveHBT, target: target, autosensMax: state.autosensMax)))%"
        }
        target = state.units == .mmolL ? target.asMmolL : target
        let targetString = target == 0 ? "" : (fetchedTargetFormatter.string(from: target as NSNumber) ?? "") + " " +
            state.units.rawValue + percentageString

        if newDuration >= 1 {
            durationString =
                "\(newDuration.formatted(.number.grouping(.never).rounded().precision(.fractionLength(0)))) min"
        } else if newDuration > 0 {
            durationString =
                "\((newDuration * 60).formatted(.number.grouping(.never).rounded().precision(.fractionLength(0)))) s"
        } else {
            /// Do not show the Temp Target anymore
            Task {
                guard let objectID = self.latestTempTarget.first?.objectID else { return }
                await state.cancelTempTarget(withID: objectID)
            }
        }

        let components = [targetString, durationString].filter { !$0.isEmpty }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    // MARK: Adjustment panel

    @ViewBuilder func adjustmentsOverrideView(_ overrideString: String) -> some View {
        Group {
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.title2)
                .foregroundStyle(Color.primary, Color.purple)
            VStack(alignment: .leading) {
                Text(latestOverride.first?.name ?? String(localized: "Custom Override"))
                    .font(.subheadline)
                    .frame(alignment: .leading)

                Text(overrideString)
                    .font(.caption)
            }
        }
        .onTapGesture {
            selectedTab = 2
        }
    }

    @ViewBuilder func adjustmentsTempTargetView(_ tempTargetString: String) -> some View {
        Group {
            Image(systemName: "target")
                .font(.title2)
                .foregroundStyle(Color.loopGreen)
            VStack(alignment: .leading) {
                Text(latestTempTarget.first?.name ?? String(localized: "Temp Target"))
                    .font(.subheadline)
                Text(tempTargetString)
                    .font(.caption)
            }
        }
        .onTapGesture {
            selectedTab = 2
        }
    }

    @ViewBuilder func adjustmentsCancelView(_ cancelAction: @escaping () -> Void) -> some View {
        Image(systemName: "xmark.app")
            .font(.title)
            .onTapGesture {
                cancelAction()
            }
    }

    @ViewBuilder func adjustmentsCancelTempTargetView() -> some View {
        Image(systemName: "xmark.app")
            .font(.title)
            .confirmationDialog(
                "Stop the Temp Target \"\(latestTempTarget.first?.name ?? "")\"?",
                isPresented: $isConfirmStopTempTargetShown,
                titleVisibility: .visible
            ) {
                Button("Stop", role: .destructive) {
                    Task {
                        guard let objectID = latestTempTarget.first?.objectID else { return }
                        await state.cancelTempTarget(withID: objectID)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .padding(.trailing, 8)
            .onTapGesture {
                if !latestTempTarget.isEmpty {
                    isConfirmStopTempTargetShown = true
                }
            }
    }

    @ViewBuilder func adjustmentsCancelOverrideView() -> some View {
        Image(systemName: "xmark.app")
            .font(.title)
            .confirmationDialog(
                "Stop the Override \"\(latestOverride.first?.name ?? "")\"?",
                isPresented: $isConfirmStopOverridePresented,
                titleVisibility: .visible
            ) {
                Button("Stop", role: .destructive) {
                    Task {
                        guard let objectID = latestOverride.first?.objectID else { return }
                        await state.cancelOverride(withID: objectID)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .padding(.trailing, 8)
            .onTapGesture {
                if !latestOverride.isEmpty {
                    isConfirmStopOverridePresented = true
                }
            }
    }

    @ViewBuilder func noActiveAdjustmentsView() -> some View {
        Group {
            VStack {
                Text("No Active Adjustment")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Profile at 100 %")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.leading, 10)

            Spacer()

            /// to ensure the same position....
            Image(systemName: "xmark.app")
                .font(.title)
                // clear color for the icon
                .foregroundStyle(Color.clear)
        }.onTapGesture {
            selectedTab = 2
        }
    }

    @ViewBuilder func adjustmentView() -> some View {
        ZStack {
            /// rectangle as background
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    (overrideString != nil || tempTargetString != nil) ?
                        (
                            colorScheme == .dark ?
                                Color(red: 0.03921568627, green: 0.133333333, blue: 0.2156862745) :
                                Color.insulin.opacity(0.1)
                        ) : Color.clear // Use clear and add the Material in the background
                )
                // Opaque backgrounds, so nothing bleeds through during a pull-down.
                .background(
                    colorScheme == .dark
                        ? Color(red: 0.03921568627, green: 0.133333333, blue: 0.2156862745)
                        : Color.black.opacity(0.075)
                )
                .background(appState.trioBackgroundColor(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .frame(height: HomeLayout.bottomPanelHeight)
                .shadow(
                    color: (overrideString != nil || tempTargetString != nil) ?
                        (
                            colorScheme == .dark ? Color(red: 0.02745098039, green: 0.1098039216, blue: 0.1411764706) :
                                Color.black.opacity(0.33)
                        ) : Color.clear,
                    radius: 3
                )
            HStack {
                if let overrideString = overrideString, let tempTargetString = tempTargetString {
                    HStack {
                        adjustmentsOverrideView(overrideString)

                        Spacer()

                        Divider()
                            .frame(height: HomeLayout.bottomPanelHeight - 24)
                            .padding(.horizontal, 2)

                        adjustmentsTempTargetView(tempTargetString)

                        Spacer()

                        adjustmentsCancelView({
                            if !latestTempTarget.isEmpty, !latestOverride.isEmpty {
                                showCancelConfirmDialog = true
                            } else if !latestOverride.isEmpty {
                                showCancelAlert = true
                            } else if !latestTempTarget.isEmpty {
                                showCancelAlert = true
                            }
                        })
                    }
                } else if let overrideString = overrideString {
                    adjustmentsOverrideView(overrideString)
                    Spacer()
                    adjustmentsCancelOverrideView()

                } else if let tempTargetString = tempTargetString {
                    HStack {
                        adjustmentsTempTargetView(tempTargetString)
                        Spacer()
                        adjustmentsCancelTempTargetView()
                    }
                } else {
                    noActiveAdjustmentsView()
                }
            }.padding(.horizontal, 10)
                .confirmationDialog("Adjustment to Stop", isPresented: $showCancelConfirmDialog) {
                    Button("Stop Override", role: .destructive) {
                        Task {
                            guard let objectID = latestOverride.first?.objectID else { return }
                            await state.cancelOverride(withID: objectID)
                        }
                    }
                    Button("Stop Temp Target", role: .destructive) {
                        Task {
                            guard let objectID = latestTempTarget.first?.objectID else { return }
                            await state.cancelTempTarget(withID: objectID)
                        }
                    }
                    Button("Stop All Adjustments", role: .destructive) {
                        Task {
                            guard let overrideObjectID = latestOverride.first?.objectID else { return }
                            await state.cancelOverride(withID: overrideObjectID)

                            guard let tempTargetObjectID = latestTempTarget.first?.objectID else { return }
                            await state.cancelTempTarget(withID: tempTargetObjectID)
                        }
                    }
                } message: {
                    Text("Select Adjustment")
                }
        }.padding(.horizontal, HomeLayout.bottomPanelHorizontalPadding)
    }

    // MARK: Bolus progress

    @ViewBuilder func bolusView(_ progress: Decimal) -> some View {
        /// ensure that state.lastPumpBolus has a value, i.e. there is a last bolus done by the pump and not an external bolus
        /// - TRUE:  show the pump bolus
        /// - FALSE:  do not show a progress bar at all
        if let bolusTotal = state.lastPumpBolus?.bolus?.amount {
            let bolusFraction = progress * (bolusTotal as Decimal)
            let bolusString =
                (bolusProgressFormatter.string(from: bolusFraction as NSNumber) ?? "0")
                    + String(localized: " of ", comment: "Bolus string partial message: 'x U of y U' in home view") +
                    (Formatter.decimalFormatterWithThreeFractionDigits.string(from: bolusTotal as NSNumber) ?? "0")
                    + String(localized: " U", comment: "Insulin unit")

            ZStack {
                /// rectangle as background
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        colorScheme == .dark ? Color(red: 0.03921568627, green: 0.133333333, blue: 0.2156862745) : Color
                            .insulin
                            .opacity(0.2)
                    )
                    .background(appState.trioBackgroundColor(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .frame(height: HomeLayout.bottomPanelHeight)
                    .shadow(
                        color: colorScheme == .dark ? Color(red: 0.02745098039, green: 0.1098039216, blue: 0.1411764706) :
                            Color.black.opacity(0.33),
                        radius: 3
                    )

                /// actual bolus view
                HStack {
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 25))

                    Spacer()

                    VStack {
                        Text("Bolusing")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(bolusString)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.leading, 5)

                    Spacer()

                    Button {
                        state.showProgressView()
                        state.cancelBolus()
                    } label: {
                        Image(systemName: "xmark.app")
                            .font(.system(size: 25))
                    }
                }.padding(.horizontal, 10)
                    .padding(.trailing, 8)
            }
            // Anchored to the panel, inside its rounded bottom edge.
            .overlay(alignment: .bottom) {
                BolusProgressBar(progress: progress)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
            }
            .padding(.horizontal, HomeLayout.bottomPanelHorizontalPadding)
        }
    }
}
