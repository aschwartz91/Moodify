//
//  chooseMoodVC.swift
//  Moodify
//
//  Created by Adam Schwartz on 11/21/23.
//

import Foundation

class chooseMoodVC: UIViewController {
    
    @IBOutlet weak var chooseGenre: UIButton!
    @IBOutlet weak var obscuritySlider: UISlider!
    @IBOutlet weak var lengthSlider: UISlider!
    
    @IBAction public func genrePressed(_ sender: UIButton) {
        print("genre button pressed")
    }
    
    @IBAction public func moodifyPressed(_ sender: Any) {
        print("moodify pressed")
    }
    
    @IBAction public func obscurityChanged(_ sender: Any) {
        print("Obscurity: \(obscuritySlider.value)")
    }
    
    @IBAction public func lengthChanged(_ sender: Any) {
        print("Length: \(lengthSlider.value)")
    }
    
}
