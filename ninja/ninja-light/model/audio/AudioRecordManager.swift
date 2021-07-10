//
//  Audio.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/1.
//

import Foundation
import AVFoundation


private let TempWavRecordPath = AudioFilesManager.wavPathWithName("wav_temp_record") //wav 临时路径
private let TempAmrFilePath = AudioFilesManager.amrPathWithName("amr_temp_record")   //amr 临时路径

class AudioRecordManager:NSObject {
    
    var recorder:AVAudioRecorder!
    var operationQueue: OperationQueue!
    
    weak var delegate: RecordAudioDelegate?
    
    fileprivate var startTime: CFTimeInterval! //录音开始时间
    fileprivate var endTimer: CFTimeInterval! //录音结束时间
    fileprivate var audioTimeInterval: NSNumber!
    fileprivate var isFinishRecord: Bool = true
    fileprivate var isCancelRecord: Bool = false

    let audioSession = AVAudioSession.sharedInstance()
    
    
    class var shared: AudioRecordManager {
        struct Static {
            static let instance: AudioRecordManager = AudioRecordManager()
        }
        return Static.instance
    }
    
    fileprivate override init() {
        self.operationQueue = OperationQueue()
        super.init()
    }

        
    func checkPermissionAndInitRecord(onFaild: @escaping(Bool) -> Void) {
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: .duckOthers)
            do {
                try audioSession.setActive(true)
                audioSession.requestRecordPermission { allowed in
                    if !allowed {
                        onFaild(allowed)
                    }
                }
            } catch let err as NSError {
                print("set audio session active faild \(err.localizedDescription)")
            }
        } catch let err as NSError {
            print("set audio session category faild \(err.localizedDescription)")
        }
        
    }
        
    func startRecord() {
        
        self.isCancelRecord = false
        self.startTime = CACurrentMediaTime()
        
        let recoredSetting = [AVSampleRateKey: NSNumber(44100.0),
                              AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),
                              AVNumberOfChannelsKey: NSNumber(1),
                              AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.medium.rawValue)] as [String : Any]
        
        do {
            self.recorder = try AVAudioRecorder(url: TempWavRecordPath, settings: recoredSetting)
            self.recorder.delegate = self
            self.recorder.isMeteringEnabled = true
            self.recorder.prepareToRecord()
        } catch let error as NSError {
            print(error)
        }
        
        self.perform(#selector(AudioRecordManager.readyStartRecord), with: self, afterDelay: 0.0)
    }
    
    func stopRecord() {
        self.isCancelRecord = false
        self.isFinishRecord = true
        self.endTimer = CACurrentMediaTime()
        
        if (self.endTimer - self.startTime) < 0.5 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(AudioRecordManager.readyStartRecord), object: self)
            
            dispatch_async_safely_to_main_queue({ () -> () in
                self.delegate?.audioRecordTooShort()
            })
        } else {
            self.audioTimeInterval = NSNumber(value: NSNumber(value: self.recorder.currentTime as Double).int32Value as Int32)
            
            if self.audioTimeInterval.int32Value < 1 {
                self.perform(#selector(AudioRecordManager.readyStopRecord), with: self, afterDelay: 0.4)
            } else {
                self.readyStopRecord()
            }
        }
        
        self.operationQueue.cancelAllOperations()
        
    }

    @objc func readyStartRecord() {
        
        do {
            try audioSession.setActive(true)
        } catch let error as NSError {
            print("setActive fail:\(error)")
            return
        }

        self.recorder.record()

        let operation = BlockOperation()
        operation.addExecutionBlock(updateMeters)
        self.operationQueue.addOperation(operation)
        
    }
    
    func updateMeters() {
        guard let recorder = self.recorder else { return }
        
        repeat {
            recorder.updateMeters()
            self.audioTimeInterval = NSNumber(value: NSNumber(value: recorder.currentTime as Double).floatValue as Float)
            let averagePower = recorder.averagePower(forChannel: 0)
            let lowPassResults = pow(10, (0.05 * averagePower)) * 10
            dispatch_async_safely_to_main_queue({ () -> () in
                
                self.delegate?.audioRecordUpdateMetra(lowPassResults)
            })
            
            if self.audioTimeInterval.int32Value > 60 {
                self.stopRecord()
            }
        
            Thread.sleep(forTimeInterval: 0.05)
        } while(recorder.isRecording)
        
    }
    
    func cancelRecord() {
        self.isCancelRecord = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(AudioRecordManager.readyStartRecord), object: self)
        self.isFinishRecord = false
        self.recorder.stop()
        self.recorder.deleteRecording()
        self.recorder = nil
        self.delegate?.audioRecordCanceled()
    }
    
    @objc func readyStopRecord() {
        self.recorder.stop()
        self.recorder = nil
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch let error as NSError {
            print("error:\(error)")
        }
    }
    
    func deleteRecordFiles() {
        AudioFilesManager.deleteAllRecordingFiles()
    }

   
}


extension AudioRecordManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag && self.isFinishRecord {
            guard let wavAudioData = try? Data(contentsOf: TempWavRecordPath) else {
                self.delegate?.audioRecordFailed()
                return
            }
            let fileName = String(data: wavAudioData, encoding: String.Encoding.utf8)
           
            let wavDestinationURL = AudioFilesManager.wavPathWithName(fileName ?? "")
            AudioFilesManager.renameFile(TempWavRecordPath, destinationPath: wavDestinationURL)
            
            self.delegate?.audioRecordWavFinish(wavAudioData, recordTime: self.audioTimeInterval.floatValue, fileHash: fileName ?? "")
            
        } else {
            self.delegate?.audioRecordFailed()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
            self.delegate?.audioRecordFailed()
        }
    }
}
