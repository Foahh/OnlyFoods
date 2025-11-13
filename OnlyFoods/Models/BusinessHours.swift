//
//  RestaurantModel.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation

struct TimeRange: Codable {
  var start: String
  var end: String

  /// Checks if the given time (in "HH:mm" format) is within this time range
  func contains(time: String) -> Bool {
    guard let openTime = parseTime(start),
      let closeTime = parseTime(end),
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

struct DayHours: Codable {
  var dayOfWeek: Int  // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
  var isClosed: Bool
  var is24hr: Bool
  var periods: [TimeRange]
}

struct BusinessHours: Codable {
  var days: [DayHours]

  // Custom Codable implementation to decode directly from array
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    days = try container.decode([DayHours].self)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(days)
  }

  init(days: [DayHours] = []) {
    self.days = days
  }

  /// Gets the day hours for a specific weekday
  func dayHoursForWeekday(_ calendarWeekday: Int) -> DayHours? {
    guard calendarWeekday >= 1 && calendarWeekday <= 7 else {
      return nil
    }

    return days.first { $0.dayOfWeek == calendarWeekday }
  }

  /// Gets the time ranges for a specific weekday
  func hoursForWeekday(_ calendarWeekday: Int) -> [TimeRange]? {
    return dayHoursForWeekday(calendarWeekday)?.periods
  }

  /// Checks if the restaurant is open at the current time
  func isCurrentlyOpen() -> Bool {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: Date())

    guard let dayHours = dayHoursForWeekday(weekday) else {
      return false
    }

    // If the day is marked as closed, return false
    if dayHours.isClosed {
      return false
    }

    // If the day is 24 hours, return true
    if dayHours.is24hr {
      return true
    }

    // Otherwise, check if current time falls within any of the time ranges for today
    return dayHours.periods.contains { $0.containsCurrentTime() }
  }

  /// Checks if the restaurant is open at a specific date
  func isOpen(at date: Date) -> Bool {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date)

    guard let dayHours = dayHoursForWeekday(weekday) else {
      return false
    }

    // If the day is marked as closed, return false
    if dayHours.isClosed {
      return false
    }

    // If the day is 24 hours, return true
    if dayHours.is24hr {
      return true
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    let timeString = formatter.string(from: date)

    // Check if the given time falls within any of the time ranges for that day
    return dayHours.periods.contains { $0.contains(time: timeString) }
  }
}
