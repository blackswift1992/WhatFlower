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
    @IBOutlet private weak var flowerImage: UIImageView!
    @IBOutlet private weak var flowerDescription: UILabel!
    
    private let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    private let imagePicker = UIImagePickerController()
    private var takenFlowerPhoto: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupImagePicker()
        customizeUIElements()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage,
           let ciImage = CIImage(image: image) {
            takenFlowerPhoto = image
            identifyFlower(photo: ciImage)
        }
        
        imagePicker.dismiss(animated: true)
    }
}


//MARK: - @IBActions
private extension ViewController {
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker , animated: true)
    }
}


//MARK: - Private methods

private extension ViewController {
    func identifyFlower(photo: CIImage) {
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: FlowerClassifier.urlOfModelInThisBundle)) else {
            fatalError("Loading CoreML Model failed")
        }
        
        let handler = VNImageRequestHandler(ciImage: photo)
        
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
    
    func requestInfo(flowerName: String) {
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
                
                self?.flowerImage.sd_setImage(with: URL(string: flowerImageURL))
                self?.flowerDescription.text = extract
            case .failure(let error):
                self?.flowerImage.image = self?.takenFlowerPhoto
                self?.flowerDescription.text = ""
                print(error)
            }
        }
    }
}


//MARK: - Set up methods

private extension ViewController {
    func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func customizeUIElements() {
        let backgroundImage = UIImageView(frame: view.bounds)
        backgroundImage.clipsToBounds = true
        backgroundImage.image = UIImage(named: "backgroundImage")
        backgroundImage.contentMode = .scaleToFill
        view.addSubview(backgroundImage)
        view.addSubview(flowerImage)
        view.addSubview(flowerDescription)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .specialGreen
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.title = "Take a picture!"

        flowerImage.layer.cornerRadius = 12.0
        flowerImage.clipsToBounds = true
    }
}
