//
//  OperatorAvatarView.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2022 Livetex. All rights reserved.
//

import UIKit
import Kingfisher

public class OperatorAvatarView: UIView {

    private let imageView = UIImageView()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(nil, for: .normal)
        button.setImage(nil, for: .normal)
        return button
    }()

    // MARK: - Initialization

   public override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(actionButton)
        addSubview(imageView)
    }

   public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Set Image

    func setImage(with url: URL?) {
        guard let resourceURL = url else {
            return
        }

        let imageProcessor = RoundCornerImageProcessor(cornerRadius: bounds.height / 2,
                                                       targetSize: bounds.size)
        imageView.kf.setImage(with: .network(ImageResource(downloadURL: resourceURL)),
                              options: [.processor(imageProcessor)])
    }

    // MARK: - Layout

   public override func layoutSubviews() {
        super.layoutSubviews()

        actionButton.frame = CGRect(origin: .zero, size: bounds.size)
        imageView.frame = CGRect(origin: .zero, size: bounds.size)
    }

}
