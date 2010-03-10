#
#  DictUnifierAppDelegate.py
#  DictUnifier
#
#  Created by Jiang Jiang on 3/7/10.
#  Copyright Jjgod Jiang 2010. All rights reserved.
#

from Foundation import *
from AppKit import *

import sys, os, glob, commands, plistlib, shutil, subprocess, time, re

class DictUnifierAppDelegate(NSObject):
    dropper   = objc.IBOutlet()
    label     = objc.IBOutlet()
    nameField = objc.IBOutlet()
    progressBar = objc.IBOutlet()
    button    = objc.IBOutlet()
    tempDir   = os.path.expanduser("~/.sdconv-temp")
    dictDir   = None
    dictID    = None
    process   = None
    totalEntries = 0

    def applicationDidFinishLaunching_(self, sender):
        pass

    def applicationShouldTerminateAfterLastWindowClosed_(self, sender):
        return True

    def applicationWillTerminate_(self, sender):
        self.stop_(sender)

    def cleanup(self):
        os.system("rm -rf %s" % self.tempDir)

    def setStatus(self, str):
        self.label.setStringValue_(str)

    def hideStatus(self):
        self.label.setHidden_(True)

    def showStatus(self):
        self.label.setHidden_(False)

    def showProgress(self):
        self.progressBar.setIndeterminate_(True)
        self.progressBar.setHidden_(False)
        self.progressBar.startAnimation_(self)

    def hideProgress(self):
        self.progressBar.setIndeterminate_(True)
        self.progressBar.stopAnimation_(self)
        self.progressBar.setHidden_(True)

    def setProgress(self, curr):
        self.progressBar.setDoubleValue_(curr)

    def error(self, str):
        self.setStatus(str)
        self.cleanup()

    @objc.IBAction
    def stop_(self, sender):
        if self.process is not None:
            os.system("kill %d" % self.process.pid)
            os.system("killall add_body_record")
            self.hideProgress()
            self.setProgress(0)
            self.button.setHidden_(True)
            self.dropper.setHidden_(False)
            self.setStatus("Drop a dictionary file to convert")
            self.cleanup()

    @objc.IBAction
    def startBuilding_(self, sender):
        self.nameField.setHidden_(True)
        self.button.setHidden_(True)

        dict_name = self.nameField.stringValue()
        self.performSelectorInBackground_withObject_(self.startBuildingWith_, dict_name)

    def startConversion(self, dict_file):
        self.performSelectorInBackground_withObject_(self.startConversionWith_, dict_file)

    def startConversionWith_(self, dict_file):
        script_file   = None
        script_module = { ".py": "python" }

        pool = NSAutoreleasePool.new()
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

        (self.dictID, ext) = os.path.splitext(os.path.basename(ifo_file))
        print("self.dictID = %s" % self.dictID)

        self.dictDir = os.path.join(self.tempDir, "dict-%s" % self.dictID)

        bundle = NSBundle.mainBundle()
        shutil.copytree(os.path.join(bundle.resourcePath(), "templates"), self.dictDir)

        cmd = "%s '%s' '%s/Dictionary.xml'" % (bundle.pathForAuxiliaryExecutable_("sdconv"), ifo_file, self.dictDir)
        print(cmd)

        self.dropper.setHidden_(True)
        self.showProgress()
        self.setStatus("Converting %s..." % os.path.basename(dict_file))
        (status, output) = commands.getstatusoutput(cmd)
        if status != 0:
            self.error("Convert %s failed, abort now." % self.dictID)
            self.hideProgress()
            return

        convert_result = output.split()
        self.performSelectorOnMainThread_withObject_waitUntilDone_(self.prepareName_, convert_result, True)

    def prepareName_(self, convert_result):
        pool = NSAutoreleasePool.new()

        self.hideProgress()
        self.nameField.setStringValue_(convert_result[0].decode("utf-8"))
        self.totalEntries = int(convert_result[1])

        self.setStatus("Enter a name to start building")
        self.nameField.setHidden_(False)
        self.nameField.setEnabled_(True)

        self.button.setAction_(self.startBuilding_)
        self.button.setTitle_("Start")
        self.button.setHidden_(False)

    def startBuildingWith_(self, dict_name):
        pool = NSAutoreleasePool.new()
        self.setStatus("Building %s..." % dict_name.encode("utf-8"))

        plist_path = os.path.join(self.dictDir, "DictInfo.plist")
        plist = plistlib.readPlist(plist_path)

        plist["CFBundleDisplayName"] = dict_name
        plist["CFBundleName"] = dict_name
        plist["CFBundleIdentifier"] = "com.apple.dictionary.%s" % self.dictID

        plistlib.writePlist(plist, plist_path)

        bundle = NSBundle.mainBundle()
        bin_dir = os.path.join(bundle.resourcePath(), "bin")
        os.putenv("LANG", "en_US.UTF-8")
        os.putenv("DICT_BUILD_TOOL_BIN", bin_dir)

        args = [ "%s/build_dict.sh" % bin_dir, self.dictID, "Dictionary.xml", "Dictionary.css", "DictInfo.plist" ]
        if commands.getoutput("sw_vers -productVersion")[:4] == "10.6":
            args.insert(1, "-v")
            args.insert(2, "10.6")

        self.dropper.setHidden_(True)
        self.showProgress()

        self.process = subprocess.Popen(args, shell=False, cwd=self.dictDir)
        f = None
        body_list = os.path.join(self.dictDir, "objects", "entry_body_list.txt")

        self.button.setAction_(self.stop_)
        self.button.setTitle_("Stop")
        self.button.setHidden_(False)

        while True:
            if f is None and os.path.isfile(body_list):
                f = open(body_list)
                if f:
                    self.progressBar.setIndeterminate_(False)
            if f:
                where = f.tell()
                line = f.readline()
                if line and len(line.split()) > 1:
                    curr = int(line.split()[0]) + 1
                    self.setProgress(float(curr) / float(self.totalEntries) * 100.0)
                    if curr == self.totalEntries:
                        self.progressBar.setIndeterminate_(True)
                        break
                else:
                    time.sleep(0.5)
                    f.seek(where)
            else:
                time.sleep(1)

        self.process.wait()
        self.button.setHidden_(True)
        self.hideProgress()

        file = os.path.join(bundle.resourcePath(), "done.png")
        done = NSImage.alloc().initWithContentsOfFile_(file)
        self.dropper.setImage_(done)
        done.release()

        self.dropper.setHidden_(False)

        dest_dir = os.path.expanduser("~/Library/Dictionaries")
        self.setStatus("Installing into %s..." % dest_dir)

        os.system("mkdir -p %s" % dest_dir)
        os.system("rm -rf '%s/%s.dictionary'" % (dest_dir, self.dictID))
        ditto_cmd = "ditto --noextattr --norsrc '%s/objects/%s.dictionary' '%s/%s.dictionary'" % (self.dictDir, self.dictID, dest_dir, self.dictID)
        print(ditto_cmd)
        os.system(ditto_cmd)
        os.utime(dest_dir, None)

        self.process = None

        self.cleanup()
        self.setStatus("Done.")

        pool.release()
