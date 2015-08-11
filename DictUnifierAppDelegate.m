//
//  DictUnifierAppDelegate.m
//  DictUnifier
//
//  Created by Jjgod Jiang on 3/11/10.
//  Copyright 2010 Jjgod Jiang. All rights reserved.
//

#import "DictUnifierAppDelegate.h"

@implementation DictUnifierAppDelegate

@synthesize tempDir, dictDir, dictID, buildTask, totalEntries;

- (id) init
{
    if (self = [super init]) {
        self.tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent: @"DictUnifier"];
        self.buildTask = nil;
        self.totalEntries = 1;
    }

    return self;
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (id) sender
{
    return YES;
}

- (void) applicationWillTerminate: (id) sender
{
    [self stop: sender];
}

- (void) startConversion: (NSString *) dictFile
{
    [self performSelectorInBackground: @selector(startConversionWith:) withObject: dictFile];
}

- (void) showProgress
{
    [dropper setHidden: YES];
    [progressBar startAnimation: nil];
    [progressBar setIndeterminate: YES];
    [progressBar setHidden: NO];
}

- (void) hideProgress
{
    [progressBar stopAnimation: self];
    [progressBar setHidden: YES];
}

- (void) setProgress: (double) curr
{
    [progressBar setDoubleValue: curr];
}

- (void) prepareName: (NSArray *) outputArray
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    [self hideProgress];
    [nameField setStringValue: [outputArray objectAtIndex: 0]];

    self.totalEntries = [[outputArray objectAtIndex: 1] integerValue];
    NSLog(@"totalEntries = %lu", self.totalEntries);
    if (self.totalEntries <= 0)
        self.totalEntries = 1;

    [self setStatus: NSLocalizedString(@"Enter a name to start building", "")];
    [nameField setHidden: NO];
    [nameField setEnabled: YES];

    [button setAction: @selector(startBuilding:)];
    [button setTitle: NSLocalizedString(@"Start", "")];
    [button setHidden: NO];

    [pool release];
}

- (void) startConversionWith: (NSString *) dictFile
{
    NSLog(@"startConversionWith: %@", dictFile);

    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSFileManager *manager = [[NSFileManager alloc] init];

    [self cleanup];

    NSLog(@"Creating %@", self.tempDir);

    if (! [manager createDirectoryAtPath: self.tempDir
             withIntermediateDirectories: YES
                              attributes: nil
                                   error: NULL])
    {
        NSLog(@"Failed to create directory %@", self.tempDir);
        goto exit;
    }

    NSLog(@"dict extension: %@", [dictFile pathExtension]);
    NSString *ifoFile = nil;

    if ([[dictFile pathExtension] isEqual: @"ifo"])
        ifoFile = dictFile;

    // Extract that file if it is a bzipped archive
    else if ([[dictFile pathExtension] isEqual: @"bz2"])
    {
        NSTask *task = [NSTask launchedTaskWithLaunchPath: @"/usr/bin/tar"
                                                arguments: [NSArray arrayWithObjects:
                                                            @"-xjf", dictFile,
                                                            @"-C", self.tempDir, nil]];
        [task waitUntilExit];

        if ([task terminationStatus])
        {
            NSLog(@"Failed to untar %@ at %@", dictFile, self.tempDir);
            goto exit;
        }

        NSArray *dirContents = [manager contentsOfDirectoryAtPath: self.tempDir error: NULL];
        if ([dirContents count])
        {
            NSString *extractedPath = [self.tempDir stringByAppendingPathComponent:
                                       [dirContents objectAtIndex: 0]];
            dirContents = [manager contentsOfDirectoryAtPath: extractedPath error: NULL];
            for (NSString *file in dirContents)
                if ([[file pathExtension] isEqual: @"ifo"])
                    ifoFile = [extractedPath stringByAppendingPathComponent: file];
        }
    }

    if (! ifoFile)
    {
        NSLog(@"Failed to find any matching ifo file.");
        goto exit;
    }

    NSLog(@"ifoFile = %@", ifoFile);
    self.dictID = [[[ifoFile lastPathComponent] stringByDeletingPathExtension] retain];
    NSLog(@"dictID = %@", self.dictID);

    self.dictDir = [self.tempDir stringByAppendingPathComponent:
                    [NSString stringWithFormat: @"dict-%@", self.dictID]];

    if (! [manager createDirectoryAtPath: self.dictDir
             withIntermediateDirectories: YES
                              attributes: nil
                                   error: NULL])
    {
        NSLog(@"Failed to create directory %@", self.dictDir);
        goto exit;
    }

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *templateDir = [[bundle resourcePath] stringByAppendingPathComponent: @"templates"];
    NSArray *dirContents = [manager contentsOfDirectoryAtPath: templateDir error: NULL];

    // Copy all the files under templates directory to temporary dictionary building directory
    for (NSString *file in dirContents)
        [manager copyItemAtPath: [templateDir stringByAppendingPathComponent: file]
                         toPath: [self.dictDir stringByAppendingPathComponent: file]
                          error: NULL];

    [self showProgress];
    [self setStatus: [NSString stringWithFormat:
                        NSLocalizedString(@"Converting %@...", ""),
                        [dictFile lastPathComponent]]];

    // Prepare to run the actual conversion utility: sdconv with ifoFile as source file
    NSTask *task = [[[NSTask alloc] init] autorelease];
    NSPipe *pipe = [NSPipe pipe];

    [task setLaunchPath: [bundle pathForAuxiliaryExecutable: @"sdconv"]];
    [task setArguments: [NSArray arrayWithObjects:
                         ifoFile, [self.dictDir stringByAppendingPathComponent: @"Dictionary.xml"], nil]];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];

    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus])
    {
        NSLog(@"Failed to run sdconv.");
        [self error: [NSString stringWithFormat:
                      NSLocalizedString(@"Convert %@ failed, abort now.", ""), self.dictID]];
        [self hideProgress];
        [dropper setHidden: NO];
        goto exit;
    }

    NSFileHandle *handle = [pipe fileHandleForReading];
    NSString *output = [[[NSString alloc] initWithData: [handle readDataToEndOfFile]
                                              encoding: NSUTF8StringEncoding] autorelease];

    [self performSelectorOnMainThread: @selector(prepareName:)
                           withObject: [output componentsSeparatedByString: @" "]
                        waitUntilDone: YES];

