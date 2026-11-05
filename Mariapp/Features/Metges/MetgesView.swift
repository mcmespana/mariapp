import SwiftUI

private struct EsborranyCita: Identifiable {
    let id = UUID()
    var cita: Cita?
    var forcaProgramada = false
}

/// Metges 🚨: l'única secció que no és calmada. Roig, avisos exagerats i molta alegria quan es compleix una cita.
struct MetgesView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduirMoviment

    @State private var filtre: String?
    @State private var edicio: EsborranyCita?
    @State private var categories = false
    @State private var pulsa = false
    @State private var mostraConfeti = false
    @State private var nFetes = 0

    private var cites: [Cita] {
        store.cites.items.filter { filtre == nil || $0.categoriaId == filtre }
    }
    private var proxima: Cita? { ServeiCites.properaCita(cites) }
    private var perDemanar: [Cita] {
        cites.filter { $0.estat == .perDemanar }
            .sorted { ($0.recordarDemanarEl ?? .distantFuture) < ($1.recordarDemanarEl ?? .distantFuture) }
    }
    private var programades: [Cita] {
        cites.filter { $0.estat == .programada && $0.id != proxima?.id }
            .sorted { ($0.data ?? .distantFuture) < ($1.data ?? .distantFuture) }
    }
    private var fetes: [Cita] {
        cites.filter { $0.estat == .feta }
            .sorted { ($0.data ?? $0.creat) > ($1.data ?? $1.creat) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                capcalera
                filtres

                if let proxima {
                    TargetaProxima(cita: proxima, categoria: ServeiCites.categoria(proxima)) {
                        edicio = EsborranyCita(cita: proxima)
                    } feta: {
                        marcaFeta(proxima)
                    }
                }

                if store.cites.items.isEmpty {
                    Targeta(tint: Paleta.alerta) {
                        Text("Cap cita apuntada. O ets la persona més sana del món o... toca el + 😅")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                    }
                }

                if !perDemanar.isEmpty {
                    bloc("Cal demanar cita", icona: "phone.fill") {
                        ForEach(perDemanar) { c in
                            FilaCita(cita: c, categoria: ServeiCites.categoria(c)) {
                                edicio = EsborranyCita(cita: c)
                            } accio: {
                                edicio = EsborranyCita(cita: c, forcaProgramada: true)
                            }
                        }
                    }
                }

                if !programades.isEmpty {
                    bloc("Programades", icona: "calendar.badge.clock") {
                        ForEach(programades) { c in
                            FilaCita(cita: c, categoria: ServeiCites.categoria(c)) {
                                edicio = EsborranyCita(cita: c)
                            } accio: {
                                marcaFeta(c)
                            }
                        }
                    }
                }

                if !fetes.isEmpty {
                    DisclosureGroup {
                        VStack(spacing: 10) {
                            ForEach(fetes) { c in
                                FilaCita(cita: c, categoria: ServeiCites.categoria(c)) {
                                    edicio = EsborranyCita(cita: c)
                                } accio: {}
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Label("Fetes (\(fetes.count))", systemImage: "checkmark.circle.fill")
                            .font(.titolSeccio)
                            .foregroundStyle(Paleta.tinta)
                    }
                    .tint(Paleta.alerta)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .fonsMariapp()
        .navigationTitle("Metges")
        .overlay { if mostraConfeti { Confeti() } }
        .overlay(alignment: .top) {
            if mostraConfeti {
                Text("Una menys! 💪")
                    .font(.titolGran(28))
                    .foregroundStyle(Paleta.alerta)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .clay(Paleta.alerta, radi: Clay.radiGran)
                    .padding(.top, 20)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(Clay.mollaJuganera, value: mostraConfeti)
        .sensoryFeedback(.success, trigger: nFetes)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Categories", systemImage: "folder.badge.gearshape") { categories = true }
                    .labelStyle(.iconOnly)
                Button("Cita nova", systemImage: "plus") { edicio = EsborranyCita() }
                    .labelStyle(.iconOnly)
            }
        }
        .sheet(item: $edicio) { e in
            EditaCita(cita: e.cita, forcaProgramada: e.forcaProgramada)
        }
        .sheet(isPresented: $categories) { GestionaCategories() }
        .onAppear { pulsa = !reduirMoviment }
    }

    // MARK: Peces

    private var capcalera: some View {
        Text("🚨 METGES 🚨")
            .font(.titolGran(38))
            .foregroundStyle(Paleta.alerta)
            .frame(maxWidth: .infinity)
            .scaleEffect(pulsa ? 1.05 : 0.97)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsa)
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var filtres: some View {
        if !store.categoriesOrdenades.isEmpty {
            FlowLayout(espai: 8) {
                XipBoto(text: "Totes", color: Paleta.alerta, seleccionat: filtre == nil) { filtre = nil }
                ForEach(store.categoriesOrdenades) { cat in
                    XipBoto(text: "\(cat.emoji) \(cat.nom)", color: Paleta.alerta, seleccionat: filtre == cat.id) {
                        filtre = filtre == cat.id ? nil : cat.id
                    }
                }
            }
        }
    }

    private func bloc<Contingut: View>(_ titol: String, icona: String, @ViewBuilder _ contingut: () -> Contingut) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                IconaClay(icona: icona, color: Paleta.alerta, mida: 30)
                Text(titol)
                    .font(.titolSeccio)
                    .foregroundStyle(Paleta.tinta)
                    .accessibilityAddTraits(.isHeader)
            }
            contingut()
        }
    }

    private func marcaFeta(_ cita: Cita) {
        ServeiCites.marcaFeta(cita)
        Sons.toca(.festa)
        nFetes += 1
        mostraConfeti = true
        Task {
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            mostraConfeti = false
        }
    }
}

