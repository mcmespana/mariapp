import SwiftUI

/// Afegir, canviar el nom i l'emoji, reordenar i esborrar (si no hi ha cites) les categories de metge.
struct GestionaCategories: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var cats: [CategoriaMetge] = []
    @State private var iniciat = false
    @State private var nouNom = ""
    @State private var nouEmoji = "🏥"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($cats) { $cat in
                        HStack(spacing: 10) {
                            TextField("🏥", text: Binding(get: { cat.emoji }, set: { cat.emoji = String($0.prefix(1)) }))
                                .frame(width: 40)
                                .multilineTextAlignment(.center)
                            TextField("Nom", text: $cat.nom)
                            let n = usos(cat)
                            if n > 0 {
                                Xip(text: "\(n) \(n == 1 ? "cita" : "cites")", color: Paleta.alerta)
                            }
                        }
                    }
                    .onMove { cats.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { indexos in
                        var esborrables = IndexSet()
                        for i in indexos where usos(cats[i]) == 0 { esborrables.insert(i) }
                        cats.remove(atOffsets: esborrables)
                    }
                } footer: {
                    Text("Només es poden esborrar les categories sense cites.")
                }
                .listRowBackground(Paleta.paper)

                Section("Nova categoria") {
                    HStack(spacing: 10) {
                        TextField("🏥", text: Binding(get: { nouEmoji }, set: { nouEmoji = String($0.prefix(1)) }))
                            .frame(width: 40)
                            .multilineTextAlignment(.center)
                        TextField("Nom (Fisio, Psicòloga…)", text: $nouNom)
                            .onSubmit(afegeix)
                        Button("Afegeix", systemImage: "plus.circle.fill", action: afegeix)
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .foregroundStyle(Paleta.alerta)
                            .disabled(nouNom.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .listRowBackground(Paleta.paper)
            }
            .fonsMariapp()
            .navigationTitle("Categories")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .cancellationAction) { EditButton() }
                #endif
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fet") { desa(); dismiss() }
                }
            }
            .onAppear {
                guard !iniciat else { return }
                iniciat = true
                cats = store.categoriesOrdenades
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 520)
        #endif
    }

    private func usos(_ cat: CategoriaMetge) -> Int {
        store.cites.items.filter { $0.categoriaId == cat.id }.count
    }

    private func afegeix() {
        let nom = nouNom.trimmingCharacters(in: .whitespaces)
        guard !nom.isEmpty else { return }
        cats.append(CategoriaMetge(nom: nom, emoji: nouEmoji.isEmpty ? "🏥" : nouEmoji, ordre: cats.count))
        nouNom = ""
        nouEmoji = "🏥"
    }

    private func desa() {
        let ids = Set(cats.map(\.id))
        for vella in store.categoriesMetge.items where !ids.contains(vella.id) {
            store.categoriesMetge.esborra(vella)
        }
        for (i, var cat) in cats.enumerated() {
            cat.ordre = i
            cat.nom = cat.nom.trimmingCharacters(in: .whitespaces)
            if !cat.nom.isEmpty { store.categoriesMetge.desa(cat) }
        }
    }
}
