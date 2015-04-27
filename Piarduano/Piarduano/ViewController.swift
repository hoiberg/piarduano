//
//  ViewController.swift
//  Piarduano
//
//  Created by Alex on 03-01-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import Cocoa
import Foundation

class ViewController: NSViewController, ORSSerialPortDelegate, NSComboBoxDataSource, NSTableViewDataSource {
    
    @IBOutlet weak var controlLabel: NSTextField!
    @IBOutlet weak var recordButton: NSButton!
    @IBOutlet weak var serialPathBox: NSComboBox!
    @IBOutlet weak var baudRateBox: NSPopUpButton!
    @IBOutlet weak var startConnectionButton: NSButton!
    
    @IBOutlet var logTextView: NSTextView!
    
    @IBOutlet weak var shiftSegments: NSSegmentedControl!
    @IBOutlet weak var freqAdjust: NSSlider!
    
    @IBOutlet weak var dummyTextField: NSTextField!
    
    @IBOutlet weak var recordingTableView: NSTableView!
    @IBOutlet weak var frequencyColumn: NSTableColumn!
    @IBOutlet weak var timeColumn: NSTableColumn!

    @IBOutlet weak var replayButton: NSButton!
    
    @IBOutlet var alertTextField: NSTextField!
    
    var frequenciesRecord: [Double] = []
    var timesRecord: [Double] = []
    
    var lastKeyDownTime: NSDate?
    var lastKeyUpTime: NSDate?
    
    var pressedKey: String = "" // the key that is currently being pressed

    var startTime: NSDate!

    var isRecording = false
    
    var isReplaying = false

    var connectionIsOpen: Bool {
        if serialPort != nil { return serialPort!.open } else { return false }
    }
    
    var portManager = ORSSerialPortManager.sharedSerialPortManager()
    var serialPort: ORSSerialPort?
    
    var textBuffer = "" // will be used for incoming data
    
    let keyRows: [[String]] = [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="],
                                ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"],
                                  ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "\\"],
                                    ["`", "z", "x", "c", "v", "b", "n", "m", ",", ".", "/", "\r"]]
    
    let notes: [[Double]] = [[C0, Db0, D0, Eb0, E0, F0, Gb0, G0, Ab0, LA0, Bb0, Be0],
                             [C1, Db1, D1, Eb1, E1, F1, Gb1, G1, Ab1, LA1, Bb1, B1],
                             [C2, Db2, D2, Eb2, E2, F2, Gb2, G2, Ab2, LA2, Bb2, B2],
                             [C3, Db3, D3, Eb3, E3, F3, Gb3, G3, Ab3, LA3, Bb3, B3],
                             [C4, Db4, D4, Eb4, E4, F4, Gb4, G4, Ab4, LA4, Bb4, B4],
                             [C5, Db5, D5, Eb5, E5, F5, Gb5, G5, Ab5, LA5, Bb5, B5],
                             [C6, Db6, D6, Eb6, E6, F6, Gb6, G6, Ab6, LA6, Bb6, B6],
                             [C7, Db7, D7, Eb7, E7, F7, Gb7, G7, Ab7, LA7, Bb7, B7]]

    
