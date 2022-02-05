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
//                print("------>>>table view count:\(msgCacheArray.count) ")
                return msgCacheArray.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
                let msgItem = msgCacheArray[indexPath.row]
                var identifer = ""
                indexPathCache[msgItem.timeStamp] = indexPath

                switch msgItem.typ {
                case .plainTxt:
                        identifer = msgItem.isOut ? "messageCell" : "messageCellL"
                        
                        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! TxtTableViewCell
                        cell.updateMessageCell(by: msgItem, name:self.peerName, avatar:self.peerAvatarData)
                        return cell
                case .voice:
                        identifer = msgItem.isOut ? "voiceCell" : "voiceCellL"
                        
                        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! VoiceTableViewCell
                        cell.updateMessageCell(by: msgItem, name:self.peerName, avatar:self.peerAvatarData)
                        return cell
                case .image:
                        identifer = msgItem.isOut ? "imageCell" : "imageCellL"
                        
                        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! ImageTableViewCell
                        cell.updateMessageCell(by: msgItem, name:self.peerName, avatar:self.peerAvatarData)
                        return cell
                case .location:
                        identifer = msgItem.isOut ? "locationCell" : "locationCellL"
                        
                        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! LocationTableViewCell
                        cell.updateMessageCell(by: msgItem, name:self.peerName, avatar:self.peerAvatarData)
                        return cell
                case .file:
                        guard let fil = msgItem.payload as?fileMsg else{
                                return UITableViewCell()//set default invalid msg cell tip
                        }
                        if fil.typ == .video{
                                identifer = msgItem.isOut ? "videoCell" : "videoCellL"
                                
                                let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! VideoTableViewCell
                                cell.updateMessageCell(by: msgItem, name:self.peerName, avatar:self.peerAvatarData)
                                return cell
                        }
                        
                        identifer = msgItem.isOut ? "fileCell" : "fileCellL"
                        
                        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! FileTableViewCell
                        cell.updateMessageCell(by: msgItem, name:self.peerName, avatar:self.peerAvatarData)
                        return cell
                default:
                        return TxtTableViewCell()
                }
        }
}
