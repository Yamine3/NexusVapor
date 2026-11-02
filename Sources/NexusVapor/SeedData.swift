//
//  SeedData.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 02/11/2026.
//

import Fluent
import Vapor

struct SeedData: AsyncMigration {

    // Catégorie déjà présente en base (ne sera jamais supprimée au revert)
    private let existingCategoryName = "Mangas"

    // Catégories créées par le seed (ajoutées à "Mangas")
    private let newCategoryNames = [
        "Cosplay",
        "Jeux vidéo",
        "Doublage & Voix"
    ]

    private let seedUserEmails = [
        "staff@herofestival.com",
        "alice@herofestival.com",
        "bob@herofestival.com",
        "chloe@herofestival.com"
    ]

    private let seedWorkshopNames = [
        "Dessine ton premier manga shonen",          // 0 - Mangas
        "Lettrage & mise en page d'une planche",     // 1 - Mangas
        "Fabrique ton armure de cosplay (EVA foam)", // 2 - Cosplay
        "Perruques & maquillage de personnage",      // 3 - Cosplay
        "Initiation au speedrun",                    // 4 - Jeux vidéo
        "Crée ton jeu en pixel art",                 // 5 - Jeux vidéo
        "Doublage d'anime : donne ta voix"           // 6 - Doublage (2 places)
    ]

