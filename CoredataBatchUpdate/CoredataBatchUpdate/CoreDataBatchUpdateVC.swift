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
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let kMaxEntriesCount = 10000
    
    //MARK:- View Controller Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        print(appDel.persistentContainer.persistentStoreDescriptions.first!.url?.absoluteString ?? "😡 Store not found")
    }
    
    
    func updateRecord(text:String) {
        if Thread.isMainThread {
            self.lblRecords.text = text
        }
        else {
            DispatchQueue.main.async {
                self.lblRecords.text = text
            }
        }
    }
    
    
    func insertRecordsInBackground() {
        
        self.appDel.persistentContainer.performBackgroundTask({ context in
            for _ in 1...self.kMaxEntriesCount {
                if let student = NSEntityDescription.insertNewObject(forEntityName: "Student", into: context) as? Student {
                    student.firstName = "New Firstname"
                    student.lastName = "New lastname"
                }
            }
            try? context.save()
        })
    }
    

    func fetchInBackground() -> String {
        
        let bkContext = self.appDel.persistentContainer.newBackgroundContext()
        var results = 0
        var timeSpent = ""
        bkContext.performAndWait { [unowned self] in
            
            timeSpent = self.performOperationAndReturnTime {
                let fetch: NSFetchRequest<Student> = Student.fetchRequest()
                results = try! bkContext.count(for: fetch)
            }
        }
        return "\(results) records in \(timeSpent)"
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

    @discardableResult
    func performOperationAndReturnTime(operation : () -> ()) -> String {
        
        let startDate = Date()
        operation()
        let timeInterval = Date().timeIntervalSince(startDate)
        let timeSpent = timeInterval.truncatingRemainder(dividingBy: 60)

        return String(format: "%0.4f sec", timeSpent)
        
    }
    
    
    
    //MARK:- IBActions -
    
    @IBAction func btnInsertAction() {
        
        updateRecord(text: "Inserting ...")
        insertRecordsInBackground()
        updateRecord(text: "Inserted \n 👍")
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
                self.appDel.saveContext()
            }
            catch {
                
            }
        }
        updateRecord(text: "Normal Updated \n 👍")

        lblNormalUpdate.text = "\(timeSpent)"
    }
    

    

    @IBAction func btnBatchUpdateAction(_ sender: Any) {

        let timeSpent = performOperationAndReturnTime {[unowned self] in
            
            let request = NSBatchUpdateRequest(entityName: "Student")
            request.propertiesToUpdate = ["firstName" : "BatchFN" , "lastName" : "BatchLN"]
            request.resultType = .updatedObjectsCountResultType
            let result = try? self.context.execute(request) as! NSBatchUpdateResult
            print(result?.result! ?? "")
        }

        updateRecord(text: "Batch Updated \n 👍")
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
            
                self.appDel.saveContext()
            }
            catch {
                
            }
        }
        updateRecord(text: "Plain Deleted \n ☠️")
        lblPlainDelete.text = "\(timeSpent)"
    }
    
    
    @IBAction func btnBatchDeleteAction(_ sender: Any) {
        print(appDel.persistentContainer.description)

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
        updateRecord(text: "Batch Deleted \n ☠️")
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

