//
//  Utils.swift
//  ninja-light
//
//  Created by wesley on 2021/4/5.
//

import Foundation
import UIKit
import MBProgressHUD
import LocalAuthentication

public func instantiateViewController(vcID: String) -> UIViewController {
    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main);
    return storyboard.instantiateViewController(withIdentifier: vcID);
}

public func DeriveAesKey(auth: String) {
    KeychainWrapper.standard.set(auth, forKey: "AUTHKey")
}

func dispatch_async_safely_to_main_queue(_ block: @escaping ()->()) {
    dispatch_async_safely_to_queue(DispatchQueue.main, block)
}

func dispatch_async_safely_to_queue(_ queue: DispatchQueue, _ block: @escaping ()->()) {
    if queue === DispatchQueue.main && Thread.isMainThread {
        block()
    } else {
        queue.async {
            block()
        }
    }
}

public func formatTimeStamp(by timeStamp: Int64) -> String {
        let time = Date.init(timeIntervalSince1970: TimeInterval(timeStamp))
        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return dateFormatterGet.string(from: time)
}

public struct AlertPayload {
        var title:String!
        var placeholderTxt:String?
        var securityShow:Bool = true
        var keyType:UIKeyboardType = .default
        var action:((String?, Bool)->Void)!
}

extension String {
    func isIncludeChinese() -> Bool {
        for ch in self.unicodeScalars {
            if (0x4e00 < ch.value  && ch.value < 0x9fff) { return true } // 中文字符范围：0x4e00 ~ 0x9fff
        }
        return false
    }
    
    func transformToPinyin(hasBlank: Bool = false) -> String {
        
        let stringRef = NSMutableString(string: self) as CFMutableString
        CFStringTransform(stringRef,nil, kCFStringTransformToLatin, false) // 转换为带音标的拼音
        CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false) // 去掉音标
        let pinyin = stringRef as String
        return hasBlank ? pinyin : pinyin.replacingOccurrences(of: " ", with: "")
    }
    
    func transformToPinyinHead(lowercased: Bool = false) -> String {
        let pinyin = self.transformToPinyin(hasBlank: true).capitalized // 字符串转换为首字母大写
        var headPinyinStr = ""
        for ch in pinyin {
            if ch <= "Z" && ch >= "A" {
                headPinyinStr.append(ch) // 获取所有大写字母
            }
        }
        return lowercased ? headPinyinStr.lowercased() : headPinyinStr
    }
    
    func transformToCapitalized() -> String {
        let str = self.capitalized
        var selectStr = ""
        for ch in str {
            if ch <= "Z" && ch >= "A" {
                selectStr.append(ch)
            }
        }
        return selectStr
    }
    
}

extension Array {
    
    /// 数组内中文按拼音字母排序
    ///
    /// - Parameter ascending: 是否升序（默认升序）
    func sortedByPinyin(ascending: Bool = true) -> Array<ContactItem>? {
        if self is Array<ContactItem> {
            return (self as! Array<ContactItem>).sorted { (value1, value2) -> Bool in
                guard let pinyin1 = value1.sortPinyin, let pinyin2 = value2.sortPinyin else {
                    return false
                }
                
//                let pinyin2 = value2.sortPinyin!
                return pinyin1.compare(pinyin2) == (ascending ? .orderedAscending : .orderedDescending)
            }
        }
        return nil
    }
}

extension UIImage {
    var jpeg: Data? { jpegData(compressionQuality: 0.8) }  // QUALITY min = 0 / max = 1
    var png: Data? { pngData() }
}

extension UIViewController {
        func hideKeyboardWhenTappedAround() {
                let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
                tap.cancelsTouchesInView = false
                view.addGestureRecognizer(tap)
        }

        @objc func dismissKeyboard() {
                view.endEditing(true)
        }
        
        func showIndicator(withTitle title: String, and Description:String) {DispatchQueue.main.async {
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.label.text = title
                Indicator.isUserInteractionEnabled = false
                Indicator.detailsLabel.text = Description
                Indicator.show(animated: true)
        }}
        
        func createIndicator(withTitle title: String, and Description:String) -> MBProgressHUD{
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.label.text = title
                Indicator.isUserInteractionEnabled = false
                Indicator.detailsLabel.text = Description
                return Indicator
        }
        
        func toastMessage(title:String) ->Void {
//            DispatchQueue.main.async {
                let hud : MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = MBProgressHUDMode.text
                hud.detailsLabel.text = title
                hud.removeFromSuperViewOnHide = true
                hud.margin = 10
                hud.offset.y = 250.0
                hud.hide(animated: true, afterDelay: 3)
//            }
        }
        
        func CustomerAlert(name:String){ DispatchQueue.main.async {
                
                let alertVC = instantiateViewController(vcID:name)
                
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                alertController.setValue(alertVC, forKey: "contentViewController");
                self.present(alertController, animated: true, completion: nil);
                }
        }
        
