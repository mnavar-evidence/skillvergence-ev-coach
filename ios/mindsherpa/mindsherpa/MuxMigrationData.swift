//
//  MuxMigrationData.swift
//  mindsherpa
//
//  Created by Claude on 9/5/25.
//

import Foundation

// MARK: - Mux Playback ID Mappings

struct MuxMigrationData {
    
    // MARK: - Basic Course Video Mappings
    static let basicVideoPlaybackIds: [String: String] = [
        // Course 1 - High Voltage Safety Foundation
        "1-1": "MPYRvK9KnXqBafit01UdxV023S011gYphUUavHkJKu96Z8",
        "1-2": "IrMUCbYqtfxeCMbDChNlqZlwxn9Q02d8nYio6a002MBFI",
        "1-3": "XfjFq015noepqrJzhqeHTboyxaA5xS70201nWwQddWMsMw",
        "1-4": "2q7gaVGp01JP00AjW7ZpRZCtJcyCdPlee00ve9lPiEn7XM",
        "1-5": "gaxBAtwysvUYmy517R01GHEAYMOhWFgFBkNz9V6DPnjQ",
        "1-6": "2air8l9JELmF5BO7kPkrVTi1ggBwGwpDx01eoVL2ng3k",
        "1-7": "VUfF2QHi7IxQxZvfV02PqPLjtee1uAS01UmcCLc9U2Hfg",
        
        // Course 2 - Electrical Fundamentals
        "2-1": "QusmX4rnjbcR7VeSS2ayv68HfKWWRr4pfhPnDZtuFRk",
        "2-2": "1dFD00lw01Gq3PRPqwtHSCA01goWEwPQEVDpzFSHbOFGFE",
        "2-3": "LS8wrghx0067Y3iq5eEGIQby6F6eAK00sDIaKc01G8y01rU",
        "2-4": "h4gzIGHOnWcgYbxds9NWp1i2mO4vF868zEbaOiWNvqY",
        
        // Course 3 - EV Charging Systems
        "3-1": "gaTm8cYuz022rhJIcA7Yslt702ymomEMGI1lbtgqFdE7M",
        "3-2": "82yTeh3aNElJUpkUx02qkrofHkca2jDTFNiubKwsxSdQ",
        
        // Course 4 - Advanced Electrical Diagnostics
        "4-1": "eyxc02bMePOacn01xCfvITF700nhQnryDFPwcOKP9v8dTo",
        "4-2": "14xiAykKQqGSiLOsjrFotxVe3miIbLk8sAOb02fcbjlo",
        
        // Course 5 - Advanced EV Systems
        "5-1": "eEz38K4wDIXb1bdISTtNNrYk1ralX5NJYl48ty2wNXg",
        "5-2": "PsA7ZUpUbSdG94unGCgQWkwdvT44mF7Z200MFKfG4ofI",
        "5-3": "lKoO2M8c6H26YQ97GxDWAOp8vE027X2mN019s5kyW5mqA"
    ]
    
    // MARK: - Advanced Course Video Mappings
    static let advancedVideoPlaybackIds: [String: String] = [
        // Course 1 Advanced
        "adv_1": "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns",
        
        // Course 2 Advanced  
        "adv_2": "UPHJQd9u5KDcadeIUwbeRk2q700ZVxJlhJ4UpA1e37aU",
        
        // Course 3 Advanced
        "adv_3": "noM3WWJr6Q43t6eGJ6JJ5VUzNnSv2IW3UcNs2601b02is",
        
        // Course 4 Advanced
        "adv_4": "cZ5rxX2013jHbgsxIBDKEHtdJyB4aTYNkLG5hB4GWmm4",
        
        // Course 5 Advanced (already in AdvancedCourse.swift)
        "adv_5_1": "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
        "adv_5_2": "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8", 
        "adv_5_3": "5UtPR00oJZQUAJrnv701jdM7S02zmkCBWYI02lGqMiwbAn4"
    ]
    
    // MARK: - Helper Methods
    
    static func getMuxPlaybackId(for videoId: String) -> String? {
        return basicVideoPlaybackIds[videoId] ?? advancedVideoPlaybackIds[videoId]
    }
    
    static func isVideoMigrated(videoId: String) -> Bool {
        return basicVideoPlaybackIds[videoId] != nil || advancedVideoPlaybackIds[videoId] != nil
    }
    
    // MARK: - Migration Status
    
    static var totalBasicVideos: Int { basicVideoPlaybackIds.count }
    static var totalAdvancedVideos: Int { advancedVideoPlaybackIds.count }
    static var totalVideos: Int { totalBasicVideos + totalAdvancedVideos }
    
    static func migrationStatus() -> (basic: Int, advanced: Int, total: Int) {
        return (basic: totalBasicVideos, advanced: totalAdvancedVideos, total: totalVideos)
    }
}