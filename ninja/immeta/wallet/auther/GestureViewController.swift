//
//  GestureViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/4/6.
//

import UIKit

protocol GestureVerified {
        func verified(success: Bool)
}

enum GType {
    case set
    case verify
    case modify
}

class WarnLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showNormal(with message: String) {
        text = message
        textColor = UIColor.black
    }

    func showWarn(with message: String) {
        text = message
        textColor = UIColor(gpRGB: 0xC94349)
        layer.gp_shake()
    }
}

class GestureViewController: UIViewController {
        let lessConnectPointsNum: Int = 3
        let GWidth = UIScreen.main.bounds.width
        let GHeight = UIScreen.main.bounds.height
        var delegate: GestureVerified?
        
        fileprivate lazy var passwordBox: Box = {
                let box = Box(frame: CGRect(x: 50, y: 200, width: GWidth - 2 * 50, height: 400))
                box.delegate = self
                return box
        }()
        
        fileprivate lazy var warnLabel: WarnLabel = {
                let label = WarnLabel(frame: CGRect(x: 50, y: 140, width: GWidth - 2 * 50, height: 20))
                label.text = "Please input gesture password".locStr
                return label
        }()
        
        fileprivate lazy var LoginBtn: UIButton = {
                let button = UIButton(frame: CGRect(x: (GWidth - 200)/2, y: GHeight - 60, width: 200, height: 20))
                button.setTitle("Forget gesture?".locStr, for: .normal)
                button.setTitleColor(UIColor(gpRGB: 0x1D80FC), for: .normal)
                return button
        }()
        
        var password: String = ""
        var firstPassword: String = ""
        var secondPassword: String = ""
        var canModify: Bool = false
        var type: GType? {
                didSet {
                        if type == .set {
                                warnLabel.text = "Please input gesture password".locStr
                                LoginBtn.isHidden = true
                        } else if type == .verify {
                                warnLabel.text = "Please input gesture password".locStr
                        } else {
                                warnLabel.text = "Please input origin password".locStr
                                LoginBtn.isHidden = true
                        }
                }
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                setupSubviews()
                
                LoginBtn.addTarget(self, action: #selector(tapForgetGesture(button:)), for: .touchUpInside)
        }
        
        @objc func tapForgetGesture(button: UIButton) {
                self.delegate?.verified(success: false)
                self.dismiss(animated: true)
        }
        
        func setupSubviews() {
                view.backgroundColor = .white
                config { options in
                        options.connectLineStart = .border
                        options.normalstyle = .outerStroke
                        options.isDrawTriangle = false
                        options.connectLineWidth = 4
                        options.matrixNum = 3
                }
                
                view.addSubview(passwordBox)
                view.addSubview(warnLabel)
                view.addSubview(LoginBtn)
                
                print(getPassword() ?? "")
        }
}

extension GestureViewController: GPasswordEventDelegate {
        func sendTouchPoint(with tag: String) {
                password += tag
        }
        
        func touchesEnded() {
                if password.count > 0 {
                        if type == .set {
                                setPassword()
                        }
                        if type == .verify {
                                let savePassword = getPassword() ?? ""
                                if password == savePassword {
                                        self.delegate?.verified(success: true)
//                                        navigationController?.popViewController(animated: true)
                                        self.dismiss(animated: true)
                                } else {
                                        warnLabel.showWarn(with: "Error password".locStr)
                                }
                        }
                }
                password = ""
        }
}

extension GestureViewController {
        func setPassword() {
                if firstPassword.isEmpty {
                        firstPassword = password
                        warnLabel.showNormal(with: "Please input again to confirm".locStr)
                } else {
                        secondPassword = password
                        if firstPassword == secondPassword {
                                save(password: firstPassword)
                                _ = Wallet.shared.UpdateUseGesture(by: true)
                                navigationController?.popViewController(animated: true)
                        } else {
                                warnLabel.showWarn(with: "Password different, please re-set".locStr)
                                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                        self.warnLabel.showNormal(with: "Please input gesture password".locStr)
                                }
                                firstPassword = ""
                                secondPassword = ""
                        }
                }
        }
}
