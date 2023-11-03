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
    
    typealias PointsPair = (thumbTip: CGPoint, thumbBase: CGPoint, thumbIP: CGPoint, thumbMP: CGPoint)
    
    private var state = State.unknown {
        didSet {
            didChangeStateClosure?(state)
        }
    }
    private var thumbUpEvidenceCounter = 0
    private var thumbDownEvidenceCounter = 0
    private let evidenceCounterStateTrigger: Int
    
    var didChangeStateClosure: ((State) -> Void)?
    private (set) var lastProcessedPointsPair = PointsPair(.zero, .zero, .zero, .zero)
    
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
