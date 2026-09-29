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
    var start_time : Date
    
    @Field(key: "end_time")
    var end_time : Date
    
    @Field(key: "capacity_max")
    var capacity_max : Int
    
    @Field(key: "total_subscribers")
    var total_subscribers : Int
    
    @Field(key: "description")
    var description: String
    
    @Parent(key: "category_id")
    var category : Category
    
    @Children(for: \.$workshop)
    var reservations : [Reservation]
    
    init() {}
    
    
    init(
        id:UUID? = nil,
        name: String,
        category_id: UUID,
        start_time: Date,
        end_time: Date,
        capacity_max: Int,
        total_subscribers: Int,
        description: String

    ) {
        self.id = id
        self.name = name
        self.$category.id = category_id
        self.start_time = start_time
        self.end_time = end_time
        self.capacity_max = capacity_max
        self.total_subscribers = total_subscribers
        self.total_subscribers = total_subscribers
        self.description = description

        
    }
    
    
    
}

