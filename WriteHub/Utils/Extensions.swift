import SwiftUI
import Foundation

// MARK: - Date Extensions
extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func endOfDay() -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay())!
    }
    
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }
    
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    func startOfYear() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)!
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isYesterday() -> Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    func daysFromNow() -> Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }
    
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func formatted(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    func relativeFormatted() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - String Extensions
extension String {
    func wordCount() -> Int {
        let words = self.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    func characterCount() -> Int {
        return self.count
    }
    
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func truncated(to length: Int) -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + "..."
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    func extractHashtags() -> [String] {
        let pattern = #"#\w+"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: self, options: [], range: NSRange(location: 0, length: self.count)) ?? []
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: self) else { return nil }
            return String(self[range])
        }
    }
    
    func highlightHashtags() -> AttributedString {
        var attributedString = AttributedString(self)
        let hashtags = extractHashtags()
        
        for hashtag in hashtags {
            if let range = attributedString.range(of: hashtag) {
                attributedString[range].foregroundColor = .blue
                attributedString[range].font = .system(.body, design: .monospaced).bold()
            }
        }
        
        return attributedString
    }
}

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let nsColor = NSColor(self)
        guard let components = nsColor.cgColor.components else { return "#000000" }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
    
    static let writeHubPrimary = Color(hex: "#007AFF") ?? .blue
    static let writeHubSecondary = Color(hex: "#5856D6") ?? .purple
    static let writeHubAccent = Color(hex: "#34C759") ?? .green
    static let writeHubWarning = Color(hex: "#FF9500") ?? .orange
    static let writeHubError = Color(hex: "#FF3B30") ?? .red
    
    static let contributionLevel0 = Color(.controlBackgroundColor)
    static let contributionLevel1 = Color.green.opacity(0.3)
    static let contributionLevel2 = Color.green.opacity(0.5)
    static let contributionLevel3 = Color.green.opacity(0.7)
    static let contributionLevel4 = Color.green.opacity(0.9)
    static let contributionLevel5 = Color.green
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    func hideKeyboard() {
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
    }
    
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        self.overlay(
            ToastView(message: message, isPresented: isPresented)
        )
    }
    
    func cardStyle(backgroundColor: Color = Color(.controlBackgroundColor)) -> some View {
        self
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    func buttonStyle(primary: Bool = false) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(primary ? Color.writeHubPrimary : Color(.controlBackgroundColor))
            .foregroundColor(primary ? .white : .primary)
            .cornerRadius(8)
    }
}

// MARK: - Custom Shapes
struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight), 
                   radius: topRight, 
                   startAngle: Angle(degrees: -90), 
                   endAngle: Angle(degrees: 0), 
                   clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight), 
                   radius: bottomRight, 
                   startAngle: Angle(degrees: 0), 
                   endAngle: Angle(degrees: 90), 
                   clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft), 
                   radius: bottomLeft, 
                   startAngle: Angle(degrees: 90), 
                   endAngle: Angle(degrees: 180), 
                   clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft), 
                   radius: topLeft, 
                   startAngle: Angle(degrees: 180), 
                   endAngle: Angle(degrees: 270), 
                   clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Custom Views
struct ToastView: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isPresented {
                HStack {
                    Text(message)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                }
                .transition(.slide)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            }
        }
        .padding()
        .allowsHitTesting(false)
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        description: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64, design: .default))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(buttonTitle, action: buttonAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Utility Functions
func formatCount(_ count: Int) -> String {
    if count < 1000 {
        return "\(count)"
    } else if count < 1000000 {
        let thousands = Double(count) / 1000.0
        return String(format: "%.1fK", thousands)
    } else {
        let millions = Double(count) / 1000000.0
        return String(format: "%.1fM", millions)
    }
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let hours = Int(seconds) / 3600
    let minutes = Int(seconds) % 3600 / 60
    let secs = Int(seconds) % 60
    
    if hours > 0 {
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%02d:%02d", minutes, secs)
    }
}

func generateRandomColor() -> Color {
    let colors: [Color] = [
        .red, .blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint, .cyan
    ]
    return colors.randomElement() ?? .blue
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func light() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
    
    static func medium() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
    
    static func heavy() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
    
    static func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
    
    static func error() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
    }
}

// MARK: - Keyboard Shortcuts
struct KeyboardShortcuts {
    static let newViewpoint = KeyEquivalent("n")
    static let search = KeyEquivalent("f")
    static let export = KeyEquivalent("e")
    static let statistics = KeyEquivalent("s")
    static let preferences = KeyEquivalent(",")
}