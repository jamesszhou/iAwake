## Getting Started
As there are two different implementations on iOS and Desktop, these setup instructions are for the Desktop Machine which could also be easily integrated into webcam and remote hardware device such as a Raspberry Pi. For setup instructions for iOS please see the README.md file under the iOS implementation branch.

### Prerequisites

To run the program, the following modules must be installed on the machine:

  twilio \
  cmake (used for dlib installation) \
  dlib \
  opencv \
  imutils \
  pyobjc (macOS only) \
  playsound \
  requests 

For installation, use pip installs as follows:
```
pip install twilio
```

### Installing

Once all the necessary modules have been installed, download the iAwake files into your working directory.

This program is easy to use and does not require any extra installation besides modules

## Running the tests

The Desktop version allows the user to specify three arguments to the program: 

  shape-predictor (required) ... provide which shape predicting reference file to use (default provided here) \
  alarm ... provide which sound file to play when the alarm sounds (default provided here) \
  webcam ... provide which webcam/camera to use (only use if external webcam detected)
  
The commandline call, using the provided alarm sound and default integrated webcam, is as follows:
```
python iAwake.py --shape-predictor shape_predictor_68_face_landmarks.dat --alarm alarm.wav
```

