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
    let workshop: GetWorkshopsListResponseDTO
    let status: ReservationStatus
}
