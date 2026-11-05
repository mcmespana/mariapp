import EventKit
import SwiftUI

/// Quins calendaris es mostren a l'agenda.
struct AjustosCalendari: View {
    @Environment(ServeiCalendari.self) private var calendari
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(calendari.calendaris, id: \.calendarIdentifier) { c in
                        Toggle(isOn: Binding(
                            get: { visible(c) },
                            set: { canvia(c, $0) }
                        )) {
                            HStack(spacing: 10) {
                                Circle().fill(Color(cgColor: c.cgColor)).frame(width: 12, height: 12)
                                Text(c.title)
                                Text(c.source.title)
                                    .font(.footnote)
                                    .foregroundStyle(Paleta.tintaSuau)
                            }
                        }
                    }
                } header: {
                    Text("Calendaris visibles")
                } footer: {
                    Text("Tria els que vols veure a l'agenda. Almenys un ha de quedar actiu.")
                }
                .listRowBackground(Paleta.paper)
            }
            .formStyle(.grouped)
            .fonsMariapp()
            .navigationTitle("Calendaris")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fet") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 400)
        #endif
    }

    private func visible(_ c: EKCalendar) -> Bool {
        calendari.calendarisVisibles.isEmpty || calendari.calendarisVisibles.contains(c.calendarIdentifier)
    }

    private func canvia(_ c: EKCalendar, _ activat: Bool) {
        let tots = Set(calendari.calendaris.map(\.calendarIdentifier))
        var actius = calendari.calendarisVisibles.isEmpty ? tots : calendari.calendarisVisibles
        if activat { actius.insert(c.calendarIdentifier) } else { actius.remove(c.calendarIdentifier) }
        guard !actius.isEmpty else { return }
        // Buit significa "tots".
        calendari.calendarisVisibles = actius == tots ? [] : actius
    }
}
