import Foundation
import CoreBluetooth

let lightSensorServiceUUID = CBUUID(string: "F000AA70-0451-4000-B000-000000000000")
let keyPressServiceUUID = CBUUID(string: "FFE0")

/// LightLSB:LightMSB
let lightSensorDataCharacteristicUUID = CBUUID(string: "F000AA71-0451-4000-B000-000000000000")
let keyPressCharacteristicUUID = CBUUID(string: "FFE1")

/// Write 0x01 to enable data collection, 0x00 to disable.
let lightSensorConfigurationCharacteristicUUID = CBUUID(string: "F000AA72-0451-4000-B000-000000000000")

/// Resolution 10 ms. Range 100 ms (0x0A) to 2.55 sec (0xFF). Default is 800 milliseconds (0x50).
let lightSensorPeriodCharacteristicUUID = CBUUID(string: "F000AA73-0451-4000-B000-000000000000")

let currentPresentationStep = 3 // 1~3
