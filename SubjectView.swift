import SwiftUI
import Charts // This is Apple's native charting library

struct SubjectView: View {
    // This is passed in from ContentView
    let subject: String
    let grades: [Grade]
    
    // --- Constants ---
    let masterLabels = Array(1...20).map { "\($0)°" }

    // --- State Variables (replaces JS globals) ---
    @State private var currentValues: [Double?] = Array(repeating: nil, count: 20)
    @State private var resultText: String = ""

    // --- Computed Properties (replaces JS getFilteredPoints()) ---
    private var chartData: (points: [GradePoint], percentage: Double) {
        var out: [GradePoint] = []
        // Loop through all 20 possible values
        for (i, label) in masterLabels.enumerated() {
            // If a value exists at this index...
            if let raw = currentValues[i] {
                // ...clamp it (like your JS logic)...
                let value = min(max(raw, 1.0), 10.0)
                // ...and add it to the 'out' array.
                out.append(GradePoint(label: label, value: value))
            }
        }
        
        var percentage: Double = 0.0
        if out.count > 1 {
            let last = out[out.count - 1].value
            let previous = out[out.count - 2].value
            if previous != 0 {
                percentage = ((last - previous) / previous) * 100
            }
        }
        
        return (out, percentage)
    }
    
    // Helper to color the chart
    private var lastValueColor: Color {
        let points = chartData.points
        guard let last = points.last else { return .gray }
        return last.value >= 6 ? .green : .red
    }

    // --- The Main UI ---
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // --- Chart Area ---
                VStack(spacing: 8) {
                    let (points, percentage) = chartData
                    
                    Text(String(format: "%.2f%%", percentage))
                        .font(.title.bold())
                        .foregroundColor(percentage >= 0 ? .green : .red)
                    
                    if points.isEmpty {
                        // Placeholder (like your #chart-placeholder)
                        Text("Nessun dato")
                            .font(.callout)
                            .foregroundColor(.gray)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color(.sRGB, white: 0.1, opacity: 1.0))
                            .cornerRadius(10)
                    } else {
                        // The native Chart
                        Chart(points) { point in
                            // The line
                            LineMark(
                                x: .value("Data", point.label),
                                y: .value("Voto", point.value)
                            )
                            .foregroundStyle(lastValueColor)
                            
                            // The dots on the line
                            PointMark(
                                x: .value("Data", point.label),
                                y: .value("Voto", point.value)
                            )
                            .foregroundStyle(lastValueColor)
                        }
                        .chartYScale(domain: 1...10)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: Array(1...10))
                        }
                        .chartXAxis {
                            // This ensures not all 20 labels try to show
                            AxisMarks(values: .automatic(desiredCount: 7))
                        }
                        .frame(height: 300)
                        .padding()
                        .background(Color(.sRGB, white: 0.1, opacity: 1.0))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Button("Voto per avere 6") {
                    computeNeeded()
                }
                .buttonStyle(PrimaryButton())
                .padding(.horizontal)
                
                Text(resultText)
                    .foregroundColor(.white)
                    .font(.headline)
                
                Spacer() // Pushes content to the top
            }
            .padding(.top, 16)
        }
        .navigationTitle(subject)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            populateGrades()
        }
    }

    private func populateGrades() {
        var newValues: [Double?] = Array(repeating: nil, count: 20)
        for (index, grade) in grades.enumerated() {
            if index < newValues.count {
                newValues[index] = grade.value
            }
        }
        self.currentValues = newValues
    }
    
    func computeNeeded() {
        // .compactMap { $0 } filters out all the 'nil' values
        let numeric = currentValues.compactMap { $0 }
        let n = numeric.count
        let sum = numeric.reduce(0.0, +)
        
        // x = (6 * (n + 1)) - sum
        let x = 6.0 * Double(n + 1) - sum
        
        if x.isNaN || x.isInfinite {
            resultText = "Impossibile calcolare"
        } else {
            // Format to 2 decimals, but remove .00 if it's a whole number
            resultText = String(format: "Voto: %.2f", x)
                         .replacingOccurrences(of: ".00", with: "")
        }
    }
}

// --- Custom Button Style (replaces .btn-primary CSS) ---
struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.medium)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            // Use the dark gray from your CSS
            .background(Color(.sRGB, red: 20/255, green: 20/255, blue: 20/255, opacity: 1.0))
            // Use the light gray text color
            .foregroundColor(Color(.sRGB, red: 128/255, green: 124/255, blue: 124/255, opacity: 1.0))
            .cornerRadius(10)
            // Animate press
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// This just provides the live preview in Xcode
#Preview {
    NavigationStack {
        SubjectView(subject: "Matematica", grades: [Grade(date: Date(), value: 7.0), Grade(date: Date(), value: 8.5), Grade(date: Date(), value: 6.5)])
    }
    .preferredColorScheme(.dark)
}
