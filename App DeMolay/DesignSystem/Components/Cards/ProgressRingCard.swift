import SwiftUI

public struct ProgressRingCard: View {
    let goal: Goal
    @State private var animatedProgress: Double = 0
    @State private var showShadowDot: Bool = false
    @State private var isAnimating: Bool = false
    
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
        if percent < 50 { return Theme.destructive }
        if percent < 80 { return Theme.warning }
        if percent < 100 { return Theme.success }
        return Theme.progressAdvancedEnd
    }
    
    private var gradientColors: (start: Color, end: Color) {
        let percent = Int(goal.progressPercentage * 100)
        if percent < 50 { return (Theme.destructive, Theme.progressLowEnd) }
        if percent < 80 { return (Theme.warning, Theme.progressMediumEnd) }
        if percent < 100 { return (Theme.success, Theme.progressHighEnd) }
        return (Theme.progressAdvancedEnd, Theme.progressAdvancedEnd)
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
                
                OverflowRing(
                    currentOverlap: max(0, CGFloat(animatedProgress) - 1.0),
                    targetOverlap: max(0, CGFloat(goal.progressPercentage) - 1.0),
                    showShadowDot: showShadowDot,
                    size: size,
                    lineWidth: lineWidth,
                    ringGradient: ringGradient
                )
                .opacity(animatedProgress > 1.0 ? 1.0 : 0.0)
                
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
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            
            VStack(spacing: Spacing.xxs) {
                Text(goal.title)
                    .font(Typography.headline)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 48, alignment: .center)
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
            } completion: {
                if goal.progressPercentage > 1.0 {
                    withAnimation(.easeIn(duration: 0.15)) {
                        showShadowDot = true
                    }
                }
            }
            if goal.progressPercentage >= 1.0 {
                isAnimating = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                    isAnimating = false
                }
            }
        }
        .onChange(of: goal.progressPercentage) { _, newValue in
            showShadowDot = false
            withAnimation(.spring(response: 1, dampingFraction: 0.9, blendDuration: 0.5)) {
                animatedProgress = newValue
            } completion: {
                if newValue > 1 {
                    withAnimation(.easeIn(duration: 0.1)) {
                        showShadowDot = true
                    }
                }
            }
            if newValue >= 1.0 {
                isAnimating = true
                withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                    isAnimating = false
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(goal.title), \(progressPercentageValue) por cento")
        .accessibilityValue("\(progressPercentageValue) por cento")
        .accessibilityHint("Toque para ver detalhes da meta")
    }
}

private struct OverflowRing: View {
    let currentOverlap: CGFloat
    let targetOverlap: CGFloat
    let showShadowDot: Bool
    let size: CGFloat
    let lineWidth: CGFloat
    let ringGradient: AngularGradient
    
    var body: some View {
        let finalAngle = Angle.degrees(360 * Double(targetOverlap) - 90)
        let radius = size / 2
        
        Circle()
            .fill(Color.black)
            .frame(width: lineWidth - 1, height: lineWidth - 1)
            .offset(x: cos(finalAngle.radians) * radius, y: sin(finalAngle.radians) * radius)
            .shadow(color: Color.black, radius: 10, x: 0, y: 0)
            .opacity(showShadowDot ? 1.0 : 0.0)
            
        Circle()
            .trim(from: 0, to: min(currentOverlap, 1.0))
            .stroke(ringGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), title: "Doações", description: "Irmão Sangue Bom", currentValue: 150, targetValue: 100, targetDate: nil, createdAt: Date()))
            
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), title: "Mensalidades", description: "Arrecadação mensal", currentValue: 999, targetValue: 2000, targetDate: nil, createdAt: Date()))
            
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), title: "Novos Membros", description: "Campanha 2026", currentValue: 79, targetValue: 100, targetDate: nil, createdAt: Date()))
            
            ProgressRingCard(goal: Goal(id: UUID(), chapterId: UUID(), title: "Doações", description: "Campanha do agasalho", currentValue: 1999, targetValue: 2000, targetDate: nil, createdAt: Date()))
        }
        .padding()
    }
    .background(Color(UIColor.systemBackground))
    .preferredColorScheme(.dark)
}
