import SwiftUI

public struct MemberCard: View {
    let member: Member
    
    public init(member: Member) {
        self.member = member
    }
    
    public var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(initials(for: member.fullName))
                        .font(Typography.headline)
                        .foregroundColor(.accentColor)
                )
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(member.fullName)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                if let role = member.role {
                    Text(role)
                        .font(Typography.caption1)
                        .foregroundColor(Theme.textSecondary)
                }
                
                HStack(spacing: Spacing.xs) {
                    if member.accessLevel == "admin" {
                        tagView(text: "Admin", color: .red)
                    }
                    if member.isSenior {
                        tagView(text: "Sênior", color: .blue)
                    }
                    if member.isMason {
                        tagView(text: "Maçom", color: .purple)
                    }
                    if member.isActive {
                        tagView(text: "Ativo", color: .green)
                    }
                }
                .padding(.top, Spacing.xxs)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Theme.textTertiary)
                .font(Typography.caption1)
        }
        .padding(Spacing.md)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }
    
    @ViewBuilder
    private func tagView(text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(Typography.caption2).bold()
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
    
    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components.last?.prefix(1) ?? ""
            return String(first + last).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "??"
    }
}
