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
    BOOL successful = NO;
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSArray *urls = [pboard readObjectsForClasses:@[[NSURL class]] options:nil];
        NSURL *firstURL = [urls firstObject];
        NSString *pathString = [firstURL path];
        [controller startConversion: pathString];
        successful = YES;
    }
    return successful;
}

@end
