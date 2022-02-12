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
import MobileCoreServices
import ChatLib

public func MustImage(data:Data?)->UIImage{
        guard let d = data else{
                return defaultAvatar
        }
        return UIImage(data: d) ?? defaultAvatar
}
extension NSLayoutConstraint {
        
        override public var description: String {
                let id = identifier ?? ""
                return "id: \(id), constant: \(constant)" //you may print whatever you want here
        }
}

func updateBadgeNum() {
        let total = ChatItem.TotalUnreadNo
        UIApplication.shared.applicationIconBadgeNumber = total
}

func compressImage(_ origin: Data?) -> Data? {
        guard let size = origin?.count else {
                return nil
        }
        let limitSize = 4*1024*1024
        if size > limitSize {
                var error: NSError?
                let data = ChatLibCompressImg(origin, limitSize, &error)
                if error != nil {
                        print("---[compress image]---\(error?.localizedDescription ?? "")")
                }
                return data
        }
        return origin
}

func mimeTypeIsVideo(_ suffix: String) -> Bool {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           suffix as NSString,
                                                           nil)?.takeRetainedValue() {
                return UTTypeConformsTo(uti, kUTTypeMovie)
        }
        return false
}

extension URL {
        func mimeType() -> String {
                let pathExtension = self.pathExtension
                if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
                        if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                                return mimetype as String
                        }
                }
                return "application/octet-stream"
        }
        
        var containsImage: Bool {
                let mimeType = self.mimeType()
                guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
                        return false
                }
                return UTTypeConformsTo(uti, kUTTypeImage)
        }
        
        var containsAudio: Bool {
                let mimeType = self.mimeType()
                guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
                        return false
                }
                return UTTypeConformsTo(uti, kUTTypeAudio)
        }
        
        var containsVideo: Bool {
                let mimeType = self.mimeType()
                guard  let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
                        return false
                }
                return UTTypeConformsTo(uti, kUTTypeMovie)
        }
        
}

public func isFirstUser() -> Bool {
        let userDefault = UserDefaults.standard
        if let firstUser = userDefault.string(forKey: "ninja") {
                print("---[First Uset]---\(firstUser)")
                return false
        }
        return true
}

public func setFirstUser() {
        let userDefault = UserDefaults.standard
        userDefault.set("old", forKey: "ninja")
}

public func afterWallet() { DispatchQueue.main.async {
        if #available(iOS 13.0, *) {
                guard let delegate =  UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else{
                        print("------->>delegate-----is nil->s")
                        return
                }
//                let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
                delegate.window?.rootViewController = instantiateViewController(vcID: "NinjaHomeTabVC")
        } else {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window?.rootViewController = instantiateViewController(vcID: "NinjaHomeTabVC")
                appDelegate.window?.makeKeyAndVisible()
        }
}
}

public func instantiateViewController(storyboardName: String, viewControllerIdentifier: String) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main);
        return storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier);
}


public func getJSONStringFromDictionary(dictionary: NSDictionary) -> String {
        if !JSONSerialization.isValidJSONObject(dictionary) {
                return ""
        }
        
        let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) as Data
        
        let JSONString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        
        return JSONString! as String
}

public func getDictionaryFromJSONString(jsonString: String) -> NSDictionary {
        let jsonData = jsonString.data(using: .utf8)!
        
        let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        
        if dict != nil {
                return dict as! NSDictionary
        }
        
        return NSDictionary()
        
}

public func instantiateViewController(vcID: String) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: vcID)
}

public func SetAesKey(auth: String) {
        KeychainWrapper.standard.set(auth, forKey: "AUTHKey")
}

public func DeriveAesKey() -> String? {
        return KeychainWrapper.standard.string(forKey: "AUTHKey")
}

public func SetDestroyKey(auth: String) {
        KeychainWrapper.standard.set(auth, forKey: "DESTORY_AUTHKey")
}

