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
    @IBOutlet weak var lblNormalDelete: UILabel!
    @IBOutlet weak var lblRecords: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context : NSManagedObjectContext!
    let kMaxEntriesCount = 100000
    var totalRecords = 0
    //MARK:- View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        context = appDelegate.persistentContainer.viewContext
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.5)
    }
    
    
    //MARK:- Core Data Operations

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
    
    func fetchTotalRecordsCount() -> Int {
        let fetch: NSFetchRequest<Student> = Student.fetchRequest()
        let backgroundContext = self.appDelegate.persistentContainer.newBackgroundContext()
        var count = 0
        backgroundContext.performAndWait {
            count = try! self.appDelegate.persistentContainer.newBackgroundContext().count(for: fetch)
        }
        return count
    }
    
    
    
    
    
    //MARK:- Helpers

    func performOperationAndReturnTime(operation : () -> ()) -> String {
        
        let startDate = Date()
        operation()
        let timeInterval = Date().timeIntervalSince(startDate)
        let timeSpent = timeInterval.truncatingRemainder(dividingBy: 60)

        return String(format: "%0.4f sec", timeSpent)
        
    }
    
}

//MARK:- IBActions

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
            let _ = try? self.context.execute(request) as! NSBatchUpdateResult
        }
        
        lblRecords.text = "Batch Updated \n 👍"
        lblBatchUpdate.text = "\(timeSpent)"
    }
    
    
    @IBAction func btnNormalDelete(_ sender: Any) {
        
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
        lblRecords.text = "Normal Deleted \n ☠️"
        lblNormalDelete.text = "\(timeSpent)"
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
    
    
    @IBAction func btnAsyncFetchAction(_ sender: Any) {
        
        // Setting Progress to Zero
        progressView.progress = 0
        
        fetchAndUpdateProgreeBar()
    }
    
    func fetchAndUpdateProgreeBar() {
        
        do {
            // Fetch Total Records Count
             totalRecords = fetchTotalRecordsCount()
            print("\n\n *** Total Records: \(totalRecords) *** \n\n")
            // Creates a new `Progress` object
            let progress = Progress(totalUnitCount: 1)
            
            // Sets the new progess as default one in the current thread
            progress.becomeCurrent(withPendingUnitCount: 1)
            
            let fetch: NSFetchRequest<Student> = Student.fetchRequest()
            let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetch, completionBlock: nil)
            
            // Keeps a reference of `NSPersistentStoreAsynchronousResult` returned by `execute`
            let fetchResult = try self.appDelegate.persistentContainer.newBackgroundContext().execute(asynchronousFetchRequest) as? NSPersistentStoreAsynchronousResult
            
            // Resigns the current progress
            progress.resignCurrent()
            
            // Adds observer
            fetchResult?.progress?.addObserver(self, forKeyPath: #keyPath(Progress.completedUnitCount), options: .new, context: nil)
            
        } catch let error {
            print("NSAsynchronousFetchRequest error: \(error)")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(Progress.completedUnitCount),
            // Reads new value
            let newValue = change?[.newKey] as? Int {
            let fNewValue = Float(newValue)
            let fTotalRecords = Float(totalRecords)
            let progress = fNewValue / fTotalRecords
            
            print("\(newValue) / \(totalRecords) = \(progress)")
            
            DispatchQueue.main.async { [weak self] in
//                self?.progressView.progress = progress
                self?.progressView.setProgress(progress, animated: true)
            }
        }
    }
    
    
    
    @IBAction func btnResetAction(_ sender: Any) {
        if let lables = self.view.subviews.filter({$0 is UILabel}) as? [UILabel] {
            lables.forEach({$0.text = "– – – –"})
        }
        progressView.progress = 0
    }
}

