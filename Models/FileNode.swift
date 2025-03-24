import Foundation

struct FileNode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: URL
    let size: UInt64
    let modificationDate: Date?
    let isDirectory: Bool
    var children: [FileNode]?
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
    
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        return lhs.path == rhs.path
    }
} 