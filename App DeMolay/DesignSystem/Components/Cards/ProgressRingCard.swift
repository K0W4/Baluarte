import SwiftUI

public struct ProgressRingCard: View {
    let goal: Goal
    @State private var animatedProgress: Double = 0
    
    private let lineWidth: CGFloat = 16
    private let size: CGFloat = 120
    
    public init(goal: Goal) {
        self.goal = goal
    }
    
    private var progressPercentageValue: Int {
        return Int(animatedProgress * 100)
    }
    
    private var formattedCurrent: String {
        let currentAnimatedValue = animatedProgress * goal.targetValue
        return String(format: "%.0f", currentAnimatedValue)
    }
    
    private var formattedTarget: String {
        return String(format: "%.0f", goal.targetValue)
    }
    
    private var baseColor: Color {
        let percent = Int(goal.progressPercentage * 100)
        if percent < 50 { return .red }
        if percent < 80 { return .orange }
        if percent < 100 { return .green }
        return .blue
    }
    
    private var gradientColors: (start: Color, end: Color) {
        let percent = Int(goal.progressPercentage * 100)
        if percent < 50 { return (.red, .pink) }
        if percent < 80 { return (.orange, .yellow) }
        if percent < 100 { return (.green, .mint) }
        return (.cyan, .cyan)
    }
    
    private var ringGradient: AngularGradient {
        let colors = gradientColors
        return AngularGradient(
            gradient: Gradient(colors: [colors.start, colors.end]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
    
    public var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(baseColor.opacity(0.2), lineWidth: lineWidth)
                
                Circle()
                    .trim(from: 0, to: min(CGFloat(animatedProgress), 1.0))
                    .stroke(ringGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .fill(gradientColors.start)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -size / 2)
                    .opacity(goal.progressPercentage > 0 ? 1.0 : 0.0)
                
                if animatedProgress > 1.0 {
                    let overlap = CGFloat(animatedProgress) - 1.0
                    
                    let angle = Angle.degrees(360 * Double(overlap) - 90)
                    let radius = size / 2
                    Circle()
                        .fill(Color.black)
                        .frame(width: lineWidth - 2, height: lineWidth - 2)
                        .offset(x: cos(angle.radians) * radius, y: sin(angle.radians) * radius)
                        .shadow(color: .black.opacity(0.4), radius: 5, x: 0, y: 0)
                    
                    Circle()
                        .trim(from: 0, to: min(overlap, 1.0))
                        .stroke(ringGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                
                VStack(spacing: Spacing.xxs) {
                    Text("\(progressPercentageValue)%")
                        .font(Typography.numericDisplay)
                        .foregroundColor(Theme.textPrimary)
                        .contentTransition(.numericText())
                    
                    Text("\(formattedCurrent)/\(formattedTarget)")
                        .font(Typography.caption1)
                        .foregroundColor(Theme.textSecondary)
                        .contentTransition(.numericText())
                }
            }
            .frame(width: size, height: size)
            
            VStack(spacing: Spacing.xxs) {
                Text(goal.title)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 48, alignment: .center)
                
                if let desc = goal.description, !desc.isEmpty {
                    Text(desc)
                        .font(Typography.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(height: 48, alignment: .top)
                } else {
                    Spacer()
                        .frame(height: 48)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
        .padding(.top, Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        )
        .onAppear {
            withAnimation(.spring(response: 1, dampingFraction: 0.9, blendDuration: 0.5)) {
                animatedProgress = goal.progressPercentage
            }
        }
        .onChange(of: goal.progressPercentage) { _, newValue in
            withAnimation(.spring(response: 1, dampingFraction: 0.9, blendDuration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), type: "Financeiro", title: "Mensalidades", description: "Arrecadação mensal", currentValue: 999, targetValue: 2000, targetDate: nil, createdAt: Date()))
            
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), type: "Iniciação", title: "Novos Membros", description: "Campanha 2026", currentValue: 79, targetValue: 100, targetDate: nil, createdAt: Date()))
            
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), type: "Filantropia", title: "Doações", description: "Campanha do agasalho", currentValue: 1999, targetValue: 2000, targetDate: nil, createdAt: Date()))
            
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), type: "Filantropia", title: "Doações", description: "Irmão Sangue Bom", currentValue: 150, targetValue: 100, targetDate: nil, createdAt: Date()))
        }
        .padding()
    }
    .background(Color(UIColor.systemBackground))
    .preferredColorScheme(.dark)
}
