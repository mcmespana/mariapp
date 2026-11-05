import SwiftUI

/// Els plats guardats: rejilla amb filtres i buscador.
struct PlatsView: View {
    @Environment(DataStore.self) private var store
    @State private var cerca = ""
    @State private var etiquetes: Set<EtiquetaPlat> = []
    @State private var nomesThermomix = false
    @State private var nomesPreferits = false
    @State private var nou = false

    private var filtrats: [Plat] {
        store.plats.items
            .filter { $0.passa(cerca: cerca, etiquetes: etiquetes, nomesThermomix: nomesThermomix, nomesPreferits: nomesPreferits) }
            .sorted { $0.nom < $1.nom }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FlowLayout(espai: 8) {
                    XipBoto(text: "⭐️ Preferits", color: Paleta.groc, seleccionat: nomesPreferits) { nomesPreferits.toggle() }
                    XipBoto(text: "🫕 Només Thermomix", color: Paleta.cafe, seleccionat: nomesThermomix) { nomesThermomix.toggle() }
                    ForEach(EtiquetaPlat.allCases) { e in
                        XipBoto(text: "\(e.emoji) \(e.nom)", color: Paleta.verd, seleccionat: etiquetes.contains(e)) {
                            if etiquetes.contains(e) { etiquetes.remove(e) } else { etiquetes.insert(e) }
                        }
                    }
                }

                if store.plats.items.isEmpty {
                    Targeta(tint: Paleta.verd) {
                        Text("Encara no tens plats. Toca el + per a guardar el primer 🍲")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                } else if filtrats.isEmpty {
                    Targeta(tint: Paleta.verd) {
                        Text("Cap plat amb eixos filtres 🤔")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14, alignment: .top)], spacing: 14) {
                    ForEach(filtrats) { plat in
                        NavigationLink {
                            DetallPlat(platId: plat.id)
                        } label: {
                            TargetaPlat(plat: plat)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(Clay.molla, value: filtrats.map(\.id))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .searchable(text: $cerca, prompt: "Cerca un plat o un ingredient")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Plat nou", systemImage: "plus") { nou = true }
                    .labelStyle(.iconOnly)
            }
        }
        .sheet(isPresented: $nou) {
            EditaPlat()
        }
    }
}

struct TargetaPlat: View {
    let plat: Plat

    var body: some View {
        Targeta(tint: Paleta.verd) {
            HStack(alignment: .top) {
                Text(plat.emoji).font(.system(size: 42))
                Spacer()
                if plat.favorit {
                    Image(systemName: "star.fill").foregroundStyle(Paleta.groc)
                }
            }
            Text(plat.nom)
                .font(.titolTargeta)
                .foregroundStyle(Paleta.tinta)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            FlowLayout(espai: 5) {
                if plat.thermomix { Xip(text: "Thermomix", color: Paleta.cafe, seleccionat: true) }
                ForEach(plat.etiquetes) { e in
                    Xip(text: "\(e.emoji) \(e.nom)", color: Paleta.verd)
                }
            }
        }
    }
}

// MARK: - Edició

struct EditaPlat: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var plat: Plat
    private let esNou: Bool
    @State private var confirmaEsborrar = false

