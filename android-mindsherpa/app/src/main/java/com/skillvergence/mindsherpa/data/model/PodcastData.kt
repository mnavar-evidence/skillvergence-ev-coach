package com.skillvergence.mindsherpa.data.model

/**
 * Complete podcast dataset matching iOS implementation
 * Contains all 19 podcast episodes across 5 courses
 */
object PodcastData {

    /**
     * All podcast episodes organized by course
     */
    fun getAllPodcasts(): List<Podcast> = listOf(
        // Course 1: High Voltage Safety Foundation (4 episodes)
        Podcast(
            id = "podcast-1-1",
            title = "High Voltage Safety Fundamentals",
            description = "Essential safety protocols and risk assessment for working with high voltage EV systems",
            duration = 1680, // 28 minutes
            audioUrl = "mux://i4QEDflyN1yzdnioCjcVDiNZeTOQbLjwsmkm00bjlsBo",
            sequenceOrder = 1,
            courseId = "1",
            episodeNumber = 1,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/hv-safety-fundamentals.jpg"
        ),
        Podcast(
            id = "podcast-1-2",
            title = "Personal Protective Equipment for EV Technicians",
            description = "Complete guide to PPE selection, usage, and maintenance for high voltage work",
            duration = 1440, // 24 minutes
            audioUrl = "mux://oXa02RGavP5mdWedJ279l4g02z01gkioUAM9mQEdxAsq9g",
            sequenceOrder = 2,
            courseId = "1",
            episodeNumber = 2,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-ppe-guide.jpg"
        ),
        Podcast(
            id = "podcast-1-3",
            title = "Lockout/Tagout Procedures for EVs",
            description = "Step-by-step LOTO procedures specific to electric vehicle maintenance and repair",
            duration = 1320, // 22 minutes
            audioUrl = "mux://LN73nvqZArkimShNSSuIuROSuJmOjTZYcvy02bGxhz02U",
            sequenceOrder = 3,
            courseId = "1",
            episodeNumber = 3,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-loto-procedures.jpg"
        ),
        Podcast(
            id = "podcast-1-4",
            title = "Emergency Response for EV Incidents",
            description = "Critical emergency procedures for high voltage incidents and fire safety protocols",
            duration = 1560, // 26 minutes
            audioUrl = "mux://QbrH2jxPRfrWncstf4VDsqwQ01017KGu1BDJ02x8ePixOg",
            sequenceOrder = 4,
            courseId = "1",
            episodeNumber = 4,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-emergency-response.jpg"
        ),

        // Course 2: Electrical Fundamentals (4 episodes)
        Podcast(
            id = "podcast-2-1",
            title = "From Spark Plugs to Silent Power: EV Evolution",
            description = "Explore the evolution from traditional combustion engines to electric powertrains",
            duration = 1650, // 27.5 minutes
            audioUrl = "mux://LyloSfhndkLxpz024h1Fu6rBVRJupQmTODYh55cMm3gs",
            sequenceOrder = 1,
            courseId = "2",
            episodeNumber = 1,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/spark-plugs-episode.jpg"
        ),
        Podcast(
            id = "podcast-2-2",
            title = "DC vs AC: Understanding EV Power Systems",
            description = "Deep dive into direct current vs alternating current in electric vehicle applications",
            duration = 1380, // 23 minutes
            audioUrl = "mux://7xaPgCXLyOeJEU801PxiOKRaC00YT4iAi7K2ade400bRJc",
            sequenceOrder = 2,
            courseId = "2",
            episodeNumber = 2,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/dc-vs-ac-power.jpg"
        ),
        Podcast(
            id = "podcast-2-3",
            title = "Ohm's Law in Electric Vehicle Circuits",
            description = "Practical applications of electrical fundamentals in EV system diagnostics",
            duration = 1260, // 21 minutes
            audioUrl = "mux://wi6uJiUJtKLLrmr01KG52G7HSnUz4fSM446r00DZMyz14",
            sequenceOrder = 3,
            courseId = "2",
            episodeNumber = 3,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ohms-law-ev.jpg"
        ),
        Podcast(
            id = "podcast-2-4",
            title = "Electrifying the Road: EV Motor Physics",
            description = "Understanding electric motor physics, power delivery, and efficiency principles",
            duration = 1800, // 30 minutes
            audioUrl = "mux://yywkj01kgEEY02M7L00PuybVyQcvDTEagEtH86kenvqt8w",
            sequenceOrder = 4,
            courseId = "2",
            episodeNumber = 4,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-motors-episode.jpg"
        ),

        // Course 3: EV System Components (3 episodes)
        Podcast(
            id = "podcast-3-1",
            title = "EV Powertrain Architecture Deep Dive",
            description = "Comprehensive overview of electric vehicle powertrain components and integration",
            duration = 1620, // 27 minutes
            audioUrl = "mux://gJw7gTkf4xwNAzY6zMp00EKTi200UcRaLMu7UF01802AwmI",
            sequenceOrder = 1,
            courseId = "3",
            episodeNumber = 1,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-powertrain-architecture.jpg"
        ),
        Podcast(
            id = "podcast-3-2",
            title = "Inverters and Power Electronics",
            description = "Understanding DC-AC conversion, motor controllers, and power management systems",
            duration = 1500, // 25 minutes
            audioUrl = "mux://LEp1g5FWhZF1d7HcAFKYfBMLt82abDCFxqNh6TNNibg",
            sequenceOrder = 2,
            courseId = "3",
            episodeNumber = 2,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/inverters-power-electronics.jpg"
        ),
        Podcast(
            id = "podcast-3-3",
            title = "Regenerative Braking Systems",
            description = "How EVs capture kinetic energy and convert it back to electrical power",
            duration = 1200, // 20 minutes
            audioUrl = "mux://rBNRQgJd0002pHnYED57YYThbNjPhndVJDdVks1pIbV00E",
            sequenceOrder = 3,
            courseId = "3",
            episodeNumber = 3,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/regenerative-braking.jpg"
        ),

        // Course 4: EV Charging Systems (4 episodes)
        Podcast(
            id = "podcast-4-1",
            title = "Demystifying EV Batteries: Chemistry to Performance",
            description = "From lead-acid to lithium-ion, understanding battery technologies and energy storage",
            duration = 1920, // 32 minutes
            audioUrl = "mux://4hS0142g7wTaRPJZt7rj01BvK8j45wNGhYMhMfu9CynX4",
            sequenceOrder = 1,
            courseId = "4",
            episodeNumber = 1,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/ev-batteries-chemistry.jpg"
        ),
        Podcast(
            id = "podcast-4-2",
            title = "Charging Standards and Protocols",
            description = "Understanding Level 1, 2, and DC fast charging standards and communication protocols",
            duration = 1740, // 29 minutes
            audioUrl = "mux://zKO2aEoOlkL59Y00EiPZNq3TUUeJ6XFb4XG004XBQoHD00",
            sequenceOrder = 2,
            courseId = "4",
            episodeNumber = 2,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/charging-standards.jpg"
        ),
        Podcast(
            id = "podcast-4-3",
            title = "Battery Management Systems Explained",
            description = "How BMS monitors, protects, and optimizes battery performance and longevity",
            duration = 1440, // 24 minutes
            audioUrl = "mux://hDJ1ctkmzHpafohwPdSyWoO019OYjhUdVwuvhrKQEf014",
            sequenceOrder = 3,
            courseId = "4",
            episodeNumber = 3,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/battery-management-systems.jpg"
        ),
        Podcast(
            id = "podcast-4-4",
            title = "Thermal Management in EV Charging",
            description = "Heat generation, cooling systems, and thermal challenges in high-power charging",
            duration = 1320, // 22 minutes
            audioUrl = "mux://ox8w3uqDkMICb5KToyQE8XbhpVor7XP7wOZqrCMlKhU",
            sequenceOrder = 4,
            courseId = "4",
            episodeNumber = 4,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/thermal-management-charging.jpg"
        ),

        // Course 5: Advanced EV Systems (3 episodes)
        Podcast(
            id = "podcast-5-1",
            title = "Vehicle-to-Grid Technology",
            description = "How EVs can feed power back to the electrical grid and smart energy management",
            duration = 1680, // 28 minutes
            audioUrl = "mux://lnY6lcvRpV1eQxXIWQ9CS3L6sE53WppNh4SdpLa98nI",
            sequenceOrder = 1,
            courseId = "5",
            episodeNumber = 1,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/vehicle-to-grid.jpg"
        ),
        Podcast(
            id = "podcast-5-2",
            title = "Autonomous Driving and EV Integration",
            description = "The intersection of self-driving technology and electric vehicle systems",
            duration = 1560, // 26 minutes
            audioUrl = "mux://di1HuLrR5qSCxCVTkf01WbIvCKIJODqP9l4IV1MeilRA",
            sequenceOrder = 2,
            courseId = "5",
            episodeNumber = 2,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/autonomous-driving-ev.jpg"
        ),
        Podcast(
            id = "podcast-5-3",
            title = "The Future of Electric Transportation",
            description = "Emerging technologies, solid-state batteries, and the next generation of EVs",
            duration = 1800, // 30 minutes
            audioUrl = "mux://Pecxte8db863F3TdikLFCf3QEFnol4ODTq4LJBY013pA",
            sequenceOrder = 3,
            courseId = "5",
            episodeNumber = 3,
            thumbnailUrl = "https://skillvergence.mindsherpa.ai/assets/podcasts/thumbnails/future-electric-transportation.jpg"
        )
    )

