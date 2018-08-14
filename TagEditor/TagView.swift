//
//  TagView.swift
//  TagEditor
//
//  Created by Ryota Iwai on 2018/08/14.
//  Copyright © 2018年 Ryota Iwai. All rights reserved.
//

import UIKit

protocol TagViewDelegate: class {
    func deleteDidTap(view: TagView)
}

final class TagView: UIView {

    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var label: UILabel!

    var tagString: String {
        guard let tagString = self.label.text else {
            return ""
        }
        return tagString
    }

    weak var delegate: TagViewDelegate?

    func configure(tagString: String) {
        self.backgroundView.layer.cornerRadius = self.backgroundView.bounds.height / 2
        label.text = "#\(tagString)"
        self.label.sizeToFit()
        self.bounds.size.width = self.label.bounds.width + 30
    }

    @IBAction func deleteButtonDidTap(_ sender: Any) {
        self.delegate?.deleteDidTap(view: self)
    }
}
