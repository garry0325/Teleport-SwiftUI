//
//  StreetViewComposer.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/7.
//

import Foundation
import UIKit
import RealityKit
import CoreLocation

class StreetViewComposer: ObservableObject {
    @Published var isDownloading: Bool = false
    let tileUrlString = "https://streetviewpixels-pa.googleapis.com/v1/tile"
    let defaultTileUrlQueries: [URLQueryItem] = [
        URLQueryItem(name: "cb_client", value: "maps_sv.tactile"),
        URLQueryItem(name: "nbt", value: "1")
    ]
    
    var realityViewEntity: Entity = Entity()
    var equirectangularImage: UIImage?
    var streetViewMetadata: StreetViewMetadata?
    
    let zoom = 4
    var xMax: Int {
        switch zoom {
        case 3:
            return 8
        case 4:
            return 16
        case 5:
            return 32
        default:
            return 8
        }
    }
    var yMax: Int {
        switch zoom {
        case 3:
            return 4
        case 4:
            return 8
        case 5:
            return 16
        default:
            return 4
        }
    }
    
    init() {
        realityViewEntity.components.set(ModelComponent(mesh: .generateSphere(radius: 100), materials: [UnlitMaterial()]))
        realityViewEntity.scale *= .init(x: -1, y: 1, z: 1)
    }
    
    func composeStreetView(coordinates: CLLocationCoordinate2D) async -> Bool {
        DispatchQueue.main.async {
            self.isDownloading = true
        }
        print("Is Downloading")

        defer {
            DispatchQueue.main.async {
                self.isDownloading = false
            }
        }
        
        do {
            self.streetViewMetadata = try GoogleMaps.getStreetViewMetadata(fromCoordinates: coordinates)
        } catch {
            print(error)
            return false
        }
        
        if await !generateEquirectangularImage() { return false }
        await generateRealityViewEntity()
        DispatchQueue.main.async {
            self.isDownloading = false
        }
        
        print("Downloaded")
        return true
    }
    
    private func generateEquirectangularImage() async -> Bool {
        guard let panoramaId = streetViewMetadata?.pano_id else {
            print("No pano_id found")
            return false
        }
        
        let tileUrlQueries = defaultTileUrlQueries +
            [URLQueryItem(name: "panoid", value: panoramaId),
            URLQueryItem(name: "zoom", value: zoom.description)]
        
        guard let tileUrlWithDefaultQueries = URL(string: tileUrlString)?.appending(queryItems: tileUrlQueries) else {
            print("Error generating tile url")
            return false
        }
        
        var tiles = [Tile]()
        
        for y in 0..<yMax {
            for x in 0..<xMax {
                let tileUrl = tileUrlWithDefaultQueries.appending(queryItems: [
                    URLQueryItem(name: "x", value: x.description),
                    URLQueryItem(name: "y", value: y.description)
                ])
                let tile = Tile(x: x, y: y, url: tileUrl)
                tiles.append(tile)
            }
        }
        
        var streetImageTiles: [[UIImage?]] = Array(repeating: Array(repeating: nil, count: yMax), count: xMax)
        var tileHasError: Bool = false
        do {
            try await withThrowingTaskGroup(of: Tile.self) { group in
                for tile in tiles {
                    group.addTask {
                        let image = self.downloadTile(from: tile.url)
                        tile.image = image
                        return tile
                    }
                }
                
                for try await tile in group {
                    if let image = tile.image {
                        streetImageTiles[tile.x][tile.y] = image
                    } else {
                        tileHasError = true
                    }
                }
            }
        } catch {
            print(error)
        }
        
        guard let sampleTileImage = streetImageTiles[0][0] else { return false }
        let tileSize = sampleTileImage.size
        var mergedSize = CGSize(width: tileSize.width * CGFloat(xMax), height: tileSize.height * CGFloat(yMax))
        
        if tileHasError {
            for y in (0..<yMax).reversed() {
                if let nonBlackY = streetImageTiles[0][y]?.nonBlackPixelStartingAt() {
                    mergedSize.height = CGFloat(y) * tileSize.height + CGFloat(nonBlackY)
                    mergedSize.width = 2 * mergedSize.height
                    break
                }
            }
        }
        
        let renderer = UIGraphicsImageRenderer(size: mergedSize)
        let mergedImage = renderer.image { context in
            for x in 0..<xMax {
                for y in 0..<yMax {
                    streetImageTiles[x][y]?.draw(at: CGPoint(x: CGFloat(x) * tileSize.width, y: CGFloat(y) * tileSize.height))
                }
            }
        }
        
        self.equirectangularImage = mergedImage
        return true
    }
    
    private func downloadTile(from url: URL) -> UIImage? {
        do {
            let tileData = try Data(contentsOf: url)
            return UIImage(data: tileData)
        } catch {
            return nil
        }
    }
    
    private func generateRealityViewEntity() async {
        guard let equirectangularCGImage = equirectangularImage?.cgImage else { return }
        guard let textureResource = try? await TextureResource.generate(from: equirectangularCGImage, options: TextureResource.CreateOptions.init(semantic: .color)) else { return }
        
        var material = UnlitMaterial()
        material.color = .init(texture: .init(textureResource))
        
        await realityViewEntity.components.set(ModelComponent(
            mesh: .generateSphere(radius: 100),
            materials: [material]
        ))
    }
}

class Tile {
    let x: Int
    let y: Int
    let url: URL
    var image: UIImage?
    
    init(x: Int, y: Int, url: URL, image: UIImage? = nil) {
        self.x = x
        self.y = y
        self.url = url
        self.image = image
    }
}
