//
//  AVQueuePlayerPrevious.h
//  XWCaptureCamera
//
//  Created by zengchao on 15/10/30.
//  Copyright © 2015年 com.xweisoft.*. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class AVQueuePlayerPrevious;

@protocol AVQueuePlayerPreviousDelegate <NSObject>
-(void)queuePlayerDidReceiveNotificationForSongIncrement:(AVQueuePlayerPrevious*)previousPlayer;
@end

@interface AVQueuePlayerPrevious : AVQueuePlayer
{
    // This is a flag used to mark whether an item being added to the queue is being added by playPreviousItem (which requires slightly different functionality then in the general case) or if it is being added by an external call
    Boolean isCalledFromPlayPreviousItem;
    
    // Adding previous song functionality requires two new class variables: one array to hold the items that the player has been initialized with (to re-create the player when necessary), and one NSNumber to keep track of which song is currently playing (to determine from where the player should be re-populated
    int nowPlayingIndex;
    
    Boolean reachToEnd;
}

@property (nonatomic, weak) id <AVQueuePlayerPreviousDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *itemsForPlayer;

-(Boolean)isAtBeginning;
-(Boolean)isAtEnd;
-(int)getIndex;

-(void)songEnded:(NSNotification *)notification;



@end
