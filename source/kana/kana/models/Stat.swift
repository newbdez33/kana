//
//  Stat.swift
//  kana
//
//  Created by JackyZ on 2017/01/25.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import Foundation
import RealmSwift

final class Stat: Object {
    dynamic var dt = Date() //start date
    dynamic var kana = ""   //display kana of question
    dynamic var kana_roma = ""   //roma of question
    dynamic var questions = "" //roma kana from question, seprated by comma ,
    dynamic var answer = "" //user's answer
    dynamic var answer_roma = ""
    dynamic var is_correct = false
    dynamic var cost:Float = 0.0
    
    convenience init(kana: String, kana_roma: String, questions: String, answer: String, answer_roma: String, is_correct: Bool, cost:Float) {
        self.init()
        self.kana = kana
        self.kana_roma = kana_roma
        self.questions = questions
        self.answer = answer
        self.answer_roma = answer_roma
        self.is_correct = is_correct
        self.cost = cost
    }
    
    class func totalCount() -> Int {
        guard let realm = try? Realm() else {
            return 0
        }
        let query = realm.objects(Stat.self)
        return query.count
    }
}
