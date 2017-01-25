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

class QuestionViewController: UIViewController {

    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var constraintQuestionTop: NSLayoutConstraint!
    
    var currentQuestioKana:[String] = []
    var currentAnswers:[[String]] = []
    var currentAnswerLabels:[String] = []
    var isShowingCorrectAnswer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let kana = currentAnswers[index]
        
        if isShowingCorrectAnswer == true { //case of user incorrect answer
            isShowingCorrectAnswer = false
        }
        
        let correct_idx = findCorrectAnswerIndex()

        if kana[KanaType.roma.rawValue] == currentQuestioKana[KanaType.roma.rawValue] {
            //correct
            addStat(index: index, is_correct: true, cost: 0)
            nextQuestion()
        }else {
            //incorrect
            addStat(index: index, is_correct: false, cost: 0)
            isShowingCorrectAnswer = true
            //show correct answer with red background
            if correct_idx >= 0 {
                let indexPath = IndexPath(item: correct_idx, section: 0)
                collectionView.reloadItems(at: [indexPath])
            }
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
    
    func addStat(index:Int, is_correct:Bool, cost:Float) {
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
    
    func nextQuestion() {
        
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

