//
//  CategoryDTO.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 29/10/2026.
//


import Vapor
import Fluent

struct CategoryDTO: Content {
    var id: UUID?
    var name: String
}

extension CategoryDTO {
    func toModel() -> CategoryModel {
        return CategoryModel(name: name)
    }
}
