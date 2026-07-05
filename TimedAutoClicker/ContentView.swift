import SwiftUI

struct ContentView: View {
    @StateObject private var model = WebClickerViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("Web Page") {
                        TextField("https://example.com", text: $model.urlText)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()

                        Button("Load Page") {
                            model.loadPage()
                        }
                    }

                    Section("Click Settings") {
                        Picker("Mode", selection: $model.mode) {
                            ForEach(ClickMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        if model.mode == .selector {
                            TextField("CSS selector, e.g. #submit", text: $model.selector)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            HStack {
                                TextField("X", text: $model.pointX)
                                    .keyboardType(.decimalPad)
                                TextField("Y", text: $model.pointY)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        DatePicker("Trigger Time", selection: $model.fireDate, displayedComponents: [.date, .hourAndMinute])

                        Stepper("Clicks: \(model.repeatCount)", value: $model.repeatCount, in: 1...100)
                        Stepper("Interval: \(model.intervalSeconds) sec", value: $model.intervalSeconds, in: 1...60)
                    }

                    Section {
                        Button("Schedule Click") {
                            model.scheduleClick()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Test Click Now") {
                            model.runClicks()
                        }

                        Button("Cancel Schedule") {
                            model.cancelSchedule()
                        }
                        .foregroundStyle(.red)

                        Text(model.status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxHeight: 470)

                Divider()

                AutoClickWebView(model: model)
            }
            .navigationTitle("Timed Click")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
