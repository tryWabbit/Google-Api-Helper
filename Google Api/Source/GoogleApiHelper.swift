//
//  GoogleApi.swift
//  Google Api
//
//  Created by @TryWabbit on 4/12/19.
//  Copyright © 2019 @TryWabbit. All rights reserved.
//

/*
 Example of api url
 Reverse Geo : https://maps.googleapis.com/maps/api/geocode/json?latlng=26.27454,73.00954&key=key
 Auto Complete : https://maps.googleapis.com/maps/api/place/autocomplete/json?input=jodhp&key=key
 Place information : https://maps.googleapis.com/maps/api/place/details/json?input=jaipur
 Near By  :https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=(lat),(long)&radius=5000&keyword=starbucks&key=(yourkey)
 */

import UIKit
struct GLocation {
    var latitude : Double?
    var longitude : Double?
}
struct GInput {
    var keyword : String?
    var originCoordinate : GLocation?
    var destinationCoordinate : GLocation?
    var radius : Int?
    var nextPageToken : String?
}
class GApiResponse {
    var data : Any?
    var error : Error?
    var nextPageToken : String?
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
        case .path:
            let data = result as? Path
            return (data != nil)
        case .nearBy:
            let data = result as? [NearBy]
            return (data != nil)
        }
    }
    class Path {
        struct Data {
            var text : String?
            var value: Int?
        }
        var points : String = ""
        var distance : Data?
        var duration : Data?
        class func initWithData(_ data:[String:Any]) -> Path {
            let object = Path()
            guard let points = data["points"] as? String else { return object }
            object.points = points
            if let distance = data["distance"] as? [String:Any]{
                var dObj  = Data()
                dObj.text = distance["text"] as? String
                dObj.value = distance["value"] as? Int
                object.distance = dObj
            }
            if let duration = data["duration"] as? [String:Any]{
                var dObj  = Data()
                dObj.text = duration["text"] as? String
                dObj.value = duration["value"] as? Int
                object.duration = dObj
            }
            return object
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
        var title : String?
        var formattedAddress : String = ""
        var placeId : String = ""
        var latitude : Double?
        var longitude : Double?
        var description : String?
        var internationNumber : String?
        var website : String?
        var icon : String?
        class func initWithData(_ data:[String:Any]) -> PlaceInfo {
            let object = PlaceInfo()
            object.description = data["vicinity"] as? String
            object.internationNumber = data["international_phone_number"] as? String
            object.website = data["website"] as? String
            object.icon = data["icon"] as? String
            object.title = data["name"] as? String
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
    class NearBy {
        var formattedAddress : String = ""
        var placeId : String = ""
        var location = GLocation()
        var iconUrl : String?
        var description : String?
        class func initWithData(_ data:[String:Any]) -> NearBy {
            let object = NearBy()
            if let pId = data["place_id"] as? String,let address = data["name"] as? String {
                object.formattedAddress = address
                object.placeId = pId
                
            }
            object.iconUrl = data["icon"] as? String
            object.description = data["vicinity"] as? String
            typealias type = GoogleApi.Results
            if let geometry = data["geometry"] as? type, let coordinate = geometry["location"] as? type {
                var location = GLocation()
                location.latitude = coordinate["lat"] as? Double
                location.longitude = coordinate["lng"] as? Double
                object.location = location
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
        /// Use this enum to find path-distance between two locations
        case path
        /// Use this enum to get nearby location around a given radius
        case nearBy
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
        case path = "https://maps.googleapis.com/maps/api/directions/json"
        case nearby = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
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
        case .path:
            return String(format: "%@?%@&key=%@",GoogleUrl.path.rawValue,input,googleApiKey)
        case .nearBy:
            return String(format: "%@?%@&key=%@",GoogleUrl.nearby.rawValue,input,googleApiKey)
        }
    }
    func cancelOldRequest() {
        session!.cancel()
        session = nil
    }
    func getConvertedInputFor(_ usedFor:UsedFor,input:GInput) -> String {
        switch usedFor {
        case .autocomplete,.placeInformation:
            return input.keyword ?? ""
        case .path:
            var convertedInput = ""
            if let oCoordinate = input.originCoordinate, let dCoordinate = input.destinationCoordinate {
                if let lat = oCoordinate.latitude, let lng = oCoordinate.longitude {
                    let lat = String(format:"%.14f", lat)
                    let long = String(format:"%.14f", lng)
                    convertedInput =  (lat + "," + long)
                }
                if let lat = dCoordinate.latitude, let lng = dCoordinate.longitude {
                    let lat = String(format:"%.14f", lat)
                    let long = String(format:"%.14f", lng)
                    convertedInput = "origin=" + convertedInput + "&" + "destination=" + (lat + "," + long)
                }
            }
            return convertedInput
        case .reverseGeo:
            if let lat = input.destinationCoordinate?.latitude, let lng = input.destinationCoordinate?.longitude {
                let lat = String(format:"%.14f", lat)
                let long = String(format:"%.14f", lng)
                return  (lat + "," + long)
            }
            return ""
        case .nearBy:
            //location=(yourlatitude),(yourlongitude)&radius=5000&keyword=starbucks&key=(yourkey)
            var finalParameters = ""
            if let lat = input.destinationCoordinate?.latitude, let lng = input.destinationCoordinate?.longitude {
                let lat = String(format:"%.14f", lat)
                let long = String(format:"%.14f", lng)
                finalParameters = "location=" + (lat + "," + long)
                if let keyword = input.keyword {
                    finalParameters = finalParameters + "&keyword=" + keyword
                }
                if let radius = input.radius {
                    finalParameters = finalParameters + "&radius=" + String(radius)
                }
                if let nextPage = input.nextPageToken{
                    finalParameters = finalParameters + "&pagetoken=" + nextPage
                }
            }
            return finalParameters
        }
    }
    func callApi(_ api : UsedFor = .autocomplete,input:GInput,completion: @escaping GCallback) {
        let covertedInput = getConvertedInputFor(api,input:input)
        guard !covertedInput.isEmpty && !googleApiKey.isEmpty else {
            let eDesc = googleApiKey.isEmpty ? "Please add valid google api key" : "Some error occured"
            print("Google api error - \(eDesc)")
            let customError = NSError(domain:"", code:666, userInfo:[ NSLocalizedDescriptionKey: eDesc])
            let response = GApiResponse()
            response.error = customError
            completion(response)
            return
        }
        let isAlreadySearched = (searchResultsCache[covertedInput] != nil) && api == UsedFor.autocomplete
        var haveResults = false
        if isAlreadySearched {
            if let  pastResult = searchResultsCache[covertedInput] as? [Results] {
                haveResults = !(pastResult.isEmpty)
            }
        }
        if let predictions = searchResultsCache[covertedInput] as? [Results], haveResults {
            let response = GApiResponse()
            var revGeoResults : [GApiResponse.Autocomplete] = []
            for prediction in predictions {
                revGeoResults.append(GApiResponse.Autocomplete.initWithData(prediction))
            }
            response.data = revGeoResults
            completion(response)
            return;
        } else {
            let urlString = getUrl(api, input: covertedInput)
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
                            self.searchResultsCache[covertedInput] = predictions
                            var autoCompleteResults : [GApiResponse.Autocomplete] = []
                            for prediction in predictions {
                                autoCompleteResults.append(GApiResponse.Autocomplete.initWithData(prediction))
                            }
                            if !autoCompleteResults.isEmpty { response.data = autoCompleteResults }
                        } else if let predictions = responseData?["results"] as? [Results], api == .reverseGeo {
                            self.searchResultsCache[covertedInput] = predictions
                            var revGeoResults : [GApiResponse.ReverseGio] = []
                            for prediction in predictions {
                                revGeoResults.append(GApiResponse.ReverseGio.initWithData(prediction))
                            }
                            if !revGeoResults.isEmpty { response.data = revGeoResults }
                        } else if let place = responseData?["result"] as? Results, api == .placeInformation {
                            response.data =  GApiResponse.PlaceInfo.initWithData(place)
                        } else if let place = responseData?["routes"] as? [Results], api == .path && !place.isEmpty {
                            let route = place.first!
                            if let oPolyline = route["overview_polyline"] as? Results,let points = oPolyline["points"] as? String {
                                var data : [String:Any] = [:]
                                data["points"] = points
                                if let legs = route["legs"] as? [Results],let leg = legs.first {
                                    if let distance = leg["distance"] as? Results {
                                        data["distance"] = distance
                                    }
                                    if let duration = leg["duration"] as? Results {
                                        data["duration"] = duration
                                    }
                                }
                                response.data =  GApiResponse.Path.initWithData(data)
                            }
                        } else if let places = responseData?["results"] as? [Results], api == .nearBy {
                            var revGeoResults : [GApiResponse.NearBy] = []
                            for place in places {
                                revGeoResults.append(GApiResponse.NearBy.initWithData(place))
                            }
                            response.data =  revGeoResults
                            response.nextPageToken = responseData?["next_page_token"] as? String
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
