//
//  TeleportView.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/6.
//

import SwiftUI
import RealityKit
import RealityKitContent
import MapKit

struct TeleportView: View {
    @State var droppedPinLocation: CLLocationCoordinate2D?
    @State var droppedPlacemark: CLPlacemark?
    @State var sheetViewLocation: CLLocationCoordinate2D?
    @EnvironmentObject var streetViewComposer: StreetViewComposer
    @EnvironmentObject var locationService: LocationService
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State var isShowingImmersiveSpace: Bool = false
    @State var isSheetPresented: Bool = false
    @State var noErrorWithStreetView: Bool = true
    
    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(isSheetPresented: $isSheetPresented, droppedPinLocation: $droppedPinLocation, sheetViewLocation: $sheetViewLocation)
            
            HStack(alignment: .bottom) {
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    let placemarkProperties: [String] = [
                        droppedPlacemark?.name ?? "",
                        droppedPlacemark?.locality ?? "",
                        droppedPlacemark?.administrativeArea ?? "",
                        droppedPlacemark?.country ?? "",
                        droppedPlacemark?.postalCode ?? ""
                    ]
                    ForEach(placemarkProperties, id: \.self) { property in
                        Text(property)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(30)
            }
            
            VStack {
                VStack {
                    Spacer()
                }
                
                if !noErrorWithStreetView {
                    Text("Error getting street view, or no street view nearby.")
                        .font(.headline)
                }
                
                HStack(alignment: .center) {
                    Button {
                        isSheetPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Button {
                        guard let droppedPinLocation = droppedPinLocation else { return }
                        Task {
                            noErrorWithStreetView = await streetViewComposer.composeStreetView(coordinates: droppedPinLocation)
                            if noErrorWithStreetView {
                                if !isShowingImmersiveSpace {
                                    await openImmersiveSpace(id: "StreetView")
                                }
                                isShowingImmersiveSpace = true
                            } else {
                                if isShowingImmersiveSpace {
                                    await dismissImmersiveSpace()
                                    isShowingImmersiveSpace = false
                                }
                            }
                        }
                    } label: {
                        if streetViewComposer.isDownloading {
                            ProgressView()
                        } else {
                            Image(systemName: "figure.walk.motion")
                        }
                        
                    }
                    .disabled(droppedPinLocation == nil)
                    
                    Button {
                        Task {
                            await dismissImmersiveSpace()
                            isShowingImmersiveSpace = false
                        }
                    } label: {
                        Image(systemName: "house")
                    }
                }
                .padding()
            }
            
        }
        .sheet(isPresented: $isSheetPresented) {
            SheetView(sheetViewLocation: $sheetViewLocation)
                .presentationBackground(.ultraThinMaterial)
                .presentationDetents([.height(60), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
                .environmentObject(locationService)
        }
        .padding()
        .onChange(of: droppedPinLocation) { oldValue, newValue in
            noErrorWithStreetView = true
            guard let droppedPinLocation = droppedPinLocation else { return }
            Task {
                droppedPlacemark = await locationService.getPlacemarkFromCoordinates(coordinates: droppedPinLocation)
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    TeleportView()
        .environmentObject(StreetViewComposer())
        .environmentObject(LocationService(completer: MKLocalSearchCompleter()))
}
