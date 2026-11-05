import Foundation

/// Suggeriments de plats SENSE IA. Lògica pura: sense UI ni estat, fàcil de provar.
enum SuggeridorMenu {
    /// Puntuació d'un plat per a un àpat.
    /// +3 si té l'etiqueta de l'àpat, +2 lleuger per a sopars, +2 preferit,
    /// −5 si ja és esta setmana, −2 si es va menjar la setmana passada, + un poc d'atzar.
    static func punts(_ plat: Plat, apat: Apat, aquestaSetmana: Set<String>, anterior: Set<String>, atzar: Double = 0) -> Double {
        var p = 0.0
        if plat.etiquetes.contains(apat.etiqueta) { p += 3 }
        if apat == .sopar && plat.etiquetes.contains(.lleuger) { p += 2 }
        if plat.favorit { p += 2 }
        if aquestaSetmana.contains(plat.id) { p -= 5 }
        if anterior.contains(plat.id) { p -= 2 }
        return p + atzar
    }

    /// Els millors plats per a un àpat (per defecte, els 5 primers).
    static func suggeriments(
        plats: [Plat],
        apat: Apat,
        setmana: MenuSetmana?,
        anterior: MenuSetmana?,
        limit: Int = 5,
        atzar: () -> Double = { Double.random(in: 0..<0.9) }
    ) -> [Plat] {
        let ara = setmana?.platIds ?? []
        let abans = anterior?.platIds ?? []
        let puntuats = plats.map { ($0, punts($0, apat: apat, aquestaSetmana: ara, anterior: abans, atzar: atzar())) }
        return puntuats
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.nom < $1.0.nom }
            .prefix(limit)
            .map(\.0)
    }

    /// Omple els forats buits de la setmana (sense tocar els que ja tenen alguna cosa).
    static func omple(
        setmana: MenuSetmana,
        plats: [Plat],
        anterior: MenuSetmana?,
        atzar: () -> Double = { Double.random(in: 0..<0.9) }
    ) -> MenuSetmana {
        guard !plats.isEmpty else { return setmana }
        var menu = setmana
        for dia in 1...7 {
            for apat in Apat.allCases where menu.entrada(dia: dia, apat: apat) == nil {
                if let plat = suggeriments(plats: plats, apat: apat, setmana: menu, anterior: anterior, limit: 1, atzar: atzar).first {
                    menu.posa(EntradaMenu(platId: plat.id), dia: dia, apat: apat)
                }
            }
        }
        return menu
    }

    /// Copia els forats de la setmana anterior als forats buits d'esta.
    static func copia(de anterior: MenuSetmana, a setmana: MenuSetmana) -> MenuSetmana {
        var menu = setmana
        for dia in 1...7 {
            for apat in Apat.allCases where menu.entrada(dia: dia, apat: apat) == nil {
                if let e = anterior.entrada(dia: dia, apat: apat) {
                    menu.posa(e, dia: dia, apat: apat)
                }
            }
        }
        return menu
    }
}
