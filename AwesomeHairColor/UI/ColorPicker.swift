//
//  ColorPicker.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/14/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation
import UIKit
import IGColorPicker

protocol ColorPickerDelegate {
    func didSelectColor(_ color: UIColor)
}

protocol ColorPicker {
    func addColorPicker(to view: UIView)
    var pickerPresenterDelegate: ColorPickerDelegate? {get set}
}

class ColorPickerViewPresenter: ColorPicker {
    var colorPickerView: ColorPickerView?
    var pickerPresenterDelegate: ColorPickerDelegate?
    var selectedColor: UIColor?

    func addColorPicker(to view: UIView) {

        let height = UIScreen.main.bounds.height
        let width = UIScreen.main.bounds.width

        colorPickerView = ColorPickerView(frame: CGRect(x: 0.0, y: height - 30 - height/14.0, width: width, height: height/14.0))

        colorPickerView?.layoutDelegate = self
        colorPickerView?.delegate = self
        colorPickerView?.colors = getColorsList()
        view.addSubview(colorPickerView!)
        view.bringSubviewToFront(colorPickerView!)
    }

}

// MARK: - ColorPickerViewDelegate
extension ColorPickerViewPresenter: ColorPickerViewDelegate {

    func colorPickerView(_ colorPickerView: ColorPickerView, didSelectItemAt indexPath: IndexPath) {
        pickerPresenterDelegate?.didSelectColor(colorPickerView.colors[indexPath.item])
    }

}

// MARK: - ColorPickerViewDelegateFlowLayout
extension ColorPickerViewPresenter: ColorPickerViewDelegateFlowLayout {

    func colorPickerView(_ colorPickerView: ColorPickerView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = UIScreen.main.bounds.height/15.0
        return CGSize(width: size, height: size)
    }

    func colorPickerView(_ colorPickerView: ColorPickerView, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }

    func colorPickerView(_ colorPickerView: ColorPickerView, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    func colorPickerView(_ colorPickerView: ColorPickerView, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
}

extension ColorPickerViewPresenter {
    func getColorsList() -> [UIColor] {
        let colorList = ["#000000",
                         "#000080",
                         "#0000ff",
                         "#003366",
                         "#008000",
                         "#008080",
                         "#00ced1",
                         "#00ff00",
                         "#00ff7f",
                         "#00ffff",
                         "#065535",
                         "#088da5",
                         "#0e2f44",
                         "#101010",
                         "#133337",
                         "#20b2aa",
                         "#333333",
                         "#3399ff",
                         "#40e0d0",
                         "#420420",
                         "#468499",
                         "#4ca3dd",
                         "#5ac18e",
                         "#660066",
                         "#666666",
                         "#66cccc",
                         "#66cdaa",
                         "#6897bb",
                         "#696969",
                         "#794044",
                         "#7fe5f0",
                         "#7fffd4",
                         "#800000",
                         "#800080",
                         "#808080",
                         "#81d8d0",
                         "#8a2be2",
                         "#8b0000",
                         "#990000",
                         "#a0db8e",
                         "#afeeee",
                         "#b0e0e6",
                         "#b4eeb4",
                         "#b6fcd5",
                         "#bada55",
                         "#c0c0c0",
                         "#c0d6e4",
                         "#c39797",
                         "#c6e2ff",
                         "#cbbeb5",
                         "#cccccc",
                         "#ccff00",
                         "#d3ffce",
                         "#daa520",
                         "#dcedc1",
                         "#dddddd",
                         "#e6e6fa",
                         "#eeeeee",
                         "#f08080",
                         "#f0f8ff",
                         "#f5f5dc",
                         "#f5f5f5",
                         "#f6546a",
                         "#f7347a",
                         "#fa8072",
                         "#faebd7",
                         "#ff0000",
                         "#ff00ff",
                         "#ff4040",
                         "#ff6666",
                         "#ff7373",
                         "#ff7f50",
                         "#ff80ed",
                         "#ffa500",
                         "#ffb6c1",
                         "#ffc0cb",
                         "#ffc3a0",
                         "#ffd700",
                         "#ffdab9",
                         "#ffe4e1",
                         "#fff68f",
                         "#ffff00",
                         "#ffff66",
                         "#ffffff"]

        var uicolors = Array<UIColor>()
        for colorString in colorList {
            let color = UIColor.hexStringToUIColor(hex: colorString)
            uicolors.append(color)
        }
        return uicolors
    }
}
