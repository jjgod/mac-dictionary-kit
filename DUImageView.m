//
//  DUImageView.m
//  DictUnifier
//
//  Created by Jjgod Jiang on 3/11/10.
//

#import "DUImageView.h"

@implementation DUImageView

- (void) awakeFromNib
{
    [self registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
}

- (NSDragOperation) draggingEntered: (id < NSDraggingInfo >) sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation opType = NSDragOperationNone;

    if ([[pboard types] containsObject: NSFilenamesPboardType])
        opType = NSDragOperationCopy;

    return opType;
}

- (BOOL) performDragOperation: (id < NSDraggingInfo >) sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    BOOL successful = NO;

    if ([[pboard types] containsObject: NSFilenamesPboardType])
    {
        NSArray *files = [pboard propertyListForType: NSFilenamesPboardType];
        [controller startConversion: [files objectAtIndex: 0]];
        successful = NO;
    }

    return successful;
}

@end
