import SwiftUI

struct OnboardingSlideView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: page.imageSystemName)
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .foregroundColor(Theme.accent)
                .padding(.bottom, Spacing.lg)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.md) {
                Text(page.title)
                    .font(Typography.title1)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text(page.description)
                    .font(Typography.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Spacer()
        }
        .padding(Spacing.screenEdgePadding)
    }
}
