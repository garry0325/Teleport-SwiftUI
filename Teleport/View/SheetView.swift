//
//  SheetView.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/10.
//

import SwiftUI
import MapKit

struct SheetView: View {
    @EnvironmentObject var locationService: LocationService
    @State private var keyword: String = ""
    @State var sheetHeight: CGFloat = 250
    @Binding var sheetViewLocation: CLLocationCoordinate2D?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextField("Search...", text: $keyword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocorrectionDisabled()
                .onChange(of: keyword) {
                    locationService.updateSearchResults(queryString: keyword)
                }
                .onSubmit {
                    search(keyword: keyword)
                }
            List(locationService.searchResults) { result in
                VStack(alignment: .leading) {
                    Text(result.title)
                        .fontWeight(.medium)
                        .font(.system(size: 15))
                    Text(result.subtitle)
                        .fontWeight(.regular)
                        .font(.system(size: 10))
                }
                .onTapGesture {
                    search(result: result, keyword: keyword)
                }
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "x.circle")
            }
        }
        .frame(width: 300, height: sheetHeight)
        .padding(.bottom, 10)
        .animation(.easeInOut, value: sheetHeight)
        .onChange(of: locationService.searchResults.count) {
            adjustHeight()
        }
        .onAppear {
            adjustHeight()
        }
    }
    
    func search(result: SearchResult? = nil, keyword: String) {
        Task {
            sheetViewLocation = await locationService.search(searchResult: result, keyword: keyword)
            if sheetViewLocation != nil {
                dismiss()
            }
        }
    }
    
    private func adjustHeight() {
        let baseHeight: CGFloat = 200 // Minimum height
        let rowHeight: CGFloat = 44 // Approximate height per row in a list
        let maxVisibleRows = 5 // Maximum number of visible rows
        let calculatedHeight = baseHeight + min(CGFloat(locationService.searchResults.count), CGFloat(maxVisibleRows)) * rowHeight
        
        sheetHeight = min(calculatedHeight, baseHeight + CGFloat(maxVisibleRows) * rowHeight)
    }
}

struct TextFieldGrayBackgroundColor: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}

#Preview {
    SheetView(sheetViewLocation: .constant(CLLocationCoordinate2D(latitude: 37, longitude: -120)))
        .environmentObject(LocationService(completer: MKLocalSearchCompleter()))
}
