import SwiftUI
import PhotosUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            HomeScreen()
                .navigationTitle("Simple Cropper")
        }
    }
}

struct HomeScreen: View {
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    @State private var navigateToCropScreen = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Simple Cropper")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            Spacer()
            
            Button(action: {
                isImagePickerPresented = true
            }) {
                Text("Select Image")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .sheet(isPresented: $isImagePickerPresented, onDismiss: {
                if selectedImage != nil {
                    navigateToCropScreen = true
                }
            }) {
                ImagePicker(image: $selectedImage)
            }

            Spacer()

            NavigationLink(
                destination: CropScreen(image: selectedImage),
                isActive: $navigateToCropScreen,
                label: { EmptyView() }
            )
        }
        .padding()
    }
}

struct CropScreen: View {
    var image: UIImage?
    @State private var cropRect: CGRect = CGRect(x: 100, y: 100, width: 200, height: 200)
    @State private var overlayPosition = CGSize.zero
    
    var body: some View {
        VStack {
            Text("Crop Image")
                .font(.title2)
                .padding(.top, 20)

            if let uiImage = image {
                GeometryReader { geometry in
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                        
                        // Crop overlay
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: cropRect.width, height: cropRect.height)
                            .offset(overlayPosition)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        overlayPosition = value.translation
                                    }
                                    .onEnded { _ in
                                        // Adjust cropRect position based on the final drag offset
                                        cropRect.origin.x += overlayPosition.width
                                        cropRect.origin.y += overlayPosition.height
                                        overlayPosition = .zero
                                    }
                            )
                    }
                }
                .frame(height: UIScreen.main.bounds.width) // Adjust height as needed
                
                Button(action: {
                    if let croppedImage = cropImage(uiImage, toRect: cropRect) {
                        saveToCameraRoll(croppedImage)
                    }
                }) {
                    Text("Save Cropped Image")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            } else {
                Text("No Image Selected")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Crop")
    }

    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        // Calculate the crop rectangle based on the image's scale
        guard let cgImage = image.cgImage else { return nil }

        let imageScale = image.size.width / UIScreen.main.bounds.width
        let scaledRect = CGRect(
            x: rect.origin.x * imageScale,
            y: rect.origin.y * imageScale,
            width: rect.size.width * imageScale,
            height: rect.size.height * imageScale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func saveToCameraRoll(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

// Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

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
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

