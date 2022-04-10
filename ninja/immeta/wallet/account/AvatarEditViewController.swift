//
//  AvatarEditViewController.swift
//  immeta
//
//  Created by ribencong on 2022/1/13.
//

import UIKit

class AvatarEditViewController: UIViewController {

        @IBOutlet weak var vipFlagImgView: UIImageView!
        @IBOutlet weak var avatarChangeButton: UIButton!
        @IBOutlet weak var avatarImg: UIImageView!
        override func viewDidLoad() {
                super.viewDidLoad()
                if let data = Wallet.shared.avatarData {
                        avatarImg.image = UIImage(data: data)
                }else{
                        avatarImg.image = UIImage(named:"logo_img")
                }
                vipFlagImgView.isHidden = Wallet.shared.isStillVip()
        }
        
        @IBAction func changeAvatar(_ sender: UIButton) {
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                let vc = UIImagePickerController()
                vc.sourceType = .photoLibrary
                vc.mediaTypes = ["public.image"]
                vc.delegate = self
                vc.allowsEditing = true
                present(vc, animated: true, completion: nil)
        }
}

extension AvatarEditViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true, completion: nil)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                picker.dismiss(animated: true, completion: nil)
                guard let img = info[.editedImage] as? UIImage  else{
                        self.toastMessage(title: "invalid avatar".locStr)
                        return
                }
                self.avatarImg.image = img
                self.showIndicator(withTitle: "", and: "uploading avatar".locStr)
                ServiceDelegate.workQueue.async {
                        self.imageDidSelected(img: img)
                        self.hideIndicator()
                }
        }
        
        private func imageDidSelected(img: UIImage) {
                var imgData = Data(img.jpegData(compressionQuality: 1)!)
                
                let imageSize: Int = imgData.count
                let maxSzie = ServiceDelegate.MaxAvatarSize()
                if imageSize > (maxSzie){
                        let compressedData =  FileManager.compressImage(data: imgData, to: maxSzie)//.CompressImg(origin: imgData, targetSize: maxSzie)
                        print("maxSzie is[\(maxSzie)] image[\(imageSize)] need to compress to[\(compressedData?.count ?? 0)]")
                        guard let d = compressedData else {
                                self.toastMessage(title: "Image size out of limit".locStr)
                                return
                        }
                        imgData = d
                }
                
                if let err = Wallet.shared.UpdateAvatarData(by: imgData) {
                        self.toastMessage(title: err.localizedDescription)
                }
        }
}

