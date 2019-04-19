//
//  GoogleApi.swift
//  Google Api
//
//  Created by Wabbit on 4/12/19.
//  Copyright © 2019 Wabbit. All rights reserved.
//

/*
Example of api url
Reverse Geo : https://maps.googleapis.com/maps/api/geocode/json?latlng=26.27454,73.00954&key=key
Auto Complete : https://maps.googleapis.com/maps/api/place/autocomplete/json?input=jodhp&key=key
Place information : https://maps.googleapis.com/maps/api/place/details/json?input=jaipur
*/

import UIKit
class GApiResponse {
    var data : Any?
    var error : Error?
    
    func isValidFor(_ type:GoogleApi.UsedFor) -> Bool {
        guard let result = data,error == nil else { return false }
        switch type {
        case .autocomplete:
            let data = result as? [Autocomplete]
            return (data != nil)
        case .reverseGeo:
            let data = result as? [ReverseGio]
            return (data != nil)
        case .placeInformation:
            let data = result as? PlaceInfo
            return (data != nil)
        }
    }
    class ReverseGio {
        var formattedAddress : String = ""
        var placeId : String = ""
        class func initWithData(_ data:[String:Any]) -> ReverseGio {
            let object = ReverseGio()
            if let pId = data["place_id"] as? String,let address = data["formatted_address"] as? String {
                object.formattedAddress = address
                object.placeId = pId
            }
            return object
        }
    }
    class Autocomplete {
        var formattedAddress : String = ""
        var placeId : String = ""
        class func initWithData(_ data:[String:Any]) -> Autocomplete {
            let object = Autocomplete()
            if let pId = data["place_id"] as? String,let address = data["description"] as? String {
                object.formattedAddress = address
                object.placeId = pId
            }
            return object
        }
    }
    class PlaceInfo {
        var formattedAddress : String = ""
        var placeId : String = ""
        var latitude : Double?
        var longitude : Double?
        class func initWithData(_ data:[String:Any]) -> PlaceInfo {
            let object = PlaceInfo()
            if let pId = data["place_id"] as? String,let address = data["formatted_address"] as? String {
                object.formattedAddress = address
                object.placeId = pId
                
            }
            if let geometry = data["geometry"] as? [String:Any],let location = geometry["location"] as? [String:Double] {
                object.latitude = location["lat"]
                object.longitude = location["lng"]
            }
            return object
        }
    }
}

class GoogleApi : NSObject {
    
    enum UsedFor {
        ///Use this enum for autocomplete
        case autocomplete
        ///Use this enum to get selected address information with the placeId
        case placeInformation
        ///Use this enum to get Address from lat long
        case reverseGeo
    }
    
    static let shared : GoogleApi = GoogleApi()
    typealias Results = [String:Any]
    typealias GCallback = (GApiResponse) -> Void
    
    var session : URLSessionDataTask?
    var searchResultsCache : Results = [:]
    var googleApiKey = ""
    
