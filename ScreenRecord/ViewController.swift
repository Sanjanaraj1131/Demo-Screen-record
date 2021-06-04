//
//  ViewController.swift
//  ScreenRecord
//
//  Created by Sanjana Work on 04/06/21.
//

import UIKit
import AVKit
import CoreMedia
import ReplayKit
import Photos


class ViewController: UIViewController,RPPreviewViewControllerDelegate {
    
    @IBOutlet weak var PlayerView: UIView!
    @IBOutlet weak var NextBtn: UIButton!
    @IBOutlet weak var CameraView: UIView!
    let recorder = RPScreenRecorder.shared()
    var videoOutputURL : URL!
    var videoWriter : AVAssetWriter!
    var videoWriterInput : AVAssetWriterInput!
    var audioWriterInput : AVAssetWriterInput!
    var playerLayerAV : AVPlayerLayer!
    
    var myAsset : AVAsset!
    var startSession = false
    var urls = [URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!,
                URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
                URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!]
    //Add items to urls array
    var playerItems = [AVPlayerItem]()
    var playerItem : AVPlayerItem!
    var videoPlayer : AVQueuePlayer!
    var current_track = 0
    private var isRecording = false
    
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    var previewView : UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        play_video()
        self.setupAVCapture()
        self.startRecordingVideo()

        
      //  screenRecord.viewOverlay.stopButtonColor = UIColor.red
      /*  let randomNumber = arc4random_uniform(9999);
        screenRecord.startRecording(withFileName: "coolScreenRecording\(randomNumber)", recordingHandler: { (error) in
           // print("Recording in progress")
        }) { (error) in
            print("Recording Complete")
        }*/
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name("isbackground"), object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name("isOnline"), object: nil)
    }
    
    

    @objc func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        if type == .began {
            // Interruption began, take appropriate actions (save state, update user interface)
            self.videoPlayer.pause()
            self.stopCamera()
            //self.stopRecordingVideo()
        } else if type == .ended {
            guard let optionsValue =
                    info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Interruption Ended - playback should resume
                videoPlayer.play()
                self.setupAVCapture()
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.multiRoute)
                } catch let error as NSError {
                    print(error)
                }
                
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch let error as NSError {
                    print(error)
                }
                //self.startRecordingVideo()
            }
        }
    }
    
    @objc func appMovedToForeground() {
        print("App moved to Forground!")
        //play_video()
        videoPlayer.play()
        self.setupAVCapture()
        self.startRecordingVideo()
    }
    
    @objc func appMovedToBackground() {
        print("App moved to Background!")
        //videoPlayer.remove(self.playerItem)
        videoPlayer?.pause()
        //playerLayerAV = nil
        //playerItem = AVPlayerItem(asset: myAsset)
        //videoPlayer = nil
        //videoPlayer = AVQueuePlayer()
       // videoPlayer.removeAllItems()
       // playerItems.removeAll()
        print(playerItems)
        //videoPlayer?.replaceCurrentItem(with: playerItem)
        //self.stopRecordingVideo()
        self.stopCamera()
        
        //play_video()
        //self.setupAVCapture()
        //self.start_recording()
    }
    
    func play_video(){
        //self.urls.append()
        
        //
        urls.forEach { (url) in
            
            myAsset = AVAsset(url: url)
            playerItem = AVPlayerItem(asset: myAsset)
            playerItems.append(playerItem)
            //print()
        }
        
        videoPlayer = AVQueuePlayer(items: playerItems)
        
        playerLayerAV = AVPlayerLayer(player: videoPlayer)
        playerLayerAV.frame = self.PlayerView.bounds
        videoPlayer.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self,selector: #selector(playerItemDidReachEnd),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,object: nil)
        self.PlayerView.layer.addSublayer(playerLayerAV)
        NextBtn.isEnabled = false
        videoPlayer.play()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.multiRoute)
        } catch let error as NSError {
            print(error)
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(error)
        }
    }
    
    
    
    
   
    
    
    private func startRecordingVideo(){

        //Initialize MP4 Output File for Screen Recorded Video
           let fileManager = FileManager.default
           let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
           guard let documentDirectory: NSURL = urls.first as NSURL? else {
               fatalError("documentDir Error")
           }
           videoOutputURL = documentDirectory.appendingPathComponent("OutputVideo.mov")

           if FileManager.default.fileExists(atPath: videoOutputURL!.path) {
               do {
                   try FileManager.default.removeItem(atPath: videoOutputURL!.path)
               } catch {
                   fatalError("Unable to delete file: \(error) : \(#function).")
               }
           }

        //Initialize Asset Writer to Write Video to User's Storage
        videoWriter = try! AVAssetWriter(outputURL: videoOutputURL!, fileType:
            AVFileType.mov)

        let videoOutputSettings: Dictionary<String, Any> = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : UIScreen.main.bounds.size.width,
            AVVideoHeightKey : UIScreen.main.bounds.size.height,
        ];

        let audioSettings = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 1,
            AVSampleRateKey : 44100.0,
            AVEncoderBitRateKey: 96000,
            ] as [String : Any]


        videoWriterInput  = AVAssetWriterInput(mediaType: AVMediaType.video,outputSettings: videoOutputSettings)
        audioWriterInput  = AVAssetWriterInput(mediaType: AVMediaType.audio,outputSettings:audioSettings )

        videoWriterInput?.expectsMediaDataInRealTime = true
        audioWriterInput?.expectsMediaDataInRealTime = true

        videoWriter?.add(videoWriterInput!)
        videoWriter?.add(audioWriterInput!)


           let sharedRecorder = RPScreenRecorder.shared()
           sharedRecorder.isMicrophoneEnabled = true
           sharedRecorder.startCapture(handler: {
               (sample, bufferType, error) in

            //Audio/Video Buffer Data returned from the Screen Recorder
               if CMSampleBufferDataIsReady(sample) {

                   DispatchQueue.main.async { [weak self] in

                    //Start the Asset Writer if it has not yet started
                       if self?.videoWriter?.status == AVAssetWriter.Status.unknown {
                           if !(self?.videoWriter?.startWriting())! {
                               return
                           }
                           self?.videoWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
                           self?.startSession = true
                       }

                   }
                //Handle errors
                   if self.videoWriter?.status == AVAssetWriter.Status.failed {
                    print(error)

                       //print("Error occured, status = \(String(describing: self.videoWriter?.status.rawValue)),\(String(describing: self.videoWriter?.error!.localizedDescription)) \(String(describing: self.videoWriter?.error))")

                       return
                   }
                //Add video buffer to AVAssetWriter Video Input
                if (bufferType == .video)
                   {
                       if(self.videoWriterInput!.isReadyForMoreMediaData) && self.startSession {
                           self.videoWriterInput?.append(sample)
                       }
                   }
                //Add audio microphone buffer to AVAssetWriter Audio Input
                   if (bufferType == .audioMic)
                   {
                         //print("MIC BUFFER RECEIVED")
                       if self.audioWriterInput!.isReadyForMoreMediaData
                       {
                          // print("Audio Buffer Came")
                           self.audioWriterInput?.append(sample)
                       }
                   }
               }

           }, completionHandler: {
               error in
               print("COMP HANDLER ERROR", error?.localizedDescription)
           })
    }

    private func stopRecordingVideo(){
        self.startSession = false
        RPScreenRecorder.shared().stopCapture{ (error) in
            self.videoWriterInput?.markAsFinished()
            self.audioWriterInput?.markAsFinished()

            if error == nil{
                self.videoWriter?.finishWriting{
                    self.startSession = false
                    print("FINISHED WRITING!")
                    DispatchQueue.main.async {
                        print(self.videoOutputURL)
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoViewController") as! VideoViewController
                        vc.modalPresentationStyle = .fullScreen
                        vc.Video_url = self.videoOutputURL
                        self.present(vc, animated: true, completion: nil)
                       /* PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoOutputURL)
                        }) { saved, error in
                            if saved {
                                print("Saved successfully")
                              //  let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                                //let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                //alertController.addAction(defaultAction)
                                //self.present(alertController, animated: true, completion: nil)
                            }
                            if error != nil {
                                print("Video did not save for some reason", error.debugDescription);
                                //debugPrint(error?.localizedDescription ?? "error is nil");
                            }
                        }*/
                       // self.setUpVideoPreview()
                    }
                }
            }else{
                //DELETE DIRECTORY
            }
        }

    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        print(previewController)
        dismiss(animated: true)
    }
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        print(userActivity?.referrerURL)
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        //videoPlayer.seek(to: CMTime.zero)
        // print(urls[current_track += 1])
        if current_track + 1 > playerItems.count{
            current_track = 0
        }
        else{
            current_track += 1
            print(current_track)
            
        }
        if current_track == playerItems.count{
            NextBtn.isEnabled = true
            NextBtn.setTitle("Finish", for: .normal)
            videoPlayer.pause()
        }
        else{
            NextBtn.isEnabled = true
            NextBtn.setTitle("Next", for: .normal)
            videoPlayer.pause()
        }
        
        
        // }
        
    }
    
    @IBAction func NextBtnOnPressed(_ sender: Any) {
        
        if current_track == playerItems.count{
            NextBtn.isEnabled = true
            NextBtn.setTitle("Finish", for: .normal)
            stopRecordingVideo()
           }
        else{
            NextBtn.isEnabled = false
            videoPlayer.advanceToNextItem()
            videoPlayer.play()
        }
        
        
        
        
        
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        videoPlayer.pause()
    }
}

// AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods
extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSession.Preset.hd1280x720
        guard let device = AVCaptureDevice
                .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                         for: .video,
                         position: AVCaptureDevice.Position.front) else {
            return
        }
        captureDevice = device
        beginSession()
    }
    
    func beginSession(){
        var deviceInput: AVCaptureDeviceInput!
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }
            
            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }
            
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames=true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
            
            if session.canAddOutput(self.videoDataOutput){
                session.addOutput(self.videoDataOutput)
            }
            
            videoDataOutput.connection(with: .video)?.isEnabled = true
            
            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            let rootLayer :CALayer = self.CameraView.layer
            rootLayer.masksToBounds=true
            previewLayer.frame = rootLayer.bounds
            rootLayer.addSublayer(self.previewLayer)
            session.startRunning()
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // do stuff here
    }
    
    // clean up AVCapture
    func stopCamera(){
        session.stopRunning()
    }
    
}

/* func start_recording(){
 
 guard recorder.isAvailable else {
     print("Recording is not available at this time.")
     return
 }
 
 // if micToggle.isOn {
 recorder.isMicrophoneEnabled = true
 let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
 self.videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("MyVideo.mp4"))
 
 //Check the file does not already exist by deleting it if it does
 do {
     try FileManager.default.removeItem(at: videoOutputURL)
 } catch {}
 
 
 do {
     try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mp4)
 } catch let writerError as NSError {
     print("Error opening video file", writerError);
     videoWriter = nil;
     return;
 }
 
 //Create the video settings
 let videoSettings: [String : Any] = [
     AVVideoCodecKey  : AVVideoCodecType.h264,
     AVVideoWidthKey : UIScreen.main.bounds.size.width,
     AVVideoHeightKey : UIScreen.main.bounds.size.height,
 ]
 var channelLayout = AudioChannelLayout.init()
 channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_5_1_D
 let audioOutputSettings: [String : Any] = [
     AVNumberOfChannelsKey: 6,
     AVFormatIDKey: kAudioFormatMPEG4AAC_HE,
     AVSampleRateKey: 44100,
     AVChannelLayoutKey: NSData(bytes: &channelLayout, length: MemoryLayout.size(ofValue: channelLayout)),
 ]
 
 //Create the asset writer input object whihc is actually used to write out the video
 //with the video settings we have created
 audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
 videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings);
 videoWriter.add(videoWriterInput)
 videoWriter.add(audioWriterInput)
 
 videoWriterInput.expectsMediaDataInRealTime = true
 audioWriterInput.expectsMediaDataInRealTime = true
 
 
 recorder.startCapture { CMSampleBuffer, rpSampleType, error in
     guard error == nil else {
         //Handle error
         print("Error starting capture");
         return;
     }
     
     switch rpSampleType {
     case RPSampleBufferType.video:
        // print("writing sample....");
         if self.videoWriter.status == AVAssetWriter.Status.unknown {
             
             if (( self.videoWriter?.startWriting ) != nil) {
                 //print("Starting writing");
                 self.videoWriter.startWriting()
                 self.videoWriter.startSession(atSourceTime:  CMSampleBufferGetPresentationTimeStamp(CMSampleBuffer))
             }
         }
         
         if self.videoWriter.status == AVAssetWriter.Status.writing {
             if (self.videoWriterInput.isReadyForMoreMediaData == true) {
                // print("Writting a sample");
                 if  self.videoWriterInput.append(CMSampleBuffer) == false {
                     print(" we have a problem writing video")
                 }
             }
             
         }
         
         
         
     default:
         print("")
        // print("not a video sample, so ignore");
     }
 }
 completionHandler: { error in
     print(error)
 }

 

         //Tell the screen recorder to start capturing and to call the handler when it has a
         //sample
}

func stop_recording(){
 recorder.stopCapture( handler: { (error) in
     print("stopping recording");
 })
 self.videoWriterInput.markAsFinished();
 self.videoWriter.finishWriting {
     print("finished writing video");
     
     //Now save the video
     PHPhotoLibrary.shared().performChanges({
         PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoOutputURL)
     }) { saved, error in
         if saved {
             print("Saved successfully")
           //  let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
             //let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
             //alertController.addAction(defaultAction)
             //self.present(alertController, animated: true, completion: nil)
         }
         if error != nil {
             print("Video did not save for some reason", error.debugDescription);
             //debugPrint(error?.localizedDescription ?? "error is nil");
         }
     }
 }
 //print(self.videoOutputURL)
// let vc = storyboard?.instantiateViewController(withIdentifier: "VideoViewController") as! VideoViewController
// vc.modalPresentationStyle = .fullScreen
// vc.Video_url = self.videoOutputURL
// self.present(vc, animated: true, completion: nil)
}

func startRecording() {
 
 
 guard recorder.isAvailable else {
     print("Recording is not available at this time.")
     return
 }
 
 // if micToggle.isOn {
 recorder.isMicrophoneEnabled = true
 //} else {
 //  recorder.isMicrophoneEnabled = false
 //}
 
 recorder.startRecording{ [unowned self] (error) in
     
     guard error == nil else {
         print("There was an error starting the recording.")
         return
     }
     
     print("Started Recording Successfully")
     //self.micToggle.isEnabled = false
     //self.recordButton.backgroundColor = UIColor.red
     //self.statusLabel.text = "Recording..."
     //self.statusLabel.textColor = UIColor.red
     
     self.isRecording = true
     
 }
 
}



func stopRecording() {
 
 recorder.stopRecording { [unowned self] (preview, error) in
     print("Stopped recording")
     
     
     guard preview != nil else {
         print("Preview controller is not available.")
         return
     }
     
     let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
     
     let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
         self.recorder.discardRecording(handler: { () -> Void in
             print("Recording suffessfully deleted.")
         })
     })
     
     let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
         preview?.previewControllerDelegate = self
         preview?.modalPresentationStyle = .fullScreen
         preview?.navigationController?.navigationBar.isHidden = true
         self.present(preview!, animated: true, completion: nil)
     })
     
     alert.addAction(editAction)
     alert.addAction(deleteAction)
     self.present(alert, animated: true, completion: nil)
     
     self.isRecording = false
     
     // self.viewReset()
     
 }
 
}*/