public func DeriveDestroyKey() -> String? {
        return KeychainWrapper.standard.string(forKey: "DESTORY_AUTHKey")
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

public let oneDay = TimeInterval(60 * 60 * 24)
public let oneMinute = TimeInterval(60)
public func formatMsgTimeStamp(by timeStamp: Int64) -> String {
        let time = Date.init(timeIntervalSince1970: TimeInterval(timeStamp/1000))
        if Calendar.current.isDateInToday(time){
                dateFormatterGet.dateFormat = "HH:mm"
        }else if Calendar.current.isDateInYesterday(time){
                dateFormatterGet.dateFormat = "昨天 HH:mm"
        }else if Calendar.current.isDateInWeekend(time){
                let idx = Calendar.current.component(.weekday, from: Date())
                let str = Calendar.current.shortWeekdaySymbols[idx - 1]
                dateFormatterGet.dateFormat = "\(str) HH:mm"
        }else{
                dateFormatterGet.dateFormat = "MM-dd"
                
        }
        return dateFormatterGet.string(from: time)
}

public func GoTimeStringToSwiftDate(str:String)->Int64{
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = f.date(from: str) else{
                return 0
        }
        return Int64(date.timeIntervalSince1970)
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


public func getKeyWindow() -> UIWindow? {
        let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
        return keyWindow
}

extension String {
        var `extension`: String {
                if let index = self.lastIndex(of: ".") {
                        return String(self[index...])
                } else {
                        return ""
                }
        }
        
        func isIncludeChinese() -> Bool {
                for ch in self.unicodeScalars {
                        if (0x4e00 < ch.value  && ch.value < 0x9fff) { return true }
                }
                return false
        }
        
        func transformToPinyin(hasBlank: Bool = false) -> String {
                
                let stringRef = NSMutableString(string: self) as CFMutableString
                CFStringTransform(stringRef,nil, kCFStringTransformToLatin, false)
                CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false)
                let pinyin = stringRef as String
                return hasBlank ? pinyin : pinyin.replacingOccurrences(of: " ", with: "")
        }
        
        func transformToPinyinHead(lowercased: Bool = false) -> String {
                let pinyin = self.transformToPinyin(hasBlank: true).capitalized
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
        
        func toArray() -> NSArray? {
                if let jsonData: Data = self.data(using: .utf8) {
                        let array = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                        if array != nil {
                                return array as? NSArray
                        }
                }
                return nil
        }
        
        var locStr:String {
                return NSLocalizedString(self, comment: "")
        }

}
extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
extension Array {
        func sortedByPinyin(ascending: Bool = true) -> Array<ContactItem>? {
                if self is Array<ContactItem> {
                        return (self as! Array<ContactItem>).sorted { (value1, value2) -> Bool in
                                guard let pinyin1 = value1.sortPinyin, let pinyin2 = value2.sortPinyin else {
                                        return false
                                }
                                return pinyin1.compare(pinyin2) == (ascending ? .orderedAscending : .orderedDescending)
                        }
                }
                return nil
        }
        
        func toString() -> String? {
                if let data = try? JSONSerialization.data(withJSONObject: self, options: []),
                   let str = String(data: data, encoding: .utf8) {
                        return str
                }
                return nil
        }
        
}

extension UIImage {
        var jpeg: Data? { jpegData(compressionQuality: 0.8) }  // QUALITY min = 0 / max = 1
        var png: Data? { pngData() }
        
        var compress: Data? {
                let len = self.size.height
                if len > 256 {
                        return jpegData(compressionQuality: 256/len)
                }
                return jpegData(compressionQuality: 1)
        }
}

extension UIViewController {
        
        private class var sharedApplication: UIApplication? {
                let selector = NSSelectorFromString("sharedApplication")
                return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
        }
        
        // Returns the current application's top most view controller.
        open class var topMostInApp: UIViewController? {
                guard let currentWindows = self.sharedApplication?.windows else { return nil }
                var rootViewController: UIViewController?
                for window in currentWindows {
                        if let windowRootViewController = window.rootViewController, window.isKeyWindow {
                                rootViewController = windowRootViewController
                                break
                        }
                }
                return self.topMost(of: rootViewController)
        }
        
        // Returns the top most view controller from given view controller's stack.
        open class func topMost(of viewController: UIViewController?) -> UIViewController? {
                
                if let presentedViewController = viewController?.presentedViewController {
                        return self.topMost(of: presentedViewController)
                }
                
                if let tabBarController = viewController as? UITabBarController,
                   let selectedViewController = tabBarController.selectedViewController {
                        return self.topMost(of: selectedViewController)
                }
                
                if let navigationController = viewController as? UINavigationController,
                   let visibleViewController = navigationController.visibleViewController {
                        return self.topMost(of: visibleViewController)
                }
                
                if let pageViewController = viewController as? UIPageViewController,
                   pageViewController.viewControllers?.count == 1 {
                        return self.topMost(of: pageViewController.viewControllers?.first)
                }
                
                for subview in viewController?.view?.subviews ?? [] {
                        if let childViewController = subview.next as? UIViewController {
                                return self.topMost(of: childViewController)
                        }
                }
                
                return viewController
        }
        
        func showInputDialog(title: String,
                             message: String,
                             textPlaceholder: String,
                             actionText: String,
                             cancelText: String,
                             cancelHandler: ((UIAlertAction) -> Void)?,
                             actionHandler: ((_ text: String?) -> Void)?
        ) {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addTextField { (textField: UITextField) in
                        textField.placeholder = textPlaceholder
                }
                alert.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: cancelHandler))
                alert.addAction(UIAlertAction(title: actionText, style: .destructive, handler: { (action: UIAlertAction) in
                        guard let textField = alert.textFields?.first else {
                                actionHandler?(nil)
                                return
                        }
                        actionHandler?(textField.text)
                }))
                
                self.present(alert, animated: true, completion: nil)
        }
        
        func hideKeyboardWhenTappedAround() { DispatchQueue.main.async {
                let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
                tap.cancelsTouchesInView = false
                self.view.addGestureRecognizer(tap)
        }}
        
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
        
        func showSyncIndicator(withTitle title: String, and Description:String) {DispatchQueue.main.async {
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.label.text = title
                Indicator.isUserInteractionEnabled = false
                Indicator.mode = .customView
                Indicator.customView = UIImageView(image: UIImage(named: "loading"))
                
                //                Indicator.tintColor = UIColor(hex: "4BB5EF")
                Indicator.detailsLabel.text = Description
                Indicator.show(animated: true)
        }}
        
        func hidedSuccIndicator() {
                MBProgressHUD.hide(for: self.view, animated: true)
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.isUserInteractionEnabled = false
                Indicator.mode = .customView
                Indicator.customView = UIImageView(image: UIImage(named: "bingggo"))
                Indicator.detailsLabel.text = "同步成功"
                Indicator.hide(animated: true, afterDelay: 2)
        }
        
        func hidedFaildIndicator() {
                MBProgressHUD.hide(for: self.view, animated: true)
                let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
                Indicator.isUserInteractionEnabled = false
                Indicator.mode = .customView
                Indicator.customView = UIImageView(image: UIImage(named: ""))
                Indicator.detailsLabel.text = "同步失败"
                Indicator.hide(animated: true, afterDelay: 2)
        }
        
        //    func createIndicator(withTitle title: String, and Description:String) -> MBProgressHUD {
        //            let Indicator = MBProgressHUD.showAdded(to: self.view, animated: true)
        //            Indicator.label.text = title
        //            Indicator.isUserInteractionEnabled = false
        //            Indicator.detailsLabel.text = Description
        //            return Indicator
        //    }
        
        func toastMessage(title:String, duration:TimeInterval = 3) -> Void {
                DispatchQueue.main.async {
                        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
                        hud.mode = MBProgressHUDMode.text
                        hud.detailsLabel.text = title
                        hud.removeFromSuperViewOnHide = true
                        hud.margin = 10
                        hud.offset.y = 250.0
                        hud.hide(animated: true, afterDelay: duration)
                }
        }
        
        func CustomerAlert(name:String) { DispatchQueue.main.async {
                
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
        
        func ShowYesOrNo(msg:String, No:(()->())? = nil, Yes:(()->())? = nil){
                DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Tips!", message: msg, preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "NO", style: .cancel, handler: { aa in
                                ac.dismiss(animated: true)
                                No?()
                        }))
                        ac.addAction(UIAlertAction(title: "Yes", style: .default, handler: { aa in
                                ac.dismiss(animated: true)
                                Yes?()
                        }))
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
        
        func LoadAlertFromStoryBoard(payload: AlertPayload) {
                DispatchQueue.main.async {
                        guard let alertVC = instantiateViewController(vcID: "PasswordViewControllerID")
                                as? PasswordViewController else {
                                        return
                                }
                        
                        alertVC.payload = payload;
                        
                        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                        alertController.setValue(alertVC, forKey: "contentViewController");
                        self.present(alertController, animated: true, completion: nil);
                }
        }
        
        func ShowQRAlertView(image:UIImage?){
                guard let alertVC = instantiateViewController(vcID: "QRCodeShowViewControllerSID") as? QRCodeShowViewController else{
                        return
                }
                alertVC.QRImage = image;
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert);
                alertController.setValue(alertVC, forKey: "contentViewController");
                self.present(alertController, animated: true, completion: nil);
        }
        
        func ShowVIPAlertView() {
                guard let alertVC = instantiateViewController(vcID: "VIPAlertViewControllerSID") as? VIPAlertViewController else {
                        return
                }
                let alertViewCtrl = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                alertViewCtrl.setValue(alertVC, forKey: "contentViewController")
                
        }
        
        func ShowTryoutView() {
                guard let alertVC = instantiateViewController(vcID: "TryoutAlertViewControllerSID") as? VIPAlertViewController else {
                        return
                }
                let alertViewCtrl = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                alertViewCtrl.setValue(alertVC, forKey: "contentViewController")
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
                        let reason = "Ask for your permission to use".locStr+"\(context.biometryType)"
                        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, authError) in
                                DispatchQueue.main.async {
                                        onCompletion(success)
                                }
                        }
                } else {
                        self.toastMessage(title: "Faild to use".locStr+"\(context.biometryType.rawValue)")
                }
        }
        
        func showVipModalViewController() {
                let modalViewController = instantiateViewController(vcID:"ShowVipNoticeVC")
                modalViewController.modalPresentationStyle = .popover
                present(modalViewController, animated: true, completion: nil)
        }
        
        func replaceByViewController(vc:UIViewController){
                guard var vcs = self.navigationController?.viewControllers else{
                        self.navigationController?.pushViewController(vc, animated: true)
                        return
                }
                _ = vcs.popLast()
                vcs.append(vc)
                self.navigationController?.setViewControllers(vcs, animated: true)
        }
}


