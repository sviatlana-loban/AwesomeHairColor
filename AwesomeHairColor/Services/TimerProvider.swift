//
//  TimerProvider.swift
//  AwesomeHairColor
//
//  Created by Sviatlana Loban on 11/21/19.
//  Copyright © 2019 SLoban. All rights reserved.
//

import Foundation

final class TimerProvider {

    private var timer: Timer?
    private var runSecondsCounter = 0
    init() {}

    @objc private func runTimed() {
        runSecondsCounter += 1
        print(runSecondsCounter)
    }

    func start() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector:#selector(runTimed), userInfo: nil, repeats: true)
    }

    func getTimerString() -> String? {
        guard timer != nil else {
            return nil
        }
        let runMinutes = Int(runSecondsCounter) / 60 % 60
        let runSeconds = Int(runSecondsCounter) % 60

        return String(format: "%02d:%02d", runMinutes, runSeconds)
    }

    func stop() {
        runSecondsCounter = 0
        timer?.invalidate()
        timer = nil
    }
}
