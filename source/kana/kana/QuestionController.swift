//
//  ViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/07.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit
import JZSpringRefresh
import RealmSwift
import GoogleMobileAds

class QuestionViewController: UIViewController {

    @IBOutlet weak var statLabelWidth: NSLayoutConstraint!
    @IBOutlet weak var questionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var adViewHeight: NSLayoutConstraint!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var constraintQuestionTop: NSLayoutConstraint!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var avgLabel: UILabel!
    @IBOutlet weak var lastAvgTitleLabel: UILabel!
    @IBOutlet weak var lastAvgLabel: UILabel!
    @IBOutlet weak var comboLabel: UILabel!
    
    var currentQuestioKana:[String] = []
    var currentAnswers:[[String]] = []
    var currentAnswerLabels:[String] = []
    var isShowingCorrectAnswer = false
    var timer:Timer?
    var currentQuestionStartTime:TimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lastAvgTitleLabel.text = String.localizedStringWithFormat(.lastNAvg, AppConfig.statisticsLastCount)
        statLabelWidth.constant = lastAvgTitleLabel.intrinsicContentSize.width
        
        let bottom = scrollView.addSpringRefresh(position: .bottom, actionHandlere: { (v:JZSpringRefresh) in
            let vc = UIStoryboard(name: "Kana", bundle: nil).instantiateInitialViewController()
            self.present(vc!, animated: true, completion: { 
                //
            })
        })
        bottom.text = "五十音図"
        bottom.readyColor = UIColor.kanaKeyRedColor()
        
        collectionView.register(UINib(nibName: "AnswerCell", bundle: nil), forCellWithReuseIdentifier: "AnswerCell")
        
        nextQuestion()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 
    func answerAction(index:Int) {
        
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }

        let cost = Date().timeIntervalSince1970 - currentQuestionStartTime
        
        let kana = currentAnswers[index]
        
        if isShowingCorrectAnswer == true { //case of user incorrect answer
            isShowingCorrectAnswer = false
        }

