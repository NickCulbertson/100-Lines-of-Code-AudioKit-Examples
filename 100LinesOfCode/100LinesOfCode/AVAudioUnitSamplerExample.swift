import SwiftUI
import Keyboard
import Tonic
import AVFoundation
class AVAudioUnitSamplerClass: ObservableObject {
    let engine = AVAudioEngine()
    var instrument = AVAudioUnitSampler()
    init() {
        engine.attach(instrument)
        engine.connect(instrument, to: engine.mainMixerNode, format: nil)
        try? instrument.loadInstrument(at: Bundle.main.url(forResource: "Sounds/uke", withExtension: "exs")!)
        try? engine.start()
    }
    func noteOn(pitch: Pitch, point: CGPoint) {
        instrument.startNote(UInt8(pitch.intValue), withVelocity: 127, onChannel: 0)
    }
    func noteOff(pitch: Pitch) {
        instrument.stopNote(UInt8(pitch.intValue), onChannel: 0)
    }
}
struct AVAudioUnitSamplerView: View {
    @StateObject var conductor = AVAudioUnitSamplerClass()
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
struct AVAudioUnitSamplerView_Previews: PreviewProvider {static var previews: some View {AVAudioUnitSamplerView()}}
