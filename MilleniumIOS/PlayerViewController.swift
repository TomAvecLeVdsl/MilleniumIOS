//
//  PlayerViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 11/09/2019.
//  Copyright © 2019 Station Millenium. All rights reserved.


import UIKit
import MediaPlayer
import Alamofire


/* This is struct of currentSongs Json*/
struct currentSongs:Codable {
    let currentSong: CurrentSong
    let last5Songs: Last5Songs
}

struct CurrentSong:Codable {
    let artist:String?
    let title:String?
    let image: Image?
    let available: Bool
}

struct Image:Codable {
    let path: String
    let width: String
    let height: String
}
struct Last5Songs:Codable {
    let song : [Song]
}
struct Song:Codable {
    let artist : String
    let title : String
    let image : songimage?
}
struct songimage:Codable {
    let path : String
    let width : String
    let height : String
}


class last5songCell: UICollectionViewCell {

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

    @IBOutlet weak var collectionView: UICollectionView!
    
    
    //Declaration player & variable de titre
    public static let player = FRadioPlayer.shared
    let notification = NotificationCenter.default
    var track: Track? {
        didSet {
            artistLabel.text = track?.artist
            SongName.text = track?.name
            updateNowPlaying(with: track)
        }
    }
    
    var currentsong = [CurrentSong]()
    var last5Songs = [Song]()
    let now = Date()
    var autoPlay : Int?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        PlayerViewController.player.delegate = self
        self.LoadingWeel.hidesWhenStopped = true
        setupRadioPlayer()
        setupRemoteTransportControls()
        
        collectionView.dataSource = self
        collectionView.delegate = self

    }
    
    @IBAction func PlayButton(_ sender: Any) {
        setupRadioPlayer()
    }
    
    @IBAction func StopButton(_ sender: Any) {
         PlayerViewController.player.stop()
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
        }else{
            track = Track(artist: "Hits & Mix", name: "Millenium")
        }
    }
    
    func getData() {  // Recupere la data et met a jours le titre si retour a la vue du player (a ameliorer) (date a cause du cache)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        guard let testUrl = URL(string: "https://www.station-millenium.com/coverart/android/currentSongs?json=true#\(formatter.string(from: now))") else {return}
        AF.request(testUrl, method: .get).responseJSON { (response) in
                guard let data = response.data else {return}
                do{
                    let utf8Data: Data = String(data: data, encoding: .ascii).flatMap { $0.data(using: .utf8) } ?? Data()
                    let songs = try JSONDecoder().decode(currentSongs.self, from: utf8Data)
                    self.currentsong = [songs.currentSong]
                    self.last5Songs =  songs.last5Songs.song
                      DispatchQueue.main.async {
                        self.collectionView!.reloadData()
                        self.collectionView!.collectionViewLayout.invalidateLayout()
                        self.collectionView!.layoutSubviews() } //Do not work
                    print("Fetched data last5Title UPDATE")
                }
                catch{}
        }
    }
    let formatter = DateFormatter()
    func getDataUpdateTitle() {  // Recupere la data et met a jours le titre si retour a la vue du player (a ameliorer)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        guard let testUrl = URL(string: "https://www.station-millenium.com/coverart/android/currentSongs?json=true#\(formatter.string(from: now))") else {return}
        AF.request(testUrl, method: .get).responseJSON { (response) in
                guard let data = response.data else {return}

                do{
                    let utf8Data: Data = String(data: data, encoding: .ascii).flatMap { $0.data(using: .utf8) } ?? Data()
                    let songs = try JSONDecoder().decode(currentSongs.self, from: utf8Data)
                    print("Fetched data")
                    self.track = Track(artist: songs.currentSong.artist , name: songs.currentSong.title)
                    self.last5Songs =  songs.last5Songs.song
                    self.collectionView?.reloadData()
                }
                catch{}
        }
     }
// MARK: - Table view data source
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return last5Songs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! last5songCell
            let songs = last5Songs[indexPath.row]
            cell.TitleLabel.text = songs.title
            cell.ArtistLabel.text = songs.artist
            
            DispatchQueue.main.async {
                if (songs.image?.path != nil){
                    let url = URL(string: "https://www.station-millenium.com/coverart\(String(describing: songs.image!.path))")
                    let data = try? Data(contentsOf: url!)
                    cell.UIimageView.image = UIImage(data: data!)
                }else{
                    cell.UIimageView.image = UIImage(named: "MilleniumLogo");
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
            track = Track(artist: artistName, name: trackName)
            
            DispatchQueue.main.async {
             sleep(4)
             self.getData()
            }
        }
        
        func radioPlayer(_ player: FRadioPlayer, itemDidChange url: URL?) {
            track = Track(artist: "Hits & Mix", name: "Millenium")
        }
        
        func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?) {
        }
        
        func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
            DispatchQueue.main.async {
            guard let artworkURL = artworkURL, let data = try? Data(contentsOf: artworkURL) else {
                    self.ArtworkImg.image = UIImage(named: "MilleniumLogo");
                    return
                }
            self.track?.image = UIImage(data: data)
                self.ArtworkImg.image = self.track?.image
                self.updateNowPlaying(with: self.track)
          }
        }
    }
