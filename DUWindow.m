//
//  DUWindow.m
//  DictUnifier
//
//  Created by Jjgod Jiang on 3/11/10.
//

#import "DUWindow.h"

@implementation DUWindow

- (void) awakeFromNib
{
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSPasteboardTypeFileURL, nil]];
}

- (NSDragOperation) draggingEntered: (id < NSDraggingInfo >) sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation opType = NSDragOperationNone;

    if ([[pboard types] containsObject: NSPasteboardTypeFileURL])
        opType = NSDragOperationCopy;

    return opType;
}

- (BOOL) performDragOperation: (id < NSDraggingInfo >) sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    BOOL successful = NO;

    if ([[pboard types] containsObject: NSPasteboardTypeFileURL])
    {
        /**
         Note: tmp fix
         ENV: Xcode 11.3.1 (11C504) Catalina 10.15.3 (19D76)
         
         Don't know why  [pboard propertyListForType: NSPasteboardTypeFileURL]  returns a string directly instead of an array.
         */
        NSObject *data = [pboard propertyListForType: NSPasteboardTypeFileURL];
        if ([data isKindOfClass: [NSArray class]]) {
            NSArray * files = (NSArray *)data;
            [controller startConversion: [files objectAtIndex: 0]];
        } else if ([data isKindOfClass: [NSString class]]) {
            NSString * filePath = (NSString *)data;
            NSURL * fileUrl = [NSURL URLWithString: filePath];
            [controller startConversion: fileUrl.path];
        }

        successful = NO;
    }

    return successful;
}

@end
