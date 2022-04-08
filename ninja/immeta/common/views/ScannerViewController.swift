//
//  ScannerViewController.swift
//  immeta
//
//  Created by wesley on 2021/4/7.
//

import UIKit
import AVFoundation

protocol ScannerViewControllerDelegate {
        func codeDetected(code: String)
}
class ScannerViewController: UIViewController {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var delegate:ScannerViewControllerDelegate?
    
        var qrCodeFrameView: UIView?
        
        @IBOutlet weak var scanCubeView: UIView!
    override func viewDidLoad() {
                super.viewDidLoad()
                scanCubeView.layer.borderWidth = 2
                scanCubeView.layer.borderColor = UIColor.init(red: 59/255.0, green: 135/255.0, blue: 127/255.0, alpha: 1).cgColor
                captureSession = AVCaptureSession()

                guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
                let videoInput: AVCaptureDeviceInput
                do {
                        videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                } catch {
                        return
                }

                if (captureSession.canAddInput(videoInput)) {
                        captureSession.addInput(videoInput)
                } else {
                        failed()
                        return
                }

                let metadataOutput = AVCaptureMetadataOutput()

                if (captureSession.canAddOutput(metadataOutput)) {
                        captureSession.addOutput(metadataOutput)
                        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        metadataOutput.metadataObjectTypes = [.qr]
                } else {
                        failed()
                        return
                }

//                let v_f = self.view.layer.bounds.size

                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//                previewLayer.frame = CGRect(origin: CGPoint(x: 20,y: 20), size: CGSize(width:v_f.width - 40, height: v_f.height - 120))
                previewLayer.frame = view.layer.bounds
                previewLayer.videoGravity = .resizeAspectFill
                view.layer.insertSublayer(previewLayer, at: 0)

                captureSession.startRunning()
            
                qrCodeFrameView = UIView()
                
                if let qrcodeFrameView = qrCodeFrameView {
                    qrcodeFrameView.layer.borderColor = UIColor.yellow.cgColor
                    qrcodeFrameView.layer.borderWidth = 2
                    view.addSubview(qrcodeFrameView)
                    view.bringSubviewToFront(qrcodeFrameView)
                }
        }

        func failed() {
                let ac = UIAlertController(title: "Scanning not supported".locStr, message:
                                                "Your device does not support scanning a code from an item. Please use a device with a camera.".locStr,
                                           preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK".locStr, style: .default))
                present(ac, animated: true)
                captureSession = nil
        }

        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)

                if (captureSession?.isRunning == false) {
                        captureSession.startRunning()
                }
        }

        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)

                if (captureSession?.isRunning == true) {
                        captureSession.stopRunning()
                }
        }
    
        override var prefersStatusBarHidden: Bool {
                return true
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
                return .portrait
        }
        
        @IBAction func ImportPhotoBtn(_ sender: UIButton) {
                let vc = UIImagePickerController()
                vc.sourceType = .photoLibrary
                vc.delegate = self
                vc.allowsEditing = false
                self.present(vc, animated: true, completion: nil)
        }
    
        @IBAction func Cancel(_ sender: Any) {
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

                if #available(iOS 13.0, *) {
                        picker.navigationBar.barTintColor = .systemBackground
                }
                picker.dismiss(animated: true, completion: nil)
                let qrcodeImg = (info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as? UIImage)!


                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
                let ciImage = CIImage(image: qrcodeImg)!

                let features = detector.features(in: ciImage) as? [CIQRCodeFeature]
                var codeStr = ""

                for feature in features! {
                        codeStr += feature.messageString!
                }
                
                self.dismiss(animated: true) {
                        self.delegate?.codeDetected(code: codeStr)
                }
        }
    
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true, completion: nil)
        }
    
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
                captureSession.stopRunning()

                if let metadataObject = metadataObjects.first {
                        guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                        guard let stringValue = readableObject.stringValue else { return }
                        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

                        self.delegate?.codeDetected(code: stringValue)
                }
                dismiss(animated: true)
        }

}
