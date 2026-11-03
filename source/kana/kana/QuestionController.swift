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
    
    private let feedbackPlayer = PracticeFeedbackPlayer()
    private var feedbackRun = PracticeFeedback(bestStreak: 0)
    var feedbackSettings = FeedbackSettings() {
        didSet { stopFeedback(); updateFeedback() }
    }
    private var inBackground = false
    private var viewHidden = false
    private var audioInterrupted = false
    private var hasInteracted = false
    private var lastBeat: TimeInterval = 0
    var now: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    
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
        feedbackRun = PracticeFeedback(bestStreak: bestStreak)
        
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

        NotificationCenter.default.addObserver(self, selector: #selector(backgroundEntered), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(foregroundEntered), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionChanged), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPause), name: .adConsentVisibilityDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(motionChanged), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        nextQuestion()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHidden = false
        refreshPause()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewHidden = true
        refreshPause()
    }

    deinit { timer?.invalidate() }

    func answerAction(index: Int) {
        guard currentAnswers.indices.contains(index), !inBackground, !viewHidden,
              !audioInterrupted, !AdsManager.shared.isConsentVisible, presentedViewController == nil else { return }
        if practiceView.isMenuExpanded { setMenuExpanded(false) }
        guard questionPausedAt == nil else { return }
        hasInteracted = true
        let isCorrect = currentAnswers[index][KanaType.roma.rawValue] == currentQuestioKana[KanaType.roma.rawValue]
        if isShowingCorrectAnswer {
            emitFeedback(FeedbackEvent(kind: .correction, streak: currentStreak, stage: PracticeFeedback.stage(for: currentStreak)))
            if isCorrect { nextQuestion() }
            return
        }
        let cost = now() - currentQuestionStartTime
        guard cost < AppConfig.questionTimeLimit else { timeout(); return }
        timer?.invalidate()
        timer = nil
        updateBestCombo(is_correct: isCorrect)
        addStat(index: index, is_correct: isCorrect, cost: cost)
        if isCorrect {
            let event = feedbackRun.correct(streak: currentStreak)
            nextQuestion()
            emitFeedback(event)
        } else {
            incorrect()
            emitFeedback(feedbackRun.broken(bestStreak: bestStreak))
        }
    }

    private var currentStreak: Int { UserDefaults.standard.integer(forKey: AppConfig.keyCurrentCombo) }
    private var bestStreak: Int { UserDefaults.standard.integer(forKey: AppConfig.keyBestCombo) }
    private var reducedMotion: Bool { feedbackSettings.reducedMotion || UIAccessibility.isReduceMotionEnabled }

    private func emitFeedback(_ event: FeedbackEvent) {
        feedbackPlayer.play(event, settings: feedbackSettings)
        practiceView.feedbackView.show(event, reducedMotion: reducedMotion)
    }

    private func timeout() {
        guard !isShowingCorrectAnswer, questionPausedAt == nil else { return }
        timer?.invalidate()
        timer = nil
        updateBestCombo(is_correct: false)
        incorrect()
        emitFeedback(feedbackRun.broken(bestStreak: bestStreak))
    }

    private func stopFeedback() {
        feedbackPlayer.stop()
        practiceView.feedbackView.stop()
        lastBeat = now()
    }

    private func updateFeedback() {
        let active = questionPausedAt == nil && !isShowingCorrectAnswer
        let remaining = isShowingCorrectAnswer ? 0 : AppConfig.questionTimeLimit - ((questionPausedAt ?? now()) - currentQuestionStartTime)
        practiceView.feedbackView.update(streak: currentStreak, remaining: remaining, active: active)
        let bpm = PracticeFeedback.bpm(for: PracticeFeedback.stage(for: currentStreak))
        if active && hasInteracted && feedbackSettings.sound && feedbackSettings.rhythm && bpm > 0,
           now() - lastBeat >= 60 / Double(bpm) {
            lastBeat = now()
            feedbackPlayer.beat()
            practiceView.feedbackView.beat(reducedMotion: reducedMotion)
        }
    }

    @objc private func backgroundEntered() { inBackground = true; refreshPause() }
    @objc private func foregroundEntered() { inBackground = false; refreshPause() }
    @objc private func motionChanged() { stopFeedback(); updateFeedback() }
    @objc private func audioSessionChanged(_ notification: Notification) {
        guard let value = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: value) else { return }
        audioInterrupted = type == .began
        refreshPause()
    }

    @objc func refreshPause() {
        let paused = practiceView.isMenuExpanded || inBackground || viewHidden || audioInterrupted || AdsManager.shared.isConsentVisible
        if paused && questionPausedAt == nil {
            questionPausedAt = now()
            timer?.invalidate()
            timer = nil
            stopFeedback()
        } else if !paused, let started = questionPausedAt {
            currentQuestionStartTime += now() - started
            questionPausedAt = nil
            lastBeat = now()
            startQuestionTimer()
        }
        updateFeedback()
    }

    func incorrect() {
        updateStatisticsLabels()
        
        showBanner()
        
        let correct_idx = findCorrectAnswerIndex()
        
        isShowingCorrectAnswer = true
        stopFeedback()
        updateFeedback()
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
        for i in 0..<AppConfig.answersCount {
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
        
        currentQuestionStartTime = now()
        questionPausedAt = (practiceView.isMenuExpanded || inBackground || viewHidden || audioInterrupted || AdsManager.shared.isConsentVisible) ? currentQuestionStartTime : nil
        startQuestionTimer()
        
        updateStatisticsLabels()
    }

    private func startQuestionTimer() {
        timer?.invalidate()
        timer = nil
        guard questionPausedAt == nil, !isShowingCorrectAnswer else { return }
        updateFeedback()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.now() - self.currentQuestionStartTime >= AppConfig.questionTimeLimit {
                self.timeout()
            } else {
                self.updateFeedback()
            }
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
        refreshPause()
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
