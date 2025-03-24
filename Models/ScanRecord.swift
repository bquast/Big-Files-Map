import Foundation
import SwiftData

@Model
final class ScanRecord {
    var id: UUID
    var timestamp: Date
    var totalHomeDirSize: UInt64
    
    init(timestamp: Date, totalHomeDirSize: UInt64) {
        self.id = UUID()
        self.timestamp = timestamp
        self.totalHomeDirSize = totalHomeDirSize
    }
}

@Model
final class UserPreference {
    var id: UUID
    var lastViewedFolderPath: String?
    
    init(lastViewedFolderPath: String? = nil) {
        self.id = UUID()
        self.lastViewedFolderPath = lastViewedFolderPath
    }
} 