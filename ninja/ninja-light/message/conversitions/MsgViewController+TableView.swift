//
//  MsgViewController+TableView.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/6.
//
import UIKit
import Foundation

extension MsgViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let msgItem = messages[indexPath.row]
        var identifer = ""
        
        switch msgItem.typ {
        case .plainTxt:
            identifer = msgItem.isOut ? "messageCell" : "messageCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! MessageTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        case .voice:
            identifer = msgItem.isOut ? "voiceCell" : "voiceCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! VoiceTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        case .image:
            identifer = msgItem.isOut ? "imageCell" : "imageCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! ImageTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        case .location:
            identifer = msgItem.isOut ? "locationCell" : "locationCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! LocationTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        case .video:
            identifer = msgItem.isOut ? "fileCell" : "fileCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! LocationTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        default:
            return MessageTableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
