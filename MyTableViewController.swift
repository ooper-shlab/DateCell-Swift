//
//  MyTableViewController.swift
//  DateCell
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/27.
//
//
/*
     File: MyTableViewController.h
     File: MyTableViewController.m
 Abstract: The main table view controller of this app.
  Version: 1.6

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2014 Apple Inc. All Rights Reserved.

 */

import UIKit

private let kPickerAnimationDuration = 0.40   // duration for the animation to slide the date picker into view
private let kDatePickerTag = 99     // view tag identifiying the date picker view

private let kTitleKey = "title"   // key for obtaining the data source item's title
private let kDateKey = "date"    // key for obtaining the data source item's date value

// keep track of which rows have date cells
private let kDateStartRow = 1
private let kDateEndRow = 2

private let kDateCellID = "dateCell"     // the cells with the start or end date
private let kDatePickerID = "datePicker" // the cell containing the date picker
private let kOtherCell = "otherCell"     // the remaining cells at the end


//MARK: -

@objc(MyTableViewController)
class MyTableViewController: UITableViewController {
    
    var dataArray: [[String: Any]] = []
    let dateFormatter = DateFormatter()
    
    // keep track which indexPath points to the cell with UIDatePicker
    var datePickerIndexPath: IndexPath?
    
    var pickerCellRowHeight: CGFloat = 0
    
    @IBOutlet var pickerView: UIDatePicker!
    
    // this button appears only when the date picker is shown (iOS 6.1.x or earlier)
    @IBOutlet var doneButton: UIBarButtonItem?
    
    
    //MARK: -
    
    /*! Primary view has been loaded for this view controller
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup our data source
        self.dataArray = [
            [kTitleKey : "Tap a cell to change its date:"],
            [kTitleKey : "Start Date",
                kDateKey : Date()],
            [kTitleKey : "End Date",
                kDateKey : Date()],
            [kTitleKey : "(other item1)"],
            [kTitleKey : "(other item2)"],
        ]
        
        self.dateFormatter.dateStyle = .short    // show short-style date format
        self.dateFormatter.timeStyle = .none
        
        // obtain the picker view cell's height, works because the cell was pre-defined in our storyboard
        let pickerViewCellToCheck = self.tableView.dequeueReusableCell(withIdentifier: kDatePickerID)!
        self.pickerCellRowHeight = pickerViewCellToCheck.frame.height
        
        // if the local changes while in the background, we need to be notified so we can update the date
        // format in the table view cells
        //
        NotificationCenter.default.addObserver(self,
            selector: #selector(MyTableViewController.localeChanged(_:)),
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil)
    }
    
    
    //MARK: - Locale
    
    /*! Responds to region format or locale changes.
    */
    @objc func localeChanged(_ notif: Notification) {
        // the user changed the locale (region format) in Settings, so we are notified here to
        // update the date format in the table view cells
        //
        self.tableView.reloadData()
    }
    
    
    //MARK: - Utilities
    
    ///*! Returns the major version of iOS, (i.e. for iOS 6.1.3 it returns 6)
    // */
    //NSUInteger DeviceSystemMajorVersion()
    //{
    //    static NSUInteger _deviceSystemMajorVersion = -1;
    //    static dispatch_once_t onceToken;
    //    dispatch_once(&onceToken, ^{
    //
    //        _deviceSystemMajorVersion =
    //            [[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] integerValue];
    //    });
    //
    //    return _deviceSystemMajorVersion;
    //}
    //
    //#define EMBEDDED_DATE_PICKER (DeviceSystemMajorVersion() >= 7)
    
    /*! Determines if the given indexPath has a cell below it with a UIDatePicker.
    
    @param indexPath The indexPath to check if its cell has a UIDatePicker below it.
    */
    private func hasPickerForIndexPath(_ indexPath: IndexPath) -> Bool {
        var hasDatePicker = false
        
        var targetedRow = indexPath.row
        targetedRow += 1
        
        let checkDatePickerCell =
        self.tableView.cellForRow(at: IndexPath(row: targetedRow, section: 0))
        let checkDatePicker = checkDatePickerCell?.viewWithTag(kDatePickerTag) as? UIDatePicker
        
        hasDatePicker = (checkDatePicker != nil)
        return hasDatePicker
    }
    
