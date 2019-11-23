//
//  UIImageExtension.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/22/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

    func convert(ciImage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}
