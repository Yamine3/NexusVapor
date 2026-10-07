//
//  GetWorkshopsList.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 30/09/2026.
//

import Vapor
import Fluent

struct CreateWorkshopDTO: Content {
    var name : String
    var startTime: Date
    var endTime: Date
    var capacityMax: Int
//    var totalSubscribers: Int
    //parce que c'est pas au frontend d'envoyer "totalSubscribers", mais au backend de lui indiquer
    var description : String
    var categoryID: UUID
    
    func convertToWorshop() -> Workshop {
        let workshop = Workshop(
            name : name,
            startTime: startTime,
            endTime: endTime,
            capacityMax: capacityMax,
            totalSubscribers: 0,
            description: description,
            categoryID: categoryID
        )
        // workshop.$category.id = categoryID
        return workshop
    }
}






