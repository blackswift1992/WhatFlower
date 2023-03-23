//
//  ViewController.swift
//  WhatFlower
//
//  Created by Олексій Мороз on 23.03.2023.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet private weak var takenPhotoImageView: UIImageView!
    
    private let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            takenPhotoImageView.image = image
        }
        
        imagePicker.dismiss(animated: true)
    }
    
    
    @IBAction private func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker , animated: true)
    }
}

