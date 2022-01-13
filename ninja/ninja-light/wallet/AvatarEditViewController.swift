//
//  AvatarEditViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/1/13.
//

import UIKit

class AvatarEditViewController: UIViewController {

        @IBOutlet weak var avatarImg: UIImageView!
        override func viewDidLoad() {
                super.viewDidLoad()
                if let data = Wallet.shared.avatarData {
                        avatarImg.image = UIImage(data: data)
                }
        }
        
        @IBAction func changeAvatar(_ sender: UIButton) {
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
                if let img = info[.editedImage] as? UIImage {
                        
                        imageDidSelected(img: img)
                }
        }
        
        private func imageDidSelected(img: UIImage) {
                self.avatarImg.image = img
                guard let imagedata = img.compress else {
                        self.toastMessage(title: "Image size out of limit")
                        return
                }
                
                if let err = Wallet.shared.UpdateAvatarData(by: imagedata) {
                        self.toastMessage(title: err.localizedDescription)
                }
        }
}

