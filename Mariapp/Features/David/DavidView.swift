import SwiftUI

/// Pensaments sobre David: queixes, agraïments, coses boniques…
struct DavidView: View {
    @Environment(DataStore.self) private var store
    @Environment(Preferencies.self) private var prefs
    @State private var filtre: TipusPensament?
    @State private var nou: TipusPensament?

    var body: some View {
        let tots = store.pensaments.items.sorted { $0.data > $1.data }
        let llista = filtre.map { f in tots.filter { $0.tipus == f } } ?? tots

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Coses que pense de David")
                    .font(.titolGran(28))
                    .foregroundStyle(Paleta.tinta)

                // Resum
                HStack(spacing: 10) {
                    ForEach(TipusPensament.allCases) { t in
                        let n = tots.filter { $0.tipus == t }.count
                        Button {
                            withAnimation(.snappy) { filtre = filtre == t ? nil : t }
                        } label: {
                            VStack(spacing: 2) {
                                Text(t.emoji).font(.system(size: 24))
                                Text("\(n)").font(.system(.headline, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(Paleta.tinta)
                            .background(filtre == t ? Paleta.taronja.opacity(0.25) : Paleta.paper,
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if prefs.esMaria {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TipusPensament.allCases) { t in
                                Button("\(t.emoji) \(t.nom)") { nou = t }
                                    .buttonStyle(.suau(Paleta.taronja))
                            }
                        }
                    }
                }

                if llista.isEmpty {
                    Targeta {
                        Text(prefs.esMaria ? "Encara res. Apunta la primera cosa (bona o roina) 😌" : "La Maria encara no ha apuntat res… de moment 👀")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }

                LazyVStack(spacing: 12) {
                    ForEach(llista) { p in
                        Targeta {
                            HStack(alignment: .top, spacing: 12) {
                                Text(p.tipus.emoji).font(.system(size: 28))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(p.text)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundStyle(Paleta.tinta)
                                    Text("\(p.tipus.nom) · \(Dates.curta(p.data))")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(Paleta.tintaSuau)
                                }
                            }
                        }
                        .contextMenu {
                            if prefs.esMaria {
                                Button("Esborrar", systemImage: "trash", role: .destructive) { store.pensaments.esborra(p) }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .fonsMariapp()
        .navigationTitle("David")
        .sheet(item: $nou) { tipus in
            NouPensament(tipus: tipus)
                .presentationDetents([.medium, .large])
        }
    }
}

private struct NouPensament: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var tanca
    @State var tipus: TipusPensament
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Tipus", selection: $tipus) {
                    ForEach(TipusPensament.allCases) { Text("\($0.emoji) \($0.nom)").tag($0) }
                }
                TextField("Escriu-ho ací…", text: $text, axis: .vertical)
                    .lineLimit(4...10)
            }
            .fonsMariapp()
            .navigationTitle(tipus.nom)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel·lar") { tanca() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Desar") {
                        store.pensaments.desa(Pensament(tipus: tipus, text: text.trimmingCharacters(in: .whitespacesAndNewlines)))
                        Sons.toca(tipus == .queixa ? .queixa : .campaneta)
                        tanca()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