//MARK: - Main functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTime = NSDate()
        
        serialPathBox.reloadData()
        
        // register event handler for keydown
        NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask, handler: { (event) -> NSEvent! in

            // only do a key down event if 1) A connection is open, 2) The recordingsTableView isn't being edited and 3) if it is not replaying at the moment
            if self.connectionIsOpen && self.recordingTableView.currentEditor() == nil && !self.isReplaying {
                
                // get the keyboard key
                let theKey = event.charactersIgnoringModifiers
                if theKey == nil { return event }

                // protect for key repeats
                if theKey == self.pressedKey { return event }
                
                // get the frequencie assigned to that key
                let index = self.positionOfCharInKeyRows(theKey!)
                var freq = self.notes[index.one + self.shiftSegments.selectedSegment][index.two]
                freq += Double(self.freqAdjust.floatValue)
                
                // if there is a recording going
                if self.isRecording {
                    
                    // check if there was a pause
                    if self.pressedKey == "" && self.lastKeyUpTime != nil {
                        
                        // add a pause to the record
                        let timeInterval = NSDate().timeIntervalSinceDate(self.lastKeyUpTime!)
                        self.frequenciesRecord.append(0.0)
                        self.timesRecord.append(timeInterval)
                        
                    }
                    
                    // check if  another key is being pressed
                    if self.pressedKey != "" && self.lastKeyDownTime != nil {
                        
                        // add the correct time interval for this key, since our new key will override this one
                        let timeInterval = NSDate().timeIntervalSinceDate(self.lastKeyDownTime!)
                        self.timesRecord.append(timeInterval)
                        
                    }
                    
                    // add the frequency and set the lastkeydowntime
                    self.frequenciesRecord.append(freq)
                    self.lastKeyDownTime = NSDate()
                    
                    // reload the table and scroll to visible
                    self.recordingTableView.reloadData()
                    if self.recordingTableView.numberOfRows > 0 {
                        self.recordingTableView.scrollRowToVisible(self.recordingTableView.numberOfRows-1)
                    }
                    
                }
                
                // now update pressededKey and send the frequency to the arduino
                self.pressedKey = theKey!
                self.controlLabel.stringValue = theKey!
                
                self.sendFrequency(Float(freq))
                
            }
            
            return event
        })
        
        // register event handler for keyup
        NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.KeyUpMask, handler: { (event) -> NSEvent! in
            
            // only do a key up event if 1) A connection is open, 2) The recordingsTableView isn't being edited and 3) if it is not replaying at the moment
            if self.connectionIsOpen && self.recordingTableView.currentEditor() == nil && !self.isReplaying {
                
                // get the keyboard key
                var theKey = event.charactersIgnoringModifiers
                if theKey == nil { return event }

                // only release the key if it was the key being pressed
                if theKey != self.pressedKey { return event }
                
                // if there is a recording going
                if self.isRecording {
                    
                    // calculate the time interval for the key that was pressed and now released
                    let timeInterval = NSDate().timeIntervalSinceDate(self.lastKeyDownTime!)
                
                    // add it to the record and update the lastkeyuptime
                    self.timesRecord.append(timeInterval)
                    self.lastKeyUpTime = NSDate()
                    
                    // reload talbeview
                    self.recordingTableView.reloadData()
                
                }
                
                // reset pressedKey
                self.pressedKey = ""
                
                // stop the arduino buzzing
                self.sendFrequency(0)
                
            }
            
            return event
        })
    }
    
    override func viewWillDisappear() {
        // instead of applicationWillTerminate
        sendFrequency(0)
        serialPort?.close()
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showExportView" {
            
            let dest = segue.destinationController as! ExportViewController
            dest.frequenciesRecord = frequenciesRecord
            dest.timesRecord = timesRecord
            
        }
        
    }
    
    func sendFrequency(freq: Float) {
        var freqData = "\(freq)".dataUsingEncoding(NSUTF8StringEncoding)
        serialPort?.sendData(freqData)
        println("I have sent \(freq)")
    }
    
    func log(toLog: String) {
        // add text
        logTextView.textStorage?.appendAttributedString(NSAttributedString(string: "\(toLog)\n"))
        
        // scroll to the end
        let length = count(logTextView.string!)
        let range: NSRange = NSMakeRange(length, 0)
        logTextView.scrollRangeToVisible(range)
    }
    
    func logBuffer() {
        if textBuffer.isEmpty { return }
        log("Received the following message:\n-\(textBuffer)")
        textBuffer = ""
    }
    
    func positionOfCharInKeyRows(theChar: String) -> (one: Int, two: Int) {
        for iOne in 0...3 {
            let keyRow = self.keyRows[iOne]
            for iTwo in 0...11 {
                let charAtIndex = keyRow[iTwo]
                if charAtIndex == theChar {
                    return (iOne, iTwo)
                }
            }
        }
        
        return (0, 0)
    }
    
    func replayNextNote(previousTimer: NSTimer?) {
        
        println("replaynextnote got called")
        
        // stop if replaying has been stopped
        if !isReplaying {
            sendFrequency(0)
            return
        }
        
        // index of the note to play
        var noteIndex = 0
        
        // if this isn't the first note
        if previousTimer != nil {
            // get the index of the next note to play
            noteIndex = previousTimer!.userInfo as! Int
        }
        
        // end replay if neccesary
        if noteIndex >= frequenciesRecord.count || noteIndex >= timesRecord.count {
            sendFrequency(0)
            replayButton.title = "Replay"
            isReplaying = false
            return
        }
        
        // select the tableview row at the index to show where we are (and scroll to that row)
        recordingTableView.selectRowIndexes(NSIndexSet(index: noteIndex), byExtendingSelection: false)
        recordingTableView.scrollRowToVisible(noteIndex)
        
        // send frequency
        let freq = Float(frequenciesRecord[noteIndex])
        sendFrequency(freq)
        
        // shedule next timer with next note as userinfo
        var timer = NSTimer.scheduledTimerWithTimeInterval(timesRecord[noteIndex], target: self, selector: Selector("replayNextNote:"), userInfo: ++noteIndex, repeats: false)
        
    }
        
