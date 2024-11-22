import SwiftUI
import SwiftSoup

struct ContentView: View {
    @State private var title: String = "Fetching..."
    @State private var description: String = ""
    @State private var productImage: UIImage? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack {
            if let productImage = productImage {
                Image(uiImage: productImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
            } else {
                Text("No Image Available")
                    .frame(height: 200)
                    .foregroundColor(.gray)
            }

            Text(title)
                .font(.headline)
                .padding()

            Text(description)
                .font(.body)
                .padding()

            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()

            Button("Fetch Product") {
                fetchWalmartProduct(itemNumber: "50591532") { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let (fetchedTitle, fetchedDescription, fetchedImage)):
                            self.title = fetchedTitle
                            self.description = fetchedDescription
                            self.productImage = fetchedImage
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .padding()
        }
        .padding()
    }

    func fetchWalmartProduct(itemNumber: String, completion: @escaping (Result<(String, String, UIImage), Error>) -> Void) {
        let searchURL = "https://www.walmart.ca/search?q=\(itemNumber)"
        
        guard let url = URL(string: searchURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "Invalid Data", code: 0, userInfo: nil)))
                return
            }
            
            print("HTML Response: \(html)") // DEBUG: Log HTML to check structure
            
            do {
                let doc = try SwiftSoup.parse(html)
                
                // Extract product link
                guard let productLink = try doc.select("a.product-title-link").first()?.attr("href") else {
                    completion(.failure(NSError(domain: "Product Not Found", code: 0, userInfo: nil)))
                    return
                }
                
                let productURL = "https://www.walmart.ca\(productLink)"
                fetchProductDetails(from: productURL, completion: completion)
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchProductDetails(from url: String, completion: @escaping (Result<(String, String, UIImage), Error>) -> Void) {
        guard let productURL = URL(string: url) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: productURL) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "Invalid Data", code: 0, userInfo: nil)))
                return
            }
            
            print("Product Page HTML: \(html)") // DEBUG: Log HTML of product page
            
            do {
                let doc = try SwiftSoup.parse(html)
                
                // Extract title
                let title = try doc.select("h1.css-1mp9cxs").text()
                
                // Extract description
                let description = try doc.select("div.css-1tsj1ev").text()
                
                // Extract image URL
                if let imageURLString = try? doc.select("img.css-1d80o5u").attr("src"),
                   let imageURL = URL(string: imageURLString),
                   let imageData = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: imageData) {
                    completion(.success((title, description, image)))
                } else {
                    completion(.failure(NSError(domain: "Image Not Found", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

