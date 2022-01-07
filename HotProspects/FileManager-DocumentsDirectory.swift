//
//  FileManager-DocumentsDirectory.swift
//  BucketList
//
//  Created by Heath Fashina on 2021-12-17.
//

import Foundation

extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
