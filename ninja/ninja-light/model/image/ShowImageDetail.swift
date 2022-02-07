//
//  ShowPhotoDetail.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/15.
//

import Foundation
import AVFoundation
import UIKit

private let showBigDuration = 0.6
private let showOriginalDuration = 0.6

class ShowImageDetail: NSObject {
        private static var originalFrame = CGRect()
        private override init() {
                super.init()
        }
}

extension ShowImageDetail {
    
        class func show(imageView: UIImageView) {
                imageView.isUserInteractionEnabled = true

                let tap = UITapGestureRecognizer(target: self, action: #selector(showBigImage))
                imageView.addGestureRecognizer(tap)
        }
   
        @objc private class func showBigImage(sender: UITapGestureRecognizer) {

                guard let imageV = sender.view as? UIImageView else {
                        fatalError("it is not UIImageView")
                }
                guard let image = imageV.image else {
                        return
                }
                //    guard let window = UIApplication.shared.delegate?.window else {
                //        return
                //    }

                guard let window = getKeyWindow() else {
                        return
                }
                window.endEditing(true)

                originalFrame = CGRect()
                //    let oldFrame = imageV.convert(imageV.bounds, to: window)
                let oldFrame = imageV.convert(imageV.bounds, from: window)
                let backgroundView = UIView(frame: UIScreen.main.bounds)
                backgroundView.backgroundColor = UIColor.black
                backgroundView.alpha = 0.0

                originalFrame = oldFrame
                let newImageV = UIImageView(frame: oldFrame)
                newImageV.contentMode = .scaleAspectFit
                newImageV.image = image
                backgroundView.addSubview(newImageV)
                window.addSubview(backgroundView)

                UIView.animate(withDuration: showBigDuration) {
                        let width = UIScreen.main.bounds.size.width
                        let height = image.size.height * width / image.size.width
                        let y = (UIScreen.main.bounds.size.height - image.size.height * width / image.size.width) * 0.5
                        newImageV.frame = CGRect(x: 0, y: y, width: width, height: height)
                        backgroundView.alpha = 1
                }
                let tap2 = UITapGestureRecognizer(target: self, action: #selector(ShowImageDetail.showOriginal(sender:)))
                backgroundView.addGestureRecognizer(tap2)

                let longTap = UILongPressGestureRecognizer(target: self, action:    #selector(ShowImageDetail.longPress(sender:)))
                backgroundView.addGestureRecognizer(longTap)
        }

        @objc class private func longPress(sender: UILongPressGestureRecognizer
        ) {
                guard let backgroundView = sender.view else {
                        return
                }
                guard let imgView = backgroundView.subviews.first as? UIImageView else {
                        return
                }
                
                let keyWindow = getKeyWindow()
                let alert = UIAlertController(title: "请选择", message: nil, preferredStyle: .actionSheet)
                let action = UIAlertAction(title: "保存到相册", style: .default) { (_) in
                        UIImageWriteToSavedPhotosAlbum(imgView.image!, nil, nil, nil)
                        //TODO::show tips
                        keyWindow?.rootViewController?.toastMessage(title: "saved success")
                }
                let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                alert.addAction(action)
                alert.addAction(cancel)

                guard let window = keyWindow?.rootViewController else {
                        return
                }
                window.present(alert, animated: true, completion: nil)
                //TODO::
                //        backgroundView.present(alert, animated: true, completion: nil)keyWindow
        }
        
        @objc class private func showOriginal(sender: UITapGestureRecognizer) {
                guard let backgroundView = sender.view else {
                        return
                }

                guard let imageV = backgroundView.subviews.first else {
                        return
                }

                UIView.animate(withDuration: showOriginalDuration, animations: {
                        imageV.frame = originalFrame
                        backgroundView.alpha = 0.0
                }) { finished in
                        backgroundView.removeFromSuperview()
                }
        }
        
        
}
