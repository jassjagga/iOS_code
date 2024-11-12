import SwiftUI
import PDFKit
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers
import CoreXLSX
import Vision
import PhotosUI

struct ContentView: View {
    @State private var inputCode: String = ""
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
    @State private var isProcessing: Bool = false
    @State private var progress: Double = 0.0

    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Barcode Generator")
                .font(.largeTitle)
                .padding(.top)

            TextField("Enter 8-digit item numbers, separated by commas", text: $inputCode)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
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
                    }
                    .offset(x: -30),
                    alignment: .trailing
                )

            Button(action: {
                showImagePicker = true
            }) {
                Text("Capture or Select Image")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(8)
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
                    Image(uiImage: firstBarcode)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 100)
                    Text(firstBarcodeLabel)
                        .font(.subheadline)
                        .padding(.bottom)
                }
            }

            if let lastBarcode = lastBarcode {
                VStack {
                    Text("Last Barcode")
                        .font(.headline)
                    Image(uiImage: lastBarcode)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 100)
                    Text(lastBarcodeLabel)
                        .font(.subheadline)
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
                        Text("\(Int(progress * 100))% completed")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker { image in
                processImage(preprocessImage(image) ?? image)
            }
        }
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

    // MARK: - Generate Barcodes from Text Input
    func generateBarcodesFromInput() {
        let codes = inputCode
            .split(whereSeparator: { $0 == "," || $0.isWhitespace || $0 == "-" })
            .map { String($0) }
            .filter { $0.count == 8 }

        if codes.isEmpty {
            showError(with: "No valid 8-digit numbers found.")
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

                        // Update progress
                        DispatchQueue.main.async {
                            progress = Double(index + 1) / Double(barcodeData.count)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    pdfURL = pdfFilePath
                    sharePDF(fileURL: pdfFilePath)
                    isProcessing = false // Hide progress bar when done
                    resetAppState() // Reset the app state after downloading the PDF
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
    
    // MARK: - Generate Barcode Image
    func generateBarcode(from code: String) -> UIImage? {
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(code.utf8)

        if let outputImage = filter.outputImage {
            let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
            return UIImage(ciImage: transformed)
        }
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
                                    if let value = cell.stringValue(sharedStrings), value.count == 8, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: value)) {
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
            let content = try String(contentsOf: url, encoding: .utf8) // Updated for iOS 18
            let codes = content.split(whereSeparator: { !$0.isNumber }).map { String($0) }.filter { $0.count == 8 }
            inputCode = codes.joined(separator: ",")
            generateBarcodesFromInput()
        } catch {
            showError(with: "Failed to read file content.")
        }
    }

    // MARK: - Error Handling
    func showError(with message: String) {
        errorMessage = message
        showError = true
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
        guard image.cgImage != nil else { // Updated to boolean check
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
            print("All detected text (unfiltered):", allDetectedText)

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

