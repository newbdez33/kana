//
//  ViewController.swift
//  kana
//
//  Created by JackyZ on 2017/01/07.
//  Copyright © 2017年 Salmonapps. All rights reserved.
//

import UIKit
import GoogleMobileAds
import AVFoundation

class QuestionViewController: UIViewController {

    private var practiceView: PracticeView { view as! PracticeView }
    var statisticsView: StatisticsView { practiceView.statisticsView }
    var bannerView: BannerView { practiceView.bannerView }
    var adViewHeight: NSLayoutConstraint { practiceView.bannerHeight }
    var questionLabel: UILabel { practiceView.questionLabel }
    var scrollView: UIScrollView { practiceView.scrollView }
    var collectionView: UICollectionView { practiceView.collectionView }
    private var bannerRequested = false
    private var requestedBannerSize: CGSize?
    
    var correctSoundEffect: AVAudioPlayer?
    var incorrectSoundEffect: AVAudioPlayer?
    
    var currentQuestioKana:[String] = []
    var currentAnswers:[[String]] = []
    var currentAnswerLabels:[String] = []
    var isShowingCorrectAnswer = false
    var timer:Timer?
    var currentQuestionStartTime:TimeInterval = 0
    private var questionPausedAt: TimeInterval?

    override func loadView() {
        view = PracticeView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .kanaKeyGrayColor()
        
        statisticsView.menuButton.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
        let menu = MenuViewController()
        addChild(menu)
        menu.view.translatesAutoresizingMaskIntoConstraints = false
        practiceView.menuContainer.addSubview(menu.view)
        NSLayoutConstraint.activate([
            menu.view.topAnchor.constraint(equalTo: practiceView.menuContainer.topAnchor),
            menu.view.bottomAnchor.constraint(equalTo: practiceView.menuContainer.bottomAnchor),
            menu.view.leadingAnchor.constraint(equalTo: practiceView.menuContainer.leadingAnchor),
            menu.view.trailingAnchor.constraint(equalTo: practiceView.menuContainer.trailingAnchor)
        ])
        menu.didMove(toParent: self)
        scrollView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self

        bannerView.adUnitID = "ca-app-pub-1295607594822275/7264793113"
        bannerView.rootViewController = self
        NotificationCenter.default.addObserver(self, selector: #selector(adsRemovedDidChange), name: .adsRemovedDidChange, object: nil)

        questionLabel.accessibilityIdentifier = "questionLabel"
        menuController?.setExpanded(false)

        collectionView.register(UINib(nibName: "AnswerCell", bundle: nil), forCellWithReuseIdentifier: "AnswerCell")

        prepareSoundEffects()
        nextQuestion()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AdsManager.shared.gatherConsent(from: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBannerSize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 
    func prepareSoundEffects() {
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers]) //Causes audio from other sessions to be ducked (reduced in volume) while audio from this session plays
        do {
            correctSoundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "correct.wav", ofType:nil)!))
            correctSoundEffect?.prepareToPlay()
            incorrectSoundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "incorrect.wav", ofType:nil)!))
            incorrectSoundEffect?.prepareToPlay()
        } catch {
            // couldn't load file :(
        }
        
    }
    func answerAction(index:Int) {
        if practiceView.isMenuExpanded { setMenuExpanded(false) }
        
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
            correctSoundEffect?.play()
            updateBestCombo(is_correct: true)
            addStat(index: index, is_correct: true, cost: cost)
            nextQuestion()
        }else {
            //incorrect
            incorrectSoundEffect?.play()
            updateBestCombo(is_correct: false)
            addStat(index: index, is_correct: false, cost: cost)
            incorrect()
        }
        
    }
    
    func incorrect() {
        updateStatisticsLabels()
        
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
        StatStore.shared.add(cost: cost, isCorrect: is_correct)
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
        isShowingCorrectAnswer = false
        
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
        
        currentQuestionStartTime = Date().timeIntervalSince1970 //timestamp
        questionPausedAt = practiceView.isMenuExpanded ? currentQuestionStartTime : nil
        startQuestionTimer()
        
        updateStatisticsLabels()
    }

    private func startQuestionTimer() {
        timer?.invalidate()
        timer = nil
        guard questionPausedAt == nil, !isShowingCorrectAnswer else { return }
        let remaining = AppConfig.questionTimeLimit - (Date().timeIntervalSince1970 - currentQuestionStartTime)
        timer = Timer.scheduledTimer(withTimeInterval: max(remaining, 0.01), repeats: false) { [weak self] _ in
            guard let self else { return }
            self.updateBestCombo(is_correct: false)
            self.addStat(index: 0, is_correct: false, cost: 0)
            self.incorrect()
        }
    }
    
    func updateStatisticsLabels() {
        let stats = StatStore.shared
        let best = UserDefaults.standard.integer(forKey: AppConfig.keyBestCombo)
        statisticsView.update(totalCount: stats.totalCount, averageTime: stats.totalAvgTime,
                              recentTime: stats.lastAvgTime, bestCombo: best)
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
    
    /// The menu row embedded above the question (revealed by pulling down).
    var menuController: MenuViewController? {
        return children.compactMap { $0 as? MenuViewController }.first
    }

    @objc private func toggleMenu() {
        setMenuExpanded(!practiceView.isMenuExpanded)
    }

    func setMenuExpanded(_ expanded: Bool) {
        guard expanded != practiceView.isMenuExpanded else { return }
        practiceView.isMenuExpanded = expanded
        if expanded {
            timer?.invalidate()
            timer = nil
            questionPausedAt = Date().timeIntervalSince1970
        } else if let pausedAt = questionPausedAt {
            // Time spent in the menu or support sheet is not answer time.
            currentQuestionStartTime += Date().timeIntervalSince1970 - pausedAt
            questionPausedAt = nil
            startQuestionTimer()
        }
        menuController?.setExpanded(expanded)
        statisticsView.menuButton.setImage(UIImage(systemName: expanded ? "chevron.up" : "line.3.horizontal"), for: .normal)
        statisticsView.menuButton.accessibilityLabel = expanded ? .closeMenu : .menu
        UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    func hideBanner() {
        bannerRequested = false
        requestedBannerSize = nil
        adViewHeight.constant = 0
        bannerView.isHidden = true
    }
    
    func showBanner() {
        guard !Store.shared.adsRemoved, AdsManager.shared.isReady else { return }
        bannerRequested = true
        view.layoutIfNeeded()
        updateBannerSize()
    }

    private func updateBannerSize() {
        guard bannerRequested, bannerView.bounds.width > 0 else { return }
        let size = currentOrientationAnchoredAdaptiveBanner(width: bannerView.bounds.width)
        guard size.size != requestedBannerSize else { return }
        requestedBannerSize = size.size
        bannerView.adSize = size
        bannerView.isHidden = false
        adViewHeight.constant = size.size.height
        bannerView.load(Request())
    }

    @objc func adsRemovedDidChange() {
        if Store.shared.adsRemoved {
            hideBanner()
        }
    }

}

extension QuestionViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging || scrollView.isDecelerating else { return }
        if !practiceView.isMenuExpanded {
            if scrollView.contentOffset.y + scrollView.adjustedContentInset.top < -60 {
                setMenuExpanded(true)
            }
        }else {
            if scrollView.contentOffset.y >= 80 {
                setMenuExpanded(false)
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
        return CGSize(width: collectionView.bounds.width/2, height: collectionView.bounds.height/2)
    }
    
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
