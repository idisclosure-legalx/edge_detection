//
//  ScannerViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import AVFoundation

/// The `ScannerViewController` offers an interface to give feedback to the user regarding quadrilaterals that are detected. It also gives the user the opportunity to capture an image with a detected rectangle.
public final class ScannerViewController: UIViewController {
    
    private var canSelectPhoto = false;
    private var captureSessionManager: CaptureSessionManager?
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    /// The view that shows the focus rectangle (when the user taps to focus, similar to the Camera app)
    private var focusRectangle: FocusRectangleView!
    
    /// The view that draws the detected rectangles.
    private let quadView = QuadrilateralView()
        
    /// Whether flash is enabled
    private var flashEnabled = false
    
    /// The original bar style that was set by the host app
    private var originalBarStyle: UIBarStyle?
    
    private lazy var shutterButton: ShutterButton = {
        let button = ShutterButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("wescan.scanning.cancel", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Cancel", comment: "The cancel button"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelImageScannerController), for: .touchUpInside)
        return button
    }()
    
    lazy var selectPhotoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "gallery", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        return button
    }()
    
    private lazy var autoScanButton: UIBarButtonItem = {
        let title = NSLocalizedString("wescan.scanning.auto", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Auto", comment: "The auto button state")
        let button = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(toggleAutoScan))
        button.tintColor = .white
        
        return button
    }()
    
