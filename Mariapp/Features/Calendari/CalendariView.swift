import EventKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Un esdeveniment del calendari amb la clau de la seua anotació.
struct ItemAgenda: Identifiable {
    let esdeveniment: EKEvent
    let clau: String
    var id: String { clau + "|" + String(esdeveniment.startDate.timeIntervalSince1970) }
}

struct CalendariView: View {
    @Environment(ServeiCalendari.self) private var calendari

    var body: some View {
        Group {
            if calendari.autoritzat {
                AgendaView()
            } else {
                SenseAccesCalendari()
            }
        }
        .navigationTitle("Calendari")
    }
}

// MARK: - Sense permís

private struct SenseAccesCalendari: View {
    @Environment(ServeiCalendari.self) private var calendari

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("📆")
                    .font(.system(size: 64))
                    .background { BolaClay(color: Paleta.blau, mida: 130) }
                    .padding(.top, 30)
                    .padding(.bottom, 12)
                Text("El calendari de tots dos")
                    .font(.titolGran(26))
                    .foregroundStyle(Paleta.tinta)
                    .multilineTextAlignment(.center)
                Text("Mariapp llig el calendari compartit per a posar-li emojis, colors, de qui és cada cosa i avisos extra. No canvia res si no li ho dius.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button {
                    Task { await calendari.demanaAcces() }
                } label: {
                    Label("Donar accés", systemImage: "lock.open.fill")
                }
                .buttonStyle(.suau(Paleta.blau, ple: true))

                Targeta(tint: Paleta.groc) {
                    CapcaleraTargeta(icona: "questionmark.circle.fill", titol: "No veus el Google Calendar?", color: Paleta.groc)
                    #if os(iOS)
                    Text("Afegeix el compte de Google a Ajustos › Calendari › Comptes › Afegir compte. Després torna ací.")
                    #else
                    Text("Afegeix el compte de Google a Ajustos del sistema › Comptes d'Internet. Després torna ací.")
                    #endif
                    #if canImport(UIKit)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link("Obrir els ajustos de Mariapp", destination: url)
                            .font(.system(.subheadline, design: .rounded).bold())
                    }
                    #endif
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Paleta.tinta)
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .fonsMariapp()
    }
}

// MARK: - Agenda

private struct AgendaView: View {
    @Environment(ServeiCalendari.self) private var calendari
    @Environment(DataStore.self) private var store

    @State private var filtre: Propietari?
    @State private var triat: ItemAgenda?
    @State private var nou = false
    @State private var ajustos = false

    private var items: [ItemAgenda] {
        calendari.esdeveniments
            .map { ItemAgenda(esdeveniment: $0, clau: ServeiCalendari.clau(per: $0)) }
            .filter { filtre == nil || (store.anotacions[$0.clau]?.propietari ?? .tots) == filtre }
    }

    var body: some View {
        let avui = Calendar.current.startOfDay(for: Date())
        let grups = Dictionary(grouping: items) { max(Calendar.current.startOfDay(for: $0.esdeveniment.startDate), avui) }
        let dies = grups.keys.sorted()

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FlowLayout(espai: 8) {
                    XipBoto(text: "Tots", color: Paleta.blau, seleccionat: filtre == nil) { filtre = nil }
                    ForEach(Propietari.allCases) { p in
                        XipBoto(text: "\(p.emoji) \(p.nom)", color: Paleta.blau, seleccionat: filtre == p) {
                            filtre = filtre == p ? nil : p
                        }
                    }
                }

                if dies.isEmpty {
                    Targeta(tint: Paleta.blau) {
                        Text("Res al calendari en els pròxims 60 dies 🌿")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }

                ForEach(dies, id: \.self) { dia in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(Self.titolDia(dia))
                            .font(.titolSeccio)
                            .foregroundStyle(Paleta.tinta)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(grups[dia] ?? []) { item in
                            FilaEsdeveniment(item: item, anotacio: store.anotacions[item.clau]) {
                                triat = item
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .fonsMariapp()
        .animation(Clay.molla, value: filtre)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Calendaris visibles", systemImage: "gearshape") { ajustos = true }
                    .labelStyle(.iconOnly)
                Button("Esdeveniment nou", systemImage: "plus") { nou = true }
                    .labelStyle(.iconOnly)
            }
        }
        .sheet(item: $triat) { item in
            EditaAnotacio(esdeveniment: item.esdeveniment, clau: item.clau)
        }
        .sheet(isPresented: $nou) { NouEsdeveniment() }
        .sheet(isPresented: $ajustos) { AjustosCalendari() }
        .onAppear { calendari.recarrega() }
    }

    static func titolDia(_ dia: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(dia) { return "Hui" }
        if cal.isDateInTomorrow(dia) { return "Demà" }
        return Dates.llarga(dia).capitalizedFirst
    }
}

private struct FilaEsdeveniment: View {
    let item: ItemAgenda
    let anotacio: AnotacioEsdeveniment?
    let toca: () -> Void

    var body: some View {
        let e = item.esdeveniment
        let color = anotacio?.color?.color ?? e.calendar.map { Color(cgColor: $0.cgColor) } ?? Paleta.blau
        Button(action: toca) {
            HStack(spacing: 12) {
                Capsule()
                    .fill(color)
                    .frame(width: 5)
                VStack(alignment: .leading, spacing: 3) {
                    Text(e.isAllDay ? "Tot el dia" : Dates.hora(e.startDate))
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(Paleta.tintaSuau)
                    Text(e.title ?? "Sense títol")
                        .font(.titolTargeta)
                        .foregroundStyle(Paleta.tinta)
                        .multilineTextAlignment(.leading)
                    if let nota = anotacio?.nota, !nota.isEmpty {
                        Text(nota)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 0)
                if let emoji = anotacio?.emoji, !emoji.isEmpty {
                    Text(emoji).font(.title2)
                }
                if let p = anotacio?.propietari {
                    Xip(text: "\(p.emoji) \(p.nom)", color: p.color)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .clay(color, radi: Clay.radiMitja, elevacio: 0.55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
