import SwiftUI

struct EditaCita: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let esNova: Bool
    @State private var cita: Cita
    @State private var data: Date
    @State private var alCalendari: Bool
    @State private var recorda: Bool
    @State private var dataRecordatori: Date
    @State private var avisos: Set<Int>
    @State private var vesprada: Bool
    @State private var alarma: Bool
    @State private var alarmaMinuts: Int
    @State private var confirmaEsborrar = false

    private static let estandard = [10080, 4320, 1440, 180, 120, 60, 30]
    private static let opcionsAlarma = [720, 180, 120, 60, 30]

    init(cita: Cita? = nil, forcaProgramada: Bool = false) {
        var c = cita ?? Cita(titol: "")
        if forcaProgramada { c.estat = .programada }
        esNova = cita == nil
        let cal = Calendar.current
        let demaMati = cal.date(bySettingHour: 10, minute: 0, second: 0, of: cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()) ?? Date()
        let d = c.data ?? demaMati
        _data = State(initialValue: d)
        _alCalendari = State(initialValue: cita == nil || cita!.estat != .programada || cita!.esdevenimentId != nil || forcaProgramada)
        _recorda = State(initialValue: c.recordarDemanarEl != nil || (cita == nil))
        _dataRecordatori = State(initialValue: c.recordarDemanarEl ?? demaMati)
        var set = Set(c.avisos)
        let mv = Compte.minutsVesprada(d)
        let teVesprada = mv.map { set.contains($0) } ?? false
        if teVesprada, let mv, !Self.estandard.contains(mv) { set.remove(mv) }
        _avisos = State(initialValue: set)
        _vesprada = State(initialValue: teVesprada)
        #if os(iOS)
        _alarma = State(initialValue: cita == nil ? true : c.alarmaMinuts != nil)
        #else
        _alarma = State(initialValue: false)
        #endif
        _alarmaMinuts = State(initialValue: c.alarmaMinuts ?? 120)
        _cita = State(initialValue: c)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("La cita") {
                    TextField("Què és? (revisió, analítica…)", text: $cita.titol)
                    Picker("Categoria", selection: $cita.categoriaId) {
                        ForEach(store.categoriesOrdenades) { Text("\($0.emoji) \($0.nom)").tag($0.id) }
                    }
                    Picker("Estat", selection: $cita.estat) {
                        ForEach(EstatCita.allCases) { Text($0.nom).tag($0) }
                    }
                }
                .listRowBackground(Paleta.paper)

                if cita.estat == .perDemanar {
                    Section {
                        Toggle("Recorda'm demanar-la", isOn: $recorda)
                        if recorda {
                            DatePicker("El", selection: $dataRecordatori)
                        }
                    } footer: {
                        Text("Saltarà un avís amb sirena perquè agafes el telèfon 📞")
                    }
                    .listRowBackground(Paleta.paper)
                } else {
                    Section("Quan i on") {
                        DatePicker("Data i hora", selection: $data)
                        Stepper(value: $cita.duradaMinuts, in: 15...480, step: 15) {
                            LabeledContent("Durada", value: "\(cita.duradaMinuts) min")
                        }
                        TextField("Lloc", text: $cita.lloc)
                    }
                    .listRowBackground(Paleta.paper)
                }

                if cita.estat == .programada {
                    Section {
                        FlowLayout(espai: 8) {
                            ForEach(chips, id: \.self) { m in
                                XipBoto(text: Self.nomAvis(m), color: Paleta.alerta, seleccionat: avisos.contains(m)) {
                                    if avisos.contains(m) { avisos.remove(m) } else { avisos.insert(m) }
                                }
                            }
                            XipBoto(text: "La vesprada abans (19:00)", color: Paleta.alerta, seleccionat: vesprada) {
                                vesprada.toggle()
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Avisos 🚨")
                    } footer: {
                        Text("Pots triar-ne uns quants. Cada un sona amb la sirena.")
                    }
                    .listRowBackground(Paleta.paper)

                    #if os(iOS)
                    Section {
                        Toggle("⏰ Alarma de despertador", isOn: $alarma)
                        if alarma {
                            Picker("Sona", selection: $alarmaMinuts) {
                                ForEach(Self.opcionsAlarma, id: \.self) { Text("\(Self.nomAvis($0)) abans").tag($0) }
                            }
                        }
                    } footer: {
                        Text("Sona encara que el mòbil estiga en silenci, amb pantalla completa.")
                    }
                    .listRowBackground(Paleta.paper)
                    #endif

                    Section {
                        Toggle("Afegir al calendari", isOn: $alCalendari)
                    }
                    .listRowBackground(Paleta.paper)
                }

                Section("Notes") {
                    TextField("Què cal portar, preguntes per al metge…", text: $cita.notes, axis: .vertical)
                        .lineLimit(2...6)
                }
                .listRowBackground(Paleta.paper)

                if !esNova {
                    Section {
                        Button("Esborrar la cita", systemImage: "trash") { confirmaEsborrar = true }
                            .foregroundStyle(Paleta.cafe)
                    }
                    .listRowBackground(Paleta.paper)
                }
            }
            .formStyle(.grouped)
            .fonsMariapp()
            .navigationTitle(esNova ? "Cita nova" : "Edita la cita")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel·la") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Desa", action: desa)
                        .disabled(cita.titol.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Esborrar «\(cita.titol)»?", isPresented: $confirmaEsborrar, titleVisibility: .visible) {
                Button("Esborra", role: .destructive) {
                    ServeiCites.esborra(cita)
                    dismiss()
                }
                Button("Cancel·la", role: .cancel) {}
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 640)
        #endif
    }

    private var chips: [Int] {
        Array(Set(Self.estandard).union(avisos)).sorted(by: >)
    }

    static func nomAvis(_ m: Int) -> String {
        switch m {
        case ..<60: return "\(m) min"
        case 60: return "1 hora"
        case ..<1440: return "\(m / 60) hores"
        case 1440: return "1 dia"
        case ..<10080: return "\(m / 1440) dies"
        case 10080: return "1 setmana"
        default: return "\(m / 10080) setmanes"
        }
    }

    private func desa() {
        var c = cita
        c.titol = c.titol.trimmingCharacters(in: .whitespaces)
        c.data = c.estat == .perDemanar ? nil : data
        var finals = avisos
        if vesprada, let m = Compte.minutsVesprada(data) { finals.insert(m) }
        c.avisos = finals.sorted(by: >)
        c.recordarDemanarEl = (c.estat == .perDemanar && recorda) ? dataRecordatori : nil
        c.alarmaMinuts = (c.estat == .programada && alarma) ? alarmaMinuts : nil
        let calendari = alCalendari
        Task { await ServeiCites.desa(c, alCalendari: calendari) }
        dismiss()
    }
}
