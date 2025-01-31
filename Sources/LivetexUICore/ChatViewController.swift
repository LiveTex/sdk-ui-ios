//
//  ChatViewController.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2022 Livetex. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Kingfisher
import SafariServices
import BFRImageViewer
import LivetexCore
import UniformTypeIdentifiers
import Combine

public class ChatViewController: MessagesViewController, InputBarAccessoryViewDelegate {

    public struct Appearance {
        static let activityIndicatorRect = CGRect(x: 0, y: 0, width: 20, height: 20)
    }

    public struct Constants {
        static let debouncedFunctionTimeInterval: TimeInterval = 2
    }



    // MARK: - Properties

    public lazy var viewModel = ChatViewModel()
    
    public lazy var typingFunction = DebouncedFunction(timeInterval: Constants.debouncedFunctionTimeInterval) { [weak self] in
            self?.setTypingIndicatorViewHidden(true, animated: true)
    }
    // Local variable showing input state
    // onDialogStateReceived dependent
    public var shouldShowInput: Bool? = true


    public override var canResignFirstResponder: Bool {
        true
    }

    // MARK: - Views

    public lazy var dialogueStateView: DialogueStateView = {
        let dialogueStateView = DialogueStateView()
        dialogueStateView.translatesAutoresizingMaskIntoConstraints = false

        return dialogueStateView
    }()
    public var isExpended = false
    public lazy var avatarView = OperatorAvatarView()
    public lazy var estimationView = EstimationView()
    public lazy var doubleEstimationView = DoubleEstimationView()
    public lazy var fiveEstimationView = FiveEstimationView()
    public lazy var estimationFiveView = EstimationFiveView()
    public lazy var messageInputBarView = MessageInputBarView()
    public lazy var barButton: UIBarButtonItem = {
        let activityIndicator = UIActivityIndicatorView(frame: Appearance.activityIndicatorRect)

        return UIBarButtonItem(customView: activityIndicator)
    }()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        configureCollectionView()
        super.viewDidLoad()

        configureInputBar()
        configureViewModel()
        configureNavigationItem()
        
        setAction()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        avatarView.frame = CGRect(origin: .zero, size: CGSize(width: 30, height: 30))

