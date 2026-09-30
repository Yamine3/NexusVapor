//
//  GetReservationListItemRequestDTO.swift
//  NexusVapor
//
//  Created by Apprenant 89 on 30/09/2026.
//

import Vapor
import Fluent

struct GetReservationListItemResponseDTO: Content {
    let id: UUID
    let workshopID: UUID
    let workshopName: String
    let category: String
    let startTime: Date
    let endTime: Date
    let maxCapacity: Int
    let status: ReservationStatus
}

