//
//  GetWorkshopsList.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 30/09/2026.
//

import Vapor
import Fluent

struct GetWorkshopsListResponseDTO: Content {
    var id: UUID
    var name : String
    var startTime: Date
    var endTime: Date
    var capacityMax: Int
//    var totalSubscribers: Int
    //pas besoin du total subscribers pour l'écran
    let remainingPlaces: Int
    //pour que l'API donne la donnée 
    var category: String
}
