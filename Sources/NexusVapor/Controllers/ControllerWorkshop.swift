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
            throw Abort (.badRequest, reason: "Invalid workshop ID.")
        }
        
        guard let workshop = try await Workshop
            .query(on: req.db)
            .with(\.$category)
            .filter(\.$id == id)
            .first()
                else {
            throw Abort(.notFound, reason: "Workshop not found.")
        }
        
        let category = workshop.category
        
        return try workshop.convertToWorkshopDetailDTO(category: category)
    }
    
    //CREATE
    //    func create(req: Request) async throws -> Workshop {
    //        let workshop = try req.content.decode(
    //            Workshop.self
    //        )
    //        try await workshop.create(on: req.db)
    //        return workshop
    //    }
    
    func create(req: Request) async throws -> GetWorkshopsDetailResponseDTO {
        let dto = try req.content.decode(CreateWorkshopDTO.self)
        
        guard !dto.name.isEmpty else {
            throw Abort(
                .badRequest,
                reason: "Workshop name is mandatory."
            )
        }
        
        guard dto.startTime < dto.endTime else {
            throw Abort(
                .badRequest,
                reason: "Start time must be before end time."
            )
        }
        
        guard dto.capacityMax > 0 else {
            throw Abort(
                .badRequest,
                reason: "Capacity must be greater than 0."
            )
        }
        
        guard try await Category.find(dto.categoryID, on: req.db) != nil else {
            throw Abort(
                .notFound,
                reason: "Category not found."
            )
        }
        
        let workshop = dto.convertToWorshop()
        
        try await workshop.create(on: req.db)
        
        let category = try await workshop.$category.get(on: req.db)
        
        return try workshop.convertToWorkshopDetailDTO(category: category)
    }
    
    //UPDATE
    func update(req: Request) async throws -> GetWorkshopsDetailResponseDTO {
        
        guard let id = req.parameters.get(
            "id", as: UUID.self
        ) else {
            throw Abort (.badRequest, reason: "Invalid ID.")
        }
        
        
        guard let workshop = try await Workshop.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Workshop not found.")
        }
        
        let dto = try req.content.decode(UpdateWorkshopDTO.self)
        
        guard !dto.name.isEmpty else {
            throw Abort(
                .badRequest,
                reason: "Workshop name is mandatory."
            )
        }
        
        guard dto.startTime < dto.endTime else {
            throw Abort(
                .badRequest,
                reason: "Start time must be before end time."
            )
        }
        
        guard dto.capacityMax > 0 else {
            throw Abort(.badRequest, reason: "Capacity must be greater than 0.")
        }
        guard dto.capacityMax >= workshop.totalSubscribers else {
            throw Abort(
                .badRequest,
                reason: "Capacity cannot be lower than the number of subscribers."
            )
        }
        
        guard try await Category.find(dto.categoryID, on: req.db) != nil else {
            throw Abort(
                .notFound,
                reason: "Category not found."
            )
        }
        
        workshop.name = dto.name
        workshop.startTime = dto.startTime
        workshop.endTime = dto.endTime
        workshop.capacityMax = dto.capacityMax
        workshop.description = dto.description
        workshop.$category.id = dto.categoryID
        
        try await workshop.update(on: req.db)
        
        let category = try await workshop.$category.get(on: req.db)
        
        
        return try workshop.convertToWorkshopDetailDTO(category: category)
    }
    
    //DELETE
    
    func delete(req: Request) async throws -> HTTPStatus {
        
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(
                .badRequest,
                reason: "Invalid workshop ID."
            )
        }
        
        guard let workshop = try await Workshop.find(id, on: req.db) else {
            throw Abort(
                .notFound,
                reason: "Workshop not found."
            )
        }
        
        try await workshop.delete(on: req.db)
        
        return .noContent
    }
}
