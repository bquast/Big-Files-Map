import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: TreeMapViewModel
    
    var body: some View {
        VStack {
            if viewModel.isScanning {
                ProgressView("Scanning...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentNode = viewModel.currentNode, let children = currentNode.children {
                List(children, id: \.id) { node in
                    HStack {
                        Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundColor(node.isDirectory ? .yellow : .blue)
                        
                        VStack(alignment: .leading) {
                            Text(node.name)
                                .lineLimit(1)
                            Text(node.formattedSize)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Show percentage
                        if let currentNode = viewModel.currentNode, currentNode.size > 0 {
                            Text("\(Int(Double(node.size) / Double(currentNode.size) * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if node.isDirectory && node.children != nil && !node.children!.isEmpty {
                            viewModel.zoomIn(to: node)
                        }
                        viewModel.selectedNode = node
                    }
                    .background(viewModel.selectedNode == node ? Color.blue.opacity(0.2) : Color.clear)
                }
            } else {
                Text("No data available")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
} 