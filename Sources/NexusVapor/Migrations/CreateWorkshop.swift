//
//  CreateWorkshop.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 29/09/2026.
//

import Fluent
struct CreateWorkshop: AsyncMigration {
    func prepare (on database: any Database) async throws {
        try await database
            .schema(Workshop.schema)
            .id()
            .field(
                "name",
                .string,
                .required
            )
            .field(
                "start_time",
                .date,
                .required
            )
            .field(
                "end_time",
                .date,
                .required
            )
            .field(
                "capacity_max",
                .int,
                .required
            )
            .field(
                "total_subscribers",
                .int,
                .required
            )
            .field(
                "description",
                .string,
                .required
            )
            .field(
                "category_id",
                .uuid,
                .required,
                .references(Category.schema, "id")
            )
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(Workshop.schema)
            .delete()
    }
    
}
