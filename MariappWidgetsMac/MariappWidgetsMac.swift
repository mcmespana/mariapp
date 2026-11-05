import SwiftUI
import WidgetKit

/// Widgets de macOS (Centre de notificacions i escriptori). Reutilitzen les vistes de `WidgetsComuns`.
@main
struct MariappWidgetsMac: WidgetBundle {
    var body: some Widget {
        HuiWidget()
        CitaWidget()
        MenuWidget()
        CansamentWidget()
        CompraWidget()
    }
}
