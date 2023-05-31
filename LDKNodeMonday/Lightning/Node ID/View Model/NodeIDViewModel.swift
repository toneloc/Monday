//
//  NodeIDViewModel.swift
//  LDKNodeMonday
//
//  Created by Matthew Ramsden on 5/29/23.
//

import SwiftUI
import WalletUI

class NodeIDViewModel: ObservableObject {
    @Published var nodeError: MondayError?
    @Published var networkColor = Color.gray
    @Published var nodeID: String = ""
    
    func getNodeID() {
        let nodeID = LightningNodeService.shared.nodeId()
        self.nodeID = nodeID
    }
    
    func getColor() {
        let color = LightningNodeService.shared.networkColor
        DispatchQueue.main.async {
            self.networkColor = color
        }
    }
    
}