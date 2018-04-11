//
//  ViewController.swift
//  Local Search Tester
//
//  Created by Simon Burbidge on 10/4/18.
//  Copyright © 2018 Bonobo Labs. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Contacts

class ViewController: UIViewController {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var modeSegControl: UISegmentedControl!
    @IBOutlet var searchButton: UIButton!
    
    var localSearch: MKLocalSearch?
    var geocoder: CLGeocoder?
    var results = [] as Array<String>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 35
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    @IBAction func performSearch(_ sender: Any) {
        switch modeSegControl.selectedSegmentIndex {
        case 0:
            self.search()
        default:
            self.geocode()
        }
    }
    
    func search() {
        let infiniteLoopCoord = CLLocationCoordinate2DMake(37.331695, -122.0322854)
        let searchString = self.textField.text
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchString
        request.region = MKCoordinateRegionMakeWithDistance(infiniteLoopCoord, 20000, 20000)
        
        self.localSearch?.cancel()
        self.localSearch = MKLocalSearch(request: request)
        
        self.localSearch?.start { (response, error) in
            guard error == nil else {
                self.displayError(error: error!)
                return
            }
            guard let response = response else { return }
            guard response.mapItems.count > 0 else { return }
            
            let item = response.mapItems.first
            let coordinate = item?.placemark.coordinate
            let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate!, 1600, 1600)
            self.mapView.setRegion(viewRegion, animated: true)
            
            var mutableResults = Array<String>()
            for item in response.mapItems {
                var itemString = CNPostalAddressFormatter().string(from: item.placemark.postalAddress!);
                itemString = itemString.replacingOccurrences(of: "\n", with: ", ")
                itemString = (item.name?.appendingFormat(", %@", itemString))!
                
                print("Name = \(String(describing: itemString))")
                mutableResults.append(itemString)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                self.mapView.addAnnotation(annotation)
            }
            self.results.insert(contentsOf: mutableResults, at: 0)
            self.tableView.reloadData()
        }
    }
    
    func geocode() {
        let searchString = self.textField.text
     
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        self.geocoder?.cancelGeocode()
        self.geocoder = CLGeocoder.init()
        
        self.geocoder?.geocodeAddressString(searchString!, in: nil) { (placemarks, error) in
            guard error == nil else {
                self.displayError(error: error!)
                return
            }
            guard let placemarks = placemarks else { return }
            guard placemarks.count > 0 else { return }

            let item = self.mapItem(placemark: placemarks.first!)
            let coordinate = item.placemark.coordinate
            
            let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 1600, 1600)
            self.mapView.setRegion(viewRegion, animated: true)
            let mapItems = placemarks.map({ (pm) -> MKMapItem in
                return self.mapItem(placemark: pm)
            })
            
            var mutableResults = Array<String>()
            for item in mapItems {
                var itemString = CNPostalAddressFormatter().string(from: item.placemark.postalAddress!);
                itemString = itemString.replacingOccurrences(of: "\n", with: ", ")
                itemString = (item.name?.appendingFormat(", %@", itemString))!
                
                print("Name = \(String(describing: itemString))")
                mutableResults.append(itemString)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                self.mapView.addAnnotation(annotation)
            }
            self.results.insert(contentsOf: mutableResults, at: 0)
            self.tableView.reloadData()
        }
    }
    
    func displayError(error: Error) {        
        let code = (error as NSError).code
        let title = String.init(format: "Error: %ld", code)
        let alert = UIAlertController.init(title: title, message: error.localizedDescription, preferredStyle: .alert)
        
        let okAction = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func mapItem(placemark: CLPlacemark) -> MKMapItem {
        let pm = MKPlacemark.init(placemark: placemark)
        return MKMapItem.init(placemark: pm)
    }
}


extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        self.performSearch(self.searchButton)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCellID", for: indexPath)
        
        cell.textLabel?.text = results[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        
        return cell;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let resultString = self.results[indexPath.row]
        self.textField.text = resultString
        self.performSearch(self.searchButton)
    }
}
