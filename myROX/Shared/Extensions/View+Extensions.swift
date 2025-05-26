import SwiftUI

extension View {
    // Card style uniforme
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.gray.opacity(0.15))
            //.background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
    
    // Animation de pression
    func pressAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// Pour les conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.yellow)
            .cornerRadius(12)
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            //.background(Color(.systemGray5))
            .background(Color.gray.opacity(0.22))
            .cornerRadius(12)
    }
}

extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(PrimaryButtonStyle())
    }
    
    func secondaryButtonStyle() -> some View {
        self.modifier(SecondaryButtonStyle())
    }
}

