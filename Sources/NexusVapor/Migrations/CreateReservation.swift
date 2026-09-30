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
                "worshop_id",
                .uuid,
                .required,
                .references(Reservation.schema, "id")
            )
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(Reservation.schema)
            .delete()
    }
}
