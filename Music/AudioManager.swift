//
//  AudioManager.swift
//  Sound
//
//  Created by Pedro Cacique on 06/11/19.
//  Copyright © 2019 Pedro Cacique. All rights reserved.
//

import Foundation
import AVFoundation

class AudioManager {
    let events = EventManager()
    var player:AVAudioPlayer = AVAudioPlayer()
    static let TRACKS_MERGED:String = "tracksMerged"
    static let TRACKS_CONCATENATED:String = "tracksConcatenated"
    var urls:[URL] = []
    var totalDuration:Float = 0
    
    func playAudio(_ url:URL, rate:Float = 2.0){
        do{
            self.player = try AVAudioPlayer(contentsOf: url)
            player.enableRate = true
            player.rate = rate
            self.player.play()
        }catch let error {
            print("Can't play the audio file failed with an error \(error.localizedDescription)")
        }
    }
    
    static func getAudioURL(name:String) -> URL{
        return URL.init(fileURLWithPath: Bundle.main.path(forResource: name, ofType: "mp3")!)
    }
    
    func mergeTracks(audios:[URL]){
        let composition = AVMutableComposition()
        for url in audios{
            let audioAsset = AVURLAsset(url: url, options: nil)
            let audioTrack: AVMutableCompositionTrack? = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
            do{
                try audioTrack?.insertTimeRange(
                    CMTimeRangeMake(start: CMTime.zero, duration: audioAsset.duration),
                    of: audioAsset.tracks(withMediaType: AVMediaType.audio)[0],
                    at: CMTime.zero
                )
            } catch let error{
                print("Can't play the audio file failed with an error \(error.localizedDescription)")
            }
        }
        
        let _assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        let mixedAudio: String = "\(String.random(length: 10)).m4a"
        var exportPath = NSTemporaryDirectory() + (mixedAudio)
        
        let exportURL = URL(fileURLWithPath: exportPath)
        if FileManager.default.fileExists(atPath: exportPath) {
        try? FileManager.default.removeItem(atPath: exportPath)
        }
        _assetExport?.outputFileType = AVFileType.m4a
        _assetExport?.outputURL = exportURL
        _assetExport?.shouldOptimizeForNetworkUse = true
        _assetExport?.exportAsynchronously(completionHandler: {() -> Void in
            print("Merge Completed Sucessfully")
            self.events.trigger(eventName: AudioManager.TRACKS_MERGED, information: exportURL);
        })
    }
    
    func concatenateTracks(audios:[URL]){
        let composition = AVMutableComposition()
        let audioTrack: AVMutableCompositionTrack? = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        for url in audios{
            let audioAsset = AVURLAsset(url: url, options: nil)
            
            var error: Error?
            try? audioTrack?.insertTimeRange(
                CMTimeRangeMake(start: CMTime.zero, duration: audioAsset.duration),
                of: audioAsset.tracks(withMediaType: AVMediaType.audio)[0],
                at: CMTime.zero
            )
            if error != nil {
                print("\(String(describing: error?.localizedDescription))")
            }
        }
        
        let _assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        let mixedAudio: String = "\(String.random(length: 10)).m4a"
        var exportPath = NSTemporaryDirectory() + (mixedAudio)
        let exportURL = URL(fileURLWithPath: exportPath)
        if FileManager.default.fileExists(atPath: exportPath) {
        try? FileManager.default.removeItem(atPath: exportPath)
        }
        _assetExport?.outputFileType = AVFileType.m4a
        _assetExport?.outputURL = exportURL
        _assetExport?.shouldOptimizeForNetworkUse = true
        _assetExport?.exportAsynchronously(completionHandler: {() -> Void in
            print("Concatenate Completed Sucessfully")
            self.events.trigger(eventName: AudioManager.TRACKS_CONCATENATED, information: exportURL);
        })
    }
}

//let cat:Cat = Cat()
//cat.events.listenTo(eventName: "meow", action: {
//    print("Human: Awww, what a cute kitty *pets cat*")
//})
//cat.meow()

extension String{
    static func random(length: Int) -> String {

        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
}
