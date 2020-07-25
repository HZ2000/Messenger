//
//  ViewController.swift
//  Messenger
//
//  Created by Hayk Zakaryan on 7/21/20.
//  Copyright © 2020 Hayk Zakaryan. All rights reserved.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
       validateAuth()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
                   let vc = LoginViewController()
                   let nav = UINavigationController(rootViewController: vc)
                   nav.modalPresentationStyle = .fullScreen
                   present(nav, animated: false)
               }
    }


}

