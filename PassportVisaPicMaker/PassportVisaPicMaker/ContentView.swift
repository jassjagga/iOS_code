import SwiftUI
import PhotosUI
import Vision



struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isPickerPresented = false

    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    Text("Original Image:")
                        .font(.headline)
                        .padding(.top)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 300)
                } else {
                    Text("No image selected")
                        .foregroundColor(.gray)
                }

                HStack {
                    Button("Upload Image") {
                        isPickerPresented = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    if selectedImage != nil {
                        Button("Convert to Passport Size") {
                            print("Convert to Passport Size button clicked.") // Debug
                            if let image = selectedImage {
                                print("Image is available. Starting conversion...") // Debug
                                processedImage = createPassportPhoto(from: image)
                            } else {
                                print("Error: No image selected for conversion.") // Debug
                            }
                        }

                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                if let outputImage = processedImage {
                    Text("Passport Photo:")
                        .font(.headline)
                        .padding(.top)
                    Image(uiImage: outputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 300)

                    Button("Save to Photos") {
                        saveImageToPhotos(outputImage)
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Passport Photo Maker")
            .sheet(isPresented: $isPickerPresented) {
                PHPickerViewControllerWrapper(selectedImage: $selectedImage)
            }
        }
    }

    func saveImageToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

struct PHPickerViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerViewControllerWrapper

        init(_ parent: PHPickerViewControllerWrapper) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
            }
        }
    }
}

func createPassportPhoto(from image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else {
        print("Error: Unable to get CGImage from UIImage.") // Debug
        return nil
    }

    print("Starting face detection...") // Debug

    let request = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])

    do {
        try handler.perform([request])

        guard let face = request.results?.first as? VNFaceObservation else {
            print("Error: No face detected.") // Debug
            return nil
        }

        print("Face detected. Bounding box: \(face.boundingBox)") // Debug

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let faceRect = CGRect(
            x: face.boundingBox.origin.x * imageWidth,
            y: (1 - face.boundingBox.origin.y - face.boundingBox.height) * imageHeight,
            width: face.boundingBox.width * imageWidth,
            height: face.boundingBox.height * imageHeight
        )

        print("Face rectangle in image coordinates: \(faceRect)") // Debug

        // Define crop rectangle
        let passportAspectRatio: CGFloat = 35 / 45
        let passportHeight = faceRect.height * 2.5
        let passportWidth = passportHeight * passportAspectRatio

        let cropX = max(faceRect.midX - passportWidth / 2, 0)
        let cropY = max(faceRect.midY - passportHeight / 2, 0)

        let cropRect = CGRect(
            x: cropX,
            y: cropY,
            width: min(passportWidth, imageWidth - cropX),
            height: min(passportHeight, imageHeight - cropY)
        )

        print("Crop rectangle for passport photo: \(cropRect)") // Debug

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            print("Error: Cropping failed.") // Debug
            return nil
        }

        print("Cropping successful. Resizing to passport dimensions...") // Debug

        let croppedUIImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        let targetSize = CGSize(width: 413, height: 531) // Passport size at 300 DPI

        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        croppedUIImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        print("Passport photo created successfully.") // Debug

        return resizedImage
    } catch {
        print("Error: Face detection failed - \(error.localizedDescription)") // Debug
        return nil
    }
}
