//
//  CreateUser.swift
//  NexusVapor
//
//  Created by apprenant92 on 30/09/2026.
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema(User.schema)
            .id()
            .field(
                "name",
                .string,
                .required
            )
            .field(
                "password",
                .string,
                .required
            )
            .field(
                "email",
                .string,
                .required
            )
            .field(
                "role",
                .string,
                .required
            )
            .field(
                "creation_date",
                .string,
                .required
            )
        
    }
    func revert(on database: any Database) async throws {
        try await database
            .schema(User.schema)
            .delete()
    }
}