exit:
    [manager release];
    [pool release];
}

- (void) showDone
{
    [button setHidden: YES];
    [self hideProgress];

    NSString *imageFile = [[[NSBundle mainBundle] resourcePath]
                            stringByAppendingPathComponent: @"done.png"];
    NSImage *done = [[NSImage alloc] initWithContentsOfFile: imageFile];
    [dropper setImage: done];
    [done release];

    [dropper setHidden: NO];
    [self setStatus: NSLocalizedString(@"Done", "")];
}

- (int) runProgram: (NSString *) program withArguments: (NSArray *) arguments
{
    NSTask *task = [NSTask launchedTaskWithLaunchPath: program
                                            arguments: arguments];

    [task waitUntilExit];
    return [task terminationStatus];
}

- (void) taskFileHandleRead: (NSNotification *) notification
{
	NSDictionary *userInfo = [notification userInfo];
	int error = [[userInfo objectForKey: @"NSFileHandleError"] intValue];

    if (error)
        NSLog(@"DictUnifier: error %d.", error);
    else
    {
		NSData *data = [userInfo objectForKey: NSFileHandleNotificationDataItem];
		NSUInteger length = [data length];
        if (length == 0)
            return;

        NSString *str = [NSString stringWithUTF8String: [data bytes]];

        if ([str hasPrefix: @"- "])
        {
            NSUInteger start, end;
            [str getLineStart: &start
                          end: &end
                  contentsEnd: NULL
                     forRange: NSMakeRange(0, 0)];
            NSString *statusStr = [str substringWithRange: NSMakeRange(start + 2,
                                                                       end - start - 3)];
            [self setStatus: NSLocalizedString(statusStr, "status during dictionary building")];
            if ([statusStr rangeOfString: @"Adding body data"].location != NSNotFound)
            {
                NSString *bodyList = [[self.dictDir stringByAppendingPathComponent: @"objects"]
                                      stringByAppendingPathComponent: @"entry_body_list.txt"];
                while (1)
                {
                    if ([[NSFileManager defaultManager] fileExistsAtPath: bodyList])
                    {
                        int fd = open([bodyList fileSystemRepresentation], O_RDONLY);
                        NSLog(@"Start watching %@", bodyList);
                        [progressBar setIndeterminate: NO];
                        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                        dispatch_source_t fileSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, globalQueue);
                        dispatch_source_set_cancel_handler(fileSource, ^{ close(fd); } );
                        dispatch_source_set_event_handler(fileSource, ^{
                            char buf[1024];
                            int len = read(fd, buf, sizeof(buf));
                            if (len > 0) {
                                // NSLog(@"Got data from stdin: %.*s", len, buf);
                                int i;
                                // scan backwards for the first \t, it's where the last processed item number ends
                                for (i = len - 1; i >= 0 && buf[i] != '\t'; i--)
                                    ;
                                // scan backwards to read in the last processed item number
                                if (i > 0 && buf[i] == '\t') {
                                    int end = i;
                                    for (i--; i >= 0 && buf[i] != '\n'; i--)
                                        ;
                                    if (buf[i] == '\n') {
                                        buf[end] = '\0';
                                        char *str = buf + i + 1;
                                        int curr = 0;
                                        sscanf(str, "%d", &curr);
                                        [self setProgress: curr * 100.0 / self.totalEntries];
                                    }
                                }
                            }
                        });
                        dispatch_resume(fileSource);
                        break;
                    } else
                        sleep(0.5);
                }
            }
        }

        [[notification object] readInBackgroundAndNotify];
    }
}

