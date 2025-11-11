import SwiftUI
import Charts // This is Apple's native charting library

struct SubjectView: View {
    // This is passed in from ContentView
    let subject: String
    
    // --- Constants ---
    let masterLabels = Array(1...20).map { "\($0)°" }
    private var userDefaultsKey: String {
        "grades_\(subject)" // Same key as your JS
    }

    // --- State Variables (replaces JS globals) ---
    @State private var currentValues: [Double?] = Array(repeating: nil, count: 20)
    @State private var gradeInput: String = ""
    @State private var resultText: String = ""
    @State private var errorText: String = ""

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
                        .chartYScale(domain: 1...10) // Y-axis from 1 to 10
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

                // --- Input + Add Button ---
                HStack(spacing: 12) {
                    TextField("Voto (es. 6 o 7.5)", text: $gradeInput)
                        .keyboardType(.decimalPad) // Shows number pad
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: gradeInput) { _ in clearMessages() }
                    
                    Button("Aggiungi") {
                        addLast()
                    }
                    .buttonStyle(PrimaryButton())
                    .frame(maxWidth: 100) // Give button a fixed size
                }
                .padding(.horizontal)
                
                // --- Action Buttons ---
                HStack(spacing: 12) {
                    Button("Rimuovi ultimo") {
                        removeLast()
                    }
                    .buttonStyle(PrimaryButton())
                    
                    Button("Voto per avere 6") {
                        computeNeeded()
                    }
                    .buttonStyle(PrimaryButton())
                }
                .padding(.horizontal)
                
                // --- Messages ---
                Text(resultText)
                    .foregroundColor(.white)
                    .font(.headline)
                Text(errorText)
                    .foregroundColor(.red)
                    .font(.callout)
                
                Spacer() // Pushes content to the top
            }
            .padding(.top, 16)
        }
        .navigationTitle(subject)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // This runs when the view loads (like DOMContentLoaded)
            loadValues()
            
            // Replicates your logic to add a "7" if the list is empty
            if currentValues.compactMap({ $0 }).isEmpty {
                currentValues[0] = 7.0
                saveValues()
            }
        }
    }
    
    // --- All Logic Functions (translated from JS) ---
    
    func clearMessages() {
        resultText = ""
        errorText = ""
    }
    
    // Replaces localStorage.getItem
    func loadValues() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            // We use JSONDecoder to read the data
            if let decoded = try? JSONDecoder().decode([Double?].self, from: data) {
                currentValues = decoded
                return
            }
        }
        // Fallback if nothing is saved
        currentValues = Array(repeating: nil, count: 20)
    }
    
    // Replaces localStorage.setItem
    func saveValues() {
        // We use JSONEncoder to save the data
        if let encoded = try? JSONEncoder().encode(currentValues) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func addLast() {
        clearMessages()
        // Convert the input string to a Double
        let cleanedInput = gradeInput.trimmingCharacters(in: .whitespaces)
                                     .replacingOccurrences(of: ",", with: ".")
        
        guard let num = Double(cleanedInput) else {
            errorText = "Valore non valido."
            return
        }
        
        let v = min(max(num, 1.0), 10.0) // Clamp value from 1-10
        
        // Find the last non-nil index
        if let lastIndex = currentValues.lastIndex(where: { $0 != nil }) {
            let next = lastIndex + 1
            if next < currentValues.count {
                currentValues[next] = v
            } else {
                errorText = "Array pieno — non è possibile aggiungere."
                return
            }
        } else {
            // No values yet, add at the start
            currentValues[0] = v
        }
        
        // Success
        gradeInput = "" // Clear input
        saveValues() // Save
    }

    func removeLast() {
        clearMessages()
        if let lastIndex = currentValues.lastIndex(where: { $0 != nil }) {
            currentValues[lastIndex] = nil // Set to nil
            saveValues() // Save
        } else {
            errorText = "Nessun voto da rimuovere."
        }
    }

    func computeNeeded() {
        clearMessages()
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
        SubjectView(subject: "Matematica")
    }
    .preferredColorScheme(.dark)
}
