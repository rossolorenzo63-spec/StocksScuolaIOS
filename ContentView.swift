import SwiftUI

struct ContentView: View {
    // This is the list of subjects from your JS
    let subjects = [
        "Matematica", "Italiano", "Inglese", "Fisica",
        "Storia", "Scienze", "Arte", "Educazione Fisica", "Latino"
    ]

    var body: some View {
        NavigationStack {
            List(subjects, id: \.self) { subject in
                // This creates a link that passes the subject's name
                // to the detail view (SubjectView)
                NavigationLink(value: subject) {
                    Text(subject)
                        .font(.headline)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Stocks Scuola")
            .listStyle(.plain)
            // This tells the NavigationStack how to build the
            // view when a subject is tapped
            .navigationDestination(for: String.self) { subjectName in
                SubjectView(subject: subjectName)
            }
        }
        .accentColor(.white) // Makes the back button text white
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
