import SwiftUI

struct EventCard: View {
    let event: HyroxEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image avec overlay
            ZStack(alignment: .topLeading) {
                 Image(event.imageName)
                     .resizable()
                     .scaledToFill()
                     .frame(height: 150)
                     .clipped()
                
                // Badge location
                Text(event.locationCode)
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(4)
                    .padding(12)
            }
            
            // Infos
            VStack(alignment: .leading, spacing: 8) {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(event.dateRange)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Bouton inscription
                if let url = event.registrationURL {
                    Link(destination: url) {
                        Text("S'INSCRIRE")
                            .font(.caption.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.yellow)
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}
