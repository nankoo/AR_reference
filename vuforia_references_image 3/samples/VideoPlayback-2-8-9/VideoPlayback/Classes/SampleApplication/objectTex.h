/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import <Foundation/Foundation.h>
#import "VideoPlaybackEAGLView.h"


@interface objectTex : NSObject {
@private
    int channelsO;
}


// --- Properties ---
@property (nonatomic, readonly) int widthO;
@property (nonatomic, readonly) int heightO;
@property (nonatomic, readwrite) int textureIDO;
@property (nonatomic, readonly) unsigned char* pngDataO;


// --- Public methods ---
- (id)initWithImageFile:(NSString*)filename;

@end
