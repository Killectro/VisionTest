//
//  ViewController.swift
//  CoreMLTest
//
//  Created by DJ Mitchell on 6/6/17.
//  Copyright © 2017 DJ Mitchell. All rights reserved.
//

import UIKit
import Vision

final class ViewController: UIViewController {

    private var image = #imageLiteral(resourceName: "michelle") {
        didSet {
            DispatchQueue.main.async {
                self.imageView.image = self.image
            }
        }
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: self.image)

        imageView.contentMode = .scaleAspectFill

        return imageView
    }()

    private var faceRect: CGRect = .zero

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imageView)
        imageView.frame = view.bounds

        performFaceFeatureRequests()
    }
}

private extension ViewController {

    func performFaceFeatureRequests() {
        guard let cgImage = image.cgImage else {
            fatalError("Invalid image")
        }

        let request = VNDetectFaceLandmarksRequest { [unowned self] request, err in
            guard err == nil else {
                print(err!)
                return
            }

            guard let result = request.results?.first as? VNFaceObservation,
                let landmarks = result.landmarks else {
                return
            }

            self.image = self.imageWith(size: self.image.size, style: { ctx in
                // The origin of the bounding box starts at the bottom left, so we need to account for that
                self.faceRect = self.rect(fromRelative: result.boundingBox, size: self.image.size)

                ctx.setStrokeColor(UIColor.yellow.cgColor)
                ctx.stroke(self.faceRect, width: 2.5)
            })!

            let pointsArray = self.normalizedPointsFrom(landmarks: landmarks)

            self.image = self.imageWith(size: self.image.size, style: { ctx in
                ctx.setStrokeColor(UIColor.red.cgColor)
                ctx.setLineWidth(2.0)

                for points in pointsArray {
                    ctx.beginPath()
                    ctx.addLines(between: points)
                    ctx.strokePath()
                }
            })!
        }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private func imageWith(size: CGSize, style: (CGContext) -> Void) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        self.image.draw(at: .zero)

        style(ctx)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func rectCenteredOn(relativePoint: vector_float2) -> CGRect {
        let pointDimension: CGFloat = 0.0075
        let pointHalfDimension: CGFloat = pointDimension / 2.0
        let relativePoint = CGPoint(x: CGFloat(relativePoint.x), y: CGFloat(relativePoint.y))

        return CGRect(
            x: relativePoint.x - pointHalfDimension,
            y: relativePoint.y - pointHalfDimension,
            width: pointDimension,
            height: pointDimension
        )
    }

    func rect(fromRelative boundingBox: CGRect, size: CGSize) -> CGRect {
        var rect = CGRect(
            x: boundingBox.origin.x * size.width,
            y: size.height - boundingBox.origin.y * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )

        rect.origin.y -= rect.height

        return rect
    }

    /// Returns a list of list of CGPoint objects that represents a collection of landmark points
    func normalizedPointsFrom(landmarks: VNFaceLandmarks2D) -> [[CGPoint]] {
        return [
            landmarks.faceContour,
            landmarks.leftEye,
            landmarks.rightEye,
            landmarks.leftEyebrow,
            landmarks.rightEyebrow,
            landmarks.nose,
            landmarks.noseCrest,
            landmarks.medianLine,
            landmarks.outerLips,
            landmarks.innerLips,
            landmarks.leftPupil,
            landmarks.rightPupil
        ].flatMap { $0 }
            .map { landmarkRegion in
                return (0 ..< landmarkRegion.pointCount)
                    .map { landmarkRegion.point(at: $0) }
                    .map { self.rectCenteredOn(relativePoint: $0) }
                    .map { rect -> CGRect in
                        var newRect = self.rect(fromRelative: rect, size: self.faceRect.size)
                        newRect.origin.x += self.faceRect.origin.x
                        newRect.origin.y += self.faceRect.origin.y

                        return newRect
                    }
                    .map { CGPoint(x: $0.midX, y: $0.midY) }
        }
    }
}
