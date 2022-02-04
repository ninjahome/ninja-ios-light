//
//  Audio.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/1.
//

import Foundation
import AVFoundation


private let TempWavRecordPath = "wav_temp_record"

class AudioRecordManager:NSObject {
        public static let MaxAudioLengthInSecond = 60.0
        public static let MinAudioLengthInSecond = 0.5
        public static let shared: AudioRecordManager = AudioRecordManager()
        
        
        private var recorder:AVAudioRecorder?
        private var recordTimer:Timer?
        private var audioTimeInterval: TimeInterval = 0
        weak var delegate: RecordAudioDelegate?
        var currntUrl = FileManager.TmpDirectory().appendingPathComponent(TempWavRecordPath)
        
        let recoredSetting = [AVSampleRateKey: NSNumber(8000.0),
                                AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                        AVNumberOfChannelsKey: NSNumber(1),
                     AVEncoderBitDepthHintKey:16,
                     AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.high.rawValue)] as [String : Any]
        
        
        func startRecord() -> Error?{
                
                do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        guard let rc =  try? AVAudioRecorder(url: self.currntUrl, settings: recoredSetting) else{
                                throw NJError.msg("create audio item failed")
                        }
                        
                        rc.delegate = self
                        rc.isMeteringEnabled = true
                        guard rc.prepareToRecord() else{
                                throw NJError.msg("failed prepare microphone")
                        }
                        
                        rc.record()
                        self.recorder = rc
                        
                        self.recordTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true, block: self.metraTimer)
                        
                } catch let err {
                        print("------>>>", err.localizedDescription)
                        self.finishRecrod(isReset: true)
                        return err
                }
                
                return nil
        }
        
        private func metraTimer(_ timer:Timer){
                guard let rc = self.recorder else{
                        return
                }
                
                rc.updateMeters()
                self.audioTimeInterval = rc.currentTime
                self.delegate?.audioRecordUpdateMetra(self.audioTimeInterval)
                
                if self.audioTimeInterval >= AudioRecordManager.MaxAudioLengthInSecond{
                        self.finishRecrod()
                }
        }
        
        func finishRecrod(isReset:Bool = false){
                self.recorder?.stop()
                if isReset{
                        self.recorder?.deleteRecording()
                }
                self.recordTimer?.invalidate()
                
                self.recorder = nil
                self.recordTimer = nil
                
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
}


extension AudioRecordManager: AVAudioRecorderDelegate {
        
        func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
                
                guard flag else{
                        self.delegate?.audioRecordFailed()
                        return
                }
                guard let wavAudioData = try? Data(contentsOf: self.currntUrl) else {
                        self.delegate?.audioRecordCanceled()
                        return
                }
                if self.audioTimeInterval < AudioRecordManager.MinAudioLengthInSecond{
                        self.delegate?.audioRecordTooShort()
                        return
                }
                
                self.delegate?.audioRecordWavFinish(wavAudioData, recordTime: self.audioTimeInterval, fileHash: "")
        }
        
        func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
                guard let e = error else{
                        return
                }
                print("------>>>\(e.localizedDescription)")
                self.delegate?.audioRecordFailed()
        }
}
