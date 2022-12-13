import SwiftUI
import AudioKit
import Controls
import SoundpipeAudioKit
import AudioToolbox
struct SynthPunkConsoleData {
    var pulseWidth: AUValue = 0.5
    var frequency: AUValue = 440
    var root: AUValue = 0.0
    var frequencyIndex: AUValue = 0
}
class SynthPunkConsoleClass: ObservableObject, MIDIListener {
    let engine = AudioEngine()
    var osc = PWMOscillator(amplitude: 0.1)
    var filter: MoogLadder!
    var dist: AppleDistortion!
    let midi = MIDI()
    @Published var cutoff = AUValue(20_000) {
        didSet { filter.cutoffFrequency = AUValue(cutoff) }
    }
    let keyNotes = [[0,2,4,7],[2,4,5,9],[4,5,7,11],[5,7,9,12],[7,9,11,14],[9,11,12,16],[11,12,14,17],[12,14,16,19]]
    init() {
        filter = MoogLadder(osc, cutoffFrequency: 20_000)
        dist = AppleDistortion(filter, dryWetMix: 20)
        dist.loadFactoryPreset(.multiEcho1)
        engine.output = dist
        try? engine.start()
        midi.addListener(self)
        midi.openInput()
    }
    @Published var data = SynthPunkConsoleData() {
        didSet {
            if data.frequencyIndex >= 0 {
                osc.start()
                osc.$pulseWidth.ramp(to: data.pulseWidth, duration: 0.2)
                osc.$frequency.ramp(to: Int(keyNotes[Int(data.root)][(Int(data.frequencyIndex) % 4)] + (Int(data.frequencyIndex)/4) * 12 + 36).midiNoteToFrequency(), duration: 0.02)
            } else {
                osc.stop()
            }
        }
    }
    func receivedMIDINoteOn(noteNumber: AudioKit.MIDINoteNumber, velocity: AudioKit.MIDIVelocity, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDINoteOff(noteNumber: AudioKit.MIDINoteNumber, velocity: AudioKit.MIDIVelocity, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIController(_ controller: AudioKit.MIDIByte, value: AudioKit.MIDIByte, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        DispatchQueue.main.async {
            if controller == 16 {
                self.data.root = Float(value) / 127.0 * 7
            }else if controller == 17 {
                self.data.frequencyIndex = Float(value) / 127.0 * 21 - 1
            }else if controller == 18 {
                self.data.pulseWidth = Float(value) / 127.0
            }else if controller == 19 {
                self.cutoff = Float(value) / 127.0 * 19980 + 20
            }
        }
    }
    func receivedMIDIAftertouch(noteNumber: AudioKit.MIDINoteNumber, pressure: AudioKit.MIDIByte, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIAftertouch(_ pressure: AudioKit.MIDIByte, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIPitchWheel(_ pitchWheelValue: AudioKit.MIDIWord, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIProgramChange(_ program: AudioKit.MIDIByte, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDISystemCommand(_ data: [AudioKit.MIDIByte], portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDISetupChange() {}
    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {}
    func receivedMIDINotification(notification: MIDINotification) {}
}
struct SynthPunkConsole: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var conductor = SynthPunkConsoleClass()
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.orange.opacity(0.5), .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    SmallKnob(value: self.$conductor.data.root, range: 0 ... 7).padding(20)
                    SmallKnob(value: self.$conductor.data.frequencyIndex, range: -1...20).padding(20)
                }
                HStack {
                    SmallKnob(value: self.$conductor.data.pulseWidth, range: 0 ... 1).padding(20)
                    SmallKnob(value: self.$conductor.cutoff, range: 200.0 ... 20000.0).padding(20)
                }
            }.frame(maxWidth: 500, maxHeight: 500).padding(20)
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if(!conductor.engine.avEngine.isRunning) {
                    try? conductor.engine.start()
                    conductor.midi.openInput()
                }
            } else if newPhase == .background {
                conductor.osc.stop()
                conductor.engine.stop()
                conductor.midi.closeAllInputs()
            }
        }.onDisappear() {
            conductor.osc.stop()
            conductor.engine.stop()
            conductor.midi.closeAllInputs()
        }
    }
}
struct SynthPunkConsole_Previews: PreviewProvider {static var previews: some View {SynthPunkConsole()}}
