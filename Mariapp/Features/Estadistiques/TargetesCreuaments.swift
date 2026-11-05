import Charts
import SwiftUI

/// "Aigua i molèsties": quin percentatge de dies té molèsties segons l'aigua beguda (el mateix dia o el dia abans).
struct TargetaAiguaMolesties: View {
    let dies: [Dia]

    @State private var diaAbans = false

    var body: some View {
        let punts = diaAbans ? Analisi.aiguaAhirVsMolesties(dies) : Analisi.aiguaVsMolesties(dies)
        Targeta(tint: Paleta.groc) {
            CapcaleraTargeta(icona: "drop.degreesign.fill", titol: "Aigua i molèsties", color: Paleta.groc)

            Picker("Aigua de…", selection: $diaAbans.animation(Clay.molla)) {
                Text("El mateix dia").tag(false)
                Text("El dia abans").tag(true)
            }
            .pickerStyle(.segmented)

            if let frase = Analisi.fraseAiguaMolesties(punts) {
                Text(frase)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Paleta.tinta)
                    .contentTransition(.opacity)
            } else {
                Text("Encara no hi ha prou dies per a dir res 🤷‍♀️")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
            }

            if !punts.isEmpty {
                Chart(punts) { p in
                    BarMark(x: .value("Aigua", p.tram.nom), y: .value("% de dies amb molèsties", p.percentatge))
                        .foregroundStyle(Paleta.groc.gradient)
                        .cornerRadius(6)
                        .annotation(position: .top) {
                            Text("\(p.dies) d").font(.caption2).foregroundStyle(Paleta.tintaSuau)
                        }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { valor in
                        AxisGridLine().foregroundStyle(Paleta.linia)
                        AxisValueLabel {
                            if let v = valor.as(Int.self) { Text("\(v) %") }
                        }
                    }
                }
                .chartXAxisLabel("Aigua beguda")
                .frame(height: 170)
            }

            Text("Són correlacions, no diagnòstics. Si les molèsties continuen, comenta-ho amb la metgessa 🩺")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Paleta.tintaSuau)
        }
    }
}

/// "Gimnàs i cansament de l'endemà", només si hi ha dies de les dues coses.
struct TargetaGimnasCansament: View {
    let dies: [Dia]
    let escala: Int

    var body: some View {
        let r = Analisi.gimnasVsCansamentEndema(dies)
        if r.hiHaDades, let a = r.cansamentAmbGimnas, let b = r.cansamentSenseGimnas {
            Targeta(tint: Paleta.verd) {
                CapcaleraTargeta(icona: "figure.strengthtraining.traditional", titol: "Gimnàs i cansament de l'endemà", color: Paleta.verd)
                if let frase = Analisi.fraseGimnasCansament(r, escala: escala) {
                    Text(frase)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Paleta.tinta)
                } else {
                    Text("Encara no hi ha prou dies per a dir res 🤷‍♀️")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
                Chart {
                    BarMark(x: .value("Dia abans", "Amb gimnàs"), y: .value("Cansament", a))
                        .foregroundStyle(Paleta.verd.gradient)
                        .cornerRadius(6)
                        .annotation(position: .top) { Text("\(r.diesAmbGimnas) d").font(.caption2).foregroundStyle(Paleta.tintaSuau) }
                    BarMark(x: .value("Dia abans", "Sense gimnàs"), y: .value("Cansament", b))
                        .foregroundStyle(Paleta.blau.gradient)
                        .cornerRadius(6)
                        .annotation(position: .top) { Text("\(r.diesSenseGimnas) d").font(.caption2).foregroundStyle(Paleta.tintaSuau) }
                }
                .chartYScale(domain: 0...escala)
                .frame(height: 150)
            }
        }
    }
}

/// "Cafés i molèsties" en una frase (sense gràfica), només si hi ha prou dies.
struct TargetaCafesMolesties: View {
    let dies: [Dia]

    var body: some View {
        if let frase = Analisi.fraseCafesMolesties(Analisi.cafesVsMolesties(dies)) {
            Targeta(tint: Paleta.cafe) {
                CapcaleraTargeta(icona: "cup.and.saucer.fill", titol: "Cafés i molèsties", color: Paleta.cafe)
                Text(frase)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Paleta.tinta)
            }
        }
    }
}

/// "Son": hores dormides de mitjana per mes (si hi ha dades d'Apple Salut).
struct TargetaSon: View {
    let resums: [ResumMes]

    var body: some View {
        let amb = resums.filter { $0.sonMitjaHores != nil }
        if !amb.isEmpty {
            Targeta(tint: Paleta.blau) {
                CapcaleraTargeta(icona: "bed.double.fill", titol: "Son", color: Paleta.blau)
                if let ultim = amb.last, let h = ultim.sonMitjaHores {
                    Text("😴 \(CalculSon.text(minuts: Int((h * 60).rounded()))) de mitjana en \(Dates.mesLlarg(ultim.mes))")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Paleta.tinta)
                }
                Chart(amb) { r in
                    BarMark(x: .value("Mes", r.mes, unit: .month), y: .value("Hores", r.sonMitjaHores ?? 0))
                        .foregroundStyle(Paleta.blau.gradient)
                        .cornerRadius(6)
                }
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine().foregroundStyle(Paleta.linia)
                        AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
                    }
                }
                .frame(height: 150)
            }
        }
    }
}

/// "Son i cansament": el cansament d'un dia segons les hores dormides la nit abans.
struct TargetaSonCansament: View {
    let dies: [Dia]
    let escala: Int

    var body: some View {
        let punts = Analisi.sonVsCansament(dies)
        if !punts.isEmpty {
            Targeta(tint: Paleta.blau) {
                CapcaleraTargeta(icona: "moon.zzz.fill", titol: "Son i cansament", color: Paleta.blau)
                if let frase = Analisi.fraseSonCansament(punts, escala: escala) {
                    Text(frase)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Paleta.tinta)
                } else {
                    Text("Encara no hi ha prou dies per a dir res 🤷‍♀️")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
                Chart(punts) { p in
                    BarMark(x: .value("Son", p.tram.nom), y: .value("Cansament", p.cansamentMitja))
                        .foregroundStyle(EscalaCansament.color(Int(p.cansamentMitja.rounded()), escala: escala).gradient)
                        .cornerRadius(6)
                        .annotation(position: .top) { Text("\(p.dies) d").font(.caption2).foregroundStyle(Paleta.tintaSuau) }
                }
                .chartYScale(domain: 0...escala)
                .chartXAxisLabel("Hores dormides la nit abans")
                .frame(height: 160)
            }
        }
    }
}
