//
//  ViewAttachment.swift
//  TagEditor
//
//  Created by Ryota Iwai on 2018/08/14.
//  Copyright © 2018年 Ryota Iwai. All rights reserved.
//

import Foundation
import UIKit

final class ViewAttachment: NSTextAttachment {

    // MARK: - Internal properties

    private(set) var attachedView: UIView? {
        didSet {
            guard let bounds = self.attachedView?.bounds else {
                return
            }
            self.bounds = bounds
        }
    }

    // MARK: - Private properties

    private var placeholderText: String?
    private var fullWidth: Bool = false
    private let utiType = "application/x-view"

    // MARK: - deinit

    deinit {
        self.attachedView?.removeFromSuperview()
    }

    // MARK: - init

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    init(attachedView: UIView, placeholderText: String? = nil, fullWidth: Bool = false) {
        if let text = placeholderText {
            let data = NSData(bytes: (text as NSString).utf8String, length: strlen((text as NSString).utf8String))
            super.init(data: (data as Data), ofType: self.utiType)
        } else {
            super.init(data: nil, ofType: self.utiType)
        }
        self.bounds = attachedView.bounds
        self.attachedView = attachedView
        self.placeholderText = placeholderText
        self.fullWidth = fullWidth
    }

    // MARK: - Override methods

    override func image(forBounds imageBounds: CGRect,
                        textContainer: NSTextContainer?,
                        characterIndex charIndex: Int) -> UIImage? {
        return nil
    }

    override func attachmentBounds(for textContainer: NSTextContainer?,
                                   proposedLineFragment lineFrag: CGRect,
                                   glyphPosition position: CGPoint,
                                   characterIndex charIndex: Int) -> CGRect {

        var rect = super.attachmentBounds(for: textContainer,
                                          proposedLineFragment: lineFrag,
                                          glyphPosition: position,
                                          characterIndex: charIndex)
        if let container = textContainer, self.fullWidth {
            rect.size.width = lineFrag.width - container.lineFragmentPadding * 2
        }
        return rect
    }

    // MARK: - Internal methods

    func attributedString() -> NSAttributedString {
        return NSAttributedString.init(attachment: self)
    }

    func attributedString(with attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        attributedText.append(self.attributedString())
        attributedText.addAttributes(attributes, range: NSRange(location: 0, length: attributedText.length))
        return NSAttributedString.init(attributedString: attributedText)
    }
}
