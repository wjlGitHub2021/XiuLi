import SwiftUI

struct DLPrimaryButton<Label: View>: View {
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    label()
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
        .disabled(isDisabled || isLoading)
    }
}
