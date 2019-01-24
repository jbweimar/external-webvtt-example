//
//  ViewController.swift
//  External WebVTT Example
//
//  Created by Joris Weimar on 16/11/2018.
//  Copyright © 2018 Joris Weimar. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    let m3u8URL = URL(string: "https://somedomain.com/playlist.m3u8")!
    let vttURL = URL(string: "https://somedomain.com/subtitles.vtt")!
    
    @IBAction func playMovie(_ sender: Any) {
        let player = CustomVTTPlayer(m3u8URL: m3u8URL, vttURL: vttURL)
        let vc = AVPlayerViewController()
        vc.player = player
        present(vc, animated: true)
    }
    
}

