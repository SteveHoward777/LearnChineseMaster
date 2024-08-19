import Foundation
import AVKit
import SwiftUI

struct Flashcard: Identifiable {
    let id = UUID()
    let pinyin: String
    let chinese: String
    let russian: String
    let english: String
}

struct FlashcardManager {
    static func getFlashcards(for lesson: Int) -> [Flashcard] {
        switch lesson {
        case 1:
            return Lesson1Flashcards.data
        case 2:
            return Lesson2Flashcards.data
        case 3:
            return Lesson3Flashcards.data
        case 4:
            return Lesson4Flashcards.data
        case 5:
            return Lesson5Flashcards.data
        case 6:
            return Lesson6Flashcards.data
        case 7:
            return Lesson7Flashcards.data
        case 8:
            return Lesson8Flashcards.data
        case 9:
            return Lesson9Flashcards.data
        case 10:
            return Lesson10Flashcards.data
        case 11:
            return Lesson11Flashcards.data
        case 12:
            return Lesson12Flashcards.data
        case 13:
            return Lesson13Flashcards.data
        case 14:
            return Lesson14Flashcards.data
        case 15:
            return Lesson15Flashcards.data
        case 16:
            return Lesson16Flashcards.data
        case 17:
            return Lesson17Flashcards.data
        case 18:
            return Lesson18Flashcards.data
        case 19:
            return Lesson19Flashcards.data
        case 20:
            return Lesson20Flashcards.data
        case 21:
            return Lesson21Flashcards.data
        case 22:
            return Lesson22Flashcards.data
        case 23:
            return Lesson23Flashcards.data
        case 24:
            return Lesson24Flashcards.data
        case 25:
            return Lesson25Flashcards.data
        case 26:
            return Lesson26Flashcards.data
        case 27:
            return Lesson27Flashcards.data
        case 28:
            return Lesson28Flashcards.data
        case 29:
            return Lesson29Flashcards.data
        case 30:
            return Lesson30Flashcards.data
        case 31:
            return Lesson31Flashcards.data
        case 32:
            return Lesson32Flashcards.data
        case 33:
            return Lesson33Flashcards.data
        case 34:
            return Lesson34Flashcards.data
        case 35:
            return Lesson35Flashcards.data
        default:
            return []
        }
    }
    
    static func getFlashcards(from startLesson: Int, to endLesson: Int) -> [Flashcard] {
        var flashcards: [Flashcard] = []
        for lesson in startLesson...endLesson {
            flashcards.append(contentsOf: getFlashcards(for: lesson))
        }
        return flashcards
    }
}

struct VideoBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return LoopingPlayerUIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

class LoopingPlayerUIView: UIView {
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        guard let path = Bundle.main.path(forResource: "Space", ofType: "MOV") else {
            print("Video file not found")
            return
        }

        let asset = AVAsset(url: URL(fileURLWithPath: path))
        let playerItem = AVPlayerItem(asset: asset)

        let player = AVQueuePlayer()
        player.isMuted = true // Optional: Mute the video if needed
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.addSublayer(playerLayer)

        self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)

        player.play()
        
        self.player = player
        self.playerLayer = playerLayer

        // Add observers for app lifecycle
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc private func applicationWillEnterForeground() {
        player?.play()
    }

    @objc private func applicationDidEnterBackground() {
        player?.pause()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.forEach { $0.frame = bounds }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
