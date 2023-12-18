//
//  songVC.swift
//  Moodify
//
//  Created by Adam Schwartz on 11/21/23.
//

import Foundation

class songVC: UIViewController {
    var accessToken: String?

    
    @IBOutlet weak var nextSong: UIButton!
    @IBOutlet weak var likeSong: UIButton!

    @IBAction public func nextSongPressed(_ sender: Any) {
        print("next song pressed")
    }
    
    @IBAction public func likeSongPressed(_ sender: Any) {
        print("like song pressed")
    }
}
