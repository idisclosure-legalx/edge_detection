import Flutter
import Foundation

class HomeViewController: UIViewController, ImageScannerControllerDelegate {
    var _image: UIImage?
    var _quad: Quadrilateral?
    var _result: FlutterResult?
    
    override func viewDidAppear(_ animated: Bool) {       

        if self.isBeingPresented {
            let scannerVC = ImageScannerController(canSelect: true, image: _image, quad: _quad, delegate: self)
            if #available(iOS 13.0, *) {
                scannerVC.isModalInPresentation = true
            }
            present(scannerVC, animated: true)
        }  
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error)
        _result!(nil)
        self.dismiss(animated: true)
    }    

    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        // Your ViewController is responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true) {
            let croppedImagePath = self.saveImage(image:results.croppedScan.image)
            let originalImagePath = self.saveImage(image: results.originalScan.image)
            self._result!([
                "cropped_image_path": croppedImagePath!,
                "original_image_path": originalImagePath!,
                "quadrilateral_top_left": [results.detectedRectangle.topLeft.x, results.detectedRectangle.topLeft.y],
                "quadrilateral_top_right": [results.detectedRectangle.topRight.x, results.detectedRectangle.topRight.y],
                "quadrilateral_bottom_right": [results.detectedRectangle.bottomRight.x, results.detectedRectangle.bottomRight.y],
                "quadrilateral_bottom_left": [results.detectedRectangle.bottomLeft.x, results.detectedRectangle.bottomLeft.y]
            ])
            
            self.dismiss(animated: true)
        }
    }
    

    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        // Your ViewController is responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
        _result!(nil)
        self.dismiss(animated: true)
    }
    

    func saveImage(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return nil
        }
        guard let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return nil
        }
        let fileName = randomString(length:10);
        let filePath: URL = directory.appendingPathComponent(fileName + ".png")!
        

        do {
            let fileManager = FileManager.default            

            // Check if file exists
            if fileManager.fileExists(atPath: filePath.path) {
                // Delete file
                try fileManager.removeItem(atPath: filePath.path)
            } else {
                print("File does not exist")
            }            

        }
        catch let error as NSError {
            print("An error took place: \(error)")
        }        

        do {
            try data.write(to: filePath)
            return filePath.path
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    

    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}
