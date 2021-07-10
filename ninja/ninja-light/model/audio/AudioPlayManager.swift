//
//  AudioPlayManager.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/2.
//

import Foundation
import AVFoundation

class AudioPlayManager: NSObject, AVAudioPlayerDelegate {
    
    var audioPlayer:AVAudioPlayer!
//    weak var delegate: PlayAudioDelegate?
    
    let session = AVAudioSession.sharedInstance()
    
    class var sharedInstance : AudioPlayManager {
        struct Static {
            static let instance : AudioPlayManager = AudioPlayManager()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        do{
            try session.setCategory(AVAudioSession.Category.playback)
            try session.setActive(true)
        }catch {
            print(error)
            return
        }
    }
    
    func playMusic(file: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: file)
            audioPlayer?.delegate = self

            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            print("播放成功")
        }catch {
            print(error)
            return
        }
    }
    
    
    
}
//usage:
//self.audioPlayer = AudioPlayManager()
//self.audioPlayer.playMusic(file: Data)
