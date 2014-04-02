/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import "Texture.h"


// Private method declarations
@interface Texture (PrivateMethods)
- (BOOL)loadImage:(NSString*)filename;
- (BOOL)copyImageDataForOpenGL:(CFDataRef)imageData;
@end


@implementation Texture

//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithImageFile:(NSString*)filename
{
    NSLog(@"番号108");
    self = [super init];
    
    if (nil != self) {
        NSLog(@"番号108a");
        if (NO == [self loadImage:filename]) {
            NSLog(@"番号108aa");
            NSLog(@"Failed to load texture image from file %@", filename);
            [self autorelease];
            self = nil;
        }
    }
    
    return self;
}


- (void)dealloc
{
    NSLog(@"番号109");
    if (_pngData) {
        NSLog(@"番号109a");
        delete[] _pngData;
    }
    
    [super dealloc];
}


//------------------------------------------------------------------------------
#pragma mark - Private methods

- (BOOL)loadImage:(NSString*)filename
{
    NSLog(@"番号110");
    BOOL ret = NO;
    
    // Build the full path of the image file
    NSString* fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    
    // Create a UIImage with the contents of the file
    UIImage* uiImage = [UIImage imageWithContentsOfFile:fullPath];
    
    if (uiImage) {
        NSLog(@"番号110a");
        
        // Get the inner CGImage from the UIImage wrapper
        //CGImageRef:
        CGImageRef cgImage = uiImage.CGImage;
        
        // Get the image size
        _width = CGImageGetWidth(cgImage);
        _height = CGImageGetHeight(cgImage);
        
        // Record the number of channels
        channels = CGImageGetBitsPerPixel(cgImage)/CGImageGetBitsPerComponent(cgImage);
        
        // Generate a CFData object from the CGImage object (a CFData object represents an area of memory)
        CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
        
        // Copy the image data for use by Open GL
        ret = [self copyImageDataForOpenGL: imageData];
        
        CFRelease(imageData);
    }
    
    return ret;
}


- (BOOL)copyImageDataForOpenGL:(CFDataRef)imageData
{
    NSLog(@"番号111");
    if (_pngData) {
        NSLog(@"番号111a");
        delete[] _pngData;
    }
    
    _pngData = new unsigned char[_width * _height * channels];
    const int rowSize = _width * channels;
    const unsigned char* pixels = (unsigned char*)CFDataGetBytePtr(imageData);

    // Copy the row data from bottom to top
    for (int i = 0; i < _height; ++i) {
        NSLog(@"番号111:for");
        memcpy(_pngData + rowSize * i, pixels + rowSize * (_height - 1 - i), _width * channels);
    }
    
    return YES;
}

@end
