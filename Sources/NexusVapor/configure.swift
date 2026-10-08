import NIOSSL
import Fluent
import FluentMySQLDriver
import Leaf
import Vapor
import Gatekeeper

/// configures your application
func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "nexus_db"
    ), as: .mysql)
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        //plus tard .custom("http://localhost:0000")
        allowedMethods: [.GET,.POST,.PUT,.DELETE,.OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin],
        cacheExpiration: 800
    )
    
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)

    app.caches.use(.memory)
    app.gatekeeper.config = .init(
        maxRequests: 2,
        per: .minute
    )
    app.middleware.use(corsMiddleware)
    
    // app.migrations.add()
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateWorkshop())
    app.migrations.add(CreateReservation())
    

    app.views.use(.leaf)

    // register routes
    try routes(app)
    
   
}
