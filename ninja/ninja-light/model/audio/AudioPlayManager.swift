//
//  AudioPlayManager.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/2.
//

import Foundation
import AVFoundation

class AudioPlayManager: NSObject, AVAudioPlayerDelegate {
        
        private var audioPlayer:AVAudioPlayer?
        let session = AVAudioSession.sharedInstance()
        public static let shared : AudioPlayManager = AudioPlayManager()
        
        override init() {
                super.init()
        }
        func stopPlay(){
                guard let player = self.audioPlayer, player.isPlaying else{
                        return
                }
                player.stop()
        }
        
        func playMusic(rawData: Data) {
                
                do {
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                        
                        if let oldPlayer = self.audioPlayer, oldPlayer.isPlaying {
                                oldPlayer.stop()
                        }
                        try session.setActive(true)
                        audioPlayer = try AVAudioPlayer(data: rawData)
                        audioPlayer?.delegate = self
                        
                        if (audioPlayer!.prepareToPlay()){
                                audioPlayer!.play()
                        }
                        audioPlayer!.play()
                } catch let err{
                        print("------>>>play music failed[\(err)], data len:[\(rawData.count)]")
                        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
                        return
                }
        }
        
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                         successfully flag: Bool){
                
                print("------>>>play music result[\(flag)]")
                do {
                        try session.setActive(false, options: [.notifyOthersOnDeactivation])
                        
                }catch let err{
                        print("------>>>session setActive false failed[\(err)]")
                }
        }
        
        func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int){
                print("------>>>audioPlayerEndInterruption flags =[\(flags)]")
        }
        func audioPlayerBeginInterruption(_ player: AVAudioPlayer){
                print("------>>>audioPlayerBeginInterruption")
        }
}
