//
//  File.swift
//  NexusVapor
//
//  Created by apprenant92 on 30/09/2026.
//

import Fluent

struct CreateReservation: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema(Reservation.schema)
            .id()
            .field(
                "status",
                .string,
                .required
            )
            .field(
                "workshop_id",
                .uuid,
                .required,
                .references(Workshop.schema, "id")
            )
            .field(
                "user_id",
                .uuid,
                .required,
                .references(User.schema, "id")
            )
            .unique(on: "workshop_id", "user_id")
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(Reservation.schema)
            .delete()
    }
}
