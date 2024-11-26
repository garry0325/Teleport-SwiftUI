//
//  Extension.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/7.
//

import Foundation
import UIKit
import MapKit

extension UIImage {
    func nonBlackPixelStartingAt() -> Int? {
        for y in (0..<Int(size.height)).reversed() {
            if let color = getRgbofPixelAt(x: 0, y: y) {
                if !(color.r == 0 && color.g == 0 && color.b == 0) {
                    return y
                }
            }
        }
        
        return nil
    }
    
    func getRgbofPixelAt(x: Int, y: Int) -> (r: UInt8, g: UInt8, b: UInt8)? {
        guard let cgImage = cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
                return nil
            }
        if cgImage.colorSpace?.model != .rgb { return nil }
        
        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
        let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
        let rgb = (r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2])
        return rgb
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && rhs.longitude == rhs.longitude
    }
}
