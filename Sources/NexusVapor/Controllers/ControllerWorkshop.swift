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
        let workshops = routes.grouped("workshops")
        
        workshops.get(use: index)
        workshops.post(use: create)
        
        workshops.group(":id") { workshop in
            workshop.put(use: update)
            workshop.delete(use: delete)
            workshop.get(use: show)
        }
        
    }
    
    
//INDEX
    //    func index(req : Request) async throws -> [Workshop] {
    //        return try await Workshop
    //            .query(on: req.db)
    //            .all()
    //    }
    
    func index(req: Request) async throws -> [GetWorkshopsListResponseDTO] {
        let workshops = try await Workshop
            .query(on: req.db)
            .with(\.$category)
            .all()
        
        return try workshops.map {
            try $0.convertToWorkshopListDTO()
        }
    }

//SHOW
    func show(req: Request) async throws -> GetWorkshopsDetailResponseDTO {
        guard let id = req.parameters.get(
            "id", as: UUID.self
        ) else {
            throw Abort (.badRequest, reason: "Invalid ID.")
        }
        
        guard let workshop = try await Workshop
            .query(on: req.db)
            .with(\.$category)
            .filter(\.$id == id)
            .first()
                else {
            throw Abort(.notFound, reason: "Workshop not found.")
        }
        return try workshop.convertToWorkshopDetailtoDTO()
    }

//CREATE
    //    func create(req: Request) async throws -> Workshop {
    //        let workshop = try req.content.decode(
    //            Workshop.self
    //        )
    //        try await workshop.create(on: req.db)
    //        return workshop
    //    }
    
    func create(req: Request) async throws -> Workshop {
        let dto = try req.content.decode(CreateWorkshopDTO.self)
        let workshop = dto.convertToWorshop()
        try await workshop.create(on: req.db)
        return workshop
    }

//UPDATE
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

//DELETE
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

