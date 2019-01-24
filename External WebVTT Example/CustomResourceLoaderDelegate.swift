//
//  CustomResourceLoaderDelegate.swift
//  External WebVTT Example
//
//  Created by Joris Weimar on 24/01/2019.
//  Copyright © 2019 Joris Weimar. All rights reserved.
//

import Foundation
import AVFoundation

/**
 A custom resource loader delegate that will manipulate the .m3u8 and inject
 the VTT for us.
 */

class CustomResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    static let mainScheme = "mainm3u8"
    private let fragmentsScheme = "fragmentsm3u8"
    private let subtitlesScheme = "subtitlesm3u8"
    private let extInfPrefix = "#EXTINF:"
    private var m3u8URL: URL
    private var vttURL: URL
    private var m3u8String: String? = nil
    private var playlistDuration: Double = 0.0
    
    init(m3u8URL: URL, vttURL: URL) {
        self.m3u8URL = m3u8URL
        self.vttURL = vttURL
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource
        loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let scheme = loadingRequest.request.url?.scheme else {
            return false
        }
        
        switch (scheme) {
        case CustomResourceLoaderDelegate.mainScheme:
            return handleMainRequest(loadingRequest)
        case fragmentsScheme:
            return handleFragments(loadingRequest)
        case subtitlesScheme:
            return handleSubtitles(loadingRequest)
        default:
            return false
        }
    }
    
    func handleMainRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        let task = URLSession.shared.dataTask(with: m3u8URL) {
            [weak self] (data, response, error) in
            guard error == nil,
                let data = data else {
                    request.finishLoading(with: error)
                    return
            }
            self?.processPlaylistWithData(data)
            self?.finishRequestWithMainPlaylist(request)
        }
        task.resume()
        return true
    }
    
    func handleFragments(_ request: AVAssetResourceLoadingRequest) -> Bool {
        let data = m3u8String!.data(using: .utf8)!
        request.dataRequest?.respond(with: data)
        request.finishLoading()
        return true
    }
    
    func handleSubtitles(_ request: AVAssetResourceLoadingRequest) -> Bool {
        let subtitlem3u8 = getSubtitlem3u8WithDuration(playlistDuration)
        let data = subtitlem3u8.data(using: .utf8)!
        request.dataRequest?.respond(with: data)
        request.finishLoading()
        return true
    }
    
    func getDurationForEXTINFLine(_ line: String) -> Double {
        let components = line.components(separatedBy: ":")
        return Double(components[1].dropLast())!
    }
    
    func processPlaylistWithData(_ data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }
        let lines = string.components(separatedBy: "\n")
        var newLines = [String]()
        var iterator = lines.makeIterator()
        playlistDuration = 0.0
        while let line = iterator.next() {
            newLines.append(line)
            if line.hasPrefix(extInfPrefix) { // Process each fragment
                playlistDuration += getDurationForEXTINFLine(line)
                if let newLine = iterator.next() { // Next line contains path
                    newLines.append(appendBasePath(newLine))
                }
            }
        }
        m3u8String = newLines.joined(separator: "\n")
    }
    
    func appendBasePath(_ string: String) -> String {
        var components = URLComponents(string: m3u8URL.absoluteString)
        components?.query = nil
        let path = components!.url!.deletingLastPathComponent().absoluteString
        return path + string
    }
    
    func finishRequestWithMainPlaylist(_ request: AVAssetResourceLoadingRequest) {
        let mainm3u8 = getMainm3u8()
        let data = mainm3u8.data(using: .utf8)!
        request.dataRequest?.respond(with: data)
        request.finishLoading()
    }
    
    func getMainm3u8() -> String {
        let mainm3u8 = """
#EXTM3U
#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",DEFAULT=NO,FORCED=NO,URI="subtitlesm3u8://foo",LANGUAGE="en"
#EXT-X-STREAM-INF:BANDWIDTH=1280000,SUBTITLES="subs"
fragmentsm3u8://foo
"""
        return mainm3u8
    }
    
    func getSubtitlem3u8WithDuration(_ duration: Double) -> String {
        let durationString = String(format: "%.3f", duration)
        let intDuration = Int(duration)
        let subtitlem3u8 = """
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-MEDIA-SEQUENCE:1
#EXT-X-PLAYLIST-TYPE:VOD
#EXT-X-ALLOW-CACHE:NO
#EXT-X-TARGETDURATION:\(intDuration)
#EXTINF:\(durationString), no desc
\(vttURL.absoluteString)
#EXT-X-ENDLIST
"""
        return subtitlem3u8
    }
}
