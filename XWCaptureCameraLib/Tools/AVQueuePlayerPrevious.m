//
//  AVQueuePlayerPrevious.m
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/30.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import "AVQueuePlayerPrevious.h"

@implementation AVQueuePlayerPrevious

@synthesize itemsForPlayer = _itemsForPlayer;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// CONSTRUCTORS

-(id)initWithItems:(NSArray *)items
{
    // This function calls the constructor for AVQueuePlayer, then sets up the nowPlayingIndex to 0 and saves the array that the player was generated from as itemsForPlayer

    self = [super initWithItems:items];
    if (self){
        self.itemsForPlayer = [NSMutableArray arrayWithArray:items];
        nowPlayingIndex = 0;
        isCalledFromPlayPreviousItem = NO;
        
        self.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(songEnded:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
    }
    return self;
}

+ (AVQueuePlayerPrevious *)queuePlayerWithItems:(NSArray *)items
{
    // This function just allocates space for, creates, and returns an AVQueuePlayerPrevious from an array.
    // Honestly I think having it is a bit silly, but since its present in AVQueuePlayer it needs to be
    // overridden here to ensure compatability.
    AVQueuePlayerPrevious *playerToReturn = [[AVQueuePlayerPrevious alloc] initWithItems:items];
    return playerToReturn;
}

// NEW METHODS

-(void)songEnded:(NSNotification *)notification {
    // This method is called by NSNotificationCenter when a song finishes playing; all it does is increment
    // nowPlayingIndex
    AVPlayerItem *cItem = notification.object;
    
    if (self.currentItem != cItem) {
        return;
    }
    
    if (nowPlayingIndex == [_itemsForPlayer count] - 1) {
        reachToEnd = YES;
        [self resetPlayerItems];
    }
    else {
        reachToEnd = NO;
        [self advanceToNextItem];
    }
    
    [self.delegate queuePlayerDidReceiveNotificationForSongIncrement:self];
}

- (BOOL)resetPlayerItems
{
    [self pause];
    
    [super removeAllItems];
    
    for (AVPlayerItem *item in _itemsForPlayer) {
        [item seekToTime:kCMTimeZero];
        if ([self canInsertItem:item afterItem:nil]) {
            [self insertItem:item afterItem:nil];
        }
    }
    nowPlayingIndex = 0;
    
    return YES;
}

-(Boolean)isAtBeginning
{
    // This function simply returns whether or not the AVQueuePlayerPrevious is at the first song. This is
    // useful for implementing custom behavior if the user tries to play a previous song at the start of
    // the queue (such as restarting the song).
    if (nowPlayingIndex == 0){
        return YES;
    } else {
        return NO;
    }
}

-(Boolean)isAtEnd
{
    if (reachToEnd){
        return YES;
    } else {
        return NO;
    }
}

-(int)getIndex
{
    // This method simply returns the now playing index
    return nowPlayingIndex;
}

// OVERRIDDEN AVQUEUEPLAYER METHODS

-(void)removeAllItems
{
    // This does the same thing as the normal AVQueuePlayer removeAllItems, but also sets the
    // nowPlayingIndex to 0.
    [super removeAllItems];
    nowPlayingIndex = 0;
    [_itemsForPlayer removeAllObjects];
}

-(void)removeItem:(AVPlayerItem *)item
{
    [super removeItem:item];
    int appearancesBeforeCurrent = 0;
    for (int tracer = 0; tracer < nowPlayingIndex; tracer++){
        if ([_itemsForPlayer objectAtIndex:tracer] == item) {
            appearancesBeforeCurrent++;
        }
    }
    nowPlayingIndex -= appearancesBeforeCurrent;
    [_itemsForPlayer removeObject:item];
}

- (void)advanceToNextItem
{
    // The only addition this method makes to AVQueuePlayer is advancing the nowPlayingIndex by 1.
    [super advanceToNextItem];
    if (nowPlayingIndex < [_itemsForPlayer count] - 1){
        nowPlayingIndex++;
    }
}


@end
