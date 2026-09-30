//
//  ControllerWorkshop.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 30/09/2026.
//

import Fluent
import Vapor

struct ControllerWorkshop: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let categories = routes.grouped("workshops")
                
                categories.get(use: index)
                categories.post(use: create)
                
                categories.group(":id") { category in
                    category.put(use: update)
                    category.delete(use: delete)
                }
        
    }
    func index(req : Request) async throws -> [Workshop] {
        return try await Workshop
            .query(on: req.db)
            .all()
    }
    
    func create(req: Request) async throws -> Workshop {
        let workshop = try req.content.decode(
            Workshop.self
        )
        try await workshop.create(on: req.db)
        return workshop
    }
    
    func update(req: Request) async throws -> Workshop {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Identifiant invalide.")
        }

        guard let workshop = try await Workshop.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Workshop introuvable.")
        }

        let newWorkshop = try req.content.decode(Workshop.self)

        guard !newWorkshop.name.isEmpty else {
            throw Abort(.badRequest, reason: "Workshop est obligatoire.")
        }

        workshop.name = newWorkshop.name

        try await workshop.update(on: req.db)

        return workshop
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Identifiant invalide.")
        }
        
        guard let workshop = try await Workshop.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Workshop introuvable.")
        }
        
        try await workshop.delete(on: req.db)
        return .noContent
    }
}

