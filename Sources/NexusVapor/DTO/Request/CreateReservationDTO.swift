//
//  CreateReservationRequestDTO.swift
//  NexusVapor
//
//  Created by apprenant92 on 30/09/2026.
//

import Vapor
import Fluent

struct CreateReservationDTO: Content {
//    let status: ReservationStatus
    //statut ne vient pas du front
    let workshopID: UUID
    let userID: UUID
        //le backend devrait connaître l'utilisateur qui fait la request quand on fera le JWT
    
//    func convertToReservation() -> Reservation {
//        let reservation = Reservation(
//           status: status,
//            workshopID: workshopID,
//            userID: userID
//        )
//        return reservation
//    }
}
