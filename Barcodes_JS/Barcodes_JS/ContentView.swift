import SwiftUI
import PDFKit
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers
import CoreXLSX
import Vision
import PhotosUI
import GoogleMobileAds


struct ContentView: View {
    @State private var inputCode: String = ""
    @State private var barcodeType: BarcodeType = .default8Digit
    @State private var barcodeData: [(code: String, image: UIImage)] = []
    @State private var firstBarcode: UIImage?
    @State private var firstBarcodeLabel: String = ""
    @State private var lastBarcode: UIImage?
    @State private var lastBarcodeLabel: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showDocumentPicker = false
    @State private var pdfURL: URL?
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var showActionSheet = false
    @State private var isProcessing: Bool = false
    @State private var progress: Double = 0.0

    @FocusState private var isInputFocused: Bool

    enum BarcodeType: String, CaseIterable, Identifiable {
        case default8Digit = "8-Digit Barcode"
        case code128 = "Code 128"
        case qrCode = "QR Code"
        case pdf417 = "PDF417"
        case dataMatrix = "Data Matrix"
        case aztec = "Aztec Code"
        case code39 = "Code 39"
        case ean8 = "EAN-8"
        case ean13 = "EAN-13"
        
        var id: String { self.rawValue }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Add the BannerAdView below the title
                  BannerAdView(adUnitID: "ca-app-pub-3940256099942544/6300978111") // Replace with your real Ad Unit ID
                      .frame(width: 320, height: 50) // AdMob's standard banner size
                      .padding()
            Text("Barcode Generator")
                .font(.largeTitle)
                .foregroundColor(.primary)
                .padding(.top)
            
            Menu {
                ForEach(BarcodeType.allCases) { type in
                    Button(action: {
                        barcodeType = type
                    }) {
                        Text(type.rawValue)
                            .foregroundColor(.primary)
                    }
                }
            } label: {
                HStack {
                    Text("Select Barcode Type: \(barcodeType.rawValue)")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                        .background(Color(UIColor.systemBackground))
                )
            }
            .padding(.horizontal)

