//
//  ViewAttachmentTextContainerView.swift
//  TagEditor
//
//  Created by Ryota Iwai on 2018/08/14.
//  Copyright © 2018年 Ryota Iwai. All rights reserved.
//

import Foundation
import UIKit

// MARK: - ViewAttachmentTextContainerViewDelegate

protocol ViewAttachmentTextContainerViewDelegate: class {
    func attachmentTextContainerView(_ textContainerView: ViewAttachmentTextContainerView,
                                     shouldDeleteAttachments attachments: [ViewAttachment]) -> Bool

    func attachmentTextContainerView(_ textContainerView: ViewAttachmentTextContainerView,
                                     willDeleteAttachment attachment: ViewAttachment)

    func attachmentTextContainerView(_ textContainerView: ViewAttachmentTextContainerView,
                                     didDeleteAttachment attachment: ViewAttachment)
}

extension ViewAttachmentTextContainerViewDelegate {
    func attachmentTextContainerView(_ textContainerView: ViewAttachmentTextContainerView,
                                     shouldDeleteAttachments attachments: [ViewAttachment]) -> Bool {
        return true
    }

    func attachmentTextContainerView(_ textContainerView: ViewAttachmentTextContainerView,
                                     willDeleteAttachment attachment: ViewAttachment) {}

    func attachmentTextContainerView(_ textContainerView: ViewAttachmentTextContainerView,
                                     didDeleteAttachment attachment: ViewAttachment) {}
}

final class ViewAttachmentTextContainerView: UIView {

    // MARK: - Static properties

    static let attachmentPlaceholderString: String = "\u{fffc}" // OBJECT REPLACEMENT CHARACTER

    // MARK: - Internal properties

    weak var delegate: ViewAttachmentTextContainerViewDelegate?
    weak var textViewDelegate: UITextViewDelegate?

    // MARK: - Private properties

    private var textStorage: NSTextStorage?
    private var textView: UITextView?
    private let manager = ViewAttachmentLayoutManager()
    private var attaches: [ViewAttachment] = []

    private var _font: UIFont? {
        didSet {
            guard let font = self._font else {
                return
            }
            self.textView?.font = font
            if let range = self.textView?.selectedRange {
                self.textStorage?.addAttributes([.font: font], range: range)
            }
        }
    }
    private var _paragraphStyle: NSParagraphStyle?

    // MARK: - init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    // MARK: - Override methods

    override func becomeFirstResponder() -> Bool {
        return self.textView?.becomeFirstResponder() ?? false
    }

    // MARK: - Internal methods



    func selectedRange() -> NSRange {
        return self.textView?.selectedRange ?? NSRange.init(location: 0, length: 0)
    }

    func set(selectedRange range: NSRange) {
        self.textView?.selectedRange = range
    }

    func textContainerInset() -> UIEdgeInsets {
        return self.textView?.textContainerInset ?? UIEdgeInsets.zero
    }

    func set(textContainerInset inset: UIEdgeInsets) {
        self.textView?.textContainerInset = inset
    }

    func length() -> Int {
        return self.textStorage?.length ?? 0
    }

    func replace(to attachment: ViewAttachment, range: Range<String.Index>) {
        guard let textView = self.textView else {
            return
        }
        self.insert(attachment: attachment, at: range.lowerBound.encodedOffset)

        let nsrange = NSRange(location: range.lowerBound.encodedOffset + 1, length: range.upperBound.encodedOffset - range.lowerBound.encodedOffset)
        self.textStorage?.beginEditing()
        self.textStorage?.replaceCharacters(in: nsrange, with: "")
        self.textStorage?.endEditing()
        let endPoistion = textView.endOfDocument
        textView.selectedTextRange = textView.textRange(from: endPoistion, to: endPoistion)
    }

    func insert(attachment: ViewAttachment) {
        guard
            let textView = self.textView,
            let textStorage = self.textStorage,
            let attachedView = attachment.attachedView else {
                return
        }
        attachedView.isHidden = true
        textView.addSubview(attachedView)
        self.attaches.append(attachment)

        textStorage.beginEditing()
        textStorage.replaceCharacters(in: self.selectedRange(), with: ViewAttachmentTextContainerView.attachmentPlaceholderString)
        textStorage.addAttributes([.attachment: attachment,
                                   .font: self.font(),
                                   .paragraphStyle: self.paragraphStyle()],
                                  range: textStorage.editedRange)
        let location = min(textStorage.editedRange.location + textStorage.editedRange.length, textStorage.length)
        let selectedRange = NSRange.init(location: location, length: 0)
        textStorage.endEditing()
        self.set(selectedRange: selectedRange)
    }

