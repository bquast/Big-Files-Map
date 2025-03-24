import SwiftUI

struct MetadataView: View {
    @ObservedObject var viewModel: TreeMapViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let node = viewModel.selectedNode {
                Group {
                    HStack {
                        Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundColor(node.isDirectory ? .yellow : .blue)
                        
                        Text(node.name)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    
                    Divider()
                    
                    MetadataRow(label: "Path", value: node.path.path)
                        .lineLimit(2)
                    
                    MetadataRow(label: "Size", value: node.formattedSize)
                    
                    if let date = node.modificationDate {
                        MetadataRow(label: "Modified", value: dateFormatter.string(from: date))
                    }
                    
                    if node.isDirectory, let children = node.children {
                        MetadataRow(label: "Items", value: "\(children.count)")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        Task {
                            _ = await viewModel.moveToTrash(node: node)
                        }
                    }) {
                        Label("Move to Trash", systemImage: "trash")
                    }
                    .disabled(node.path == FileManager.default.homeDirectoryForCurrentUser)
                }
                .padding(.horizontal)
            } else {
                Text("No item selected")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(height: 200)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// Simple metadata row component instead of LabeledContent
struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
} 