//
//  VirtualTouristClient.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/22/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import Foundation
import CoreData

class VirtualTouristClient {
    enum EndPoints {
        static let base = "https://api.flickr.com/services/rest/?method=flickr.photos.search"
        static let fetchImage = "https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg"
        
        case fetchPhotos(Double, Double)
        case fetchPhotosWithPageNumber(Double, Double, Int)
        case fetchImageFromMetadata(Int, String, String, String)
        
        var stringValue: String {
            switch self {
            case .fetchPhotos(let lat, let lon):
                return EndPoints.base + "&api_key=\(APIKeys.apiKey)" + "&lat=\(lat)&lon=\(lon)&format=json"
            case .fetchPhotosWithPageNumber(let lat, let lon, let pageNumber):
                return EndPoints.base + "&api_key=\(APIKeys.apiKey)" + "&lat=\(lat)&lon=\(lon)&page=\(pageNumber)&format=json"
            case .fetchImageFromMetadata(let farmId, let serverId, let photoId, let secret):
                return "https://farm\(farmId).staticflickr.com/\(serverId)/\(photoId)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    // MARK : Fetches the photos metadata that is used to fetch the image
    func getPhotosForLocation(latitude: Double, longitude: Double, completionHandler: @escaping(Int?, String?) -> Void) {
        let request = URLRequest(url: EndPoints.fetchPhotos(latitude,longitude).url)
        
        print("Photos for Location request is : \(request)")
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                completionHandler(nil, error?.localizedDescription)
            }
            
            guard let data = data else {
                print("unable to get the metadata")
                DispatchQueue.main.async {
                    completionHandler(nil, error?.localizedDescription)
                }
                return
            }
            
            guard let httpStatusCode = (response as? HTTPURLResponse)?.statusCode else {
                print("No http code is returned")
                return
            }
            
            if(httpStatusCode >= 200 && httpStatusCode < 300) {
                
                // generating a new data by removing additional characters that are contained in the response
                var newData = data.subdata(in: 14..<data.count)
                newData.remove(at: newData.endIndex - 1)
                
                //print("\(String(data: newData, encoding: .utf8) ?? "\"parsing error\"")")
                
                let decoder = JSONDecoder()
                do {
                    let photo = try decoder.decode(PhotosForLocationResponse.self, from: newData)
                    DispatchQueue.main.async {
                        completionHandler(photo.photoData.photoMetadata.count, nil)
                    }
                } catch {
                    print(error)
                }
            } else {
                switch httpStatusCode {
                case 2:
                    completionHandler(nil, httpStatusCode.description)
                    break
                case 10:
                    completionHandler(nil, httpStatusCode.description)
                    break
                case 100:
                    completionHandler(nil, httpStatusCode.description)
                    break
                case 116:
                    completionHandler(nil, httpStatusCode.description)
                    break
                default:
                    completionHandler(nil, httpStatusCode.description)
                }
            }
        }
        dataTask.resume()
    }
    
    func getPhotosForLocationWithRandomPageNumber(latitude: Double, longitude: Double, dataController: DataController, pin: Pin, randomPageNumber: Int, completionHandler: @escaping(Bool?, Error?) -> Void) {
        let request = URLRequest(url: EndPoints.fetchPhotosWithPageNumber(latitude, longitude, randomPageNumber).url)
        
        //print("request is : \(request)")
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            // generating a new data by removing additional characters that are contained in the response
            var newData = data.subdata(in: 14..<data.count)
            newData.remove(at: newData.endIndex - 1)
            
            //print("\(String(data: newData, encoding: .utf8) ?? "\"parsing error\"")")
            
            let decoder = JSONDecoder()
            do {
                let photo = try decoder.decode(PhotosForLocationResponse.self, from: newData)
                
                let metaData = photo.photoData.photoMetadata[randomPageNumber]
                
                self.generateImageURLFromMetadata(farmId: metaData.farm, serverId: metaData.server, photoId: metaData.id, secret: metaData.secret, dataController: dataController, pin: pin, completionHandler: { (data, error) in
                    if let data = data {
                        //print("persisting images")
                        
                    }
                })
            } catch {
                print(error)
            }
        }
        dataTask.resume()
    }
    
    private func generateImageURLFromMetadata(farmId: Int, serverId: String, photoId: String, secret: String, dataController: DataController, pin: Pin, completionHandler: @escaping(Data?, Error?) -> Void) {
        let request = URLRequest(url: EndPoints.fetchImageFromMetadata(farmId, serverId, photoId, secret).url)
        
        //print("request is : \(request)")
        DispatchQueue.main.async {
            self.persistImageURL(data: nil, imageURL: EndPoints.fetchImageFromMetadata(farmId, serverId, photoId, secret).url, dataController: dataController, pin: pin)
        }
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(data, nil)
            }
        }
        dataTask.resume()
    }
    
    private func persistImageURL(data: Data?, imageURL: URL, dataController: DataController, pin: Pin) {
        let photo = PhotosAssociatedWithPin(context: dataController.viewContext)
        
        photo.creationDate = Date()
        photo.imageURL = imageURL
        photo.imageData = nil
        photo.pin = pin
        photo.imageId = UUID().uuidString
        
        do {
            try dataController.viewContext.save()
        } catch {
            print("Unable to save the photo")
        }
    }
}
