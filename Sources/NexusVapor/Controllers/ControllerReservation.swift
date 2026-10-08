//
//  ControllerReservation.swift
//  NexusVapor
//
//  Created by Apprenant 89 on 02/10/2026.
//

import Fluent
import Vapor
import Gatekeeper

struct ControllerReservation : RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let reservations = routes.grouped("reservations")
        
        let reservationRoutes = reservations.grouped(
            GatekeeperMiddleware(),
            JWTMiddleware()
        )
        reservationRoutes.post(use: create)
        //Pour le festivalGoer et le staff = toutes personne qui est authentifiée
        let authenticatedRoutes = reservations.grouped(
            JWTMiddleware()
        )

//        authenticatedRoutes.post(use: create)
        authenticatedRoutes.delete(":id", use: cancel)
        
        //Pour le staff
        let staffRoutes = reservations.grouped(
            JWTMiddleware(), EnsureStaffMiddleware()
        )
        staffRoutes.get(use: index)
        staffRoutes.get("workshops",":workshopID","attendees", use: attendees)
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
        
        let payload = try req.auth.require(UserPayload.self)
        
        guard let workshop = try await Workshop.find(
            dto.workshopID,
            on: req.db
        ) else {
            throw Abort(
                .notFound,
                reason: "Workshop not found."
            )
        }
        
        guard try await UserModel.find(
            payload.id,
            // avant dto.userID
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
            .filter(\.$user.$id == payload.id)
                //avant dto.userID
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
        
        let reservation = Reservation(status: .validated, workshopID: dto.workshopID, userID: payload.id)
        //avant dto.userID
        
        try await reservation.create(on: req.db)
        
        workshop.totalSubscribers += 1
        
        try await workshop.update(on: req.db)
        
        return ReservationResponseDTO(
            id: try reservation.requireID(),
            status: reservation.status)
    }
    
    //cancel
    func cancel (req: Request) async throws -> HTTPStatus {
        
        let payload = try req.auth.require(UserPayload.self)
        
        guard let id = req.parameters.get(
            "id", as: UUID.self
        ) else {
            throw Abort(.badRequest, reason: "Invalid ID.")
        }
        
        guard let reservation = try await Reservation.find(id, on: req.db)
                else { throw Abort(.notFound, reason: "Reservation not found.") }
        
        guard let currentUser = try await UserModel.find(
            payload.id,
            on: req.db
        ) else {
            throw Abort(.unauthorized)
        }
        
        //un festivalGoer peut seulement annuler sa réservation
        //un staff peut annuler n'importe quelle réservation
        //Si je ne suis pas staff ET que la réservation ne m'appartient pas -> interdiction d'annuler
        //Donc festivalGoer + ma résa c'est OK
        //staff + résa de quelqu'un d'autre c'est OK
        
        if currentUser.role != .staff && reservation.$user.id != payload.id {
            throw Abort(
                .forbidden,
                reason: "You are not authorized to cancel this reservation."
            )
        }
        
        guard reservation.status == .validated
                else { throw Abort(.badRequest, reason: "Reservation cannot be cancelled.")}
        
        reservation.status = .cancelled
        
        try await reservation.update(on: req.db)
        
        let workshop = try await reservation.$workshop.get(on: req.db)
        
        workshop.totalSubscribers -= 1
        
        try await workshop.update(on: req.db)
        
        return .noContent
    }
    
//GET /reservations/workshops/:workshopID/attendees
    func attendees(req: Request) async throws -> [WorkshopAttendeeResponseDTO] {
        
        guard let workshopID = req.parameters.get(
            "workshopID",
            as: UUID.self
        ) else {
            throw Abort(.badRequest, reason: "Invalid workshop ID.")
        }
        
        let reservations = try await Reservation
            .query(on: req.db)
            .filter(\.$workshop.$id == workshopID)
            .with(\.$user)
            .all()
        
        return try reservations.map {
            try $0.convertToWorkshopAttendeeDTO()
        }
    }
}
