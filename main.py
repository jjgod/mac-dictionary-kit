#
#  main.py
#  DictUnifier
#
#  Created by Jiang Jiang on 3/7/10.
#  Copyright Jjgod Jiang 2010. All rights reserved.
#

#import modules required by application
import objc
import Foundation
import AppKit

from PyObjCTools import AppHelper

# import modules containing classes required to start application and load MainMenu.nib
import DictUnifierAppDelegate
import DUWindow, DUImageView

# pass control to AppKit
AppHelper.runEventLoop()
