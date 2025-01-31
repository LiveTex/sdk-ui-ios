//
//  ChatViewModel.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2022 Livetex. All rights reserved.
//

import UIKit
import MessageKit
import LivetexCore
import KeychainSwift
import Combine

public class ChatViewModel {

    var onReload: (() -> Void)?
    var onDeleteElement: ((IndexSet) -> Void)?
    var onDepartmentReceived: (([Department]) -> Void)?
    var onLoadMoreMessages: (([ChatMessage]) -> Void)?
    var onMessagesReceived: (([ChatMessage]) -> Void)?
    var onMessageUpdated: ((Int) -> Void)?
    var onDialogStateReceived: ((Conversation) -> Void)?
    var onAttributesReceived: (() -> Void)?
    var onTypingReceived: (() -> Void)?
    var onWebsocketStateChanged: ((Bool) -> Void)?
    var deviceToken: String?
    var followMessage: String?
    var messages: [ChatMessage] = []
    var sessionToken: SessionToken?
    var isTwoPoint = true
    var point: String? = nil
    var isSet: VoteResult?
    var votedMessage: ChatMessage? = nil
    var departments: Departments?
    var isSentName = CurrentValueSubject<Bool, Never>(true)
    var eventDepartment = PassthroughSubject<[Department], Never>()

    var user = Recipient(senderId: UUID().uuidString, displayName: "")

    private(set) var sessionService: LivetexSessionService?
    private let loadMoreOffset = 20
    private var isRated = true
    private(set) var isContentLoaded = false
    private(set) var isLoadingMore = false
    private let keychain = KeychainSwift()
    private var isCanLoadMore = true

    private(set) var isEmployeeEstimated = true
    var isEnableType = false

    private let settings = Settings()

    // MARK: - Initialization

