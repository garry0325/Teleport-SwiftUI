//
//  Global.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/12/1.
//

import Foundation

#if DEBUG
// In Debug builds, use the standard `print`
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    Swift.print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
}
#else
// In Release builds, redefine `print` to do nothing
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // No-op
}
#endif
