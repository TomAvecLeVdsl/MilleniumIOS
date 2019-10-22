//
//  ViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 08/09/2019.
//  Copyright © 2019 Station Milenium. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    var menuIsHidden = true
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var mytableView: UITableView! {
        didSet {
            mytableView.delegate = self;
            mytableView.dataSource = self;
        }
    }
    
    var courses = [Course]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leadingConstraint.constant = -210
        
        menuView.layer.shadowOpacity = 0.7
        menuView.layer.shadowRadius  = 6
        
        fetchJSON()


    }
    
    struct Course: Decodable {
        
        let text: String
        let url: String
    }

    
    @IBOutlet weak var ToogleMenuButton: UIBarButtonItem!
    @IBAction func toogleMenu(_ sender: UIBarButtonItem) {
        if menuIsHidden{
            leadingConstraint.constant = 0
            
            UIView.animate(withDuration: 0.3) {self.view.layoutIfNeeded()}
        }else{
            leadingConstraint.constant = -202
            
            UIView.animate(withDuration: 0.3) {self.view.layoutIfNeeded()}
        }
        
        menuIsHidden = !menuIsHidden
        
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

