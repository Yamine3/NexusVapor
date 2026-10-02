//
//  ControllerReservation.swift
//  NexusVapor
//
//  Created by Apprenant 89 on 02/10/2026.
//

import Fluent
import Vapor

struct ControllerReservation : RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let reservations = routes.grouped("reservations")
        
        reservations.get(use: index)
        reservations.post(use: create)
        reservations.delete(use: cancel)
    }
    
    //GET ALL
    func index(req:Request) async throws -> [GetReservationListItemResponseDTO] {
        let reservations = try await Reservation
            .query(on: req.db)
            .with(\.$workshop,
                   { workshop in workshop.with(\.$category) }
            )
            .with(\.$user)
            .all()
        
        return try reservations.map {
            try $0.convertToReservationListDTO()
        }
    }
    
    //CREATE
    func create(req: Request) async throws -> ReservationResponseDTO{
        
        let dto = try req.content.decode(CreateReservationDTO.self)
        
        guard let workshop = try await Workshop.find(
            dto.workshopID,
            on: req.db
        ) else {
            throw Abort(
                .notFound,
                reason: "Workshop not found."
            )
        }
        
        guard try await User.find(
            dto.userID,
            on: req.db
        ) != nil else {
            throw Abort(
                .notFound,
                reason: "User not found."
            )
        }
        
        guard try await Reservation
            .query(on: req.db)
            .filter(\.$workshop.$id == dto.workshopID)
            .filter(\.$user.$id == dto.userID)
            .filter(\.$status == .validated)
            .first() == nil
                else {
            throw Abort(
                .conflict,
                reason:"User already has a reservation for \(workshop.name)."
            )
        }
        
        guard workshop.totalSubscribers < workshop.capacityMax else {
            throw Abort(
                .conflict,
                reason: "Workshop is full."
            )
        }
        
        let reservation = Reservation(status: .validated, workshopID: dto.workshopID, userID: dto.userID)
        
        try await reservation.create(on: req.db)
        
        workshop.totalSubscribers += 1
        
        try await workshop.update(on: req.db)
        
        return ReservationResponseDTO(
            id: try reservation.requireID(),
            status: reservation.status)
    }
    
    //cancel
    func cancel (req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get(
            "id", as: UUID.self
        ) else {
            throw Abort(.badRequest, reason: "Invalid ID.")
        }
        
        guard let reservation = try await Reservation.find(id, on: req.db)
                else { throw Abort(.notFound, reason: "Reservation not found.") }
        
        guard reservation.status == .validated
                else { throw Abort(.badRequest)}
        
        reservation.status = .cancelled
        
        try await reservation.update(on: req.db)
        
        let workshop = try await reservation.$workshop.get(on: req.db)
        
        workshop.totalSubscribers -= 1
        
        try await workshop.update(on: req.db)
        
        return .noContent
    }
}
