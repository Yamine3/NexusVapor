//
//  WorkshopAttendeeResponseDTO.swift
//  NexusVapor
//
//  Created by Apprenant 89 on 30/09/2026.
//

import Vapor
import Fluent

struct WorkshopAttendeeResponseDTO: Content {
    let reservationID: UUID
    let userID: UUID
    let name: String
    let email: String
    let status: ReservationStatus
}


