//
//  UserController.swift
//  NexusVapor
//
//  Created by Apprenant 109 on 02/10/2026.
//
import Vapor
import Fluent
import JWT
import FluentSQL
import Gatekeeper

struct UserController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        
        //PUBLIC
        //POST /users
        users.post(use: create) //crée un nouvel utilisateur
        
        //POST /users/login + rate limiting
        let loginRoutes = users.grouped(GatekeeperMiddleware())
        
       loginRoutes.post("login", use: login) //connexion d'un utilisateur
        
        //Pour les utilisateurs authentifiés (festivalGoer + Staff)
        let protectedRoutes = users.grouped(JWTMiddleware())
        
        protectedRoutes.get("profile", use: profile)
        //accès aux infos d'un utilisateur
    }
    
    
    @Sendable
    func create(req:Request) async throws -> UserDTO {
        var newUser = try req.content.decode(CreateUserDTO.self)
        newUser.password = try Bcrypt.hash(newUser.password)
        let userToSave = newUser.toModel()
        try await userToSave.save(on: req.db)
        return userToSave.toDTO()
    }
    
    @Sendable
    func login(req:Request) async throws -> AuthDTO{
        let userRequest = try req.content.decode(LoginRequestDTO.self)
        
        guard let userDB = try await UserModel.query(on: req.db)
            .filter(\.$email == userRequest.email)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }
        
        guard try Bcrypt.verify(userRequest.password, created: userDB.password)
        else {
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }
        
        let payload = UserPayload(id: userDB.id!)
        
        let signer = JWTSigner.hs256(key: Environment.get("SECRET_KEY")!)
        
        let jwToken = try signer.sign(payload)
        
        return AuthDTO(token: jwToken)
    }
    
    @Sendable
    func profile(req: Request) async throws -> UserDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let userDB = try await UserModel.find(payload.id, on: req.db)
        else {
            throw Abort(.notFound, reason: "User does not exist.")
        }
        return userDB.toDTO()
    }

    /*
    @Sendable
    func getUserById(req: Request) async throws -> UserDTO {
        guard let userIdReq = req.parameters.get("userID") as UUID?
        else {
            throw Abort(.notFound, reason: "User does not exist.")
        }
        
        if let sql = req.db as? (any SQLDatabase) {
            let users = try await sql.raw("SELECT * FROM utilisateurs WHERE id = \(bind: userIdReq)")
                .all(decodingFluent: UserModel.self)
            
            guard let foundUser = users.first
            else {
                throw Abort(.notFound, reason: "User not found.")
            }
            
            return foundUser.toDTO()
        }
        
        throw Abort(.internalServerError, reason: "The data base is not of type SQL.")
    }
    
*/
}
