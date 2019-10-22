//
//  ReplayPlayerViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 26/09/2019.
//  Copyright © 2019 Station Millenium. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ReplayPlayerViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var playerSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var PodcastTitle: SpringLabel!
    @IBOutlet weak var Podcast: UILabel!
    @IBOutlet weak var ImageView: UIImageView!
    
    var avPlayer: AVPlayer!
    var timer: Timer?
    var songUrlString : String = ""
    var podcastTitle : String = ""
    var podcast : String = ""
    var imgURL : String? = nil
    

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let songUrl = URL(string:songUrlString) else{return}
        self.play(url: songUrl)
        self.setupTimer()
        PodcastTitle.text = podcastTitle
        Podcast.text = podcast

        let formatedURL = URL(string: imgURL!)
        if formatedURL != nil {
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: formatedURL!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                DispatchQueue.main.async {
                    if data != nil {
                        self.ImageView.image = UIImage(data:data!)
                    }else{
                        self.ImageView.image = UIImage(named: "MilleniumLogo")
                    }
                }
            }
        }
    }
    
    
    @IBAction func PlayButton(_ sender: Any) {
        avPlayer.play()
    }
    
    @IBAction func PauseButton(_ sender: Any) {
        avPlayer.pause()
    }
    
    
    func play(url:URL) {
        PlayerViewController.self.player.stop()
        self.avPlayer = AVPlayer(playerItem: AVPlayerItem(url: url))
        self.avPlayer.automaticallyWaitsToMinimizeStalling = false
        avPlayer!.volume = 1.0
        avPlayer.play()
    }
    
    
    @IBAction func sliderValueChange(_ sender: UISlider) {
        let seconds : Int64 = Int64(sender.value)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        avPlayer!.seek(to: targetTime)
    }
    
    @IBAction func sliderTapped(_ sender: UILongPressGestureRecognizer) {
        if let slider = playerSlider {
            if slider.isHighlighted { return }
            let point = sender.location(in: slider)
            let percentage = Float(point.x / slider.bounds.width)
            let delta = percentage * (slider.maximumValue - slider.minimumValue)
            let value = slider.minimumValue + delta
            slider.setValue(value, animated: false)
            let seconds : Int64 = Int64(value)
            let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
            avPlayer!.seek(to: targetTime)
        }
    }
    
    
    func setupTimer(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        timer = Timer(timeInterval: 0.001, target: self, selector: #selector(ReplayPlayerViewController.tick), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
    }
    
    @objc func tick(){
        if((avPlayer.currentItem?.asset.duration) != nil){
            if let _ = avPlayer.currentItem?.asset.duration{}else{return}
            if let _ = avPlayer.currentItem?.currentTime(){}else{return}
            let currentTime1 : CMTime = (avPlayer.currentItem?.asset.duration)!
            let seconds1 : Float64 = CMTimeGetSeconds(currentTime1)
            let time1 : Float = Float(seconds1)
            playerSlider.minimumValue = 0
            playerSlider.maximumValue = time1
            let currentTime : CMTime = (self.avPlayer?.currentTime())!
            let seconds : Float64 = CMTimeGetSeconds(currentTime)
            let time : Float = Float(seconds)
            self.playerSlider.value = time
            timeLabel.text =  self.formatTimeFromSeconds(totalSeconds: Int32(Float(Float64(CMTimeGetSeconds((self.avPlayer?.currentItem?.asset.duration)!)))))
            currentTimeLabel.text = self.formatTimeFromSeconds(totalSeconds: Int32(Float(Float64(CMTimeGetSeconds((self.avPlayer?.currentItem?.currentTime())!)))))
        }else{
            playerSlider.value = 0
            playerSlider.minimumValue = 0
            playerSlider.maximumValue = 0
            timeLabel.text = "Live stream \(self.formatTimeFromSeconds(totalSeconds: Int32(CMTimeGetSeconds((avPlayer.currentItem?.currentTime())!))))"
        }
    }
    
    func formatTimeFromSeconds(totalSeconds: Int32) -> String {
        let seconds: Int32 = totalSeconds%60
        let minutes: Int32 = (totalSeconds/60)%60
        let hours: Int32 = totalSeconds/3600
        return String(format: "%02d:%02d:%02d", hours,minutes,seconds)
    }
    
    @objc func didPlayToEnd() {
        avPlayer.pause()
    }
    
    override func viewWillDisappear( _ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.avPlayer = nil
        self.timer?.invalidate()
    }
}