        layoutView(isExpended: isExpended)
    }

    // MARK: - Configuration
    private func setAction() {
        doubleEstimationView.onDoubleEstimateAction = { [weak self] result in
            self?.handleDoubleTapEstimation()
            self?.viewModel.point = result
            self?.estimationView.voteConfig(result)
            self?.viewModel.sendEvent(ClientEvent(.rating (SendVoteResult(type: TypeVote.doublePoint, value: result), nil)))
        }
        
        estimationView.onEstimateAction = { [weak self] in
            self?.handleTapEstimation()
        }
        
        fiveEstimationView.onFiveEstimateAction = { [weak self] result in
            self?.handleExTapFiveEstimation()
            self?.viewModel.point = result.description
            self?.estimationFiveView.voteConfig(result.description)
            self?.viewModel.sendEvent(ClientEvent(.rating(SendVoteResult(type: TypeVote.fivePoint, value: result.description), nil)))
        }
        
        estimationFiveView.onEstimateAction = { [weak self] in
            self?.handleTapFiveEstimation()
        }
    }
    
    public func layoutView(isExpended: Bool) {
        if viewModel.isEnableType {
            if viewModel.isTwoPoint {
                view.addSubview(estimationView)
                view.addSubview(doubleEstimationView)
                doubleEstimationView.isHidden = !isExpended
                estimationView.isHidden = isExpended
                
                let tapEstimation = UITapGestureRecognizer(target: self, action: #selector(handleTapEstimation))
                let tapDoubleEstimation = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapEstimation))
                                
                estimationView.frame = CGRect(x: view.safeAreaLayoutGuide.layoutFrame.minX,
                                              y: view.safeAreaLayoutGuide.layoutFrame.minY,
                                              width: view.safeAreaLayoutGuide.layoutFrame.width,
                                              height: EstimationView.viewHeight)
                
                doubleEstimationView.frame = CGRect(x: view.safeAreaLayoutGuide.layoutFrame.minX,
                                                    y: view.safeAreaLayoutGuide.layoutFrame.minY,
                                                    width: view.safeAreaLayoutGuide.layoutFrame.width,
                                                    height: DoubleEstimationView.viewHeight)
                if estimationView.isHidden == false {
                    messagesCollectionView.contentInset.top = EstimationView.viewHeight
                    messagesCollectionView.verticalScrollIndicatorInsets.top = EstimationView.viewHeight
                    estimationView.voteConfig(viewModel.point)

                } else {
                    messagesCollectionView.contentInset.top = DoubleEstimationView.viewHeight
                    messagesCollectionView.verticalScrollIndicatorInsets.top =   DoubleEstimationView.viewHeight
                }
                
                estimationView.addGestureRecognizer(tapEstimation)
                estimationView.isUserInteractionEnabled = true
                doubleEstimationView.addGestureRecognizer(tapDoubleEstimation)
                doubleEstimationView.isUserInteractionEnabled = true
            } else {
                view.addSubview(estimationFiveView)
                view.addSubview(fiveEstimationView)
                fiveEstimationView.isHidden = !isExpended
                estimationFiveView.isHidden = isExpended
                
                
                let tapEstimation = UITapGestureRecognizer(target: self, action: #selector(handleTapFiveEstimation))
                let tapDoubleEstimation = UITapGestureRecognizer(target: self, action: #selector(handleExTapFiveEstimation))
                
                
                estimationFiveView.frame = CGRect(x: view.safeAreaLayoutGuide.layoutFrame.minX,
                                                  y: view.safeAreaLayoutGuide.layoutFrame.minY,
                                                  width: view.safeAreaLayoutGuide.layoutFrame.width,
                                                  height: EstimationFiveView.viewHeight)
                
                fiveEstimationView.frame = CGRect(x: view.safeAreaLayoutGuide.layoutFrame.minX,
                                                    y: view.safeAreaLayoutGuide.layoutFrame.minY,
                                                    width: view.safeAreaLayoutGuide.layoutFrame.width,
                                                    height: FiveEstimationView.viewHeight)
                if estimationFiveView.isHidden == false {
                    messagesCollectionView.contentInset.top = EstimationFiveView.viewHeight
                    messagesCollectionView.verticalScrollIndicatorInsets.top = EstimationFiveView.viewHeight
                    estimationFiveView.voteConfig(viewModel.point)
                } else {
                    messagesCollectionView.contentInset.top =  FiveEstimationView.viewHeight
                    messagesCollectionView.verticalScrollIndicatorInsets.top = FiveEstimationView.viewHeight
                }
                estimationFiveView.addGestureRecognizer(tapEstimation)
                estimationFiveView.isUserInteractionEnabled = true
                fiveEstimationView.addGestureRecognizer(tapDoubleEstimation)
                fiveEstimationView.isUserInteractionEnabled = true
            }
            
        } else {
            estimationView.isHidden = true
            doubleEstimationView.isHidden = true
            estimationFiveView.isHidden = true
            estimationFiveView.voteConfig(nil)
            estimationView.voteConfig(nil)
            viewModel.point = nil
            messagesCollectionView.contentInset.top =  0
            messagesCollectionView.verticalScrollIndicatorInsets.top = 0
        }
    }
    
    @objc func handleTapEstimation() {
        estimationView.isHidden = true
        doubleEstimationView.isHidden = false
        isExpended = true
        if viewModel.point != nil {
            doubleEstimationView.resultVote = nil
            doubleEstimationView.resetResult()
        }
        messagesCollectionView.contentInset.top =  DoubleEstimationView.viewHeight
        messagesCollectionView.verticalScrollIndicatorInsets.top =  DoubleEstimationView.viewHeight
    }
    
    @objc func handleDoubleTapEstimation() {
        estimationView.isHidden = false
        doubleEstimationView.isHidden = true
        isExpended = false
        doubleEstimationView.resultVote = nil
        doubleEstimationView.resetResult()

        messagesCollectionView.contentInset.top =   EstimationView.viewHeight
        messagesCollectionView.verticalScrollIndicatorInsets.top =  EstimationView.viewHeight
    }
    
    @objc func handleTapFiveEstimation() {
        estimationFiveView.isHidden = true
        fiveEstimationView.isHidden = false
        isExpended = true
        if viewModel.point != nil {
            fiveEstimationView.rating = 0
            fiveEstimationView.resetResult()
        }
        messagesCollectionView.contentInset.top = FiveEstimationView.viewHeight
        messagesCollectionView.verticalScrollIndicatorInsets.top =  FiveEstimationView.viewHeight
    }
    
    @objc func handleExTapFiveEstimation() {
        estimationFiveView.isHidden = false
        fiveEstimationView.isHidden = true
        isExpended = false
        fiveEstimationView.rating = 0
        fiveEstimationView.resetResult()

        messagesCollectionView.contentInset.top =  EstimationFiveView.viewHeight
        messagesCollectionView.verticalScrollIndicatorInsets.top =  EstimationFiveView.viewHeight
    }

    public func configureNavigationItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatarView)
        navigationItem.titleView = dialogueStateView
    }

    public func configureInputBar() {
        messageInputBarView.delegate = self

        messageInputBarView.onAttachmentButtonTapped = { [weak self] in
            self?.sendAttachment()
        }
        self.inputBarType = .custom(messageInputBarView)
    }

    public func setConnectingState() {
        if let token = viewModel.sessionToken {
            viewModel.sessionService?.connect()
        }
        dialogueStateView.setConnectionInProgress(withKind: .connect)
    }

    public func setConnectedState() {
        dialogueStateView.setConnectedSuccessfully()
    }

    // MARK: - ViewModel binding

    public func configureViewModel() {
        viewModel.onWebsocketStateChanged = { [weak self] isConnected in
            isConnected ?
            self?.setConnectedState() :
            self?.setConnectingState()
        }
    
        viewModel.isSentName
            .combineLatest(viewModel.eventDepartment)
            .sink { [weak self] (isSentName, departments) in
                guard let self = self, !departments.isEmpty else {
                    return
                }
                if isSentName {
                    let minDepartments = 1
                    guard departments.count > minDepartments else {
                        self.viewModel.sendEvent(ClientEvent(.department(departments.first?.id ?? "")))
                        self.viewModel.clearRate()
                        self.viewModel.eventDepartment.send([])
                        return
                    }
                    
                    let actions = departments.map { department in
                        return UIAlertAction(title: department.name, style: .default) { _ in
                            self.viewModel.sendEvent(ClientEvent(.department(department.id)))
                            self.viewModel.clearRate()
                            self.handleInputStateIfNeeded(shouldShowInput: self.shouldShowInput)
                            self.viewModel.eventDepartment.send([])
                        }
                    }
                    
                    let alertController = UIAlertController(title: "Выбор отдела",
                                                            message: "Выберите куда направить ваше обращение",
                                                            preferredStyle: .actionSheet)
                    alertController.addActions(actions)
                    self.present(alertController, animated: true)
                }
            }
            .store(in: &cancellables)
        
        viewModel.onLoadMoreMessages = { [weak self] newMessages in
            self?.viewModel.messages.insert(contentsOf: newMessages, at: 0)
            self?.messagesCollectionView.reloadDataAndKeepOffset()
        }
        
        viewModel.onMessageUpdated = { [weak self] index in
            self?.messagesCollectionView.performBatchUpdates({
                self?.messagesCollectionView.reloadSections(IndexSet(integer: index))
            }, completion: nil)
        }
        
        viewModel.onDeleteElement = { [weak self] index in
            index.reversed().forEach { index in
                self?.viewModel.messages.remove(at: index)
            }
            
            self?.messagesCollectionView.performBatchUpdates({
                
                self?.messagesCollectionView.deleteSections(index)
            }, completion: nil)
        }
        
        viewModel.onReload = { [weak self]  in
            self?.messagesCollectionView.performBatchUpdates({
                self?.messagesCollectionView.reloadData()
                
            }, completion: nil)
        }
        
        viewModel.onMessagesReceived = { [weak self] newMessages in
            guard let self = self else {
                return
            }
            
            let updates = {
                self.messagesCollectionView.performBatchUpdates({
                    let count = self.viewModel.messages.count
                    let indexSet = IndexSet(integersIn: count..<count + newMessages.count)
                    self.viewModel.messages.append(contentsOf: newMessages)
                    self.messagesCollectionView.insertSections(indexSet)
                }, completion: { _ in
                    self.messagesCollectionView.scrollToLastItem(at: .top, animated: true)
                })
            }
            if self.viewModel.messages.isEmpty {
                updates()
            } else {
                if self.isTypingIndicatorHidden {
                    updates()
                } else {
                    self.setTypingIndicatorViewHidden(true,
                                                      animated: true,
                                                      whilePerforming: updates,
                                                      completion: nil)
                }
            }
        }
        viewModel.onDialogStateReceived = { [weak self] dialog in
            self?.dialogueStateView.title = dialog.employee?.name
            self?.dialogueStateView.subtitle = dialog.employeeStatus?.rawValue
            self?.avatarView.setImage(with: URL(string: dialog.employee?.avatarUrl ?? ""))
            self?.shouldShowInput = dialog.showInput
            self?.handleInputStateIfNeeded(shouldShowInput: dialog.showInput)
            if let rate = dialog.rate,
               let enableType = rate.enabledType {
                self?.viewModel.isEnableType = true
                if enableType == .doublePoint {
                    self?.viewModel.isTwoPoint = true
                } else {
                    self?.viewModel.isTwoPoint = false
                }
                if let set = rate.isSet {
                    self?.viewModel.isSet = set
                    if enableType == set.type {
                        self?.viewModel.point = set.value
                    } else {
                        self?.viewModel.point = nil
                    }
                } else {
                    self?.viewModel.isSet = nil
                    self?.viewModel.point = nil
                }
            } else {
                self?.viewModel.deleteRate()
            }
                UIView.animate(withDuration: 0.5) { [weak self] in
                    self?.layoutView(isExpended: self?.isExpended ?? false)
                }
        }


        viewModel.onTypingReceived = { [weak self] in
            self?.typingFunction.call()
            
            self?.setTypingIndicatorViewHidden(false, animated: true, completion: { _ in
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            })
        }
        viewModel.onAttributesReceived = { [weak self] in
            self?.viewModel.isSentName.send(false)
            let alertController = UIAlertController(title: "Атрибуты",
                                                    message: "Необходимо указать обязательные атрибуты",
                                                    preferredStyle: .alert)
            
            let placeholder = NSMutableAttributedString(string: "* Имя")
            placeholder.setAttributes([.foregroundColor: UIColor.red,
                                       .baselineOffset: 1],
                                      range: NSRange(location: 0, length: 1))
            
            alertController.addTextField { textField in
                textField.attributedPlaceholder = placeholder
            }
            alertController.addTextField { textField in
                textField.placeholder = "Телефон"
                textField.keyboardType = .phonePad
            }
            alertController.addTextField { textField in
                textField.placeholder = "Email"
                textField.keyboardType = .emailAddress
            }
            let accept = UIAlertAction(title: "OK", style: .default) { _ in
                let attributes = Attributes(name: alertController.textFields?[0].text ?? "",
                                            phone: alertController.textFields?[1].text ?? "",
                                            email: alertController.textFields?[2].text ?? "")
                self?.viewModel.user.displayName = alertController.textFields?[0].text ?? ""
                self?.viewModel.sendEvent(ClientEvent(.attributes(attributes)))
                self?.handleInputStateIfNeeded(shouldShowInput: self?.shouldShowInput)
                self?.viewModel.isSentName.send(true)
            }
            alertController.addActions(accept)
            self?.present(alertController, animated: true)
        }
    }

    public func configureCollectionView() {
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout())
        messagesCollectionView.register(TextMessageCollectionViewCell.self)
        messagesCollectionView.register(SystemMessageCollectionViewCell.self)
        messagesCollectionView.register(FollowTextMessageCollectionViewCell.self)
        messagesCollectionView.register(AttachmentCollectionViewCell.self)
        messagesCollectionView.register(RateViewCell.self)
        messagesCollectionView.register(ActionsReusableView.self,
                                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
        messagesCollectionView.delegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.gestureRecognizers?.filter { $0 is UITapGestureRecognizer }
        .forEach { $0.delaysTouchesBegan = false }

        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right,
                                                                          textInsets: UIEdgeInsets(top: 0,
                                                                                                   left: 0,
                                                                                                   bottom: 0,
                                                                                                   right: 16)))
        layout?.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left,
                                                                          textInsets: UIEdgeInsets(top: 0,
                                                                                                   left: 0,
                                                                                                   bottom: 0,
                                                                                                   right: 0)))
        layout?.setMessageIncomingAvatarPosition(AvatarPosition(vertical: .messageTop))
        layout?.setMessageIncomingAccessoryViewSize(.zero)
        layout?.setMessageOutgoingAccessoryViewSize(.zero)
        layout?.setMessageIncomingAccessoryViewPadding(.zero)
        layout?.setMessageOutgoingAccessoryViewPadding(.zero)
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageIncomingAvatarSize(CGSize(width: 30, height: 30))
        
        scrollsToLastItemOnKeyboardBeginsEditing = true
        maintainPositionOnInputBarHeightChanged = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        messagesCollectionView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        
        if doubleEstimationView.isHidden == false && viewModel.isTwoPoint == true  {
            if viewModel.isSet == nil {
                doubleEstimationView.resetResult()
                estimationView.voteConfig(nil)
            }
            handleDoubleTapEstimation()
        } else if fiveEstimationView.isHidden == false && viewModel.isTwoPoint == false   {
            if  viewModel.isSet == nil {
                fiveEstimationView.resetResult()
                estimationFiveView.voteConfig()
            }
            handleExTapFiveEstimation()
            
        }
    }

    // MARK: - Send attachment

    private func sendAttachment() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        let cancel = UIAlertAction(title: "Отменить", style: .cancel)

        let library = UIAlertAction(title: "Фото и Видео", style: .default) { _ in
            imagePickerController.sourceType = .savedPhotosAlbum//.photoLibrary
            imagePickerController.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
            self.present(imagePickerController, animated: true)
        }
        library.setValue(UIImage(asset: .photo), forKey: "image")

        let camera = UIAlertAction(title: "Камера", style: .default) { _ in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true)
        }
        camera.setValue(UIImage(asset: .camera), forKey: "image")

        let documents = UIAlertAction(title: "Документ", style: .default) { _ in
            let allowedContentTypes: [UTType] = [UTType.item]
            let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
            documentPickerController.delegate = self
            documentPickerController.allowsMultipleSelection = false
            self.present(documentPickerController, animated: true)
        }
        documents.setValue(UIImage(asset: .document), forKey: "image")

        alertController.addActions(camera, library, documents, cancel)
        alertController.view.tintColor = .black
        present(alertController, animated: true)
    }

    // MARK: - Send message

    public func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        messageInputBarView.inputTextView.text = ""
        messageInputBarView.invalidatePlugins()
        messageInputBarView.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if let followMessage = viewModel.followMessage {
            viewModel.followMessage = nil
            viewModel.sendEvent(ClientEvent(.text("> \(followMessage)\n\(trimmedText)")))
        } else {
            viewModel.sendEvent(ClientEvent(.text(trimmedText)))
        }
    }

    public func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        guard !text.isEmpty else {
            return
        }
        if text.count > 2000 {
                    inputBar.inputTextView.text = String(text.prefix(2000))
                }
        messagesCollectionView.scrollToLastItem()
        viewModel.sendEvent(ClientEvent(.typing(text)))
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPaste text: String) {
        let currentText = inputBar.inputTextView.text ?? ""
        let newText = currentText + text
        
        if newText.count > 2000 {
            let allowedText = String(newText.prefix(2000))
            inputBar.inputTextView.text = allowedText
        } else {
            inputBar.inputTextView.insertText(text)
        }
        return
    }

    // MARK: - UICollectionViewDelegate

    public override func collectionView(_ collectionView: UICollectionView,
                                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }

        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }

        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        switch message.kind {
        case .text:
            let cell = messagesCollectionView.dequeueReusableCell(TextMessageCollectionViewCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            if #available(iOS 13.0, *) {
                cell.messageContainerView.isUserInteractionEnabled = true
                cell.messageContainerView.addInteraction(UIContextMenuInteraction(delegate: self))
            }
            return cell

        case let .custom(value):
            if value is ChatViewModel.AttachmentFile {
                let cell = messagesCollectionView.dequeueReusableCell(AttachmentCollectionViewCell.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
            
            if value is Rate {
                let cell = messagesCollectionView.dequeueReusableCell(RateViewCell.self, for: indexPath)
                if let message = value as? Rate {
                    
                    if let setRate = message.isSet {
                        if setRate.type == .fivePoint {
                            cell.config(isComment: message.commentEnabled, isTwoPoint: false, beforTitle: message.textBefore ?? "", afterTitle: message.textAfter ?? "", setRate: setRate)
                        } else {
                            cell.config(isComment: message.commentEnabled, isTwoPoint: true, beforTitle: message.textBefore ?? "", afterTitle: message.textAfter ?? "", setRate: setRate)
                        }
                    } else {
                        if message.enabledType == .fivePoint {
                            cell.config(isComment: message.commentEnabled, isTwoPoint: false, beforTitle: message.textBefore ?? "", afterTitle: "")
                        } else {
                            cell.config(isComment: message.commentEnabled, isTwoPoint: true, beforTitle: message.textBefore ?? "", afterTitle: "")
                        }
                        cell.action = { [weak self] rate, text in
                            if let type = message.enabledType,
                               let rate = rate {
                                self?.viewModel.sendEvent(ClientEvent(.rating(SendVoteResult(type: type, value: rate.description), text)))
                            }
                        }
                        
                        cell.actionKeyboard = { [weak self] in
                            self?.messagesCollectionView.scrollToLastItem()
                        }
                    }
                }
                return cell
            }
            
            guard let type = value as? CustomType else {
                return super.collectionView(collectionView, cellForItemAt: indexPath)
            }

            switch type {
            case .system:
                let cell = messagesCollectionView.dequeueReusableCell(SystemMessageCollectionViewCell.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            case .follow:
                let cell = messagesCollectionView.dequeueReusableCell(FollowTextMessageCollectionViewCell.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }

        default:
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }
    }

    // MARK: - UIScrollViewDelegate

    public override func collectionView(_ collectionView: UICollectionView,
                                        willDisplay cell: UICollectionViewCell,
                                        forItemAt indexPath: IndexPath) {
        if indexPath.section == 0, viewModel.isContentLoaded, !viewModel.isLoadingMore {
            viewModel.loadMoreMessagesIfNeeded()
        }
    }

}

// MARK: - Helper methods

extension ChatViewController {

    public func handleInputStateIfNeeded(shouldShowInput: Bool?) {
        if let shouldShowInput = shouldShowInput {
            if shouldShowInput {
                becomeFirstResponder()
            } else {
                hideInputAccessoryView()
            }
        }
    }

    public func hideInputAccessoryView() {
        guard let firstResponder = UIResponder.first else {
            return
        }

        firstResponder.resignFirstResponder()
        hideInputAccessoryView()
    }

}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {

    public var currentSender: SenderType {
        return viewModel.user
    }

    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.count
    }

    public func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages[indexPath.section]
    }

    public func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard viewModel.isPreviousMessageSameDate(at: indexPath.section) else {
            return NSAttributedString(string: DateFormatter.relativeDate.string(from: message.sentDate),
                                      attributes: [.font: UIFont.boldSystemFont(ofSize: 10),
                                                   .foregroundColor: UIColor.darkGray])
        }

        return nil
    }

    public func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: message.sender.displayName,
                                  attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }

    public func messageFooterView(for indexPath: IndexPath,
                                  in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        let message = viewModel.messages[indexPath.section]
        guard let keyboard = message.keyboard else {
            return MessageReusableView()
        }
        
        let view = messagesCollectionView.dequeueReusableFooterView(ActionsReusableView.self, for: indexPath)
        view.configure(with: keyboard)
        view.onAction = { [weak self] button in
            self?.viewModel.sendEvent(ClientEvent(.buttonPressed(button.payload)))
        }

        return view
    }

}

