//
//  BasicToAdvancedMapping.swift
//  mindsherpa
//
//  Created by Claude on 9/6/25.
//

import Foundation

// MARK: - Step 1: Basic mapping structure with 2-3 test mappings
struct BasicToAdvancedMapping {
    
    // Complete mapping dictionary - all 18 video modules across 5 courses
    static let videoToAdvancedMapping: [String: String] = [
        // Course 1 - EV Safety Pyramid (7 modules)
        "1-1": "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns",
        "1-2": "XOvqV82WjeJnJiu4josaw9JL2k4Rq1hdV3SQA4Sg678",
        "1-3": "bI2WjGdUUWzHJ7w00Gv3aRf7OHz1vn46RDGdgp5YvVcU",
        "1-4": "8mRfAgwaHusffNx5gObTyztZz9vtOIUY9umBArsTaic",
        "1-5": "NCCNveUpYpRKBkTDINDNksgsooofohQr7q9McFS7DpY",
        "1-6": "AxKaucprgU200mmFTGLNIRlpSkaA02FMZwFmmZ1rmaUrE",
        "1-7": "fYYHPmsdI1iYZYBZfOhuUkQgD8RDsfm2tHSScOUIYAw",
        
        // Course 2 - High Voltage Hazards (4 modules)
        "2-1": "KGnXNWj2cE7FE8usEaoA2ROnqGQAMqZq021Xykgski2k",
        "2-2": "UPHJQd9u5KDcadeIUwbeRk2q700ZVxJlhJ4UpA1e37aU",
        "2-3": "f7bWarA02aIjBloGalrhHuSXRGGEEtpwvJ3nLnjAtxV4",
        "2-4": "k7feJpMDdL6CJc1GeCS2MHRR9B1h2Yotr02Kypy2bupg",
        
        // Course 3 - Navigating Electrical Shock Protection (2 modules)
        "3-1": "noM3WWJr6Q43t6eGJ6JJ5VUzNnSv2IW3UcNs2601b02is",
        "3-2": "WMQlHCyi1zrF018XtLXycNXHqTMnvVxV70001tMSXOS02J4",
        
        // Course 4 - High Voltage PPE (2 modules)
        "4-1": "cZ5rxX2013jHbgsxIBDKEHtdJyB4aTYNkLG5hB4GWmm4",
        "4-2": "zfSZVFnzqFm02QkqkNw301mhZtC700qvgd5IH6srTBmtJo",
        
        // Course 5 - Inside an Electric Car (3 modules)
        "5-1": "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
        "5-2": "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8",
        "5-3": "5UtPR00oJZQUAJrnv701jdM7S02zmkCBWYI02lGqMiwbAn4"
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
        print("  Total mappings: \(videoToAdvancedMapping.count)")
        
        // Test by course
        let courseGroups = Dictionary(grouping: videoToAdvancedMapping.keys) { String($0.prefix(1)) }
        for courseNum in courseGroups.keys.sorted() {
            let moduleCount = courseGroups[courseNum]?.count ?? 0
            print("  Course \(courseNum): \(moduleCount) modules")
        }
        
        // Test lookups
        print("🔍 Testing lookups:")
        print("  1-1 has advanced: \(hasAdvancedContent(for: "1-1"))")
        print("  5-3 has advanced: \(hasAdvancedContent(for: "5-3"))")
        print("  6-1 has advanced: \(hasAdvancedContent(for: "6-1"))")
    }
}