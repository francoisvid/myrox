import Foundation

extension Date {
    // "Aujourd'hui", "Hier", "Lundi 12"
    var relativeFormatted: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(self) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(self) {
            return "Hier"
        } else if let daysAgo = calendar.dateComponents([.day], from: self, to: Date()).day, daysAgo < 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            formatter.dateFormat = "EEEE d MMMM"
            return formatter.string(from: self)
        }
    }
    
    // "12:34"
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    // "12 janvier 2024"
    var fullFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
