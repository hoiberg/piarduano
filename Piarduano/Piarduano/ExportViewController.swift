//
//  ExportViewController.swift
//  Piarduano
//
//  Created by Alex on 26-01-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import Cocoa

class ExportViewController: NSViewController {

    @IBOutlet weak var codeField: NSTextField!
    
    var code: String?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set text
        if code != nil {
            codeField.stringValue = code!
        }
        
    }

    @IBAction func close(sender: NSButton) {
        
        // just dismiss this view
        dismissController(self)
        
    }
    
    @IBAction func copyAndClose(sender: NSButton) {
        
        // copy contents of codeField to generalPasteBoard
        let pasteBoard = NSPasteboard.generalPasteboard()
        pasteBoard.declareTypes([NSStringPboardType], owner: nil)
        pasteBoard.setString(codeField.stringValue, forType: NSStringPboardType)
        
        // dismiss the view
        dismissController(self)
        
    }
}
