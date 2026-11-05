import SwiftUI

struct LlistaCompraView: View {
    @Environment(DataStore.self) private var store
    @State private var nou = ""
    @State private var quantitat = ""
    @State private var confirmaNeteja = false
    @FocusState private var enfocat: Bool

    private var tots: [ElementCompra] { store.llistaCompra.items }
    private var pendents: [ElementCompra] { tots.filter { !$0.comprat }.sorted { $0.creat < $1.creat } }
    private var comprats: [ElementCompra] { tots.filter(\.comprat).sorted { $0.creat < $1.creat } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                afegeix

                if tots.isEmpty {
                    Targeta(tint: Paleta.verd) {
                        Text("La llista està buida 🎉 Afig coses ací o genera-la des del menú de la setmana (🛒).")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }

                if !pendents.isEmpty {
                    Targeta(tint: Paleta.verd) {
                        CapcaleraTargeta(icona: "cart.fill", titol: "Pendents (\(pendents.count))", color: Paleta.verd)
                        ForEach(pendents) { fila($0) }
                    }
                }

                if !comprats.isEmpty {
                    Targeta(tint: Paleta.cafe) {
                        CapcaleraTargeta(icona: "checkmark.circle.fill", titol: "Comprats (\(comprats.count))", color: Paleta.cafe) {
                            Button("Esborra els comprats", systemImage: "trash") { confirmaNeteja = true }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .foregroundStyle(Paleta.tintaSuau)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        ForEach(comprats) { fila($0) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .fonsMariapp()
        .navigationTitle("Compra")
        .animation(Clay.molla, value: tots.map { "\($0.id)\($0.comprat)" })
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: textPerCompartir) {
                    Label("Compartir la llista", systemImage: "square.and.arrow.up")
                }
                .disabled(pendents.isEmpty)
            }
        }
        .confirmationDialog("Esborrar els \(comprats.count) comprats?", isPresented: $confirmaNeteja, titleVisibility: .visible) {
            Button("Esborra", role: .destructive) {
                comprats.forEach { store.llistaCompra.esborra($0) }
            }
            Button("Cancel·la", role: .cancel) {}
        }
    }

    private var afegeix: some View {
        Targeta(tint: Paleta.verd) {
            HStack(spacing: 10) {
                TextField("Afegir (llet, pa…)", text: $nou)
                    .textFieldStyle(.roundedBorder)
                    .focused($enfocat)
                    .onSubmit(afegeixElement)
                TextField("Quant.", text: $quantitat)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                    .onSubmit(afegeixElement)
                BotoRodo(titol: "Afegir a la llista", icona: "plus", color: Paleta.verd, accio: afegeixElement)
            }
        }
    }

    private func fila(_ e: ElementCompra) -> some View {
        Button {
            LlistaCompra.marca(e, comprat: !e.comprat)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: e.comprat ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(e.comprat ? Paleta.cafe : Paleta.verd)
                    .symbolEffect(.bounce, value: e.comprat)
                VStack(alignment: .leading, spacing: 1) {
                    Text(e.nom)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(e.comprat ? Paleta.tintaSuau : Paleta.tinta)
                        .strikethrough(e.comprat, color: Paleta.tintaSuau)
                    if let plat = e.platNom {
                        Text("per a \(plat)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }
                Spacer(minLength: 0)
                if let q = e.quantitat, !q.isEmpty {
                    Xip(text: q, color: Paleta.verd)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: e.comprat)
        .contextMenu {
            Button("Esborra", systemImage: "trash") { store.llistaCompra.esborra(e) }
        }
    }

    private func afegeixElement() {
        let text = nou.trimmingCharacters(in: .whitespaces)
        guard GeneradorCompra.podeuAfegir(text, a: tots) else {
            nou = ""
            return
        }
        var e = ElementCompra(nom: text)
        let q = quantitat.trimmingCharacters(in: .whitespaces)
        e.quantitat = q.isEmpty ? nil : q
        store.llistaCompra.desa(e)
        Sons.toca(.gota)
        nou = ""
        quantitat = ""
        enfocat = true
    }

    private var textPerCompartir: String {
        let linies = pendents.map { e in
            "• \(e.nom)" + ((e.quantitat ?? "").isEmpty ? "" : " (\(e.quantitat ?? ""))")
        }
        return (["🛒 Llista de la compra"] + linies).joined(separator: "\n")
    }
}

/// Operacions sobre la llista.
enum LlistaCompra {
    static func marca(_ element: ElementCompra, comprat: Bool) {
        let store = DataStore.shared
        var e = element
        e.comprat = comprat
        store.llistaCompra.desa(e)
        // Si ve d'un plat, l'ingredient passa a "el tenim" (o torna a faltar si es desfà).
        if let platId = element.platId, let plat = store.plats[platId],
           let nou = GeneradorCompra.platActualitzat(plat, element: element, tenim: comprat) {
            store.plats.desa(nou)
        }
    }

    /// Genera la llista a partir del menú. Torna quants elements s'han afegit.
    @discardableResult
    static func genera(des menu: MenuSetmana) -> Int {
        let store = DataStore.shared
        let plats = Dictionary(uniqueKeysWithValues: store.plats.items.map { ($0.id, $0) })
        let nous = GeneradorCompra.nous(menu: menu, plats: plats, existents: store.llistaCompra.items)
        nous.forEach { store.llistaCompra.desa($0) }
        return nous.count
    }
}
