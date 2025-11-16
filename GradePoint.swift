import Foundation

// The native Charts framework needs data to be "Identifiable"
// This struct replaces the simple { label, value } object from your JS
struct GradePoint: Identifiable {
    // We use UUID to make each point unique
    var id = UUID()
    var label: String // e.g., "1°", "2°"
    var value: Double // e.g., 7.5

}
