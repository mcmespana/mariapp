import AppIntents

/// Dreceres de Siri / Spotlight / botó d'Acció.
struct DreceresMariapp: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SumaAiguaIntent(),
            phrases: ["Apunta aigua a \(.applicationName)", "He begut aigua a \(.applicationName)"],
            shortTitle: "Aigua",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: SumaCafeIntent(),
            phrases: ["Apunta un café a \(.applicationName)"],
            shortTitle: "Café",
            systemImageName: "cup.and.saucer.fill"
        )
        AppShortcut(
            intent: AfegeixCompraIntent(),
            phrases: ["Afig una cosa a la compra de \(.applicationName)", "Afegeix a la compra de \(.applicationName)"],
            shortTitle: "Afegir a la compra",
            systemImageName: "cart.badge.plus"
        )
        AppShortcut(
            intent: SumaQueixaIntent(),
            phrases: ["Apunta una queixa a \(.applicationName)"],
            shortTitle: "Queixa",
            systemImageName: "exclamationmark.bubble.fill"
        )
    }
}

/// "Afig llet a la compra": Siri pregunta què cal comprar i ho apunta a la llista (només a l'app, no al widget).
struct AfegeixCompraIntent: AppIntent {
    static let title: LocalizedStringResource = "Afegir a la compra"
    static let description = IntentDescription("Afig una cosa a la llista de la compra.")

    @Parameter(title: "Què cal comprar?", requestValueDialog: "Què cal comprar?")
    var nom: String

    init() {}
    init(nom: String) { self.nom = nom }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        let store = DataStore.shared
        guard !text.isEmpty else { return .result(dialog: "No he entés què cal comprar 🤔") }
        guard GeneradorCompra.podeuAfegir(text, a: store.llistaCompra.items) else {
            return .result(dialog: "Ja ho tens a la llista 🛒")
        }
        store.llistaCompra.desa(ElementCompra(nom: text.capitalizedFirst))
        return .result(dialog: "Fet! He afegit «\(text)» a la compra 🛒")
    }
}
