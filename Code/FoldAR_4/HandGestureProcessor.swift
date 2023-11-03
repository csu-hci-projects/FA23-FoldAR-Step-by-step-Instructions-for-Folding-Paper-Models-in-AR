//
//  HandGestureProcessor.swift
//  FoldAR_5
//
//  Created by Tom Cavey on 11/02/23.

import CoreGraphics

class HandGestureProcessor {
    enum State {
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
    private let evidenceCounterStateTrigger: Int
    
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
    }
}