        func hideIndicator() {DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
        }}
        
        func ShowTips(msg:String){
                DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Tips!", message: msg, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                }
        }
    
        func showPwdInput(title: String, placeHolder:String?, securityShow:Bool = false, type:UIKeyboardType = .default, nextAction:((String?, Bool)->Void)?) {
            let ap = AlertPayload(title: title,
                                  placeholderTxt: placeHolder,
                                  securityShow: securityShow,
                                  keyType: type,
                                  action: nextAction)
            LoadAlertFromStoryBoard(payload: ap)
        }
        
        func LoadAlertFromStoryBoard(payload:AlertPayload){ DispatchQueue.main.async {
                guard let alertVC = instantiateViewController(vcID: "PasswordViewControllerID")
                            as? PasswordViewController else{
                            return
                        }
                        
                        alertVC.payload = payload;
            
                        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                        alertController.setValue(alertVC, forKey: "contentViewController");
                        self.present(alertController, animated: true, completion: nil);
            }
        }
        
        func ShowQRAlertView(image:UIImage?){
                guard let alertVC = instantiateViewController(vcID: "QRCodeShowViewControllerSID")
                    as? QRCodeShowViewController else{
                    return
                }
                alertVC.QRImage = image;
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                alertController.setValue(alertVC, forKey: "contentViewController");
                self.present(alertController, animated: true, completion: nil);
        }
        
        func ShowQRAlertView(data:String){
                guard let image = generateQRCode(from: data) else { return }
                self.ShowQRAlertView(image: image)
        }
        
        func generateQRCode(from message: String) -> UIImage? {
                
                guard let data = message.data(using: .utf8) else{
                        return nil
                }
                
                guard let qr = CIFilter(name: "CIQRCodeGenerator",
                                        parameters: ["inputMessage":
                                                data, "inputCorrectionLevel":"M"]) else{
                        return nil
                }
                
                guard let qrImage = qr.outputImage?.transformed(by: CGAffineTransform(scaleX: 5, y: 5)) else{
                        return nil
                }
                let context = CIContext()
                let cgImage = context.createCGImage(qrImage, from: qrImage.extent)
                let uiImage = UIImage(cgImage: cgImage!)
                return uiImage
        }
        
        func generateViewImg(info: UIView) -> UIImage? {
            var img: UIImage?
            UIGraphicsBeginImageContextWithOptions(info.bounds.size, false, 0.0)
            info.layer.render(in: UIGraphicsGetCurrentContext()!)
            img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return img
            
        }
    
        func biometryUsage(onCompletion: @escaping(Bool) -> Void) {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "是否允许App使用您的\(context.biometryType)"
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, authError) in
                    DispatchQueue.main.async {
                        onCompletion(success)
                    }
                }
            } else {
                self.toastMessage(title: "加载\(context.biometryType.rawValue)失败")
            }
        }
}

func cleanAllData() {
    MessageItem.cache.removeAll()
    ChatItem.CachedChats.removeAll()
    ContactItem.cache.removeAll()
}

extension MBProgressHUD{
        
        func setDetailText(msg:String) {
                 DispatchQueue.main.async {
                        self.detailsLabel.text = msg
                }
        }
}

extension FileManager {
    func cleanTempFiles() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try removeItem(atPath: fileUrl.path)
            }
        } catch let err as NSError {
            print("clear temp files failed \(err.localizedDescription)")
        }
    }
}

enum ZGJButtonImageEdgeInsetsStyle {
    case top, left, right, bottom
}

extension UIColor {

    var toHexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "%02X%02X%02X",
            Int(r * 0xff),
            Int(g * 0xff),
            Int(b * 0xff)
        )
    }

convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }

}


extension UIButton {
    func imagePosition(at style: ZGJButtonImageEdgeInsetsStyle, space: CGFloat) {
        guard let imageV = imageView else { return }
        guard let titleL = titleLabel else { return }
        //获取图像的宽和高
        let imageWidth = imageV.frame.size.width
        let imageHeight = imageV.frame.size.height
        //获取文字的宽和高
        let labelWidth  = titleL.intrinsicContentSize.width
        let labelHeight = titleL.intrinsicContentSize.height
        
        var imageEdgeInsets = UIEdgeInsets.zero
        var labelEdgeInsets = UIEdgeInsets.zero
        //UIButton同时有图像和文字的正常状态---左图像右文字，间距为0
        switch style {
        case .left:
            //正常状态--只不过加了个间距
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -space * 0.5, bottom: 0, right: space * 0.5)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: space * 0.5, bottom: 0, right: -space * 0.5)
        case .right:
            //切换位置--左文字右图像
            //图像：UIEdgeInsets的left是相对于UIButton的左边移动了labelWidth + space * 0.5，right相对于label的左边移动了-labelWidth - space * 0.5
            imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + space * 0.5, bottom: 0, right: -labelWidth - space * 0.5)
            labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - space * 0.5, bottom: 0, right: imageWidth + space * 0.5)
        case .top:
            //切换位置--上图像下文字
            /**图像的中心位置向右移动了labelWidth * 0.5，向上移动了-imageHeight * 0.5 - space * 0.5
             *文字的中心位置向左移动了imageWidth * 0.5，向下移动了labelHeight*0.5+space*0.5
            */
            imageEdgeInsets = UIEdgeInsets(top: -imageHeight * 0.5 - space * 0.5, left: labelWidth * 0.5, bottom: imageHeight * 0.5 + space * 0.5, right: -labelWidth * 0.5)
            labelEdgeInsets = UIEdgeInsets(top: labelHeight * 0.5 + space * 0.5, left: -imageWidth * 0.5, bottom: -labelHeight * 0.5 - space * 0.5, right: imageWidth * 0.5)
        case .bottom:
            //切换位置--下图像上文字
            /**图像的中心位置向右移动了labelWidth * 0.5，向下移动了imageHeight * 0.5 + space * 0.5
             *文字的中心位置向左移动了imageWidth * 0.5，向上移动了labelHeight*0.5+space*0.5
             */
            imageEdgeInsets = UIEdgeInsets(top: imageHeight * 0.5 + space * 0.5, left: labelWidth * 0.5, bottom: -imageHeight * 0.5 - space * 0.5, right: -labelWidth * 0.5)
            labelEdgeInsets = UIEdgeInsets(top: -labelHeight * 0.5 - space * 0.5, left: -imageWidth * 0.5, bottom: labelHeight * 0.5 + space * 0.5, right: imageWidth * 0.5)
        }
        self.titleEdgeInsets = labelEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
    }
}
