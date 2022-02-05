//
//  SystemMeesageViewController.swift
//  ninja-light
//
//  Created by wesley on 2022/2/5.
//

import UIKit
import WebKit

class SystemMeesageViewController: UIViewController {
        
        @IBOutlet weak var msgWebView: WKWebView!
        var targetUrl = "https://sbcproxyer.github.io/dl/app.html"
        override func viewDidLoad() {
                super.viewDidLoad()
                msgWebView.load(URLRequest(url: URL(string: targetUrl)!))
        }
}
