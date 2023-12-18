//
//  chooseMoodVC.swift
//  Moodify
//
//  Created by Adam Schwartz on 11/21/23.
//

import Foundation

class chooseMoodVC: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var recommendations: [[String: String]] = []
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row] // The title for each row
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Code to handle the selection
        print("Selected item: \(pickerData[row])")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        genreView.delegate = self
        genreView.dataSource = self
    }


    
    var accessToken: String?

    
    @IBOutlet weak var obscuritySlider: UISlider!
    @IBOutlet weak var lengthSlider: UISlider!
    
    @IBOutlet weak var genreView: UIPickerView!
    var trackURIs: [String] = []

    
    @IBAction public func genrePressed(_ sender: UIButton) {
        print("genre button pressed")
    }
    let pickerData = ["country", "classical", "pop"]
    
    func getSelectedPickerValue() -> String {
        let selectedRow = genreView.selectedRow(inComponent: 0)
        return pickerData[selectedRow]
    }


    
    @IBAction public func moodifyPressed(_ sender: Any) {
        print("moodify pressed")
        let current_genre = getSelectedPickerValue()
        fetchRecommendations(genre: current_genre, targetPopularity: Int(obscuritySlider.value), minDurationMs: Int(lengthSlider.value)) { recommendations, error in
            if let recommendations = recommendations {
                // Handle the fetched recommendations
            } else if let error = error {
                // Handle the error
            }
        }
    }
    
    @IBAction public func obscurityChanged(_ sender: Any) {
        print("Obscurity: \(obscuritySlider.value)")
    }
    
    @IBAction public func lengthChanged(_ sender: Any) {
        print("Length: \(lengthSlider.value)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PlaylistDisplaySegue",
           let destinationVC = segue.destination as? PlaylistDisplayVC {
            print("Sending data: \(self.recommendations)")
            destinationVC.playlist = self.recommendations
            destinationVC.accessToken = self.accessToken
            destinationVC.trackURIs = self.trackURIs
        }
    }
    
    func fetchRecommendations(genre: String, targetPopularity: Int, minDurationMs: Int, completion: @escaping ([String: Any]?, Error?) -> Void) {
        print("recommendations")
        print(self.accessToken!)
        DispatchQueue.global().async { [self] in
            var components = URLComponents(string: "https://api.spotify.com/v1/recommendations")!
            var queryItems = [URLQueryItem(name: "seed_genres", value: genre)]
            queryItems.append(URLQueryItem(name: "target_popularity", value: "\(targetPopularity)"))
            queryItems.append(URLQueryItem(name: "min_duration_ms", value: "\(minDurationMs)"))
            components.queryItems = queryItems
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            request.setValue("Bearer \(self.accessToken!)", forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print(error)
                    return
                }
                guard let data = data else {
                    print("no data")
                    return
                }

                do {
                    // Parsing the JSON data
                    if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let tracks = jsonResult["tracks"] as? [[String: Any]] {
                        
                        self.trackURIs.removeAll()
                        self.recommendations.removeAll()
                        // Extracting details from each track
                        for track in tracks {
                            var trackDetails: [String: String] = [:]

                            // Extracting track name
                            if let name = track["name"] as? String {
                                trackDetails["name"] = name
                            }
                            if let uri = track["uri"] as? String {
                                self.trackURIs.append(uri)
                            }

                            // Extracting artist(s) name
                            if let artists = track["artists"] as? [[String: Any]],
                               let artistName = artists.first?["name"] as? String {
                                trackDetails["artist"] = artistName
                            }

                            // Extracting artwork URL
                            if let album = track["album"] as? [String: Any],
                               let images = album["images"] as? [[String: Any]],
                               let imageUrl = images.first?["url"] as? String {
                                trackDetails["artworkUrl"] = imageUrl
                            }

                            self.recommendations.append(trackDetails)
                        }
                        print("Self.recommendations:  \(self.recommendations)")
                        
                        DispatchQueue.main.sync {
                            self.performSegue(withIdentifier: "PlaylistDisplaySegue", sender: self)
                        }
                        
                    } else {
                    }
                } catch {
                    print(error)
                }
            }
            task.resume()
            //
        }
    }
}
