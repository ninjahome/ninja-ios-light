//
//  GuideViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/1/7.
//

import UIKit

class GuideViewController: UIViewController, UIScrollViewDelegate {
        
        let images = ["guide01", "guide02", "guide03", "guide04", "guide05"]

        @IBOutlet weak var pageCtrl: UIPageControl!
        @IBOutlet weak var scrollView: UIScrollView!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                scrollView.delegate = self
                scrollView.isPagingEnabled = true
                scrollView.contentSize = CGSize(width: CGFloat(images.count)*self.view.bounds.width, height: self.view.bounds.height)
                loadFeature()
        }
        
        func loadFeature() {
                for index in 0..<images.count {
                        self.view.frame.origin.x = scrollView.frame.size.width * CGFloat(index)
                        self.view.frame.size = scrollView.frame.size
                        let imgView = UIImageView(frame: self.view.frame)
                        imgView.image = UIImage(named: images[index])
                        self.scrollView.addSubview(imgView)
                }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
                let pageNumber = scrollView.contentOffset.x / scrollView.frame.size.width
                pageCtrl.currentPage = Int(pageNumber)
        }
}
