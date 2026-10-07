//
//  User.swift
//  NexusVapor
//
//  Created by apprenant92 on 30/09/2026.
//

import Fluent
import Vapor

final class UserModel: Model, Content, @unchecked Sendable {
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name : String
    
    @Field(key: "password")
    var password : String
    
    @Field(key: "email")
    var email : String
    
    @Enum(key: "role")
    var role : Role
    
    @Field(key: "creation_date")
    var creationDate: Date
    
    @Children(for: \.$user)
    var reservations : [Reservation]
        
    init()  {}
    
    init(
        id: UUID? = nil,
        name: String,
        password: String,
        email: String,
        role: Role?,
        creationDate: Date?
        
    ) {
        self.id = id
        self.name = name
        self.password = password
        self.email = email
        self.role = role ?? Role.festivalGoer
        self.creationDate = creationDate ?? Date()
    }
}

enum Role: String, Codable {
    case staff
    case festivalGoer
}


extension UserModel {
    func toDTO() -> UserDTO {
        return UserDTO(id: id, name: name, email: email)
    }
}
