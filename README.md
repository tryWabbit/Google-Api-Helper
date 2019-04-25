# Google-Api-Helper
Google api helper is created to save the time that developer have to spend using basic google apis like Autocomplete, ReverseGeo and Place api.

---
![Swift](https://img.shields.io/badge/Swift-v4.2-orange.svg) 
![Xcode](https://img.shields.io/badge/XCode-10.0-blue.svg)
![](https://img.shields.io/badge/Google-Helper-green.svg) 

![google map resize](https://user-images.githubusercontent.com/20557360/56422259-1f509e80-62c4-11e9-82b2-5159ac877d57.gif)


Welcome to Google api helper. This library saves your time to write basic google apis and handle there response. You can call Google Autocomplete , ReverseGeo and Place Information Api with this library, only with four lines of code! all three api can be accessed with only four lines. See the example :-

## Autocomplete

    var input = GInput()
    input.keyword = "San francisco"
    GoogleApi.shared.callApi(input: input) { (response) in
        if let results = response.data as? [GApiResponse.Autocomplete], response.isValidFor(.autocomplete) {
            //Enjoy the Autocomplete Api
        } else { print(response.error ?? "ERROR") }
    }
        
## Reverse Geo

    var input = GInput()
    let destination = GLocation.init(latitude: lattitude, longitude: longitude)
    input.destinationCoordinate = destination
    GoogleApi.shared.callApi(.reverseGeo , input: input) { (response) in
        if let places = response.data as? [GApiResponse.ReverseGio], response.isValidFor(.reverseGeo) {
            //Enjoy the ReverseGeo Api
        } else { print(response.error ?? "ERROR") }
    }
## Place information

    var input = GInput()
    input.keyword = "chijucwgqk6mqtkrukvhclvqfie"
    GoogleApi.shared.callApi(.placeInformation,input: input) { (response) in
        if let place =  response.data as? GApiResponse.PlaceInfo, response.isValidFor(.placeInformation) {
            //Enjoy the Place Api
        } else { print(response.error ?? "ERROR") }
    }
    
## Draw path

    var input = GInput()
    let origin = GLocation.init(latitude: oLattitude, longitude: oLongitude)
    let destination = GLocation.init(latitude: dLattitude, longitude: dLongitude)
    input.destinationCoordinate = destination
    input.originCoordinate = origin
    GoogleApi.shared.callApi(.path , input: input) { (response) in
        if let path = response.data as? GApiResponse.Path, response.isValidFor(.reverseGeo) {
            //Enjoy the Path Api
        } else { print(response.error ?? "ERROR") }
    }

## How to use?

#### Step-1 Import GoogleApiHelper to your project
#### Step-2 Initialise GoogleApi with your Api key
    GoogleApi.shared.initialiseWithKey("API_KEY")
#### Step-3 Use any api from the api with input
    GoogleApi.shared.callApi(.placeInformation,input: "chijucwgqk6mqtkrukvhclvqfie") { (response) in
        if let result = response.data, response.isValidFor(.placeInformation) {
            // Enjoy your results
        } else { print(response.error ?? "ERROR") }
    }

## Note
The response will be different for each api and for each response there is a data model that can be updated according to your need. All the three api response exapmple are added into the project so you can check and see how to handle them.


## MIT License

Copyright (c) 2019 Wabbit

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:


The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

The Software Is Provided "As Is", Without Warranty Of Any Kind, Express Or
Implied, Including But Not Limited To The Warranties Of Merchantability,
Fitness For A Particular Purpose And Noninfringement. In No Event Shall The
Authors Or Copyright Holders Be Liable For Any Claim, Damages Or Other
Liability, Whether In An Action Of Contract, Tort Or Otherwise, Arising From,
Out Of Or In Connection With The Software Or The Use Or Other Dealings In The Software.

