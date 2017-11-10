import UIKit
import Charts

class ViewController: UIViewController, ChartViewDelegate {
    @IBOutlet var lineChartView: LineChartView!
    lazy var sensorTagReceiver: SensorTagReceiver = SensorTagReceiver(delegate: self)
    var values = [Double]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureChart()
        sensorTagReceiver.start()
    }
}

extension ViewController: SensorTagReceiverDelegate {
    func sensorTagReceiverReceivedLightValue(_ value: Double) {
        printFunction(value)
        appendChartValue(value: value)
    }
}
