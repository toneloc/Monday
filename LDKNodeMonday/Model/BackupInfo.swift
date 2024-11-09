//
//  BackupInfo.swift
//  LDKNodeMonday
//
//  Created by Matthew Ramsden on 9/14/23.
//

import Foundation

struct BackupInfo: Codable, Equatable {
    var mnemonic: String

    init(mnemonic: String) {
        self.mnemonic = mnemonic
    }

    static func == (lhs: BackupInfo, rhs: BackupInfo) -> Bool {
        return lhs.mnemonic == rhs.mnemonic
    }
}

struct ChannelInfo: Codable, Equatable {
    var channelID: String
    var amount: Double

    init(
        channelID: String,
        amount: Double
    ) {
        self.channelID = channelID
        self.amount = amount
    }

    static func == (lhs: ChannelInfo, rhs: ChannelInfo) -> Bool {
        return lhs.channelID == rhs.channelID && lhs.amount == rhs.amount
    }
}

#if DEBUG
    let mockBackupInfo = BackupInfo(mnemonic: "")
    let mockChannelInfo = ChannelInfo(channelID: "", amount: 0)
#endif
