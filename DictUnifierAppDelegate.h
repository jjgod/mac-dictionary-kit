//
//  DictUnifierAppDelegate.h
//  DictUnifier
//
//  Created by Jjgod Jiang on 3/11/10.
//  Copyright 2010 Jjgod Jiang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DictUnifierAppDelegate : NSObject {
    IBOutlet NSImageView *dropper;
    IBOutlet NSTextField *label;
    IBOutlet NSTextField *nameField;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSButton *button;

    NSString *tempDir;
    NSString *dictDir;
    NSString *dictID;
    NSTask   *buildTask;
    NSUInteger totalEntries;
}

@property (retain) NSString *tempDir, *dictDir, *dictID;
@property (retain) NSTask   *buildTask;
@property (assign) NSUInteger totalEntries;

- (void) setStatus: (NSString *) str;
- (void) error: (NSString *) str;
- (void) startConversion: (NSString *) dictFile;
- (IBAction) startBuilding: (id) sender;
- (IBAction) stop: (id) sender;
- (void) cleanup;

@end
