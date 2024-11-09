//
//  ChannelCloseViewModel.swift
//  LDKNodeMonday
//
//  Created by Matthew Ramsden on 5/29/23.
//

import LDKNode
import SwiftUI

class ChannelDetailViewModel: ObservableObject {
    @Published var channel: ChannelDetails
    @Published var channelDetailViewError: MondayError?
    @Published var networkColor = Color.gray

    init(channel: ChannelDetails) {
        self.channel = channel
    }
    
    func close() {
        Task {
            do {
                try await LightningNodeService.shared.checkStability(stableChannelId: "72104b95608f433751d6070ecb9c9ade30746d7733d4fa901e9068d6f2384f7d", expectedDollarAmount: 155)
            } catch {
                print("Failed to check stability: \(error)")
            }
        }
    }

//    func close() {
//        do {
//            try LightningNodeService.shared.closeChannel(
//                userChannelId: self.channel.userChannelId,
//                counterpartyNodeId: self.channel.counterpartyNodeId
//            )
//            channelDetailViewError = nil
//        } catch let error as NodeError {
//            let errorString = handleNodeError(error)
//            DispatchQueue.main.async {
//                self.channelDetailViewError = .init(
//                    title: errorString.title,
//                    detail: errorString.detail
//                )
//            }
//        } catch {
//            DispatchQueue.main.async {
//                self.channelDetailViewError = .init(
//                    title: "Unexpected error",
//                    detail: error.localizedDescription
//                )
//            }
//        }
//    }

    func getColor() {
        let color = LightningNodeService.shared.networkColor
        DispatchQueue.main.async {
            self.networkColor = color
        }
    }

}
