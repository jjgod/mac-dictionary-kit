#
#  DictUnifierAppDelegate.py
#  DictUnifier
#
#  Created by Jiang Jiang on 3/7/10.
#  Copyright Jjgod Jiang 2010. All rights reserved.
#

from Foundation import *
from AppKit import *

class DictUnifierAppDelegate(NSObject):
    dropper = objc.IBOutlet()
    label = objc.IBOutlet()
    nameField = objc.IBOutlet()

    def applicationDidFinishLaunching_(self, sender):
        self.label.setStringValue_("Application did finish launching.")

    def applicationShouldTerminateAfterLastWindowClosed_(self, sender):
        return True
