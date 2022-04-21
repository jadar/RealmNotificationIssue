//
//  ViewController.swift
//  RealmCollectionCrash
//
//  Created by Jacob Rhoda on 4/21/22.
//

import UIKit
import RealmSwift

class Animal: Object {
    @Persisted var name: String = ""
   
    override init() {
    }
    
    init(_ json: Animals._Animal) {
        name = json.common
    }
}

struct Animals: Codable {
    struct _Animal: Codable {
        var common: String
        var family: String
        var id: Int
        var text: String?
    }
    
    var animals: [String: _Animal]
}

class ViewController: UIViewController {

    var realm = try! Realm()
   
    lazy var results = realm.objects(Animal.self)
    
    var backgroundQueue: DispatchQueue = DispatchQueue(label: "Import Queue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction
    func hydratePressed(_ sender: Any) {
        backgroundQueue.async {
            autoreleasepool {
                let url = Bundle.main.url(forResource: "Animals", withExtension: "json")!
                let data = try! Data(contentsOf: url)
                let jsonDecoder = JSONDecoder()
                let animals = try! jsonDecoder.decode(Animals.self, from: data)
                
                let backgroundRealm = try! Realm()
                try! backgroundRealm.write {
                    for jsonAnimal in animals.animals.values {
                        let animal = Animal(jsonAnimal)
                        backgroundRealm.add(animal)
                    }
                }
            }
        }
    }
    
    @IBAction
    func deletePressed(_ sender: Any) {
        backgroundQueue.async {
            autoreleasepool {
                let backgroundRealm = try! Realm()
                try! backgroundRealm.write {
                    backgroundRealm.deleteAll()
                }
            }
        }
    }
}

