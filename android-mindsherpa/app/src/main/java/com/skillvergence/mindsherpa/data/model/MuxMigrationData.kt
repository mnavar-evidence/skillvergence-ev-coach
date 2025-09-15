package com.skillvergence.mindsherpa.data.model

/**
 * Mux Playback ID Mappings
 * Mirrors iOS MuxMigrationData for consistent video streaming
 */
object MuxMigrationData {

    // Basic Course Video Mappings
    private val basicVideoPlaybackIds = mapOf(
        // Course 1 - High Voltage Safety Foundation
        "1-1" to "MPYRvK9KnXqBafit01UdxV023S011gYphUUavHkJKu96Z8",
        "1-2" to "IrMUCbYqtfxeCMbDChNlqZlwxn9Q02d8nYio6a002MBFI",
        "1-3" to "XfjFq015noepqrJzhqeHTboyxaA5xS70201nWwQddWMsMw",
        "1-4" to "2q7gaVGp01JP00AjW7ZpRZCtJcyCdPlee00ve9lPiEn7XM",
        "1-5" to "gaxBAtwysvUYmy517R01GHEAYMOhWFgFBkNz9V6DPnjQ",
        "1-6" to "2air8l9JELmF5BO7kPkrVTi1ggBwGwpDx01eoVL2ng3k",
        "1-7" to "VUfF2QHi7IxQxZvfV02PqPLjtee1uAS01UmcCLc9U2Hfg",

        // Course 2 - Electrical Fundamentals
        "2-1" to "QusmX4rnjbcR7VeSS2ayv68HfKWWRr4pfhPnDZtuFRk",
        "2-2" to "1dFD00lw01Gq3PRPqwtHSCA01goWEwPQEVDpzFSHbOFGFE",
        "2-3" to "LS8wrghx0067Y3iq5eEGIQby6F6eAK00sDIaKc01G8y01rU",
        "2-4" to "h4gzIGHOnWcgYbxds9NWp1i2mO4vF868zEbaOiWNvqY",

        // Course 3 - EV System Components
        "3-1" to "gaTm8cYuz022rhJIcA7Yslt702ymomEMGI1lbtgqFdE7M",
        "3-2" to "82yTeh3aNElJUpkUx02qkrofHkca2jDTFNiubKwsxSdQ",

        // Course 4 - EV Charging Systems
        "4-1" to "eyxc02bMePOacn01xCfvITF700nhQnryDFPwcOKP9v8dTo",
        "4-2" to "14xiAykKQqGSiLOsjrFotxVe3miIbLk8sAOb02fcbjlo",

        // Course 5 - Advanced EV Systems
        "5-1" to "eEz38K4wDIXb1bdISTtNNrYk1ralX5NJYl48ty2wNXg",
        "5-2" to "PsA7ZUpUbSdG94unGCgQWkwdvT44mF7Z200MFKfG4ofI",
        "5-3" to "lKoO2M8c6H26YQ97GxDWAOp8vE027X2mN019s5kyW5mqA"
    )

    // Advanced Course Video Mappings
    private val advancedVideoPlaybackIds = mapOf(
        // Course 1 Advanced
        "adv_1" to "6nHzce7SgTCbcBD00UoMqPdZqobvlBMyJUqnhvzsvIns",

        // Course 2 Advanced
        "adv_2" to "UPHJQd9u5KDcadeIUwbeRk2q700ZVxJlhJ4UpA1e37aU",

        // Course 3 Advanced
        "adv_3" to "noM3WWJr6Q43t6eGJ6JJ5VUzNnSv2IW3UcNs2601b02is",

        // Course 4 Advanced
        "adv_4" to "cZ5rxX2013jHbgsxIBDKEHtdJyB4aTYNkLG5hB4GWmm4",

        // Course 5 Advanced
        "adv_5_1" to "lJjDsHFQ1J5c9tcfy3Bh6OP00SbOQcWMEJ243Lk102Yyk",
        "adv_5_2" to "00KESDsUll4nd8vc88PV01OpJqH7tKC01kqNAgydDmdbx8",
        "adv_5_3" to "5UtPR00oJZQUAJrnv701jdM7S02zmkCBWYI02lGqMiwbAn4"
    )

    /**
     * Get Mux playback ID for a given video ID
     * @param videoId The video ID to look up
     * @return The Mux playback ID, or null if not found
     */
    fun getMuxPlaybackId(videoId: String): String? {
        return basicVideoPlaybackIds[videoId] ?: advancedVideoPlaybackIds[videoId]
    }

    /**
     * Check if a video has been migrated to Mux
     * @param videoId The video ID to check
     * @return True if the video has a Mux playback ID
     */
    fun isVideoMigrated(videoId: String): Boolean {
        return basicVideoPlaybackIds.containsKey(videoId) || advancedVideoPlaybackIds.containsKey(videoId)
    }

    /**
     * Get migration status
     * @return Triple containing (basic videos, advanced videos, total videos)
     */
    fun getMigrationStatus(): Triple<Int, Int, Int> {
        val basicCount = basicVideoPlaybackIds.size
        val advancedCount = advancedVideoPlaybackIds.size
        val totalCount = basicCount + advancedCount
        return Triple(basicCount, advancedCount, totalCount)
    }

    // Properties for compatibility
    val totalBasicVideos: Int get() = basicVideoPlaybackIds.size
    val totalAdvancedVideos: Int get() = advancedVideoPlaybackIds.size
    val totalVideos: Int get() = totalBasicVideos + totalAdvancedVideos
}