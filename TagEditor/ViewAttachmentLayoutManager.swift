//
//  ViewAttachmentLayoutManager.swift
//  TagEditor
//
//  Created by Ryota Iwai on 2018/08/14.
//  Copyright © 2018年 Ryota Iwai. All rights reserved.
//

import Foundation
import UIKit

final class ViewAttachmentLayoutManager: NSLayoutManager {
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

        self.textStorage?.enumerateAttribute(
            .attachment,
            in: glyphsToShow,
            options: .longestEffectiveRangeNotRequired,
            using: { (value, range, stop) in
                guard
                    let attachment = value as? ViewAttachment,
                    let textContainer = self.textContainer(forGlyphAt: range.location, effectiveRange: nil),
                    let attachmentViewHeight = attachment.attachedView?.bounds.height else {
                        return
                }
                var rect = self.boundingRect(forGlyphRange: range,
                                             in: textContainer)
                rect.origin.x += origin.x
                rect.origin.y += origin.y + rect.height - attachmentViewHeight
                rect.size.height = attachmentViewHeight
                attachment.attachedView?.frame = rect
                attachment.attachedView?.isHidden = false
        })
    }
}
