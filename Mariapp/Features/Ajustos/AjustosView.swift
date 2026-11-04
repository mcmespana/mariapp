import SwiftUI

struct AjustosView: View {
    @Environment(DataStore.self) private var store
    @Environment(Preferencies.self) private var prefs
    @Environment(Sincronitzacio.self) private var sync
    @Environment(Navegacio.self) private var nav
    @Environment(ServeiCalendari.self) private var calendari

    @State private var codi = ""
    @State private var clauIA = ServeiIA.clau ?? ""
    @State private var provaIA: String?
    @State private var provantIA = false

    var body: some View {
        @Bindable var prefs = prefs
        Form {
            Section("Qui eres?") {
                Picker("En aquest dispositiu", selection: Binding(get: { prefs.rol ?? .maria }, set: { prefs.rol = $0 })) {
                    Text("🌻 Maria").tag(Rol.maria)
                    Text("🐻 David (convidat)").tag(Rol.david)
                }
            }
            .listRowBackground(Paleta.paper)

            seccioSincronitzacio
                .listRowBackground(Paleta.paper)

            if prefs.esMaria {
                Section {
                    Stepper(value: Binding(get: { store.config.ampollaMl }, set: { v in store.desaConfig { $0.ampollaMl = v } }), in: 250...2000, step: 50) {
                        LabeledContent("Mida de la botella", value: FormatAigua.text(store.config.ampollaMl))
                    }
                    Stepper(value: Binding(get: { store.config.objectiuMl }, set: { v in store.desaConfig { $0.objectiuMl = v } }), in: 500...5000, step: 250) {
                        LabeledContent("Objectiu diari", value: "\(FormatAigua.text(store.config.objectiuMl)) · \(FormatAigua.ampolles(store.config.objectiuMl, ampolla: store.config.ampollaMl))")
                    }
                } header: {
                    Text("Aigua 💧")
                }
                .listRowBackground(Paleta.paper)

                Section {
                    Toggle("Avisos actius", isOn: $prefs.avisosActius)
                    DatePicker("Pregunta pel cansament", selection: Binding(get: { prefs.horaCansament.comData }, set: { prefs.horaCansament = Hora($0) }), displayedComponents: .hourAndMinute)
                    ForEach(prefs.horesAigua.sorted()) { hora in
                        HStack {
                            Text("💧 Recordatori d'aigua")
                            Spacer()
                            Text(hora.text).foregroundStyle(Paleta.tintaSuau)
                            Button(role: .destructive) {
                                prefs.horesAigua.removeAll { $0 == hora }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    NovaHoraAigua { prefs.horesAigua.append($0) }
                    Toggle("Preguntar pel gimnàs", isOn: $prefs.avisGimnas)
                    if prefs.avisGimnas {
                        DatePicker("Hora del gimnàs", selection: Binding(get: { prefs.horaGimnas.comData }, set: { prefs.horaGimnas = Hora($0) }), displayedComponents: .hourAndMinute)
                    }
                    Toggle("Sonets divertits", isOn: $prefs.sonsActius)
                    #if os(iOS)
                    Toggle("Aigua i cafés a la pantalla de bloqueig", isOn: $prefs.activitatEnDirecte)
                    #endif
                } header: {
                    Text("Avisos 🔔")
                } footer: {
                    Text("Des de la notificació pots apuntar sense obrir l'app: mantén-la premuda.")
                }
                .listRowBackground(Paleta.paper)
            }

            Section {
                if calendari.autoritzat {
                    LabeledContent("Accés al calendari", value: "✅")
                    Picker("Calendari per a les cites", selection: Binding(get: { calendari.calendariCites ?? "" }, set: { calendari.calendariCites = $0.isEmpty ? nil : $0 })) {
                        Text("El per defecte").tag("")
                        ForEach(calendari.calendaris, id: \.calendarIdentifier) { c in
                            Text(c.title).tag(c.calendarIdentifier)
                        }
                    }
                } else {
                    Button("Donar accés al calendari") { Task { await calendari.demanaAcces() } }
                }
            } header: {
                Text("Calendari 📆")
            } footer: {
                Text("Per a veure el Google Calendar compartit, afegeix el compte de Google a Ajustos del sistema › Calendari.")
            }
            .listRowBackground(Paleta.paper)

            Section {
                SecureField("Clau de l'API d'Anthropic (sk-ant-…)", text: $clauIA)
                    .onSubmit { ServeiIA.clau = clauIA }
                Picker("Model", selection: $prefs.modelIA) {
                    Text("Haiku (ràpid i barat)").tag(ServeiIA.modelRapid)
                    Text("Sonnet (més llest)").tag(ServeiIA.modelBo)
                }
                Button(provantIA ? "Provant…" : "Desar i provar") {
                    ServeiIA.clau = clauIA
                    provantIA = true
                    Task {
                        do {
                            provaIA = try await ServeiIA.pregunta("Saluda la Maria en una frase curta i suggereix-li un sopar lleuger.", maxTokens: 300)
                        } catch {
                            provaIA = "⚠️ \(error.localizedDescription)"
                        }
                        provantIA = false
                    }
                }
                .disabled(clauIA.isEmpty || provantIA)
                if let provaIA {
                    Text(provaIA).font(.system(.callout, design: .rounded)).foregroundStyle(Paleta.tintaSuau)
                }
            } header: {
                Text("Intel·ligència artificial ✨")
            } footer: {
                Text("S'usa per a suggerir plats i analitzar dades. La clau només es guarda en aquest dispositiu.")
            }
            .listRowBackground(Paleta.paper)

            Section {
                LabeledContent("Versió", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–")
                Text("Feta amb 💛 per a la Maria")
                    .foregroundStyle(Paleta.tintaSuau)
            }
            .listRowBackground(Paleta.paper)
        }
        .formStyle(.grouped)
        .fonsMariapp()
        .navigationTitle("Ajustos")
        .onAppear {
            if let c = nav.codiInvitacio { codi = c }
        }
    }

    @ViewBuilder
    private var seccioSincronitzacio: some View {
        Section {
            if !Sincronitzacio.firebaseDisponible {
                Label("Les dades es guarden només en aquest dispositiu.", systemImage: "iphone")
                Text("Per a sincronitzar amb el Mac i compartir amb David cal configurar Firebase (veure docs/FIREBASE.md).")
                    .font(.footnote)
                    .foregroundStyle(Paleta.tintaSuau)
            } else {
                switch sync.estat {
                case .local, .error:
                    if case .error(let msg) = sync.estat {
                        Text(msg).foregroundStyle(Paleta.taronja)
                    }
                    if prefs.esMaria {
                        Button {
                            Task { await sync.creaLlar() }
                        } label: {
                            Label("Crear la llar al núvol", systemImage: "icloud.and.arrow.up")
                        }
                    }
                    TextField("Codi de la llar", text: $codi)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        #endif
                    Button {
                        Task { await sync.uneix(codi: codi) }
                    } label: {
                        Label("Unir-me amb el codi", systemImage: "person.badge.plus")
                    }
                    .disabled(codi.isEmpty)
                case .connectant:
                    HStack { ProgressView(); Text("Connectant…") }
                case .connectat(let codiLlar):
                    LabeledContent("Estat", value: "Sincronitzat ☁️")
                    LabeledContent("Codi de la llar") {
                        Text(codiLlar).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                    }
                    ShareLink(item: sync.enllacInvitacio(codiLlar),
                              subject: Text("Mariapp"),
                              message: Text("Uneix-te a la Mariapp amb el codi \(codiLlar) 💛")) {
                        Label("Convidar (David, el Mac…)", systemImage: "square.and.arrow.up")
                    }
                    Button("Desconnectar aquest dispositiu", role: .destructive) { sync.desconnecta() }
                }
            }
        } header: {
            Text("Sincronització i convidats")
        } footer: {
            Text("La llar té un codi secret. Qualsevol dispositiu amb el codi veu i edita les dades.")
        }
    }
}

private struct NovaHoraAigua: View {
    let afegeix: (Hora) -> Void
    @State private var hora = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        HStack {
            DatePicker("Nou recordatori", selection: $hora, displayedComponents: .hourAndMinute)
            Button {
                afegeix(Hora(hora))
            } label: {
                Image(systemName: "plus.circle.fill").foregroundStyle(Paleta.aigua)
            }
            .buttonStyle(.borderless)
        }
    }
}