// MARK: - UIContextMenuInteractionDelegate

extension ChatViewController: UIContextMenuInteractionDelegate {
    
    @available(iOS 13.0, *)
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                       configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let point = interaction.location(in: messagesCollectionView)
        guard let indexPath = messagesCollectionView.indexPathForItem(at: point),
              case let .text(value) = viewModel.messages[indexPath.section].kind else {
                  return nil
              }

        let message = viewModel.messages[indexPath.section]
        let testView = FollowMessageView(name: message.sender.displayName, text: value)
        viewModel.followMessage = value
        testView.onCancelAction = { [weak self] in
            self?.viewModel.followMessage = nil
            self?.messageInputBarView.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        }

        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { action in
            let answer = UIAction(title: "Ответить", image: UIImage(systemName: "arrowshape.turn.up.left")) { _ in
                self.messageInputBarView.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                self.messageInputBarView.topStackView.addArrangedSubview(testView)
            }

            let copy = UIAction(title: "Скопировать", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = value
            }

            return UIMenu(title: "", children: [answer, copy])
        }

        return configuration
    }

}

extension ChatViewController: MessageCellDelegate {

    public func didSelectURL(_ url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true)
    }

    public  func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              case let .photo(item) = viewModel.messages[indexPath.section].kind, let url = item.url,
              let imageSource = BFRBackLoadedImageSource(initialImage: item.placeholderImage, hiResURL: url),
              let viewController = BFRImageViewController(imageSource: [imageSource]) else {
                  return
              }

        present(viewController, animated: true)
    }

    public func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else { return }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        switch message.kind {
        case .custom(let data):
            guard let attachment = data as? ChatViewModel.AttachmentFile, let url = attachment.url
            else { return }
            dialogueStateView.setConnectionInProgress(withKind: .download)
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else { return }
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent((attachment.name ?? url.pathExtension) + "." + (url.pathExtension))
                do {
                    try data.write(to: tmpURL)
                    DispatchQueue.main.async { [weak self] in
                        let avc = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
                        avc.completionWithItemsHandler = { [weak self] activityType, completed, returnedItems, activityError in
                            do {
                                self?.dialogueStateView.setConnectedSuccessfully()
                                try FileManager.default.removeItem(at: tmpURL)
                            } catch {
                                print(error)
                            }
                        }
                        self?.present(avc, animated: true)
                    }
                    } catch {
                        print(error)
                    }
            }.resume()
        default:
            return
        }
    }
}

