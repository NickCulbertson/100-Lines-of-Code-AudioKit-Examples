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
                    NavigationLink("4. Synth Punk Console", destination: SynthPunkConsole())
                    NavigationLink("5. Apple Sampler Example", destination: AppleSamplerView())
                }
                Group {
                    NavigationLink("6. Dunne Sampler Example", destination: DunneSamplerView())
                    NavigationLink("7. AVAudioUnitSampler Example", destination: AVAudioUnitSamplerView())
                }
            }
        }.navigationBarTitle("100 Lines of Code")
    }
}
