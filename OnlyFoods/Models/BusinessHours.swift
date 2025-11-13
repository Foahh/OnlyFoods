
//
//  RestaurantModel.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation

struct TimeRange: Codable {
  var open: String
  var close: String

  /// Checks if the given time (in "HH:mm" format) is within this time range
  func contains(time: String) -> Bool {
    guard let openTime = parseTime(open),
      let closeTime = parseTime(close),
      let checkTime = parseTime(time)
    else {
      return false
    }

    // Handle case where close time is next day (e.g., 23:00 to 02:00)
    if closeTime < openTime {
      return checkTime >= openTime || checkTime <= closeTime
    } else {
      return checkTime >= openTime && checkTime <= closeTime
    }
  }

  /// Checks if the current time is within this time range
  func containsCurrentTime() -> Bool {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    let currentTimeString = formatter.string(from: Date())
    return contains(time: currentTimeString)
  }

  /// Parses a time string in "HH:mm" format to minutes since midnight
  private func parseTime(_ timeString: String) -> Int? {
    let components = timeString.split(separator: ":")
    guard components.count == 2,
      let hours = Int(components[0]),
      let minutes = Int(components[1]),
      hours >= 0 && hours < 24,
      minutes >= 0 && minutes < 60
    else {
      return nil
    }
    return hours * 60 + minutes
  }
}

struct BusinessHours: Codable {
  var monday: [TimeRange]?
  var tuesday: [TimeRange]?
  var wednesday: [TimeRange]?
  var thursday: [TimeRange]?
  var friday: [TimeRange]?
  var saturday: [TimeRange]?
  var sunday: [TimeRange]?

  /// Gets the time ranges for a specific weekday (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
  func hoursForWeekday(_ weekday: Int) -> [TimeRange]? {
    switch weekday {
    case 1: return sunday
    case 2: return monday
    case 3: return tuesday
    case 4: return wednesday
    case 5: return thursday
    case 6: return friday
    case 7: return saturday
    default: return nil
    }
  }

  /// Checks if the restaurant is open at the current time
  func isCurrentlyOpen() -> Bool {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())

    guard let timeRanges = hoursForWeekday(weekday) else {
      return false
    }

    // Check if current time falls within any of the time ranges for today
    return timeRanges.contains { $0.containsCurrentTime() }
  }

  /// Checks if the restaurant is open at a specific date
  func isOpen(at date: Date) -> Bool {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date)

    guard let timeRanges = hoursForWeekday(weekday) else {
      return false
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    let timeString = formatter.string(from: date)

    // Check if the given time falls within any of the time ranges for that day
    return timeRanges.contains { $0.contains(time: timeString) }
  }
}
