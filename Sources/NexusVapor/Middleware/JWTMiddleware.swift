//
//  JWTMiddleware.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 01/10/2026.
//

import Vapor
import JWT

final class JWTMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        guard let token = request.headers.bearerAuthorization?.token else {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "pas de token"))
        }
       
        let signer = JWTSigner.hs256(key: Environment.get("SECRET_KEY")!)
        let payload : UserPayload
        
        do {
            payload = try signer.verify(String(token), as: UserPayload.self)
        } catch {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "invalid Token"))
        }
        
        request.auth.login(payload)
        return next.respond(to: request)
        
//        let signer = JWTS
    }
}
