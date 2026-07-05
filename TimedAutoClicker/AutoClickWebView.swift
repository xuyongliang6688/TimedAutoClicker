import SwiftUI
import WebKit

struct AutoClickWebView: UIViewRepresentable {
    @ObservedObject var model: WebClickerViewModel

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        model.attach(webView: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

