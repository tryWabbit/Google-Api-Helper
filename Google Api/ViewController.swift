//  Created by Wabbit on 29/08/18.
//  Copyright © 2018 Wabbit. All rights reserved.

import UIKit
import MapKit
class ViewController: UIViewController {
    @IBOutlet weak var textfieldAddress: UITextField!
    @IBOutlet weak var tableviewSearch: UITableView!
    @IBOutlet weak var constraintSearchIconWidth: NSLayoutConstraint!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var mapview: MKMapView!
    var autocompleteResults :[GApiResponse.Autocomplete] = []
    var oldLocation :CLLocationCoordinate2D?

    @IBAction func searchButtonPressed(_ sender: Any) {
        textfieldAddress.becomeFirstResponder()
    }
    func showResults(string:String){
        var input = GInput()
        input.keyword = string
        GoogleApi.shared.callApi(input: input) { (response) in
            if response.isValidFor(.autocomplete) {
                DispatchQueue.main.async {
                    self.searchView.isHidden = false
                    self.autocompleteResults = response.data as! [GApiResponse.Autocomplete]
                    self.tableviewSearch.reloadData()
                }
            } else { print(response.error ?? "ERROR") }
        }
    }
    func hideResults(){
        searchView.isHidden = true
        autocompleteResults.removeAll()
        tableviewSearch.reloadData()
    }
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        hideResults() ; return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text! as NSString
        let fullText = text.replacingCharacters(in: range, with: string)
        if fullText.count > 2 {
            showResults(string:fullText)
        }else{
            hideResults()
        }
        return true
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        constraintSearchIconWidth.constant = 0.0 ; return true
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        constraintSearchIconWidth.constant = 38.0 ; return true
    }
}
extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        var input = GInput()
        let destination = GLocation.init(latitude: mapview.region.center.latitude, longitude: mapview.region.center.longitude)
        input.destinationCoordinate = destination
        GoogleApi.shared.callApi(.reverseGeo , input: input) { (response) in
            if let places = response.data as? [GApiResponse.ReverseGio], response.isValidFor(.reverseGeo) {
                DispatchQueue.main.async {
                    self.textfieldAddress.text = places.first?.formattedAddress
                }
            } else { print(response.error ?? "ERROR") }
        }
        
        // Just to demonstrate draw path api
        if let location = oldLocation {
            let origin = GLocation.init(latitude: location.latitude, longitude: location.longitude)
            input.originCoordinate = origin
            GoogleApi.shared.callApi(.path , input: input) { (response) in
                if let _ = response.data as? GApiResponse.Path, response.isValidFor(.path) {
                    /* draw path on map
                    DispatchQueue.main.async {
                        let path = GMSPath(fromEncodedPath: route.points)
                        let polyline = GMSPolyline(path: path)
                        polyline.strokeWidth = 3.0
                        polyline.map = mapView
                    }
                    */
                } else { print(response.error ?? "ERROR") }
            }
        }
        oldLocation = mapview.centerCoordinate
    }
}
extension ViewController : UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autocompleteResults.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell")
        let label = cell?.viewWithTag(1) as! UILabel
        label.text = autocompleteResults[indexPath.row].formattedAddress
        return cell!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        textfieldAddress.text = autocompleteResults[indexPath.row].formattedAddress
        textfieldAddress.resignFirstResponder()
        var input = GInput()
        input.keyword = autocompleteResults[indexPath.row].placeId
        GoogleApi.shared.callApi(.placeInformation,input: input) { (response) in
            if let place =  response.data as? GApiResponse.PlaceInfo, response.isValidFor(.placeInformation) {
                DispatchQueue.main.async {
                    self.searchView.isHidden = true
                    if let lat = place.latitude, let lng = place.longitude{
                        let center  = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        self.mapview.setRegion(region, animated: true)
                    }
                    self.tableviewSearch.reloadData()
                }
            } else { print(response.error ?? "ERROR") }
        }
    }
}