    private lazy var flashButton: UIBarButtonItem = {
        let image = UIImage(systemName: "bolt.fill", named: "flash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleFlash))
        button.tintColor = .white
        
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    // MARK: - Life Cycle
    
    init(canSelectPhoto: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.canSelectPhoto = canSelectPhoto
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        title = nil
        view.backgroundColor = UIColor.black
        
        setupViews()
        setupNavigationBar()
        setupConstraints()
        
        captureSessionManager = CaptureSessionManager(videoPreviewLayer: videoPreviewLayer, delegate: self)
        
        originalBarStyle = navigationController?.navigationBar.barStyle
        
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        
        CaptureSession.current.isEditing = false
        quadView.removeQuadrilateral()
        captureSessionManager?.start()
        UIApplication.shared.isIdleTimerDisabled = true
        
        navigationController?.navigationBar.barStyle = .blackTranslucent
        if canSelectPhoto { selectPhotoButton.isHidden = false }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        videoPreviewLayer.frame = view.layer.bounds
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanup()
    }
    
    public func cleanup() {
        UIApplication.shared.isIdleTimerDisabled = false
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = originalBarStyle ?? .default
        captureSessionManager?.stop()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        if device.torchMode == .on {
            toggleFlash()
        }
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        view.backgroundColor = .darkGray
        view.layer.addSublayer(videoPreviewLayer)
        quadView.translatesAutoresizingMaskIntoConstraints = false
        quadView.editable = false
        view.addSubview(quadView)
        view.addSubview(cancelButton)
        view.addSubview(shutterButton)
        if canSelectPhoto {
            view.addSubview(selectPhotoButton)
        }
        view.addSubview(activityIndicator)
    }
    
    private func setupNavigationBar() {
        navigationItem.setLeftBarButton(flashButton, animated: false)
        navigationItem.setRightBarButton(autoScanButton, animated: false)
        
        if UIImagePickerController.isFlashAvailable(for: .rear) == false {
            let flashOffImage = UIImage(systemName: "bolt.slash.fill", named: "flashUnavailable", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
            flashButton.image = flashOffImage
            flashButton.tintColor = UIColor.lightGray
        }
    }
    
    private func setupConstraints() {
        var quadViewConstraints = [NSLayoutConstraint]()
        var cancelButtonConstraints = [NSLayoutConstraint]()
        var shutterButtonConstraints = [NSLayoutConstraint]()
        var activityIndicatorConstraints = [NSLayoutConstraint]()
        var selectPhotoButtonConstraints = [NSLayoutConstraint]()
        
        quadViewConstraints = [
            quadView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: quadView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: quadView.trailingAnchor),
            quadView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ]
        
        shutterButtonConstraints = [
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.widthAnchor.constraint(equalToConstant: 65.0),
            shutterButton.heightAnchor.constraint(equalToConstant: 65.0)
        ]
        
        activityIndicatorConstraints = [
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]
        
        if #available(iOS 11.0, *) {
            if canSelectPhoto {
                selectPhotoButtonConstraints = [
                    selectPhotoButton.widthAnchor.constraint(equalToConstant: 44.0),
                    selectPhotoButton.heightAnchor.constraint(equalToConstant: 44.0),
                    selectPhotoButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -24.0),
                    view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: selectPhotoButton.bottomAnchor, constant: (65.0 / 2) - 10.0)
                ]
            }
            cancelButtonConstraints = [
                cancelButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 24.0),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: (65.0 / 2) - 10.0)
            ]
            
            let shutterButtonBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 8.0)
            shutterButtonConstraints.append(shutterButtonBottomConstraint)
        } else {
            if canSelectPhoto {
                selectPhotoButtonConstraints = [
                    selectPhotoButton.widthAnchor.constraint(equalToConstant: 44.0),
                    selectPhotoButton.heightAnchor.constraint(equalToConstant: 44.0),
                    selectPhotoButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24.0),
                    view.bottomAnchor.constraint(equalTo: selectPhotoButton.bottomAnchor, constant: (65.0 / 2) - 10.0)
                ]
            }
            cancelButtonConstraints = [
                cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24.0),
                view.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: (65.0 / 2) - 10.0)
            ]
            
            let shutterButtonBottomConstraint = view.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 8.0)
            shutterButtonConstraints.append(shutterButtonBottomConstraint)
        }
        
        NSLayoutConstraint.activate(quadViewConstraints + cancelButtonConstraints + selectPhotoButtonConstraints + shutterButtonConstraints + activityIndicatorConstraints)
    }
    
    // MARK: - Tap to Focus
    
    /// Called when the AVCaptureDevice detects that the subject area has changed significantly. When it's called, we reset the focus so the camera is no longer out of focus.
    @objc private func subjectAreaDidChange() {
        /// Reset the focus and exposure back to automatic
        do {
            try CaptureSession.current.resetFocusToAuto()
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }
        
        /// Remove the focus rectangle if one exists
        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: true)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard  let touch = touches.first else { return }
        let touchPoint = touch.location(in: view)
        let convertedTouchPoint: CGPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: false)
        
        focusRectangle = FocusRectangleView(touchPoint: touchPoint)
        view.addSubview(focusRectangle)
        
        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager = captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }
    }
    
    // MARK: - Actions
    
    @objc private func captureImage(_ sender: UIButton) {
        (navigationController as? ImageScannerController)?.flashToBlack()
        shutterButton.isUserInteractionEnabled = false
        captureSessionManager?.capturePhoto()
    }
    
    @objc public func toggleAutoScan() {
        if CaptureSession.current.isAutoScanEnabled {
            CaptureSession.current.isAutoScanEnabled = false
            autoScanButton.title = NSLocalizedString("wescan.scanning.manual", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Manual", comment: "The manual button state")
        } else {
            CaptureSession.current.isAutoScanEnabled = true
            autoScanButton.title = NSLocalizedString("wescan.scanning.auto", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Auto", comment: "The auto button state")
        }
    }
    
    @objc private func toggleFlash() {
        let state = CaptureSession.current.toggleFlash()
        
        let flashImage = UIImage(systemName: "bolt.fill", named: "flash", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let flashOffImage = UIImage(systemName: "bolt.slash.fill", named: "flashUnavailable", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        
        switch state {
        case .on:
            flashEnabled = true
            flashButton.image = flashImage
            flashButton.tintColor = .yellow
        case .off:
            flashEnabled = false
            flashButton.image = flashImage
            flashButton.tintColor = .white
        case .unknown, .unavailable:
            flashEnabled = false
            flashButton.image = flashOffImage
            flashButton.tintColor = UIColor.lightGray
        }
    }
    
    @objc private func cancelImageScannerController() {
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(imageScannerController)
    }
    
    @objc private func selectPhoto() {
        if CaptureSession.current.isAutoScanEnabled {
            toggleAutoScan()
        }
        selectPhotoButton.isHidden = true
        if let imageScannerController = navigationController as? ImageScannerController {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = imageScannerController
            imagePicker.sourceType = .photoLibrary
            imageScannerController.present(imagePicker, animated: true)
        }
    }
    
}

extension ScannerViewController: RectangleDetectionDelegateProtocol {
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didFailWithError error: Error) {
        
        activityIndicator.stopAnimating()
        shutterButton.isUserInteractionEnabled = true
        
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
    }
    
    func didStartCapturingPicture(for captureSessionManager: CaptureSessionManager) {
        activityIndicator.startAnimating()
        captureSessionManager.stop()
        shutterButton.isUserInteractionEnabled = false
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didCapturePicture picture: UIImage, withQuad detectedQuad: Quadrilateral?) {
        activityIndicator.stopAnimating()
        
        selectPhotoButton.isHidden = true
        
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        
        var quad = detectedQuad
        if (quad == nil) {
            let topLeft = CGPoint(x: picture.size.width * 0.05, y: picture.size.height * 0.05)
            let topRight = CGPoint(x: picture.size.width * 0.95, y: picture.size.height * 0.05)
            let bottomRight = CGPoint(x: picture.size.width * 0.95, y: picture.size.height * 0.95)
            let bottomLeft = CGPoint(x: picture.size.width * 0.05, y: picture.size.height * 0.95)
            
            quad = Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)
        }
        guard let quad = quad,
            let ciImage = CIImage(image: picture) else {
                if let imageScannerController = navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
                }
                return
        }
        let cgOrientation = CGImagePropertyOrientation(picture.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
        let scaledQuad = detectedQuad ?? quad
        
        // Cropped Image
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: picture.size.height)
        cartesianScaledQuad.reorganize()
        
        let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
        ])
        
        let croppedImage = UIImage.from(ciImage: filteredImage)
        // Enhanced Image
        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
        let enhancedScan = enhancedImage.flatMap { ImageScannerScan(image: $0) }
        
        let results = ImageScannerResults(detectedRectangle: scaledQuad, originalScan: ImageScannerScan(image: picture), croppedScan: ImageScannerScan(image: croppedImage), enhancedScan: enhancedScan)
        
        imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithResults: results)
       
        shutterButton.isUserInteractionEnabled = true
    }
    
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didDetectQuad quad: Quadrilateral?, _ imageSize: CGSize) {
        guard let quad = quad else {
            // If no quad has been detected, we remove the currently displayed on on the quadView.
            quadView.removeQuadrilateral()
            return
        }
        
        let portraitImageSize = CGSize(width: imageSize.height, height: imageSize.width)
        
        let scaleTransform = CGAffineTransform.scaleTransform(forSize: portraitImageSize, aspectFillInSize: quadView.bounds.size)
        let scaledImageSize = imageSize.applying(scaleTransform)
        
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)

        let imageBounds = CGRect(origin: .zero, size: scaledImageSize).applying(rotationTransform)

        let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: imageBounds, toCenterOfRect: quadView.bounds)
        
        let transforms = [scaleTransform, rotationTransform, translationTransform]
        
        let transformedQuad = quad.applyTransforms(transforms)
        
        quadView.drawQuadrilateral(quad: transformedQuad, animated: true)
    }
    
}
