//
//  GetWorkshopsList.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 30/09/2026.
//

import Vapor
import Fluent

struct GetWorkshopsDetailDTO: Content {
    var id: UUID
    var name : String
    var startTime: Date
    var endTime: Date
    var capacityMax: Int
    var totalSubscribers: Int
    var description : String
    var category: String
}
