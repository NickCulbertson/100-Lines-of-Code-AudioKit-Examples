import SwiftUI
struct ContentView: View {
    var body: some View {
        NavigationView {
            MasterView()
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
struct MasterView: View {
    var body: some View {
        Form {
            Section(header: Text("Demos")) {
                Group {
                    NavigationLink("1. Drum Pads", destination: DrumPads())
                    NavigationLink("2. Sequencer", destination: Sequencer())
                    NavigationLink("3. Synth", destination: SynthView())
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
        }.navigationBarTitle("100 Lines of Code")
    }
}
