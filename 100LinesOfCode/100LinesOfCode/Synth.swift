import SwiftUI
import AudioKit
import Keyboard
import Tonic
import SoundpipeAudioKit
import Controls
struct MorphingOscillatorData {
    var frequency: AUValue = 440
    var octaveFrequency: AUValue = 440
    var amplitude: AUValue = 0.2
}
class SynthClass: ObservableObject {
    let engine = AudioEngine()
    @Published var octave = 1
    let filter : MoogLadder
    @Published var env : AmplitudeEnvelope
    var notes = Array(repeating: 0, count: 11)
    @Published var cutoff = AUValue(20_000) {
        didSet { filter.cutoffFrequency = AUValue(cutoff) }
    }
    var osc = [MorphingOscillator(index:0.75,detuningOffset: -0.5), MorphingOscillator(index:0.75,detuningOffset: 0.5), MorphingOscillator(index:2.75)]
    init() {
        filter = MoogLadder(Mixer(osc[0],osc[1],osc[2]), cutoffFrequency: 20_000)
        env = AmplitudeEnvelope(filter, attackDuration: 0.0, decayDuration: 1.0, sustainLevel: 0.0, releaseDuration: 0.25)
        engine.output = env
        try? engine.start()
    }
    @Published var data = MorphingOscillatorData() {
        didSet {
            for i in 0...2 {
                osc[i].start()
                osc[i].$amplitude.ramp(to: data.amplitude, duration: 0)
            }
            osc[0].$frequency.ramp(to: data.frequency, duration: 0.1)
            osc[1].$frequency.ramp(to: data.frequency, duration: 0.1)
            osc[2].$frequency.ramp(to: data.octaveFrequency, duration: 0.1)
        }
    }
    func noteOn(pitch: Pitch, point: CGPoint) {
        env.closeGate()
        data.frequency = AUValue(pitch.midiNoteNumber).midiNoteToFrequency()
        data.octaveFrequency = AUValue(pitch.midiNoteNumber-12).midiNoteToFrequency()
        for num in 0 ... 10 {
            if notes[num] == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { self.env.openGate() }
                notes[num] = pitch.intValue
                break
            }
        }
    }
    func noteOff(pitch: Pitch) {
        for num in 0 ... 10 { //closeGate if all fingers are off
            if notes[num] == pitch.intValue { notes[num] = 0 }
            if Set(notes).count <= 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { self.env.closeGate() }
            }
        }
    }
}
struct SynthView: View {
    @StateObject var conductor = SynthClass()
    var body: some View {
        ZStack { RadialGradient(gradient: Gradient(colors: [.pink.opacity(0.5), .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    VStack {
                        Text("Filter\n\(Int(conductor.cutoff))").multilineTextAlignment(.center).padding(.top, 10)
                        SmallKnob(value: $conductor.cutoff, range: 12.0 ... 20_000.0).frame(maxWidth:150).padding(.bottom, 10)
                    }
                    VStack {
                        Text("Attack\n\(String(format: "%.2f", conductor.env.attackDuration))").multilineTextAlignment(.center).padding(.top, 10)
                        SmallKnob(value: $conductor.env.attackDuration, range: 0.0 ... 10.0).frame(maxWidth:150).padding(.bottom, 10)
                    }
                    VStack {
                        Text("Decay\n\(String(format: "%.2f", conductor.env.decayDuration))").multilineTextAlignment(.center).padding(.top, 10)
                        SmallKnob(value: $conductor.env.decayDuration, range: 0.0 ... 10.0).frame(maxWidth:150).padding(.bottom, 10)
                    }
                    VStack {
                        Text("Sustain\n\(String(format: "%.2f", conductor.env.sustainLevel))").multilineTextAlignment(.center).padding(.top, 10)
                        SmallKnob(value: $conductor.env.sustainLevel, range: 0.0 ... 1.0).frame(maxWidth:150).padding(.bottom, 10)
                    }
                    VStack {
                        Text("Release\n\(String(format: "%.2f", conductor.env.releaseDuration))").multilineTextAlignment(.center).padding(.top, 10)
                        SmallKnob(value: $conductor.env.releaseDuration, range: 0.0 ... 10.0).frame(maxWidth:150).padding(.bottom, 10)
                    }
                }.padding(10)
                HStack {
                    Button(action: { conductor.octave = max(-2, conductor.octave - 1) }) {
                        Image(systemName: "arrowtriangle.backward.fill").foregroundColor(.white)
                    }
                    Text("Octave: \(conductor.octave)").frame(maxWidth:150)
                    Button(action: { conductor.octave = min(3, conductor.octave + 1) }) {
                        Image(systemName: "arrowtriangle.forward.fill").foregroundColor(.white)
                    }
                }.frame(maxWidth: 400).padding(10)
                SwiftUIKeyboard(firstOctave: conductor.octave, octaveCount: 2, noteOn: conductor.noteOn(pitch:point:), noteOff: conductor.noteOff).frame(maxHeight: 600)
            }
        }.onDisappear() { self.conductor.engine.stop() }
    }
}
