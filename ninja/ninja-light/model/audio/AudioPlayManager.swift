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
        let session = AVAudioSession.sharedInstance()
        public static let shared : AudioPlayManager = AudioPlayManager()
        
        override init() {
                super.init()
                do{
                        try session.setCategory(.playback)
                }catch let err{
                        print("------>>>player init failed[\(err)]")
                        return
                }
        }
        func stopPlay(){
                guard let player = self.audioPlayer, player.isPlaying else{
                        return
                }
                player.stop()
        }
        
        func playMusic(file: Data) {
                
                do {
                        try session.setActive(true, options: .notifyOthersOnDeactivation)
                        audioPlayer = try AVAudioPlayer(data: file)
                        audioPlayer?.delegate = self
                        
                        if (audioPlayer!.prepareToPlay()){
                                audioPlayer!.play()
                        }
                        
                } catch let err{
                        print("------>>>play music failed[\(err)]")
                        return
                }
        }
        
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                         successfully flag: Bool){
                
                print("------>>>play music result[\(flag)]")
        }
}
