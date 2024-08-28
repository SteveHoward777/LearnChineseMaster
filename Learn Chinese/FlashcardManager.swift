import Foundation
import SwiftUI
import AVKit
import UIKit

// Flashcard Struct
struct Flashcard: Identifiable, Codable {
    let id: UUID
    let pinyin: String
    let chinese: String
    let russian: String
    let english: String
    
    // Custom decoder to assign UUID during JSON decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate a new UUID for each decoded flashcard
        self.pinyin = try container.decode(String.self, forKey: .pinyin)
        self.chinese = try container.decode(String.self, forKey: .chinese)
        self.russian = try container.decode(String.self, forKey: .russian)
        self.english = try container.decode(String.self, forKey: .english)
    }
    
    init(id: UUID = UUID(), pinyin: String, chinese: String, russian: String, english: String) {
        self.id = id
        self.pinyin = pinyin
        self.chinese = chinese
        self.russian = russian
        self.english = english
    }
}

// Flashcard Manager
struct FlashcardManager {
    static func getFlashcards(for lesson: Int) -> [Flashcard] {
        let fileName = "Lesson\(lesson)Flashcards.json"
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("File not found: \(fileName)")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let flashcards = try decoder.decode([Flashcard].self, from: data)
            return flashcards
        } catch {
            print("Failed to load or decode file: \(fileName), error: \(error)")
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

// Video Background View
struct VideoBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return LoopingPlayerUIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// Looping Video Player
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
