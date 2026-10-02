//
//  ControllerUser.swift
//  NexusVapor
//
//  Created by AymTek.
//

import Fluent
import Vapor

struct ControllerUser: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        
        users.get(use: index)
        users.post(use: create)
        
        users.group(":id") { user in
            user.get(use: show)
            user.put(use: update)
            user.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [User] {
        return try await User
            .query(on: req.db)
            .all()
    }
    
    func show(req: Request) async throws -> User {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID.")
        }
        
        guard let user = try await User.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }
        
        return user
    }
    
    func create(req: Request) async throws -> User {

        let user = try req.content.decode(User.self)
        
        guard !user.email.isEmpty, !user.name.isEmpty else {
            throw Abort(.badRequest, reason: "Username and email needed")
        }
        
        try await user.create(on: req.db)
        return user
    }

    
    func update(req: Request) async throws -> User {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID.")
        }
        
        guard let user = try await User.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }
        
        let updatedData = try req.content.decode(User.self)
        
        user.name = updatedData.name
        user.email = updatedData.email
        user.role = updatedData.role
        
        try await user.update(on: req.db)
        return user
    }
    

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid ID.")
        }
        
        guard let user = try await User.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Utilisateur introuvable.")
        }
        
        try await user.delete(on: req.db)
        return .noContent
    }
}
