//
//  NetworkFetcher.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 01/05/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation

class NFetcher{
    var cTask: URLSessionTask?
    
    func fetchJSON(fromURL url: URL, completion: @escaping (([String: Any]?, Error?) -> Void)) {
        let session = URLSession.shared
        cTask = session.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard error == nil, let data = data, let parsedData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completion(nil, error)
                    return
                }
                completion(parsedData, nil)
            }
        }
        cTask?.resume()
    }
    
    deinit {
        cTask?.cancel()
    }
}
