import SwiftUI

/// A component for selecting between major styles with a larger preview area.
struct StyleSelectButton<T: Equatable, Content: View>: View {
    let title: String
    let value: T
    @Binding var currentSelection: T
    @ViewBuilder let content: Content
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentSelection = value
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                    
                    content
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(width: 72, height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .padding(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(currentSelection == value ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                
                Text(title)
                    .font(.system(size: 11, weight: currentSelection == value ? .semibold : .medium))
                    .foregroundColor(currentSelection == value ? .primary : .secondary)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }
}

/// A compact component for selecting options.
struct OptionSelectButton<T: Equatable, Content: View>: View {
    let title: String
    let value: T
    @Binding var currentSelection: T
    @ViewBuilder let content: Content
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentSelection = value
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                    
                    content
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .frame(width: 44, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .padding(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(currentSelection == value ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                
                Text(title)
                    .font(.system(size: 9, weight: currentSelection == value ? .semibold : .medium))
                    .foregroundColor(currentSelection == value ? .primary : .secondary)
            }
            .frame(width: 48)
        }
        .buttonStyle(.plain)
    }
}

/// A wide component for selecting options that need more horizontal space.
struct WideOptionSelectButton<T: Equatable, Content: View>: View {
    let title: String
    let value: T
    @Binding var currentSelection: T
    @ViewBuilder let content: Content
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentSelection = value
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                    
                    content
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(width: 80, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .padding(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(currentSelection == value ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                
                Text(title)
                    .font(.system(size: 10, weight: currentSelection == value ? .semibold : .medium))
                    .foregroundColor(currentSelection == value ? .primary : .secondary)
            }
            .frame(width: 90)
        }
        .buttonStyle(.plain)
    }
}

/// A simple color swatch for previews.
struct ColorSwatch: View {
    var c1: Color
    var c2: Color
    var body: some View {
        LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
