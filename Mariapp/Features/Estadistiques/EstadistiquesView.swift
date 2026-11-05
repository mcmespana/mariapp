import Charts
import SwiftUI

struct EstadistiquesView: View {
    @Environment(DataStore.self) private var store
    @Environment(Navegacio.self) private var nav
    @State private var mesos = 6

    var body: some View {
        let dies = store.dies.items
        let resums = Analisi.perMes(dies, mesos: mesos)
        let millorGimnas = resums.max { $0.diesGimnas < $1.diesGimnas }
        let escala = store.config.escalaCansament

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Període", selection: $mesos) {
                    Text("3 mesos").tag(3)
                    Text("6 mesos").tag(6)
                    Text("1 any").tag(12)
                }
                .pickerStyle(.segmented)

                if dies.isEmpty {
                    Targeta {
                        Text("Encara no hi ha dades. Apunta uns quants dies i ací apareixeran gràfiques boniques 📈")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }

                AnalisiIAView(resum: Analisi.resumPerIA(
                    resums: resums,
                    cafes: Analisi.cafesVsCansament(dies),
                    diaSetmana: Analisi.cansamentPerDiaSetmana(dies),
                    creuaments: Analisi.creuamentsPerIA(dies, escala: escala),
                    escala: escala,
                    objectiuMl: store.config.objectiuMl
                ))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16, alignment: .top)], spacing: 16) {
                    // Gimnàs
                    Targeta(tint: Paleta.verd) {
                        CapcaleraTargeta(icona: "figure.strengthtraining.traditional", titol: "Dies de gimnàs", color: Paleta.verd)
                        if let millor = millorGimnas, millor.diesGimnas > 0 {
                            Text("🏆 El millor mes: \(Dates.mesLlarg(millor.mes)) amb \(millor.diesGimnas) dies")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(Paleta.tinta)
                        }
                        Chart(resums) { r in
                            BarMark(x: .value("Mes", r.mes, unit: .month), y: .value("Dies", r.diesGimnas))
                                .foregroundStyle(r.id == millorGimnas?.id && r.diesGimnas > 0 ? Paleta.groc : Paleta.verd)
                                .cornerRadius(6)
                        }
                        .chartXAxis { eixMesos }
                        .frame(height: 170)
                    }

                    // Cansament
                    Targeta(tint: Paleta.blau) {
                        CapcaleraTargeta(icona: "battery.25percent", titol: "Cansament mitjà", color: Paleta.blau)
                        Chart(resums.filter { $0.cansamentMitja != nil }) { r in
                            LineMark(x: .value("Mes", r.mes, unit: .month), y: .value("Cansament", r.cansamentMitja ?? 0))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Paleta.blau)
                            PointMark(x: .value("Mes", r.mes, unit: .month), y: .value("Cansament", r.cansamentMitja ?? 0))
                                .foregroundStyle(Paleta.blau)
                        }
                        .chartYScale(domain: 0...escala)
                        .chartXAxis { eixMesos }
                        .frame(height: 170)
                    }

                    // Dia de la setmana
                    let perDia = Analisi.cansamentPerDiaSetmana(dies)
                    if !perDia.isEmpty {
                        Targeta(tint: Paleta.blau) {
                            CapcaleraTargeta(icona: "calendar.day.timeline.left", titol: "Quin dia estàs més cansada?", color: Paleta.blau)
                            if let pitjor = perDia.max(by: { $0.mitja < $1.mitja }) {
                                Text("Els \(Analisi.nomsDiesLlargs[pitjor.diaSetmana - 1]) són els més durs 😮‍💨")
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    .foregroundStyle(Paleta.tinta)
                            }
                            Chart(perDia) { d in
                                BarMark(x: .value("Dia", d.nom), y: .value("Cansament", d.mitja))
                                    .foregroundStyle(EscalaCansament.color(Int(d.mitja.rounded()), escala: escala))
                                    .cornerRadius(6)
                            }
                            .chartYScale(domain: 0...escala)
                            .frame(height: 150)
                        }
                    }

                    // Cafés vs cansament
                    let punts = Analisi.cafesVsCansament(dies)
                    if !punts.isEmpty {
                        Targeta(tint: Paleta.cafe) {
                            CapcaleraTargeta(icona: "cup.and.saucer.fill", titol: "Cafés i cansament", color: Paleta.cafe)
                            if let frase = Analisi.fraseCafes(punts, escala: escala) {
                                Text(frase)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Paleta.tinta)
                            }
                            Chart(punts) { p in
                                BarMark(x: .value("Cafés", p.cafes == 5 ? "5+" : "\(p.cafes)"), y: .value("Cansament", p.cansament))
                                    .foregroundStyle(Paleta.cafe.gradient)
                                    .cornerRadius(6)
                                    .annotation(position: .top) {
                                        Text("\(p.dies) d").font(.caption2).foregroundStyle(Paleta.tintaSuau)
                                    }
                            }
                            .chartYScale(domain: 0...escala)
                            .chartXAxisLabel("Cafés al dia")
                            .frame(height: 170)
                        }
                    }

                    // Aigua
                    Targeta(tint: Paleta.aigua) {
                        CapcaleraTargeta(icona: "drop.fill", titol: "Aigua mitjana al dia", color: Paleta.aigua)
                        Chart {
                            ForEach(resums.filter { $0.aiguaMitjana != nil }) { r in
                                BarMark(x: .value("Mes", r.mes, unit: .month), y: .value("ml", r.aiguaMitjana ?? 0))
                                    .foregroundStyle(Paleta.aigua.gradient)
                                    .cornerRadius(6)
                            }
                            RuleMark(y: .value("Objectiu", store.config.objectiuMl))
                                .foregroundStyle(Paleta.aigua.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("objectiu").font(.caption2).foregroundStyle(Paleta.aigua)
                                }
                        }
                        .chartXAxis { eixMesos }
                        .frame(height: 170)
                    }

                    // Dolor
                    Targeta(tint: Paleta.groc) {
                        CapcaleraTargeta(icona: "drop.triangle.fill", titol: "Dies amb molèsties d'orina", color: Paleta.groc)
                        Chart(resums) { r in
                            BarMark(x: .value("Mes", r.mes, unit: .month), y: .value("Dies", r.diesDolor))
                                .foregroundStyle(Paleta.groc.gradient)
                                .cornerRadius(6)
                        }
                        .chartXAxis { eixMesos }
                        .frame(height: 150)
                    }

                    // Creuaments
                    TargetaAiguaMolesties(dies: dies)
                    TargetaCafesMolesties(dies: dies)
                    TargetaGimnasCansament(dies: dies, escala: escala)

                    // Queixes
                    Targeta(tint: Paleta.taronja) {
                        CapcaleraTargeta(icona: "exclamationmark.bubble.fill", titol: "Queixes sobre David", color: Paleta.taronja)
                        let total = resums.reduce(0) { $0 + $1.queixes }
                        if let pitjor = resums.max(by: { $0.queixes < $1.queixes }), pitjor.queixes > 0 {
                            Text("\(total) en total. El mes més queixós: \(Dates.mesLlarg(pitjor.mes)) 😤")
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundStyle(Paleta.tinta)
                        }
                        Chart(resums) { r in
                            LineMark(x: .value("Mes", r.mes, unit: .month), y: .value("Queixes", r.queixes))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Paleta.taronja)
                            AreaMark(x: .value("Mes", r.mes, unit: .month), y: .value("Queixes", r.queixes))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Paleta.taronja.opacity(0.15).gradient)
                        }
                        .chartXAxis { eixMesos }
                        .frame(height: 150)
                    }
                }
            }
            .padding(16)
            .ampleMaxim(1100)
        }
        .fonsMariapp()
        .navigationTitle("Estadístiques")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Resum setmanal", systemImage: "calendar.badge.clock") { nav.mostraResum = true }
                    .labelStyle(.iconOnly)
            }
        }
    }

    private var eixMesos: some AxisContent {
        AxisMarks(values: .stride(by: .month)) { _ in
            AxisGridLine().foregroundStyle(Paleta.linia)
            AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
        }
    }
}