    /**
     * Get podcasts for a specific course
     */
    fun getPodcastsByCourse(courseId: String): List<Podcast> {
        val normalizedCourseId = normalizeCourseId(courseId)
        return getAllPodcasts().filter {
            it.courseId == normalizedCourseId
        }.sortedBy { it.sequenceOrder }
    }

    /**
     * Get a specific podcast by ID
     */
    fun getPodcastById(id: String): Podcast? {
        return getAllPodcasts().find { it.id == id }
    }

    /**
     * Get total podcast count
     */
    fun getTotalPodcastCount(): Int = getAllPodcasts().size

    /**
     * Get podcast count by course
     */
    fun getPodcastCountByCourse(courseId: String): Int {
        return getPodcastsByCourse(courseId).size
    }

    /**
     * Get total duration for all podcasts (in seconds)
     */
    fun getTotalDuration(): Int {
        return getAllPodcasts().sumOf { it.duration }
    }

    /**
     * Get total duration for a specific course (in seconds)
     */
    fun getTotalDurationByCourse(courseId: String): Int {
        return getPodcastsByCourse(courseId).sumOf { it.duration }
    }

    /**
     * Normalize course ID to handle both "course-1" and "1" formats
     */
    private fun normalizeCourseId(courseId: String): String {
        return when {
            courseId.startsWith("course-") -> courseId.substringAfter("course-")
            else -> courseId
        }
    }

    /**
     * Get course title by course ID
     */
    fun getCourseTitle(courseId: String): String {
        val normalizedId = normalizeCourseId(courseId)
        return when (normalizedId) {
            "1" -> "High Voltage Safety Foundation"
            "2" -> "Electrical Fundamentals"
            "3" -> "EV System Components"
            "4" -> "EV Charging Systems"
            "5" -> "Advanced EV Systems"
            else -> "Unknown Course"
        }
    }

    /**
     * Get all unique course IDs
     */
    fun getAllCourseIds(): List<String> {
        return getAllPodcasts().mapNotNull { it.courseId }.distinct().sorted()
    }

    /**
     * Get podcasts grouped by course
     */
    fun getPodcastsGroupedByCourse(): Map<String, List<Podcast>> {
        return getAllPodcasts()
            .filter { it.courseId != null }
            .groupBy { it.courseId!! }
            .mapValues { (_, podcasts) ->
                podcasts.sortedBy { it.sequenceOrder }
            }
    }
}