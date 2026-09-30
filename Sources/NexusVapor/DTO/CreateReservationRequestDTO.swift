//
//  CreateReservationRequestDTO.swift
//  NexusVapor
//
//  Created by apprenant92 on 30/09/2026.
//

import Vapor
import Fluent

struct CreateReservationDTO: Content {
    let status: ReservationStatus
    let workshopID: UUID
    let userID: UUID
    
    func toModel() -> Reservation {
        let reservation = Reservation(
            status: status,
            workshopID: workshopID,
            userID: userID
        )
        return reservation
    }
}
