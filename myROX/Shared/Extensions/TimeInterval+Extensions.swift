import Foundation

extension TimeInterval {
    // Format: "12:34" ou "1:23:45"
    var formatted: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    // Format : "01:11:12
    var formattedWithMilliseconds: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let centiseconds = Int((self.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%02d:%02d:%02d", minutes, seconds, centiseconds)
        } else {
            return String(format: "%d.%02d", seconds, centiseconds)
        }
    }
    
    // Format court: "12m 34s"
    var shortFormatted: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// Pour faciliter la création
extension TimeInterval {
    static func from(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) -> TimeInterval {
        return TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
}
