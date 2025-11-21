//
//  TimeService.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import Combine
import Foundation

class TimeService: ObservableObject {
  @Published var currentTime: Date = Date()
  
  static let shared = TimeService()
  
  private var timer: Timer?
  
  private init() {
    startTimer()
  }
  
  deinit {
    stopTimer()
  }
  
  private func startTimer() {
    // Update immediately
    currentTime = Date()
    
    // Set up timer to update every minute
    timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
      self?.currentTime = Date()
    }
  }
  
  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }
}

