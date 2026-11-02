//
//  SeedData.swift
//  NexusVapor
//
//  Migration that inserts test data (anime / manga / video games / sci-fi / cinema theme).
//  Password of every test account: Password123!
//

import Fluent
import Vapor

struct SeedData: AsyncMigration {

    // Categories created by the seed
    private let seedCategoryNames = [
        "Mangas",     // 0
        "Cosplay",    // 1
        "Gaming",     // 2
        "SCI-FI",     // 3
        "Cinema"      // 4
    ]

    private let seedUserEmails = [
        "staff@nexusfestival.com",    // 0
        "alice@nexusfestival.com",    // 1
        "bob@nexusfestival.com",      // 2
        "chloe@nexusfestival.com",    // 3
        "david@nexusfestival.com",    // 4
        "emma@nexusfestival.com",     // 5
        "hugo@nexusfestival.com",     // 6
        "lina@nexusfestival.com"      // 7
    ]

    private let seedWorkshopNames = [
        "Draw your first shonen manga",                // 0  - Mangas
        "Lettering & page layout",                     // 1  - Mangas
        "Build your cosplay armor (EVA foam)",         // 2  - Cosplay
        "Wigs & character makeup",                     // 3  - Cosplay
        "Craft your prop weapon",                      // 4  - Cosplay
        "Speedrunning 101",                            // 5  - Gaming
        "Create your pixel art game",                  // 6  - Gaming
        "Fighting game masterclass",                   // 7  - Gaming
        "Design your alien species",                   // 8  - SCI-FI
        "Worldbuilding: create a space saga",          // 9  - SCI-FI
        "Stunt choreography: fight like a movie hero", // 10 - Cinema
        "Film your own one-minute short",              // 11 - Cinema
        "Anime dubbing: lend your voice",              // 12 - Cinema (2 spots)
        "Star Wars: lightsaber duel academy"           // 13 - SCI-FI (3 spots, full)
    ]