            TextField("Enter item numbers (comma-separated)", text: $inputCode)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                        .background(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
                .focused($isInputFocused)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Button("Done") {
                            isInputFocused = false
                        }
                    }
                }
                .overlay(
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        Image(systemName: "paperclip")
                            .padding()
                            .foregroundColor(.primary)
                    }
                    .offset(x: -30),
                    alignment: .trailing
                )

            Button(action: {
                showActionSheet = true
            }) {
                Text("Select Image")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Select Source"),
                    buttons: [
                        .default(Text("Camera")) {
                            showCameraPicker = true
                        },
                        .default(Text("Photo Gallery")) {
                            showImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker { image in
                    processImage(preprocessImage(image) ?? image)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker { image in
                    processImage(preprocessImage(image) ?? image)
                }
            }

            Button(action: {
                generateBarcodesFromInput()
            }) {
                Text("Generate Barcode")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }

            if let firstBarcode = firstBarcode {
                VStack {
                    Text("First Barcode")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Image(uiImage: firstBarcode)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 100)
                    Text(firstBarcodeLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
            }

            if let lastBarcode = lastBarcode {
                VStack {
                    Text("Last Barcode")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Image(uiImage: lastBarcode)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 100)
                    Text(lastBarcodeLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
            }

            Button(action: {
                saveToPDF()
            }) {
                Text("Download PDF")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .overlay(
            Group {
                if isProcessing {
                    VStack {
                        ProgressView("Generating PDF...", value: progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding()
                            .foregroundColor(.primary)
                        Text("\(Int(progress * 100))% completed")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                }
            }
        )
        .alert(isPresented: $showError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { url in
                handleFile(url: url)
            }
        }
    }
    // MARK: - Generate Barcodes from Text Input
    func generateBarcodesFromInput() {
        let codes = inputCode
            .split(whereSeparator: { $0 == "," || $0.isWhitespace || $0 == "-" })
            .map { String($0) }
            .filter { code in
                barcodeType == .default8Digit ? code.count == 8 : !code.isEmpty
            }

        if codes.isEmpty {
            showError(with: "No valid numbers found for \(barcodeType.rawValue).")
            return
        }

        let images = generateBatchBarcodes(from: codes)

        if let first = images.first {
            firstBarcode = first.image
            firstBarcodeLabel = first.code
        }
        if let last = images.last {
            lastBarcode = last.image
            lastBarcodeLabel = last.code
        }

        barcodeData = images
    }

    // MARK: - Generate Barcode Image Based on Type
    func generateBarcode(from code: String) -> UIImage? {
        let filter: CIFilter?
        
        switch barcodeType {
        case .default8Digit, .code128:
            filter = CIFilter.code128BarcodeGenerator()
        case .qrCode:
            filter = CIFilter.qrCodeGenerator()
        case .pdf417:
            filter = CIFilter.pdf417BarcodeGenerator()
        case .aztec:
            filter = CIFilter.aztecCodeGenerator()
        case .dataMatrix:
            if #available(iOS 15.0, *) {
                filter = CIFilter(name: "CIDataMatrixCodeGenerator") // Available in iOS 15.0 and later
            } else {
                // Placeholder or error handling for unsupported iOS versions
                showError(with: "Data Matrix is not supported on this iOS version.")
                return nil
            }
        case .code39:
            return generateCode39Barcode(from: code) // Placeholder for custom Code 39 generation
        case .ean8, .ean13:
            return generateEANBarcode(from: code)    // Placeholder for custom EAN-8/EAN-13 generation
        }
        
        filter?.setValue(Data(code.utf8), forKey: "inputMessage")
        
        guard let outputImage = filter?.outputImage else { return nil }
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
        return UIImage(ciImage: transformed)
    }


    // MARK: - Custom Barcode Generators (Placeholders for Code 39 and EAN)
    func generateCode39Barcode(from code: String) -> UIImage? {
        // Placeholder function for generating Code 39 using external libraries or custom implementation
        return nil
    }

    func generateEANBarcode(from code: String) -> UIImage? {
        // Placeholder function for generating EAN-8 or EAN-13 using external libraries or custom implementation
        return nil
    }

    // MARK: - Generate Batch Barcodes
    func generateBatchBarcodes(from codes: [String]) -> [(code: String, image: UIImage)] {
        return codes.compactMap { code in
            if let barcodeImage = generateBarcode(from: code) {
                return (code: code, image: barcodeImage)
            }
            return nil
        }
    }

    // MARK: - PDF Generation with Progress Tracking
    func saveToPDF() {
        guard !barcodeData.isEmpty else {
            showError(with: "No barcodes generated.")
            return
        }
        
        isProcessing = true
        progress = 0.0

        DispatchQueue.global(qos: .userInitiated).async {
            let pdfFileName = "Barcodes-\(UUID().uuidString).pdf"
            let pdfFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(pdfFileName)
            let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

            do {
                try pdfRenderer.writePDF(to: pdfFilePath) { context in
                    context.beginPage()
                    let itemsPerRow = 3
                    let itemWidth: CGFloat = 180
                    let itemHeight: CGFloat = 120
                    var xPosition: CGFloat = 20
                    var yPosition: CGFloat = 20
                    var itemCount = 0
                    
                    for (index, data) in barcodeData.enumerated() {
                        data.image.draw(in: CGRect(x: xPosition, y: yPosition, width: itemWidth, height: itemHeight - 20))

                        let textAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: UIColor.black
                        ]
                        let textRect = CGRect(x: xPosition, y: yPosition + itemHeight - 20, width: itemWidth, height: 20)
                        let attributedText = NSAttributedString(string: data.code, attributes: textAttributes)
                        attributedText.draw(in: textRect)

                        itemCount += 1
                        if itemCount % itemsPerRow == 0 {
                            xPosition = 20
                            yPosition += itemHeight + 20
                        } else {
                            xPosition += itemWidth + 20
                        }

                        if yPosition + itemHeight > 772 && index < barcodeData.count - 1 {
                            context.beginPage()
                            xPosition = 20
                            yPosition = 20
                        }

                        DispatchQueue.main.async {
                            progress = Double(index + 1) / Double(barcodeData.count)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    pdfURL = pdfFilePath
                    sharePDF(fileURL: pdfFilePath)
                    isProcessing = false
                    resetAppState()
                }
                
            } catch {
                DispatchQueue.main.async {
                    showError(with: "Failed to save PDF.")
                    isProcessing = false
                }
            }
        }
    }

    // MARK: - PDF Sharing with iPad Compatibility
    func sharePDF(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityViewController.popoverPresentationController?.sourceView = rootVC.view
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            activityViewController.popoverPresentationController?.permittedArrowDirections = []
            rootVC.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - File Upload Handling
    func handleFile(url: URL) {
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            if url.pathExtension == "xlsx" {
                readExcelFile(url: url)
            } else if url.pathExtension == "pdf" || url.pathExtension == "txt" {
                readTextOrPDFFile(url: url)
            } else {
                showError(with: "Unsupported file type.")
            }
        } else {
            showError(with: "Failed to access file.")
        }
    }

    func readExcelFile(url: URL) {
        do {
            if let file = try XLSXFile(filepath: url.path) {
                var itemCodes: [String] = []

                if let sharedStrings = try file.parseSharedStrings() {
                    for path in try file.parseWorksheetPaths() {
                        if let worksheet = try? file.parseWorksheet(at: path) {
                            for row in worksheet.data?.rows ?? [] {
                                for cell in row.cells {
                                    if let value = cell.stringValue(sharedStrings), barcodeType == .default8Digit ? value.count == 8 : !value.isEmpty, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: value)) {
                                        itemCodes.append(value)
                                    }
                                }
                            }
                        }
                    }
                }
                inputCode = itemCodes.joined(separator: ",")
                generateBarcodesFromInput()
            }
        } catch {
            showError(with: "Failed to read Excel file.")
        }
    }

    func readTextOrPDFFile(url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let codes = content.split(whereSeparator: { !$0.isNumber }).map { String($0) }.filter { barcodeType == .default8Digit ? $0.count == 8 : !$0.isEmpty }
            inputCode = codes.joined(separator: ",")
            generateBarcodesFromInput()
        } catch {
            showError(with: "Failed to read file content.")
        }
    }

    // MARK: - Image Preprocessing (Grayscale, Contrast, and Sharpening)
    func preprocessImage(_ image: UIImage) -> UIImage? {
        let inputImage = CIImage(image: image)
        let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono")
        grayscaleFilter?.setValue(inputImage, forKey: kCIInputImageKey)

        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(grayscaleFilter?.outputImage, forKey: kCIInputImageKey)
        contrastFilter?.setValue(1.5, forKey: kCIInputContrastKey)

        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
        sharpenFilter?.setValue(contrastFilter?.outputImage, forKey: kCIInputImageKey)
        sharpenFilter?.setValue(0.7, forKey: kCIInputSharpnessKey)

        guard let outputImage = sharpenFilter?.outputImage else { return nil }
        let context = CIContext()
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }

    // MARK: - Image Recognition (OCR) for Barcodes with Enhanced Processing
    func processImage(_ image: UIImage) {
        guard image.cgImage != nil else {
            showError(with: "Unable to process image.")
            return
        }

        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                showError(with: "Failed to recognize text.")
                return
            }

            let allDetectedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            let detectedCodes = allDetectedText.flatMap { text in
                let regex = try? NSRegularExpression(pattern: "\\b\\d{8}\\b")
                let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []
                return matches.compactMap {
                    Range($0.range, in: text).flatMap { String(text[$0]) }
                }
            }

            if detectedCodes.isEmpty {
                showError(with: "No valid 8-digit codes found in the image.")
            } else {
                inputCode = detectedCodes.joined(separator: ",")
                generateBarcodesFromInput()
            }
        }

        let preprocessedImage = preprocessImage(image) ?? image
        let requestHandler = VNImageRequestHandler(cgImage: preprocessedImage.cgImage!, options: [:])
        try? requestHandler.perform([request])
    }

    // MARK: - Reset App State
    func resetAppState() {
        inputCode = ""
        barcodeData = []
        firstBarcode = nil
        firstBarcodeLabel = ""
        lastBarcode = nil
        lastBarcodeLabel = ""
        progress = 0.0
    }

    // MARK: - Error Handling
    func showError(with message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Document Picker Wrapper
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .pdf, .text, .spreadsheet])
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onPick(url)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

// MARK: - Camera Picker Implementation
struct CameraPicker: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void
    var onCancel: (() -> Void)? = nil

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPick(image)
            }
            picker.dismiss(animated: true, completion: nil)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel?()
            picker.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        // Check if the camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            print("Camera not available.")
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Image Picker Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true, completion: nil)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { (image, error) in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.onPick(uiImage)
                    }
                }
            }
        }
    }
}
