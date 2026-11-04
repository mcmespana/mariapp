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
            intent: SumaQueixaIntent(),
            phrases: ["Apunta una queixa a \(.applicationName)"],
            shortTitle: "Queixa",
            systemImageName: "exclamationmark.bubble.fill"
        )
    }
}