- (void) startBuildingWith: (NSString *) dictName
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    [self setStatus: [NSString stringWithFormat: NSLocalizedString(@"Building %@...", ""), dictName]];

    NSLog(@"dictDir = %@", self.dictDir);

    // Set the name and id strings accordingly for the dictionary to build
    NSString *plistPath = [self.dictDir stringByAppendingPathComponent: @"DictInfo.plist"];
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile: plistPath];

    [plist setObject: dictName forKey: @"CFBundleDisplayName"];
    [plist setObject: dictName forKey: @"CFBundleName"];
    [plist setObject: [NSString stringWithFormat: @"com.apple.dictionary.%@", self.dictID]
              forKey: @"CFBundleIdentifier"];

    [plist writeToFile: plistPath atomically: YES];

    // Construct the arguments to invoke build_dict.sh from Dictionary
    // Development Kit
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *binaryDir = [[bundle resourcePath] stringByAppendingPathComponent: @"bin"];
    NSTask *task = [[[NSTask alloc] init] autorelease];
    NSPipe *pipe = [NSPipe pipe];
    NSDictionary *environments = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"en_US.UTF-8", @"LANG",
                                    binaryDir, @"DICT_BUILD_TOOL_BIN", nil];
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:self.dictID, @"Dictionary.xml",
                                    @"Dictionary.css", @"DictInfo.plist", nil];

    // If we have Mac OS X 10.6, use the new (compress) feature provided by Dictionary Development Kit.
    NSDictionary *version = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString *productVersion = [version objectForKey:@"ProductVersion"];
    NSInteger versionMinor = [[[productVersion componentsSeparatedByString:@"."] lastObject] integerValue];
    if (versionMinor >= 6) {
        [arguments insertObject: @"-v" atIndex: 0];
        [arguments insertObject: versionMinor >= 11 ? @"10.11" : @"10.6" atIndex: 1];
        NSLog(@"%@", arguments);
    }

    [task setEnvironment: environments];
    [task setCurrentDirectoryPath: self.dictDir];
    [task setLaunchPath: [binaryDir stringByAppendingPathComponent: @"build_dict.sh"]];
    [task setArguments: arguments];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];

    // Read process output in background and update status accordingly
    NSFileHandle *readHandle = [pipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskFileHandleRead:)
                                                 name: NSFileHandleReadCompletionNotification
                                               object: readHandle];
    [readHandle readInBackgroundAndNotify];
    [task launch];

    self.buildTask = task;
    [task waitUntilExit];
    self.buildTask = nil;

    NSString *dictBasename = [NSString stringWithFormat: @"%@.dictionary", self.dictID];
    NSString *srcDict = [[self.dictDir stringByAppendingPathComponent: @"objects"]
                         stringByAppendingPathComponent: dictBasename];
    NSFileManager *manager = [[[NSFileManager alloc] init] autorelease];
    BOOL isDirectory;

    if (! [task terminationStatus] &&
        [manager fileExistsAtPath: srcDict isDirectory: &isDirectory] && isDirectory)
    {
        NSString *destDir = [@"~/Library/Dictionaries" stringByExpandingTildeInPath];
        NSString *destDict = [destDir stringByAppendingPathComponent: dictBasename];

        [self setStatus: [NSString stringWithFormat:
                            NSLocalizedString(@"Installing into %@...", ""), destDir]];

        NSLog(@"Creating %@", destDir);
        [self runProgram: @"/bin/mkdir" withArguments: [NSArray arrayWithObjects: @"-p", destDir, nil]];
        NSLog(@"Removing %@", destDict);
        [self runProgram: @"/bin/rm" withArguments: [NSArray arrayWithObjects: @"-rf", destDict, nil]];
        NSLog(@"Installing %@ to %@", srcDict, destDict);
        [self runProgram: @"/usr/bin/ditto"
           withArguments: [NSArray arrayWithObjects:
                           @"--noextattr", @"--norsrc", srcDict, destDict, nil]];
        NSLog(@"Done.");
        [self showDone];
    }

    [self cleanup];
    [pool release];
}

- (IBAction) startBuilding: (id) sender
{
    [nameField setHidden: YES];
    [self showProgress];

    [button setAction: @selector(stop:)];
    [button setTitle: NSLocalizedString(@"Stop", "")];

    [self performSelectorInBackground: @selector(startBuildingWith:)
                           withObject: [nameField stringValue]];
}

- (void) dealloc
{
    [buildTask release];
    [dictID release];
    [dictDir release];
    [tempDir release];
    [super dealloc];
}

- (void) cleanup
{
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath: self.tempDir
                                             isDirectory: &isDirectory] && isDirectory)
    {
        NSLog(@"Removing %@", self.tempDir);
        NSTask *task = [NSTask launchedTaskWithLaunchPath: @"/bin/rm"
                                                arguments: [NSArray arrayWithObjects:
                                                            @"-rf", self.tempDir, nil]];
        [task waitUntilExit];
    }
}

- (void) setStatus: (NSString *) str
{
    [label setStringValue: str];
}

- (void) error: (NSString *) str
{
    [self setStatus: str];
    [self cleanup];
}

- (IBAction) stop: (id) sender
{
    if (self.buildTask)
    {
        [self.buildTask terminate];
        system("killall add_body_record");
    }

    [self hideProgress];
    [button setHidden: YES];
    [dropper setHidden: NO];
    [self setStatus: NSLocalizedString(@"Drop a dictionary file to convert", "")];
    [self cleanup];
}

@end
