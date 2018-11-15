//
//  ViewController.swift
//  GiferExample
//
//  Created by Vladyslav Yakovlev on 11/13/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import Gifer
import MobileCoreServices

final class ViewController: UIViewController {
    
    private let imagePicker = UIImagePickerController()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 216, height: 80)
        button.setTitle("Create GIF", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel!.font = UIFont(name: "AvenirNext-Bold", size: 21)
        button.layer.cornerRadius = button.frame.height/2
        button.layer.shadowPath = UIBezierPath(roundedRect: button.bounds, cornerRadius: button.layer.cornerRadius).cgPath
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 0.14
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = .zero
        button.backgroundColor = .white
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        layoutViews()
    }

    private func setupViews() {
        view.backgroundColor = .white
        
        imagePicker.delegate = self
        
        view.addSubview(createButton)
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
    }
    
    private func layoutViews() {
        createButton.center = view.center
    }
    
    @objc private func createButtonTapped() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [kUTTypeMovie] as [String]
            imagePicker.allowsEditing = true
            present(imagePicker, animated: true)
        }
    }
    
    private func createGifFromVideo(_ videoUrl: URL) {
        createButton.setTitle("Process...", for: .normal)
        createButton.isUserInteractionEnabled = false
        Gifer.createGifFromVideo(videoUrl, frameRate: 10, loopCount: 0, startTime: 0, size: CGSize(width: 700, height: 700)) { gifUrl, error in
            guard let url = gifUrl else { return }
            self.createButton.isUserInteractionEnabled = true
            self.createButton.setTitle("Create GIF", for: .normal)
            self.showGifPreview(with: url)
        }
    }
    
    private func showGifPreview(with url: URL) {
        let previewVC = GifPreviewVC()
        previewVC.gifUrl = url
        present(previewVC, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            picker.dismiss(animated: true)
            createGifFromVideo(videoUrl)
        }
    }
}

