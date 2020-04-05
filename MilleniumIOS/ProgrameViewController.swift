//
//  ProgrameViewController.swift
//  MilleniumIOS
//
//  Created by Tom Guillou on 14/09/2019.
//  Copyright © 2019 Station Millenium. All rights reserved.
//

import UIKit
import WebKit

class ProgrameViewController: UIViewController, WKNavigationDelegate {

    
    @IBOutlet var webView: WKWebView!
    
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.matomoTracker.track(view: ["Programes"])

        let url = URL(string: "https://www.station-millenium.com/radio/la-grille-des-programmes/")!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true

    }

}
