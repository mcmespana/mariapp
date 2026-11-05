import Foundation

/// Un tros de temps de l'anàlisi del son (sense HealthKit: així es pot provar i compilar a tot arreu).
struct IntervalSon: Equatable {
    var inici: Date
    var fi: Date
    /// Dormint de veres (nucli, profund, REM o sense especificar). `false` = al llit despert o despert.
    var dormit: Bool
}

enum CalculSon {
    /// Minuts dormits: unió dels intervals de son (l'iPhone i el Watch es solapen i no s'han de comptar dos voltes),
    /// retallats a la finestra si se'n dona una.
    static func minutsDormits(_ intervals: [IntervalSon], finestra: (inici: Date, fi: Date)? = nil) -> Int {
        let dormits = intervals
            .filter(\.dormit)
            .map { i -> (Date, Date) in
                guard let f = finestra else { return (i.inici, i.fi) }
                return (max(i.inici, f.inici), min(i.fi, f.fi))
            }
            .filter { $0.1 > $0.0 }
            .sorted { $0.0 < $1.0 }

        var total: TimeInterval = 0
        var actual: (inici: Date, fi: Date)?
        for (inici, fi) in dormits {
            if let a = actual, inici <= a.fi {
                if fi > a.fi { actual = (a.inici, fi) }
            } else {
                if let a = actual { total += a.fi.timeIntervalSince(a.inici) }
                actual = (inici, fi)
            }
        }
        if let a = actual { total += a.fi.timeIntervalSince(a.inici) }
        return Int((total / 60).rounded())
    }

    /// La nit que acaba en `dia`: de les 18:00 del dia anterior a les 12:00.
    static func finestra(nit dia: Date, calendari: Calendar = .current) -> (inici: Date, fi: Date) {
        let inici = calendari.startOfDay(for: dia)
        let ahir = calendari.date(byAdding: .day, value: -1, to: inici) ?? inici
        let desde = calendari.date(bySettingHour: 18, minute: 0, second: 0, of: ahir) ?? ahir
        let finsA = calendari.date(bySettingHour: 12, minute: 0, second: 0, of: inici) ?? inici
        return (desde, finsA)
    }

    /// "7 h 20 min", "8 h", "45 min".
    static func text(minuts: Int) -> String {
        let h = minuts / 60
        let m = minuts % 60
        switch (h, m) {
        case (0, _): return "\(m) min"
        case (_, 0): return "\(h) h"
        default: return "\(h) h \(m) min"
        }
    }

    /// "🏋️ Força tradicional · 45 min"
    static func textEntrenament(nom: String, minuts: Int) -> String {
        "🏋️ \(nom) · \(text(minuts: minuts))"
    }
}
