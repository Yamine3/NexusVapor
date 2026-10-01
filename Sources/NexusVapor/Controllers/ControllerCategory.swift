//
//  ControllerCategory.swift
//  NexusVapor
//
//  Created by Apprenant 89 on 30/09/2026.
//

import Fluent
import Vapor

struct ControllerCategory: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let categories = routes.grouped("categories")
        categories.get(use: index)
        categories.post(use: create)
    }
    
    func index(req: Request) async throws -> [Category] {
        return try await Category
            .query(on: req.db)
            .all()
    }
    
    func create(req: Request) async throws -> Category {
        let category = try req.content.decode(Category.self)
        try await category.create(on: req.db)
        return category
    }
    
    
}
