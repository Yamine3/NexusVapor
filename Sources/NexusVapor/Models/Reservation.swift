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


    init() { }

    init(
        id: UUID? = nil,
        status: ReservationStatus,
        workshopID: UUID
        
    ) {
        self.id = id
        self.status = status
        self.$workshop.id = workshopID
    }
}

enum ReservationStatus: String, Codable {
    case validated
    case pending
    case cancelled
}
