//
//  ViewController.swift
//  CoredataBatchUpdate
//
//  Created by Abhishek Bedi on 4/7/17.
//  Copyright © 2017 abhishekbedi. All rights reserved.
//

import UIKit
import CoreData

class CoreDataBatchUpdateVC: UIViewController {

    /// IBOutlets
    @IBOutlet weak var lblNormalUpdate: UILabel!
    @IBOutlet weak var lblBatchUpdate: UILabel!
    @IBOutlet weak var lblBatchDelete: UILabel!
    @IBOutlet weak var lblPlainDelete: UILabel!
    @IBOutlet weak var lblRecords: UILabel!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context : NSManagedObjectContext!
    let kMaxEntriesCount = 10000
    
    //MARK:- View Controller Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        context = appDelegate.persistentContainer.viewContext
    }
    
    
    //MARK:- Core Data Operations -

    func insertRecordsInBackground() {
        
        self.appDelegate.persistentContainer.performBackgroundTask({ context in
            for _ in 1...self.kMaxEntriesCount {
                if let student = NSEntityDescription.insertNewObject(forEntityName: "Student", into: context) as? Student {
                    student.firstName = "New Firstname"
                    student.lastName = "New lastname"
                }
            }
            try? context.save()
        })
    }

    func fetch() -> String {
        var results = 0
        
        let timeSpent = performOperationAndReturnTime {[unowned self] in
            let fetch: NSFetchRequest<Student> = Student.fetchRequest()
            results = try! self.context.count(for: fetch)
        }
        
        return "\(results) records \n in \n\(timeSpent)"
    }

    
    
    
    //MARK:- Helpers -

    func performOperationAndReturnTime(operation : () -> ()) -> String {
        
        let startDate = Date()
        operation()
        let timeInterval = Date().timeIntervalSince(startDate)
        let timeSpent = timeInterval.truncatingRemainder(dividingBy: 60)

        return String(format: "%0.4f sec", timeSpent)
        
    }
    
}

extension CoreDataBatchUpdateVC {
    @IBAction func btnInsertAction() {
        
        insertRecordsInBackground()
        lblRecords.text = "Inserted \n 👍"
    }
    
    @IBAction func btnNormalUpdateAction(_ sender: Any) {
        
        let timeSpent = performOperationAndReturnTime {[unowned self] in
            
            let fetch: NSFetchRequest<Student> = Student.fetchRequest()
            
            do {
                let results = try self.context.fetch(fetch)
                for s in results {
                    s.firstName = "A"
                    s.lastName = "B"
                }
                self.appDelegate.saveContext()
            }
            catch {
                
            }
        }
        lblRecords.text = "Normal Updated \n 👍"
        lblNormalUpdate.text = "\(timeSpent)"
    }
    
    
    @IBAction func btnBatchUpdateAction(_ sender: Any) {
        
        let timeSpent = performOperationAndReturnTime {[unowned self] in
            
            let request = NSBatchUpdateRequest(entityName: "Student")
            request.propertiesToUpdate = ["firstName" : "BatchFN" , "lastName" : "BatchLN"]
            request.resultType = .updatedObjectsCountResultType
            let result = try? self.context.execute(request) as! NSBatchUpdateResult
        }
        
        lblRecords.text = "Batch Updated \n 👍"
        lblBatchUpdate.text = "\(timeSpent)"
    }
    
    
    @IBAction func btnPlainDelete(_ sender: Any) {
        
        let timeSpent = performOperationAndReturnTime {[unowned self] in
            
            let fetch: NSFetchRequest<Student> = Student.fetchRequest()
            
            do {
                let results = try self.context.fetch(fetch)
                for r in results {
                    self.context.delete(r)
                }
                
                self.appDelegate.saveContext()
            }
            catch {
                
            }
        }
        lblRecords.text = "Plain Deleted \n ☠️"
        lblPlainDelete.text = "\(timeSpent)"
    }
    
    
    @IBAction func btnBatchDeleteAction(_ sender: Any) {
        
        let timeSpent = performOperationAndReturnTime {[unowned self] in
            
            let fetch: NSFetchRequest<Student> = Student.fetchRequest()
            fetch.resultType = .countResultType
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch as! NSFetchRequest<NSFetchRequestResult>)
            
            do {
                try self.context.execute(deleteRequest)
                try self.context.save()
            } catch {
                print ("There was an error")
            }
        }
        lblRecords.text = "Batch Deleted \n ☠️"
        lblBatchDelete.text = "\(timeSpent)"
    }
    
    
    @IBAction func btnFetchAction(_ sender: Any) {
        lblRecords.text = fetch()
    }
    
    
    @IBAction func btnResetAction(_ sender: Any) {
        if let lables = self.view.subviews.filter({$0 is UILabel}) as? [UILabel] {
            lables.forEach({$0.text = "– – – –"})
        }
    }
}

