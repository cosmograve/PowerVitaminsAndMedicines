import SwiftUI

struct AppNavBar: View {

    let title: String
    let showsBack: Bool
    let onBackTap: (() -> Void)?

    private let barHeight: CGFloat = 56
    private let tapArea: CGFloat = 44
    private let sidePadding: CGFloat = AppLayout.sidePadding
    private let iconSize: CGFloat = 36

    var body: some View {
        ZStack {
            AppColors.background

            if showsBack {
                HStack {
                    Button { onBackTap?() } label: {
                        Image(.navBack)
                            .resizable()
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                            .foregroundColor(AppColors.yellow)
                            .frame(width: tapArea, height: tapArea)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")

                    Spacer()

                    Text(title)
                        .font(AppFont.poppins(size: 24, weight: .semibold))
                        .foregroundColor(AppColors.yellow)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, sidePadding)
            } else {
                // Only title centered
                Text(title)
                    .font(AppFont.poppins(size: 24, weight: .semibold))
                    .foregroundColor(AppColors.yellow)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, sidePadding)
            }
        }
        .frame(height: barHeight)
        .frame(maxWidth: .infinity)
    }
}

#Preview() {
    AddEditMedicationView(mode: .create)
        .environmentObject(AppStore())
}
