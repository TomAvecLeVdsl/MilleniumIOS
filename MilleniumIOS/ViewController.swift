//
//  ViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 08/09/2019.
//  Copyright © 2019 Station Milenium. All rights reserved.
//

import UIKit
import MatomoTracker

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var fbbutton: UIButton!
    @IBOutlet weak var mytableView: UITableView! {
        didSet {
            mytableView.delegate = self;
            mytableView.dataSource = self;
        }
    }
    
    var courses = [Course]()
    static let matomoTracker = MatomoTracker(siteId: "5", baseURL: URL(string: "https://www.station-millenium.com/piwik/piwik.php")!)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchJSON()
        registerSettingsBundle()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        defaultsChanged()
        ViewController.matomoTracker.track(view: ["Accueil"])

    }
    
    func registerSettingsBundle(){
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
    }
    @objc func defaultsChanged(){
        //print(UserDefaults.standard.value(forKey: "auto_play")!)
    }
    
    struct Course: Decodable {
        let text: String
        let url: String
    }
    
    
    @IBAction func fbclicked(_ sender: Any) {
        UIApplication.tryURL(urls: [
        "fb://profile/132025813602837", // App
        "http://www.facebook.com/132025813602837" // Website if app fails
        ])
    }
    
    @IBAction func twclicked(_ sender: Any) {
        UIApplication.tryURL(urls: [
        "twitter://user?screen_name=Millenium22", // App
        "https://twitter.com/Millenium22" // Website if app fails
        ])
        
    }
    
    @IBAction func WebClicked(_ sender: Any) {
        UIApplication.shared.open(URL(string:"https://station-millenium.com")!)
    }
    
    fileprivate func fetchJSON() {
        let urlString = "https://station-millenium.com/facebook-api/v1/feed"
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
                    self.mytableView.reloadData()
                } catch let jsonErr {
                    print("Failed to decode:", jsonErr)
                }
            }
            }.resume()
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courses.count
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellId")
        let course = courses[indexPath.row]
        cell.textLabel?.text = course.text
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let course = courses[indexPath.row]
        if let url = URL(string: course.url)
        {
            UIApplication.shared.open(url)
        }
    }
    

}

extension UIImage {

    public convenience init?(systemItem sysItem: UIBarButtonItem.SystemItem, renderingMode:UIImage.RenderingMode = .automatic) {
        guard let sysImage = UIImage.imageFromSystemItem(sysItem, renderingMode: renderingMode)?.cgImage else {
            return nil
        }

        self.init(cgImage: sysImage)
    }

    private class func imageFromSystemItem(_ systemItem: UIBarButtonItem.SystemItem, renderingMode:UIImage.RenderingMode = .automatic) -> UIImage? {

        let tempItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)

        // add to toolbar and render it
        let bar = UIToolbar()
        bar.setItems([tempItem], animated: false)
        bar.snapshotView(afterScreenUpdates: true)

        // got image from real uibutton
        let itemView = tempItem.value(forKey: "view") as! UIView

        for view in itemView.subviews {
            if view is UIButton {
                let button = view as! UIButton
                let image = button.imageView!.image!
                image.withRenderingMode(renderingMode)
                return image
            }
        }

        return nil
    }
}

extension UIApplication {
  class func tryURL(urls: [String]) {
      let application = UIApplication.shared
      for url in urls {
          if application.canOpenURL(URL(string: url)!) {
              if #available(iOS 10.0, *) {
                  application.open(URL(string: url)!, options: [:], completionHandler: nil)
              }
              else {
                  application.openURL(URL(string: url)!)
              }
              return
          }
      }
    }
}

