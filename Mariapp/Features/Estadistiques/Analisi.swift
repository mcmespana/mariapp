import Foundation

/// Càlculs de les estadístiques (sense UI, fàcil de provar).
struct ResumMes: Identifiable {
    let mes: Date              // primer dia del mes
    var diesGimnas = 0
    var sumaCansament = 0
    var diesCansament = 0
    var sumaAigua = 0
    var diesAigua = 0
    var sumaCafes = 0
    var diesCafes = 0
    var diesDolor = 0
    var queixes = 0

    var id: Date { mes }
    var cansamentMitja: Double? { diesCansament > 0 ? Double(sumaCansament) / Double(diesCansament) : nil }
    var aiguaMitjana: Double? { diesAigua > 0 ? Double(sumaAigua) / Double(diesAigua) : nil }
    var cafesMitjans: Double? { diesCafes > 0 ? Double(sumaCafes) / Double(diesCafes) : nil }
}

struct PuntCafeCansament: Identifiable {
    let cafes: Int
    let cansament: Double
    let dies: Int
    var id: Int { cafes }
}

struct CansamentDiaSetmana: Identifiable {
    let diaSetmana: Int   // 1 = dilluns
    let nom: String
    let mitja: Double
    var id: Int { diaSetmana }
}

enum Analisi {
    static let nomsDies = ["dl", "dt", "dc", "dj", "dv", "ds", "dg"]
    static let nomsDiesLlargs = ["dilluns", "dimarts", "dimecres", "dijous", "divendres", "dissabte", "diumenge"]

    static func perMes(_ dies: [Dia], mesos: Int = 12, ara: Date = Date()) -> [ResumMes] {
        let cal = Calendar.current
        guard let iniciMesActual = cal.date(from: cal.dateComponents([.year, .month], from: ara)) else { return [] }
        var resums: [Date: ResumMes] = [:]
        for i in 0..<mesos {
            if let m = cal.date(byAdding: .month, value: -i, to: iniciMesActual) {
                resums[m] = ResumMes(mes: m)
            }
        }
        for d in dies {
            guard let m = cal.date(from: cal.dateComponents([.year, .month], from: d.data)), var r = resums[m] else { continue }
            if d.gimnas { r.diesGimnas += 1 }
            if let c = d.cansament { r.sumaCansament += c; r.diesCansament += 1 }
            if d.aiguaMl > 0 { r.sumaAigua += d.aiguaMl; r.diesAigua += 1 }
            if d.cafes > 0 || d.cansament != nil { r.sumaCafes += d.cafes; r.diesCafes += 1 }
            if d.teDolor { r.diesDolor += 1 }
            r.queixes += d.queixes
            resums[m] = r
        }
        return resums.values.sorted { $0.mes < $1.mes }
    }

    /// Cansament mitjà segons els cafés del dia (només dies amb cansament apuntat).
    static func cafesVsCansament(_ dies: [Dia]) -> [PuntCafeCansament] {
        var grups: [Int: [Int]] = [:]
        for d in dies {
            guard let c = d.cansament else { continue }
            grups[min(d.cafes, 5), default: []].append(c)
        }
        return grups.map { cafes, valors in
            PuntCafeCansament(cafes: cafes, cansament: Double(valors.reduce(0, +)) / Double(valors.count), dies: valors.count)
        }
        .sorted { $0.cafes < $1.cafes }
    }

    static func cansamentPerDiaSetmana(_ dies: [Dia]) -> [CansamentDiaSetmana] {
        let cal = Calendar.current
        var grups: [Int: [Int]] = [:]
        for d in dies {
            guard let c = d.cansament else { continue }
            // weekday: 1 = diumenge … 7 = dissabte → 1 = dilluns … 7 = diumenge
            let w = cal.component(.weekday, from: d.data)
            let idx = (w + 5) % 7 + 1
            grups[idx, default: []].append(c)
        }
        return grups.map { idx, valors in
            CansamentDiaSetmana(diaSetmana: idx, nom: nomsDies[idx - 1], mitja: Double(valors.reduce(0, +)) / Double(valors.count))
        }
        .sorted { $0.diaSetmana < $1.diaSetmana }
    }

    /// Frase sobre la relació cafés–cansament.
    static func fraseCafes(_ punts: [PuntCafeCansament], escala: Int) -> String? {
        let pocs = punts.filter { $0.cafes <= 1 }
        let molts = punts.filter { $0.cafes >= 3 }
        func mitja(_ p: [PuntCafeCansament]) -> Double? {
            let dies = p.reduce(0) { $0 + $1.dies }
            guard dies >= 3 else { return nil }
            return p.reduce(0) { $0 + $1.cansament * Double($1.dies) } / Double(dies)
        }
        guard let a = mitja(pocs), let b = mitja(molts) else { return nil }
        let f = { (x: Double) in escala > 10 ? "\(Int(x.rounded()))" : String(format: "%.1f", x).replacingOccurrences(of: ".", with: ",") }
        let llindar = Double(escala) * 0.05
        if b > a + llindar {
            return "Els dies de 3 o més cafés estàs més cansada (\(f(b))) que els de 0–1 (\(f(a))). El café no ho arregla tot ☕️"
        } else if a > b + llindar {
            return "Els dies de 0–1 cafés estàs més cansada (\(f(a))) que els de 3 o més (\(f(b)))."
        }
        return "El café no sembla canviar gaire el cansament (\(f(a)) vs \(f(b)))."
    }
}
