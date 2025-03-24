//
//  ContentView.swift
//  Big Files Map
//
//  Created by Bastiaan Quast on 3/24/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: TreeMapViewModel
    
    init() {
        // Initialize the ViewModel with the ModelContext
        // We use temporary context to pass it to the ViewModel during initialization
        let tempContext = ModelContext(try! ModelContainer(for: ScanRecord.self, UserPreference.self))
        _viewModel = StateObject(wrappedValue: TreeMapViewModel(modelContext: tempContext))
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
                .toolbar {
                    ToolbarItem {
                        Button(action: {
                            Task {
                                await viewModel.startScan()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(viewModel.isScanning)
                    }
                }
        } detail: {
            VStack(spacing: 0) {
                HStack {
                    if !viewModel.navigationPath.isEmpty || viewModel.currentNode != viewModel.rootNode {
                        Button(action: {
                            viewModel.zoomOut()
                        }) {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .disabled(viewModel.navigationPath.isEmpty)
                        
                        Button(action: {
                            viewModel.resetToRoot()
                        }) {
                            Label("Home", systemImage: "house")
                        }
                        .disabled(viewModel.currentNode == viewModel.rootNode)
                    }
                    
                    Spacer()
                    
                    if let currentNode = viewModel.currentNode {
                        Text(currentNode.path.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    if viewModel.isScanning {
                        ProgressView()
                            .scaleEffect(0.5)
                            .padding(.trailing)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                
                TreeMapView(viewModel: viewModel)
                
                MetadataView(viewModel: viewModel)
                    .background(Color.secondary.opacity(0.05))
            }
        }
        .onAppear {
            // Update the modelContext with the one from the environment
            viewModel.updateModelContext(modelContext)
            
            // Start scanning on appear
            Task {
                await viewModel.startScan()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ScanRecord.self, UserPreference.self], inMemory: true)
}
