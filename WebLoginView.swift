import SwiftUI
import WebKit

struct WebLoginView: UIViewRepresentable {
    @Environment(\.presentationMode) var presentationMode

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: URL(string: "https://web.spaggiari.eu/cvv/app/default/genitori_note.php?ordine=materia&filtro=tutto")!)
        uiView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebLoginView

        init(_ parent: WebLoginView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url, url.absoluteString.contains("genitori_note.php") {
                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                    NetworkManager.shared.setCookies(cookies)
                    DispatchQueue.main.async {
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
