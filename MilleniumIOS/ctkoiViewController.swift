//
//  ctkoiViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 21/10/2019.
//  Copyright © 2019 Station Millenium. All rights reserved.
//
import UIKit

class ctkoiCell: UITableViewCell {
    
    @IBOutlet weak var SongArtist: SpringLabel!
    
    @IBOutlet weak var SongTitle: UILabel!
    
    @IBOutlet weak var ArtworkImage: UIImageView!
    
    @IBOutlet weak var DateLabel: UILabel!
}

class ctkoiViewController: UITableViewController, UISearchBarDelegate  {
    
    @IBOutlet weak var SearchBar: UISearchBar!
    
    let formatter = DateFormatter()
    let now = Date()
    let datePicker = DatePickerDialog(
        textColor: .red,
        buttonColor: .red,
        font: UIFont.boldSystemFont(ofSize: 17),
        showCancelButton: true
    )

    /* This is struct of currentSongs Json*/
    struct searchSongsHistory : Codable {
        let historySong: [HistorySong]
    }

    struct HistorySong : Codable {
        let playedDate : String
        let artist : String?
        let title : String?
        let image : Image?
    }

    struct Image : Codable {
        let path : String
        let width : String
        let height : String
    }

    var historySong = [HistorySong]()
    @IBOutlet weak var DatePickerButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        SearchBar.delegate = self
        SearchBar.placeholder = "Rechercher une musique"
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if (searchBar.text != ""){
            print("Searched:\(SearchBar.text!)")
            getDataWithText(text: SearchBar.text!)
        }else{
            getData()
        }
    }
    
    @IBAction func DatepickerButtonTouched(_ sender: Any) {
        openDatePicker()
    }
    
    func openDatePicker() {
        let currentDate = Date()
        var dateComponents = DateComponents()
        dateComponents.month = -12
        let xMonthAgo = Calendar.current.date(byAdding: dateComponents, to: currentDate)

        datePicker.show("Selectionnez une date",
                        doneButtonTitle: "Terminé",
                        cancelButtonTitle: "Annuler",
                        minimumDate: xMonthAgo,
                        maximumDate: currentDate,
                        datePickerMode: .dateAndTime) { (date) in
            if let dt = date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd-HHmm"
                if (formatter.string(from: dt) == formatter.string(from: self.now)){
                    self.getData()
                }else{
                    self.getDataWithDate(date: formatter.string(from: dt))
                }
            }
        }
    }
    
    func getData() {  // function getData to load the Api
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = URL(string : "https://www.station-millenium.com/coverart/android/searchSongsHistory?json=true")
       let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession.init(configuration: config);
        
        session.dataTask(with: url!) { (data, response, error) in
            DispatchQueue.main.async {
                do {
                    let utf8Data: Data = String(data: data!, encoding: .ascii).flatMap { $0.data(using: .utf8) } ?? Data()
                    if (error == nil) {
                        let songs = try JSONDecoder().decode(searchSongsHistory.self, from: utf8Data)
                        self.historySong = songs.historySong
                        print("Fetched data")
                        self.tableView.reloadData()
                    }
                } catch {
                    print("\(error)")
                }
            }
            
            }.resume()
    }
    func getDataWithDate(date: String) {  // function getData to load the Api

        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = URL(string : "https://station-millenium.com/coverart/android/searchSongsHistory?json=true&action=DATE&query=\(date)")
           let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.urlCache = nil
            let session = URLSession.init(configuration: config);
            
            session.dataTask(with: url!) { (data, response, error) in
            DispatchQueue.main.async {
                do {
                    let utf8Data: Data = String(data: data!, encoding: .ascii).flatMap { $0.data(using: .utf8) } ?? Data()
                    if (error == nil) {
                        let songs = try JSONDecoder().decode(searchSongsHistory.self, from: utf8Data)
                        self.historySong = songs.historySong
                        print("Fetched data")
                        self.tableView.reloadData()
                    }
                } catch {
                    print("\(error)")
                }
            }
            
            }.resume()
    }
    func getDataWithText(text: String) {  // function getData to load the Api
        print(text)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = URL(string : "https://station-millenium.com/coverart/android/searchSongsHistory?json=true&action=FULL_TEXT&query=\(text)")
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            config.urlCache = nil
            let session = URLSession.init(configuration: config);
            
            session.dataTask(with: url!) { (data, response, error) in
            DispatchQueue.main.async {
                do {
                    let utf8Data: Data = String(data: data!, encoding: .ascii).flatMap { $0.data(using: .utf8) } ?? Data()
                    if (error == nil) {
                        let songs = try JSONDecoder().decode(searchSongsHistory.self, from: utf8Data)
                        self.historySong = songs.historySong
                        print("Fetched data")
                        self.tableView.reloadData()
                    }
                } catch {
                    print("\(error)")
                }
            }
            
            }.resume()
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return historySong.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        as! ctkoiCell
        
        let songs = historySong[indexPath.row]
        
        cell.SongArtist.text = songs.artist
        cell.SongTitle.text = songs.title
        
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmm"

        // Change the `...` for your needs
        let date = formatter.date(from: songs.playedDate)

        // Changing the format accordingly or use `DateFormatter.Style`
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        cell.DateLabel.text = formatter.string(from: date!)
        
        let url : URL
        
        if (songs.image?.path != nil){
            url = URL(string: "https://www.station-millenium.com/coverart\(String(describing: songs.image!.path))")!
            
        }else{
            url = URL(string: "https://www.station-millenium.com/wp-millenium/wp-content/uploads/2015/11/MetaSlider-Logo-Mill-Millenium-6.png")!
        }
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url);             DispatchQueue.main.async {
                cell.ArtworkImage.image = UIImage(data: data!)
            }
        }
        return cell
    }
}

