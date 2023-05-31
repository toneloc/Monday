//
//  SendConfirmationViewModel.swift
//  LDKNodeMonday
//
//  Created by Matthew Ramsden on 5/29/23.
//

import SwiftUI
import LightningDevKitNode

class SendConfirmationViewModel: ObservableObject {
    @Published var nodeError: MondayError?
    @Published var invoice: String = ""
    @Published var networkColor = Color.gray
    @Published var paymentHash: PaymentHash?
    
    init(invoice: String) {
        self.invoice = invoice
    }
    
    func sendPayment(invoice: Invoice) async  {
        do {
            let paymentHash = try await LightningNodeService.shared.sendPayment(invoice: invoice)
            DispatchQueue.main.async {
                self.paymentHash = paymentHash
            }
        } catch let error as NodeError {
            let errorString = handleNodeError(error)
            DispatchQueue.main.async {
                self.nodeError = .init(title: errorString.title, detail: errorString.detail)
            }
        } catch {
            DispatchQueue.main.async {
                self.nodeError = .init(title: "Unexpected error", detail: error.localizedDescription)
            }
        }
    }
    
    func getColor() {
        let color = LightningNodeService.shared.networkColor
        DispatchQueue.main.async {
            self.networkColor = color
        }
    }
    
}