// MARK: - Pròxima cita

private struct TargetaProxima: View {
    let cita: Cita
    let categoria: CategoriaMetge?
    let edita: () -> Void
    let feta: () -> Void

    var body: some View {
        Targeta(tint: Paleta.alerta) {
            Text("Pròxima cita")
                .font(.system(.caption, design: .rounded).weight(.heavy))
                .foregroundStyle(Paleta.alerta)
                .textCase(.uppercase)
            Button(action: edita) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Text(categoria?.emoji ?? "🏥").font(.system(size: 44))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cita.titol)
                                .font(.titolGran(26))
                                .foregroundStyle(Paleta.tinta)
                                .multilineTextAlignment(.leading)
                            if let categoria {
                                Text(categoria.nom)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Paleta.tintaSuau)
                            }
                        }
                    }
                    if let data = cita.data {
                        TimelineView(.everyMinute) { context in
                            Compta(data: data, ara: context.date)
                        }
                        Label("\(Dates.llarga(data).capitalizedFirst) · \(Dates.hora(data))", systemImage: "clock.fill")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(Paleta.tinta)
                    }
                    if !cita.lloc.isEmpty {
                        Label(cita.lloc, systemImage: "mappin.and.ellipse")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Paleta.tinta)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Button(action: feta) {
                Label("Ja està feta", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.suau(Paleta.alerta))
        }
    }
}

/// "en 3 dies, 4 hores" o, si és hui, "ÉS HUI!!!" parpellejant.
private struct Compta: View {
    let data: Date
    let ara: Date
    @State private var parpelleja = false
    @Environment(\.accessibilityReduceMotion) private var reduirMoviment

    var body: some View {
        if Calendar.current.isDateInToday(data) {
            Text("ÉS HUI!!! 🏃‍♀️💨")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Paleta.alerta)
                .opacity(parpelleja ? 0.35 : 1)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: parpelleja)
                .onAppear { parpelleja = !reduirMoviment }
            Text(Compte.text(fins: data, ara: ara))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Paleta.alerta)
        } else {
            Text(Compte.text(fins: data, ara: ara))
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(Paleta.alerta)
                .contentTransition(.numericText())
        }
    }
}

// MARK: - Fila de cita

private struct FilaCita: View {
    let cita: Cita
    let categoria: CategoriaMetge?
    let edita: () -> Void
    let accio: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: edita) {
                HStack(spacing: 12) {
                    Text(categoria?.emoji ?? "🏥").font(.system(size: 30))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cita.titol)
                            .font(.titolTargeta)
                            .foregroundStyle(Paleta.tinta)
                            .multilineTextAlignment(.leading)
                        Text(subtitol)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Paleta.tintaSuau)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Paleta.tintaSuau)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            switch cita.estat {
            case .perDemanar:
                Button(action: accio) {
                    Label("📞 Ja l'he demanada", systemImage: "phone.arrow.up.right")
                }
                .buttonStyle(.suau(Paleta.alerta, ple: true))
            case .programada:
                Button(action: accio) {
                    Label("Feta", systemImage: "checkmark.circle")
                }
                .buttonStyle(.suau(Paleta.alerta))
            case .feta:
                EmptyView()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clay(Paleta.alerta, radi: Clay.radiMitja, elevacio: 0.6)
    }

    private var subtitol: String {
        switch cita.estat {
        case .perDemanar:
            if let r = cita.recordarDemanarEl { return "Recorda'm: \(Dates.curta(r)) a les \(Dates.hora(r))" }
            return "Sense recordatori"
        case .programada, .feta:
            guard let d = cita.data else { return "Sense data" }
            let base = "\(Dates.llarga(d)) · \(Dates.hora(d))"
            let passada = cita.estat == .programada && d < Date() ? " · ja ha passat, està feta?" : ""
            return base + (cita.lloc.isEmpty ? "" : " · \(cita.lloc)") + passada
        }
    }
}
