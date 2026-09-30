//
//  ReservationResponseDTO.swift
//  NexusVapor
//
//  Created by apprenant92 on 30/09/2026.
//

import Vapor
import Fluent

struct ReservationResponseDTO: Content {
    let status: ReservationStatus
    let userID: UUID
    let workshopID: UUID
    
    func toModel() -> Reservation {
        let reservation = Reservation(
            status: status,
            workshopID: workshopID,
            userID: userID
        )
//        reservation.$user.id = userID
//        reservation.$workshop.id = workshopID
        return reservation
    }
}
