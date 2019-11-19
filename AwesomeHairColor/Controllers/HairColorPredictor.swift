//
//  HairColorPredictor.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/10/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation
import UIKit
import Fritz

protocol HairColorPredictor: class {

  var visionModel: FritzVisionHairSegmentationModelFast { get }
  var color: HairColor! { get set }
}

struct HairColor {
  var hairColor: UIColor
}

extension HairColorPredictor {

  func predict(with src: FritzVisionImage) -> UIImage? {
    guard let result = try? visionModel.predict(src),
      let mask = result.buildSingleClassMask(
        forClass: FritzVisionHairClass.hair,
        clippingScoresAbove: clippingScoresAbove,
        zeroingScoresBelow: zeroingScoresBelow,
        resize: false,
        color: maskColor)
      else { return nil }

    let blended = src.blend(
      withMask: mask,
      blendKernel: blendKernel,
      opacity: opacity
    )

    return blended
  }
}

extension HairColorPredictor {
  /// Scores output from model greater than this value will be set as 1.
  /// Lowering this value will make the mask more intense for lower confidence values.
  var clippingScoresAbove: Double { return 0.7 }

  /// Values lower than this value will not appear in the mask.
  var zeroingScoresBelow: Double { return 0.3 }

  /// Controls the opacity the mask is applied to the base image.
  var opacity: CGFloat { return 0.7 }

  /// The method used to blend the hair mask with the underlying image.
  /// Soft light produces the best results in our tests, but check out
  /// .hue and .color for different effects.
  var blendKernel: CIBlendKernel { return .softLight }

  /// Color of the mask.
  var maskColor: UIColor {
    get { return color.hairColor }
    set { color.hairColor = newValue }
  }
}
