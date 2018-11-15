//
//  GifPreviewVC.swift
//  GiferExample
//
//  Created by Vladyslav Yakovlev on 11/15/18.
//  Copyright © 2018 Vladyslav Yakovlev. All rights reserved.
//

import Gifu

final class GifPreviewVC: UIViewController {
    
    var gifUrl: URL!
    
    private let gifView = GIFImageView()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 43, height: 43)
        button.setImage(UIImage(named: "CloseIcon"), for: .normal)
        button.layer.cornerRadius = button.frame.height/2
        button.layer.shadowPath = UIBezierPath(roundedRect: button.bounds, cornerRadius: button.layer.cornerRadius).cgPath
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowOpacity = 0.26
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
        
        view.addSubview(gifView)
        gifView.contentMode = .scaleAspectFit
        gifView.animate(withGIFURL: gifUrl)
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func layoutViews() {
        gifView.frame = view.bounds
        
        closeButton.frame.origin.x = view.frame.width - closeButton.frame.width - 20
        closeButton.frame.origin.y = currentDevice == .iPhoneX ? 20 + 30 : 20
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
