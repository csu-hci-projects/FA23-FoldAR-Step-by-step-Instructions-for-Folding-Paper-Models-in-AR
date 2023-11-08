//
//  HandGestureProcessor.swift
//  FoldAR_4
//
//  Created by Tom Cavey & Tani Cath on 11/02/23.

import CoreGraphics
import UIKit

class HandGestureProcessor
{
    // CONSTANTS
    var startCollection = false
    var savedName = "none"
    var switchState = 0
    var frameCounter = 0
    private let writeInterval = 5
    
    
    private let headers = "pid, mode, frame, date, time (MST), thumbTip.x, thumbTip.y, thumbIP.x, thumbIP.y, thumbMP.x, thumbMP.y, thumbCMC.x, thumbCMC.y, thumbTip2.x, thumbTip2.y, thumbIP2.x, thumbIP2.y, thumbMP2.x, thumbMP2.y, thumbCMC2.x, thumbCMC2.y, indexTip.x, indexTip.y, indexPIP.x, indexPIP.y, indexDIP.x, indexDIP.y, indexMCP.x, indexMCP.y, indexTip2.x, indexTip2.y, indexPIP2.x, indexPIP2.y, indexDIP2.x, indexDIP2.y, indexMCP2.x, indexMCP2.y, middleTip.x, middleTip.y, middlePIP.x, middlePIP.y, middleDIP.x, middleDIP.y, middleMCP.x, middleMCP.y, middleTip2.x, middleTip2.y, middlePIP2.x, middlePIP2.y, middleDIP2.x, middleDIP2.y, middleMCP2.x, middleMCP2.y, ringTip.x, ringTip.y, ringPIP.x, ringPIP.y, ringDIP.x, ringDIP.y, ringMCP.x, ringMCP.y, ringTip2.x, ringTip2.y, ringPIP2.x, ringPIP2.y, ringDIP2.x, ringDIP2.y, ringMCP2.x, ringMCP2.y, littleTip.x, littleTip.y, littlePIP.x, littlePIP.y, littleDIP.x, littleDIP.y, littleMCP.x, littleMCP.y, littleTip2.x, littleTip2.y, littlePIP2.x, littlePIP2.y, littleDIP2.x, littleDIP2.y, littleMCP2.x, littleMCP2.y\n"
    
    
    enum State
    {
        case thumbUp
        case thumbDown
        case unknown
    }
    
    typealias PointsPair = (thumbTip: CGPoint, thumbBase: CGPoint, thumbIP: CGPoint, thumbMP: CGPoint,
                            thumbTip2: CGPoint, thumbBase2: CGPoint, thumbIP2: CGPoint, thumbMP2: CGPoint,
                            indexTip: CGPoint, indexPIP: CGPoint, indexDIP: CGPoint, indexMCP: CGPoint,
                            indexTip2: CGPoint, indexPIP2: CGPoint, indexDIP2: CGPoint, indexMCP2: CGPoint,
                            middleTip: CGPoint, middlePIP: CGPoint, middleDIP: CGPoint, middleMCP: CGPoint,
                            middleTip2: CGPoint, middlePIP2: CGPoint, middleDIP2: CGPoint, middleMCP2: CGPoint,
                            ringTip: CGPoint, ringPIP: CGPoint, ringDIP: CGPoint, ringMCP: CGPoint,
                            ringTip2: CGPoint, ringPIP2: CGPoint, ringDIP2: CGPoint, ringMCP2: CGPoint,
                            littleTip: CGPoint, littlePIP: CGPoint, littleDIP: CGPoint, littleMCP: CGPoint,
                            littleTip2: CGPoint, littlePIP2: CGPoint, littleDIP2: CGPoint, littleMCP2: CGPoint)
    
//    typealias PointsPair = [CGPoint]
    
    private var state = State.unknown {
        didSet {
            didChangeStateClosure?(state)
        }
    }
    
    var didChangeStateClosure: ((State) -> Void)?
    private (set) var lastProcessedPointsPair = PointsPair(.zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero,
                                                           .zero, .zero, .zero, .zero)
    
    func processPointsPair(_ pointsPair: [CGPoint], pp:PointsPair)
    {
        lastProcessedPointsPair = pp
        state = .unknown
        
        // This stores the captured data in the Documents folder that is accessible via Xcode.
        // Because this app is sandboxed, the only way to get the data is through the following menu:
        // Window -> Devices and Simulators -> Find name of the app -> click 3 dots with circle ->
        // select "Download Container" -> navigate to the container in the finder window -> right click
        // then select "Show Package Contents" -> AppData -> Documents. Here you will find the .txt folder
        // that is used below!
        if startCollection
        {
            // We will only do this once every 5 frames.
            frameCounter += 1
            if (frameCounter % writeInterval) == 0
            {
                let text = generateData(savedName: savedName, mode: switchState, frame: frameCounter-writeInterval, pointsPair: pointsPair)
                // Generate text
                
                writeToFile(fileName: "sessionData3.csv", data: text, headers: headers)
                
            }
        }
        else{
            frameCounter = 0
        }
    }
    
    func generateData(savedName:String, mode: Int, frame:Int, pointsPair: [CGPoint]) -> String{
        var pID = "none"
        if savedName != ""{
            pID = savedName
        }

        let timestamp = Date.now.formatted()
        var modeName = ""
        switch mode {
        case 0:
            modeName = "full"
        case 1:
            modeName = "hands"
        case 2:
            modeName = "blind"
        default:
            modeName = ""
        }
        var row = "\(pID), \(modeName), \(String(frame)), \(timestamp)"
        
        for (_, value) in pointsPair.enumerated(){
            row += ", \(value.x), \(value.y)"
        }
        row += "\n"
        return row
    }
    
    func writeToFile(fileName:String, data:String, headers:String){
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            let path = fileURL.path
            let fm = FileManager.default
            
            if !fm.fileExists(atPath: path){
                print("File does not exist. Creating and writing headers.")
                writeData(fileURL: fileURL, data: headers, append: false)
                
            }else{
//                print("File exists. Appending.")
                writeData(fileURL: fileURL, data: data, append: true)
            }
            
        }
    }
    func writeData(fileURL:URL, data:String, append:Bool){
        if let outputStream = OutputStream(url: fileURL, append: append){
            outputStream.open()
            let bytesWritten = outputStream.write(data, maxLength: data.count)
            if bytesWritten >= 0
            {
                print("\(bytesWritten) bytes written to file.")
            }
            else
            {
                print("Failed to write to file.")
            }
            outputStream.close()
        }
        else
        {
            print("Unable to open file at \(fileURL) for writing.")
        }
    }
}
