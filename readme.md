# NoMouseInAppSwitcher

A background app that monitors when you hit Cmd+Tab and then moves the mouse out of the App Switcher, so it doesn't interfere when you Cmd+Tab.

Often times I find that I switch between the same two apps, like Xcode and Safari. A single Cmd+Tab takes me to Safari and another single Cmd+Tab takes me back to Xcode. But sometimes I land on some completely other app. I couldn't figure out why, until I realized that if the mouse pointer happens to be in the area where the App Switcher appears on screen, then any slight mouse movement, will select whatever app is under the mouse pointer.

So the solution is to move the mouse pointer out of the way.


## Technical solution
At first I tried to capture and extract the actual location and size of the App Switcher window. But after multiple failed attempts I settled on just "guesstimating" where the App Switcher is.

![Screenshot](App Switcher.png?raw=true "App Switcher")
