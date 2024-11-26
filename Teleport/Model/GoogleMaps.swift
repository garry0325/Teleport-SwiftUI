//
//  GoogleMaps.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/7.
//

import Foundation
import UIKit
import CoreLocation

struct GoogleMaps {
    static let apiUrlString = "https://maps.googleapis.com/maps/api/streetview/"
    private static var apiKey: String {
        guard let infoUrl = Bundle.main.url(forResource: "Info", withExtension: "plist") else {
            print("GoogleMaps.apiKey: Cannot read Info.plist")
            return ""
        }
        guard let apiKey = try? NSDictionary(contentsOf: infoUrl, error: ()).value(forKey: "Google Maps API Key") as? String else {
            print("GoogleMaps.apiKey: Cannot get API key in Info.plist")
            return ""
        }
        return apiKey
    }
    static let panoRadius = 2000
    
    static func getStreetViewMetadata(fromCoordinates coordinates: CLLocationCoordinate2D) throws -> StreetViewMetadata {
        // Generating url to download
        guard let metadataUrl = URL(string: GoogleMaps.apiUrlString)?.appending(path: "metadata") else {
            throw GoogleMapsError.URLError("Error generating metadataUrl")
        }
        let urlQueries: [URLQueryItem] = [
            URLQueryItem(name: "location", value: String(format: "%@,%@", coordinates.latitude.description, coordinates.longitude.description)),
            URLQueryItem(name: "radius", value: GoogleMaps.panoRadius.description),
            URLQueryItem(name: "source", value: "outdoor"),
            URLQueryItem(name: "key", value: GoogleMaps.apiKey)
        ]
        let panoramaIdUrl = metadataUrl.appending(queryItems: urlQueries)
        print(panoramaIdUrl.absoluteString)
        
        // Downloading data
        guard let panoramaData = try? Data(contentsOf: panoramaIdUrl) else {
            throw GoogleMapsError.DataError("Error downloading data")
        }
        
        // Reading data
        return StreetViewMetadata(data: panoramaData)
    }
}

enum GoogleMapsError: Error {
    case URLError(String)
    case DataError(String)
}

struct StreetViewMetadata {
    var date: Date?
    var pano_id: String?
    var location: CLLocation?
    let status: StatusCode
    
    init(data: Data) {
        guard let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Error converting street view metadata to dictionary")
            self.status = .DataError
            return
        }
        
        // Getting the response code
        guard let status = jsonData["status"] as? String else {
            self.status = .DataError
            return
        }
        switch status {
        case "OK":
            self.status = .OK
        case "ZERO_RESULTS":
            self.status = .ZERO_RESULTS
        case "NOT_FOUND":
            self.status = .NOT_FOUND
        case "OVER_QUERY_LIMIT":
            self.status = .OVER_QUERY_LIMIT
        case "REQUEST_DENIED":
            self.status = .REQUEST_DENIED
        case "INVALID_REQUEST":
            self.status = .INVALID_REQUEST
        case "UNKNOWN_ERROR":
            self.status = .UNKNOWN_ERROR
        default:
            self.status = .UNKNOWN_ERROR
        }
        
        // Getting the date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        self.date = dateFormatter.date(from: jsonData["date"] as? String ?? "")
        
        // Getting the coordinates
        if let locationData = jsonData["location"] as? [String: Double] {
            if let latitude = locationData["lat"], let longitude = locationData["lng"] {
                self.location = CLLocation(latitude: latitude, longitude: longitude)
            }
        }
        
        // Getting the pano_id
        if let pano_id = jsonData["pano_id"] as? String {
            self.pano_id = pano_id
        }
    }
    
    enum StatusCode {
        case OK
        case ZERO_RESULTS
        case NOT_FOUND
        case OVER_QUERY_LIMIT
        case REQUEST_DENIED
        case INVALID_REQUEST
        case UNKNOWN_ERROR
        case DataError
    }
}
