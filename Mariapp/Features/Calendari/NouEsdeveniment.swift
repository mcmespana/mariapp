import EventKit
import SwiftUI

/// Formulari propi per a crear un esdeveniment (funciona igual en iPhone i Mac).
struct NouEsdeveniment: View {
    @Environment(ServeiCalendari.self) private var calendari
    @Environment(DataStore.self) private var store
    @Environment(Preferencies.self) private var prefs
    @Environment(\.dismiss) private var dismiss

    @State private var titol = ""
    @State private var inici = Calendar.current.date(bySetting: .minute, value: 0, of: Date().addingTimeInterval(3600)) ?? Date()
    @State private var totElDia = false
    @State private var calendariId = ""
    @State private var error: String?

    private var editables: [EKCalendar] {
        calendari.calendaris.filter { $0.allowsContentModifications }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Títol", text: $titol)
                    Toggle("Tot el dia", isOn: $totElDia)
                    DatePicker("Quan", selection: $inici, displayedComponents: totElDia ? .date : [.date, .hourAndMinute])
                    Picker("Calendari", selection: $calendariId) {
                        Text("El per defecte").tag("")
                        ForEach(editables, id: \.calendarIdentifier) { Text($0.title).tag($0.calendarIdentifier) }
                    }
                }
                .listRowBackground(Paleta.paper)

                if let error {
                    Section {
                        Text(error).foregroundStyle(Paleta.taronja)
                    }
                    .listRowBackground(Paleta.paper)
                }
            }
            .formStyle(.grouped)
            .fonsMariapp()
            .navigationTitle("Esdeveniment nou")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel·la") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea", action: crea)
                        .disabled(titol.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 360)
        #endif
    }

    private func crea() {
        let cal = editables.first { $0.calendarIdentifier == calendariId }
        do {
            let e = try calendari.crea(
                titol: titol.trimmingCharacters(in: .whitespaces),
                inici: totElDia ? Calendar.current.startOfDay(for: inici) : inici,
                totElDia: totElDia,
                calendari: cal
            )
            var a = AnotacioEsdeveniment(id: ServeiCalendari.clau(per: e))
            a.propietari = prefs.rol == .david ? .david : .maria
            store.anotacions.desa(a)
            Sons.toca(.campaneta)
            dismiss()
        } catch {
            self.error = "No s'ha pogut crear: \(error.localizedDescription)"
        }
    }
}
