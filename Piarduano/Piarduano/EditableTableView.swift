//
//  EditableTableView.swift
//  Piarduano
//
//  Created by Alex on 22-01-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import Cocoa
import Foundation

protocol EditableTableViewDelegate: NSTableViewDelegate {
    
    func textDidEndEditing()
    func textShouldEndEditing()
    
}

class EditableTableView: NSTableView {
    
    var delegate: EditableTableViewDelegate?
    
    override func textShouldEndEditing(textObject: NSText) -> Bool {
        
        self.delegate?.textShouldEndEditing()
        
        super.textShouldEndEditing(textObject)
        
        return true
    }
    
    override func textDidEndEditing(notification: NSNotification) {
        
        super.textDidEndEditing(notification)
                
        self.delegate?.textDidEndEditing()
        
    }
    
}