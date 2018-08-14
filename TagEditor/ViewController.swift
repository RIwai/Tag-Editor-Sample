//
//  ViewController.swift
//  TagEditor
//
//  Created by Ryota Iwai on 2018/08/14.
//  Copyright © 2018年 Ryota Iwai. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    @IBOutlet private weak var attachmentTextContainerView: ViewAttachmentTextContainerView! {
        didSet {
            self.attachmentTextContainerView.layer.cornerRadius = 8
            self.attachmentTextContainerView.clipsToBounds = true
            self.attachmentTextContainerView.delegate = self
            self.attachmentTextContainerView.textViewDelegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func insertButtonDidTap(_ sender: Any) {
        self.insertTag(tag: "タグって30分")
    }

    func insertTag(tag: String) {
        let attached = ViewAttachment(attachedView: self.loadTagView(tag: tag), placeholderText: "[Dummy TAG]")
        self.attachmentTextContainerView.insert(attachment: attached)
    }

    func replaceToTag(tag: String, range: Range<String.Index>) {
        let attached = ViewAttachment(attachedView: self.loadTagView(tag: tag), placeholderText: "[Dummy TAG]")
        self.attachmentTextContainerView.replace(to: attached, range: range)
    }

    func loadTagView(tag: String) -> TagView {
        let view = Bundle.main.loadNibNamed("TagView", owner: self, options: nil)!.first as! TagView
        view.configure(tagString: tag)
        view.delegate = self
        return view
    }
}

extension ViewController: ViewAttachmentTextContainerViewDelegate {}

extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let inputText = textView.text, !inputText.isEmpty else {
            return
        }
        let replacedString = inputText.replacingOccurrences(of: ViewAttachmentTextContainerView.attachmentPlaceholderString, with: "")
        guard !replacedString.isEmpty, replacedString.contains(" ") || replacedString.contains("\n") else {
            return
        }
        let components = replacedString.components(separatedBy: .whitespacesAndNewlines)
        components.forEach {
            guard
                !$0.isEmpty,
                $0 != ViewAttachmentTextContainerView.attachmentPlaceholderString,
                let range = textView.text.range(of: $0),
                range.upperBound.encodedOffset < inputText.count else {
                    return
            }
            self.replaceToTag(tag: $0, range: range)
        }
    }
}

extension ViewController: TagViewDelegate {
    func deleteDidTap(view: TagView) {
        self.attachmentTextContainerView.remove(attachedView: view)
    }
}