    init(plat: Plat? = nil) {
        _plat = State(initialValue: plat ?? Plat(nom: ""))
        esNou = plat == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("El plat") {
                    TextField("Nom", text: $plat.nom)
                    HStack {
                        Text("Emoji")
                        Spacer()
                        TextField("🍲", text: Binding(get: { plat.emoji }, set: { plat.emoji = String($0.prefix(1)) }))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    Toggle("⭐️ Preferit", isOn: $plat.favorit)
                    Toggle("🫕 Es fa amb Thermomix", isOn: $plat.thermomix)
                }
                .listRowBackground(Paleta.paper)

                Section("Etiquetes") {
                    FlowLayout(espai: 8) {
                        ForEach(EtiquetaPlat.allCases) { e in
                            XipBoto(text: "\(e.emoji) \(e.nom)", color: Paleta.verd, seleccionat: plat.etiquetes.contains(e)) {
                                if let i = plat.etiquetes.firstIndex(of: e) {
                                    plat.etiquetes.remove(at: i)
                                } else {
                                    plat.etiquetes.append(e)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Paleta.paper)

                Section {
                    ForEach($plat.ingredients) { $ing in
                        HStack(spacing: 10) {
                            TextField("Ingredient", text: $ing.nom)
                            Toggle("El tenim", isOn: $ing.tenim)
                                .toggleStyle(.switch)
                                .fixedSize()
                            Button("Esborra l'ingredient", systemImage: "minus.circle.fill") {
                                plat.ingredients.removeAll { $0.id == ing.id }
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .foregroundStyle(Paleta.tintaSuau)
                        }
                    }
                    Button("Afegir ingredient", systemImage: "plus.circle.fill") {
                        plat.ingredients.append(Ingredient(nom: ""))
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("Els que no tenim aniran a la llista de la compra.")
                }
                .listRowBackground(Paleta.paper)

                Section("Recepta") {
                    TextEditor(text: $plat.recepta)
                        .frame(minHeight: 120)
                        .font(.system(.body, design: .rounded))
                }
                .listRowBackground(Paleta.paper)

                Section("Més coses") {
                    TextField("Enllaç (https://…)", text: Binding(get: { plat.enllac ?? "" }, set: { plat.enllac = $0.isEmpty ? nil : $0 }))
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                    TextField("Notes", text: $plat.notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                .listRowBackground(Paleta.paper)

                if !esNou {
                    Section {
                        Button("Esborrar el plat", systemImage: "trash") { confirmaEsborrar = true }
                            .foregroundStyle(Paleta.cafe)
                    }
                    .listRowBackground(Paleta.paper)
                }
            }
            .formStyle(.grouped)
            .fonsMariapp()
            .navigationTitle(esNou ? "Plat nou" : "Edita el plat")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel·la") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Desa", action: desa)
                        .disabled(plat.nom.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Esborrar «\(plat.nom)»?", isPresented: $confirmaEsborrar, titleVisibility: .visible) {
                Button("Esborra", role: .destructive) {
                    store.plats.esborra(plat)
                    dismiss()
                }
                Button("Cancel·la", role: .cancel) {}
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 640)
        #endif
    }

    private func desa() {
        var p = plat
        p.nom = p.nom.trimmingCharacters(in: .whitespaces)
        p.ingredients.removeAll { $0.nom.trimmingCharacters(in: .whitespaces).isEmpty }
        if p.emoji.isEmpty { p.emoji = "🍲" }
        store.plats.desa(p)
        Sons.toca(.cafe)
        dismiss()
    }
}

// MARK: - Detall

struct DetallPlat: View {
    let platId: String

    @Environment(DataStore.self) private var store
    @State private var edita = false
    @State private var afegeix = false

    var body: some View {
        Group {
            if let plat = store.plats[platId] {
                contingut(plat)
            } else {
                Text("Este plat ja no hi és 🤷‍♀️")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .fonsMariapp()
            }
        }
    }

    @ViewBuilder
    private func contingut(_ plat: Plat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 12) {
                    Text(plat.emoji)
                        .font(.system(size: 56))
                        .background { BolaClay(color: Paleta.verd, mida: 118) }
                        .padding(.vertical, 10)
                    Text(plat.nom)
                        .font(.titolGran(28))
                        .foregroundStyle(Paleta.tinta)
                        .multilineTextAlignment(.center)
                    FlowLayout(espai: 6) {
                        if plat.thermomix { Xip(text: "🫕 Thermomix", color: Paleta.cafe, seleccionat: true) }
                        ForEach(plat.etiquetes) { Xip(text: "\($0.emoji) \($0.nom)", color: Paleta.verd) }
                    }
                }
                .frame(maxWidth: .infinity)

                if !plat.ingredients.isEmpty {
                    Targeta(tint: Paleta.verd) {
                        CapcaleraTargeta(icona: "basket.fill", titol: "Ingredients", color: Paleta.verd)
                        ForEach(plat.ingredients) { ing in
                            Button {
                                canviaTenim(plat, ing)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: ing.tenim ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(ing.tenim ? Paleta.verd : Paleta.taronja)
                                    Text(ing.nom)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundStyle(Paleta.tinta)
                                    Spacer()
                                    if !ing.tenim { Xip(text: "Falta", color: Paleta.taronja) }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !plat.recepta.isEmpty {
                    Targeta(tint: Paleta.groc) {
                        CapcaleraTargeta(icona: "book.fill", titol: "Recepta", color: Paleta.groc)
                        Text(plat.recepta)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                            .textSelection(.enabled)
                    }
                }

                if let enllac = plat.enllac, let url = URL(string: enllac), url.scheme?.hasPrefix("http") == true {
                    Link(destination: url) {
                        Label("Obrir l'enllaç", systemImage: "safari")
                    }
                    .buttonStyle(.suau(Paleta.blau))
                }

                if !plat.notes.isEmpty {
                    Targeta(tint: Paleta.aigua) {
                        CapcaleraTargeta(icona: "note.text", titol: "Notes", color: Paleta.aigua)
                        Text(plat.notes)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                    }
                }

                Button {
                    afegeix = true
                } label: {
                    Label("Afegir al menú", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(.suau(Paleta.verd, ple: true))
            }
            .padding(16)
        }
        .fonsMariapp()
        .navigationTitle(plat.nom)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(plat.favorit ? "Treu dels preferits" : "Marca com a preferit", systemImage: plat.favorit ? "star.fill" : "star") {
                    var p = plat
                    p.favorit.toggle()
                    store.plats.desa(p)
                }
                .labelStyle(.iconOnly)
                Button("Edita", systemImage: "pencil") { edita = true }
                    .labelStyle(.iconOnly)
            }
        }
        .sheet(isPresented: $edita) { EditaPlat(plat: plat) }
        .sheet(isPresented: $afegeix) { AfegirAlMenu(plat: plat) }
    }

    private func canviaTenim(_ plat: Plat, _ ing: Ingredient) {
        var p = plat
        guard let i = p.ingredients.firstIndex(where: { $0.id == ing.id }) else { return }
        p.ingredients[i].tenim.toggle()
        store.plats.desa(p)
    }
}

// MARK: - Afegir un plat al menú

struct AfegirAlMenu: View {
    let plat: Plat

    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var setmanes = 0
    @State private var dia = Setmana.numeroDia()
    @State private var apat: Apat = .dinar

    var body: some View {
        NavigationStack {
            Form {
                Section("Quan?") {
                    Picker("Setmana", selection: $setmanes) {
                        Text("Esta setmana").tag(0)
                        Text("La que ve").tag(1)
                    }
                    .pickerStyle(.segmented)
                    Picker("Dia", selection: $dia) {
                        ForEach(1...7, id: \.self) { Text(Setmana.nomDia($0)).tag($0) }
                    }
                    Picker("Àpat", selection: $apat) {
                        ForEach(Apat.allCases) { Text("\($0.emoji) \($0.nom)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Paleta.paper)

                Section {
                    Button("Afegir «\(plat.nom)»", action: afegeix)
                        .buttonStyle(.suau(Paleta.verd, ple: true))
                }
                .listRowBackground(Color.clear)
            }
            .formStyle(.grouped)
            .fonsMariapp()
            .navigationTitle("Afegir al menú")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel·la") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 380)
        #endif
        .presentationDetents([.medium])
    }

    private func afegeix() {
        let inici = Setmana.mou(Setmana.inici(de: Date()), setmanes: setmanes)
        let id = MenuSetmana.id(per: inici)
        var m = store.menus[id] ?? MenuSetmana(id: id)
        m.posa(EntradaMenu(platId: plat.id), dia: dia, apat: apat)
        store.menus.desa(m)
        Sons.toca(.festa)
        dismiss()
    }
}
