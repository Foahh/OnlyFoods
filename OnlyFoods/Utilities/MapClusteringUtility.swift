//
//  MapClusteringUtility.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/24.
//
//  Reference: https://medium.com/@worthbak/clustering-with-mapkit-on-ios-11-a578baada84a

import Foundation
import MapKit
import UIKit

extension UIGraphicsImageRenderer {
  static func clusterImage(for annotations: [MKAnnotation], in rect: CGRect) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: rect.size)

    let totalCount = annotations.count
    let highRatedCount = annotations.highRatedRestaurantCount

    let countText = "\(totalCount)"

    return renderer.image { _ in
      // Green background circle
      UIColor(red: 126 / 255.0, green: 211 / 255.0, blue: 33 / 255.0, alpha: 1.0).setFill()
      UIBezierPath(ovalIn: rect).fill()

      // Orange pie slice for high-rated restaurants
      if highRatedCount > 0 {
        UIColor(red: 245 / 255.0, green: 166 / 255.0, blue: 35 / 255.0, alpha: 1.0).setFill()
        let piePath = UIBezierPath()
        piePath.addArc(
          withCenter: CGPoint(x: 20, y: 20),
          radius: 20,
          startAngle: 0,
          endAngle: (CGFloat.pi * 2.0 * CGFloat(highRatedCount)) / CGFloat(totalCount),
          clockwise: true
        )
        piePath.addLine(to: CGPoint(x: 20, y: 20))
        piePath.close()
        piePath.fill()
      }

      // White inner circle
      UIColor.white.setFill()
      UIBezierPath(ovalIn: CGRect(x: 8, y: 8, width: 24, height: 24)).fill()

      // Count text
      countText.drawClusterText(in: rect)
    }
  }
}

extension Sequence where Element == MKAnnotation {
  var highRatedRestaurantCount: Int {
    return
      self
      .compactMap { $0 as? RestaurantAnnotation }
      .filter { $0.rating.reviewCount > 0 && $0.rating.averageRating >= 4.0 }
      .count
  }
}

extension String {
  func drawClusterText(in rect: CGRect) {
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.black,
      .font: UIFont.boldSystemFont(ofSize: 14),
    ]
    let textSize = self.size(withAttributes: attributes)
    let textRect = CGRect(
      x: (rect.width / 2) - (textSize.width / 2),
      y: (rect.height / 2) - (textSize.height / 2),
      width: textSize.width,
      height: textSize.height
    )

    self.draw(in: textRect, withAttributes: attributes)
  }
}

extension UIColor {
  static func interpolate(
    from: UIColor,
    to: UIColor,
    via: UIColor,
    at value: CGFloat,
    midpoint: CGFloat
  ) -> UIColor {
    var fromR: CGFloat = 0
    var fromG: CGFloat = 0
    var fromB: CGFloat = 0
    var fromA: CGFloat = 0
    var toR: CGFloat = 0
    var toG: CGFloat = 0
    var toB: CGFloat = 0
    var toA: CGFloat = 0
    var viaR: CGFloat = 0
    var viaG: CGFloat = 0
    var viaB: CGFloat = 0
    var viaA: CGFloat = 0

    from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
    to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
    via.getRed(&viaR, green: &viaG, blue: &viaB, alpha: &viaA)

    let max: CGFloat = 5.0  // Rating scale is 0-5

    if value <= midpoint {
      // Interpolate from -> via (0.0 to midpoint)
      let t = value / midpoint
      let r = fromR + (viaR - fromR) * t
      let g = fromG + (viaG - fromG) * t
      let b = fromB + (viaB - fromB) * t
      let a = fromA + (viaA - fromA) * t
      return UIColor(red: r, green: g, blue: b, alpha: a)
    } else {
      // Interpolate via -> to (midpoint to max)
      let t = (value - midpoint) / (max - midpoint)
      let r = viaR + (toR - viaR) * t
      let g = viaG + (toG - viaG) * t
      let b = viaB + (toB - viaB) * t
      let a = viaA + (toA - viaA) * t
      return UIColor(red: r, green: g, blue: b, alpha: a)
    }
  }
}

extension UIImage {
  /// Creates an annotation image with a door image and rating border
  static func annotationImage(
    doorImage: UIImage?,
    rating: RestaurantRating,
    size: CGSize = CGSize(width: 40, height: 40),
    borderWidth: CGFloat = 3
  ) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { context in
      let rect = CGRect(origin: .zero, size: size)
      let imageRect = rect.insetBy(dx: borderWidth, dy: borderWidth)

      // Determine border color based on rating with linear interpolation
      let borderColor: UIColor
      if rating.reviewCount == 0 {
        borderColor = .gray
      } else {
        // Linear interpolation: Red (0.0) -> Orange (2.5) -> Green (5.0)
        let normalizedRating = max(0.0, min(5.0, rating.averageRating))
        borderColor = UIColor.interpolate(
          from: .systemRed,
          to: .systemGreen,
          via: .systemOrange,
          at: normalizedRating,
          midpoint: 2.5
        )
      }

      // Draw border circle
      borderColor.setFill()
      UIBezierPath(ovalIn: rect).fill()

      // Draw door image or placeholder
      if let doorImage = doorImage {
        // Clip to circle for the image
        let path = UIBezierPath(ovalIn: imageRect)
        path.addClip()

        // Draw the image
        doorImage.draw(in: imageRect)
      } else {
        // Draw placeholder
        UIColor.systemGray4.setFill()
        UIBezierPath(ovalIn: imageRect).fill()

        // Draw placeholder icon
        if let icon = UIImage(systemName: "photo") {
          let iconSize = min(imageRect.width, imageRect.height) * 0.5
          let iconRect = CGRect(
            x: imageRect.midX - iconSize / 2,
            y: imageRect.midY - iconSize / 2,
            width: iconSize,
            height: iconSize
          )
          icon.withTintColor(.systemGray2).draw(in: iconRect)
        }
      }
    }
  }
}
