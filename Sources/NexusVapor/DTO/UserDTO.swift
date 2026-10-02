//
//  UserDTO.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 01/10/2026.
//

import Fluent
import Vapor

struct UserDTO: Content {
    let id: UUID?
    let name: String
    let email: String
}

extension UserDTO {
    func toModel() -> UserModel {
        return UserModel(
            id: id,
            name: name,
            password: "default",
            email: email,
            role: Role.festivalGoer,
            creationDate: Date(),
        )
    }
}

