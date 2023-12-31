### CS 567: Introduction to 3D User Interfaces - FA23
# FoldAR: Gesture Analytics Using Apple Vision Framework
#### Ian Brown, Tani Cath, Tom Cavey

## Application Description
At a high level, the application captures live video and overlays a marker on key hand points. This involves processing video frames, performing inference on each frame, and dynamically adding virtual graphics to the screen, which creates the augmented reality scene in real time. In addition to detecting and displaying visuals in real time, the timestamp, user data, and 2D points are recorded in a CSV format in the application’s memory sandbox.

## Repository Contents
```
├── README.md (this file)
├── Code
|   ├── Configuration (Xcode configuration files)
|   ├── FoldAR_4 (Xcode source files)
|   └── FoldAR_4.xcodeproj
└── Data
    ├── FoldAR_NumericAnalysis.ipynb
    ├── FoldAR_SpatialAnalysis.ipynb
    ├── Images (plots saved from python notebooks)
    |   ├── boxPlots
    |   ├── meanDistances
    |   ├── temporalPlots
    |   ├── tipPathImages
    |   └── userCompletionTimes
    └── sessionData (Data files from experiments)
```


# Running the Application

## System Requirements
1. An Apple mobile device running iOS 16.6 or later.
2. A USB-to-Lightning or USB-to-USB-C cable rated for data transfer.
3. An Apple computer running MacOS 14.0 ("Sonoma") or later.
4. Xcode version 15.1 or newer.
5. A development environment capable of editing and running IPython notebooks (\texttt{.ipynb} files).


## Instuctions to deploy and run application code onto local iOS device
To build and deploy the application onto a local iOS device, perform the following steps:
1. Ensure that Developer Mode is enabled on your iOS device by navigating to Settings > Privacy & Security > Developer Mode, and toggling Developer Mode to "on".
2. Download the source code repository onto an Apple computer with Xcode installed.
3. Navigate to the `Source Code` directory and launch `FoldAR_4.xcodeproj` in Xcode.
4. In the Xcode project navigator, select the parent `FoldAR_4` project item, go to the "Signing & Capabilities" tab, and change the following settings:
    - From the "Team" dropdown menu, select the name/Apple account that is currently signed into Xcode.
    - Rename the "Bundle Identifier" to use a unique ID, such as your GitHub username, using the following format: `userID.FoldAR-4`
5. Connect your iOS device to the computer using a cable rated for data transfer and ensure that it is listed in the top bar of Xcode similar to `FoldAR_4 > iPhone 8`.
6. Unlock your iOS device and click the "Build and Run" button (gray "play" triangle) in the top-left of the Xcode window. You should see a "Build Succeeded" message within Xcode and the application will automatically launch on the iOS device.
7. To close the application either click the "Stop Execution" button (gray "stop" square) or close the application using the iOS app switcher.

## Instructions to use the application
To use the application, perform the following steps:
1. With the application running in portrait mode after launching from Xcode or the home screen, rotate the phone into landscape mode.
2. Tap the "ParticipantID" field in the top-left of the user interface and enter a name or identifying number using the on-screen keyboard.
3. Tap or swipe the "Mode Switcher" in the top-center of the UI to select the experiment mode the participant will be performing.
4. Tap the "START" button in the top-right of the UI to begin recording hand-point data.
5. To stop recording, tap the "STOP" button in the top-right corner.

## Instructions to access recorded data from the iOS device
To offload the recorded session data files from the iOS device, perform the following steps:
1. Open `FoldAR_4.xcodeproj` in Xcode, unlock your iOS device, and connect it to the computer with a cable.
2. In Xcode's top bar, click on the iOS device model and from the dropdown menu select "Manage Run Destinations...".
3. In the pop-up window, select `FoldAR_4` under "INSTALLED APPS", then click on the menu button below the section (a circle with three dots, next to the "+" and "-" buttons) and select "Download Container...".
4. Choose a download location and wait for the process to complete. Once completed the destination location will pop up in the MacOS Finder with the downloaded `.xcappdata` file highlighted.
5. Right-click the data file and select "Show Package Contents".
6. Within the package, navigate to `AppData/Documents` and copy the desired `sessionData-x-y.csv` file(s) to another location in the operating system (`x` = `participantID`; `y` = `mode`, 0, 1, or 2).
7. When finished, disconnect the iOS device and close Xcode, saving any changes if needed.


# Links
## Video Presentations
Presentation Video: https://colostate.sharepoint.com/:v:/s/CompSci_CS567_FA23-Team/EX7NW3BfjWBOsnu8LcSKVaQBvrCCXYlnTLGYxqhwQ2iVBA?e=hCnMSt
Demo+Code Video: https://colostate.sharepoint.com/:v:/s/CompSci_CS567_FA23-Team/EToowcPOUdpKi3U1n0KO9TcBLVXcGUYZcg3hIRZwbxFOkA?e=VMfd8a
Elevator Pitch (Quick Video): https://colostate.sharepoint.com/:v:/s/CompSci_CS567_FA23-Team/EWyhfNg8yNJLsq6WpwwLGNgBk7lZcO7e7tQgqQ9oMVo8ng?e=qAYzkf

## GitHub Repository
https://github.com/csu-hci-projects/FA23-FoldAR-Step-by-step-Instructions-for-Folding-Paper-Models-in-AR

## Overleaf Project
https://www.overleaf.com/project/655fba1d8b736bb6914d6df5

