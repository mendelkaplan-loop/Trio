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
    /// Zone B: pump panel / glucose bobble / loop status header.
    static let headerHeight: CGFloat = 150
    /// Zone C: meal panel (IOB / COB / delivery rate) slot at default type.
    static let mealSlotHeight: CGFloat = 44
    /// Zone E: shared slot for the adjustment panel and bolus progress view,
    /// sized to the taller of the two canonical states at default type.
    static let bottomSlotHeight: CGFloat = 72
    /// Zone D: minimum usable chart height (basal + glucose + COB/IOB panes).
    static let chartMinHeight: CGFloat = 260
}
