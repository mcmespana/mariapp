import SwiftUI

/// Full per a triar què es menja en un forat del menú: suggeriments, buscador, text lliure o buidar.
struct TriaPlat: View {
    let apat: Apat
    let dia: Int
    let menu: MenuSetmana
    let anterior: MenuSetmana?
    let teEntrada: Bool
    /// `nil` = buidar el forat.
    let alTriar: (EntradaMenu?) -> Void

    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var cerca = ""
    @State private var etiquetes: Set<EtiquetaPlat> = []
    @State private var textLliure = ""
    @State private var suggerits: [Plat] = []
    @State private var receptesMon = false

    private var filtrats: [Plat] {
        store.plats.items
            .filter { $0.passa(cerca: cerca, etiquetes: etiquetes) }
            .sorted { $0.nom < $1.nom }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if cerca.isEmpty && etiquetes.isEmpty && !suggerits.isEmpty {
                        Targeta(tint: Paleta.verd) {
                            CapcaleraTargeta(icona: "sparkles", titol: "Suggeriments", color: Paleta.verd)
                            ForEach(suggerits) { fila($0) }
                        }
                    }

                    IdeesIA(apat: apat, dia: dia, menu: menu) { plat in
                        alTriar(EntradaMenu(platId: plat.id))
                        dismiss()
                    }

                    Button {
                        receptesMon = true
                    } label: {
                        Label("🌍 Receptes del món", systemImage: "globe.europe.africa.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.suau(Paleta.verd))

                    filtres

                    Targeta(tint: Paleta.groc) {
                        CapcaleraTargeta(icona: "text.cursor", titol: "Text lliure", color: Paleta.groc)
                        HStack(spacing: 10) {
                            TextField("Sopar fora 🎉", text: $textLliure)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit(posaText)
                            Button("Posa-ho", action: posaText)
                                .buttonStyle(.suau(Paleta.groc, ple: true))
                                .disabled(textLliure.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    if store.plats.items.isEmpty {
                        Targeta {
                            Text("Encara no tens plats guardats. Afig-los a la pestanya «Plats» 🍲")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Paleta.tintaSuau)
                        }
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filtrats) { fila($0) }
                        }
                        if filtrats.isEmpty {
                            Text("Cap plat amb això 🤔")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Paleta.tintaSuau)
                        }
                    }

                    if teEntrada {
                        Button {
                            alTriar(nil)
                            dismiss()
                        } label: {
                            Label("Buidar este forat", systemImage: "xmark.circle")
                        }
                        .buttonStyle(.suau(Paleta.cafe))
                    }
                }
                .padding(16)
            }
            .fonsMariapp()
            .navigationTitle("\(Setmana.nomDia(dia)) · \(apat.emoji) \(apat.nom)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $cerca, prompt: "Cerca un plat o un ingredient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tanca") { dismiss() }
                }
            }
            .sheet(isPresented: $receptesMon) {
                ReceptesMonView { plat in
                    alTriar(EntradaMenu(platId: plat.id))
                    dismiss()
                }
            }
            .onAppear {
                suggerits = SuggeridorMenu.suggeriments(plats: store.plats.items, apat: apat, setmana: menu, anterior: anterior)
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 640)
        #endif
    }

    private var filtres: some View {
        FlowLayout(espai: 8) {
            ForEach(EtiquetaPlat.allCases) { e in
                XipBoto(text: "\(e.emoji) \(e.nom)", color: Paleta.verd, seleccionat: etiquetes.contains(e)) {
                    if etiquetes.contains(e) { etiquetes.remove(e) } else { etiquetes.insert(e) }
                }
            }
        }
    }

    private func fila(_ plat: Plat) -> some View {
        Button {
            alTriar(EntradaMenu(platId: plat.id))
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(plat.emoji).font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plat.nom)
                        .font(.titolTargeta)
                        .foregroundStyle(Paleta.tinta)
                        .multilineTextAlignment(.leading)
                    Text(plat.etiquetes.map(\.emoji).joined(separator: " "))
                        .font(.caption)
                }
                Spacer(minLength: 0)
                if plat.favorit { Image(systemName: "star.fill").foregroundStyle(Paleta.groc) }
                if plat.thermomix { Xip(text: "TM", color: Paleta.cafe) }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clay(Paleta.verd, radi: Clay.radiMitja, elevacio: 0.5)
        }
        .buttonStyle(.plain)
    }

    private func posaText() {
        let t = textLliure.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        alTriar(EntradaMenu(text: t))
        dismiss()
    }
}
