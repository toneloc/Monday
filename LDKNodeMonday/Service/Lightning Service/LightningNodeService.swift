//
//  LightningNodeService.swift
//  LDKNodeMonday
//
//  Created by Matthew Ramsden on 2/20/23.
//

import Foundation
import LDKNode
import SwiftUI
import os

class LightningNodeService {
    static var shared: LightningNodeService = LightningNodeService()
    private let ldkNode: LdkNode
    private let storageManager = LightningStorage()
    private let keyService: KeyClient
    var networkColor = Color.black
    var network: Network

    init(
        keyService: KeyClient = .live
    ) {

        let storedNetworkString = try! keyService.getNetwork() ?? Network.testnet.description
        let storedEsploraURL =
            try! keyService.getEsploraURL()
            ?? Constants.Config.EsploraServerURLNetwork.Testnet.testnet_mempoolspace

        self.network = Network(stringValue: storedNetworkString) ?? .testnet
        self.keyService = keyService

        let config = Config(
            storageDirPath: storageManager.getDocumentsDirectory(),
            network: network,
            listeningAddresses: ["0.0.0.0:9735"],
            defaultCltvExpiryDelta: UInt32(144),
            onchainWalletSyncIntervalSecs: UInt64(60),
            walletSyncIntervalSecs: UInt64(20),
            feeRateCacheUpdateIntervalSecs: UInt64(600),
            logLevel: .trace
        )

        let nodeBuilder = Builder.fromConfig(config: config)
        nodeBuilder.setEsploraServer(esploraServerUrl: storedEsploraURL)

        switch self.network {
        case .bitcoin:
            nodeBuilder.setGossipSourceRgs(
                rgsServerUrl: Constants.Config.RGSServerURLNetwork.bitcoin
            )
            self.networkColor = Constants.BitcoinNetworkColor.bitcoin.color
        case .testnet:
            nodeBuilder.setGossipSourceRgs(
                rgsServerUrl: Constants.Config.RGSServerURLNetwork.testnet
            )
            self.networkColor = Constants.BitcoinNetworkColor.testnet.color
        case .signet:
            self.networkColor = Constants.BitcoinNetworkColor.signet.color
        case .regtest:
            self.networkColor = Constants.BitcoinNetworkColor.regtest.color
        }

        let mnemonic: String
        do {
            let backupInfo = try keyService.getBackupInfo()
            if backupInfo.mnemonic == "" {
                let newMnemonic = generateEntropyMnemonic()
                let backupInfo = BackupInfo(mnemonic: newMnemonic)
                try? keyService.saveBackupInfo(backupInfo)
                mnemonic = newMnemonic
            } else {
                mnemonic = backupInfo.mnemonic
            }
        } catch {
            let newMnemonic = generateEntropyMnemonic()
            let backupInfo = BackupInfo(mnemonic: newMnemonic)
            try? keyService.saveBackupInfo(backupInfo)
            mnemonic = newMnemonic
        }
        nodeBuilder.setEntropyBip39Mnemonic(mnemonic: mnemonic, passphrase: nil)

        // TODO: -!
        /// 06.22.23
        /// Breaking change in ldk-node 0.1 today
        /// `build` now `throws`
        /// - Resolve by actually handling error
        let ldkNode = try! nodeBuilder.build()
        self.ldkNode = ldkNode
    }

    func start() async throws {
        try ldkNode.start()
    }

    func stop() throws {
        try ldkNode.stop()
    }

    func nodeId() -> String {
        let nodeID = ldkNode.nodeId()
        return nodeID
    }

    func newOnchainAddress() async throws -> String {
        let fundingAddress = try ldkNode.newOnchainAddress()
        return fundingAddress
    }

    func spendableOnchainBalanceSats() async throws -> UInt64 {
        let startTime = Date()
        Logger.log("spendableOnchainBalanceSats started at: \(startTime)")
        let balance = try ldkNode.spendableOnchainBalanceSats()
        let endTime = Date()
        Logger.log("spendableOnchainBalanceSats ended at: \(startTime)")
        Logger.log(
            "Time taken for spendableOnchainBalanceSats: \(endTime.timeIntervalSince(startTime)) seconds"
        )
        return balance
    }

    func totalOnchainBalanceSats() async throws -> UInt64 {
        let startTime = Date()
        Logger.log("totalOnchainBalanceSats started at: \(startTime)")
        let balance = try ldkNode.totalOnchainBalanceSats()
        let endTime = Date()
        Logger.log("totalOnchainBalanceSats ended at: \(startTime)")
        Logger.log(
            "Time taken for totalOnchainBalanceSats: \(endTime.timeIntervalSince(startTime)) seconds"
        )
        return balance
    }

    func connect(nodeId: PublicKey, address: String, persist: Bool) async throws {
        try ldkNode.connect(
            nodeId: nodeId,
            address: address,
            persist: persist
        )
    }

    func disconnect(nodeId: PublicKey) throws {
        try ldkNode.disconnect(nodeId: nodeId)
    }

    func connectOpenChannel(
        nodeId: PublicKey,
        address: String,
        channelAmountSats: UInt64,
        pushToCounterpartyMsat: UInt64?,
        channelConfig: ChannelConfig?,
        announceChannel: Bool = true
    ) async throws {
        try ldkNode.connectOpenChannel(
            nodeId: nodeId,
            address: address,
            channelAmountSats: channelAmountSats,
            pushToCounterpartyMsat: pushToCounterpartyMsat,
            channelConfig: nil,
            announceChannel: false
        )
    }

    func closeChannel(channelId: ChannelId, counterpartyNodeId: PublicKey) throws {
        try ldkNode.closeChannel(channelId: channelId, counterpartyNodeId: counterpartyNodeId)
    }

    func sendPayment(invoice: Bolt11Invoice) async throws -> PaymentHash {
        let paymentHash = try ldkNode.sendPayment(invoice: invoice)
        return paymentHash
    }

    func receivePayment(amountMsat: UInt64, description: String, expirySecs: UInt32) async throws
        -> Bolt11Invoice
    {
        let invoice = try ldkNode.receivePayment(
            amountMsat: amountMsat,
            description: description,
            expirySecs: expirySecs
        )
        return invoice
    }

    func listPeers() -> [PeerDetails] {
        let peers = ldkNode.listPeers()
        return peers
    }

    func listChannels() -> [ChannelDetails] {
        let channels = ldkNode.listChannels()
        return channels
    }

    func sendAllToOnchainAddress(address: Address) async throws -> Txid {
        let txId = try ldkNode.sendAllToOnchainAddress(address: address)
        return txId
    }

    func listPayments() -> [PaymentDetails] {
        let payments = ldkNode.listPayments()
        return payments
    }

}

// Danger Zone
extension LightningNodeService {
    func deleteWallet() throws {
        try keyService.deleteBackupInfo()
    }
    func getBackupInfo() throws -> BackupInfo {
        let backupInfo = try keyService.getBackupInfo()
        return backupInfo
    }
}

// Event Handling
extension LightningNodeService {
    func listenForEvents() {
        Task {
            while true {
                if let event = ldkNode.nextEvent() {
                    NotificationCenter.default.post(
                        name: .ldkEventReceived,
                        object: event.description
                    )
                    ldkNode.eventHandled()
                }
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
}

// Save Seed
extension LightningNodeService {
    func save(mnemonic: Mnemonic) throws {
        let backupInfo = BackupInfo(mnemonic: mnemonic)
        try keyService.saveBackupInfo(backupInfo)
    }
}