    // Petite fonction pour fabriquer une date (fuseau de Paris)
    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        let components = DateComponents(
            year: year, month: month, day: day,
            hour: hour, minute: minute
        )
        return calendar.date(from: components)!
    }

    // Retrouve une catégorie par son nom, ou la crée si elle n'existe pas
    private func findOrCreateCategory(named name: String, on database: any Database) async throws -> Category {
        if let existing = try await Category.query(on: database)
            .filter(\.$name == name)
            .first() {
            return existing
        }
        let category = Category(name: name)
        try await category.save(on: database)
        return category
    }

    // Retrouve un utilisateur par son email, ou le crée s'il n'existe pas
    private func findOrCreateUser(
        name: String, email: String, role: Role, password: String,
        on database: any Database
    ) async throws -> UserModel {
        if let existing = try await UserModel.query(on: database)
            .filter(\.$email == email)
            .first() {
            return existing
        }
        let user = UserModel(
            name: name, password: password,
            email: email, role: role, creationDate: Date()
        )
        try await user.save(on: database)
        return user
    }

    func prepare(on database: any Database) async throws {

        // 1. CATEGORIES (Mangas déjà en base -> réutilisée)
        let mangas = try await findOrCreateCategory(named: existingCategoryName, on: database)
        var created: [Category] = []
        for name in newCategoryNames {
            created.append(try await findOrCreateCategory(named: name, on: database))
        }
        let cosplay = created[0]
        let jeuxVideo = created[1]
        let doublage = created[2]

        // 2. USERS (mots de passe hashés avec Bcrypt, comme dans UserController)
        let hashedPassword = try Bcrypt.hash("Password123!")

        let staff = try await findOrCreateUser(
            name: "Sensei Staff", email: seedUserEmails[0],
            role: .staff, password: hashedPassword, on: database
        )
        let alice = try await findOrCreateUser(
            name: "Alice Martin (Sakura Blade)", email: seedUserEmails[1],
            role: .festivalGoer, password: hashedPassword, on: database
        )
        let bob = try await findOrCreateUser(
            name: "Bob Durand (Pixel Ninja)", email: seedUserEmails[2],
            role: .festivalGoer, password: hashedPassword, on: database
        )
        let chloe = try await findOrCreateUser(
            name: "Chloé Bernard (Neko Gamer)", email: seedUserEmails[3],
            role: .festivalGoer, password: hashedPassword, on: database
        )

        let users = [staff, alice, bob, chloe]

        // 3. WORKSHOPS (totalSubscribers est recalculé plus bas)
        let workshops = [
            Workshop(
                name: seedWorkshopNames[0],
                startTime: date(2027, 7, 10, 10), endTime: date(2027, 7, 10, 12),
                capacityMax: 15, totalSubscribers: 0,
                description: "Invente ton héros, son design et ses pouvoirs, puis dessine ta première page de manga façon shonen.",
                categoryID: try mangas.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[1],
                startTime: date(2027, 7, 10, 14), endTime: date(2027, 7, 10, 16),
                capacityMax: 12, totalSubscribers: 0,
                description: "Apprends à découper une planche, placer les bulles et les onomatopées comme un vrai mangaka.",
                categoryID: try mangas.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[2],
                startTime: date(2027, 7, 11, 10), endTime: date(2027, 7, 11, 13),
                capacityMax: 10, totalSubscribers: 0,
                description: "Découpe, assemble et peins une armure en mousse EVA inspirée de ton personnage de jeu ou d'anime préféré.",
                categoryID: try cosplay.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[3],
                startTime: date(2027, 7, 11, 14), endTime: date(2027, 7, 11, 16),
                capacityMax: 20, totalSubscribers: 0,
                description: "Coiffe une perruque démesurée et maîtrise le maquillage pour ressembler trait pour trait à ton personnage.",
                categoryID: try cosplay.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[4],
                startTime: date(2027, 7, 11, 16, 30), endTime: date(2027, 7, 11, 18),
                capacityMax: 16, totalSubscribers: 0,
                description: "Découvre les techniques, glitchs et astuces des speedrunners et tente ton premier chrono en direct.",
                categoryID: try jeuxVideo.requireID()
            ),
            Workshop(
                name: seedWorkshopNames[5],
                startTime: date(2027, 7, 12, 9), endTime: date(2027, 7, 12, 12),
                capacityMax: 8, totalSubscribers: 0,
                description: "Dessine tes sprites, anime ton personnage et crée un mini-jeu rétro jouable en une matinée.",
                categoryID: try jeuxVideo.requireID()
            ),
            // Petit workshop (2 places) pour tester le cas "Workshop is full."
            Workshop(
                name: seedWorkshopNames[6],
                startTime: date(2027, 7, 12, 14), endTime: date(2027, 7, 12, 16),
                capacityMax: 2, totalSubscribers: 0,
                description: "Prête ta voix à un personnage d'anime devant un micro, comme en studio de doublage.",
                categoryID: try doublage.requireID()
            )
        ]
        for workshop in workshops {
            try await workshop.save(on: database)
        }

        // 4. RESERVATIONS : (index user, index workshop, status)
        // ⚠️ Un même user ne peut réserver qu'une fois le même workshop (contrainte unique).
        let plan: [(Int, Int, ReservationStatus)] = [
            (1, 0, .validated),   // Alice -> manga shonen
            (2, 0, .validated),   // Bob   -> manga shonen
            (1, 2, .validated),   // Alice -> armure cosplay
            (3, 2, .cancelled),   // Chloé -> armure cosplay (annulée)
            (3, 3, .pending),     // Chloé -> perruques & maquillage (en attente)
            (2, 4, .validated),   // Bob   -> speedrun
            (3, 5, .validated),   // Chloé -> pixel art
            (1, 6, .validated),   // Alice -> doublage
            (2, 6, .validated)    // Bob   -> doublage (le workshop devient complet)
        ]

        for (userIndex, workshopIndex, status) in plan {
            let reservation = Reservation(
                status: status,
                workshopID: try workshops[workshopIndex].requireID(),
                userID: try users[userIndex].requireID()
            )
            try await reservation.save(on: database)

            // totalSubscribers = nombre de réservations validées
            if status == .validated {
                workshops[workshopIndex].totalSubscribers += 1
            }
        }

        // 5. Mise à jour des compteurs d'inscrits
        for workshop in workshops {
            try await workshop.update(on: database)
        }
    }

    func revert(on database: any Database) async throws {
        // On supprime dans l'ordre inverse (à cause des clés étrangères)
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

        // "Mangas" n'est volontairement PAS supprimée : elle existait avant le seed
        try await Category.query(on: database)
            .filter(\.$name ~~ newCategoryNames)
            .delete()
    }
}
