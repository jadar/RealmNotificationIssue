//
//  ListViewController.swift
//  RealmCollectionCrash
//
//  Created by Jacob Rhoda on 4/21/22.
//

import UIKit
import RealmSwift

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
   
    var collection: Results<Animal>!
    var token: NotificationToken?
   
    override func viewDidLoad() {
        super.viewDidLoad()
      
        let realm = try! Realm()
        collection = realm.objects(Animal.self)
    }
    
    var backgroundQueue: DispatchQueue = DispatchQueue(label: "Break The Universe Queue")
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("Create observer")
        token = collection.observe({ [tableView] change in
            switch change {
            case .initial(let collection):
                print("Initial load with \(collection.count)")
                tableView!.reloadData()
            case .update(_, let deletions, let insertions, let updates):
                print("Update with \(deletions.count), \(insertions.count), \(updates.count)")
                tableView!.performBatchUpdates {
                    tableView!.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0)}, with: .automatic)
                    tableView!.insertRows(at: insertions.map { IndexPath(row: $0, section: 0)}, with: .automatic)
                    tableView!.reloadRows(at: updates.map { IndexPath(row: $0, section: 0)}, with: .automatic)
                }
            case .error(let error):
                print("Error: \(error)")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        // This appears to be necessary to trigger the issue. Without this, the issue doesn't happen until another write triggers the "delayed" update.
        // It doesn't matter if it happens "now" or in one second.
//        backgroundQueue.asyncAfter(deadline: .now() + .seconds(1)) {
        backgroundQueue.async {
            autoreleasepool {
                let backgroundRealm = try! Realm()
                try! backgroundRealm.write {
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
       
        print("Invalidate observer")
        token?.invalidate()
        token = nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collection.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = collection[indexPath.row].name
        return cell
    }
}
