//
//  Reservation.swift
//  NexusVapor
//
//  Created by AymTek.
//

import Fluent
import Vapor

final class Reservation: Model,Content, @unchecked Sendable {
    static let schema = "reservations"
    
    @ID(key: .id)
    var id: UUID?
    
    @Enum(key: "status")
    var status: ReservationStatus
    
    @Parent(key: "workshop_id")
    var workshop : Workshop
    
    @Parent(key: "user_id")
    var user: UserModel
    
    init() { }
    
    init(
        id: UUID? = nil,
        status: ReservationStatus,
        workshopID: UUID,
        userID: UUID
        
    ) {
        self.id = id
        self.status = status
        self.$workshop.id = workshopID
        self.$user.id = userID
        
    }
}

enum ReservationStatus: String, Codable {
    case validated
    case pending
    case cancelled
}

extension Reservation {
    func convertToReservationListDTO() throws -> GetReservationListItemResponseDTO {
        GetReservationListItemResponseDTO(
            id: try requireID(),
            workshopID: try workshop.requireID(),
            workshopName: workshop.name,
            category: workshop.category.name,
            startTime: workshop.startTime,
            endTime: workshop.endTime,
            capacityMax: workshop.capacityMax,
            status: status
        )
    }
}

extension Reservation {
    func convertToWorkshopAttendeeDTO() throws -> WorkshopAttendeeResponseDTO {
        WorkshopAttendeeResponseDTO(
            reservationID: try requireID(),
            userID: try user.requireID(),
            name: user.name,
            email: user.email,
            status: status
        )
    }
}
