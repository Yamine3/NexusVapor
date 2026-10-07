//
//  EnsureStaffMiddleware.swift
//  NexusVapor
//
//  Created by Apprenant 89 on 06/10/2026.
//

import Vapor
import Fluent

struct EnsureStaffMiddleware: AsyncMiddleware {
    
    func respond(
        to request: Request,
        chainingTo next: any AsyncResponder
    ) async throws -> Response {
        
        guard let payload = request.auth.get(UserPayload.self) else {
            throw Abort(.unauthorized)
        }
        
        guard let user = try await UserModel.find(
            payload.id,
            on: request.db
        ) else {
            throw Abort(.unauthorized)
        }
        
        guard user.role == .staff else {
            throw Abort(
                .forbidden,
                reason: "Only staff members are allowed."
            )
        }
        
        return try await next.respond(to: request)
    }
}
