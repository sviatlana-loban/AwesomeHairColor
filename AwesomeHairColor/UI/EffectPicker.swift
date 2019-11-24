//
//  EffectPicker.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/24/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation
import UIKit

enum Effect: Int {
    case dark = 0
    case light = 1
}

protocol EffectPickerDelegate {
    func didSelectEffect(_ effect: Effect)
}

protocol EffectPicker {
    func addEffectPicker(to view: UIView)
    var effectPickerPresenterDelegate: EffectPickerDelegate? {get set}
    var effectPickerView: UIStackView? { get }
}

class EffectPickerViewPresenter: EffectPicker {

    var effectPickerView: UIStackView?
    var effectButtons = [UIButton]()
    var effectPickerPresenterDelegate: EffectPickerDelegate?
    var selectedEffect: Effect?

    func addEffectPicker(to view: UIView) {

        let height = UIScreen.main.bounds.height
        let width = UIScreen.main.bounds.width

        let darkEffect = UIButton()
        let softEffect = UIButton()

        effectButtons.append(softEffect)
        effectButtons.append(darkEffect)

        for button in effectButtons {
            button.backgroundColor = .lightGray
            button.setTitle("\(button)", for: .normal)
            button.setTitleColor(.darkGray, for: .normal)
            button.setTitleColor(.black, for: .selected)

            button.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 10.0
            //button.set
        }

        darkEffect.setTitle("Dark", for: .normal)
        softEffect.setTitle("Light", for: .normal)

        effectPickerView = UIStackView(arrangedSubviews: effectButtons)

        effectPickerView?.axis = .vertical
        effectPickerView?.frame = CGRect(x: width - 70, y: height/2 - 45, width: 60, height: 80)
        effectPickerView?.distribution = .fillEqually
        effectPickerView?.spacing = 10.0

        softEffect.isSelected = true

        darkEffect.addTarget(self, action: #selector(effectButtonTapped(_:)), for: .touchUpInside)
        softEffect.addTarget(self, action: #selector(effectButtonTapped(_:)), for: .touchUpInside)

        view.addSubview(effectPickerView!)
        view.bringSubviewToFront(effectPickerView!)
    }

    @objc func effectButtonTapped(_ button: UIButton) {
        guard let index = effectButtons.firstIndex(of: button),
              let effect = Effect(rawValue: index) else { return }

        for effectButton in effectButtons {
            effectButton.isSelected = false
        }
        button.isSelected = true
        effectPickerPresenterDelegate?.didSelectEffect(effect)
    }

}
