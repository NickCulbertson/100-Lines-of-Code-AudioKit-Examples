import SwiftUI
import AudioKit
class SequencerClass: ObservableObject {
    let engine = AudioEngine()
    var instrument = AppleSampler()
    var sequencer = AppleSequencer()
    var midiCallback = MIDICallbackInstrument()
    @Published var playing : [Bool] = Array(repeating: false, count: 256)
    @Published var rowIsActive = -1
    let notes = [36,37,38,40,41,42]
    var isLoading = false
    init() {
        midiCallback.callback = { status, note, velocity in
            if status == 144 { //Note On
                let beat = self.sequencer.currentRelativePosition.beats * 4
                if Int(beat) < 12 {
                    self.isLoading = false
                }
                if !self.isLoading {
                    self.rowIsActive = Int(beat)
                    self.instrument.play(noteNumber: note, velocity: velocity, channel: 0)
                }
            } else if status == 128 { //Note Off
                self.instrument.stop(noteNumber: note, channel: 0)
                self.rowIsActive = -1
            }
        }
        engine.output = instrument
        try? instrument.loadInstrument(url: Bundle.main.url(forResource: "Sounds/GuitarTaps", withExtension: "exs")!)
        try? engine.start()
        sequencer.newTrack("Track 1")
        sequencer.setLength(Duration(beats: 4))
        sequencer.setGlobalMIDIOutput(midiCallback.midiIn)
        sequencer.enableLooping()
    }
}
struct SequencerPadView: Identifiable, View {
    @EnvironmentObject var conductor: SequencerClass
    @GestureState private var isPressed = false
    var id: Int
    @State var isActive = false
    var body: some View {
        RoundedRectangle(cornerRadius: .infinity).fill(conductor.playing[id] ? Color.purple : Color.purple.opacity(0.2)).aspectRatio(contentMode: .fit).shadow(color: Color.purple, radius: isActive ? 5 : 0, x: 0, y: 0)
            .gesture(DragGesture(minimumDistance: 0).updating($isPressed) { (value, gestureState, transaction) in
                gestureState = true
            }).onChange(of: isPressed, perform: { (pressed) in
                if pressed {
                    conductor.playing[id].toggle()
                    if conductor.playing[id] { // Add 16th
                        conductor.sequencer.tracks.first?.add(noteNumber: MIDINoteNumber(conductor.notes[Int(id / 16)]), velocity: 127, position: Duration(beats: 0.25 * Double(id % 16)), duration: Duration(beats: 0.25))
                    } else { // Remove 16th
                        conductor.sequencer.clearRange(start: Duration(beats: 0.25 * Double(id % 16)), duration: Duration(beats: 0.25))
                        for x in -5...5 { // Add active notes back in
                            if id + (x * 16) >= 0 && id + (x * 16) <= conductor.playing.count && conductor.playing[id + (x * 16)] { // Re-Add 16th
                                conductor.sequencer.tracks.first?.add(noteNumber: MIDINoteNumber(conductor.notes[Int(id / 16) + x]), velocity: 127, position: Duration(beats: 0.25 * Double(id % 16)), duration: Duration(beats: 0.25))
                            }
                        }
                    }
                }
            }).onChange(of: conductor.rowIsActive) { newValue in
                if newValue == id % 16 && conductor.playing[id] {
                    isActive = true
                } else {
                    isActive = false
                }
            }
    }
}
struct Sequencer: View {
    @StateObject var conductor = SequencerClass()
    @State var isPlaying = false
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.purple.opacity(0.5), .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack{
                Text(isPlaying ? "STOP" : "START").bold().foregroundColor(.blue).onTapGesture {
                    isPlaying.toggle()
                    if isPlaying {
                        conductor.isLoading = true
                        conductor.sequencer.setTime(3)
                        conductor.sequencer.play()
                    } else {
                        conductor.sequencer.stop()
                    }
                }.padding(10)
                ForEach(0..<5) { x in
                    HStack{
                        ForEach(0..<16) { y in
                            SequencerPadView(id: y + (x * 16))
                        }
                    }
                }
            }.padding(10)
        }.onDisappear() {
            self.conductor.sequencer.stop()
            self.conductor.engine.stop()
        }.environmentObject(conductor)
    }
}
