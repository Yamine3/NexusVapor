//
//  Workshops.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 29/09/2026.
//


import Fluent
import Vapor
final class Workshop: Model, Content , @unchecked Sendable {
    
    static let schema = "workshops"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name : String
    
    @Field(key: "start_time")
    var startTime : Date
    
    @Field(key: "end_time")
    var endTime : Date
    
    @Field(key: "capacity_max")
    var capacityMax : Int
    
    @Field(key: "total_subscribers")
    var totalSubscribers : Int
    
    @Field(key: "description")
    var description: String
    
    @Parent(key: "category_id")
    var category : Category
    
    @Siblings(
        through: Reservation.self,
        from: \.$workshop,
        to: \.$user
    )
    var users : [User]
    
    init() {}
    
    init(
        id: UUID? = nil,
        name: String,
        startTime: Date,
        endTime: Date,
        capacityMax: Int,
        totalSubscribers: Int,
        description: String,
        categoryID: UUID,
        
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.capacityMax = capacityMax
        self.totalSubscribers = totalSubscribers
        self.description = description
        self.$category.id = categoryID
        
    }

}

