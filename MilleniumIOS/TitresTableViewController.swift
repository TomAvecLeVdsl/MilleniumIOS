//
//  TitresTableViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 21/09/2019.
//  Copyright © 2019 Station Millenium. All rights reserved.
//

import UIKit

class titleCell: UITableViewCell {
    
    @IBOutlet weak var SongArtist: SpringLabel!
    
    @IBOutlet weak var ArtworkImage: UIImageView!
}

class TitresTableViewController: UITableViewController {
    
    var id:Int = 0
    var podcast : String = ""
    
    public var courses = [Course]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let alert = UIAlertController(title: nil, message: "Veuillez patienter ...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        
        fetchJSON()
    }
    
    public struct Course: Decodable {
        
        let id: Int
        let title: String
        let imageURL: String?
        let date: String
        let duration: Int
        let fileSize: Int
        let fileURL: String
    }
    
    fileprivate func fetchJSON() {
        let urlString = "https://station-millenium.com/replay-api/v1/podcasts?serie=\(id)"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { (data, _, err) in
            DispatchQueue.main.async {
                if let err = err {
                    print("Failed to get data from url:", err)
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    // link in description for video on JSONDecoder
                    let decoder = JSONDecoder()
                    // Swift 4.1
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    self.courses = try decoder.decode([Course].self, from: data)
                    self.tableView.reloadData()
                    self.dismiss(animated: false, completion: nil)
                    print("reloaded title data")
                    
                } catch let jsonErr {
                    print("Failed to decode:", jsonErr)
                }
            }
            }.resume()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {return 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return courses.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! titleCell
        let course = courses[indexPath.row]
        cell.SongArtist.text = course.title
        cell.ArtworkImage.image = UIImage(named: "MilleniumLogo");
                   DispatchQueue.global(qos: .background).async {
                    if (course.imageURL != nil){
                        let url = URL(string: course.imageURL!)
                           let data = try? Data(contentsOf: url!)
                           DispatchQueue.main.async {
                           cell.ArtworkImage.image = UIImage(data: data!)
                           }
                       }
                       }
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigatio
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //performSegue(withIdentifier: "showPlayer", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showPlayer" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let course = courses[indexPath.row]
                if segue.destination is ReplayPlayerViewController
                {
                    let vc = segue.destination as? ReplayPlayerViewController
                    vc?.podcast = podcast
                    vc?.podcastTitle = course.title
                    vc?.songUrlString = course.fileURL
                    vc?.imgURL = course.imageURL
                    print("Sended data Player")
                }
            }
        }
    }
    
    



}
