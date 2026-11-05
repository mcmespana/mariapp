import AVFoundation
import Foundation

/// Sonets divertits de l'app. Els fitxers són a Resources/Sons (generats amb scripts/genera-sons.py).
enum So: String, CaseIterable {
    case gota       // aigua
    case campaneta  // avisos suaus
    case cafe       // café
    case queixa     // queixa sobre David (trombó trist)
    case sirena     // metges: ALERTA
    case festa      // gimnàs / fites

    var fitxer: String { "\(rawValue).wav" }
}

enum Sons {
    private static var reproductors: [So: AVAudioPlayer] = [:]

    static func toca(_ so: So) {
        guard Preferencies.shared.sonsActius else { return }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        #endif
        if reproductors[so] == nil,
           let url = Bundle.main.url(forResource: so.rawValue, withExtension: "wav") {
            reproductors[so] = try? AVAudioPlayer(contentsOf: url)
        }
        reproductors[so]?.currentTime = 0
        reproductors[so]?.play()
    }
}
