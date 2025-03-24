import SwiftUI

struct TreeMapView: View {
    @ObservedObject var viewModel: TreeMapViewModel
    @State private var hoveredNode: FileNode?
    
    var body: some View {
        ZStack {
            if let currentNode = viewModel.currentNode {
                if viewModel.isScanning {
                    ProgressView("Scanning...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let children = currentNode.children, !children.isEmpty {
                    TreeMapContainerView(
                        nodes: children,
                        parentSize: currentNode.size,
                        selectedNode: $viewModel.selectedNode,
                        hoveredNode: $hoveredNode,
                        onNodeClick: { node in
                            if node.isDirectory, node.children != nil, !node.children!.isEmpty {
                                viewModel.zoomIn(to: node)
                            } else {
                                viewModel.selectedNode = node
                            }
                        }
                    )
                } else {
                    Text("No files in this directory")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if viewModel.error != nil {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(viewModel.error ?? "Unknown error")
                        .padding()
                    Button("Try Again") {
                        Task {
                            await viewModel.startScan()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isScanning {
                ProgressView("Scanning...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("No data available")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct TreeMapContainerView: View {
    let nodes: [FileNode]
    let parentSize: UInt64
    @Binding var selectedNode: FileNode?
    @Binding var hoveredNode: FileNode?
    let onNodeClick: (FileNode) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            TreeMapLayout(
                nodes: nodes,
                parentSize: parentSize,
                size: geometry.size,
                selectedNode: $selectedNode,
                hoveredNode: $hoveredNode,
                onNodeClick: onNodeClick
            )
        }
    }
}

struct TreeMapLayout: View {
    let nodes: [FileNode]
    let parentSize: UInt64
    let size: CGSize
    @Binding var selectedNode: FileNode?
    @Binding var hoveredNode: FileNode?
    let onNodeClick: (FileNode) -> Void
    
    var body: some View {
        let sortedNodes = nodes.sorted { $0.size > $1.size }
        
        let rects = calculateRects(
            for: sortedNodes,
            in: CGRect(origin: .zero, size: size),
            totalSize: parentSize
        )
        
        ZStack {
            ForEach(Array(zip(sortedNodes.indices, sortedNodes)), id: \.0) { index, node in
                if let rect = rects[safe: index] {
                    TreeMapCell(
                        node: node,
                        rect: rect,
                        isSelected: selectedNode == node,
                        isHovered: hoveredNode == node,
                        onHover: { isHovered in
                            hoveredNode = isHovered ? node : nil
                        },
                        onClick: {
                            onNodeClick(node)
                        }
                    )
                }
            }
        }
    }
    
    // Squarified Treemap Algorithm
    private func calculateRects(for nodes: [FileNode], in availableRect: CGRect, totalSize: UInt64) -> [CGRect] {
        var result: [CGRect] = []
        var currentRect = availableRect
        var remainingNodes = nodes
        
        while !remainingNodes.isEmpty {
            // Determine layout direction
            let isWide = currentRect.width >= currentRect.height
            
            // Get next row/column of rectangles
            let (rowNodes, _) = findOptimalRow(  // Use _ to ignore optimizedRatio
                in: remainingNodes,
                for: currentRect,
                isWide: isWide,
                totalSize: totalSize
            )
            
            // Calculate rects for this row/column
            let rowRects = layoutRow(
                nodes: rowNodes,
                in: currentRect,
                isWide: isWide,
                totalSize: totalSize
            )
            
            result.append(contentsOf: rowRects)
            
            // Update remaining nodes
            remainingNodes.removeFirst(rowNodes.count)
            
            // Update the remaining rectangle
            if isWide {
                currentRect = CGRect(
                    x: currentRect.minX,
                    y: currentRect.minY + rowRects[0].height,
                    width: currentRect.width,
                    height: currentRect.height - rowRects[0].height
                )
            } else {
                currentRect = CGRect(
                    x: currentRect.minX + rowRects[0].width,
                    y: currentRect.minY,
                    width: currentRect.width - rowRects[0].width,
                    height: currentRect.height
                )
            }
            
            // If we have an empty or too small rect, break
            if currentRect.width < 1 || currentRect.height < 1 {
                break
            }
        }
        
        return result
    }
    
    private func findOptimalRow(in nodes: [FileNode], for rect: CGRect, isWide: Bool, totalSize: UInt64) -> ([FileNode], CGFloat) {
        // Start with first node
        var bestRatio = CGFloat.infinity
        var bestCount = 1
        
        // Removed unused shorterSide variable
        
        for count in 1...nodes.count {
            let rowNodes = Array(nodes.prefix(count))
            let rowRatio = calculateAspectRatio(
                nodes: rowNodes,
                in: rect,
                isWide: isWide,
                totalSize: totalSize
            )
            
            if rowRatio < bestRatio {
                bestRatio = rowRatio
                bestCount = count
            } else {
                // If ratio starts getting worse, we've found the optimal row
                break
            }
        }
        
        return (Array(nodes.prefix(bestCount)), bestRatio)
    }
    
    private func calculateAspectRatio(nodes: [FileNode], in rect: CGRect, isWide: Bool, totalSize: UInt64) -> CGFloat {
        let totalRowSize = nodes.reduce(UInt64(0)) { $0 + $1.size }
        let shorterSide = isWide ? rect.height : rect.width
        let longSide = isWide ? rect.width : rect.height
        
        // Calculate the width or height of each node
        var maxAspect: CGFloat = 0
        var minAspect: CGFloat = CGFloat.infinity
        
        for node in nodes {
            let nodeRatio = CGFloat(node.size) / CGFloat(totalSize)
            let nodeShorterSide = shorterSide
            let nodeLongerSide = longSide * nodeRatio * CGFloat(totalSize) / CGFloat(totalRowSize)
            
            let aspect = max(nodeShorterSide / nodeLongerSide, nodeLongerSide / nodeShorterSide)
            maxAspect = max(maxAspect, aspect)
            minAspect = min(minAspect, aspect)
        }
        
        return maxAspect
    }
    
    private func layoutRow(nodes: [FileNode], in rect: CGRect, isWide: Bool, totalSize: UInt64) -> [CGRect] {
        var result: [CGRect] = []
        let rowSize = nodes.reduce(UInt64(0)) { $0 + $1.size }  // Using rowSize in calculations below
        
        var currentPosition: CGFloat = isWide ? rect.minX : rect.minY
        
        for node in nodes {
            let ratio = CGFloat(node.size) / CGFloat(totalSize)
            let length = (isWide ? rect.width : rect.height) * ratio * CGFloat(totalSize) / CGFloat(rowSize)
            
            let nodeRect: CGRect
            if isWide {
                nodeRect = CGRect(
                    x: currentPosition,
                    y: rect.minY,
                    width: length,
                    height: rect.height
                )
                currentPosition += length
            } else {
                nodeRect = CGRect(
                    x: rect.minX,
                    y: currentPosition,
                    width: rect.width,
                    height: length
                )
                currentPosition += length
            }
            
            result.append(nodeRect)
        }
        
        return result
    }
}

struct TreeMapCell: View {
    let node: FileNode
    let rect: CGRect
    let isSelected: Bool
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onClick: () -> Void
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(cellColor)
                .border(isSelected ? Color.white : Color.black, width: isSelected ? 2 : 0.5)
                .brightness(isHovered ? 0.1 : 0)
            
            if rect.width > 40 && rect.height > 20 {
                Text(node.name)
                    .font(.system(size: min(12, rect.width / 10)))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(4)
                    .foregroundColor(.white)
            }
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .onHover(perform: onHover)
        .onTapGesture(perform: onClick)
    }
    
    private var cellColor: Color {
        if node.isDirectory {
            // Generate a color based on the hash of the node's name
            let hue = abs(CGFloat(node.name.hashValue % 10) / 10)
            return Color(hue: hue, saturation: 0.7, brightness: 0.7)
        } else {
            // Files get a different color
            return Color.blue.opacity(0.6)
        }
    }
}

// Helper extension for safely accessing array indices
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 