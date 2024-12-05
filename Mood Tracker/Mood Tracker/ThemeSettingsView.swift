import SwiftUI

struct ThemeSettingsView: View {
    @EnvironmentObject var viewModel: MoodViewModel
    private let themes = ["Default", "Dark", "Light"]

    var body: some View {
        Form {
            Section(header: Text("Select a Theme")) {
                ForEach(themes, id: \.self) { theme in
                    HStack {
                        Text(theme)
                        Spacer()
                        if theme == viewModel.selectedTheme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.saveTheme(theme)
                    }
                }
            }
        }
        .navigationTitle("Theme Settings")
    }
}

