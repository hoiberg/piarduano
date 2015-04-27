//
//  ExportViewController.swift
//  Piarduano
//
//  Created by Alex on 27-04-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import Cocoa

class ExportViewController: NSViewController {
   
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var numberOfArraysPopUp: NSPopUpButton!

    
    var frequenciesRecord: [Double] = []
    var timesRecord: [Double] = []
    
    private var code = ""
    
    
    // no viewDidLoad necessary
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showCodeView" {
            
            let dest = segue.destinationController as! CodeViewController
            dest.code = code
            
        }

    }
    
    @IBAction func generateCode(sender: AnyObject) {
        
        let useTwoArrays = numberOfArraysPopUp.indexOfSelectedItem == 1
        let arrayName = nameField.stringValue
        
        // clear code
        code = ""

        // specify the units of measurement
        "// notes in hertz, durations in milliseconds\n"
        
        // the total duration of the song
        var totalTime = Int(timesRecord.reduce(0.0, combine: +) * Double(1000))
        code += "// total duration: \(totalTime)\n"

        // first the count of the number of notes
        code += "// number of notes: \(frequenciesRecord.count)\n"
        
        if !useTwoArrays {
            
            // combine the two arrays into one c array in text
            code += "// this array contains the notes as well as the durations (first comes the note, then the corresponding duration)\n // this of course does not work with the example sketch\n"
            code += "uint16_t \(arrayName)[] = {"
            
            for (index, freq) in enumerate(frequenciesRecord) {
                
                code += NSString(format: "%.0f", freq) as String
                
                let seconds = timesRecord[index]
                let milliSeconds = Int(seconds * Double(1000))
                code += ", \(milliSeconds)"

                if index < frequenciesRecord.endIndex-1 {
                    code += ", "
                }
                
            }
            
            code += "};\n"

            
        } else {
        
            // now the notes array
            code += "float \(arrayName)Notes[] = {"
            
            for (index, freq) in enumerate(frequenciesRecord) {
                
                code += NSString(format: "%.0f", freq) as String
                
                if index < frequenciesRecord.endIndex-1 {
                    code += ", "
                }
                
            }
            
            // end notes array
            code += "};\n"
            
            
            // now the time intervals array
            code += "int \(arrayName)Durations[] = {"
            
            for (index, seconds) in enumerate(timesRecord) {
                
                let milliSeconds = Int(seconds * Double(1000))
                code += "\(milliSeconds)"
                
                if index < timesRecord.endIndex-1 {
                    code += ", "
                }
                
            }
            
            // end time intervals array
            code += "};\n"

        }
        
        performSegueWithIdentifier("showCodeView", sender: self)
        
    }

    @IBAction func cancel(sender: AnyObject) {
        
        dismissController(self)
        
    }
    
}
