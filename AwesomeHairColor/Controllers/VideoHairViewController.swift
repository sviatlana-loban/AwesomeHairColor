//
//  VideoHairViewController.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/10/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import UIKit

class VideoHairViewController: UIViewController {

    var photoLibraryPicker: PhotoLibraryPicker?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.photoLibraryPicker = PhotoLibraryPicker(presentationController: self, delegate: self)
        self.photoLibraryPicker?.present(from: view)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension VideoHairViewController: PhotoLibraryPickerDelegate {
    func didSelect(url: URL?) {
        print(url)
    }

}
