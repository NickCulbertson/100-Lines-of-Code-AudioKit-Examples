import SwiftUI
import AudioKit
import Keyboard
import Tonic
class AppleSamplerClass: ObservableObject {
    let engine = AudioEngine()
    var instrument = AppleSampler()
    init() {
        engine.output = instrument
        try? instrument.loadInstrument(url: Bundle.main.url(forResource: "Sounds/uke", withExtension: "exs")!)
        try? engine.start()
    }
    func noteOn(pitch: Pitch, point: CGPoint) {
        instrument.play(noteNumber: MIDINoteNumber(pitch.intValue), velocity: 127, channel: 0)
    }
    func noteOff(pitch: Pitch) {
        instrument.stop(noteNumber: MIDINoteNumber(pitch.intValue), channel: 0)
    }
}
struct AppleSamplerView: View {
    @StateObject var conductor = AppleSamplerClass()
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.green.opacity(0.5), .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                SwiftUIKeyboard(firstOctave: 2, octaveCount: 2, noteOn: conductor.noteOn(pitch:point:), noteOff: conductor.noteOff).frame(maxHeight: 600)
            }
        }.onDisappear() { self.conductor.engine.stop() }
    }
}
struct AppleSampler_Previews: PreviewProvider {static var previews: some View {AppleSamplerView()}}
