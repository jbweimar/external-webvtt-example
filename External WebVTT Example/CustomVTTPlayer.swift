//
//  CustomResourceLoaderDelegate.swift
//  External WebVTT
//
//  Created by Joris Weimar on 1/24/2019.
//  Copyright © 2019 Joris Weimar. All rights reserved.
//

import Foundation
import AVFoundation

class CustomVTTPlayer: AVPlayer {
    private var loaderQueue = DispatchQueue(label: "resourceLoader")
    private var m3u8URL: URL
    private var delegate: CustomResourceLoaderDelegate
    
    init?(m3u8URL: URL, vttURL: URL) {
        self.m3u8URL = m3u8URL
        self.delegate = CustomResourceLoaderDelegate(m3u8URL: m3u8URL,
                                                     vttURL: vttURL)
        super.init()
        let customScheme = CustomResourceLoaderDelegate.mainScheme
        guard let customURL = replaceURLWithScheme(customScheme,
                                                   url: m3u8URL) else {
                                                    return nil
        }
        let asset = AVURLAsset(url: customURL)
        asset.resourceLoader.setDelegate(delegate, queue: loaderQueue)
        let playerItem = AVPlayerItem(asset: asset)
        self.replaceCurrentItem(with: playerItem)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    func replaceURLWithScheme(_ scheme: String, url: URL) -> URL? {
        let urlString = url.absoluteString
        guard let index = urlString.firstIndex(of: ":") else { return nil }
        let rest = urlString[index...]
        let newUrlString = scheme + rest
        return URL(string: newUrlString)
    }
    
}
