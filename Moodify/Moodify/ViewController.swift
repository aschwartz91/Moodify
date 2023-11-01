//
//  ViewController.swift
//  Moodify
//
//  Created by Adam Schwartz on 11/1/23.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var connectWithSpotify: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        connectWithSpotify.clipsToBounds = true

    }

    @IBAction func connectWithSpotifyPressed(_ sender: Any) {
        //Spotify credentials authorization...
    }
    
}