    /*! Updates the UIDatePicker's value to match with the date of the cell above it.
    */
    private func updateDatePicker() {
        guard let datePickerIndexPath = self.datePickerIndexPath else {return}
        let associatedDatePickerCell = self.tableView.cellForRow(at: datePickerIndexPath)
        
        guard let targetedDatePicker = associatedDatePickerCell?.viewWithTag(kDatePickerTag) as? UIDatePicker else {return}
        // we found a UIDatePicker in this cell, so update it's date value
        //
        let itemData = self.dataArray[datePickerIndexPath.row - 1]
        targetedDatePicker.setDate(itemData[kDateKey] as! Date, animated: false)
    }
    
    /*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
    */
    private var hasInlineDatePicker: Bool {
        return (self.datePickerIndexPath != nil)
    }
    
    /*! Determines if the given indexPath points to a cell that contains the UIDatePicker.
    
    @param indexPath The indexPath to check if it represents a cell with the UIDatePicker.
    */
    private func indexPathHasPicker(_ indexPath: IndexPath) -> Bool {
        return self.hasInlineDatePicker && self.datePickerIndexPath!.row == indexPath.row
    }
    
    /*! Determines if the given indexPath points to a cell that contains the start/end dates.
    
    @param indexPath The indexPath to check if it represents start/end date cell.
    */
    private func indexPathHasDate(_ indexPath: IndexPath) -> Bool {
        var hasDate = false
        
        if indexPath.row == kDateStartRow ||
            indexPath.row == kDateEndRow || (self.hasInlineDatePicker && indexPath.row == kDateEndRow + 1)
        {
            hasDate = true
        }
        
        return hasDate
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.indexPathHasPicker(indexPath) ? self.pickerCellRowHeight : self.tableView.rowHeight
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.hasInlineDatePicker {
            // we have a date picker, so allow for it in the number of rows in this section
            let numRows = self.dataArray.count
            return numRows + 1
        }
        
        return self.dataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cellID = kOtherCell
        
        if self.indexPathHasPicker(indexPath) {
            // the indexPath is the one containing the inline date picker
            cellID = kDatePickerID     // the current/opened date picker cell
        } else if self.indexPathHasDate(indexPath) {
            // the indexPath is one that contains the date information
            cellID = kDateCellID       // the start/end date cells
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID)!
        
        if indexPath.row == 0 {
            // we decide here that first cell in the table is not selectable (it's just an indicator)
            cell.selectionStyle = .none
        }
        
        // if we have a date picker open whose cell is above the cell we want to update,
        // then we have one more cell than the model allows
        //
        var modelRow = indexPath.row
        if self.datePickerIndexPath != nil && self.datePickerIndexPath!.row <= indexPath.row {
            modelRow -= 1
        }
        
        let itemData = self.dataArray[modelRow]
        
        // proceed to configure our cell
        if cellID == kDateCellID {
            // we have either start or end date cells, populate their date field
            //
            cell.textLabel!.text = (itemData[kTitleKey] as! String)
            cell.detailTextLabel!.text = self.dateFormatter.string(from: itemData[kDateKey] as! Date)
        } else if cellID == kOtherCell {
            // this cell is a non-date cell, just assign it's text label
            //
            cell.textLabel!.text = (itemData[kTitleKey] as! String)
        }
        
        return cell
    }
    
    /*! Adds or removes a UIDatePicker cell below the given indexPath.
    
    @param indexPath The indexPath to reveal the UIDatePicker.
    */
    private func toggleDatePickerForSelectedIndexPath(_ indexPath: IndexPath) {
        self.tableView.beginUpdates()
        
        let indexPaths = [IndexPath(row: indexPath.row + 1, section: 0)]
        
        // check if 'indexPath' has an attached date picker below it
        if self.hasPickerForIndexPath(indexPath) {
            // found a picker below it, so remove it
            self.tableView.deleteRows(at: indexPaths, with: .fade)
        } else {
            // didn't find a picker below it, so we should insert it
            self.tableView.insertRows(at: indexPaths, with: .fade)
        }
        
        self.tableView.endUpdates()
    }
    
