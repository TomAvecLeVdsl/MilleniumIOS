//
//  PlayerViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 11/09/2019.
//  Copyright © 2019 Station Millenium. All rights reserved.


import UIKit
import MediaPlayer


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
    let artist:String
    let title:String
}

class PlayerViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var ArtworkImg: SpringImageView!
    @IBOutlet weak var SongName: SpringLabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var LoadingWeel: UIActivityIndicatorView!
    @IBOutlet weak var last5TableView: UITableView! {
        didSet {
            last5TableView.delegate = self;
            last5TableView.dataSource = self;
        }
    }
    
    //Declaration player & variable de titre
    public static let player = FRadioPlayer.shared
    var track: Track? {
        didSet {
            artistLabel.text = track?.artist
            SongName.text = track?.name
            updateNowPlaying(with: track)
        }
    }
    
    var currentsong = [CurrentSong]()
    var last5Songs = [Song]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        PlayerViewController.player.delegate = self
        self.LoadingWeel.hidesWhenStopped = true
        
        setupRadioPlayer()
        
        setupRemoteTransportControls()
        
       
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
            //Si la radio n'est pas en lecture , faire des chauses ici
             PlayerViewController.player.radioURL = URL(string: "https://www.station-millenium.com/millenium.mp3")
        }else{
            track = Track(artist: "Hits & Mix", name: "Millenium")
            getDataUpdateTitle()
        }
    }
    
    func getData() {  // function getData to load the Api
        let url = URL(string : "https://www.station-millenium.com/coverart/android/currentSongs?json=true")
        URLCache.shared.removeAllCachedResponses()
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            DispatchQueue.main.async {
                do {
                    let utf8Data: Data = String(data: data!, encoding: .ascii).flatMap { $0.data(using: .utf8) } ?? Data()
                    if (error == nil) {
                        let songs = try JSONDecoder().decode(currentSongs.self, from: utf8Data)
                        self.currentsong = [songs.currentSong]
                        self.last5Songs =  songs.last5Songs.song
                        self.last5TableView.reloadData()
                        print("Fetched data")
                    }
                } catch {
                    print("\(error)")
                }
            }
            
            }.resume()
    }
    func getDataUpdateTitle() {  // Recupere la data et met a jours le titre si retour a la vue du player (a ameliorer)
         let url = URL(string : "https://www.station-millenium.com/coverart/android/currentSongs?json=true")
        URLCache.shared.removeAllCachedResponses()
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
             DispatchQueue.main.async {
                 do {
                     let utf8Data: Data = String(data: data!, encoding: .ascii).flatMap { $0.data(using: .utf8) } ?? Data()
                     if (error == nil) {
                         let songs = try JSONDecoder().decode(currentSongs.self, from: utf8Data)
                         print("Fetched data")
                         sleep(2)
                         self.track = Track(artist: songs.currentSong.artist , name: songs.currentSong.title)
                         self.last5Songs =  songs.last5Songs.song
                         self.last5TableView.reloadData()
                     }
                 } catch {
                     print("\(error)")
                 }
             }
             
             }.resume()
     }
// MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return last5Songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellId")
        let songs = last5Songs[indexPath.row]
        cell.textLabel?.text = songs.title
        cell.detailTextLabel?.text = songs.artist
        return cell
    }
    
    
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
             sleep(2)
             self.getData()
            }
        }
        
        func radioPlayer(_ player: FRadioPlayer, itemDidChange url: URL?) {
            track = Track(artist: "Hits & Mix", name: "Millenium")
        }
        
        func radioPlayer(_ player: FRadioPlayer, metadataDidChange rawValue: String?) {
        }
        
        func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
            
            // Please note that the following example is for demonstration purposes only, consider using asynchronous network calls to set the image from a URL.
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
