//
//  TeleportApp.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/6.
//

import SwiftUI
import CoreLocation
import MapKit

@main
struct TeleportApp: App {
    @StateObject var streetViewComposer = StreetViewComposer()
    @StateObject var locationService = LocationService(completer: MKLocalSearchCompleter())
    
    var body: some Scene {
        WindowGroup("somethingelse") {
            TeleportView()
                .environmentObject(streetViewComposer)
                .environmentObject(locationService)
        }
        
        ImmersiveSpace(id: "StreetView") {
            EnvironmentView(realityViewEntity: $streetViewComposer.realityViewEntity)
        }
    }
}
