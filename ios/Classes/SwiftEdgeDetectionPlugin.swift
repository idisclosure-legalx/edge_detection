import Flutter
import UIKit

public class SwiftEdgeDetectionPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {
  
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "edge_detection", binaryMessenger: registrar.messenger())
    let instance = SwiftEdgeDetectionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if let viewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
        if (call.method == "edge_detect") {
            let destinationViewController = HomeViewController()
            destinationViewController._result = result
            viewController.present(destinationViewController,animated: true,completion: nil);
        }
        if (call.method == "edge_adjust") {
            let args = call.arguments as! Dictionary<String, Any>
            let originalImagePath = args["original_image_path"] as! String
            let quadTopLeft = args["quadrilateral_top_left"] as! Array<Double>
            let quadTopRight = args["quadrilateral_top_right"] as! Array<Double>
            let quadBottomRight = args["quadrilateral_bottom_right"] as! Array<Double>
            let quadBottomLeft = args["quadrilateral_bottom_left"] as! Array<Double>
            
            let imageUrl = URL.init(fileURLWithPath: originalImagePath)
            let imageData = try! Data(contentsOf: imageUrl)
            let image = UIImage(data: imageData)
            
            let quad = Quadrilateral(
                topLeft: CGPoint(x: quadTopLeft[0], y: quadTopLeft[1]),
                topRight: CGPoint(x: quadTopRight[0], y: quadTopRight[1]),
                bottomRight: CGPoint(x: quadBottomRight[0], y: quadBottomRight[1]),
                bottomLeft: CGPoint(x: quadBottomLeft[0], y: quadBottomLeft[1]))
            
            let destinationViewController = HomeViewController()
            destinationViewController._image = image
            destinationViewController._quad = quad
            destinationViewController._result = result
            viewController.present(destinationViewController,animated: true,completion: nil);
        }
    }
    
  }
}
