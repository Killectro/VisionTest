//
//  ViewController.swift
//  CoreMLTest
//
//  Created by DJ Mitchell on 6/6/17.
//  Copyright © 2017 DJ Mitchell. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let imageView: UIImageView = {
        let image = UIImage(named: "michelle.jpg")
        let imageView = UIImageView(image: image)

        imageView.contentMode = .scaleAspectFill

        return imageView
    }()

    override func loadView() {
        super.loadView()

        view.addSubview(imageView)
        imageView.frame = view.bounds
        print(imageView.frame)
        view.backgroundColor = .red
    }
}

