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
        let colorList = [
                         "#0000ff",
                         "#00ced1",
                         "#00ff00",
                         "#00ffff",
                         "#660066",
                         "#800000",
                         "#8a2be2",
                         "#bada55",
                         "#c0d6e4",
                         "#d3ffce",
                         "#daa520",
                         "#e6e6fa",
                         "#faebd7",
                         "#ff0000",
                         "#ff7373",
                         "#ff80ed",
                         "#ffa500",
                         "#ffff66"]

        var uicolors = Array<UIColor>()
        for colorString in colorList {
            let color = UIColor.hexStringToUIColor(hex: colorString)
            uicolors.append(color)
        }
        return uicolors
    }
}
