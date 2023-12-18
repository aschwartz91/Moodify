//
//  PlaylistDisplayVC.swift
//  Moodify
//
//  Created by Jay Kim on 12/2/23.
//

import UIKit

class PlaylistDisplayVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var playlistTable: UITableView!
    
    var playlist: [[String: String]] = [] //Array of track details
    var accessToken: String?
    var userId: String?
    var playlistId: String?
    var trackURIs: [String] = []
    
    func getCurrentLocalTime() -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: currentDate)
    }

    @IBOutlet weak var save: UIButton!
    @IBAction func saveToSpotify(_ sender: Any) {
        print("moodify pressed")

            // Fetch Spotify User ID
            fetchSpotifyUserID() { [weak self] userID in
                guard let self = self, let userID = userID else {
                    print("Failed to fetch Spotify User ID")
                    return
                }
                self.userId = userID
                print("Spotify User ID: \(userID)")

                // Create a Playlist
                let localTime = getCurrentLocalTime()
                self.createPlaylist(playlistName: "Moodify \(localTime)") { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let playlistID):
                            print("Playlist created successfully with ID: \(playlistID)")
                            self.playlistId = playlistID

                            // Add Tracks to the Playlist (using self.trackURIs)
                            self.addTracksToPlaylist() { success in
                                if success {
                                    print("Tracks added successfully to the playlist")
                                    // Update UI or perform further actions as needed
                                } else {
                                    print("Failed to add tracks to the playlist")
                                    // Handle error case, possibly show a user-facing error message
                                }
                            }

                        case .failure(let error):
                            print("Failed to create playlist: \(error.localizedDescription)")
                            // Handle the error case, e.g., show an alert to the user
                        }
                    }
                }
            }
            let alert = UIAlertController(title: "Playlist Added", message: "This Mood has been added to Spotify", preferredStyle: .alert)
                   alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                   self.present(alert, animated: true)
        }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Received data: \(playlist)")
        // Do any additional setup after loading the view.
        playlistTable.dataSource = self
        playlistTable.delegate = self
        playlistTable.reloadData()
        view.bringSubviewToFront(save)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackCell", for: indexPath)
        let trackInfo = playlist[indexPath.row]
        cell.textLabel?.text = trackInfo["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete{
            playlist.remove(at: indexPath.row)
            trackURIs.remove(at:indexPath.row)
        }
        playlistTable.reloadData()
    }
    
    func fetchSpotifyUserID( completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(self.accessToken!)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let userID = json["id"] as? String {
                completion(userID)
                print(userID)
                self.userId = userID
            } else {
                print("Failed to parse JSON response")
                completion(nil)
            }
        }
        task.resume()
    }
    
    func createPlaylist(playlistName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/users/\(self.userId!)/playlists")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(self.accessToken!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let playlistDetails = [
            "name": playlistName,
            "description": "Created via API",
            "public": false // Change to true if you want it public
        ] as [String : Any]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: playlistDetails, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? NSError(domain: "Unknown Error", code: 0, userInfo: nil)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let playlistID = jsonResponse["id"] as? String {
                        completion(.success(playlistID))
                        self.playlistId = playlistID
                    } else {
                        completion(.failure(NSError(domain: "JSON Parsing Error", code: 0, userInfo: nil)))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(NSError(domain: "API Error", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: nil)))
            }
        }
        task.resume()
    }
    
    func addTracksToPlaylist( completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/playlists/\(self.playlistId!)/tracks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(self.accessToken!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["uris": self.trackURIs]
        print(self.trackURIs)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error: Cannot create JSON payload")
            completion(false)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error adding tracks to playlist: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("Tracks added successfully.")
                completion(true)
            } else {
                print("Failed to add tracks to playlist. Status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                completion(false)
            }
        }
        task.resume()
    }
}
