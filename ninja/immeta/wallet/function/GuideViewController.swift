//
//  GuideViewController.swift
//  immeta
//
//  Created by ribencong on 2022/1/7.
//

import UIKit

class GuideViewController: UIViewController, UIScrollViewDelegate {
        
        let images = ["guide01".locStr, "guide02".locStr, "guide03".locStr, "guide04".locStr, "guide05".locStr]
        
        @IBOutlet weak var pageCtrl: UIPageControl!
        @IBOutlet weak var scrollView: UIScrollView!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                scrollView.delegate = self
                scrollView.isPagingEnabled = true
                scrollView.contentSize = CGSize(width: CGFloat(images.count)*self.view.bounds.width, height: 0)
                loadFeature()
        }
        
        func loadFeature() {
                for index in 0..<images.count {
                        
                        self.view.frame.origin.x = scrollView.frame.size.width * CGFloat(index)
                        scrollView.frame.size = self.view.frame.size
                        //                        self.view.frame.size = scrollView.frame.size
                        let imgView = UIImageView(frame: self.view.frame)
                        imgView.image = UIImage(named: images[index])
                        imgView.contentMode = .scaleAspectFit
                        imgView.isUserInteractionEnabled = true
                        self.scrollView.addSubview(imgView)
                        if index == images.count - 1 {
                                let btn = UIButton.init(frame: CGRect(x: imgView.frame.width/2-80, y: imgView.bounds.height * 0.85, width: 160, height: 50))
                                imgView.addSubview(btn)
                                btn.setTitle("Enjoin".locStr, for: .normal)
                                btn.backgroundColor = UIColor(hex: "26253C")
                                btn.setTitleColor(UIColor(hex: "FFFFFF"), for: .normal)
                                btn.layer.cornerRadius = 25
                                btn.addTarget(self, action: #selector(tapped), for: .touchUpInside)
                        }
                        
                }
        }
        
        @objc func tapped(sender: UIButton) {
                self.performSegue(withIdentifier: "finishGuideSEG", sender: self)
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
                let pageNumber = scrollView.contentOffset.x / scrollView.frame.size.width
                pageCtrl.currentPage = Int(pageNumber)
        }
}
