import AudioKit
import AVFoundation
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            MasterView()
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct MasterView: View {
    var body: some View {
        Form {
            Section(header: Text("Demos")) {
                Group {
                NavigationLink("1. Drum Pads", destination: DrumPads())
                NavigationLink("2. ?", destination: ComingSoon())
                NavigationLink("3. ?", destination: ComingSoon())
                NavigationLink("4. ?", destination: ComingSoon())
                NavigationLink("5. ?", destination: ComingSoon())
                }
                Group {
                NavigationLink("6. ?", destination: ComingSoon())
                NavigationLink("7. ?", destination: ComingSoon())
                NavigationLink("8. ?", destination: ComingSoon())
                NavigationLink("9. ?", destination: ComingSoon())
                NavigationLink("10. ?", destination: ComingSoon())
                }
            }
        }
        .navigationBarTitle("100 Lines of Code")
    }
}

struct DetailView: View {
    @State private var opacityValue = 0.0
    var body: some View {
        VStack(spacing: 0) {
            Text("100 Lines of Code : AudioKit Examples")
                .font(.system(.largeTitle, design: .rounded))
                .padding()
            Text("Please select a demo from the left-side menu.")
                .font(.system(.body, design: .rounded))
        }
        .opacity(opacityValue)
        .onAppear {
            DispatchQueue.main
                .asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        opacityValue = 1.0
                    }
                }
        }
    }
}
