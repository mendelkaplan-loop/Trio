import CoreGraphics

/// Fixed zone heights for the non-scrolling Home dashboard, from the measured
/// zone inventory (SE 3rd gen / 17 Pro / 17 Pro Max). The bobble is a fixed
/// 130pt circle, so the header is constant; the chart gets the remainder.
enum HomeLayout {
    /// Zone B: air between nav bar and header.
    static let headerTopPadding: CGFloat = 6
    /// Zone B: pump panel / glucose bobble / loop status header.
    static let headerHeight: CGFloat = 150
    /// Zone C: meal panel slot; the row centers inside it.
    static let mealSlotHeight: CGFloat = 44
    /// Zone E: rounded panel shared by the adjustment and bolus views.
    static let bottomPanelHeight: CGFloat = 60
    /// Zone E: horizontal inset of the panel.
    static let bottomPanelHorizontalPadding: CGFloat = 10
    /// Zone E: air above the panel.
    static let bottomZoneTopPadding: CGFloat = 10
    /// Zone E: air between panel and tab bar.
    static let bottomZoneBottomPadding: CGFloat = 16
    /// Zone E: total height including padding.
    static var bottomZoneHeight: CGFloat { bottomPanelHeight + bottomZoneTopPadding + bottomZoneBottomPadding }
    /// Zone D: breathing room above and below the chart's pane stack.
    static let chartVerticalPadding: CGFloat = 8
    /// Zone D: chart floor; must stay below the natural SE-class allocation.
    static let chartMinHeight: CGFloat = 240
    /// Pull distance that triggers the forced loop.
    static let refreshTriggerDistance: CGFloat = 70
    /// Indicator row height while the loop runs.
    static let refreshIndicatorHeight: CGFloat = 40
}
