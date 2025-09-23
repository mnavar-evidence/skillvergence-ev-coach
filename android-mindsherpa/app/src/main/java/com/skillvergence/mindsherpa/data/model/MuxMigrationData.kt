package com.skillvergence.mindsherpa.data.model

/**
 * Mux Playback ID Mappings
 * Mirrors iOS MuxMigrationData for consistent video streaming
 */
object MuxMigrationData {

    // Basic Course Video Mappings - UPDATED WITH NEW MUX PLAYBACK IDS
    private val basicVideoPlaybackIds = mapOf(
        // Course 1 - High Voltage Safety Foundation
        "1-1" to "Tkk1BFdFi1hlKZSMqosuhoNExgghDyqv5rBMup02bSes",
        "1-2" to "zTOywHrdACjLFt35Qv802wk8BN8m8gV7C01flvbPQrOCw",
        "1-3" to "ng2Lphh1xBIphzI2CQ5M7g1Qbg34ZhbP3Cqqn49srug",
        "1-4" to "hTtD008sNmMbyP00QYvJFEuAXCHZK8yZKru01o02UNQSSSg",
        "1-5" to "JXcV75OWRVKHtfj021f023vzwQfzlap72PiBBlR3uXj3c",
        "1-6" to "vF4SD1tvGyldj2OegjU02uUJQrJN61Xom9q5hPdyATtA",
        "1-7" to "nGTcPZf7kKNws7E5ScALwqsZGeasrtv6mG5rWVmWFFg",

        // Course 2 - Electrical Fundamentals
        "2-1" to "pV3dep004GN1zEAIFT4qIooD6mMRjdn66ynvQigDQofM",
        "2-2" to "Menv901GUUnCrBloH3DDZUYnBaZk02r02Bee3weEpsSN6w",
        "2-3" to "LS8wrghx0067Y3iq5eEGIQby6F6eAK00sDIaKc01G8y01rU", // KEEP OLD - NOT PROVIDED
        "2-4" to "h4gzIGHOnWcgYbxds9NWp1i2mO4vF868zEbaOiWNvqY", // KEEP OLD - NOT PROVIDED

        // Course 3 - EV System Components
        "3-1" to "bgZgCTexV2XPDVDx4QkVZ4J01J7Wmd201TiWk02ARcrARA",
        "3-2" to "brv6fRh2X1oGHhKrOGZ2fHSxNAGMkb9gblLm5D0292004",

        // Course 4 - EV Charging Systems
        "4-1" to "fitlrB5AwgmQTZisHZ9XXwBkK00Uz1QAJCdSF4LNpcko",
        "4-2" to "Ep1iWbH5PcGwrX9a6WSyMuOofSnmeZcjCjYP5vbWhnA",

        // Course 5 - Advanced EV Systems
        "5-1" to "kM1To00cnB8up4CYm01IxH02m93Rg6mm5gNJiKqGy5s1a8",
        "5-2" to "h2doMoMMh5YcMJj79QX1LTzoxxcSEnvBWD7xH00f5JJA",
        "5-3" to "fjsvFA01kKjP9100EKhNFfMllpQsaPilkUiopwbSe5QrM"
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