//
//  URLExtension.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/10/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation
import MobileCoreServices

extension URL {
    var isImage: Bool {
        let fileExtension = self.pathExtension
        if !fileExtension.isEmpty {
            let cfFileExtension: CFString = fileExtension as NSString
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, cfFileExtension, nil)?.takeRetainedValue() {
                return UTTypeConformsTo(uti, kUTTypeImage)
            }
        }
        return false
    }

    var isMovie: Bool {
        let fileExtension = self.pathExtension
        if !fileExtension.isEmpty {
            let cfFileExtension: CFString = fileExtension as NSString
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, cfFileExtension, nil)?.takeRetainedValue() {
                return UTTypeConformsTo(uti, kUTTypeMovie)
            }
        }
        return false
    }
}