    // Small helper to build a date (Paris time zone)
    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        let components = DateComponents(
            year: year, month: month, day: day,
            hour: hour, minute: minute
        )
        return calendar.date(from: components)!
    }

    func prepare(on database: any Database) async throws {

        // 1. CATEGORIES
        var categories: [Category] = []
        for name in seedCategoryNames {
            let category = Category(name: name)
            try await category.save(on: database)
            categories.append(category)
        }
        let mangas = categories[0]
        let cosplay = categories[1]
        let gaming = categories[2]
        let sciFi = categories[3]
        let cinema = categories[4]

        // 2. USERS (passwords hashed with Bcrypt, like in UserController)
        let hashedPassword = try Bcrypt.hash("Password123!")

        let userData: [(String, Role)] = [
            ("Sensei Staff", .staff),
            ("Alice Martin (Sakura Blade)", .festivalGoer),
            ("Bob Durand (Pixel Ninja)", .festivalGoer),
            ("Chloé Bernard (Neko Gamer)", .festivalGoer),
            ("David Lefevre (Star Pilot)", .festivalGoer),
            ("Emma Rousseau (Cyber Witch)", .festivalGoer),
            ("Hugo Petit (Mecha Boy)", .festivalGoer),
            ("Lina Moreau (Shadow Director)", .festivalGoer)
        ]

        var users: [UserModel] = []
        for (index, data) in userData.enumerated() {
            let user = UserModel(
                name: data.0, password: hashedPassword,
                email: seedUserEmails[index], role: data.1, creationDate: Date()
            )
            try await user.save(on: database)
            users.append(user)
        }

        // 3. WORKSHOPS (totalSubscribers is recomputed below)
        let workshops = [
            // --- Mangas ---
            Workshop(
                name: seedWorkshopNames[0],
                startTime: date(2027, 7, 10, 10), endTime: date(2027, 7, 10, 12),
                capacityMax: 15, totalSubscribers: 0,
                description: "Invent your hero, their design and powers, then draw your first shonen-style manga page.",
                categoryID: try mangas.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[1],
                startTime: date(2027, 7, 10, 14), endTime: date(2027, 7, 10, 16),
                capacityMax: 12, totalSubscribers: 0,
                description: "Learn to lay out a page, place speech bubbles and sound effects like a real mangaka.",
                categoryID: try mangas.requireID()
            ),
            // --- Cosplay ---
            Workshop(
                name: seedWorkshopNames[2],
                startTime: date(2027, 7, 11, 10), endTime: date(2027, 7, 11, 13),
                capacityMax: 10, totalSubscribers: 0,
                description: "Cut, assemble and paint an EVA foam armor inspired by your favorite game or anime character.",
                categoryID: try cosplay.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[3],
                startTime: date(2027, 7, 11, 14), endTime: date(2027, 7, 11, 16),
                capacityMax: 20, totalSubscribers: 0,
                description: "Style an oversized wig and master makeup to look exactly like your character.",
                categoryID: try cosplay.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[4],
                startTime: date(2027, 7, 12, 10), endTime: date(2027, 7, 12, 12, 30),
                capacityMax: 12, totalSubscribers: 0,
                description: "Sculpt, sand and paint a legendary sword or blaster that looks like it came straight out of the screen.",
                categoryID: try cosplay.requireID()
            ),
            // --- Gaming ---
            Workshop(
                name: seedWorkshopNames[5],
                startTime: date(2027, 7, 10, 16, 30), endTime: date(2027, 7, 10, 18),
                capacityMax: 16, totalSubscribers: 0,
                description: "Discover the techniques, glitches and tricks of speedrunners and try your first live run.",
                categoryID: try gaming.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[6],
                startTime: date(2027, 7, 11, 9), endTime: date(2027, 7, 11, 12),
                capacityMax: 8, totalSubscribers: 0,
                description: "Draw your sprites, animate your character and build a playable retro mini-game in one morning.",
                categoryID: try gaming.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[7],
                startTime: date(2027, 7, 12, 14), endTime: date(2027, 7, 12, 17),
                capacityMax: 14, totalSubscribers: 0,
                description: "Master frame data, combos and mind games with a pro player, then enter a friendly mini-tournament.",
                categoryID: try gaming.requireID()
            ),
            // --- SCI-FI ---
            Workshop(
                name: seedWorkshopNames[8],
                startTime: date(2027, 7, 10, 11), endTime: date(2027, 7, 10, 13),
                capacityMax: 18, totalSubscribers: 0,
                description: "Imagine an alien species from another galaxy: anatomy, culture, language and home planet.",
                categoryID: try sciFi.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[9],
                startTime: date(2027, 7, 12, 10), endTime: date(2027, 7, 12, 12),
                capacityMax: 15, totalSubscribers: 0,
                description: "Build the universe of your own space saga: factions, starships, technology and epic conflicts.",
                categoryID: try sciFi.requireID()
            ),
            // --- Cinema ---
            Workshop(
                name: seedWorkshopNames[10],
                startTime: date(2027, 7, 11, 15), endTime: date(2027, 7, 11, 17),
                capacityMax: 10, totalSubscribers: 0,
                description: "Learn to chain fight moves safely and make them look like a real action movie scene.",
                categoryID: try cinema.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[11],
                startTime: date(2027, 7, 12, 9), endTime: date(2027, 7, 12, 12),
                capacityMax: 8, totalSubscribers: 0,
                description: "Write, shoot and edit a one-minute superhero short film with professional equipment.",
                categoryID: try cinema.requireID()
            ),
            // Tiny workshop (2 spots) to test the "Workshop is full." case
            Workshop(
                name: seedWorkshopNames[12],
                startTime: date(2027, 7, 12, 14), endTime: date(2027, 7, 12, 16),
                capacityMax: 2, totalSubscribers: 0,
                description: "Lend your voice to an anime character in front of a mic, just like in a dubbing studio.",
                categoryID: try cinema.requireID()
            ),
            // Star Wars workshop: 3 spots, all taken -> "Workshop is full."
            Workshop(
                name: seedWorkshopNames[13],
                startTime: date(2027, 7, 11, 18), endTime: date(2027, 7, 11, 20),
                capacityMax: 3, totalSubscribers: 0,
                description: "Train like a Jedi: learn lightsaber forms, duel choreography and the way of the Force with a Star Wars stunt coach.",
                categoryID: try sciFi.requireID()
            )
        ]
        for workshop in workshops {
            try await workshop.save(on: database)
        }

        // 4. RESERVATIONS: (user index, workshop index, status)
        // Warning: a user can only book the same workshop once (unique constraint).
        let plan: [(Int, Int, ReservationStatus)] = [
            // Mangas
            (1, 0, .validated),   // Alice -> shonen manga
            (2, 0, .validated),   // Bob   -> shonen manga
            (4, 0, .validated),   // David -> shonen manga
            (4, 1, .validated),   // David -> lettering
            // Cosplay
            (1, 2, .validated),   // Alice -> armor
            (3, 2, .cancelled),   // Chloé -> armor (cancelled)
            (5, 2, .validated),   // Emma  -> armor
            (3, 3, .pending),     // Chloé -> wigs & makeup (pending)
            (6, 3, .validated),   // Hugo  -> wigs & makeup
            (7, 4, .cancelled),   // Lina  -> prop weapon (cancelled)
            // Gaming
            (2, 5, .validated),   // Bob   -> speedrunning
            (7, 5, .validated),   // Lina  -> speedrunning
            (3, 6, .validated),   // Chloé -> pixel art
            (4, 6, .validated),   // David -> pixel art
            (5, 7, .validated),   // Emma  -> fighting game
            (6, 7, .pending),     // Hugo  -> fighting game (pending)
            // SCI-FI
            (1, 8, .validated),   // Alice -> alien species
            (7, 8, .validated),   // Lina  -> alien species
            (2, 9, .validated),   // Bob   -> worldbuilding
            // Cinema
            (4, 10, .validated),  // David -> stunt choreography
            (6, 10, .validated),  // Hugo  -> stunt choreography
            (5, 11, .validated),  // Emma  -> short film
            (1, 12, .validated),  // Alice -> anime dubbing
            (2, 12, .validated),  // Bob   -> anime dubbing (the workshop becomes full)
            // Star Wars (full: 3/3)
            (1, 13, .validated),  // Alice -> lightsaber duel
            (4, 13, .validated),  // David -> lightsaber duel
            (6, 13, .validated)   // Hugo  -> lightsaber duel (the workshop becomes full)
        ]

        for (userIndex, workshopIndex, status) in plan {
            let reservation = Reservation(
                status: status,
                workshopID: try workshops[workshopIndex].requireID(),
                userID: try users[userIndex].requireID()
            )
            try await reservation.save(on: database)

            // totalSubscribers = number of validated reservations
            if status == .validated {
                workshops[workshopIndex].totalSubscribers += 1
            }
        }

        // 5. Update the subscriber counters
        for workshop in workshops {
            try await workshop.update(on: database)
        }
    }

    func revert(on database: any Database) async throws {
        // Delete in reverse order (because of foreign keys)
        let users = try await UserModel.query(on: database)
            .filter(\.$email ~~ seedUserEmails)
            .all()
        let userIDs = users.compactMap { $0.id }

        try await Reservation.query(on: database)
            .filter(\.$user.$id ~~ userIDs)
            .delete()

        try await Workshop.query(on: database)
            .filter(\.$name ~~ seedWorkshopNames)
            .delete()

        try await UserModel.query(on: database)
            .filter(\.$email ~~ seedUserEmails)
            .delete()

        try await Category.query(on: database)
            .filter(\.$name ~~ seedCategoryNames)
            .delete()
    }
}