    /*! Reveals the date picker inline for the given indexPath, called by "didSelectRowAtIndexPath".
    
    @param indexPath The indexPath to reveal the UIDatePicker.
    */
    private func displayInlineDatePickerForRowAtIndexPath(_ indexPath: IndexPath) {
        // display the date picker inline with the table content
        self.tableView.beginUpdates()
        
        var before = false   // indicates if the date picker is below "indexPath", help us determine which row to reveal
        if self.hasInlineDatePicker {
            before = self.datePickerIndexPath!.row < indexPath.row
        }
        
        let sameCellClicked = (self.datePickerIndexPath?.row ?? 0) - 1 == indexPath.row
        
        // remove any date picker cell if it exists
        if self.hasInlineDatePicker {
            self.tableView.deleteRows(at: [IndexPath(row: self.datePickerIndexPath!.row, section: 0)], with: .fade)
            self.datePickerIndexPath = nil
        }
        
        if !sameCellClicked {
            // hide the old date picker and display the new one
            let rowToReveal = (before ? indexPath.row - 1 : indexPath.row)
            let indexPathToReveal = IndexPath(row: rowToReveal, section: 0)
            
            self.toggleDatePickerForSelectedIndexPath(indexPathToReveal)
            self.datePickerIndexPath = IndexPath(row: indexPathToReveal.row + 1, section: 0)
        }
        
        // always deselect the row containing the start or end date
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        self.tableView.endUpdates()
        
        // inform our date picker of the current date to match the current cell
        self.updateDatePicker()
    }
    
    ///*! Reveals the UIDatePicker as an external slide-in view, iOS 6.1.x and earlier, called by "didSelectRowAtIndexPath".
    //
    // @param indexPath The indexPath used to display the UIDatePicker.
    // */
    //- (void)displayExternalDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
    //{
    //    // first update the date picker's date value according to our model
    //    NSDictionary *itemData = self.dataArray[indexPath.row];
    //    [self.pickerView setDate:[itemData valueForKey:kDateKey] animated:YES];
    //
    //    // the date picker might already be showing, so don't add it to our view
    //    if (self.pickerView.superview == nil)
    //    {
    //        CGRect startFrame = self.pickerView.frame;
    //        CGRect endFrame = self.pickerView.frame;
    //
    //        // the start position is below the bottom of the visible frame
    //        startFrame.origin.y = CGRectGetHeight(self.view.frame);
    //
    //        // the end position is slid up by the height of the view
    //        endFrame.origin.y = startFrame.origin.y - CGRectGetHeight(endFrame);
    //
    //        self.pickerView.frame = startFrame;
    //
    //        [self.view addSubview:self.pickerView];
    //
    //        // animate the date picker into view
    //        [UIView animateWithDuration:kPickerAnimationDuration animations: ^{ self.pickerView.frame = endFrame; }
    //                         completion:^(BOOL finished) {
    //                             // add the "Done" button to the nav bar
    //                             self.navigationItem.rightBarButtonItem = self.doneButton;
    //                         }];
    //    }
    //}
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.reuseIdentifier == kDateCellID {
            self.displayInlineDatePickerForRowAtIndexPath(indexPath)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    //MARK: - Actions
    
    /*! User chose to change the date by changing the values inside the UIDatePicker.
    
    @param sender The sender for this action: UIDatePicker.
    */
    @IBAction func dateAction(_ targetedDatePicker: UIDatePicker) {
        let targetedCellIndexPath: IndexPath
        
        if self.hasInlineDatePicker {
            // inline date picker: update the cell's date "above" the date picker cell
            //
            targetedCellIndexPath = IndexPath(row: self.datePickerIndexPath!.row - 1, section: 0)
        } else {
            // external date picker: update the current "selected" cell's date
            targetedCellIndexPath = self.tableView.indexPathForSelectedRow!
        }
        
        let cell = self.tableView.cellForRow(at: targetedCellIndexPath)
        
        // update our data model
        self.dataArray[targetedCellIndexPath.row][kDateKey] = targetedDatePicker.date
        
        // update the cell's date string
        cell?.detailTextLabel!.text = self.dateFormatter.string(from: targetedDatePicker.date)
    }
    
    
    /*! User chose to finish using the UIDatePicker by pressing the "Done" button
    (used only for "non-inline" date picker, iOS 6.1.x or earlier)
    
    @param sender The sender for this action: The "Done" UIBarButtonItem
    */
    @IBAction func doneAction(_: AnyObject) {
        var pickerFrame = self.pickerView.frame
        pickerFrame.origin.y = self.view.frame.height
        
        // animate the date picker out of view
        UIView.animate(withDuration: kPickerAnimationDuration, animations: {self.pickerView.frame = pickerFrame}, completion: {finished in
            self.pickerView.removeFromSuperview()
        })
        
        // remove the "Done" button in the navigation bar
        self.navigationItem.rightBarButtonItem = nil;
        
        // deselect the current table cell
        let indexPath = self.tableView.indexPathForSelectedRow!
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
