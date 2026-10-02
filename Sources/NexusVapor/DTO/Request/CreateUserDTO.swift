//
//  CreateUserDTO.swift
//  NexusVapor
//
//  Created by AymTek.
//

import Vapor

struct CreateUserDTO: Content {
    let name: String
    let email: String
    let password: String
    let role: String
    }