    public init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidRegisterForRemoteNotifications(_:)),
                                               name: UIApplication.didRegisterForRemoteNotifications,
                                               object: nil)
      NotificationCenter.default.post(name: UIApplication.didRegisterForRemoteNotifications,
                                      object:  keychain.get("deviceToken"))
    }

    // MARK: - Configuration

    public func requestAuthentication(deviceToken: String) {
        let loginService = LivetexAuthService(visitorToken: settings.visitorToken,
                                              deviceToken: deviceToken)
        self.deviceToken = deviceToken
        loginService.requestAuthorization { [weak self] result in
           // DispatchQueue.main.async {
                switch result {
                case let .success(token):
                    self?.sessionToken = token
                    self?.startSession(token: token)
                case let .failure(error):
                    print(error.localizedDescription)
                }
           // }
        }
    }

    public func startSession(token: SessionToken) {
        settings.visitorToken = token.visitorToken
        sessionService = LivetexSessionService(token: token)
        sessionService?.onEvent = { [weak self] event in
            self?.didReceive(event: event)
        }
        sessionService?.onConnect = { [weak self] in
            self?.onWebsocketStateChanged?(true)
        }

        sessionService?.onDisconnect = { [weak self] in
            self?.onWebsocketStateChanged?(false)
        }

        sessionService?.connect()
    }

    func loadMoreMessagesIfNeeded() {
        guard isCanLoadMore, let id = messages.first?.messageId, !id.isEmpty else {
            return
        }

        let event = ClientEvent(.getHistory(id, loadMoreOffset))
        sessionService?.sendEvent(event)
        isLoadingMore = true
    }

    // MARK: - Application Lifecycle

    @objc public func applicationDidEnterBackground() {
        sessionService?.disconnect()
    }

    @objc public func applicationWillEnterForeground() {
        sessionService?.connect()
    }

    @objc public func applicationDidRegisterForRemoteNotifications(_ notification: Notification) {
        let deviceToken = notification.object as? String
        requestAuthentication(deviceToken: deviceToken ?? "")
    }

    // MARK: - Session

   public func sendEvent(_ event: ClientEvent) {
        let isConnected = sessionService?.isConnected ?? false
        if !isConnected {
            sessionService?.connect()
        }

        sessionService?.sendEvent(event)

        updateMessageIfNeeded(event: event)
    }

    private func didReceive(event: ServiceEvent) {
        switch event {
        case let .result(result):
            print("Answer from back-end:", result)
        case let .state(result):
            isEmployeeEstimated = result.isEmployeeEstimated
            if let rate = result.rate {
                if result.status != .unassigned {
                    onDialogStateReceived?(result)
                } else {
                    addRateMessage(result: rate)
                }
            } else {
                onDialogStateReceived?(result)
            }
        case .attributes:
            onAttributesReceived?()
        case let .departments(result):
            eventDepartment.send(result.departments)
        case let .update(result):
            messageHistoryReceived(items: result.messages)
        case .employeeTyping:
            onTypingReceived?()
        @unknown default:
            break
        }
    }
    
    func addRateMessage(result: Rate) {
        var rate = Rate(enabledType: result.enabledType, commentEnabled: result.commentEnabled, textBefore: result.textBefore, textAfter: result.textAfter, isSet: result.isSet)
        var newRate = ChatMessage(sender: Recipient(senderId: "Rate", displayName: ""), messageId: "", sentDate: Date(), kind: .custom(rate))
          
        if rate.isSet != nil {

            if messages.isEmpty {
                votedMessage = newRate
            } else {
           
                guard let index = messages.lastIndex(where: { $0.sender.senderId == "Rate"}) else {
                        return
                    }
                onDeleteElement?(IndexSet(integer: index))
                    onReload?()
                    onMessagesReceived?([newRate])
                    isRated = true
            }
        } else {

            if messages.isEmpty {
                votedMessage = newRate

            } else {
                if messages.contains(where: { message in if case let .custom(data) = message.kind,
                                                            var modelRate = data as? Rate, modelRate.isSet == nil {
                    return true
                } else {
                    return false
                } })  {
                    return
                } else {

                    onMessagesReceived?([newRate])
                    isRated = true
                }
            }
        }
    }
    
    func deleteRate() {
        if let index = messages.lastIndex(where: { $0.sender.senderId == "Rate"}) {
            
            onDeleteElement?(IndexSet(integer: index))
            onReload?()
        }
    }
    
    public func updateMessageIfNeeded(event: ClientEvent) {
        guard case .buttonPressed = event.content,
              let index = messages.lastIndex(where: { $0.keyboard != nil }),
              !messages.isEmpty, let keyboard = messages[index].keyboard else {
            return
        }

        var message = messages[index]
        message.keyboard = Keyboard(buttons: keyboard.buttons, pressed: true)
        messages.remove(at: index)
        messages.insert(message, at: index)

        onMessageUpdated?(index)
    }

   public func isPreviousMessageSameDate(at index: Int) -> Bool {
        guard index - 1 >= 0 else {
            return false
        }

        let currentDate = messages[index].sentDate
        let previousDate = messages[index - 1].sentDate
        return Calendar.current.isDate(currentDate, inSameDayAs: previousDate)
    }

     func convertMessages(_ messages: [Message]) -> [ChatMessage] {
        return messages.map {
            let kind: MessageKind
            let sender = $0.creator.isVisitor ? self.user : Recipient(senderId: "",
                                                                      displayName: $0.creator.employee?.name ?? "")
            switch $0.content {
            case let .text(text):
                if text.isImageUrl {
                    kind = .photo(File(url: text))
                } else if text.first == ">" {
                    let texts = text.trimmingCharacters(in: CharacterSet(charactersIn: "> ")).split(separator: "\n")
                    kind = .custom(CustomType.follow(String(texts.first ?? ""), String(texts.last ?? "")))
                } else {
                    kind = $0.creator.type == .system ? .custom(CustomType.system(text)) : .text(text)
                }
            case let .file(attachment):
                if attachment.url.isImageUrl {
                    kind = .photo(File(url: attachment.url))
                } else {
                    kind = .custom(AttachmentFile(url: attachment.url, name: attachment.name))
                }
            @unknown default:
                kind = .text("")
            }

            return ChatMessage(sender: sender,
                               messageId: $0.id,
                               sentDate: $0.createdAt,
                               kind: kind,
                               creator: $0.creator,
                               keyboard: $0.keyboard)
        }
    }
    
    func clearRate() {
        var indexPathsToDelete: IndexSet = []
        if isRated == true {
            messages.enumerated().forEach { index, element in
                if element.sender.senderId == "Rate" {
                    indexPathsToDelete.insert(index)
                }
            }
                onDeleteElement?(indexPathsToDelete)
                onReload?()
                }
                isRated = false
    }

    public func messageHistoryReceived(items: [Message]) {
        guard !items.isEmpty else {
            isCanLoadMore = false
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            
            self.isLoadingMore = false
            var newMessages = Array(Set(self.convertMessages(items)).subtracting(self.messages))
            if newMessages.count != self.messages.count || self.messages.count == 1 {
                let currentDate = self.messages.first?.sentDate ?? Date()
                let receivedDate = newMessages.last?.sentDate ?? Date()
                newMessages.sort(by: { $0.sentDate < $1.sentDate })
                DispatchQueue.main.async {
                    if !self.messages.isEmpty, receivedDate.compare(currentDate) == .orderedAscending {
                        self.onLoadMoreMessages?(newMessages)
                    } else {
                        if let voted = self.votedMessage {
                            newMessages.append(voted)
                        }
                        self.onMessagesReceived?(newMessages)
                        self.isContentLoaded = true
                    }
                    self.votedMessage = nil
                }
            }
        }
    }
}


public extension UIApplication {

  public static let didRegisterForRemoteNotifications = NSNotification.Name(rawValue: "didRegisterForRemoteNotifications")
}
