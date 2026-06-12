# NoMouseInAppSwitcher

A background app that monitors when you hit Cmd+Tab and then moves the mouse out of the App Switcher, so it doesn't interfere when you Cmd+Tab.

This is what I call the App Switcher:
![Screenshot](/Resources/AppSwitcher.png)

Often times I find that I switch between the same two apps, like Xcode and Safari. A single Cmd+Tab takes me to Safari and another single Cmd+Tab takes me back to Xcode. But sometimes I land on some completely other app. I couldn't figure out why, until I realized that if the mouse pointer happens to be in the area where the App Switcher appears on screen, then any slight mouse movement, will select whatever app is under the mouse pointer.

So the solution is to move the mouse pointer out of the way.


## Technical solution
At first I tried to capture and extract the actual location and size of the App Switcher window. But after multiple failed attempts I settled on just "guesstimating" where the App Switcher is.

The numbers I have come up with for the guesstimation may not fit with every possible mac. I also didn't test with multiple monitor setup. For now, you may need to adjust values to fit your need.

There is a debug overlay that can help you better see where the app is guessing that the App Switcher should be.
Also you can chose whether the mouse cursor should be put back to where it was when you release the Cmd key.

These are controlled in the top of the AppDelegate.swift:

```swift
// Settings
let moveMouseBackToOriginalPosition = false
let debugOverlayEnabled = false
```


## Installation
1. Download the app
2. Drag it into the /Applications folder
3. Try to open it (it wont work)
4. Go to System Settings -> Privacy & Security. Scroll down to the bottom and select "Open Anyway" (you should generally never do this, unless you absolutely trust that the app is safe - if you want you can compile it yourself with Xcode)
![Screenshot](/Resources/Settings_blocked.png)
5. Open the app again and now there are two permissions you need to grant:
![Screenshot](/Resources/Accessibility_Access.png)
![Screenshot](/Resources/Keystroke_Receiving.png)
6. Either click the "Open System Settings" on each dialog or open System Settings and navigate to Privacy & Security -> Accessibility
![Screenshot](/Resources/Settings_Accessibility.png)
7. Also navigate to Privacy & Security -> Input Monitoring
![Screenshot](/Resources/Settings_InputMonitoring.png)

