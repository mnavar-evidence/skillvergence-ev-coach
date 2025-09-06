//
//  BasicToAdvancedMapping.swift
//  mindsherpa
//
//  Created by Claude on 9/6/25.
//

import Foundation

// MARK: - Step 1: Basic mapping structure with 2-3 test mappings
struct BasicToAdvancedMapping {
    
    // Simple mapping dictionary - starting with just 3 test cases
    static let videoToAdvancedMapping: [String: String] = [
        "1-1": "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns",
        "1-2": "XOvqV82WjeJnJiu4josaw9JL2k4Rq1hdV3SQA4Sg678",
        "2-1": "KGnXNWj2cE7FE8usEaoA2ROnqGQAMqZq021Xykgski2k"
    ]
    
    // Basic lookup function
    static func getAdvancedMuxId(for basicVideoId: String) -> String? {
        return videoToAdvancedMapping[basicVideoId]
    }
    
    // Simple availability check
    static func hasAdvancedContent(for basicVideoId: String) -> Bool {
        return videoToAdvancedMapping[basicVideoId] != nil
    }
    
    // Debug helper to test the mapping
    static func testMapping() {
        print("🧪 Testing Basic → Advanced Mapping:")
        for (basicId, advancedId) in videoToAdvancedMapping {
            print("  \(basicId) → \(advancedId.prefix(8))...")
        }
        
        // Test lookup
        print("🔍 Testing lookups:")
        print("  1-1 has advanced: \(hasAdvancedContent(for: "1-1"))")
        print("  1-3 has advanced: \(hasAdvancedContent(for: "1-3"))")
        print("  2-1 advanced ID: \(getAdvancedMuxId(for: "2-1") ?? "none")")
    }
}