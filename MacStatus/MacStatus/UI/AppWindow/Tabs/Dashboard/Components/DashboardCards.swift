import SwiftUI

struct DashboardCards: View {
    var body: some View {
        EmptyView() // This file is just for component definitions
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(iconColor)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct DashboardSimpleCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // Colored Icon Badge
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Text Group
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(LocalizedStringKey(label))
                .foregroundColor(.secondary)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}