        if kana[KanaType.roma.rawValue] == currentQuestioKana[KanaType.roma.rawValue] {
            //correct
            updateBestCombo(is_correct: true)
            addStat(index: index, is_correct: true, cost: cost)
            nextQuestion()
        }else {
            //incorrect
            updateBestCombo(is_correct: false)
            addStat(index: index, is_correct: false, cost: cost)
            incorrect()
        }
        
    }
    
    func incorrect() {
        
        showBanner()
        
        let correct_idx = findCorrectAnswerIndex()
        
        isShowingCorrectAnswer = true
        //show correct answer with red background
        if correct_idx >= 0 {
            let indexPath = IndexPath(item: correct_idx, section: 0)
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func findCorrectAnswerIndex() -> Int {
        for i in 0...currentAnswers.count-1 {
            let ans = currentAnswers[i]
            if ans[KanaType.roma.rawValue] == currentQuestioKana[KanaType.roma.rawValue] {
                return i
            }
        }
        return -1
    }
    
    func addStat(index:Int, is_correct:Bool, cost:Double) {
        var cost = cost
        if cost > AppConfig.questionTimeLimit {
            cost = 0
        }
        
        let stat = Stat(kana: questionLabel.text!,
                        kana_roma: currentQuestioKana[KanaType.roma.rawValue],
                        questions: currentAnswerLabels.joined(separator: ","),
                        answer: currentAnswerLabels[index],
                        answer_roma: currentAnswers[index][KanaType.roma.rawValue],
                        is_correct: is_correct,
                        cost: cost)
        guard let realm = try? Realm() else {
            return
        }
        let _ = try? realm.write {
            realm.add(stat)
        }
    }
    
    func updateBestCombo(is_correct:Bool) {
        
        var current = UserDefaults.standard.integer(forKey: AppConfig.keyCurrentCombo)
        let best = UserDefaults.standard.integer(forKey: AppConfig.keyBestCombo)
        
        if is_correct {
            current += 1
        }else {
            current = 0
        }
        UserDefaults.standard.set(current, forKey: AppConfig.keyCurrentCombo)
        
        if current > best {
            UserDefaults.standard.set(current, forKey: AppConfig.keyBestCombo)
        }
        
        UserDefaults.standard.synchronize()
        
    }
    
    func nextQuestion() {
        
        hideBanner()
        
        // random kana picking
        currentQuestioKana = randomKana()
        let questionKanaText = randomType(ofKana: currentQuestioKana)
        
        // random answer picking
        currentAnswers.removeAll()
        currentAnswerLabels.removeAll()
        let randomCorrectAnswerIndex = Int(arc4random_uniform(UInt32(AppConfig.answersCount)))
        for i in 0...AppConfig.answersCount {
            if i == randomCorrectAnswerIndex {
                currentAnswers.append(currentQuestioKana)
                currentAnswerLabels.append(randomType(ofKana: currentQuestioKana, exclude: questionKanaText))
            }else {
                let kana = randomKana(excludeRoma: currentQuestioKana[KanaType.roma.rawValue])
                currentAnswers.append(kana)
                currentAnswerLabels.append(randomType(ofKana: kana))
            }
        }
        
        questionLabel.text = questionKanaText
        collectionView.reloadData()
        
        timer = Timer.scheduledTimer(withTimeInterval: AppConfig.questionTimeLimit, repeats: false, block: { (t:Timer) in
            self.incorrect()
        })
        currentQuestionStartTime = Date().timeIntervalSince1970 //timestamp
        
        updateStatisticsLabels()
    }
    
    func updateStatisticsLabels() {
        
        totalLabel.text = "\(Stat.totalCount())"
        avgLabel.text = "\(Stat.totalAvgTime().roundTo(places: 2))s"
        lastAvgLabel.text = "\(Stat.lastAvgTime().roundTo(places: 2))s"
        
        let best = UserDefaults.standard.integer(forKey: AppConfig.keyBestCombo)
        comboLabel.text = "\(best)"
    }
    
    func randomKana(excludeRoma:String = "") -> [String] {
        
        let section = Int(arc4random_uniform(UInt32(AppConfig.monographs.count)))
        let index =  Int(arc4random_uniform(UInt32(AppConfig.monographs[section].count)))
        let kana = AppConfig.monographs[section][index]
        if kana[KanaType.roma.rawValue] == "" || kana[KanaType.roma.rawValue] == excludeRoma {
            return randomKana(excludeRoma: excludeRoma)
        }
        
        return kana
        
    }
    
    func randomType(ofKana kana:[String], exclude:String = "") -> String {
        let index = Int(arc4random_uniform(UInt32(kana.count)))
        let text = kana[index]
        if text == exclude {
            return randomType(ofKana: kana, exclude: exclude)
        }
        
        return text
    }
    
    func hideBanner() {
        adViewHeight.constant = 0
        questionViewHeight.constant = 0
    }
    
    func showBanner() {
        bannerView.adUnitID = "ca-app-pub-1295607594822275/7264793113"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        adViewHeight.constant = 50
        questionViewHeight.constant = -50
    }

}

extension QuestionViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print(scrollView.contentOffset.y)
        if constraintQuestionTop.constant == 0 {
            if scrollView.contentOffset.y < -80 {
                constraintQuestionTop.constant = 80
            }
        }else {
            if scrollView.contentOffset.y >= 80 {
                constraintQuestionTop.constant = 0
            }
        }
    }
    
}

extension QuestionViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AnswerCell", for: indexPath) as! AnswerCell
        let kana = currentAnswers[indexPath.row]
        cell.backgroundColor = UIColor.clear
        cell.kanaLabel.textColor = UIColor.kanaBlackColor()
        cell.kanaLabel.text = currentAnswerLabels[indexPath.row]
        
        if isShowingCorrectAnswer {
            if kana[KanaType.roma.rawValue] == currentQuestioKana[KanaType.roma.rawValue] {
                cell.backgroundColor = UIColor.kanaIncorrectAnswerBackgroundColor()
                cell.kanaLabel.textColor = UIColor.white
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        answerAction(index: indexPath.row)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4;
    }
    
    // Cell Size Change
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width/2, height: collectionView.bounds.size.height/2)
    }
    
}

