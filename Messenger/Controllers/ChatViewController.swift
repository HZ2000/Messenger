//
//  ChatViewController.swift
//  Messenger
//
//  Created by Hayk Zakaryan on 7/27/20.
//  Copyright © 2020 Hayk Zakaryan. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var senderId: String
    public var displayName: String
    public var photoURL: String
    
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
}


class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail: String
    private let conversationId: String?
    
    private var messages = [Message]()
    
    private var selfSender : Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(senderId: safeEmail,
                      displayName: "Killian Jones" ,
                      photoURL: "")
    }
    
    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId , shouldScrollToBottom: true)
        }
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside {[weak self] (_) in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you want to attach", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {[weak self] (_) in
            self?.presentPhotoInputActionSheet()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {[weak self] (_) in
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {[weak self] (_) in
            
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet , animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker , animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker , animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet , animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a video from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker , animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {[weak self] (_) in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker , animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet , animated: true)
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) {[weak self] (result) in
            switch result {
            case .success(let messages):
                print("Success in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("Messages are empty")
                    return
                }
                
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
            case .failure(let error):
                print("Failed to get messages: \(error)")
            }
        }
    }
    
}


extension ChatViewController : UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
            let conversationId = conversationId,
            let name = self.title,
            let selfSender = selfSender
            else {
                return
        }
        
        if let image = info[.editedImage] as? UIImage,let imageData = image.pngData() {
            let fileName = "photo_message" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            //Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) {[weak self] (result) in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print("Uploaded message photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else {
                            return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message ) { (success) in
                        if success {
                            print("Sent photo message")
                        }
                        else {
                            print("Failed to send photo message")
                        }
                    }
                case .failure(let error):
                    print("Message photo upload error: \(error)")
                }
            }
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"

            //Upload video
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) {[weak self] (result) in
                           guard let strongSelf = self else {
                               return
                           }
                           switch result {
                           case .success(let urlString):
                               // Ready to send message
                               print("Uploaded message video: \(urlString)")
                               
                               guard let url = URL(string: urlString),
                                   let placeholder = UIImage(systemName: "plus") else {
                                       return
                               }
                               
                               let media = Media(url: url,
                                                 image: nil,
                                                 placeholderImage: placeholder,
                                                 size: .zero)
                               
                               let message = Message(sender: selfSender,
                                                     messageId: messageId,
                                                     sentDate: Date(),
                                                     kind: .video(media))
                               
                               DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message ) { (success) in
                                   if success {
                                       print("Sent photo message")
                                   }
                                   else {
                                       print("Failed to send photo message")
                                   }
                               }
                           case .failure(let error):
                               print("Message photo upload error: \(error)")
                           }
                       }
            
        }
        
        
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty ,
            let selfSender = self.selfSender,
            let messageId = createMessageId()
            else {
                return
        }
        
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        if isNewConversation {
            //Create convo in database
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,
                                                         name: self.title ?? "User" ,
                                                         firstMessage: message) {[weak self] (success) in
                                                            if success {
                                                                print("Message sent")
                                                                self?.isNewConversation = false
                                                            }
                                                            else {
                                                                print("Failed to send")
                                                            }
            }
        }
        else {
            guard let convesationId = conversationId,
                let name = self.title else {
                    return
            }
            //Append to existing conversation data
            DatabaseManager.shared.sendMessage(to: convesationId,otherUserEmail: otherUserEmail, name: name, newMessage: message) { (success) in
                if success {
                    print("Message sent")
                }
                else {
                    print("Failed to send")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        //date , otherUserEmail , senderEmail
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("Created message id: \(newIdentifier)")
        return newIdentifier
    }
    
}

extension ChatViewController: MessagesDataSource , MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        
        fatalError("Self Sender is nil, email should be cached")
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            vc.player?.play()
            present(vc , animated: true)
        default:
            break
        }
        
        
    }
}
