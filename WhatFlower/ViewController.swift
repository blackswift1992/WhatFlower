//
//  ViewController.swift
//  WhatFlower
//
//  Created by Олексій Мороз on 23.03.2023.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet private weak var flowerPhoto: UIImageView! //takenPhotoImageView
    @IBOutlet private weak var flowerDescription: UILabel!
    
    private let imagePicker = UIImagePickerController()
    private let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupImagePicker()
        customizeUIElements()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage,
           let ciimage = CIImage(image: image) {
            identifyFlower(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true)
    }
    
    private func identifyFlower(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: FlowerClassifier.urlOfModelInThisBundle)) else {
            fatalError("Loading CoreML Model failed")
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        let request = VNCoreMLRequest(model: model) { [weak self] (request, error) in
            guard let identifiedFlower = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not identify image")
            }
            
            self?.navigationItem.title = identifiedFlower.identifier.capitalized
            self?.requestInfo(flowerName: identifiedFlower.identifier)
        }
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    private func requestInfo(flowerName: String) {
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "redirects" : "1",
          "titles" : flowerName,
          "indexpageids" : "",
          "pithumbsize" : "500" //pixels size for pageimage(s)
          ]

        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { [weak self] response in
            switch response.result {
            case .success(let flower):
                let flowerJSON = JSON(flower)
                let pageId = flowerJSON["query"]["pageids"][0].stringValue
                let extract = flowerJSON["query"]["pages"]["\(pageId)"]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"]["\(pageId)"]["thumbnail"]["source"].stringValue
                
                self?.flowerPhoto.sd_setImage(with: URL(string: flowerImageURL))
                self?.flowerDescription.text = extract
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    private func customizeUIElements() {
        navigationItem.title = "Take a picture!"
        
        flowerPhoto.layer.cornerRadius = 10.0
        flowerPhoto.clipsToBounds = true
    }
    
    @IBAction private func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker , animated: true)
    }
}

