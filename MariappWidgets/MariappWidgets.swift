import SwiftUI
import WidgetKit

@main
struct MariappWidgets: WidgetBundle {
    var body: some Widget {
        HuiWidget()
        CitaWidget()
        MenuWidget()
        CansamentWidget()
        HuiLiveActivity()
        AiguaControl()
        CafeControl()
    }
}

// MARK: - Controls (Centre de control / pantalla de bloqueig / botó d'Acció)

struct AiguaControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "es.mariapp.control.aigua") {
            ControlWidgetButton(action: SumaAiguaIntent(ml: HuiSnapshot.carrega().ampollaMl / 2)) {
                Label("Mitja botella", systemImage: "drop.fill")
            }
        }
        .displayName("Apuntar aigua")
        .description("Suma mitja botella d'aigua.")
    }
}

struct CafeControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "es.mariapp.control.cafe") {
            ControlWidgetButton(action: SumaCafeIntent()) {
                Label("Café", systemImage: "cup.and.saucer.fill")
            }
        }
        .displayName("Apuntar café")
    }
}
