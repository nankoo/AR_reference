/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/
//VideoPlaybackeaglview.h


#import <UIKit/UIKit.h>

#import <QCAR/UIGLViewProtocol.h>

#import "Texture.h"
#import "SampleApplicationSession.h"
#import "VideoPlayerHelper.h"

//定数
#define NUM_AUGMENTATION_TEXTURES 5
#define NUM_VIDEO_TARGETS 2

// VideoPlayback is a subclass of UIView and conforms to the informal protocol
// UIGLViewProtocol
@interface VideoPlaybackEAGLView : UIView <UIGLViewProtocol> {
@private
    
    // Instantiate one VideoPlayerHelper per target
    //ターゲットごとにvideoplayerhelperのインスタンスをつくる
    VideoPlayerHelper* videoPlayerHelper[NUM_VIDEO_TARGETS];
    float videoPlaybackTime[NUM_VIDEO_TARGETS];
    
    
    VideoPlaybackViewController * videoPlaybackViewController ;
    
    // Timer to pause on-texture video playback after tracking has been lost.
    // Note: written/read on two threads, but never concurrently
    //concurrently:同時に/pause：休止する/
    NSTimer* trackingLostTimer;
    
    // Coordinates of user touch
    //ユーザータッチの場所？
    float touchLocation_X;
    float touchLocation_Y;
    
    // Lock to synchronise data that is (potentially) accessed concurrently
    //synchronise:時間または方法で、同時に起こさせ調整する/
    NSLock* dataLock;
    
    
    // OpenGL ES context
    //EAGLContext:OpenGL ESを使用して描画するのに必要なリソースやコマンド、状態情報を管理
    EAGLContext *context;
    
    // The OpenGL ES names for the framebuffer and renderbuffers used to render
    // to this view
    //framebuffer:OpenGLでプラットフォームに依存せず オフスクリーンレンダリングを実現する機構/複数の論理バッファを統合する より抽象的なデータ構造
    //renderbuffers:renderbuffer の実体は2次元ピクセル配列であり texture buffer と同じ 階層で取り扱われるバッファ
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
    // GLuint：変数の型

    // Shader handles
    GLuint shaderProgramID;
    GLint vertexHandle;
    GLint normalHandle;
    GLint textureCoordHandle;
    GLint mvpMatrixHandle;
    GLint texSampler2DHandle;
    
    // Texture used when rendering augmentation
    Texture* augmentationTexture[NUM_AUGMENTATION_TEXTURES];

    SampleApplicationSession * vapp;
}

- (id)initWithFrame:(CGRect)frame rootViewController:(VideoPlaybackViewController *) rootViewController appSession:(SampleApplicationSession *) app;

- (void) prepare;
- (void) dismiss;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;

- (bool) handleTouchPoint:(CGPoint) touchPoint;
- (bool) handleDoubleTouchPoint:(CGPoint) touchPoint;

- (void) preparePlayers;
- (void) dismissPlayers;

@end

