//
//  LoginRequestDTO.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 01/10/2026.
//

import Vapor
import Fluent

struct LoginRequestDTO: Content {
    let email: String
    let password: String
}
