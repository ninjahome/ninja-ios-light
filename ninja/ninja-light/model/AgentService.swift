//
//  AgentService.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/1.
//

import Foundation
import ChatLib

enum ImportResultCode: Int {
    case Success = 0
    case ParseJsonErr
    case ConnectionErr
    case CallContractErr
    case OtherErr
}

enum IsVaildResultCode: Int {
    case DecodeLicenseErr = 0
    case ConnectionErr
    case ContractErr
    case CallContractErr
    case ValidTrue
    case ValidFalse
}

extension IsVaildResultCode {
    var localizedDescription: String {
        switch self {
        case .ValidFalse:
            return "This license is already used."
        default:
            return ""
        }
    }
}

class AgentService {
    var expireDate: String = ""
    var expireDays: Int = 0
    var isActive: Bool = false
    
    public static let shared = AgentService()
    
    func getAgentStatus() -> AgentStatus {

        let currentTime = Int64(Date().timeIntervalSince1970)
        let expireTime = ChatLib.ChatLibGetLicense(0)
        expireDate = formatTimeStamp(by: expireTime)
        if currentTime > expireTime {
            return AgentStatus.initial
        }
        
        self.isActive = true
        
        let expStamp = expireTime - currentTime
        expireDays = Int(expStamp / 86400)
        
        if expStamp < 604800 {
            return AgentStatus.almostExpire
        }
        
        return AgentStatus.activated
    }
    
    func decodeLicense(_ licenseCode: String) throws -> String? {
        let license = ChatLib.ChatLibDecodeLicense(licenseCode)
        let code = ChatLib.ChatLibIsValidLicense(licenseCode)
        let verifyCode = IsVaildResultCode(rawValue: code)
        
        switch verifyCode {
        case .ValidFalse:
            return license
        case .ValidTrue:
            throw NJError.agent(verifyCode!.localizedDescription)
        default:
            return nil
        }
        
    }
    
    func importVaildLicense(_ license: String) throws {
        let importRes = ChatLib.ChatLibImportLicense(license)
        let dict = getDictionaryFromJSONString(jsonString: importRes)
        guard let rawVal = dict["result_code"] as? Int else {
            return
        }
        let impCode = ImportResultCode(rawValue: rawVal)
        switch impCode {
        case .Success:
            self.isActive = true
            break
        default:
            throw NJError.agent(dict["result_message"] as! String)
        }
    }
    
    func transferLicense(to addr: String, days: Int) -> Bool {
        let ret = ChatLib.ChatLibTransferLicense(addr, days)
        
        if ret == "" {
            return false
        }
        
        return true
    }
        
}
