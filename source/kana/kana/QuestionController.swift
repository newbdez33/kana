//
//  ViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/07.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit
import JZSpringRefresh

class QuestionViewController: UIViewController {

    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var currentQuestioKana:[String] = []
    var currentAnswers:[[String]] = []
    
    var isShowingCorrectAnswer = false
    var correctAnswerLabelKanaType:KanaType = .roma
    
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
    func answerAction(kana:[String]) {
        
        if isShowingCorrectAnswer == true {
            isShowingCorrectAnswer = false
        }
        
        if kana[KanaType.roma.rawValue] == currentQuestioKana[KanaType.roma.rawValue] {
            //correct
            nextQuestion()
        }else {
            //incorrect
            isShowingCorrectAnswer = true
            //show correct answer with red background
            for i in 0...currentAnswers.count-1 {
                let ans = currentAnswers[i]
                if ans[KanaType.roma.rawValue] == currentQuestioKana[KanaType.roma.rawValue] {
                    let indexPath = IndexPath(item: i, section: 0)
                    collectionView.reloadItems(at: [indexPath])
                    return
                }
            }
        }
        
    }
    
    func nextQuestion() {
        // random kana picking
        currentQuestioKana = randomKana()
        
        // random answer picking
        currentAnswers.removeAll()
        let randomCorrectAnswerIndex = Int(arc4random_uniform(UInt32(AppConfig.answersCount)))
        for i in 0...AppConfig.answersCount {
            if i == randomCorrectAnswerIndex {
                currentAnswers.append(currentQuestioKana)
            }else {
                currentAnswers.append(randomKana(excludeRoma: currentQuestioKana[KanaType.roma.rawValue]))
            }
        }
        
        questionLabel.text = randomType(ofKana: currentQuestioKana)
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
    
    func randomType(ofKana kana:[String]) -> String {
        let index = Int(arc4random_uniform(UInt32(kana.count)))
        return kana[index]
    }

}

extension QuestionViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AnswerCell", for: indexPath) as! AnswerCell
        let kana = currentAnswers[indexPath.row]
        cell.backgroundColor = UIColor.clear
        cell.kanaLabel.textColor = UIColor.kanaBlackColor()
        cell.kanaLabel.text = randomType(ofKana: kana)
        
        if isShowingCorrectAnswer {
            if kana[KanaType.roma.rawValue] == currentQuestioKana[KanaType.roma.rawValue] {
                cell.backgroundColor = UIColor.kanaIncorrectAnswerBackgroundColor()
                cell.kanaLabel.textColor = UIColor.white
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let kana = currentAnswers[indexPath.row]
        answerAction(kana: kana)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4;
    }
    
    // Cell Size Change
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 150)
    }
    
}

