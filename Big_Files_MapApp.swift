//
//  Big_Files_MapApp.swift
//  Big Files Map
//
//  Created by Bastiaan Quast on 3/24/25.
//

import SwiftUI
import SwiftData

@main
struct Big_Files_MapApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ScanRecord.self,
            UserPreference.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .modelContainer(sharedModelContainer)
    }
}
