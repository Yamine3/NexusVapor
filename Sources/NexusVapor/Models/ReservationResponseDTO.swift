//
//  ReservationResponseDTO.swift
//  NexusVapor
//
//  Created by apprenant92 on 30/09/2026.
//

import Vapor

struct ReservationResponseDTO: Content {
    let id: UUID
    let status: ReservationStatus
}
