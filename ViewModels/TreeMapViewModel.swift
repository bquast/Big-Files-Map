import Foundation
import SwiftUI
import SwiftData

@MainActor
class TreeMapViewModel: ObservableObject {
    @Published var rootNode: FileNode?
    @Published var currentNode: FileNode?
    @Published var isScanning: Bool = false
    @Published var error: String?
    @Published var selectedNode: FileNode?
    @Published var navigationPath: [FileNode] = []
    
    private let scanner = FileScanner()
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLastViewedPath()
    }
    
    func startScan() async {
        isScanning = true
        error = nil
        
        do {
            let homeNode = try await scanner.scanHomeDirectory()
            rootNode = homeNode
            
            // If we have a last viewed path, navigate to it
            if let lastPath = await retrieveLastPath(), let rootNode = rootNode {
                navigateToSavedPath(lastPath, from: rootNode)
            } else {
                currentNode = homeNode
            }
            
            // Save scan record
            saveScanRecord(size: homeNode.size)
            
        } catch {
            self.error = "Failed to scan: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
    
    private func saveScanRecord(size: UInt64) {
        let record = ScanRecord(timestamp: Date(), totalHomeDirSize: size)
        modelContext.insert(record)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save scan record: \(error)")
        }
    }
    
    func zoomIn(to node: FileNode) {
        if let currentNode = currentNode {
            navigationPath.append(currentNode)
        }
        currentNode = node
        saveLastViewedPath(node.path.path)
    }
    
    func zoomOut() {
        guard !navigationPath.isEmpty else { return }
        currentNode = navigationPath.removeLast()
        if let currentNode = currentNode {
            saveLastViewedPath(currentNode.path.path)
        }
    }
    
    func resetToRoot() {
        currentNode = rootNode
        navigationPath = []
        if let rootNode = rootNode {
            saveLastViewedPath(rootNode.path.path)
        }
    }
    
    func moveToTrash(node: FileNode) async -> Bool {
        guard node.path != FileManager.default.homeDirectoryForCurrentUser else {
            return false // Don't allow deleting home directory
        }
        
        do {
            var resultingItemURL: NSURL?
            try FileManager.default.trashItem(at: node.path, resultingItemURL: &resultingItemURL)
            
            // Refresh scan to update view
            await startScan()
            return true
        } catch {
            self.error = "Failed to move to trash: \(error.localizedDescription)"
            return false
        }
    }
    
    private func loadLastViewedPath() {
        Task {
            await retrieveLastPath()
        }
    }
    
    private func retrieveLastPath() async -> String? {
        let descriptor = FetchDescriptor<UserPreference>()
        
        do {
            let preferences = try modelContext.fetch(descriptor)
            return preferences.first?.lastViewedFolderPath
        } catch {
            print("Failed to fetch user preferences: \(error)")
            return nil
        }
    }
    
    private func navigateToSavedPath(_ path: String, from node: FileNode) {
        let url = URL(fileURLWithPath: path)
        var pathComponents = url.pathComponents
        
        // Remove the first component if it's "/"
        if pathComponents.first == "/" {
            pathComponents.removeFirst()
        }
        
        var currentNode = node
        navigationPath = []
        
        // Try to navigate through each path component
        for component in pathComponents {
            if let nextNode = currentNode.children?.first(where: { $0.name == component }) {
                navigationPath.append(currentNode)
                currentNode = nextNode
            } else {
                break
            }
        }
        
        self.currentNode = currentNode
    }
    
    private func saveLastViewedPath(_ path: String) {
        // Fetch existing preference or create new
        let descriptor = FetchDescriptor<UserPreference>()
        
        do {
            let preferences = try modelContext.fetch(descriptor)
            
            if let preference = preferences.first {
                preference.lastViewedFolderPath = path
            } else {
                let newPreference = UserPreference(lastViewedFolderPath: path)
                modelContext.insert(newPreference)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to save user preference: \(error)")
        }
    }
    
    func updateModelContext(_ newContext: ModelContext) {
        self.modelContext = newContext
    }
} 