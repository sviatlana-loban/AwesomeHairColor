//
//  FileService.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/23/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation

final class FileService {
    static func getFileUrl() -> URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd-HH-mm-ss"
        let date = dateFormatter.string(from: Date())

        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
        checkForAndDeleteFile(at: url)
        return url
    }

    static func checkForAndDeleteFile(at url: URL) {
        let fm = FileManager.default
        let exist = fm.fileExists(atPath: url.path)

        if exist {
            do {
                try fm.removeItem(at: url as URL)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
}
