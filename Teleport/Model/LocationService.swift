//
//  LocationService.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/10.
//

import Foundation
import MapKit

class LocationService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate, Identifiable {
    private var completer: MKLocalSearchCompleter
    
    @Published var searchResults: [SearchResult] = []
    @Published var searchMapItem: MKMapItem?
    
    init(completer: MKLocalSearchCompleter) {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.completer.resultTypes = [.address, .pointOfInterest, .query]
    }
    
    func updateSearchResults(queryString: String) {
        completer.queryFragment = queryString
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results.map { result in
            return SearchResult(title: result.title, subtitle: result.subtitle)
        }
    }
    
    func search(searchResult: SearchResult? = nil, keyword: String) async -> CLLocationCoordinate2D? {
        print("Searching...")
        var searchKeyword = ""
        if let searchResult = searchResult {
            searchKeyword = "\(searchResult.title) \(searchResult.subtitle)"
        } else if let firstSearchResult = searchResults.first {
            searchKeyword = "\(firstSearchResult.title) \(firstSearchResult.subtitle)"
        } else {
            searchKeyword = keyword
        }
        
        print("Keyword: \(searchKeyword)")
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchKeyword
        
        let search = MKLocalSearch(request: searchRequest)
        do {
            let response = try await search.start()
            
            guard let firstMapItem = response.mapItems.first else {
                return nil
            }
            
            print("Found: \(firstMapItem.placemark.coordinate)")
            DispatchQueue.main.async {
                self.searchMapItem = firstMapItem
            }
        } catch {
            return nil
        }
        
        return self.searchMapItem?.placemark.coordinate
    }
    
    func getPlacemarkFromCoordinates(coordinates: CLLocationCoordinate2D) async -> CLPlacemark? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        do {
            let placemark = try await geocoder.reverseGeocodeLocation(location)
            return placemark.first
        } catch {
            return nil
        }
    }
}

class SearchResult: Identifiable {
    var title: String
    var subtitle: String
    
    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}
