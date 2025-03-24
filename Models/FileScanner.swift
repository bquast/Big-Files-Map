import Foundation

class FileScanner {
    enum ScannerError: Error {
        case accessDenied
        case scanningFailed(String)
    }
    
    private let fileManager = FileManager.default
    
    func scanHomeDirectory() async throws -> FileNode {
        // homeDirectoryForCurrentUser is not optional
        let homeURL = fileManager.homeDirectoryForCurrentUser.standardized
        return try await scanDirectory(at: homeURL)
    }
    
    func scanDirectory(at url: URL) async throws -> FileNode {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            // This is a file, not a directory
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? UInt64 ?? 0
            let modDate = attributes[.modificationDate] as? Date
            
            return FileNode(
                name: url.lastPathComponent,
                path: url,
                size: size,
                modificationDate: modDate,
                isDirectory: false,
                children: nil
            )
        }
        
        // This is a directory, scan its contents
        var children: [FileNode] = []
        var totalSize: UInt64 = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey], options: [.skipsHiddenFiles])
            
            for childURL in contents {
                do {
                    let childNode = try await scanDirectory(at: childURL)
                    children.append(childNode)
                    totalSize += childNode.size
                } catch {
                    // Skip files we can't access
                    print("Skipping \(childURL): \(error.localizedDescription)")
                }
            }
        } catch {
            throw ScannerError.scanningFailed("Failed to scan \(url.path): \(error.localizedDescription)")
        }
        
        // Sort children by size (largest first)
        children.sort { $0.size > $1.size }
        
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let modDate = attributes[.modificationDate] as? Date
        
        return FileNode(
            name: url.lastPathComponent,
            path: url,
            size: totalSize,
            modificationDate: modDate,
            isDirectory: true,
            children: children
        )
    }
} 