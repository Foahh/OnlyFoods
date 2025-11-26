//
//  ImageFilterUtility.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/23.
//

import CoreImage
import UIKit

enum ImageFilter: String, CaseIterable, Identifiable {
  case none = "None"
  case vibrant = "Vibrant"
  case warm = "Warm"
  case cool = "Cool"
  case saturated = "Saturated"
  case vintage = "Vintage"
  case blackWhite = "Black & White"
  case highContrast = "High Contrast"

  var id: String { rawValue }

  var displayName: String { rawValue }

  var icon: String {
    switch self {
    case .none:
      return "photo"
    case .vibrant:
      return "sparkles"
    case .warm:
      return "sun.max.fill"
    case .cool:
      return "snowflake"
    case .saturated:
      return "paintpalette.fill"
    case .vintage:
      return "camera.filters"
    case .blackWhite:
      return "circle.lefthalf.filled"
    case .highContrast:
      return "circle.righthalf.filled"
    }
  }
}

struct ImageFilterUtility {
  static let context = CIContext(options: [.useSoftwareRenderer: false])

  static func applyFilter(_ filter: ImageFilter, to image: UIImage) -> UIImage? {
    guard filter != .none else { return image }

    guard let ciImage = CIImage(image: image) else { return image }

    let filteredImage: CIImage

    switch filter {
    case .none:
      return image

    case .vibrant:
      // Enhanced colors with slight saturation boost
      guard let colorControls = CIFilter(name: "CIColorControls") else { return image }
      colorControls.setValue(ciImage, forKey: kCIInputImageKey)
      colorControls.setValue(1.1, forKey: kCIInputSaturationKey)
      colorControls.setValue(1.05, forKey: kCIInputContrastKey)

      filteredImage = colorControls.outputImage ?? ciImage

    case .warm:
      // Warm tones with temperature adjustment
      guard let temperature = CIFilter(name: "CITemperatureAndTint") else { return image }
      temperature.setValue(ciImage, forKey: kCIInputImageKey)
      temperature.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
      temperature.setValue(CIVector(x: 5500, y: 0), forKey: "inputTargetNeutral")
      filteredImage = temperature.outputImage ?? ciImage

    case .cool:
      // Cool tones with temperature adjustment
      guard let temperature = CIFilter(name: "CITemperatureAndTint") else { return image }
      temperature.setValue(ciImage, forKey: kCIInputImageKey)
      temperature.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
      temperature.setValue(CIVector(x: 7500, y: 0), forKey: "inputTargetNeutral")
      filteredImage = temperature.outputImage ?? ciImage

    case .saturated:
      // High saturation for vibrant food colors
      guard let colorControls = CIFilter(name: "CIColorControls") else { return image }
      colorControls.setValue(ciImage, forKey: kCIInputImageKey)
      colorControls.setValue(1.3, forKey: kCIInputSaturationKey)
      colorControls.setValue(1.05, forKey: kCIInputContrastKey)
      filteredImage = colorControls.outputImage ?? ciImage

    case .vintage:
      // Vintage/retro look with sepia and reduced saturation
      guard let sepia = CIFilter(name: "CISepiaTone") else { return image }
      sepia.setValue(ciImage, forKey: kCIInputImageKey)
      sepia.setValue(0.3, forKey: kCIInputIntensityKey)

      if let sepiaOutput = sepia.outputImage,
        let colorControls = CIFilter(name: "CIColorControls")
      {
        colorControls.setValue(sepiaOutput, forKey: kCIInputImageKey)
        colorControls.setValue(0.8, forKey: kCIInputSaturationKey)
        colorControls.setValue(0.95, forKey: kCIInputContrastKey)
        filteredImage = colorControls.outputImage ?? sepiaOutput
      } else {
        filteredImage = sepia.outputImage ?? ciImage
      }

    case .blackWhite:
      // Black and white conversion
      guard let mono = CIFilter(name: "CIColorMonochrome") else { return image }
      mono.setValue(ciImage, forKey: kCIInputImageKey)
      mono.setValue(CIColor.gray, forKey: kCIInputColorKey)
      mono.setValue(1.0, forKey: kCIInputIntensityKey)
      filteredImage = mono.outputImage ?? ciImage

    case .highContrast:
      // High contrast for dramatic effect
      guard let colorControls = CIFilter(name: "CIColorControls") else { return image }
      colorControls.setValue(ciImage, forKey: kCIInputImageKey)
      colorControls.setValue(1.3, forKey: kCIInputContrastKey)
      colorControls.setValue(1.1, forKey: kCIInputSaturationKey)
      filteredImage = colorControls.outputImage ?? ciImage
    }

    guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
      return image
    }

    return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
  }
}
