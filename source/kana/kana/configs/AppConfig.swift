//
//  AppConfig.swift
//  kana
//
//  Created by JackyZ on 2017/01/12.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit

enum KanaType: Int {
    case roma = 0, hiragana, katakana
}

struct AppConfig {
    static let keyBestCombo = "user.stat.bestCombo"
    static let keyCurrentCombo = "user.stat.currentCombo"
    
    static var answersCount:Int = 4
    static var questionTimeLimit:Double = 5
    static var statisticsLastCount:Int = 10
    
    static let monographs:[[[String]]] = [
        [["a", "あ", "ア"], ["i", "い", "イ"], ["u", "う", "ウ"], ["e", "え", "エ"], ["o", "お", "オ"]],
        [["ka", "か", "カ"], ["ki", "き", "キ"], ["ku", "く", "ク"], ["ke", "け", "ケ"], ["ko", "こ", "コ"]],
        [["sa", "さ", "サ"], ["shi", "し", "シ"], ["su", "す", "ス"], ["se", "せ", "セ"], ["so", "そ", "ソ"]],
        [["ta", "た", "タ"], ["chi", "ち", "チ"], ["tsu", "つ", "ツ"], ["te", "て", "テ"], ["to", "と", "ト"]],
        [["na", "な", "ナ"], ["ni", "に", "ニ"], ["nu", "ぬ", "ヌ"], ["ne", "ね", "ネ"], ["no", "の", "ノ"]],
        [["ha", "は", "ハ"], ["hi", "ひ", "ヒ"], ["fu", "ふ", "フ"], ["he", "へ", "ヘ"], ["ho", "ほ", "ホ"]],
        [["ma", "ま", "マ"], ["mi", "み", "ミ"], ["mu", "む", "ム"], ["me", "め", "メ"], ["mo", "も", "モ"]],
        [["ya", "や", "ヤ"], ["", "", ""], ["yu", "ゆ", "ユ"], ["", "", ""], ["yo", "よ", "ヨ"]],
        [["ra", "ら", "ラ"], ["ri", "り", "リ"], ["ru", "る", "ル"], ["re", "れ", "レ"], ["ro", "ろ", "ロ"]],
        [["wa", "わ", "ワ"], ["", "", ""], ["", "", ""], ["", "", ""], ["wo", "を", "ヲ"]],
        [["n", "ん", "ン"]]
    ];
    
    static let digraphs = [
        [["kya", "きゃ", "キャ"], ["kyu", "きゅ", "キュ"], ["kyo", "きょ", "キョ"]],
        [["sha", "しゃ", "シャ"], ["shu", "しゅ", "シュ"], ["sho", "しょ", "ショ"]],
        [["cha", "ちゃ", "チャ"], ["chu", "ちゅ", "チュ"], ["cho", "ちょ", "チョ"]],
        [["nya", "にゃ", "ニャ"], ["nyu", "にゅ", "ニュ"], ["nyo", "にょ", "ニョ"]],
        [["hya", "ひゃ", "ヒャ"], ["hyu", "ひゅ", "ヒュ"], ["hyo", "ひょ", "ヒョ"]],
        [["mya", "みゃ", "ミャ"], ["myu", "みゅ", "ミュ"], ["myo", "みょ", "ミョ"]],
        [["rya", "りゃ", "リャ"], ["ryu", "りゅ", "リュ"], ["ryo", "りょ", "リョ"]]
    ]
    
    static let monographs_with_diacritics = [
        [["ga", "が", "ガ"], ["gi", "ぎ", "ギ"], ["gu", "ぐ", "グ"], ["ge", "げ", "ゲ"], ["go", "ご", "ゴ"]],
        [["za", "ざ", "ザ"], ["ji", "じ", "ジ"], ["zu", "ず", "ズ"], ["ze", "ぜ", "ゼ"], ["zo", "ぞ", "ゾ"]],
        [["da", "だ", "ダ"], ["ji*", "ぢ", "ヂ"], ["zu*", "づ", "ヅ"], ["de", "で", "デ"], ["do", "ど", "ド"]],
        [["ba", "ば", "バ"], ["bi", "び", "ビ"], ["bu", "ぶ", "ブ"], ["be", "べ", "ベ"], ["bo", "ぼ", "ボ"]],
        [["pa", "ぱ", "パ"], ["pi", "ぴ", "ピ"], ["pu", "ぷ", "プ"], ["pe", "ぺ", "ペ"], ["po", "ぽ", "ポ"]]
    ]
    
    static let digraphs_with_diacritics = [
        [["gya", "ぎゃ", "ギャ"], ["gyu", "ぎゅ", "ギュ"], ["gyo", "ぎょ", "ギョ"]],
        [["ja", "じゃ", "ジャ"], ["ju", "じゅ", "ジュ"], ["jo", "じょ", "ジョ"]],
        [["ja*", "ぢゃ", "ヂャ"], ["ju*", "ぢゅ", "ヂュ"], ["jo*", "ぢょ", "ヂョ"]],
        [["bya", "びゃ", "ビャ"], ["byu", "びゅ", "ビュ"], ["byo", "びょ", "ビョ"]],
        [["pya", "ぴゃ", "ピャ"], ["pyu", "ぴゅ", "ピュ"], ["pyo", "ぴょ", "ピョ"]]
    ]
    
//    static func realmConfig() -> Realm.Configuration {
//        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
//        let directory = URL(fileURLWithPath: path!)
//        let realmPath = directory.appendingPathComponent("db.realm")
//        print(realmPath.path)
//        var config = Realm.Configuration(schemaVersion: 1, migrationBlock: { migration, oldSchemaVersion in
//            //
//        })
//        
//        config.fileURL = realmPath
//        
//        return config
//    }
    
    func printFonts() {
        let fontFamilyNames = UIFont.familyNames
        for familyName in fontFamilyNames {
            print("------------------------------")
            print("Font Family Name = [\(familyName)]")
            let names = UIFont.fontNames(forFamilyName: familyName)
            print("Font Names = [\(names)]")
        }
    }
}
