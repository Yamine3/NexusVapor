//
//  UpdateWorkshopDTO.swift
//  NexusVapor
//
//  Created by Apprenant 89 on 30/09/2026.
//

import Vapor
import Fluent

struct UpdateWorkshopDTO: Content {
    let name: String
    let startTime: Date
    let endTime: Date
    let capacityMax: Int
    let description: String
    let categoryID: UUID
    
    func toModel() -> Workshop {
        let workshop = Workshop(
            name: name,
            startTime: startTime,
            endTime: endTime,
            capacityMax: capacityMax,
            totalSubscribers: 0,
            description: description,
            categoryID: categoryID
        )
//        workshop.$category.id = categoryID
        return workshop
    }
}
