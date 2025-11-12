import SwiftUI

struct ContentView: View {
    @State private var subjects: [String: [Grade]] = [:]
    @State private var showingLogin = false
    @State private var isRefreshing = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            List(subjects.keys.sorted(), id: \.self) { subject in
                NavigationLink(value: subject) {
                    Text(subject)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Stocks Scuola")
            .listStyle(.plain)
            .navigationDestination(for: String.self) { subjectName in
                SubjectView(subject: subjectName, grades: subjects[subjectName] ?? [])
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        logout()
                    }) {
                        Image(systemName: "arrow.left.square")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingLogin.toggle()
                    }) {
                        Image(systemName: "person.circle")
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        fetchSubjects()
                    }) {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingLogin, onDismiss: fetchSubjects) {
                WebLoginView()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Session Expired"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .accentColor(.white)
        .onAppear(perform: onAppear)
        
        Text("Applicazione creata esclusivamente per uno scopo informativo. Non siamo responsabili per nessun problema legale")
            .font(.system(size: 8))
            .font(.headline)
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
    }
    
    private func onAppear() {
        if NetworkManager.shared.isLoggedIn {
            fetchSubjects()
        } else {
            showingLogin = true
        }
    }
    
    private func fetchSubjects() {
        isRefreshing = true
        NetworkManager.shared.fetchGrades { result in
            DispatchQueue.main.async {
                isRefreshing = false
                switch result {
                case .success(let grades):
                    self.subjects = grades
                case .failure(let error):
                    switch error {
                    case .sessionExpired:
                        self.alertMessage = "Your session has expired. Please log in again."
                        self.showAlert = true
                        self.showingLogin = true
                    default:
                        self.alertMessage = "An error occurred: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    private func logout() {
        NetworkManager.shared.logout()
        subjects.removeAll()
        showingLogin = true
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
