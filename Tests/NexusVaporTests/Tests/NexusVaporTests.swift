@testable import NexusVapor
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct NexusVaporTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        setenv("SECRET_KEY", "test-secret-key", 1)
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            print("ERREUR DANS LE TEST:", String(reflecting: error))
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    private func createUserTest(
        _ app: Application,
        email: String = "staff@test.com",
        password: String = "password123",
        role: Role = .staff) async throws {
            let user = UserModel(
                name: "Admin",
                password: try Bcrypt.hash(password),
                email: email,
                role: role,
                creationDate: nil
            )
            try await user.save(on: app.db)
        }
    
    private func tokenStaff(
        _ app: Application,
        email: String = "staff@test.com",
        password: String = "password123") async throws -> String {
        try await createUserTest(app, email: email, password: password)
        
        let login = LoginRequestDTO(email: email, password: password)
        var token = ""
        
        try await app.testing().test(
            .POST, "users/login",
            beforeRequest: { req in
                try req.content.encode(login, as: .json)
            },
            afterResponse: { res async throws in
                token = try res.content.decode(AuthDTO.self).token
            }
        )
        return token
    }
    
    private func tokenFestivalGoer(
        _ app: Application,
        email: String = "user@test.com",
        password: String = "password123") async throws -> String {
            try await createUserTest(app, email: email, password: password, role: .festivalGoer)
        
        let login = LoginRequestDTO(email: email, password: password)
        var token = ""
        
        try await app.testing().test(
            .POST, "users/login",
            beforeRequest: { req in
                try req.content.encode(login, as: .json)
            },
            afterResponse: { res async throws in
                token = try res.content.decode(AuthDTO.self).token
            }
        )
        return token
    }
    
    private func reserveTest(_ app: Application, token: String, workshop: Workshop) async throws {
        let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

        try await app.testing().test(
            .POST, "reservations",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(reservationDTO)
            },
            afterResponse: { res async throws in
                #expect(res.status == .ok)
            }
        )
    }
    
    @Test("/POST User creation")
    func userCreation() async throws {
        try await withApp { app in
            let userDTO = CreateUserDTO(
                name: "Alice",
                email: "alice@test.com",
                password: "password123"
            )

            try await app.testing().test(
                .POST, "users",
                beforeRequest: { req in
                    try req.content.encode(userDTO, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let user = try res.content.decode(UserDTO.self)
                    #expect(user.email == "alice@test.com")
                    #expect(user.name == "Alice")
                }
            )
        }
    }
    
    @Test("/GET Index Categories")
    func indexCategories() async throws {
        try await withApp { app in
            
            let token = try await tokenFestivalGoer(app)
            
            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)
            let category2 = CategoryModel(name : "Jeux")
            try await category2.save(on: app.db)
            
            try await app.testing().test(
                .GET, "categories",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let categories = try res.content.decode([CategoryModel].self)
                    #expect(categories.count == 2)
                    #expect(categories.map(\.name).contains("Mangas"))
                    #expect(categories.map(\.name).contains("Jeux"))
                }
            )
        }
    }
    
    @Test("/POST Staff connexion")
    func staffLogin() async throws {
        try await withApp { app in
            try await createUserTest(app)
            
            let login = LoginRequestDTO(email: "staff@test.com", password: "password123")
            
            try await app.testing().test(
                .POST, "users/login",
                beforeRequest: { req in
                    try req.content.encode(login, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let auth = try res.content.decode(AuthDTO.self)
                    #expect(!auth.token.isEmpty)
                }
            )
            let saved = try await UserModel.query(on: app.db)
                .filter(\.$email == "staff@test.com")
                .first()
            #expect(saved?.role == .staff)
        }
    }
    
    @Test("/POST Login wrong password")
    func loginWrongPassword() async throws {
        try await withApp { app in
            try await createUserTest(app)
            
            let login = LoginRequestDTO(email: "staff@test.com", password: "mauvais")
            
            try await app.testing().test(
                .POST, "users/login",
                beforeRequest: { req in
                    try req.content.encode(login, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }
    
    @Test("/POST Login wrong email")
    func loginWrongEmail() async throws {
        try await withApp { app in
            try await createUserTest(app)
            
            let login = LoginRequestDTO(email: "staff@test.co", password: "password123")
            
            try await app.testing().test(
                .POST, "users/login",
                beforeRequest: { req in
                    try req.content.encode(login, as: .json)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }
    
    @Test("/POST Category creation")
    func creationCategory() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)
            
            let categoryDTO = CategoryDTO(
                id: UUID(),
                name: "Mangas"
            )
            try await app.testing().test(
                .POST, "categories",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(categoryDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let category = try res.content.decode(CategoryModel.self)
                    #expect(category.name == "Mangas")
                    #expect(category.id != nil)
                }
            )

            let count = try await CategoryModel.query(on: app.db).count()
            #expect(count == 1)
        }
    }
    
    @Test("/POST Category creation with the wrong token")
    func creationCategoryFailed() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)
            
            let categoryDTO = CategoryDTO(
                id: UUID(),
                name: "Mangas"
            )
            try await app.testing().test(
                .POST, "categories",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(categoryDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .forbidden)
                }
            )

            let count = try await CategoryModel.query(on: app.db).count()
            #expect(count == 0)
        }
    }
    
    @Test("/POST Category creation with no name")
    func creationCategoryWithNoName() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)
            
            let categoryDTO = CategoryDTO(
                id: UUID(),
                name: " "
            )
            try await app.testing().test(
                .POST, "categories",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(categoryDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )

            let count = try await CategoryModel.query(on: app.db).count()
            #expect(count == 0)
        }
    }
    
    @Test("/POST Expecting bad request")
        func postCategoryNegative() async throws{
            try await withApp { app in
                let token = try await tokenStaff(app)

                let categoryDTO = CategoryDTO(
                    id: UUID(),
                    name: ""
                )
                try await app.testing().test(
                    .POST, "categories",
                    beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(categoryDTO)
                }, afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                })
            }
        }
    
    @Test("/POST Workshop creation")
    func workshopCreation() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)
            
            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshopDTO = CreateWorkshopDTO(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )

            try await app.testing().test(
                .POST, "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let workshop = try res.content.decode(GetWorkshopsDetailResponseDTO.self)
                    #expect(workshop.name == "Atelier dessin")
                    #expect(workshop.category == "Mangas")
                }
            )
        }
    }
    
    @Test("/POST Workshop creation empty name")
    func workshopCreationEmptyName() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)
            
            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshopDTO = CreateWorkshopDTO(
                name: "",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )

            try await app.testing().test(
                .POST, "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }
    
    @Test("/POST Workshop creation empty capacity")
    func workshopCreationEmptyCapacity() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)
            
            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshopDTO = CreateWorkshopDTO(
                name: "Mangas",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )

            try await app.testing().test(
                .POST, "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(workshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }
    
    @Test("/PUT Workshop update")
    func workshopUpdate() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            let updateDTO = UpdateWorkshopDTO(
                name: "Atelier manga",
                startTime: Date(),
                endTime: Date().addingTimeInterval(7200),
                capacityMax: 20,
                description: "Apprendre à dessiner un manga",
                categoryID: category.id!
            )

            try await app.testing().test(
                .PUT, "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let updated = try res.content.decode(GetWorkshopsDetailResponseDTO.self)
                    #expect(updated.name == "Atelier manga")
                    #expect(updated.capacityMax == 20)
                }
            )
        }
    }
    
    @Test("/PUT Workshop update failed")
    func workshopUpdateFailed() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            let updateDTO = UpdateWorkshopDTO(
                name: "",
                startTime: Date(),
                endTime: Date().addingTimeInterval(7200),
                capacityMax: 20,
                description: "Apprendre à dessiner un manga",
                categoryID: category.id!
            )

            try await app.testing().test(
                .PUT, "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(updateDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }
    
    @Test("/DELETE Workshop delete")
    func workshopDelete() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            try await app.testing().test(
                .DELETE, "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .noContent)
                }
            )
            let workshopCount = try await Workshop.query(on: app.db).count()
            #expect(workshopCount == 0)

            let categoryCount = try await CategoryModel.query(on: app.db).count()
            #expect(categoryCount == 1)
        }
    }
    
    @Test("/DELETE Workshop delete unknown id")
    func workshopDeleteUnknownId() async throws {
        try await withApp { app in
            let token = try await tokenStaff(app)

            try await app.testing().test(
                .DELETE, "workshops/\(UUID())",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }
    
    @Test("/GET Workshops index")
    func workshopsIndex() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            try await app.testing().test(
                .GET, "workshops",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )
        }
    }

    @Test("/GET Workshop detail")
    func workshopShow() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            try await app.testing().test(
                .GET, "workshops/\(workshop.id!)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let detail = try res.content.decode(GetWorkshopsDetailResponseDTO.self)
                    #expect(detail.name == "Atelier dessin")
                    #expect(detail.category == "Mangas")
                }
            )
        }
    }
    
    @Test("/GET Workshop attendees")
    func workshopAttendees() async throws {
        try await withApp { app in
            let userToken = try await tokenFestivalGoer(app)
            let staffToken = try await tokenStaff(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            try await reserveTest(app, token: userToken, workshop: workshop)

            try await app.testing().test(
                .GET, "reservations/workshops/\(workshop.id!)/attendees",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: staffToken)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )
        }
    }

    @Test("/GET Workshop attendees forbidden")
    func workshopAttendeesForbidden() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            try await app.testing().test(
                .GET, "reservations/workshops/\(workshop.id!)/attendees",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .forbidden)
                }
            )
        }
    }
    
    @Test("/POST Reservation creation")
    func reservationCreation() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

            try await app.testing().test(
                .POST, "reservations",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(reservationDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let reservation = try res.content.decode(ReservationResponseDTO.self)
                    #expect(reservation.status == .validated)
                }
            )
        }
    }
    
    @Test("/POST Reservation creation without token")
    func reservationCreationWithoutToken() async throws {
        try await withApp { app in
            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

            try await app.testing().test(
                .POST, "reservations",
                beforeRequest: { req in
                    try req.content.encode(reservationDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .unauthorized)

                }
            )
        }
    }

    @Test("/POST Reservation twice on the same workshop")
    func reservationTwice() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            try await reserveTest(app, token: token, workshop: workshop)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

            try await app.testing().test(
                .POST, "reservations",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(reservationDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .conflict)
                }
            )

            let count = try await Reservation.query(on: app.db).count()
            #expect(count == 1)
        }
    }

    @Test("/POST Reservation workshop full")
    func reservationWorkshopFull() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 1,
                totalSubscribers: 1,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)

            try await app.testing().test(
                .POST, "reservations",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(reservationDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .conflict)
                }
            )

            let count = try await Reservation.query(on: app.db).count()
            #expect(count == 0)
        }
    }

    @Test("/POST Reservation cancel")
    func reservationCancel() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            let reservationDTO = CreateReservationDTO(workshopID: workshop.id!)
            var reservationID = UUID()

            try await app.testing().test(
                .POST, "reservations",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                    try req.content.encode(reservationDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    reservationID = try res.content.decode(ReservationResponseDTO.self).id
                }
            )
            
            try await app.testing().test(
                .DELETE, "reservations/\(reservationID)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .noContent)
                }
            )
        }
    }

    @Test("/GET Reservations index")
    func reservationsIndex() async throws {
        try await withApp { app in
            let userToken = try await tokenFestivalGoer(app)
            let staffToken = try await tokenStaff(app)

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            try await reserveTest(app, token: userToken, workshop: workshop)

            try await app.testing().test(
                .GET, "reservations",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: staffToken)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )
        }
    }
    
    
    @Test("/GET Reservations index forbidden")
    func reservationsIndexForbidden() async throws {
        try await withApp { app in
            let token = try await tokenFestivalGoer(app)

            try await app.testing().test(
                .GET, "reservations",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .forbidden)
                }
            )
        }
    }

    @Test("/GET Reservations/me ")
    func reservationsMe() async throws {
        try await withApp { app in
            let myToken = try await tokenFestivalGoer(app, email: "emma@nexusfestival.com")
            let otherToken = try await tokenFestivalGoer(app, email: "bob@nexusfestival.com")

            let category = CategoryModel(name : "Mangas")
            try await category.save(on: app.db)

            let workshop = Workshop(
                name: "Atelier dessin",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                capacityMax: 10,
                totalSubscribers: 0,
                description: "Apprendre à dessiner un personnage",
                categoryID: category.id!
            )
            try await workshop.save(on: app.db)

            try await reserveTest(app, token: myToken, workshop: workshop)
            try await reserveTest(app, token: otherToken, workshop: workshop)

            try await app.testing().test(
                .GET, "reservations/me",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = BearerAuthorization(token: myToken)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let reservations = try res.content.decode([GetReservationListItemResponseDTO].self)
                    #expect(reservations.count == 1)
                    #expect(reservations.first?.status == .validated)
                }
            )
        }
    }
}

