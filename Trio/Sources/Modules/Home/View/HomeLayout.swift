import CoreGraphics

/// Fixed zone heights for the non-scrolling Home dashboard.
///
/// Values come from the measured canonical zone inventory (iPhone SE 3rd gen,
/// 17 Pro, 17 Pro Max; default Dynamic Type and XXXL):
/// - The glucose bobble is a fixed 130pt circle that does not track Dynamic
///   Type, so the header renders at 140pt (circle + 10pt top padding) in its
///   canonical configured-CGM state on every device. `headerHeight` adds
///   breathing room for the sensor status tag that overhangs the circle's
///   bottom edge by ~14pt.
/// - The chart is the only flexible zone: it takes the height left over after
///   the fixed slots, never less than `chartMinHeight`.
enum HomeLayout {
    /// Zone B: air between the nav bar and the header, so the bobble keeps
    /// the same visual distance to the bar above as to the meal panel below.
    static let headerTopPadding: CGFloat = 6
    /// Zone B: pump panel / glucose bobble / loop status header.
    static let headerHeight: CGFloat = 150
    /// Zone C: meal panel (IOB / COB / delivery rate) slot; the single
    /// callout-sized row centers inside it up to the XXL type cap.
    static let mealSlotHeight: CGFloat = 44
    /// Zone E: fixed height of the rounded panel shared by the adjustment
    /// view and the bolus progress view (previously 8% of screen height,
    /// 48-65pt depending on device). Both canonical states' two-line content
    /// fits at the XXL type cap.
    /// Pull distance that triggers the forced loop.
    static let refreshTriggerDistance: CGFloat = 70
    /// Indicator row height while the loop runs.
    static let refreshIndicatorHeight: CGFloat = 40
    static let bottomPanelHeight: CGFloat = 60
    /// Zone E: horizontal inset of the panel, matching the visual margin of
    /// the header and meal panels.
    static let bottomPanelHorizontalPadding: CGFloat = 10
    /// Zone E: clear air above the panel (below the chart's x-axis labels).
    static let bottomZoneTopPadding: CGFloat = 10
    /// Zone E: clear air between the panel and the tab bar.
    static let bottomZoneBottomPadding: CGFloat = 16
    /// Zone E: total height including padding, as reserved in the chart's
    /// height calculation.
    static var bottomZoneHeight: CGFloat { bottomPanelHeight + bottomZoneTopPadding + bottomZoneBottomPadding }
    /// Zone D: breathing room above and below the chart's pane stack.
    static let chartVerticalPadding: CGFloat = 8
    /// Zone D: minimum usable chart height (basal + glucose + COB/IOB panes).
    /// SE-class devices fit ~248pt naturally; the floor only guards against
    /// pathological cases and must stay below the natural SE allocation so
    /// the stack cannot overflow into the bottom controls.
    static let chartMinHeight: CGFloat = 240
}
