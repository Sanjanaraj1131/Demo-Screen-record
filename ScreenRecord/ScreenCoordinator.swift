//
//  ScreenCoordinator.swift
//  ScreenRecord
//
//  Created by Sanjana Work on 04/06/21.
//

import Foundation

class ScreenRecordCoordinator: NSObject
{
   // let viewOverlay = WindowUtil()
    let screenRecorder = ScreenRecorder()
    var recordCompleted:((Error?) ->Void)?
    
    override init()
    {
        super.init()
        
        //viewOverlay.onStopClick = {
          //  self.stopRecording()
        //}
        
        
    }
    
    func startRecording(withFileName fileName: String, recordingHandler: @escaping (Error?) -> Void,onCompletion: @escaping (Error?)->Void)
    {
        ////self.viewOverlay.show()
        print(fileName)
        screenRecorder.startRecording(withFileName: fileName) { (error) in
            recordingHandler(error)
            self.recordCompleted = onCompletion
        }
    }
    
    func stopRecording()
    {
        /*screenRecorder.stopRecording { (error) in
          //  self.viewOverlay.hide()
            self.recordCompleted?(error)
        }*/
        screenRecorder.stopRecording(isBack: true, aPathName: "path") { (error) in
            self.recordCompleted?(error)
        }
        
    }
    
    class func listAllReplays() -> Array<URL>
    {
        return ReplayFileUtil.fetchAllReplays()
    }
    
    
}
