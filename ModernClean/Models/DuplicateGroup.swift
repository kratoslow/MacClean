//
//  DuplicateGroup.swift
//  ModernClean
//
//  Model representing a group of duplicate files

import Foundation

struct DuplicateGroup: Identifiable, Hashable {
    let id: UUID
    let hash: String
    let size: Int64
    var files: [ScannedFile]
    
    init(hash: String, size: Int64, files: [ScannedFile]) {
        self.id = UUID()
        self.hash = hash
        self.size = size
        self.files = files
    }
    
    /// Total space that could be saved by removing all but one duplicate
    var potentialSavings: Int64 {
        return size * Int64(files.count - 1)
    }
    
    /// Number of duplicate copies (excludes original)
    var duplicateCount: Int {
        return files.count - 1
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DuplicateGroup, rhs: DuplicateGroup) -> Bool {
        lhs.id == rhs.id
    }
}

