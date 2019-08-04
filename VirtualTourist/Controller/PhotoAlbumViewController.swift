//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/21/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet var photoCollection: UICollectionView!
    @IBOutlet weak var photoCollectionFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var photoAlbumDataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<PhotosAssociatedWithPin>!
    var pin: Pin!
    let virtualTouristClient = VirtualTouristClient()
    let collectionViewCellsCount: Int = 21
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        photoCollection.allowsMultipleSelection = true // Multiple images can be selected to remove
        setUpCollectionViewFlowLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        downloadPhotoMetadata()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    @IBAction func removeImages(_ sender: Any) {
        if newCollectionButton.currentTitle == "New Collection" {
            removeExistingImages()
            downloadPhotoMetadata()
        } else {
            removeSelectedImages()
        }
        configureButtonText()
    }
    
    // MARK: Configuring the space between cells in collection view
    private func setUpCollectionViewFlowLayout() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        photoCollectionFlowLayout.minimumInteritemSpacing = space
        photoCollectionFlowLayout.minimumLineSpacing = space
        photoCollectionFlowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    // MARK: Setting up fetched results controller
    private func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<PhotosAssociatedWithPin> = PhotosAssociatedWithPin.fetchRequest()
        
        if let pin = pin {
            let predicate = NSPredicate(format: "pin == %@", pin)
            fetchRequest.predicate = predicate
        }
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: photoAlbumDataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("PhotoAlbumVC: Unable to fetch the results")
        }
    }
    
    // MARK: Removes all the existing images for the current location
    private func removeExistingImages() {
        if let removeImages = fetchedResultsController.fetchedObjects {
            for image in removeImages {
                photoAlbumDataController.viewContext.delete(image)
                do {
                    try photoAlbumDataController.viewContext.save()
                } catch {
                    print("Unable to delete images")
                }
            }
        }
    }
    
    // MARK: Remove selected images for the current location
    private func removeSelectedImages() {
        var imageIds: [String] = []
        
        // All the index paths for the selected images are returned
        if let selectedImagesIndexPaths = photoCollection.indexPathsForSelectedItems {
            for indexPath in selectedImagesIndexPaths {
                let selectedImageToRemove = fetchedResultsController.object(at: indexPath)
                
                if let imageId = selectedImageToRemove.imageId {
                    imageIds.append(imageId)
                }
            }
            
            for imageId in imageIds {
                if let selectedImages = fetchedResultsController.fetchedObjects {
                    for image in selectedImages {
                        if image.imageId == imageId {
                            photoAlbumDataController.viewContext.delete(image)
                        }
                        do {
                            try photoAlbumDataController.viewContext.save()
                            newCollectionButton.titleLabel?.text = "New Collection"
                        } catch {
                            print("Unable to remove the photo")
                        }
                    }
                }
            }
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // providing default cell count in case no images are present
        return fetchedResultsController.sections?[section].numberOfObjects ?? collectionViewCellsCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //print("this is called")
        let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomPhotoAlbum", for: indexPath) as! PhotoAlbumCustomCell
        
        guard !(self.fetchedResultsController.fetchedObjects?.isEmpty)! else {
            print("images are already present.")
            return photoCell
        }
        
        let photo = self.fetchedResultsController.object(at: indexPath)
        
        if photo.imageData == nil {
            newCollectionButton.isEnabled = false // User cannot interact with it when downloading images
            photoCell.imageOverlay.backgroundColor = UIColor.customColor(red: 242, green: 242, blue: 254, alpha: 0.85)
            photoCell.imageLoadingIndicator.startAnimating()
            DispatchQueue.global(qos: .background).async {
                if let imageData = try? Data(contentsOf: photo.imageURL!) {
                    DispatchQueue.main.async {
                        photo.imageData = imageData
                        do {
                            try self.photoAlbumDataController.viewContext.save()
                        } catch {
                            print("error in saving image data")
                        }
                        let image = UIImage(data: imageData)
                        print("index is : \(indexPath.row)")
                        photoCell.selectedLatLongImage.image = image
                        photoCell.imageOverlay.backgroundColor = UIColor.customColor(red: 255, green: 255, blue: 255, alpha: 0)
                        photoCell.imageLoadingIndicator.stopAnimating()
                    }
                }
            }
        } else {
            if let imageData = photo.imageData {
                let image = UIImage(data: imageData)
                photoCell.selectedLatLongImage.image =  image
                photoCell.imageOverlay.backgroundColor = UIColor.customColor(red: 255, green: 255, blue: 255, alpha: 0)
                photoCell.imageLoadingIndicator.stopAnimating()
            }
        }
        newCollectionButton.isEnabled = true
        return photoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        configureSelectionUI(collectionView: collectionView, indexPath: indexPath, isSelected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        configureSelectionUI(collectionView: collectionView, indexPath: indexPath, isSelected: false)
    }
    
    private func downloadPhotoMetadata() {
        guard (fetchedResultsController.fetchedObjects?.isEmpty)! else {
            print("image metadata is already present. no need to re download")
            return
        }
        
        print("About to start downloading of images metadata")
        
        virtualTouristClient.getPhotosForLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude, completionHandler: handleDownloadPhotoResponse(totalNumberOfPages:message:))
    }
    
    private func handleDownloadPhotoResponse(totalNumberOfPages: Int?, message: String?) {
        if let message = message {
            displayError(message: message)
            return
        }
        
        var downloadedImagesCount = 0
        
        print("Need to fetch as many images as cells")
        while downloadedImagesCount <= collectionViewCellsCount {
            if let totalNumberOfPages = totalNumberOfPages {
                print("Fetched images metadata successfully. Need to generate image URL now")
                let randomPageNumber = arc4random_uniform(UInt32(totalNumberOfPages))
                
                virtualTouristClient.getPhotosForLocationWithRandomPageNumber(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude, dataController: photoAlbumDataController, pin: pin, randomPageNumber: Int(randomPageNumber), completionHandler: { (success, error) in
                    if let _ = success {
                        print("Reloading photo collection")
                        DispatchQueue.main.async {
                            self.photoCollection.reloadData()
                        }
                    }
                })
            }
            downloadedImagesCount += 1
        }
    }
    
    private func configureButtonText() {
        if photoCollection.indexPathsForSelectedItems!.isEmpty {
            newCollectionButton.setTitle("New Collection", for: .normal)
        } else {
            newCollectionButton.setTitle("Remove", for: .normal)
        }
    }
    
    private func configureSelectionUI(collectionView: UICollectionView, indexPath: IndexPath, isSelected: Bool) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoAlbumCustomCell
        if isSelected {
            cell.imageOverlay.backgroundColor = UIColor.customColor(red: 242, green: 242, blue: 254, alpha: 0.85)
        } else {
            cell.imageOverlay.backgroundColor = UIColor.customColor(red: 255, green: 255, blue: 255, alpha: 0)
        }
        configureButtonText()
    }
    
    private func displayError(message: String) {
        let alertVC = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        DispatchQueue.main.async {
            self.present(alertVC, animated: true, completion: nil)
        }
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photoCollection.insertItems(at: [newIndexPath!])
        case .delete:
            photoCollection.deleteItems(at: [indexPath!])
        case .update:
            photoCollection.reloadItems(at: [newIndexPath!])
        default:
            break
        }
    }
}
