//
//  Student+CoreDataProperties.swift
//  CoredataBatchUpdate
//
//  Created by Abhishek Bedi on 4/8/17.
//  Copyright © 2017 abhishekbedi. All rights reserved.
//

import Foundation
import CoreData


extension Student {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Student> {
        return NSFetchRequest<Student>(entityName: "Student")
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?

}
