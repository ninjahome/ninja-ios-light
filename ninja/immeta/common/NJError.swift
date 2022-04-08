//
//  NJError.swift
//  immeta
//
//  Created by wesley on 2021/4/6.
//

import Foundation

public enum NJError: Error,LocalizedError {
        
        case wallet(String)
        case coreData(String)
        case contact(String)
        case account(String)
        case group(String)
        case msg(String)
        case agent(String)
        case config(String)

        public var localizedDescription: String? {
                switch self {
                case .wallet(let err): return err
                case .coreData(let err): return err
                case .contact(let err):
                        print("------>>", err)
                        return err
                case .msg(let err): return err
                case .group(let err): return err
                case .agent(let err): return err
                case .account(let err): return err
                case .config(let err): return err
                }
        }
    
}
