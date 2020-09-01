//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Hayk Zakaryan on 9/1/20.
//  Copyright © 2020 Hayk Zakaryan. All rights reserved.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