//MARK: - ORSSerialPortDelegate functions
    func serialPortWasRemovedFromSystem(givenSerialPort: ORSSerialPort!) {
        // log it
        log("Serial port \(givenSerialPort.path) has been removed from system!")
        
        // ignore if it isn't our serial port
        if givenSerialPort != serialPort { return }
       
        // empty serialport
        serialPort = nil
        
        // display an alert
        var alert = NSAlert()
        alert.messageText = "The arduino has been disconnected!"
        alert.addButtonWithTitle("Dismiss")
        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.runModal()
    }
    
    func serialPortWasOpened(givenSerialPort: ORSSerialPort!) {
        // log it
        log("Serial port \(givenSerialPort.path) has been opened")
        
        // update view
        startConnectionButton.title = "Stop"
        startConnectionButton.keyEquivalent = ""
        
        serialPathBox.editable = false
    }
    
    func serialPortWasClosed(givenSerialPort: ORSSerialPort!) {
        // log it
        log("Serial port \(givenSerialPort.path) has been closed")
        
        // update view
        startConnectionButton.title = "Start"
        startConnectionButton.keyEquivalent = "\r"
        
        serialPathBox.editable = true
    }
    
    func serialPort(givenSerialPort: ORSSerialPort!, didEncounterError error: NSError!) {
        // log it
        log("Serial port \(givenSerialPort.path) has encoutered an error: \n \(error.localizedDescription)")
    }
    
    func serialPort(givenSerialPort: ORSSerialPort!, didReceiveData data: NSData!) {
        // if it can be converted to a string, log it..
        if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
            // append to the textbuffer
            textBuffer += string as String
            
            // wait a couple of seconds for the rest of the string to arrive
            NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("logBuffer"), userInfo: nil, repeats: false)
        }
    }
    
//MARK: - NSCombobox datasource
    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        var portAtIndex = portManager.availablePorts[index] as! ORSSerialPort
        return portAtIndex.path
    }
    
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return portManager.availablePorts.count
    }
    
//MARK: - NSTableView datasource
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return frequenciesRecord.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        if tableColumn == frequencyColumn {
            
            return frequenciesRecord[row]
            
        } else if tableColumn == timeColumn {
            
            if row >= timesRecord.count {
                
                return "-"
                
            } else {
                
                return timesRecord[row]
                
            }
            
        }
        
        return ""
        
    }
    
    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        
        // a tableviewcell has been edited!! Get the frequency and update one of the arrays!
        let newFreq = object as! NSString
        
        if tableColumn == frequencyColumn {
            
            if row < frequenciesRecord.count {
                frequenciesRecord[row] = newFreq.doubleValue
            }
            
        } else if tableColumn == timeColumn {
            
            if row < timesRecord.count {
                timesRecord[row] = newFreq.doubleValue
            }
        }
        
    }
    
//MARK: - IBActions
    @IBAction func RecordPressed(sender: NSButton) {
        
        if isRecording {
            
            // stop recording
            
            sender.title = "Start Recording"
            
            isRecording = false
            
            
            // if there is a key being pressed, act as if it was released now
            if pressedKey != "" {
                
                // calculate the time interval for the key that was pressed and now released
                let timeInterval = NSDate().timeIntervalSinceDate(self.lastKeyDownTime!)
                
                // add it to the record
                self.timesRecord.append(timeInterval)
                
                // reload table view
                self.recordingTableView.reloadData()

            }
            
            // reset
            pressedKey = ""
            lastKeyDownTime = nil
            lastKeyUpTime = nil
            
        } else {
            
            // cannot record while replaying
            if isReplaying {
                log("Cannot record while replaying")
                return
            }
            
            // start recording
            sender.title = "Pause Recording"
            
            isRecording = true
            
        }
    }
    
    @IBAction func startConnectionPressed(sender: NSButton) {
        if connectionIsOpen {
            // close the connection
            serialPort?.close()
            serialPort = nil
        } else {
            // open the connection
            serialPort = ORSSerialPort(path: serialPathBox.stringValue)
            serialPort?.delegate = self
            serialPort?.baudRate = baudRateBox.integerValue
            serialPort?.open()
            
            dummyTextField.becomeFirstResponder()
        }
    }
    
    @IBAction func replayPressed(sender: NSButton) {
        
        // don't replay if a recording is going or if a key is being pressed
        if isRecording || pressedKey != ""  {
            log("Cannot replay while recording or while a key is being pressed")
            return
        }
        
        if !isReplaying {
            
            // change ui
            sender.title = "Stop"
            
            // start replaying
            isReplaying = true
            replayNextNote(nil)
            
        } else {
            
            // change ui
            sender.title = "Replay"
            
            // stop replaying
            isReplaying = false
            
        }
    }
    
    @IBAction func clearPressed(sender: NSButton) {
        
        // don't clear if a recording is goingor if a key is being pressed
        if isRecording || pressedKey != ""  {
            log("Cannot clear recording while recording or while a key is being pressed")
            return
        }
        
        // clear recordingsarrays
        frequenciesRecord.removeAll(keepCapacity: false)
        timesRecord.removeAll(keepCapacity: false)
        
        // reload table view
        recordingTableView.reloadData()
    }
    
    @IBAction func exportToCode(sender: NSButton) {
        
        performSegueWithIdentifier("showExportView", sender: self)
        
    }
}

