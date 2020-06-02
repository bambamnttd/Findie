//
//  QRScannerViewController.swift
//  thesisApp
//
//  Created by Bambam on 26/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

struct QRData {
    var codeString: String?
}

extension QRScannerViewController: AddPointDelegate {
    func addPoint(add: Bool) {
        self.add = add
        print(self.add)
    }
}

class QRScannerViewController: UIViewController {
    
    @IBOutlet weak var text: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var scannerView: QRScannerView! {
        didSet {
            scannerView.delegate = self
        }
    }
    
    var add = false
    var cardData : CardCafeListData!
    var qrData: QRData? = nil {
        didSet {
            if qrData?.codeString == "thesisApp" {
                let addRewardVC = storyboard?.instantiateViewController(withIdentifier: "AddRewardVC") as! AddRewardViewController
                addRewardVC.cardData = cardData
                addRewardVC.qrData = self.qrData
                addRewardVC.delegate = self
                self.present(addRewardVC, animated: true)
                //self.performSegue(withIdentifier: "addRewardScreen", sender: self)
            }
            else {
                qrScanningDidFail()
                print(qrData?.codeString as! String)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(cardData.cafename_en) หน้าสแกน")
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        text.text = "สแกน QR code เพื่อสะสมแต้มให้ลูกค้า\n\nสำหรับพนักงานเท่านั้น*"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("เข้าหรือไม่ \(add)")
        if add == true {
            dismiss(animated: true, completion: nil)
            add = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !scannerView.isRunning {
            scannerView.startScanning()
        }
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
    }
    
    ///เปลี่ยนให้ StatusBar เป็นตีมขาว หรือดำ
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent  //เปลี่ยนเป็นตีมขาว
    }
    
    @objc func close() {
        performSegueToReturnBack()
    }
    
    func presentAlert(withTitle title: String, message : String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            self.scannerView.startScanning()
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }

}

extension QRScannerViewController: QRScannerViewDelegate {
    
    func qrScanningDidFail() {
        presentAlert(withTitle: "Error", message: "Scanning Failed. Please try again")
    }
    
    func qrScanningSucceededWithCode(_ str: String?) {
        self.qrData = QRData(codeString: str)
    }
}

extension QRScannerViewController {
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "addRewardScreen", let addRewardVC = segue.destination as? AddRewardViewController {
//            addRewardVC.qrData = self.qrData
//        }
//    }
}

//class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
//
//    var video = AVCaptureVideoPreviewLayer()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        print("thesisApp Would Like to Access the Camera")
//        scanner()
//    }
//
//    func scanner() {
//        //create session
//        let session = AVCaptureSession()
//
//        //define capture device
//        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
//        do {
//            let input = try AVCaptureDeviceInput(device: captureDevice!)
//            session.addInput(input)
//        }
//        catch {
//            print("Error")
//        }
//        let output = AVCaptureMetadataOutput()
//        session.addOutput(output)
//
//        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
//        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
//
//        video = AVCaptureVideoPreviewLayer(session: session)
//        video.frame = view.layer.bounds
//        view.layer.addSublayer(video)
//
//        session.startRunning()
//    }
//
//    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//        if metadataObjects != nil && metadataObjects.count != 0 {
//            if let object = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
//                if object.type == AVMetadataObject.ObjectType.qr {
//                    let alert = UIAlertController(title: "OR Code", message: object.stringValue, preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
//
//                    self.present(alert, animated: true)
//                    if object.stringValue == "thesisApp" {
//                        print("bambam")
//                    }
//                }
//            }
//        }
//    }
//}
