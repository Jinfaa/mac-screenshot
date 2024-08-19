import Cocoa

class HistoryViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    let collectionView: NSCollectionView = NSCollectionView()
    
    var imagePaths: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        fetchImagePaths()
    }
    
    func fetchImagePaths() {
        imagePaths = CoreDataManager.shared.fetchImagePaths()
        collectionView.reloadData()
    }
    
    func setupCollectionView() {
        let layout = NSCollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        collectionView.collectionViewLayout = layout
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            collectionView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        collectionView.register(HistoryItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("HistoryItem"))
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    // Реализация метода для динамического расчета размера элементов
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let width = collectionView.bounds.width - 40 // Учитываем отступы
        return NSSize(width: width, height: 120)
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagePaths.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("HistoryItem"), for: indexPath) as! HistoryItem
        let imagePath = imagePaths[indexPath.item]
        let path = imagePath.value(forKey: "path") as! String
        let description = imagePath.value(forKey: "desc") as! String
        
        item.imageView?.image = NSImage(contentsOfFile: path)
        item.textField?.stringValue = description
        
        return item
    }
}
