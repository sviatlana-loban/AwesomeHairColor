//
//  Localize.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/24/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation

extension String {
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        return NSLocalizedString(self, tableName: tableName, value: self, comment: "")
    }
}
