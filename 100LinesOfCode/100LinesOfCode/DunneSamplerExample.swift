import SwiftUI
import AudioKit
import Keyboard
import Tonic
import DunneAudioKit
class DunneSamplerClass: ObservableObject {
    let engine = AudioEngine()
    var instrument = Sampler()
    init() {
        engine.output = instrument
        instrument.loadSFZ(url: Bundle.main.url(forResource: "Sounds/sqr", withExtension: "SFZ")!)
        instrument.masterVolume = 0.15
        try? engine.start()
    }
    func noteOn(pitch: Pitch, point: CGPoint) {
        instrument.play(noteNumber: MIDINoteNumber(pitch.intValue), velocity: 127, channel: 0)
    }
    func noteOff(pitch: Pitch) {
        instrument.stop(noteNumber: MIDINoteNumber(pitch.intValue), channel: 0)
    }
}
struct DunneSamplerView: View {
    @StateObject var conductor = DunneSamplerClass()
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.green.opacity(0.5), .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                SwiftUIKeyboard(firstOctave: 2, octaveCount: 2, noteOn: conductor.noteOn(pitch:point:), noteOff: conductor.noteOff).frame(maxHeight: 600)
            }
        }.onDisappear() {
            self.conductor.engine.stop()
        }
    }
}
struct DunneSampler_Previews: PreviewProvider {static var previews: some View {DunneSamplerView()}}
