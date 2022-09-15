import SwiftUI
import AudioKit
import AVFoundation
class DrumClass: ObservableObject {
    let engine = AudioEngine()
    var instrument = AppleSampler()
    @Published var playing : [Bool] = Array(repeating: false, count: 16)
    let notes = [36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51]
    let names = ["KICK","CLOSED HI-HAT","SNARE","OPEN HI-HAT","RIM SHOT","CRASH","TOM I","TOM II","PAD I","PAD II","PAD III","PAD IV","PAD V","PAD VI","PAD VII","PAD VIII"]
    init() {
        engine.output = instrument
        try? instrument.loadInstrument(url: Bundle.main.url(forResource: "Sounds/GuitarTaps", withExtension: "exs")!)
        try? engine.start()
    }
}
struct DrumView: Identifiable, View {
    @EnvironmentObject var conductor: DrumClass
    @GestureState private var isPressed = false
    var id: Int
    var body: some View {
        RoundedRectangle(cornerRadius: 20.0).fill(conductor.playing[id] ? Color.blue : Color.blue.opacity(0.5)).aspectRatio(contentMode: .fit)
            .gesture(DragGesture(minimumDistance: 0).updating($isPressed) { (value, gestureState, transaction) in
                    gestureState = true
                }).onChange(of: isPressed, perform: { (pressed) in
                    if pressed {
                        conductor.playing[id] = true
                        conductor.instrument.play(noteNumber: MIDINoteNumber(conductor.notes[id]), velocity: 90, channel: 0)
                    } else {
                        conductor.playing[id] = false
                        conductor.instrument.stop(noteNumber: MIDINoteNumber(conductor.notes[id]), channel: 0)
                    }
                }).overlay (
                Text(conductor.names[id]).allowsHitTesting(false)
            )
    }
}
struct DrumPads: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var conductor = DrumClass()
    func reloadAudio() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if !conductor.engine.avEngine.isRunning {
                try? conductor.instrument.loadInstrument(url: Bundle.main.url(forResource: "Sounds/GuitarTaps", withExtension: "exs")!)
                try? conductor.engine.start()
            }
        }
    }
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.blue.opacity(0.5), .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack{
                ForEach(0..<4) { x in
                    HStack{
                        ForEach(0..<4) { y in
                            DrumView(id: y + (x * 4))
                        }
                    }
                }
            }.padding(10)
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if !conductor.engine.avEngine.isRunning {
                    try? conductor.instrument.loadInstrument(url: Bundle.main.url(forResource: "Sounds/GuitarTaps", withExtension: "exs")!)
                    try? conductor.engine.start()
                }
            } else if newPhase == .background {
                conductor.engine.stop()
            }
        }.onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { event in
            switch event.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt {
            case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
                    reloadAudio()
            case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
                    reloadAudio()
            default:
                break
            }
        }.onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { event in
            guard let info = event.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            if type == .began {
                self.conductor.engine.stop()
            } else if type == .ended {
                guard let optionsValue =
                        info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return
                }
                if AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                            reloadAudio()
                }
            }
        }.onDisappear() {
            self.conductor.engine.stop()
        }.environmentObject(conductor)
    }
}
