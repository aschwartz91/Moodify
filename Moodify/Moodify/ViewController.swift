//
//  ViewController.swift
//  Moodify
//
//  Created by Adam Schwartz on 11/1/23.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - Spotify Authorization & Configuration
    var responseCode: String? {
        didSet {
            fetchAccessToken { (dictionary, error) in
                if let error = error {
                    print("Fetching token request error \(error)")
                    return
                }
                let accessToken = dictionary!["access_token"] as! String
                self.accessToken = accessToken
                DispatchQueue.main.async {
                    self.appRemote.connectionParameters.accessToken = accessToken
                    self.appRemote.connect()
                }
            }
        }
    }

    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()

    var accessToken = UserDefaults.standard.string(forKey: accessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: accessTokenKey)
        }
    }

    lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: spotifyClientId, redirectURL: redirectUri)
        configuration.playURI = nil
        configuration.tokenSwapURL = URL(string: "http://localhost:1234/swap")
        configuration.tokenRefreshURL = URL(string: "http://localhost:1234/refresh")
        return configuration
    }()

    lazy var sessionManager: SPTSessionManager? = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        print("Session manager created and delegate assigned")
        print(manager)
        return manager
    }()


    private var lastPlayerState: SPTAppRemotePlayerState?


    // MARK: App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()


    }


    // MARK: - Actions
    
    @IBAction func didTapConnect(_ sender: Any) {
        print("did tap connect")
        guard let sessionManager = sessionManager else {
            print("failed did tap connect")
            return }
        sessionManager.initiateSession(with: scopes, options: .clientOnly)
        print("session manager initiated")
        
    }

    private func presentAlertController(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            controller.addAction(action)
            self.present(controller, animated: true)
        }
    }
    
    func fetchRecommendations(genre: String, targetPopularity: Int, minDurationMs: Int, completion: @escaping ([String: Any]?, Error?) -> Void) {
        print("recommendations")
        print(self.accessToken!)
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
                    var recommendations: [[String: String]] = []

                    // Extracting details from each track
                    for track in tracks {
                        var trackDetails: [String: String] = [:]

                        // Extracting track name
                        if let name = track["name"] as? String {
                            trackDetails["name"] = name
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

                        recommendations.append(trackDetails)
                    }

                    // Printing the recommendations with details
                    for recommendation in recommendations {
                        print("Track: \(recommendation["name"] ?? "N/A"), Artist: \(recommendation["artist"] ?? "N/A"), Artwork URL: \(recommendation["artworkUrl"] ?? "N/A")")
                    }
                    
                } else {
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    

}



// MARK: - SPTAppRemoteDelegate
extension ViewController: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
            }
        })
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {

        lastPlayerState = nil
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {

        lastPlayerState = nil
    }
}

// MARK: - SPTAppRemotePlayerAPIDelegate
extension ViewController: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        debugPrint("Spotify Track name: %@", playerState.track.name)
    }
}

// MARK: - SPTSessionManagerDelegate
extension ViewController: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("failed")
        if error.localizedDescription == "The operation couldn’t be completed. (com.spotify.sdk.login error 1.)" {
            print("AUTHENTICATE with WEBAPI")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let secondVC = storyboard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
                secondVC.modalPresentationStyle = .fullScreen
                self.present(secondVC, animated: true, completion: nil)
        } else {
            print("AUTHENTICATE failed")
        }
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("Session Renewed")
        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("initiated")
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
        print("before reached")
        self.performSegue(withIdentifier: "testSegue", sender: self)
        print("after reached")
    }
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {

        print("Opened url")
        guard let url = URLContexts.first?.url else {
            return
        }
        sessionManager?.application(UIApplication.shared, open: url, options: [:])
    }
    
}

// MARK: - Networking
extension ViewController {

    func fetchAccessToken(completion: @escaping ([String: Any]?, Error?) -> Void) {
        print("fetch access token")
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let spotifyAuthKey = "Basic \((spotifyClientId + ":" + spotifyClientSecretKey).data(using: .utf8)!.base64EncodedString())"
        request.allHTTPHeaderFields = ["Authorization": spotifyAuthKey,
                                       "Content-Type": "application/x-www-form-urlencoded"]

        var requestBodyComponents = URLComponents()
        let scopeAsString = stringScopes.joined(separator: " ")

        requestBodyComponents.queryItems = [
            URLQueryItem(name: "client_id", value: spotifyClientId),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: responseCode!),
            URLQueryItem(name: "redirect_uri", value: redirectUri.absoluteString),
            URLQueryItem(name: "code_verifier", value: ""), // not currently used
            URLQueryItem(name: "scope", value: scopeAsString),
        ]

        request.httpBody = requestBodyComponents.query?.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,                              // is there data
                  let response = response as? HTTPURLResponse,  // is there HTTP response
                  (200 ..< 300) ~= response.statusCode,         // is statusCode 2XX
                  error == nil else {                           // was there no error, otherwise ...
                      print("Error fetching token \(error?.localizedDescription ?? "")")
                      return completion(nil, error)
                  }
            let responseObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let accessToken = responseObject?["access_token"] as? String {
                        print("Successfully fetched access token: \(accessToken)")
                    } else {
                        print("Failed to fetch access token.")
                    }
            print("Access Token Dictionary=", responseObject ?? "")
            completion(responseObject, nil)
        }
        task.resume()
    }

}
