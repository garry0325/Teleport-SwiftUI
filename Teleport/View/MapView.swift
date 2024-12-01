//
//  MapView.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/6.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: StartingLocation, span: StartingSpan))
    @Binding var isSheetPresented: Bool
    @Binding var droppedPinLocation: CLLocationCoordinate2D?
    @Binding var sheetViewLocation: CLLocationCoordinate2D?
    
    var body: some View {
        MapReader { mapProxy in
            Map(position: $mapCameraPosition, interactionModes: [.pan, .pitch, .zoom]) {
                if let droppedPinLocation = droppedPinLocation {
                    Marker(coordinate: droppedPinLocation) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.yellow)
                            Image(systemName: "figure.walk.motion")
                                .foregroundStyle(.regularMaterial)
                                .padding(5)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 35))
            .onTapGesture { tappedLocation in
                print("tapped on map")
                droppedPinLocation = mapProxy.convert(tappedLocation, from: .local)
                print(droppedPinLocation ?? "")
            }
            .onChange(of: sheetViewLocation) {
                updateMapPosition()
            }
        }
    }
    
    func updateMapPosition() {
        if let sheetViewLocation = sheetViewLocation {
            mapCameraPosition = .region(MKCoordinateRegion(center: sheetViewLocation, span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)))
            droppedPinLocation = sheetViewLocation
        }
    }
}

#Preview {
    MapView(isSheetPresented: .constant(false), droppedPinLocation: .constant(CLLocationCoordinate2D(latitude: 37, longitude: -120)), sheetViewLocation: .constant(CLLocationCoordinate2D(latitude: 40, longitude: -110)))
}

#if DEBUG
let StartingLocation = CLLocationCoordinate2D(latitude: 59.912005, longitude: 10.751368)
let StartingSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
#else
let StartingLocation = CLLocationCoordinate2D(latitude: 23.5, longitude: 150)
let StartingSpan = MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
#endif

