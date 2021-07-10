//
//  AudioDelegate.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/2.
//

import Foundation

protocol RecordAudioDelegate: AnyObject {

    func audioRecordUpdateMetra(_ metra: Float)

    func audioRecordTooShort()
    
    func audioRecordFailed()
    
    func audioRecordCanceled()
    
     /**
     - parameter recordTime:        录音时长
     - parameter uploadAmrData:     上传的 amr Data
     - parameter fileHash:          amr 音频数据的 MD5 值 (NSData)
     */
    func audioRecordFinish(_ uploadAmrData: Data, recordTime: Float, fileHash: String)
    
    func audioRecordWavFinish(_ uploadWavData: Data, recordTime: Float, fileHash: String)

}

protocol PlayAudioDelegate: AnyObject {
    
    func audioPlayStart()
    
    func audioPlayFinished()
    
    func audioPlayFailed()
    
    func audioPlayInterruption()
}
