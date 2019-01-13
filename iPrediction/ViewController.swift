//
//  ViewController.swift
//  iPrediction
//
//  Created by lucas on 06/01/2019.
//  Copyright © 2019 lucas. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate,AVCapturePhotoCaptureDelegate {
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var photoCheckImage: UIImageView!
    @IBOutlet weak var predictionLbl: UILabel!
    @IBOutlet weak var rotationBtn: UIButton!
    @IBOutlet weak var takeLib: UIButton!
    @IBOutlet weak var takePhotoBtn: UIButton!
    private var captureSession : AVCaptureSession?
    private var takePhotoOutput : AVCapturePhotoOutput?
    private var takeVideoPreviewLayer : AVCaptureVideoPreviewLayer?
    private var position = AVCaptureDevice.Position.back
    private var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
         photoCheckImage.layer.cornerRadius = 100
        
        self.initView()
    }
    func request(data: Data) {
        do{
            let coreML = try VNCoreMLModel(for: MobileNet().model)
            let request = VNCoreMLRequest(model: coreML, completionHandler: response)
            let requestHandler = VNImageRequestHandler(data: data)
            try requestHandler.perform([request])
        }catch {
            print(error.localizedDescription)
        }
    }
    func response(_ request: VNRequest, _ error: Error?) {
        if let result = request.results as? [VNClassificationObservation] {
            let resltats = result.sorted(by: {$0.confidence > $1.confidence})
            if resltats.count > 0 {
                let meilleurResultat = resltats[0]
                let attributed = NSMutableAttributedString(string: meilleurResultat.identifier, attributes: [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor : UIColor.red])
                let pourcentage = Int(meilleurResultat.confidence * 100)
                let confianceString = "\n Je suis sur à "+String(pourcentage)+"%"
                attributed.append(NSAttributedString(string: confianceString, attributes: [.font: UIFont.boldSystemFont(ofSize: 17), .foregroundColor : UIColor.black]))
                predictionLbl.attributedText = attributed
            }
            
        }
    }
    func initView() {
       
        rotationBtn.layer.cornerRadius = 5
        takeLib.layer.cornerRadius = 5
        takeVideoPreviewLayer?.removeFromSuperlayer()
        captureSession = AVCaptureSession()
        if captureSession != nil {
            if let camera = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: position){
                do{
                    let input = try AVCaptureDeviceInput(device: camera)
                    if captureSession!.canAddInput(input) {
                        captureSession!.addInput(input)
                        takePhotoOutput = AVCapturePhotoOutput()
                        if takePhotoOutput != nil {
                            if captureSession!.canAddOutput(takePhotoOutput!){
                                captureSession!.addOutput(takePhotoOutput!)
                                takeVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                                takeVideoPreviewLayer?.videoGravity = .resizeAspectFill
                                takeVideoPreviewLayer?.connection?.videoOrientation = .portrait
                                if takeVideoPreviewLayer != nil {
                                    takeVideoPreviewLayer?.frame = cameraView.bounds
                                    cameraView.layer.addSublayer(takeVideoPreviewLayer!)
                                    captureSession?.startRunning()
                                }
                                
                            }
                        }
                    }
                }catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            if let data = photo.fileDataRepresentation(){
                photoCheckImage.image = UIImage(data: data)
                request(data: data)
            }else {
                print("Le resultat obteni n'est donnée pas le data")
            }
        }else {
            print(error!.localizedDescription)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
       if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            photoCheckImage.image = image
           if let data = UIImagePNGRepresentation(image){
               self.request(data: data)
           }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func avSetting() -> AVCapturePhotoSettings {
        let mSetting = AVCapturePhotoSettings()
        mSetting.previewPhotoFormat = mSetting.embeddedThumbnailPhotoFormat
        return mSetting
        
    }
    @IBAction func onClickTackPhoto(_ sender: Any) {
        if takePhotoOutput != nil {
            takePhotoOutput?.capturePhoto(with: avSetting(), delegate: self)
        }
    }
    @IBAction func onClickChange(_ sender: Any) {
      imagePicker.allowsEditing = false
      imagePicker.sourceType = .photoLibrary
      present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func onClickPhotoLibrarie(_ sender: Any) {
        switch position {
        case .front: position = .back
        case .back: position = .front
        case .unspecified: position = .back
        }
        self.initView()
    }

}

