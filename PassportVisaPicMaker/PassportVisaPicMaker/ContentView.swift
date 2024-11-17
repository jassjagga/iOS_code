import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var showEditor = false

    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    NavigationLink(destination: ImageEditorView(image: image), isActive: $showEditor) {
                        EmptyView()
                    }
                }
                Button("Upload Image") {
                    selectImage()
                }
                .font(.title2)
                .padding()
            }
            .navigationTitle("Home")
        }
    }

    private func selectImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = ImagePickerCoordinator(selectedImage: $selectedImage, showEditor: $showEditor)
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }
}

class ImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @Binding var selectedImage: UIImage?
    @Binding var showEditor: Bool

    init(selectedImage: Binding<UIImage?>, showEditor: Binding<Bool>) {
        _selectedImage = selectedImage
        _showEditor = showEditor
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            showEditor = true
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
struct ImageEditorView: View {
    var image: UIImage
    @State private var overlayRect = CGRect(x: 0, y: 0, width: 200, height: 200) // Initial crop rect
    @State private var scaleFactor: CGFloat = 1.0
    @State private var adjustedImage = UIImage()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        CropOverlayView(overlayRect: $overlayRect, image: image)
                            .gesture(DragGesture().onChanged { value in
                                handleDrag(value: value)
                            })
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Button("Save") {
                    saveCroppedImage()
                }
                .font(.headline)
                .padding()
                Spacer()
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupEditor()
        }
    }

    private func setupEditor() {
        let scale = min(UIScreen.main.bounds.width / image.size.width,
                        UIScreen.main.bounds.height / image.size.height)
        scaleFactor = scale
        overlayRect = CGRect(x: 50, y: 50, width: 204, height: 204)
    }

    private func handleDrag(value: DragGesture.Value) {
        let delta = value.translation
        overlayRect.origin.x += delta.width
        overlayRect.origin.y += delta.height
    }

    private func saveCroppedImage() {
        let scaledRect = CGRect(x: overlayRect.origin.x / scaleFactor,
                                y: overlayRect.origin.y / scaleFactor,
                                width: overlayRect.width / scaleFactor,
                                height: overlayRect.height / scaleFactor)

        if let cropped = image.cgImage?.cropping(to: scaledRect) {
            let croppedImage = UIImage(cgImage: cropped)
            UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil)
        }
        presentationMode.wrappedValue.dismiss()
    }
}
struct CropOverlayView: View {
    @Binding var overlayRect: CGRect
    var image: UIImage

    var body: some View {
        Rectangle()
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: overlayRect.width, height: overlayRect.height)
            .position(x: overlayRect.midX, y: overlayRect.midY)
            .background(Color.black.opacity(0.5))
            .mask(Rectangle().inset(by: -10))
    }
}

