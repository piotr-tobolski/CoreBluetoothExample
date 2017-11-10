import Foundation
import Charts

func printFunction(name function: String = #function, _ args: Any?...) {
    let argsString = args.reduce("") {
            $0 + " | \($1 ?? "null")"
        }
    let line = "\n" + String(repeating: "-", count: 50)
    print(line, function, argsString)
}

let audioGenerator = AudioGenerator()

func update() {
    if audioGenerator.isPlaying {
        audioGenerator.stop()
    } else {
        audioGenerator.start()
    }
}

extension ViewController {

    func configureChart() {
        lineChartView.noDataTextColor = .red

        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.leftAxis.axisMaximum = 1000
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawLimitLinesBehindDataEnabled = false

        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.rightAxis.drawGridLinesEnabled = false
        lineChartView.rightAxis.drawLimitLinesBehindDataEnabled = false

        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.xAxis.drawAxisLineEnabled = false
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.drawLimitLinesBehindDataEnabled = false
        lineChartView.xAxis.axisMinimum = 0
        lineChartView.xAxis.axisMaximum = 99

        lineChartView.legend.form = .none

//        lineChartView.descriptionTextColor = .red
        lineChartView.chartDescription?.textColor = .red

        audioGenerator.setFrequency(440)
    }

    func appendChartValue(value: Double) {
        values.append(value)
        while values.count > 100 {
            values.removeFirst()
        }
        let chartValues = values.enumerated().map {
            ChartDataEntry(x: Double($0), y: $1)
        }

        if let data = lineChartView.data,
            data.dataSetCount > 0,
            let set = lineChartView.data?.dataSets[0] as? LineChartDataSet {
            set.values = chartValues
            lineChartView.data?.notifyDataChanged()
            lineChartView.notifyDataSetChanged()
        } else {
            let set = LineChartDataSet(values: chartValues, label: nil)
            set.setColor(.red)
            set.drawCirclesEnabled = false
            set.drawValuesEnabled = false
            set.drawVerticalHighlightIndicatorEnabled = false
            set.drawHorizontalHighlightIndicatorEnabled = false
            lineChartView.data = LineChartData(dataSets: [set])
        }
//        lineChartView.descriptionText = "\(value)"
        lineChartView.chartDescription?.text = "\(value)"

        audioGenerator.setFrequency(adjustFrequency(value))
    }

    func adjustFrequency(_ value: Double) -> Double {
        var targetFreq: Double = 0
        let adjustedValue = 4 * value
        for i in 4...39 {
            targetFreq = 220 * pow(2.0, Double(i)/12.0)
            if targetFreq > adjustedValue {
                let lowFreq = targetFreq * pow(2.0, -1.0/12.0)
                if (targetFreq - adjustedValue) > (adjustedValue - lowFreq) {
                    targetFreq = lowFreq
                }
                break
            }
        }
        return max(220, targetFreq)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func doubleTap(_ sender: UITapGestureRecognizer) {
        if view.backgroundColor == .black {
            view.backgroundColor = .white
        } else {
            view.backgroundColor = .black
        }
    }

    @IBAction func twoFingerTap(_ sender: UITapGestureRecognizer) {
        update()
    }
}
