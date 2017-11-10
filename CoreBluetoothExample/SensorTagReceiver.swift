import Foundation
import CoreBluetooth

class SensorTagReceiver: NSObject {
    var delegate: SensorTagReceiverDelegate
    var centralManager: CBCentralManager?
    var sensorTag: CBPeripheral?

    init(delegate: SensorTagReceiverDelegate) {
        self.delegate = delegate
    }

    func start() {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    func stop() {
        if let centralManager = centralManager {
            centralManager.stopScan()

            if let sensorTag = sensorTag {
                centralManager.cancelPeripheralConnection(sensorTag)
            }
        }

        centralManager = nil
        sensorTag = nil
    }
}

protocol SensorTagReceiverDelegate {
    func sensorTagReceiverReceivedLightValue(_ value: Double)
}

extension SensorTagReceiver: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        printFunction(central.state.rawValue)
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: nil)
        case .unsupported:
            fatalError("Run this app on device")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        printFunction(peripheral, advertisementData, RSSI)

        if currentPresentationStep >= 2,
            let name = peripheral.name,
            name.contains("SensorTag 2.0") {

            central.stopScan()
            sensorTag = peripheral
            peripheral.delegate = self
            central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        printFunction(peripheral)
        peripheral.discoverServices(nil)
    }
}

extension SensorTagReceiver: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        printFunction(peripheral, error)
        for service in peripheral.services! {
            print(service)

            if service.uuid == lightSensorServiceUUID ||
                service.uuid == keyPressServiceUUID ||
                currentPresentationStep == 2 {

                peripheral.discoverCharacteristics(nil, for: service)
//                peripheral.discoverIncludedServices(nil, for: service)
            }
        }
    }

    @objc(peripheral:didDiscoverCharacteristicsForService:error:)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        printFunction(service, error)
        for characteristic in service.characteristics! {
            print(characteristic)

            if currentPresentationStep >= 3 {
                switch characteristic.uuid {
                case lightSensorDataCharacteristicUUID:
                    fallthrough
                case keyPressCharacteristicUUID:
                    //Subscribe to notifications
                    peripheral.setNotifyValue(true, for: characteristic)

                case lightSensorConfigurationCharacteristicUUID:
                    //Enable sensor on device
                    peripheral.writeValue(Data(bytes: [UInt8(0x1)]),
                                          for: characteristic,
                                          type: .withResponse)

                case lightSensorPeriodCharacteristicUUID:
                    //Set interval to 100ms
                    peripheral.writeValue(Data(bytes: [UInt8(0xA)]),
                                          for: characteristic,
                                          type: .withResponse)
                default:
                    break
                }
            } else {
                peripheral.readValue(for: characteristic)
                peripheral.discoverDescriptors(for: characteristic)
            }
        }
    }

    @objc(peripheral:didUpdateValueForCharacteristic:error:)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        printFunction(characteristic, error)

        if characteristic.uuid == lightSensorDataCharacteristicUUID,
            let data = characteristic.value,
            data.count == 2, data[0] != 0xCC, data[1] != 0xCC,
            characteristic.uuid == lightSensorDataCharacteristicUUID {

            let e = data[1] >> 4
            let m = UInt16(data[0]) + (UInt16(data[1]) & 0x0F) << 8
            let value = Double(m) * (0.01 * pow(2.0, Double(e)))
            delegate.sensorTagReceiverReceivedLightValue(value)
        } else if characteristic.uuid == keyPressCharacteristicUUID,
            let data = characteristic.value,
            data.count == 1 {
            if data[0] == 3 {
                update()
            }

            print("big button \((data[0] & 1) > 0 ? "" : "not ")pressed")
            print("small button \((data[0] & 2) > 0 ? "" : "not ")pressed")
        }
    }
}

// MARK: Diagnostic logging
extension SensorTagReceiver {
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        printFunction(peripheral, error)
    }

    @objc(centralManager:didFailToConnectPeripheral:error:)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        printFunction(peripheral, error)
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        printFunction(peripheral.name)
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        printFunction(RSSI, error)
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        printFunction(invalidatedServices)
    }

    @objc(peripheral:didDiscoverDescriptorsForCharacteristic:error:)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        printFunction(characteristic, error)
        for descriptor in characteristic.descriptors! {
            print(descriptor)
            peripheral.readValue(for: descriptor)
        }
    }

    @objc(peripheral:didWriteValueForDescriptor:error:)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        printFunction(descriptor, error)
    }

    @objc(peripheral:didUpdateValueForDescriptor:error:)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        printFunction(descriptor, error)
    }

    @objc(peripheral:didDiscoverIncludedServicesForService:error:)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        printFunction(service, service.includedServices, error)
    }

    @objc(peripheral:didWriteValueForCharacteristic:error:)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        printFunction(characteristic, error)
    }

    @objc(peripheral:didUpdateNotificationStateForCharacteristic:error:)
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        printFunction(characteristic, characteristic.isNotifying, error)
    }
}
