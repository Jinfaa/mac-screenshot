import Cocoa
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    let persistentContainer: NSPersistentContainer = NSPersistentContainer(name: "ScreenshotCodename")
    
    private init() {
        initializeCoreData()
    }
    
    private func initializeCoreData() {
        persistentContainer.loadPersistentStores { (storeDescription, error) in }
    }
    
    func saveImagePath(_ path: String, description: String, timestamp: Date) {
        let context = persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "ImagePath", in: context) else { return }
        let newPath = NSManagedObject(entity: entity, insertInto: context)
        newPath.setValue(path, forKey: "path")
        newPath.setValue(description, forKey: "desc")
        newPath.setValue(timestamp, forKey: "timestamp")
        
        do {
            try context.save()
        } catch {
           
        }
    }
    
    func fetchImagePaths() -> [NSManagedObject] {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ImagePath")
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            return []
        }
    }
}
