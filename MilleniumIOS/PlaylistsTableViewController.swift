//
//  ReplayTableViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 21/09/2019.
//  Copyright © 2019 Station Millenium. All rights reserved.
//

import UIKit
import ViewAnimator

class PlaylistsTableViewController: UITableViewController {
    
    @IBOutlet var tableview: UITableView!
    public var courses = [Course]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
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
        let count: Int
    }

    fileprivate func fetchJSON() {
        let urlString = "https://www.station-millenium.com/replay-api/v1/series"
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
                    print("reloaded playlist data")
                    self.dismiss(animated: false, completion: nil)
                    UIView.animate(views: self.tableview.visibleCells, animations: [ AnimationType.from(direction: .right, offset: 500) ] )
                } catch let jsonErr {
                    print("Failed to decode:", jsonErr)
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
        return courses.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        let course = courses[indexPath.row]
        cell.textLabel?.text = course.title
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigatio
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: "showTitles", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showTitles" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let course = courses[indexPath.row]
                if segue.destination is TitresTableViewController
                {
                    let vc = segue.destination as? TitresTableViewController
                    vc?.podcast = course.title
                    vc?.id = course.id
                    
                }
            }
        }
    }
    
}
