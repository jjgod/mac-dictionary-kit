#
#  DictUnifierAppDelegate.py
#  DictUnifier
#
#  Created by Jiang Jiang on 3/7/10.
#  Copyright Jjgod Jiang 2010. All rights reserved.
#

from Foundation import *
from AppKit import *

import sys, os, glob, commands, plistlib, shutil

class DictUnifierAppDelegate(NSObject):
    dropper   = objc.IBOutlet()
    label     = objc.IBOutlet()
    nameField = objc.IBOutlet()
    tempDir   = os.path.expanduser("~/.sdconv-temp")

    def applicationDidFinishLaunching_(self, sender):
        pass

    def applicationShouldTerminateAfterLastWindowClosed_(self, sender):
        return True

    def cleanup(self):
        os.system("rm -rf %s" % self.tempDir)

    def setStatus(self, str):
        self.label.performSelectorOnMainThread_withObject_waitUntilDone_(self.label.setStringValue_, str, False)

    def error(self, str):
        self.setStatus(str)
        self.cleanup()

    def startConversion(self, dict_file):
        self.performSelectorInBackground_withObject_(self.startConversionWith_, dict_file)

    def startConversionWith_(self, dict_file):
        script_file   = None
        script_module = { ".py": "python" }

        self.cleanup()
        os.makedirs(self.tempDir)

        # if it's a bzipped file, extract it first
        if dict_file.endswith(".bz2"):
            os.system("tar -xjf '%s' -C %s" % (dict_file, self.tempDir))

            ifos = glob.glob("%s/*/*.ifo" % self.tempDir)

            if len(ifos) == 0:
                self.error("No .ifo files existed in %s" % dict_file)
                return

            ifo_file = ifos[0]

        elif dict_file.endswith(".ifo"):
            if os.access(dict_file, os.R_OK):
                ifo_file = dict_file
            else:
                self.error("%s not readable" % dict_file)
                return
        else:
            self.error("%s not readable" % dict_file)
            return

        print("ifo_file = %s" % ifo_file)

        (dict_id, ext) = os.path.splitext(os.path.basename(ifo_file))
        print("dict_id = %s" % dict_id)

        dict_path = os.path.join(self.tempDir, "dict-%s" % dict_id)
        pool = NSAutoreleasePool.new()
        bundle = NSBundle.mainBundle()
        shutil.copytree(os.path.join(bundle.resourcePath(), "templates"), dict_path)

        cmd = "%s '%s' '%s/Dictionary.xml'" % (bundle.pathForAuxiliaryExecutable_("sdconv"), ifo_file, dict_path)
        print(cmd)

        (status, output) = commands.getstatusoutput(cmd)
        if status != 0:
            self.error("Convert %s failed, abort now." % dict_id)
            pool.release()
            return

        dict_name = output.split()[0].decode("utf-8")
        print("dict_name = %s" % dict_name)
        self.setStatus("Converting %s..." % dict_name)

        plist_path = os.path.join(dict_path, "DictInfo.plist")
        plist = plistlib.readPlist(plist_path)

        plist["CFBundleDisplayName"] = dict_name;
        plist["CFBundleName"] = dict_name;
        plist["CFBundleIdentifier"] = "com.apple.dictionary.%s" % dict_id

        plistlib.writePlist(plist, plist_path)
