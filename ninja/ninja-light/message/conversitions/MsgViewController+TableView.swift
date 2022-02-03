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
                return msgCacheArray.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
                let msgItem = msgCacheArray[indexPath.row]
                var identifer = ""
                indexPathCache[msgItem.timeStamp] = indexPath
                
//                print("------>>row[\(indexPath.row)]=>msg[\(msgItem.timeStamp)]")
                
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
                case .file:
                        guard let fil = msgItem.payload as?fileMsg else{
                                return UITableViewCell()//set default invalid msg cell tip
                        }
                        if fil.typ == .video{
                                identifer = msgItem.isOut ? "videoCell" : "videoCellL"
                                
                                let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! VideoTableViewCell
                                cell.updateMessageCell(by: msgItem)
                                return cell
                        }
                        
                        identifer = msgItem.isOut ? "fileCell" : "fileCellL"
                        
                        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! FileTableViewCell
                        cell.updateMessageCell(by: msgItem)
                        return cell
                default:
                        return MessageTableViewCell()
                }
        }
}
