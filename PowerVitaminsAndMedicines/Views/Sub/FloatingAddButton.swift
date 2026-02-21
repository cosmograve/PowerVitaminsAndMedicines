import SwiftUI

struct FloatingAddButton: View {

    let onTap: () -> Void

    private let size: CGFloat = 62
    private let iconSize: CGFloat = 60

    var body: some View {
        Button(action: onTap) {
            Image(.fabPlus)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}