func getAppVersion() -> String? {
        if let infoDict: [String: Any] = Bundle.main.infoDictionary {
                if let mainVersion = infoDict["CFBundleShortVersionString"] as? String,
                   let build = infoDict["CFBundleVersion"] as? String {
                        return String(mainVersion+"."+build)
                }
        }
        
        return nil
}

func getSavedAppVersion() -> String? {
        let userDefault = UserDefaults.standard
        return userDefault.string(forKey: AppVersionKey)
}

extension MBProgressHUD {
        func setDetailText(msg:String) {
                self.detailsLabel.text = msg
        }
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

enum ButtonImageEdgeInsetsStyle {
        case top, left, right, bottom
}

extension UIButton {
        func imagePosition(at style: ButtonImageEdgeInsetsStyle, space: CGFloat) {
                guard let imageV = imageView else { return }
                guard let titleL = titleLabel else { return }
                
                let imageWidth = imageV.frame.size.width
                let imageHeight = imageV.frame.size.height
                
                let labelWidth  = titleL.intrinsicContentSize.width
                let labelHeight = titleL.intrinsicContentSize.height
                
                var imageEdgeInsets = UIEdgeInsets.zero
                var labelEdgeInsets = UIEdgeInsets.zero
                
                switch style {
                case .left:
                        
                        imageEdgeInsets = UIEdgeInsets(top: 0, left: -space * 0.5, bottom: 0, right: space * 0.5)
                        labelEdgeInsets = UIEdgeInsets(top: 0, left: space * 0.5, bottom: 0, right: -space * 0.5)
                case .right:
                        imageEdgeInsets = UIEdgeInsets(top: 0, left: labelWidth + space * 0.5, bottom: 0, right: -labelWidth - space * 0.5)
                        labelEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth - space * 0.5, bottom: 0, right: imageWidth + space * 0.5)
                case .top:
                        imageEdgeInsets = UIEdgeInsets(top: -imageHeight * 0.5 - space * 0.5, left: labelWidth * 0.5, bottom: imageHeight * 0.5 + space * 0.5, right: -labelWidth * 0.5)
                        labelEdgeInsets = UIEdgeInsets(top: labelHeight * 0.5 + space * 0.5, left: -imageWidth * 0.5, bottom: -labelHeight * 0.5 - space * 0.5, right: imageWidth * 0.5)
                case .bottom:
                        imageEdgeInsets = UIEdgeInsets(top: imageHeight * 0.5 + space * 0.5, left: labelWidth * 0.5, bottom: -imageHeight * 0.5 - space * 0.5, right: -labelWidth * 0.5)
                        labelEdgeInsets = UIEdgeInsets(top: -labelHeight * 0.5 - space * 0.5, left: -imageWidth * 0.5, bottom: labelHeight * 0.5 + space * 0.5, right: imageWidth * 0.5)
                }
                self.titleEdgeInsets = labelEdgeInsets
                self.imageEdgeInsets = imageEdgeInsets
        }
}

