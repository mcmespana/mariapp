import EventKit
import SwiftUI

/// Decorar un esdeveniment: de qui és, emoji, color, nota i avisos extra.
struct EditaAnotacio: View {
    let esdeveniment: EKEvent
    let clau: String

    @Environment(DataStore.self) private var store
    @Environment(Preferencies.self) private var prefs
    @Environment(\.dismiss) private var dismiss

    @State private var anotacio: AnotacioEsdeveniment
    @State private var nota: String
    private let existia: Bool
    private static let suggerits = ["🎂", "🍽️", "✈️", "🏥", "💼", "🎉", "🏋️‍♀️", "🛒", "💇‍♀️"]

    init(esdeveniment: EKEvent, clau: String) {
        self.esdeveniment = esdeveniment
        self.clau = clau
        let existent = DataStore.shared.anotacions[clau]
        existia = existent != nil
        _anotacio = State(initialValue: existent ?? AnotacioEsdeveniment(id: clau))
        _nota = State(initialValue: existent?.nota ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(esdeveniment.title ?? "Sense títol")
                            .font(.titolTargeta)
                        Text(quan)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }
                .listRowBackground(Paleta.paper)

                Section("De qui és?") {
                    Picker("Propietari", selection: $anotacio.propietari) {
                        ForEach(Propietari.allCases) { Text("\($0.emoji) \($0.nom)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .listRowBackground(Paleta.paper)

                Section("Emoji") {
                    FlowLayout(espai: 8) {
                        ForEach(Self.suggerits, id: \.self) { e in
                            Button {
                                anotacio.emoji = anotacio.emoji == e ? nil : e
                            } label: {
                                Text(e)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .clay(Paleta.blau, radi: 14, elevacio: anotacio.emoji == e ? 0.15 : 0.5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    TextField("Un altre emoji", text: Binding(
                        get: { anotacio.emoji ?? "" },
                        set: { anotacio.emoji = $0.isEmpty ? nil : String($0.prefix(1)) }
                    ))
                }
                .listRowBackground(Paleta.paper)

                Section("Color") {
                    HStack(spacing: 14) {
                        ForEach(ColorEtiqueta.allCases) { c in
                            Button {
                                anotacio.color = anotacio.color == c ? nil : c
                            } label: {
                                BolaClay(color: c.color, mida: anotacio.color == c ? 38 : 30)
                                    .overlay {
                                        if anotacio.color == c {
                                            Image(systemName: "checkmark").font(.footnote.bold()).foregroundStyle(.white)
                                        }
                                    }
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(c.nom)
                            .animation(Clay.molla, value: anotacio.color)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Paleta.paper)

                Section("Nota") {
                    TextField("Una nota per a tots dos…", text: $nota, axis: .vertical)
                        .lineLimit(2...6)
                }
                .listRowBackground(Paleta.paper)

                Section {
                    FlowLayout(espai: 8) {
                        ForEach(AvisosAnotacio.opcions, id: \.self) { m in
                            XipBoto(text: AvisosAnotacio.nom(m), color: Paleta.blau, seleccionat: anotacio.avisos.contains(m)) {
                                if let i = anotacio.avisos.firstIndex(of: m) {
                                    anotacio.avisos.remove(at: i)
                                } else {
                                    anotacio.avisos.append(m)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Avisos extra 🔔")
                } footer: {
                    Text("Només sonen al mòbil de la Maria.")
                }
                .listRowBackground(Paleta.paper)

                if existia {
                    Section {
                        Button("Treure la decoració", systemImage: "xmark.circle") { treu() }
                            .foregroundStyle(Paleta.cafe)
                    }
                    .listRowBackground(Paleta.paper)
                }
            }
            .formStyle(.grouped)
            .fonsMariapp()
            .navigationTitle("Decorar")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel·la") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Desa", action: desa)
                }
            }
            .onAppear {
                // Una anotació nova comença sent del qui l'està fent.
                if !existia { anotacio.propietari = prefs.rol == .david ? .david : .maria }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 620)
        #endif
    }

    private var quan: String {
        if esdeveniment.isAllDay { return "\(Dates.llarga(esdeveniment.startDate).capitalizedFirst) · tot el dia" }
        return "\(Dates.llarga(esdeveniment.startDate).capitalizedFirst) · \(Dates.hora(esdeveniment.startDate))"
    }

    private func desa() {
        var a = anotacio
        a.nota = nota.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : nota
        store.anotacions.desa(a)
        Avisos.programa(anotacio: a, titol: esdeveniment.title ?? "Esdeveniment", inici: esdeveniment.startDate)
        Sons.toca(.campaneta)
        dismiss()
    }

    private func treu() {
        store.anotacions.esborra(id: clau)
        Avisos.cancela(anotacioId: clau)
        dismiss()
    }
}
