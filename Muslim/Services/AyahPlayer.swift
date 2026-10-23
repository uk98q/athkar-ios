import AVFoundation
import Foundation

/// Streams one ayah at a time from everyayah.com and advances to the next ayah when it ends.
@MainActor
final class AyahPlayer: ObservableObject {
    @Published private(set) var surah: QuranSurah?
    @Published private(set) var index: Int = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var failed = false

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?

    func play(surah: QuranSurah, ayahIndex: Int, reciter: Reciter) {
        configureSession()
        self.surah = surah
        index = max(0, min(ayahIndex, surah.ayahCount - 1))
        load(reciter: reciter, autoplay: true)
    }

    func togglePlay(reciter: Reciter) {
        guard let surah else { return }
        guard let player else {
            play(surah: surah, ayahIndex: index, reciter: reciter)
            return
        }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func next(reciter: Reciter) {
        guard let surah else { return }
        if index + 1 < surah.ayahCount {
            index += 1
            load(reciter: reciter, autoplay: true)
        } else {
            stop()
        }
    }

    func previous(reciter: Reciter) {
        guard surah != nil, index > 0 else { return }
        index -= 1
        load(reciter: reciter, autoplay: true)
    }

    func stop() {
        player?.pause()
        isPlaying = false
    }

    private func load(reciter: Reciter, autoplay: Bool) {
        guard let surah else { return }
        failed = false
        removeEndObserver()
        let item = AVPlayerItem(url: reciter.url(surah: surah.number, ayah: index + 1))
        if let player {
            player.replaceCurrentItem(with: item)
        } else {
            player = AVPlayer(playerItem: item)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.next(reciter: reciter)
            }
        }
        if autoplay {
            player?.play()
            isPlaying = true
        }
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }
}
