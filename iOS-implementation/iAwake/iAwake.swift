//
//  ViewController.swift
//  iAwake
//
//  Created by Jack Brewer on 3/30/19.
//  Copyright © 2019 Jack Brewer. All rights reserved.
//
import UIKit
import CoreLocation
import ARKit
import AVFoundation

import Foundation
import Alamofire


//var emergencyContactNumber = "+13109947617"
//var twilioPhoneNumber = "+15103690674"


var player: AVAudioPlayer?

func playSound() {
    guard let url = Bundle.main.url(forResource: "alarmNew", withExtension: "wav") else { return }
    
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
        
        /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
        player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
        
        /* iOS 10 and earlier require the following line:
         player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
        
        guard let player = player else { return }
        
        player.play()
        
    } catch let error {
        print(error.localizedDescription)
    }
}
class iAwake: UIViewController
{
    
 
    @IBOutlet weak var image: UIImageView!
    
    let noseOptions = [" "]
    let eyeOptions = [" "]
    let mouthOptions = [" "]
    let hatOptions = [" "]
    
    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[9], [1064], [42], [24, 25], [20]]
    var leftCounter = 0
    var rightCounter = 0
    var soundBool = true
    var soundCounter = 0
    var numTimesSlept = 0
    var threeTimesBool = false
    let locManager = CLLocationManager()
    
    @IBOutlet var sceneView: ARSCNView!
    override func viewDidLoad() {
       //image.layer.cornerRadius = image.frame.size.width / 2
       //image.clipsToBounds = true;
        
        locManager.requestWhenInUseAuthorization()
        super.viewDidLoad()
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        // Do any additional setup after loading the view, typically from a nib.
        sceneView.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1
        let configuration = ARFaceTrackingConfiguration()
        
        // 2
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        // 1
        sceneView.session.pause()
    }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        // 1
        // 1
        for (feature, indices) in zip(features, featureIndices)  {
            // 2
            let child = node.childNode(withName: feature, recursively: false) as? EmojiNode
            
            // 3
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            
            // 4
            child?.updatePosition(for: vertices)
            switch feature {
                
            // 2
            case "leftEye":
                
                // 3
                let scaleX = child?.scale.x ?? 1.0
                
                // 4
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
                //print(eyeBlinkValue)
                
                if(eyeBlinkValue > 0.85)
                {
                    leftCounter += 1
                }
                else
                {
                    leftCounter = 0
                }
                // 5
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
            case "rightEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
                
                if(eyeBlinkValue > 0.85)
                {
                    rightCounter += 1
                }
                else
                {
                    rightCounter = 0
                }
                
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
            // 6
            default:
                break
            }
            if(leftCounter >= 90 && rightCounter >= 90)
            {
                if(soundBool == true)
                {
                    playSound()
                    soundBool = false
                    numTimesSlept += 1
                }
                else if(soundCounter >= 650)
                {
                    soundCounter = 0
                    playSound()
                }
                else
                {
                    soundCounter += 1
                }
            }
            else
            {
                soundBool = true
            }
            
            if(numTimesSlept == 3 && threeTimesBool == false)
            {
                print("You have fallen asleep three times, your emergency contact x was contacted, Click Enter to be directed to the nearest gas station")
                //Send texts Twillio
                
                var currentLocation: CLLocation!
                
                if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() ==  .authorizedAlways){
                    
                    currentLocation = locManager.location
                }
                
                let lat = "\(currentLocation.coordinate.latitude)"
                let lng = "\(currentLocation.coordinate.longitude)"
                
                let placeParam = ["key": "AIzaSyDhZ0QL7TXtPf0r02gtW7oCDoJm_cVkY9A",
                                  "type": "gas_station",
                                  "opennow": "true",
                                  "rankby": "distance",
                                  "location": lat + "," + lng]
                let placeURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
                
                Alamofire.request(placeURL, method: .get, parameters: placeParam)
                    .responseJSON { response in
                        
                        if let responseData = response.result.value as? [String: Any] {
                            //print(responseData)
                        
                            if let results = responseData["results"] as? [Int: Any] {
                                print(results)
                                print("AHDGFJF")
                                if let first = results[0] as? [String: Any] {
                                    print(first)
                                    print("AHDFGJDAFJDGHFJ")
                                    if let geo = first["geometry"] as? [String: Any]{
                                        print(geo)
                                    }
                                    
                                }
                            
                                
                            }
                        }
                        //let data: Data=response
                        //let responseData = try? JSONSerialization.jsonObject(with: data, options: [])
                    
            }
                
            
                
                let output = "Your friend is falling asleep at the wheel at http://maps.google.com/?q=" + lat + "," + lng

                let twilioUrl = "https://api.twilio.com/2010-04-01/Accounts/AC3e220f999406b7030d12d76f5b1babb3/Messages"
                
                let arr = ["+13109947617", "+19252553815"]
                
                for i in arr
                {
                let twilioParameters = ["From": "+15103690674", "To": i, "Body": output]
                
                    Alamofire.request(twilioUrl, method: .post, parameters: twilioParameters)
                        .authenticate(user: "AC3e220f999406b7030d12d76f5b1babb3", password: "ce168b24400fe07db8fce466c889c830")
                        .responseJSON { response in
                            debugPrint(response)
                    }
                }
                    
                    
                    RunLoop.main.run()
                
                //Do googleMaps geolocation
                //Do googleMaps places
                //Send pop-up alert to you
                threeTimesBool = true
            }
            
        }
        
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        // 1
        let location = sender.location(in: sceneView)
        
        // 2
        let results = sceneView.hitTest(location, options: nil)
        
        // 3
        if let result = results.first,
            let node = result.node as? EmojiNode {
            
            // 4
            node.next()
        }
        
    }
    
    
}

// 1

extension iAwake: ARSCNViewDelegate {
    // 2
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        // 3
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let device = sceneView.device else {
                return nil
        }
        
        
        // 4
        let faceGeometry = ARSCNFaceGeometry(device: device)
        
        // 5
        let node = SCNNode(geometry: faceGeometry)
        
        // 6
        node.geometry?.firstMaterial?.fillMode = .lines
        // 1
        node.geometry?.firstMaterial?.transparency = 0.5
        
        // 2
        let noseNode = EmojiNode(with: noseOptions)
        
        // 3
        noseNode.name = "nose"
        
        // 4
        node.addChildNode(noseNode)
        
        let leftEyeNode = EmojiNode(with: eyeOptions)
        leftEyeNode.name = "leftEye"
        leftEyeNode.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
        node.addChildNode(leftEyeNode)
        
        let rightEyeNode = EmojiNode(with: eyeOptions)
        rightEyeNode.name = "rightEye"
        node.addChildNode(rightEyeNode)
        
        let mouthNode = EmojiNode(with: mouthOptions)
        mouthNode.name = "mouth"
        node.addChildNode(mouthNode)
        
        let hatNode = EmojiNode(with: hatOptions)
        hatNode.name = "hat"
        node.addChildNode(hatNode)
        
        
        // 5
        updateFeatures(for: node, using: faceAnchor)
        
        // 7
        return node
    }
    // 1
    func renderer(
        _ renderer: SCNSceneRenderer,
        didUpdate node: SCNNode,
        for anchor: ARAnchor) {
        
        // 2
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
        }
        
        // 3
        faceGeometry.update(from: faceAnchor.geometry)
        updateFeatures(for: node, using: faceAnchor)
    }
}

