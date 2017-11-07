//
//  MatcherProtocol.swift
//  Alamofire
//
//  Created by Natalia  Stele on 11/5/17.
//

import Foundation


public protocol MatcherProtocol: NSObjectProtocol {

    func match(matchValue: Any?, bucketingKey: String? ,atributtes: [String:Any]?) -> Bool

}
