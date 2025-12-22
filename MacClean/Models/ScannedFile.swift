//
//  ScannedFile.swift
//  MacClean
//

import Foundation

struct ScannedFile: Identifiable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let size: Int64
    let isDirectory: Bool
    let modifiedDate: Date?
    let createdDate: Date?
    
    init(url: URL, size: Int64, isDirectory: Bool, modifiedDate: Date? = nil, createdDate: Date? = nil) {
        self.id = UUID()
        self.name = url.lastPathComponent
        self.path = url.path
        self.size = size
        self.isDirectory = isDirectory
        self.modifiedDate = modifiedDate
        self.createdDate = createdDate
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ScannedFile, rhs: ScannedFile) -> Bool {
        lhs.id == rhs.id
    }
}

