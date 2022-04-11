//
//  AgentButton.swift
//  immeta
//
//  Created by ribencong on 2021/9/1.
//

import UIKit

public enum AgentStatus {
        case initial, activated, almostExpire
}

extension AgentStatus {
    
        var color: UIColor {
                switch self {
                case .initial, .almostExpire:
                        return UIColor.init(hex: "000000")
                case .activated:
                        return UIColor.init(hex: "FFD477")
                }
        }
        
        var fontColor: UIColor {
                switch self {
                case .initial, .almostExpire:
                    return UIColor.init(hex: "FFFFFF")
                case .activated:
                    return UIColor.init(hex: "#000000")
                }
        }
    
        var handleText: [String] {
                switch self {
                case .initial:
                        return ["Active".locStr, "Inactive".locStr]
                case .activated:
                        return ["Renew".locStr, "In Use".locStr]
                case .almostExpire:
                        return ["Renew".locStr, "License remains".locStr]
                }
        }
    
}

class AgentButton: UIButton {
    
        var currentStatus: AgentStatus = .initial {
                didSet {
                        self.setTitleColor(self.currentStatus.fontColor, for: .normal)
                        self.backgroundColor = self.currentStatus.color
                        self.setTitle(self.currentStatus.handleText[0], for: .normal)
                }
        }

}
