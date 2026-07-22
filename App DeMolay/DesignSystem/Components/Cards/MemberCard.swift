import SwiftUI

public struct MemberCard: View {
    let member: Member
    
    public init(member: Member) {
        self.member = member
    }
    
    public var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(initials(for: member.fullName))
                            .font(Typography.headline)
                            .foregroundColor(Theme.accent)
                    )
                
                Text(member.fullName)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(Typography.body)
                    .foregroundColor(Theme.accent)
            }
            
            Divider()
                .background(Theme.border)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(member.role ?? "Sem cargo")
                    .font(Typography.subheadline)
                    .foregroundColor(member.role != nil ? Theme.textSecondary : Theme.textTertiary)
                
                HStack(spacing: Spacing.xs) {
                    if member.accessLevel == "admin" {
                        tagView(text: "Admin", color: .red)
                    }
                    if member.isSenior {
                        tagView(text: "Sênior", color: .blue)
                    }
                    if member.isMason {
                        tagView(text: "Maçom", color: .yellow)
                    }
                    if member.isActive {
                        tagView(text: "Ativo", color: .green)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }
    
    @ViewBuilder
    private func tagView(text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(Typography.caption2)
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
