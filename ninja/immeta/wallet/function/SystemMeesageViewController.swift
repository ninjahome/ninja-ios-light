//
//  SystemMeesageViewController.swift
//  immeta
//
//  Created by wesley on 2022/2/5.
//

import UIKit
import WebKit

class SystemMeesageViewController: UIViewController, WKNavigationDelegate {
        
        @IBOutlet weak var msgWebView: WKWebView!
        
        public static  var newTargetUrl = ""
        
        private let  defaultUrl = URL(string: "https://www.immeta.chat")!
        private let lastTargetUrlKey = "Last_target_url_key_v2"
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                msgWebView.navigationDelegate = self
                
                var targetUrl:String?
                if SystemMeesageViewController.newTargetUrl.isEmpty{
                        targetUrl =  UserDefaults.standard.string(forKey: lastTargetUrlKey)
                }else{
                        targetUrl = SystemMeesageViewController.newTargetUrl
                }
               
                guard let t = targetUrl, !t.isEmpty else{
                        msgWebView.load(URLRequest(url: defaultUrl))
                        return
                }
                guard let url = URL(string: t) else{
                        msgWebView.load(URLRequest(url: defaultUrl))
                        return
                }
                
                msgWebView.load(URLRequest(url: url))
        }
        
        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!){
                
                UserDefaults.standard.set(webView.url?.absoluteString, forKey: lastTargetUrlKey)
                SystemMeesageViewController.newTargetUrl = ""
        }
}
