import AVFoundation
import Foundation
import SwiftUI

/// A verse reference inside the Quran.
struct AyahRef: Hashable, Identifiable {
    let surah: Int
    let ayah: Int
    var id: Int { surah * 1000 + ayah }
}

/// Streams one verse at a time and moves through the whole Quran, one verse after another.
@MainActor
final class MushafPlayer: ObservableObject {
    /// Verse the reader has selected (tapped), or is playing.
    @Published private(set) var selected: AyahRef?
    /// Verse whose audio is currently loaded.
    @Published private(set) var loaded: AyahRef?
    @Published private(set) var isPlaying = false

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private let order: [AyahRef]
    private let indexOf: [AyahRef: Int]

    init() {
        var refs: [AyahRef] = []
        for surah in QuranStore.shared.surahs {
            for ayah in 1...max(surah.ayahCount, 1) {
                refs.append(AyahRef(surah: surah.number, ayah: ayah))
            }
        }
        order = refs
        var map: [AyahRef: Int] = [:]
        for (i, ref) in refs.enumerated() { map[ref] = i }
        indexOf = map
    }

    func select(_ ref: AyahRef) {
        selected = ref
    }

    /// Plays the selected verse, or pauses and resumes it when it is already loaded.
    func togglePlay(reciter: Reciter) {
        guard let current = selected else { return }
        if loaded != current {
            play(current, reciter: reciter)
        } else if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
    }

    /// Moves to the previous (-1) or next (+1) verse and starts it.
    func step(_ delta: Int, reciter: Reciter) {
        guard let current = selected, let i = indexOf[current] else { return }
        let target = i + delta
        guard order.indices.contains(target) else { return }
        play(order[target], reciter: reciter)
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        removeObserver()
    }

    private func play(_ ref: AyahRef, reciter: Reciter) {
        selected = ref
        loaded = ref
        removeObserver()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        let item = AVPlayerItem(url: reciter.url(surah: ref.surah, ayah: ref.ayah))
        let p = AVPlayer(playerItem: item)
        player = p
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.finished(ref, reciter: reciter)
            }
        }
        p.play()
        isPlaying = true
    }

    private func finished(_ ref: AyahRef, reciter: Reciter) {
        guard let i = indexOf[ref], order.indices.contains(i + 1) else {
            isPlaying = false
            return
        }
        play(order[i + 1], reciter: reciter)
    }

    private func removeObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }
}
