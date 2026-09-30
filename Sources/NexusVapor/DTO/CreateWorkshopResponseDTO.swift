//
//  GetWorkshopsList.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 30/09/2026.
//

import Vapor
import Fluent

struct CreateWorkshopResponseDTO: Content {
    var name : String
    var startTime: Date
    var endTime: Date
    var capacityMax: Int
    var totalSubscribers: Int
    var description : String
    var categoryID: UUID
    
    func ReservationtoModel() -> Workshop {
        let workshop = Workshop(
            name : name,
            startTime: startTime,
            endTime: endTime,
            capacityMax: capacityMax,
            totalSubscribers: totalSubscribers,
            description: description,
            categoryID: categoryID
        )
        // workshop.$category.id = categoryID
        return workshop
    }
}






