# USAGE
# python iAwake.py --shape-predictor shape_predictor_68_face_landmarks.dat --alarm alarm.wav

from scipy.spatial import distance as dist
from imutils.video import VideoStream
from imutils import face_utils
from threading import Thread
from twilio.rest import Client

account_sid = 'AC3e220f999406b7030d12d76f5b1babb3'
auth_token = 'ce168b24400fe07db8fce466c889c830'
client = Client(account_sid, auth_token)
numbers_to_message = ['+19252553815', '+18312410698']
userNumber = '+13109947617'
sender = '+15103690674'

import numpy as np
import playsound
import requests
import argparse
import imutils
import time
import dlib
import json
import cv2

def sound_alarm(path):
	# activate the alarm
	playsound.playsound(path)

def eye_aspect_ratio(eye):
	# distances between vertical eye landmarks
	A = dist.euclidean(eye[1], eye[5])
	B = dist.euclidean(eye[2], eye[4])

	# distances between horizontal eye landmarks
	C = dist.euclidean(eye[0], eye[3])

	# compute and return eye aspect ratio
	ear = (A + B) / (2.0 * C)
	return ear
 
# construct argument parse and parse arguments
ap = argparse.ArgumentParser()
ap.add_argument("-p", "--shape-predictor", required=True,
	help="path to facial landmark predictor")
ap.add_argument("-a", "--alarm", type=str, default="",
	help="path alarm .WAV file")
ap.add_argument("-w", "--webcam", type=int, default=0,
	help="index of webcam on system")
args = vars(ap.parse_args())
 
# values less than EYE_THRESH represent blinking/closing of eye
# EYE_AR_CONSEC_FRAMES represents number of frames eye can be closed
# before alarm is triggered
EYE_AR_THRESH = 0.20
EYE_AR_CONSEC_FRAMES = 24

# initialize the frame counter, boolean alarm activator,
# accumulator for number of times dozed off
COUNTER = 0
ALARM_ON = False
PING = 0

# initialize dlib's face detector and create facial landmark predictor
print("[INFO] loading facial detection...")
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(args["shape_predictor"])

# grab indices of facial landmarks for left and right eye
(lStart, lEnd) = face_utils.FACIAL_LANDMARKS_IDXS["left_eye"]
(rStart, rEnd) = face_utils.FACIAL_LANDMARKS_IDXS["right_eye"]

# start the video stream thread
print("[INFO] starting video stream via camera...")
vs = VideoStream(src=args["webcam"]).start()
time.sleep(1.0)

# loop over video stream frames
while True:
	# grab frame, resize, and change to grayscale channel
	frame = vs.read()
	frame = imutils.resize(frame, width=750)
	gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

	# detect faces in grayscale frame
	rects = detector(gray, 0)

	# loop over face detections
	for rect in rects:
		# determine facial landmarks and convert (x, y)-coordinates to a NumPy
		# array
		shape = predictor(gray, rect)
		shape = face_utils.shape_to_np(shape)

		# extract left and right eye coordinates
		# calculate eye aspect ratios
		leftEye = shape[lStart:lEnd]
		rightEye = shape[rStart:rEnd]
		leftEAR = eye_aspect_ratio(leftEye)
		rightEAR = eye_aspect_ratio(rightEye)

		# get average EAR
		ear = (leftEAR + rightEAR) / 2.0

		# compute the convex hull for the left and right eye, then
		# visualize each of the eyes
		leftEyeHull = cv2.convexHull(leftEye)
		rightEyeHull = cv2.convexHull(rightEye)
		cv2.drawContours(frame, [leftEyeHull], -1, (0, 255, 0), 1)
		cv2.drawContours(frame, [rightEyeHull], -1, (0, 255, 0), 1)

		# check to see if EAR is below blink threshold
		# increment blink frame counter if so
		if ear < EYE_AR_THRESH:
			COUNTER += 1

			# if eyes closed for enough frames, sound alarm
			if COUNTER >= EYE_AR_CONSEC_FRAMES:
				# if alarm is not on, turn on
				if not ALARM_ON:
					ALARM_ON = True
					PING += 1

					# check for alarm file and play sound
					if args["alarm"] != "":
						t = Thread(target=sound_alarm,
							args=(args["alarm"],))
						t.deamon = True
						t.start()

				# draw notification on screen
				cv2.putText(frame, "WAKE UP!", (10, 300),
					cv2.FONT_HERSHEY_TRIPLEX, 5, (0, 0, 255), 2)
				
				# if dozed off three times, get location and send to
				# emergency contacts
				if PING == 3:
					# send location to emergency contacts
					session = requests.Session()
					params = {'key': 'AIzaSyAmEPFwIt5Uc4-fFrRtE2r1BbIYbIFaq5w'}
					res = session.post(url='https://www.googleapis.com/geolocation/v1/geolocate', params=params).json()
					location = res['location']
					lat = location['lat']
					lng = location['lng']
					accuracy = res['accuracy'] / 1609.344
					messageScreen = "Your friends have been notified of your location! Lat = {0:.6g} Long = {1:.6g}".format(lat, lng)
					textMap = "http://maps.google.com/?q={},{}".format(lat, lng)
					
					cv2.putText(frame, messageScreen, (10, 50),
						cv2.FONT_HERSHEY_TRIPLEX, 1, (0, 0, 255), 2)
						
					# find closest gas station
					session = requests.Session()
					params2 = {'key': 'AIzaSyAmEPFwIt5Uc4-fFrRtE2r1BbIYbIFaq5w',
							'type': 'gas_station',
							'opennow': 'true',
							'rankby': 'distance',
							'location': '{},{}'.format(lat, lng),
							}
					res2 = session.get(url='https://maps.googleapis.com/maps/api/place/nearbysearch/json', params=params2).json()
					gasInfo = res2['results'][0]
					closestLat = gasInfo['geometry']['location']['lat']
					closestLng = gasInfo['geometry']['location']['lng']
					directionsMap = "https://www.google.com/maps/dir/?api=1&origin={},{}&destination={},{}&travelmode=driving&dir_action=navigate".format(lat, lng, closestLat, closestLng)

					for number in numbers_to_message:
						message = client.messages.create(
							body="Your friend is falling asleep at the wheel at: {0} within a radius of {1:.3g} miles.".format(textMap, accuracy),
							from_=sender,
							to=number
						)
						print(message.sid)
						
					message = client.messages.create(
						body="You are falling asleep! Here is the closest gas station: {}".format(directionsMap),
						from_=sender,
						to=userNumber
					)
					print(message.sid)
						
					PING = 0

		# otherwise, EAR not below threshold
		# reset counter and alarm
		else:
			COUNTER = 0
			ALARM_ON = False

		# draw EAR for debugging purposes
		cv2.putText(frame, "EAR: {:.2f}".format(ear), (600, 30),
			cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
 
	# show frame
	cv2.imshow("Frame", frame)
	key = cv2.waitKey(1) & 0xFF
 
	# if `q` key pressed, break from loop (quit app)
	if key == ord("q"):
		break

# cleanup
cv2.destroyAllWindows()
vs.stop()