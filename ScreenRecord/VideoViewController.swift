//
//  VideoViewController.swift
//  ScreenRecord
//
//  Created by Sanjana Work on 04/06/21.
//

import UIKit
import AVFoundation

class VideoViewController: UIViewController {

    @IBOutlet weak var VideoView: UIView!
    var Video_url : URL!
    override func viewDidLoad() {
        super.viewDidLoad()

        print(Video_url)
        let videoURL = Video_url
        let player = AVPlayer(url: videoURL!)
        let playerLayer = AVPlayerLayer(player: player)
        NotificationCenter.default.addObserver(self,selector: #selector(playerItemDidReachEnd),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,object: nil)
        playerLayer.frame = self.VideoView.bounds
        self.VideoView.layer.addSublayer(playerLayer)
        player.play()
        // Do any additional setup after loading the view.
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
    exit(0)
    }

}
