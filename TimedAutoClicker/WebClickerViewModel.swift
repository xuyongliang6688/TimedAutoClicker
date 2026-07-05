import Foundation
import UserNotifications
import WebKit

enum ClickMode: String, CaseIterable, Identifiable {
    case selector
    case point

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selector:
            return "Selector"
        case .point:
            return "Point"
        }
    }
}

@MainActor
final class WebClickerViewModel: ObservableObject {
    @Published var urlText = "https://example.com"
    @Published var mode = ClickMode.selector
    @Published var selector = "button"
    @Published var pointX = "120"
    @Published var pointY = "240"
    @Published var fireDate = Date().addingTimeInterval(60)
    @Published var repeatCount = 1
    @Published var intervalSeconds = 1
    @Published var status = "Load a page, then choose a time."

    private weak var webView: WKWebView?
    private var timer: Timer?

    func attach(webView: WKWebView) {
        self.webView = webView
        loadPage()
    }

    func loadPage() {
        guard let url = normalizedURL(from: urlText) else {
            status = "Invalid URL."
            return
        }

        webView?.load(URLRequest(url: url))
        status = "Loaded: \(url.absoluteString)"
    }

    func scheduleClick() {
        cancelSchedule()

        let delay = max(0, fireDate.timeIntervalSinceNow)
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.runClicks()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        scheduleNotification(at: fireDate)
        status = "Scheduled for \(formatted(date: fireDate)). Keep the app in the foreground to run automatically."
    }

    func cancelSchedule() {
        timer?.invalidate()
        timer = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timed-click"])
        status = "Schedule canceled."
    }

    func runClicks() {
        timer?.invalidate()
        timer = nil

        guard webView != nil else {
            status = "The page is not ready yet."
            return
        }

        Task { @MainActor in
            let total = max(1, repeatCount)

            for index in 1...total {
                await clickOnce(index: index, total: total)

                if index < total {
                    let seconds = UInt64(max(1, intervalSeconds))
                    try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                }
            }

            status = "Finished \(total) click(s)."
        }
    }

    private func clickOnce(index: Int, total: Int) async {
        guard let webView else {
            status = "The page is not ready yet."
            return
        }

        let script: String
        switch mode {
        case .selector:
            let selectorLiteral = javaScriptStringLiteral(selector)
            script = """
            (() => {
                const el = document.querySelector(\(selectorLiteral));
                if (!el) return "not-found";
                el.scrollIntoView({ block: "center", inline: "center" });
                const rect = el.getBoundingClientRect();
                const x = rect.left + rect.width / 2;
                const y = rect.top + rect.height / 2;
                el.dispatchEvent(new MouseEvent("mousedown", { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y }));
                el.dispatchEvent(new MouseEvent("mouseup", { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y }));
                el.click();
                return "clicked";
            })();
            """

        case .point:
            let x = Double(pointX) ?? 0
            let y = Double(pointY) ?? 0
            script = """
            (() => {
                const x = \(x);
                const y = \(y);
                const el = document.elementFromPoint(x, y);
                if (!el) return "not-found";
                el.dispatchEvent(new MouseEvent("mousedown", { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y }));
                el.dispatchEvent(new MouseEvent("mouseup", { bubbles: true, cancelable: true, view: window, clientX: x, clientY: y }));
                el.click();
                return el.tagName.toLowerCase();
            })();
            """
        }

        do {
            let result = try await evaluate(script, in: webView)
            status = "Click \(index)/\(total): \(String(describing: result ?? "ok"))"
        } catch {
            status = "Click failed: \(error.localizedDescription)"
        }
    }

    private func evaluate(_ script: String, in webView: WKWebView) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript(script) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    private func scheduleNotification(at date: Date) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        let content = UNMutableNotificationContent()
        content.title = "Timed click is due"
        content.body = "Open the app to continue if the page is still loaded."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "timed-click", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func normalizedURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }

    private func javaScriptStringLiteral(_ value: String) -> String {
        guard
            let data = try? JSONSerialization.data(withJSONObject: [value]),
            let arrayLiteral = String(data: data, encoding: .utf8),
            arrayLiteral.count >= 2
        else {
            return "\"\""
        }

        return String(arrayLiteral.dropFirst().dropLast())
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
