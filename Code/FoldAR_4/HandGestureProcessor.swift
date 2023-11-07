//
//  HandGestureProcessor.swift
//  FoldAR_5
//
//  Created by Tom Cavey on 11/02/23.

import CoreGraphics
import UIKit

class HandGestureProcessor
{
    var startCollection = false
    
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
    
    private var state = State.unknown {
        didSet {
            didChangeStateClosure?(state)
        }
    }
    
    private var thumbUpEvidenceCounter = 0
    private var thumbDownEvidenceCounter = 0
    private var frameCounter = 0
    private let evidenceCounterStateTrigger: Int
    private let writeInterval = 5
    
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
    
    init(evidenceCounterStateTrigger: Int = 3)
    {
        self.evidenceCounterStateTrigger = evidenceCounterStateTrigger
    }
    
    func reset() {
        state = .unknown
        thumbUpEvidenceCounter = 0
        thumbDownEvidenceCounter = 0
    }
    
    func processPointsPair(_ pointsPair: PointsPair)
    {
        lastProcessedPointsPair = pointsPair
        
        // thumbs up or thumbs down decision
        let position = pointsPair.thumbTip.y - pointsPair.thumbBase.y
        
        if position < 0
        {
            thumbUpEvidenceCounter += 1
            thumbDownEvidenceCounter = 0
            
            state = (thumbUpEvidenceCounter >= evidenceCounterStateTrigger) ? .thumbUp : .thumbUp
        }
        else
        {
            thumbDownEvidenceCounter += 1
            thumbUpEvidenceCounter = 0
            
            state = (thumbDownEvidenceCounter >= evidenceCounterStateTrigger) ? .thumbDown : .thumbDown
        }
        
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
                if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                {
                    let fileURL = documentsURL.appendingPathComponent("sessionData4.txt")
                    
                    if let outputStream = OutputStream(url: fileURL, append: true)
                    {
                        outputStream.open()
                        var text = ""
                        
                        // put timestamp in here!
                        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                        text += "Timestamp: \(timestamp)\n"
                        text += "thumbTip.x: \(pointsPair.thumbTip.x), thumbTip.y: \(pointsPair.thumbTip.y)\n"
                        text += "thumbIP.x: \(pointsPair.thumbIP.x), thumbIP.y: \(pointsPair.thumbIP.y)\n"
                        text += "thumbMP.x: \(pointsPair.thumbMP.x), thumbMP.y: \(pointsPair.thumbMP.y)\n"
                        text += "thumbCMC.x: \(pointsPair.thumbBase.x), thumbCMC.y: \(pointsPair.thumbBase.y)\n"
                        text += "thumbTip2.x: \(pointsPair.thumbTip2.x), thumbTip2.y: \(pointsPair.thumbTip2.y)\n"
                        text += "thumbIP2.x: \(pointsPair.thumbIP2.x), thumbIP2.y: \(pointsPair.thumbIP2.y)\n"
                        text += "thumbMP2.x: \(pointsPair.thumbMP2.x), thumbMP2.y: \(pointsPair.thumbMP2.y)\n"
                        text += "thumbCMC2.x: \(pointsPair.thumbBase2.x), thumbCMC2.y: \(pointsPair.thumbBase2.y)\n"
                        text += "indexTip.x: \(pointsPair.indexTip.x), indexTip.y: \(pointsPair.indexTip.y)\n"
                        text += "indexPIP.x: \(pointsPair.indexPIP.x), indexPIP.y: \(pointsPair.indexPIP.y)\n"
                        text += "indexDIP.x: \(pointsPair.indexDIP.x), indexDIP.y: \(pointsPair.indexDIP.y)\n"
                        text += "indexMCP.x: \(pointsPair.indexMCP.x), indexMCP.y: \(pointsPair.indexMCP.y)\n"
                        text += "indexTip2.x: \(pointsPair.indexTip2.x), indexTip2.y: \(pointsPair.indexTip2.y)\n"
                        text += "indexPIP2.x: \(pointsPair.indexPIP2.x), indexPIP2.y: \(pointsPair.indexPIP2.y)\n"
                        text += "indexDIP2.x: \(pointsPair.indexDIP2.x), indexDIP2.y: \(pointsPair.indexDIP2.y)\n"
                        text += "indexMCP2.x: \(pointsPair.indexMCP2.x), indexMCP2.y: \(pointsPair.indexMCP2.y)\n"
                        text += "middleTip.x: \(pointsPair.middleTip.x), middleTip.y: \(pointsPair.middleTip.y)\n"
                        text += "middlePIP.x: \(pointsPair.middlePIP.x), middlePIP.y: \(pointsPair.middlePIP.y)\n"
                        text += "middleDIP.x: \(pointsPair.middleDIP.x), middleDIP.y: \(pointsPair.middleDIP.y)\n"
                        text += "middleMCP.x: \(pointsPair.middleMCP.x), middleMCP.y: \(pointsPair.middleMCP.y)\n"
                        text += "middleTip2.x: \(pointsPair.middleTip2.x), middleTip2.y: \(pointsPair.middleTip2.y)\n"
                        text += "middlePIP2.x: \(pointsPair.middlePIP2.x), middlePIP2.y: \(pointsPair.middlePIP2.y)\n"
                        text += "middleDIP2.x: \(pointsPair.middleDIP2.x), middleDIP2.y: \(pointsPair.middleDIP2.y)\n"
                        text += "middleMCP2.x: \(pointsPair.middleMCP2.x), middleMCP2.y: \(pointsPair.middleMCP2.y)\n"
                        text += "ringTip.x: \(pointsPair.ringTip.x), ringTip.y: \(pointsPair.ringTip.y)\n"
                        text += "ringPIP.x: \(pointsPair.ringPIP.x), ringPIP.y: \(pointsPair.ringPIP.y)\n"
                        text += "ringDIP.x: \(pointsPair.ringDIP.x), ringDIP.y: \(pointsPair.ringDIP.y)\n"
                        text += "ringMCP.x: \(pointsPair.ringMCP.x), ringMCP.y: \(pointsPair.ringMCP.y)\n"
                        text += "ringTip2.x: \(pointsPair.ringTip2.x), ringTip2.y: \(pointsPair.ringTip2.y)\n"
                        text += "ringPIP2.x: \(pointsPair.ringPIP2.x), ringPIP2.y: \(pointsPair.ringPIP2.y)\n"
                        text += "ringDIP2.x: \(pointsPair.ringDIP2.x), ringDIP2.y: \(pointsPair.ringDIP2.y)\n"
                        text += "ringMCP2.x: \(pointsPair.ringMCP2.x), ringMCP2.y: \(pointsPair.ringMCP2.y)\n"
                        text += "littleTip.x: \(pointsPair.littleTip.x), littleTip.y: \(pointsPair.littleTip.y)\n"
                        text += "littlePIP.x: \(pointsPair.littlePIP.x), littlePIP.y: \(pointsPair.littlePIP.y)\n"
                        text += "littleDIP.x: \(pointsPair.littleDIP.x), littleDIP.y: \(pointsPair.littleDIP.y)\n"
                        text += "littleMCP.x: \(pointsPair.littleMCP.x), littleMCP.y: \(pointsPair.littleMCP.y)\n"
                        text += "littleTip2.x: \(pointsPair.littleTip2.x), littleTip2.y: \(pointsPair.littleTip2.y)\n"
                        text += "littlePIP2.x: \(pointsPair.littlePIP2.x), littlePIP2.y: \(pointsPair.littlePIP2.y)\n"
                        text += "littleDIP2.x: \(pointsPair.littleDIP2.x), littleDIP2.y: \(pointsPair.littleDIP2.y)\n"
                        text += "littleMCP2.x: \(pointsPair.littleMCP2.x), littleMCP2.y: \(pointsPair.littleMCP2.y)\n"
                        text += "END OF DATA FOR FRAME \(frameCounter)\n\n\n"
                        
                        let bytesWritten = outputStream.write(text, maxLength: text.count)
                        
                        if bytesWritten >= 0
                        {
                            print("Wrote \(bytesWritten) bytes to the file.")
                        } 
                        else
                        {
                            print("Failed to write to the file.")
                        }
                        outputStream.close()
                    } 
                    else
                    {
                        print("Unable to open the file for writing.")
                    }
                } 
                else
                {
                    print("Unable to access the Documents directory.")
                }
            }
        }
    }
}