extension ChatViewController: MessagesDisplayDelegate {

    public func backgroundColor(for message: MessageType,
                                at indexPath: IndexPath,
                                in messagesCollectionView: MessagesCollectionView) -> UIColor {
        switch message.kind {
        case .photo:
            return .messageGray
        default:
            return isFromCurrentSender(message: message) ? .messageBlue : .messageGray
        }
    }

    public func enabledDetectors(for message: MessageType,
                                 at indexPath: IndexPath,
                                 in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url]
    }

    public  func textColor(for message: MessageType,
                           at indexPath: IndexPath,
                           in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }

    public func detectorAttributes(for detector: DetectorType,
                                   and message: MessageType,
                                   at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: isFromCurrentSender(message: message) ? UIColor.white : UIColor.black,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: isFromCurrentSender(message: message) ? UIColor.white : UIColor.black]
    }

    public func messageStyle(for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .bubble
    }

    public func configureMediaMessageImageView(_ imageView: UIImageView,
                                               for message: MessageType,
                                               at indexPath: IndexPath,
                                               in messagesCollectionView: MessagesCollectionView) {
        guard case let .photo(item) = message.kind, let imageURL = item.url else {
            return
        }

        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: .network(Kingfisher.ImageResource(downloadURL: imageURL)))
    }

    public func configureAvatarView(_ avatarView: AvatarView,
                                    for message: MessageType,
                                    at indexPath: IndexPath,
                                    in messagesCollectionView: MessagesCollectionView) {
        let placeholderImage = UIImage(asset: .account)
        guard let chatMessage = message as? ChatViewModel.ChatMessage,
              let urlString = chatMessage.creator?.employee?.avatarUrl,
              let resourceURL = URL(string: urlString) else {
            avatarView.backgroundColor = .clear
            avatarView.set(avatar: Avatar(image: placeholderImage))
            return
        }

        avatarView.kf.setImage(with: Kingfisher.ImageResource(downloadURL: resourceURL), placeholder: placeholderImage)
    }

}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {

    public func cellTopLabelHeight(for message: MessageType,
                            at indexPath: IndexPath,
                            in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return viewModel.isPreviousMessageSameDate(at: indexPath.section) ? 0 : 24
    }

    public func messageTopLabelHeight(for message: MessageType,
                               at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isFromCurrentSender(message: message) ? 0 : 20
    }
    
    public func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        guard let keyboard = viewModel.messages[section].keyboard, !keyboard.buttons.isEmpty,
              let layout = messagesCollectionView.collectionViewLayout as? CustomMessagesFlowLayout else {
                  return .zero
              }

        return CGSize(width: layout.itemWidth, height: ActionsReusableView.viewHeight(for: keyboard))
    }

}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage,
           let data = image.jpegData(compressionQuality: 0.5),
           let url = info[.imageURL] as? URL {

            let documentURL = url //urls[0]
            let documentExtension = documentURL.pathExtension
            let name  = documentURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "test"
            viewModel.sessionService?.upload(data: data, fileName: name, mimeType: "image/jpeg") { [weak self] result in
                switch result {
                case let .success(attachment):
                    self?.viewModel.sendEvent(ClientEvent(.file(attachment)))
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
        } else if let videoURL = info[.mediaURL] as? URL{
            do { let videoData = try Data(contentsOf: videoURL)
                let documentURL = videoURL //urls[0]
                let documentExtension = documentURL.pathExtension
                let name  = documentURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "test"
                if let typeFile = UTType(filenameExtension: documentURL.pathExtension)?.preferredMIMEType {
                    viewModel.sessionService?.upload(data: videoData, fileName: name, mimeType: typeFile) { [weak self] result in
                        switch result {
                        case let .success(attachment):
                            self?.viewModel.sendEvent(ClientEvent(.file(attachment)))
                        case let .failure(error):
                            print(error.localizedDescription)
                        }
                    }
                }
            }  catch {
                debugPrint("Couldn't get Data from URL")
            }
        } else if let originImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
                  (info[UIImagePickerController.InfoKey.imageURL] as? URL) == nil {

            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let fileName = UUID().uuidString + ".jpeg"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            guard let jpegData = originImage.jpegData(compressionQuality: 0.5) else { return }
            do {
                try jpegData.write(to: fileURL)
            } catch let error {
                print("error saving file with error", error)
            }
            viewModel.sessionService?.upload(data: jpegData, fileName: fileName, mimeType: "image/jpeg") { [weak self] result in
                switch result {
                case let .success(attachment):
                    self?.viewModel.sendEvent(ClientEvent(.file(attachment)))
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
        }
        picker.dismiss(animated: true)
    }
}

extension ChatViewController: UIDocumentPickerDelegate {

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        url.startAccessingSecurityScopedResource()
        guard let documentData = try? Data(contentsOf: url) else { return }
        url.stopAccessingSecurityScopedResource()

        let documentURL = url //urls[0]
        let documentExtension = documentURL.pathExtension
        let name  = documentURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "test"

        // TODO: - Add methods upload and sendEvent to viewModel
        switch documentExtension {
        case "pdf":
            viewModel.sessionService?.upload(data: documentData, fileName: name, mimeType: "application/pdf") { [weak self] result in
                switch result {
                case let .success(attachment):
                    self?.viewModel.sendEvent(ClientEvent(.file(attachment)))
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
        default:
            if let typeFile = UTType(filenameExtension: documentURL.pathExtension)?.preferredMIMEType {
                viewModel.sessionService?.upload(data: documentData, fileName: name, mimeType: typeFile) { [weak self] result in
                    switch result {
                    case let .success(attachment):
                        self?.viewModel.sendEvent(ClientEvent(.file(attachment)))
                    case let .failure(error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}