    func insert(attachment: ViewAttachment, at index: Int) {
        guard
            let textView = self.textView,
            let textStorage = self.textStorage,
            let attachedView = attachment.attachedView else {
                return
        }
        attachedView.isHidden = true
        textView.addSubview(attachedView)
        self.attaches.append(attachment)

        textStorage.beginEditing()
        textStorage.replaceCharacters(in: NSRange.init(location: index, length: 0),
                                      with: ViewAttachmentTextContainerView.attachmentPlaceholderString)
        textStorage.addAttributes([.attachment: attachment,
                                   .font: self.font(),
                                   .paragraphStyle: self.paragraphStyle()],
                                  range: textStorage.editedRange)
        let location = textStorage.editedRange.location + textStorage.editedRange.length
        let selectedRange = NSRange.init(location: location, length: 0)
        textStorage.endEditing()
        self.set(selectedRange: selectedRange)
    }

    func remove(attachment removeAttachment : ViewAttachment) {
        guard let textStorage = self.textStorage else {
            return
        }
        textStorage.enumerateAttribute(
            .attachment,
            in: NSRange.init(location: 0, length: textStorage.length),
            options: .longestEffectiveRangeNotRequired) { (value, range, stop) in

                guard
                    let attachment = value as? ViewAttachment,
                    attachment === removeAttachment else {
                        return
                }
                textStorage.removeAttribute(.attachment, range: range)
                textStorage.replaceCharacters(in: range, with: "")
                attachment.attachedView?.removeFromSuperview()
                if let index = self.attaches.index(of: attachment) {
                    self.attaches.remove(at: index)
                }

                stop.pointee = true
        }
    }

    func remove(attachedView: UIView) {
        for attache in self.attaches where attache.attachedView === attachedView {
            self.remove(attachment: attache)
            break
        }
    }

    // MARK: - Private methods

    private func setup() {
        let container = NSTextContainer()
        container.widthTracksTextView = true
        self.textStorage = NSTextStorage(string: "", attributes: [.font: self.font(),
                                                                  .paragraphStyle: self.paragraphStyle()])
        self.textStorage?.addLayoutManager(self.manager)
        self.manager.addTextContainer(container)
        self.textView = UITextView(frame: self.bounds, textContainer: container)
        self.textView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.textView?.delegate = self
        self.textView?.font = self.font()
        if let textView = self.textView {
            self.addSubview(textView)
        }
    }

    private func font() -> UIFont {
        guard let font = self._font else {
            return UIFont.systemFont(ofSize: 18)
        }
        return font
    }

    private func paragraphStyle() -> NSParagraphStyle {
        guard let paragraphStyle = self._paragraphStyle else {
            let style = NSParagraphStyle.default
            self._paragraphStyle = style
            return style
        }
        return paragraphStyle
    }
}

extension ViewAttachmentTextContainerView: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return self.textViewDelegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return self.textViewDelegate?.textViewShouldEndEditing?(textView) ?? true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.textViewDelegate?.textViewDidBeginEditing?(textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.textViewDelegate?.textViewDidEndEditing?(textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        var shouldChange = true
        var attachments: [ViewAttachment] = []

        self.textStorage?.enumerateAttribute(
            .attachment,
            in: range,
            options: .longestEffectiveRangeNotRequired,
            using: { (value, range, stop) in
                guard let attachment = value as? ViewAttachment else {
                    return
                }
                attachments.append(attachment)
        })
        if !attachments.isEmpty {
            shouldChange = self.delegate?.attachmentTextContainerView(self, shouldDeleteAttachments: attachments) ?? true
        }

        if !shouldChange {
            return shouldChange
        }
        attachments = []
        self.textStorage?.enumerateAttribute(
            .attachment,
            in: range,
            options: .longestEffectiveRangeNotRequired,
            using: { (value, range, stop) in
                guard let attachment = value as? ViewAttachment else {
                    return
                }
                self.delegate?.attachmentTextContainerView(self, willDeleteAttachment: attachment)
                self.textStorage?.removeAttribute(.attachment, range: range)
                attachment.attachedView?.removeFromSuperview()
                self.delegate?.attachmentTextContainerView(self, didDeleteAttachment: attachment)
        })

        return shouldChange
    }

    func textViewDidChange(_ textView: UITextView) {
        self.textViewDelegate?.textViewDidChange?(textView)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        self.textViewDelegate?.textViewDidChangeSelection?(textView)
    }
}
