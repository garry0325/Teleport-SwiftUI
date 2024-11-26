//
//  EnvironmentView.swift
//  Teleport
//
//  Created by Garry Sinica on 2024/9/7.
//

import SwiftUI
import RealityKit

struct EnvironmentView: View {
    @Binding var realityViewEntity: Entity
    
    var body: some View {
        RealityView { content in
            content.add(realityViewEntity)
        }
    }
}
