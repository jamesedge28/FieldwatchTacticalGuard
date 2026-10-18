import SwiftUI

// MARK: - Tactical Guard Design System (Tema Táctico de Contrainteligencia)
// Configuración estricta en modo oscuro: Fondos #000000, Tarjetas #1C1C1E, Acentos #00FF00

public struct TacticalTheme {
    // Paleta de Colores Principal
    public static let pureBlack = Color(red: 0.0, green: 0.0, blue: 0.0)             // #000000
    public static let cardDarkGray = Color(red: 0.11, green: 0.11, blue: 0.12)       // #1C1C1E
    public static let secondaryCardGray = Color(red: 0.17, green: 0.17, blue: 0.18)  // #2C2C2E
    public static let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.0)             // #00FF00
    public static let neonGreenDimmed = Color(red: 0.0, green: 0.65, blue: 0.0)       // Verde Táctico Atenuado
    public static let alertRed = Color(red: 1.0, green: 0.23, blue: 0.19)            // #FF3B30
    public static let warningAmber = Color(red: 1.0, green: 0.58, blue: 0.0)         // #FF9500
    public static let hudCyan = Color(red: 0.0, green: 0.9, blue: 1.0)               // #00E5FF
    public static let textMuted = Color(red: 0.55, green: 0.55, blue: 0.58)          // Gris texto militar
    
    // Fuentes de estilo militar / monospaced táctico
    public static func monoFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Modificadores de Vista Tácticos

public struct TacticalCardModifier: ViewModifier {
    var borderColor: Color = TacticalTheme.neonGreen.opacity(0.3)
    var cornerRadius: CGFloat = 8
    var backgroundColor: Color = TacticalTheme.cardDarkGray

    public func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
}

public struct TacticalHUDFrameModifier: ViewModifier {
    var color: Color = TacticalTheme.neonGreen
    var bracketLength: CGFloat = 12
    var lineWidth: CGFloat = 2

    public func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    // Esquina Superior Izquierda
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: bracketLength))
                        path.addLine(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: bracketLength, y: 0))
                    }
                    .stroke(color, lineWidth: lineWidth)

                    // Esquina Superior Derecha
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: geo.size.width - bracketLength, y: 0))
                            path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                            path.addLine(to: CGPoint(x: geo.size.width, y: bracketLength))
                        }
                        .stroke(color, lineWidth: lineWidth)
                    }

                    // Esquina Inferior Izquierda
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height - bracketLength))
                            path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                            path.addLine(to: CGPoint(x: bracketLength, y: geo.size.height))
                        }
                        .stroke(color, lineWidth: lineWidth)
                    }

                    // Esquina Inferior Derecha
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: geo.size.width - bracketLength, y: geo.size.height))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - bracketLength))
                        }
                        .stroke(color, lineWidth: lineWidth)
                    }
                }
            )
    }
}

public extension View {
    func tacticalCard(borderColor: Color = TacticalTheme.neonGreen.opacity(0.3),
                      backgroundColor: Color = TacticalTheme.cardDarkGray,
                      cornerRadius: CGFloat = 8) -> some View {
        self.modifier(TacticalCardModifier(borderColor: borderColor, cornerRadius: cornerRadius, backgroundColor: backgroundColor))
    }

    func tacticalHUDFrame(color: Color = TacticalTheme.neonGreen) -> some View {
        self.modifier(TacticalHUDFrameModifier(color: color))
    }
}

// MARK: - Componentes Reutilizables de Interfaz

/// Barra superior de estado militar con código de misión y batería/reloj UTC
public struct TacticalTopBar: View {
    let title: String
    let statusText: String
    let statusColor: Color

    public init(title: String, statusText: String = "SISTEMA ACTIVO", statusColor: Color = TacticalTheme.neonGreen) {
        self.title = title
        self.statusText = statusText
        self.statusColor = statusColor
    }

    public var body: some View {
        VStack(spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: statusColor, radius: 4)
                    
                    Text("FW-TACTICAL // V4.2")
                        .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                        .foregroundColor(TacticalTheme.neonGreenDimmed)
                }

                Spacer()

                HStack(spacing: 12) {
                    Text("SEC: TACTICAL-DEF")
                        .font(TacticalTheme.monoFont(size: 9, weight: .semibold))
                        .foregroundColor(TacticalTheme.textMuted)

                    Text(Date(), style: .time)
                        .font(TacticalTheme.monoFont(size: 10, weight: .bold))
                        .foregroundColor(TacticalTheme.neonGreen)
                }
            }

            HStack {
                Text(title.uppercased())
                    .font(TacticalTheme.monoFont(size: 18, weight: .black))
                    .foregroundColor(TacticalTheme.neonGreen)

                Spacer()

                Text("[ \(statusText) ]")
                    .font(TacticalTheme.monoFont(size: 10, weight: .heavy))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.12))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(statusColor.opacity(0.4), lineWidth: 1)
                    )
            }
            
            Divider()
                .background(TacticalTheme.neonGreen.opacity(0.3))
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(TacticalTheme.pureBlack)
    }
}

/// Medidor de barra segmentada militar para RSSI o porcentajes
public struct TacticalGaugeBar: View {
    let value: Double // 0.0 a 1.0
    let label: String
    let detailText: String
    var alertThreshold: Double = 0.75
    var primaryColor: Color = TacticalTheme.neonGreen
    var alertColor: Color = TacticalTheme.alertRed

    public init(value: Double, label: String, detailText: String, alertThreshold: Double = 0.75) {
        self.value = max(0.0, min(1.0, value))
        self.label = label
        self.detailText = detailText
        self.alertThreshold = alertThreshold
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(TacticalTheme.monoFont(size: 11, weight: .semibold))
                    .foregroundColor(TacticalTheme.textMuted)
                Spacer()
                Text(detailText)
                    .font(TacticalTheme.monoFont(size: 11, weight: .bold))
                    .foregroundColor(value >= alertThreshold ? alertColor : primaryColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Fondo de medidor
                    Rectangle()
                        .fill(TacticalTheme.secondaryCardGray)
                        .frame(height: 8)

                    // Progreso
                    Rectangle()
                        .fill(value >= alertThreshold ? alertColor : primaryColor)
                        .frame(width: geo.size.width * CGFloat(value), height: 8)
                        .shadow(color: (value >= alertThreshold ? alertColor : primaryColor).opacity(0.6), radius: 3)
                }
                .cornerRadius(2)
            }
            .frame(height: 8)
        }
    }
}
