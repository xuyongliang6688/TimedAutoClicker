# Timed Auto Clicker for iOS

This is a small SwiftUI iOS app that can load a web page and run a timed click inside that web page.

Important limits:

- It cannot click inside other iOS apps. Stock iOS does not allow third-party apps to inject touch events into other apps.
- The timer runs only while this app is open or in the foreground. If iOS backgrounds/suspends the app, the app sends a local notification at the selected time so you can reopen it.
- Coordinate clicks are viewport coordinates inside the loaded web page, not whole-phone screen coordinates.

## How to use

1. Open `TimedAutoClicker.xcodeproj` in Xcode on a Mac.
2. Select your iPhone or a simulator.
3. Change the bundle identifier in the target settings if Xcode asks.
4. Build and run.
5. Enter a URL, choose either a CSS selector or point click, choose the time, then tap the schedule button.

For selector mode, examples include:

```text
button
#submit
.buy-now
button[type="submit"]
```

## GitHub Actions packaging

This project includes `.github/workflows/ios-build.yml`.

After pushing to GitHub, open the repository's Actions tab and run `iOS build`.
The workflow produces:

- `TimedAutoClicker-simulator-app.zip`
- `TimedAutoClicker-unsigned.ipa`

The unsigned IPA is not directly installable on a normal iPhone. For real-device installation, sign the app with an Apple Developer account and a matching provisioning profile.
