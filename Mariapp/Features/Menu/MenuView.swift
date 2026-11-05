import SwiftUI

/// Secció Menú: la setmana i els plats guardats.
struct MenuView: View {
    enum Pestanya: String, CaseIterable, Identifiable {
        case setmana = "Setmana"
        case plats = "Plats"
        var id: String { rawValue }
    }

    @State private var pestanya: Pestanya = .setmana

    var body: some View {
        VStack(spacing: 0) {
            Picker("Vista", selection: $pestanya) {
                ForEach(Pestanya.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch pestanya {
            case .setmana: SetmanaView()
            case .plats: PlatsView()
            }
        }
        .fonsMariapp()
        .navigationTitle("Menú")
        .sensoryFeedback(.selection, trigger: pestanya)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    LlistaCompraView()
                } label: {
                    Label("Llista de la compra", systemImage: "cart")
                }
            }
        }
    }
}
