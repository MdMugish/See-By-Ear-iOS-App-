//
//  ViewController.swift
//  Vision
//
//  Created by mugish on 14/10/18.
//  Copyright © 2018 Softech. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState{
    case off
    case on
}
class CameraVC: UIViewController {

    var captureSession : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    var photoData : Data?
    
    var flashControlState : FlashState = .off

    var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashBtn: RoundedShadowBtn!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.spinner.isHidden = true
        
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) == true {
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        }catch{
            debugPrint(error)
        }
        
    }
    
    @objc func didTapCameraView(){
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        let settings = AVCapturePhotoSettings()
        
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashControlState == .off{
            settings.flashMode = .off
        }else{
            settings.flashMode = .on
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
        
    }
    
    
    func resultsMethod(request : VNRequest, error : Error?){
        
        guard let results = request.results as? [VNClassificationObservation] else { return }
        
        for classification in results{
            if classification.confidence < 0.5 {
                let unknownObjectMessage = "I am not sure what this is. Please try again."
                self.identificationLbl.text = unknownObjectMessage
                self.confidenceLbl.text = ""
                synthesizeSpeech(fromString: unknownObjectMessage)
                break
            } else{
                let identification = classification.identifier
                let confidence = Int(classification.confidence * 100)
                self.identificationLbl.text = identification
                self.confidenceLbl.text = "CONFIDENCE : \(confidence)%"
                synthesizeSpeech(fromString: "This looks like a \(identification) and I am \(confidence) persent sure.")
                break
            }
        }
        
    }
    
    //Any String we pass in this speek for us
    func synthesizeSpeech(fromString string:String){
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterance)
    }
    
    
    @IBAction func flaseBtnAction(_ sender: Any) {
        switch flashControlState {
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
        }
    }
}




extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        }else{
            photoData = photo.fileDataRepresentation()
            
            do{
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData! )
                
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
            
        }
    }
    
}


extension CameraVC : AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        //Code to finish utterance
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
}













