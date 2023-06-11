//
//  ViewController.swift
//  History Places
//
//  Created by ilya on 10/06/2023.
//

import UIKit
import YandexMapsMobile
import VisionKit

struct Place: Codable {
    var id: Int
    var latitude: Double
    var longitude: Double
    var title: String
    var description: String
    var address: String
}

class ViewController: UIViewController {
    
    var scannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
    
    let CAMERA_TARGET = YMKPoint(latitude: 43.592812, longitude: 39.977536)
    
    
    @IBAction func startScanningPressed(_ sender: Any) {
        guard scannerAvailable == true else {
            print("Error: Scanner is not available for usage. Please check settings.")
            return
        }
        
        let dataScanner = DataScannerViewController(recognizedDataTypes: [.barcode()], isHighlightingEnabled: true)
        present(dataScanner, animated: true) {
            try? dataScanner.startScanning()
        }
    }
    
    @IBOutlet weak var mapView: YMKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createMapObjects()
        mapView.mapWindow.map.move(
            with: YMKCameraPosition.init(target: CAMERA_TARGET, zoom: 9, azimuth: 0, tilt: 0))
    }
    
    func createMapObjects() {
        var request = URLRequest(url: URL(string: "https://pros.sbs/historyplaces/API.php?apicall=get_places")!)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data else {
                print("URLSession dataTask error:", error ?? "nil")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let places = try decoder.decode([Place].self, from: data)
                let mapObjects = self.mapView.mapWindow.map.mapObjects;
                
                for place in places {
                    let viewPlacemark = mapObjects.addPlacemark(
                        with: YMKPoint(latitude: place.latitude, longitude: place.longitude));
                    viewPlacemark.userData = PlaceObjectUserData(id: Int32(place.id), title: place.title, description: place.description, address: place.address)
                }
            } catch {
                print("JSONSerialization error:", error)
            }
            
            
            //print(String(decoding: data!, as: UTF8.self))
            //print(error)
            
        }
        task.resume()
        
        
    }
    
    private class PlaceObjectTapListener: NSObject, YMKMapObjectTapListener {
        private weak var controller: UIViewController?
        
        init(controller: UIViewController) {
            self.controller = controller
        }
        
        func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
            if let place = mapObject as? YMKCircleMapObject {
                
                if let userData = place.userData as? PlaceObjectUserData {
                    //let message = "Circle with id \(userData.id) and description '\(userData.description)' tapped";
                }
            }
            return true;
        }
    }
    
    private class PlaceObjectUserData {
        let id: Int32;
        let title: String;
        let description: String;
        let address: String;
        init(id: Int32, title: String, description: String, address: String) {
            self.id = id;
            self.title = title;
            self.description = description;
            self.address = address;
        }
    }
}


extension ViewController: DataScannerViewControllerDelegate {
    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        switch item {
        case .text(let text):
            print("text: \(text.transcript)")
        case .barcode(let code):
            print("code: \(code.payloadStringValue)")
        default:
            print("Unexpected item")
        }
    }
}

