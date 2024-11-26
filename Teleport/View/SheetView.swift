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
    @Binding var sheetViewLocation: CLLocationCoordinate2D?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading) {
                    ForEach(locationService.searchResults.reversed()) { result in
                        VStack(alignment: .leading) {
                            Text(result.title)
                                .fontWeight(.medium)
                                .font(.system(size: 15))
                            Text(result.subtitle)
                                .fontWeight(.regular)
                                .font(.system(size: 10))
                            Divider()
                        }
                        .onTapGesture {
                            search(result: result, keyword: keyword)
                        }
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            .frame(minWidth: 200, maxHeight: 400)
            Spacer()
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a place", text: $keyword)
                    .autocorrectionDisabled()
                    .onChange(of: keyword) {
                        locationService.updateSearchResults(queryString: keyword)
                    }
                    .onSubmit {
                        search(keyword: keyword)
                    }
                Image(systemName: "x.circle.fill")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
        .padding()
    }
    
    func search(result: SearchResult? = nil, keyword: String) {
        Task {
            sheetViewLocation = await locationService.search(searchResult: result, keyword: keyword)
            if sheetViewLocation != nil {
                dismiss()
            }
        }
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
}
