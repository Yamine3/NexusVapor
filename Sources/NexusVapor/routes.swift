import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    try app.register(collection: ControllerWorkshop())
    try app.register(collection: ControllerCategory())
    try app.register(collection: UserController())
    
}
