//
//  CreateUserDTO.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 02/10/2026.
//

import Vapor

struct CreateUserDTO: Content {
    let name: String
    let email: String
    var password: String
}

extension CreateUserDTO {
    func toModel() -> UserModel {
        return UserModel (
            id: nil,
            name: name,
            password: password,
            email: email,
            role: Role.festivalGoer,
            creationDate: Date()
        )
    }
}
