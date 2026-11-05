import SwiftUI
import WidgetKit

/// Famílies compatibles segons la plataforma (els accessoris només existeixen a iOS).
enum FamiliesWidget {
    #if os(iOS)
    static let hui: [WidgetFamily] = [.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular]
    static let cita: [WidgetFamily] = [.systemSmall, .systemMedium, .accessoryRectangular]
    static let menu: [WidgetFamily] = [.systemSmall, .systemMedium, .accessoryRectangular]
    static let cansament: [WidgetFamily] = [.systemSmall, .accessoryCircular]
    #else
    static let hui: [WidgetFamily] = [.systemSmall, .systemMedium]
    static let cita: [WidgetFamily] = [.systemSmall, .systemMedium]
    static let menu: [WidgetFamily] = [.systemSmall, .systemMedium]
    static let cansament: [WidgetFamily] = [.systemSmall]
    #endif
}

/// Dates en valencià per als widgets (no poden usar el codi de l'app).
enum FormatWidget {
    static let locale = Locale(identifier: "ca_ES")

    static func diaLlarg(_ d: Date) -> String {
        d.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
    }

    static func hora(_ d: Date) -> String {
        d.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().locale(locale))
    }
}
