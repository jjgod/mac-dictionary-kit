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

    if (pboard.pasteboardItems.count <= 1) {
        //直接获取文件路径
        
        NSString *fileURL = [[NSURL URLFromPasteboard:pboard] path];
        [controller startConversion:fileURL];
        successful = NO;
    }
    
    
    return successful;
}

@end
