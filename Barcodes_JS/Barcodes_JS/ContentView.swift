import SwiftUI
import PDFKit
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers
import CoreXLSX

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
    
    // State to control the focus
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
                .focused($isInputFocused) // Attach focus state
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Button("Done") {
                            isInputFocused = false // Dismiss keyboard
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
                clearData() // Clear data after downloading PDF
            }) {
                Text("Download PDF")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
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

    // MARK: - PDF Generation
    func saveToPDF() {
        let pdfFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("Barcodes.pdf")
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
                }
            }
            pdfURL = pdfFilePath
            sharePDF(fileURL: pdfFilePath)
        } catch {
            showError(with: "Failed to save PDF.")
        }
    }

    // MARK: - Clear Data
    func clearData() {
        inputCode = ""
        barcodeData = []
        firstBarcode = nil
        firstBarcodeLabel = ""
        lastBarcode = nil
        lastBarcodeLabel = ""
    }

    // MARK: - PDF Sharing
    func sharePDF(fileURL: URL) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true, completion: nil)
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
            let content = try String(contentsOf: url)
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

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if necessary
        }
    }
}