    enum GoogleCallback : String {
        case notFound = "NOT_FOUND"
        case denied = "REQUEST_DENIED"
    }
    enum GoogleUrl : String {
        case autocomplete = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        case placeInfo = "https://maps.googleapis.com/maps/api/place/details/json"
        case reverseGeo = "https://maps.googleapis.com/maps/api/geocode/json"
    }
    func initialiseWithKey(_ key:String) {
        googleApiKey = key
    }
    func getUrl(_  usedFor:UsedFor,input:String) -> String {
        guard !input.isEmpty else { return input }
        switch usedFor {
        case .autocomplete:
            let updatedInput = input.lowercased()
            return String(format: "%@?input=%@&key=%@",GoogleUrl.autocomplete.rawValue,updatedInput,googleApiKey)
        case .placeInformation:
            return String(format: "%@?placeid=%@&key=%@",GoogleUrl.placeInfo.rawValue,input,googleApiKey)
        case .reverseGeo:
            return String(format: "%@?latlng=%@&key=%@",GoogleUrl.reverseGeo.rawValue,input,googleApiKey)
        }
    }
    func cancelOldRequest() {
        session!.cancel()
        session = nil
    }
    func callApi(_ api : UsedFor = .autocomplete,input:String,completion: @escaping GCallback) {
        guard !input.isEmpty && !googleApiKey.isEmpty else {
            let eDesc = googleApiKey.isEmpty ? "Please add valid google api key" : "Some error occured"
            print("Google api error - \(eDesc)")
            let customError = NSError(domain:"", code:666, userInfo:[ NSLocalizedDescriptionKey: eDesc])
            let response = GApiResponse()
            response.error = customError
            completion(response)
            return
        }
        let isAlreadySearched = (searchResultsCache[input] != nil) && api == UsedFor.autocomplete
        var haveResults = false
        if isAlreadySearched {
            if let  pastResult = searchResultsCache[input] as? [Results] {
                haveResults = !(pastResult.isEmpty)
            }
        }
        if let predictions = searchResultsCache[input] as? [Results], haveResults {
            let response = GApiResponse()
            var revGeoResults : [GApiResponse.Autocomplete] = []
            for prediction in predictions {
                revGeoResults.append(GApiResponse.Autocomplete.initWithData(prediction))
            }
            response.data = revGeoResults
            completion(response)
            return;
        } else {
            let urlString = getUrl(api, input: input)
            print("Google api request - \(urlString)")
            let url =  URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!)!
            let urlSession = URLSession(configuration: URLSessionConfiguration.default)
            let urlRequest = URLRequest(url: url)
            if session != nil { cancelOldRequest() } // will cancel old request when overided with new one
            session = urlSession.dataTask(with: urlRequest, completionHandler: { (data, _, error) in
                let customError = NSError(domain:"", code:666, userInfo:[ NSLocalizedDescriptionKey: "Some error occured"])
                let response = GApiResponse()
                if let data = data {
                    let responseData = self.getDictionary(data:data)
                    var isApiError = false
                    if let responseStatus = responseData?["status"] as? String {
                        isApiError = (responseStatus == GoogleCallback.notFound.rawValue || responseStatus == GoogleCallback.denied.rawValue)
                    }
                    if error != nil || isApiError {
                        response.error = error ?? (customError as Error)
                        completion(response)
                    } else if responseData != nil && error == nil {
                        // For reverse geo
                        if let predictions = responseData?["predictions"] as? [Results], api == .autocomplete {
                            self.searchResultsCache[input] = predictions
                            var autoCompleteResults : [GApiResponse.Autocomplete] = []
                            for prediction in predictions {
                                autoCompleteResults.append(GApiResponse.Autocomplete.initWithData(prediction))
                            }
                            if !autoCompleteResults.isEmpty { response.data = autoCompleteResults }
                        } else if let predictions = responseData?["results"] as? [Results], api == .reverseGeo {
                            self.searchResultsCache[input] = predictions
                            var revGeoResults : [GApiResponse.ReverseGio] = []
                            for prediction in predictions {
                                revGeoResults.append(GApiResponse.ReverseGio.initWithData(prediction))
                            }
                            if !revGeoResults.isEmpty { response.data = revGeoResults }
                        } else if let place = responseData?["result"] as? Results, api == .placeInformation {
                            response.data =  GApiResponse.PlaceInfo.initWithData(place)
                        }
                        completion(response)
                    } else {
                        response.error = (customError as Error)
                        completion(response)
                    }
                } else {
                    response.error = (customError as Error)
                    completion(response)
                }
                
            })
            session!.resume()
        }
    }
    func getDictionary(data:Data) -> Results? {
        let string =  String(data: data, encoding: String.Encoding.utf8)
        let data = string?.data(using: .utf8)!
        if data != nil {
            do {
                let output = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Results
                return output
            } catch {
                print (error)
                return nil
            }
        } else {
            return nil
        }
        
    }
}
