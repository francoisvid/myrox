import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
            
            Text(value)
                .font(.headline)
                .foregroundColor(Color(.label))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}
