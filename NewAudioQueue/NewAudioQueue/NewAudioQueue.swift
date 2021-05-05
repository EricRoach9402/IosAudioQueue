//
//  NewAudioQueue.swift
//  DolphinDebug
//
//  Created by 方奕凱 on 2021/5/1.
//

import UIKit
import AudioToolbox

extension Notification.Name {
    static let audioServiceDidUpdateData = Notification.Name(rawValue: "AudioQueueCaptureDidUpdateDataNotification")
}
//當錄製音頻隊列完成填充時呼叫
func AQAudioQueueInputCallback(inUserData: UnsafeMutableRawPointer?,
                               inAQ: AudioQueueRef,
                               inBuffer: AudioQueueBufferRef,
                               inStartTime: UnsafePointer<AudioTimeStamp>,
                               inNumberPacketDescriptions: UInt32,
                               inPacketDescs: UnsafePointer<AudioStreamPacketDescription>?) {
    let audioService = unsafeBitCast(inUserData!, to:newAudioQueue.self)
    if inBuffer.pointee.mAudioDataByteSize == 0 {
        //audioService.isLastFrame = "0"
        return
    }
    audioService.writePackets(inBuffer: inBuffer)
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
    
    //print("startingPacketCount: \(audioService.startingPacketCount), maxPacketCount: \(audioService.maxPacketCount)")
    if (audioService.maxPacketCount <= audioService.startingPacketCount) {
        audioService.stopRecord()
    }
}

class newAudioQueue {
    
    static let MyAudioQueue = newAudioQueue()
    
    var buffer: UnsafeMutableRawPointer
    var audioQueueObject: AudioQueueRef?
    //let numPacketsToRead: UInt32 = 44100
    var numPacketsToWrite: UInt32 = 48000
    var startingPacketCount: UInt32
    var maxPacketCount: UInt32
    let bytesPerPacket: UInt32 = 2
    let seconds: UInt32 = 200
    var audioFormat: AudioStreamBasicDescription {
      return AudioStreamBasicDescription(mSampleRate: 48000.0,
                                         mFormatID: kAudioFormatLinearPCM,
                                         mFormatFlags: AudioFormatFlags(kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked),
                                         mBytesPerPacket: 2,//每包中的位元數
                                         mFramesPerPacket: 1,//幀數
                                         mBytesPerFrame: 2,
                                         mChannelsPerFrame: 1,//聲道數
                                         mBitsPerChannel: 16,//位寬,不必改
                                         mReserved: 0)//未滿８位數自動補０
    }
    var data: NSData? {
      didSet {
        NotificationCenter.default.post(name: .audioServiceDidUpdateData, object: self)
      }
    }

    //init(_ obj: Any?) {
    init() {
      startingPacketCount = 0
      maxPacketCount = (48000 * seconds)
      buffer = UnsafeMutableRawPointer(malloc(Int(maxPacketCount * bytesPerPacket)))
    }

    func startRecord() {
            buffer = UnsafeMutableRawPointer(malloc(Int(maxPacketCount * bytesPerPacket)))
            guard audioQueueObject == nil else  { return }
            data = nil
            prepareForRecord()
            let err: OSStatus = AudioQueueStart(audioQueueObject!, nil)
            print("err: \(err)")
        }
    private func prepareForRecord() {
            print("prepareForRecord")
            var audioFormat = self.audioFormat
            AudioQueueNewInput(&audioFormat,
                               AQAudioQueueInputCallback,
                               unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
                               CFRunLoopGetCurrent(),
                               CFRunLoopMode.commonModes.rawValue,
                               0,
                               &audioQueueObject)
            startingPacketCount = 0;
            var buffers = Array<AudioQueueBufferRef?>(repeating: nil, count: 3)
            let bufferByteSize: UInt32 = numPacketsToWrite * audioFormat.mBytesPerPacket
            for bufferIndex in 0 ..< buffers.count {
                AudioQueueAllocateBuffer(audioQueueObject!, bufferByteSize, &buffers[bufferIndex])
                AudioQueueEnqueueBuffer(audioQueueObject!, buffers[bufferIndex]!, 0, nil)
            }
        }

    func stopRecord() {
        AudioQueueStop(audioQueueObject!, true)
        AudioQueueDispose(audioQueueObject!, true)
        audioQueueObject = nil
        data = NSData(bytesNoCopy: buffer, length: Int(startingPacketCount * bytesPerPacket))
        //print(data)
        //print(buffer)
        var byteArray = [UInt8]()
        byteArray = [UInt8](data!)
        //print(byteArray)
            
        /*let u16data = Data(byteArray)
        let u16array = u16data.withUnsafeBytes{Array($0.bindMemory(to: Int16.self))}
        //let u16array = u16data.withUnsafeBytes{Array($0.bindMemory(to: Int16.self)).map(Int16.init(bigEndian:))}
        print(u16array)*/
        
        
            //print(byteArray)
        let u16data = Data(byteArray)
        var u16 = [Int16]()
        u16 = u16data.withUnsafeBytes{[Int16](UnsafeBufferPointer(start: $0, count: u16data.count/MemoryLayout<Int16>.stride))}
        print(u16)
        print(u16.min())
        print(u16.max())
    }

    func writePackets(inBuffer: AudioQueueBufferRef) {
            //print("writePackets mAudioDataByteSize: \(inBuffer.pointee.mAudioDataByteSize), numPackets: \(inBuffer.pointee.mAudioDataByteSize / 2)")
            var numPackets: UInt32 = (inBuffer.pointee.mAudioDataByteSize / bytesPerPacket)
            if ((maxPacketCount - startingPacketCount) < numPackets) {
                numPackets = (maxPacketCount - startingPacketCount)
            }
            /*
                      **do what you wanna do
                  */
            if 0 < numPackets {
                memcpy(buffer.advanced(by: Int(bytesPerPacket * startingPacketCount)),
                       inBuffer.pointee.mAudioData,
                       Int(bytesPerPacket * numPackets))
                
            }
        //在此開始對Buffer中的數據做處理
        autoreleasepool{//autoreleasepool釋放NSData內存
            data = NSData(bytesNoCopy: buffer, length: Int(startingPacketCount * bytesPerPacket))
            //將轉data為bate陣列
            //byteArray = [UInt8](data!)
        }
        startingPacketCount += numPackets;
        }
}
