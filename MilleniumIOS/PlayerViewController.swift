//
//  PlayerViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 11/09/2019.
//  Copyright © 2019 Station Millenium. All rights reserved.


import UIKit
import MediaPlayer
import MatomoTracker
import Foundation


// MARK: - Last5Song
struct Last5Song: Codable {
    let time: String
    let isTrack, isImage: Bool
    let artist, title: String

    enum CodingKeys: String, CodingKey {
        case time
        case isTrack = "is_track"
        case isImage = "is_image"
        case artist, title
    }
}

class last5songCell: UICollectionViewCell {

    var tintView: UIView!
    
    @IBOutlet weak var UIimageView: UIImageView!
    
    @IBOutlet weak var ArtistLabel: SpringLabel!
    
    @IBOutlet weak var TitleLabel: UILabel!
    
}

class PlayerViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource{
    
    
    let replayPlayerViewController = ReplayPlayerViewController()

    @IBOutlet weak var ArtworkImg: SpringImageView!
    @IBOutlet weak var SongName: SpringLabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var LoadingWeel: UIActivityIndicatorView!

    @IBOutlet weak var PlayPauseButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    //Declaration player & variable de titre
    public static let player = FRadioPlayer.shared
    let notification = NotificationCenter.default
    var track: Track? {
        didSet {
            SongName.text = track?.artist
            artistLabel.text = track?.name
            updateNowPlaying(with: track)
        }
    }
    
    public var last5songs = [Last5Song]()

    let now = Date()
    var autoPlay : Int?
    let matomoTrackerPlayer = MatomoTracker(siteId: "2", baseURL: URL(string: "https://www.station-millenium.com/piwik/piwik.php")!)
    let settings = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PlayerViewController.player.delegate = self
        self.LoadingWeel.hidesWhenStopped = true
        if settings.bool(forKey: "auto_play") == true{
        setupRadioPlayer()
        }else{}

        setupRemoteTransportControls()
        matomoTrackerPlayer.isOptedOut = ViewController.OptedOut
        
        collectionView.dataSource = self
        collectionView.delegate = self
        self.ArtworkImg.image = UIImage(named: "MilleniumLogo");
        track = Track(artist: "Hits & Mix", name: "Millenium")
        ViewController.matomoTracker.track(view: ["Player"])
    }
    
    @IBAction func PlayButton(_ sender: Any) {
        setupRadioPlayer()
    }
    
    static func stopRadioPlayer(){
         PlayerViewController.player.stop()
    }
    
    //si vue rechargé ne pas reset le player et le laisser jouer la radio
    func setupRadioPlayer() {
        if  PlayerViewController.player.isPlaying == false{
            //Si la radio n'est pas en lecture Sa lance le streaming
            notification.post(name: Notification.Name("StopMusic"), object: nil)
            PlayerViewController.player.radioURL = URL(string: "https://www.station-millenium.com/millenium.mp3")
            matomoTrackerPlayer.trackGoal(id: 5, revenue: 00.00)
            PlayPauseButton.setImage(UIImage(named: "btn-pause.png"), for: .normal)
        }else{
            PlayerViewController.player.stop()
            PlayPauseButton.setImage(UIImage(named: "btn-play.png"), for: .normal)
        }
    }
    
    let formatter = DateFormatter()
    func getData() {  // Recupere la data met a jour les 5 derniers titres
    formatter.dateFormat = "yyyyMMdd-HHmmss"
      guard let url = URL(string: "https://dev.station-millenium.com:8080/coverart/api/v1/getLast5Tracks") else {return}
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config);
        session.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                do {
                    self.last5songs = try JSONDecoder().decode([Last5Song].self, from: data!)
                    //let utf8Data: Data = String(data: data!, encoding: .ascii).flatMap { $0.data(using: .utf8) }!
                    //let songs = try JSONDecoder().decode(currentSongs.self, from: utf8Data)
                    self.collectionView.reloadData()
                } catch {
                    print("\(error)")
                }
            }
        }.resume()
    }
    
// MARK: - Table view data source
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return last5songs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! last5songCell
        let songs = last5songs[indexPath.row]
        cell.TitleLabel.text = songs.title
         cell.ArtistLabel.text = songs.artist
          //setup place holder image
         cell.UIimageView.image = UIImage(named: "MilleniumLogo")
                //setup tintview while the image is loading
            if cell.tintView == nil {
                let tintView = UIView()
                tintView.backgroundColor = UIColor(white: 0, alpha: 0.2) //change to your liking
                tintView.frame = CGRect(x: 0, y: 0, width: cell.UIimageView.frame.width, height: cell.UIimageView.frame.height)
                cell.UIimageView.addSubview(tintView)
                cell.tintView = tintView // By Angel.Alice on Swift discord
            }
                //start loading image in background, after it is loaded, set the image to imageview.
                 DispatchQueue.global(qos: .background).async {
                    if (songs.isImage != false){
                            let url = URL(string: "https://dev.station-millenium.com:8080/coverart/api/v1/getImage/\(String(describing: songs.time))")
                               if let data = try? Data(contentsOf: url!), let image = UIImage(data: data) {
                                   DispatchQueue.main.async {
                                       cell.UIimageView.image = image
                                   }
                               }
                    }
                }
            return cell
        }
    // MARK: - Setup Remote controls
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            if  PlayerViewController.self.player.rate == 0.0 {
                 PlayerViewController.self.player.play()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            if  PlayerViewController.self.player.rate == 1.0 {
                 PlayerViewController.self.player.pause()
                return .success
            }
            return .commandFailed
        }
        
    }
    
    // MARK: - Update Now playing
    func updateNowPlaying(with track: Track?) {
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        
        if let artist = track?.artist{
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = track?.name ?? "Millenium"
        
        
        if let image = track?.image {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ -> UIImage in
                return image
            })
        }
        
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
 }
}
// MARK: - FRadioPlayer Delegate
extension PlayerViewController: FRadioPlayerDelegate {
        
        func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState) {
            if state.description == "Loading" {
                LoadingWeel.startAnimating()
            }else{
                LoadingWeel.stopAnimating()
            }
        }
        
        func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlaybackState) {}
        
        func radioPlayer(_ player: FRadioPlayer, metadataDidChange artistName: String?, trackName: String?) {
            self.track = Track(artist: artistName, name: trackName)
            DispatchQueue.global().async {
            sleep(5)
             self.getData()
            }
        }
        
        func radioPlayer(_ player: FRadioPlayer, itemDidChange url: URL?) {
            track = Track(artist: "Hits & Mix", name: "Millenium")
        }
        
        func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?) {}
        //MARK: - Updating ArtWork
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        
    DispatchQueue.global(qos: .background).async {
      guard let artworkURL = artworkURL, let data = try? Data(contentsOf: artworkURL) else {
         DispatchQueue.main.async {
            self.ArtworkImg.image = UIImage(named: "MilleniumLogo");
            }
              return
            }

            DispatchQueue.main.async {
                self.track?.image =  UIImage(data: data)
                self.ArtworkImg.image = self.track?.image
                self.updateNowPlaying(with: self.track)
            }
            }
        }
}
