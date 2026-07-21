import SwiftUI

public struct ProgressRingCard: View {
    let goal: Goal
    
    private let lineWidth: CGFloat = 16
    private let size: CGFloat = 120
    
    public init(goal: Goal) {
        self.goal = goal
    }
    
    private var progressPercentageValue: Int {
        return Int(goal.progressPercentage * 100)
    }
    
    private var formattedCurrent: String {
        return String(format: "%g", goal.currentValue)
    }
    
    private var formattedTarget: String {
        return String(format: "%g", goal.targetValue)
    }
    
    private var baseColor: Color {
        let percent = progressPercentageValue
        if percent < 50 { return .red }
        if percent < 80 { return .yellow }
        return .green
    }
    
    private var ringGradient: AngularGradient {
        let percent = progressPercentageValue
        let startColor: Color
        let endColor: Color
        
        if percent < 50 {
            startColor = .red.opacity(0.5)
            endColor = .red
        } else if percent < 80 {
            startColor = .orange
            endColor = .yellow
        } else {
            startColor = .green.opacity(0.5)
            endColor = .green
        }
        
        return AngularGradient(
            gradient: Gradient(colors: [startColor, endColor, startColor]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }
    
    public var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(baseColor.opacity(0.2), lineWidth: lineWidth)
                
                Circle()
                    .trim(from: 0, to: CGFloat(goal.progressPercentage))
                    .stroke(ringGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: Spacing.xxs) {
                    Text("\(progressPercentageValue)%")
                        .font(Typography.numericDisplay)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("\(formattedCurrent)/\(formattedTarget)")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.textSecondary)
                        .bold()
                }
            }
            .frame(width: size, height: size)
            
            VStack(spacing: Spacing.xxs) {
                Text(goal.title)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .center)
                
                if let desc = goal.description, !desc.isEmpty {
                    Text(desc)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(height: 40, alignment: .top)
                } else {
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(baseColor.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), type: "Financeiro", title: "Mensalidades", description: "Arrecadação mensal", currentValue: 850, targetValue: 2000, targetDate: nil, createdAt: Date()))
            
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), type: "Iniciação", title: "Novos Membros", description: "Campanha 2026", currentValue: 3, targetValue: 5, targetDate: nil, createdAt: Date()))
            
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), type: "Filantropia", title: "Doações", description: "Campanha do agasalho", currentValue: 1700, targetValue: 2000, targetDate: nil, createdAt: Date()))
        }
        .padding()
    }
    .background(Color(UIColor.systemBackground))
    .preferredColorScheme(.dark)
}
