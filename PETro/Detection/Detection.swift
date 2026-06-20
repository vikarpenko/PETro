//
//  Detection.swift
//  PETro
//
//  Created by Діана Цісарук on 17.06.2026.
//

import Combine
import CoreML
import UIKit
import Vision

struct Detection: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    let classIndex: Int
    let normRect: CGRect
    var trackId: Int? = nil
    var trail: [CGPoint] = []
}

class Detector: ObservableObject {
    private var mlModel: MLModel?
    private var vnModel: VNCoreMLModel?
    @Published var isReady = false

    let confThreshold: Float = 0.25

    let color: UIColor = UIColor(red: 1.0, green: 0.44, blue: 0.56, alpha: 1)

    static let cocoLabels = [
        "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train",
        "truck", "boat",
        "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
        "bird", "cat",
        "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe",
        "backpack",
        "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis",
        "snowboard", "sports ball",
        "kite", "baseball bat", "baseball glove", "skateboard", "surfboard",
        "tennis racket",
        "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl",
        "banana", "apple",
        "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut",
        "cake", "chair",
        "couch", "potted plant", "bed", "dining table", "toilet", "tv",
        "laptop", "mouse",
        "remote", "keyboard", "cell phone", "microwave", "oven", "toaster",
        "sink",
        "refrigerator", "book", "clock", "vase", "scissors", "teddy bear",
        "hair drier", "toothbrush",
    ]

    init() { loadModel() }

    private func loadModel() {
        DispatchQueue.global(qos: .userInitiated).async {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            guard let yoloModel = try? yolo26s(configuration: config)
            else {
                print("error in loading yolo26s model")
                return
            }
            
            let model = yoloModel.model
            let vn = try? VNCoreMLModel(for: model)
            
            DispatchQueue.main.async { [weak self] in
                self?.mlModel = model
                self?.vnModel = vn
                self?.isReady = true
            }
        }
    }

    var visionModel: VNCoreMLModel? { vnModel }

    func detect(pixelBuffer: CVPixelBuffer) -> [Detection] {
        guard let vnModel else { return [] }
        var result: [Detection] = []

        let request = VNCoreMLRequest(model: vnModel) { [weak self] req, _ in
            result = self?.parseResults(req) ?? []
        }
        request.imageCropAndScaleOption = .scaleFill
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            .perform([request])

        return result
    }

    func parseResults(_ req: VNRequest) -> [Detection] {
        guard let results = req.results as? [VNCoreMLFeatureValueObservation]
        else { return [] }
        var out: [Detection] = []

        for observation in results {
            guard let arr = observation.featureValue.multiArrayValue else {
                continue
            }
            let shape = arr.shape.map { $0.intValue }
            guard shape.count == 3 && shape[2] == 6 else { continue }
            for i in 0..<shape[1] {
                let conf = arr[[0, i, 4] as [NSNumber]].floatValue
                guard conf >= confThreshold else { continue }
                let x1 = CGFloat(arr[[0, i, 0] as [NSNumber]].floatValue) / 640
                let y1 = CGFloat(arr[[0, i, 1] as [NSNumber]].floatValue) / 640
                let x2 = CGFloat(arr[[0, i, 2] as [NSNumber]].floatValue) / 640
                let y2 = CGFloat(arr[[0, i, 3] as [NSNumber]].floatValue) / 640
                let cid = Int(arr[[0, i, 5] as [NSNumber]].floatValue)
                let label =
                    cid < Self.cocoLabels.count
                    ? Self.cocoLabels[cid] : "\(cid)"
                out.append(
                    Detection(
                        label: label,
                        confidence: conf,
                        classIndex: cid,
                        normRect: CGRect(
                            x: x1,
                            y: y1,
                            width: x2 - x1,
                            height: y2 - y1
                        )
                    )
                )
            }
        }
        return out
    }

}
