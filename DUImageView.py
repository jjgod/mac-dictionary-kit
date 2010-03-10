#
#  DUImageView.py
#  DictUnifier
#
#  Created by Jiang Jiang on 3/7/10.
#  Copyright (c) 2010 Jjgod Jiang. All rights reserved.
#

from objc import YES, NO, IBAction, IBOutlet
from Foundation import *
from AppKit import *

class DUImageView(NSImageView):
    controller = objc.IBOutlet()

    def awakeFromNib(self):
        self.registerForDraggedTypes_([NSFilenamesPboardType])

    def draggingEntered_(self, sender):
        pboard = sender.draggingPasteboard()
        types = pboard.types()
        opType = NSDragOperationNone
        if NSFilenamesPboardType in types:
            opType = NSDragOperationCopy
        return opType

    def performDragOperation_(self,sender):
        pboard = sender.draggingPasteboard()
        successful = False
        if NSFilenamesPboardType in pboard.types():
            files = pboard.propertyListForType_(NSFilenamesPboardType)
            self.controller.startConversion(files[0])
            successful = True
        return successful

