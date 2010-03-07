#
#  DUWindow.py
#  DictUnifier
#
#  Created by Jiang Jiang on 3/7/10.
#  Copyright (c) 2010 Jjgod Jiang. All rights reserved.
#

import objc
from Foundation import *
from AppKit import *

class DUWindow(NSWindow):
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
            print files
            successful = True
        return successful
