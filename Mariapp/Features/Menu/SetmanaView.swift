import SwiftUI

/// Un forat del menú: un dia i un àpat.
struct Forat: Identifiable, Hashable {
    let dia: Int
    let apat: Apat
    var id: String { MenuSetmana.clau(dia: dia, apat: apat) }
}

private struct IdPlat: Identifiable {
    let id: String
}

struct SetmanaView: View {
    @Environment(DataStore.self) private var store
    @State private var inici = Setmana.inici(de: Date())
    @State private var forat: Forat?
    @State private var veuPlat: IdPlat?
    @State private var celebra = 0
    @State private var afegitsCompra: Int?

    private var idSetmana: String { MenuSetmana.id(per: inici) }
    private var menu: MenuSetmana { store.menus[idSetmana] ?? MenuSetmana(id: idSetmana) }
    private var anterior: MenuSetmana? { store.menus[MenuSetmana.id(per: Setmana.mou(inici, setmanes: -1))] }
    private var esSetmanaActual: Bool { inici == Setmana.inici(de: Date()) }

    var body: some View {
        GeometryReader { geo in
            let ample = geo.size.width > 700
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    capcalera
                    if ample {
                        HStack(alignment: .top, spacing: 16) {
                            HStack(alignment: .top, spacing: 10) {
                                ForEach(1...7, id: \.self) { columna($0) }
                            }
                            PlatsLateral()
                                .frame(width: 210)
                        }
                    } else {
                        VStack(spacing: 14) {
                            ForEach(1...7, id: \.self) { fila($0) }
                        }
                    }
                    accions
                    avisCompra
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .animation(Clay.molla, value: menu.apats)
        .animation(Clay.molla, value: afegitsCompra)
        .onChange(of: inici) { _, _ in afegitsCompra = nil }
        .sensoryFeedback(.success, trigger: celebra)
        .sheet(item: $forat) { f in
            TriaPlat(
                apat: f.apat,
                dia: f.dia,
                menu: menu,
                anterior: anterior,
                teEntrada: menu.entrada(dia: f.dia, apat: f.apat) != nil
            ) { entrada in
                assigna(entrada, f)
            }
        }
        .sheet(item: $veuPlat) { v in
            NavigationStack { DetallPlat(platId: v.id) }
                #if os(macOS)
                .frame(minWidth: 480, minHeight: 600)
                #endif
        }
    }

    // MARK: Capçalera i accions

    private var capcalera: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                BotoRodo(titol: "Setmana anterior", icona: "chevron.left", color: Paleta.verd) {
                    inici = Setmana.mou(inici, setmanes: -1)
                }
                VStack(spacing: 2) {
                    Text(Setmana.titol(inici))
                        .font(.titolGran(24))
                        .foregroundStyle(Paleta.tinta)
                        .contentTransition(.numericText())
                    Text("Setmana \(Setmana.numeroSetmana(inici))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Paleta.tintaSuau)
                }
                .frame(maxWidth: .infinity)
                BotoRodo(titol: "Setmana següent", icona: "chevron.right", color: Paleta.verd) {
                    inici = Setmana.mou(inici, setmanes: 1)
                }
            }
            if !esSetmanaActual {
                Button("Torna a hui") { inici = Setmana.inici(de: Date()) }
                    .buttonStyle(.suau(Paleta.verd))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(Clay.molla, value: inici)
        .animation(Clay.molla, value: esSetmanaActual)
    }

    private var accions: some View {
        FlowLayout(espai: 10) {
            Button {
                omple()
            } label: {
                Label("Omplir la setmana", systemImage: "sparkles")
            }
            .buttonStyle(.suau(Paleta.verd, ple: true))
            .disabled(store.plats.items.isEmpty)

            Button {
                copiaAnterior()
            } label: {
                Label("Copiar setmana anterior", systemImage: "doc.on.doc")
            }
            .buttonStyle(.suau(Paleta.verd))
            .disabled(anterior == nil)

            Button {
                afegitsCompra = LlistaCompra.genera(des: menu)
                celebra += 1
            } label: {
                Label("Generar llista", systemImage: "cart.badge.plus")
            }
            .buttonStyle(.suau(Paleta.verd))
            .disabled(menu.platIds.isEmpty)
        }
    }

    @ViewBuilder
    private var avisCompra: some View {
        if let n = afegitsCompra {
            Targeta(tint: Paleta.verd) {
                Text(n == 0 ? "🛒 No falta res nou: tot el que cal ja és a la llista o el tenim." : "🛒 He afegit \(n) \(n == 1 ? "cosa" : "coses") a la llista de la compra.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Paleta.tinta)
                NavigationLink {
                    LlistaCompraView()
                } label: {
                    Label("Veure la llista", systemImage: "cart.fill")
                }
                .buttonStyle(.suau(Paleta.verd, ple: true))
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: Disposicions

    private func fila(_ dia: Int) -> some View {
        let data = Setmana.dia(inici, dia)
        let avui = Calendar.current.isDateInToday(data)
        return Targeta(tint: avui ? Paleta.groc : Paleta.verd) {
            HStack(spacing: 8) {
                Text(Setmana.nomDia(dia))
                    .font(.titolSeccio)
                    .foregroundStyle(Paleta.tinta)
                Text(Dates.curta(data))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Paleta.tintaSuau)
                Spacer()
                if avui { Xip(text: "Hui", color: Paleta.groc, seleccionat: true) }
            }
            HStack(spacing: 10) {
                ForEach(Apat.allCases) { apat in
                    elForat(Forat(dia: dia, apat: apat), compacte: false)
                }
            }
        }
    }

    private func columna(_ dia: Int) -> some View {
        let data = Setmana.dia(inici, dia)
        let avui = Calendar.current.isDateInToday(data)
        return VStack(spacing: 8) {
            VStack(spacing: 0) {
                Text(Analisi.nomsDies[dia - 1].capitalizedFirst)
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(avui ? Paleta.groc : Paleta.tintaSuau)
                Text("\(Setmana.calendari.component(.day, from: data))")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(Paleta.tinta)
            }
            ForEach(Apat.allCases) { apat in
                elForat(Forat(dia: dia, apat: apat), compacte: true)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .clay(avui ? Paleta.groc : Paleta.verd, radi: Clay.radiMitja, elevacio: 0.7)
    }

    private func elForat(_ f: Forat, compacte: Bool) -> some View {
        let entrada = menu.entrada(dia: f.dia, apat: f.apat)
        let plat = entrada?.platId.flatMap { store.plats[$0] }
        return ForatApat(apat: f.apat, entrada: entrada, plat: plat, compacte: compacte) {
            forat = f
        } buida: {
            assigna(nil, f)
        } veu: {
            if let id = plat?.id { veuPlat = IdPlat(id: id) }
        }
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first, store.plats[id] != nil else { return false }
            assigna(EntradaMenu(platId: id), f)
            return true
        }
    }

    // MARK: Accions

    private func assigna(_ entrada: EntradaMenu?, _ f: Forat) {
        var m = menu
        m.posa(entrada, dia: f.dia, apat: f.apat)
        store.menus.desa(m)
        celebra += 1
        if entrada != nil { Sons.toca(.cafe) }
    }

    private func omple() {
        let nou = SuggeridorMenu.omple(setmana: menu, plats: store.plats.items, anterior: anterior)
        store.menus.desa(nou)
        celebra += 1
        Sons.toca(.festa)
    }

    private func copiaAnterior() {
        guard let anterior else { return }
        store.menus.desa(SuggeridorMenu.copia(de: anterior, a: menu))
        celebra += 1
        Sons.toca(.cafe)
    }
}

// MARK: - Forat (dinar o sopar d'un dia)

private struct ForatApat: View {
    let apat: Apat
    let entrada: EntradaMenu?
    let plat: Plat?
    let compacte: Bool
    let toca: () -> Void
    let buida: () -> Void
    let veu: () -> Void

    var body: some View {
        Button(action: toca) {
            if let entrada {
                ple(entrada)
            } else {
                buit
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if entrada != nil {
                Button("Canviar", systemImage: "arrow.triangle.2.circlepath", action: toca)
                if plat != nil {
                    Button("Veure la recepta", systemImage: "book", action: veu)
                }
                Button("Buidar", systemImage: "xmark.circle", action: buida)
            }
        }
    }

    private var buit: some View {
        VStack(spacing: 4) {
            Text(compacte ? apat.emoji : "\(apat.emoji) \(apat.nom)")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(Paleta.tintaSuau)
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Paleta.verd.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: compacte ? 84 : 74)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Paleta.verd.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func ple(_ entrada: EntradaMenu) -> some View {
        let nom = plat?.nom ?? (entrada.platId != nil ? "Plat esborrat" : (entrada.text ?? ""))
        let emoji = plat?.emoji ?? (entrada.platId != nil ? "❔" : "📝")
        VStack(alignment: .leading, spacing: 4) {
            Text(compacte ? apat.emoji : "\(apat.emoji) \(apat.nom)")
                .font(.system(.caption2, design: .rounded).bold())
                .foregroundStyle(Paleta.tintaSuau)
            if compacte {
                Text(emoji).font(.title2)
                Text(nom)
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(Paleta.tinta)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            } else {
                HStack(spacing: 8) {
                    Text(emoji).font(.title2)
                    Text(nom)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Paleta.tinta)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            if let plat {
                HStack(spacing: 4) {
                    if plat.etiquetes.contains(.tupper) { Text("🥡").font(.caption2) }
                    if plat.thermomix { Text("TM").font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(Paleta.cafe) }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: compacte ? 84 : 74, alignment: .leading)
        .clay(Paleta.verd, radi: 16, elevacio: 0.55)
    }
}

// MARK: - Plats arrossegables (només en pantalla ampla)

private struct PlatsLateral: View {
    @Environment(DataStore.self) private var store
    @State private var cerca = ""

    var body: some View {
        let plats = store.plats.items
            .filter { $0.passa(cerca: cerca) }
            .sorted { $0.nom < $1.nom }
        VStack(alignment: .leading, spacing: 10) {
            Text("Arrossega un plat")
                .font(.titolSeccio)
                .foregroundStyle(Paleta.tinta)
            TextField("Cerca", text: $cerca)
                .textFieldStyle(.roundedBorder)
            ForEach(plats) { plat in
                HStack(spacing: 8) {
                    Text(plat.emoji)
                    Text(plat.nom)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(Paleta.tinta)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clay(Paleta.verd, radi: 14, elevacio: 0.5)
                .draggable(plat.id)
            }
        }
        .padding(12)
        .clay(Paleta.verd, radi: Clay.radiMitja, elevacio: 0.7)
    }
}
