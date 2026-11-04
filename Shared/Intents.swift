import AppIntents
import Foundation

#if os(iOS)
/// LiveActivityIntent fa que el codi s'execute dins del procés de l'app (també des del widget),
/// així l'acció arriba al núvol immediatament.
typealias IntentRapid = LiveActivityIntent
#else
typealias IntentRapid = AppIntent
#endif

struct SumaAiguaIntent: IntentRapid {
    static let title: LocalizedStringResource = "Apuntar aigua"
    static let description = IntentDescription("Apunta l'aigua que has begut.")

    @Parameter(title: "Mil·lilitres", default: 375)
    var ml: Int

    init() {}
    init(ml: Int) { self.ml = ml }

    func perform() async throws -> some IntentResult {
        await AccionsRapides.executa(.aigua(ml: ml))
        return .result()
    }
}

struct SumaCafeIntent: IntentRapid {
    static let title: LocalizedStringResource = "Apuntar un café"
    static let description = IntentDescription("Suma un café al dia de hui.")

    init() {}

    func perform() async throws -> some IntentResult {
        await AccionsRapides.executa(.cafe(quantitat: 1))
        return .result()
    }
}

struct SumaQueixaIntent: IntentRapid {
    static let title: LocalizedStringResource = "Apuntar una queixa sobre David"
    static let description = IntentDescription("Una altra? Apa, apuntada.")

    init() {}

    func perform() async throws -> some IntentResult {
        await AccionsRapides.executa(.queixa)
        return .result()
    }
}

#if os(iOS)
/// Engega l'activitat en directe del dia. Es pot posar en una automatització de Dreceres (p. ex. a les 9:00).
struct ComencaElDiaIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Començar el dia"
    static let description = IntentDescription("Mostra l'aigua i els cafés de hui a la pantalla de bloqueig.")

    init() {}

    func perform() async throws -> some IntentResult {
        ActivitatHui.comenca(HuiSnapshot.carrega())
        return .result()
    }
}
#endif
