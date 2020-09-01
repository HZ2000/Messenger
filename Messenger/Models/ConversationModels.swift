//
//  ConversationModels.swift
//  Messenger
//
//  Created by Hayk Zakaryan on 9/1/20.
//  Copyright © 2020 Hayk Zakaryan. All rights reserved.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
    
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead : Bool
}

