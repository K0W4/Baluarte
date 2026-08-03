import SwiftUI

public struct MemberCard: View {
    let member: Member
    
    public init(member: Member) {
        self.member = member
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(alignment: .center, spacing: Spacing.xs) {
                    ViewThatFits(in: .horizontal) {
                        Text(member.fullName)
                            .font(Typography.headline)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            
                        Text(abbreviatedName(for: member.fullName))
                            .font(Typography.headline)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    .layoutPriority(1)
                    
                    if member.accessLevel == "admin" { tagView(text: "Admin") }
                    if member.isSenior { tagView(text: "Sênior") }
                    if member.isMason { tagView(text: "Maçom") }
                    if member.isActive { tagView(text: "Ativo") }
                }
                
                Text(member.role ?? "Sem cargo")
                    .font(Typography.subheadline)
                    .foregroundColor(member.role != nil ? Theme.textSecondary : Theme.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: Spacing.xs)
            
            Image(systemName: "chevron.right")
                .font(Typography.body)
                .foregroundColor(Theme.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.fullName), \(member.role ?? "Sem cargo"), \(member.isActive ? "Ativo" : "Inativo")")
        .accessibilityHint("Toque para ver detalhes do membro")
        .accessibilityAddTraits(.isButton)
        .padding(Spacing.md)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Spacing.cornerRadius).stroke(Theme.border, lineWidth: 1))
    }
    
    @ViewBuilder
    private func tagView(text: String) -> some View {
        Text(text)
            .font(Typography.caption2)
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.textSecondary.opacity(0.15))
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
    }
    
    private func abbreviatedName(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0]
            let last = components.last?.prefix(1) ?? ""
            return "\(first) \(last)."
        }
        return name
    }
}
