/*==============================================================================
 Copyright (c) 2012-2013 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#import "SampleApplicationShaderUtils.h"

@implementation SampleApplicationShaderUtils

+ (GLuint)compileShader:(NSString*)shaderFileName withDefs:(NSString *) defs withType:(GLenum)shaderType {
    NSLog(@"番号105");
    
    NSString* shaderName = [[shaderFileName lastPathComponent] stringByDeletingPathExtension];
    NSString* shaderFileType = [shaderFileName pathExtension];
    
    NSLog(@"debug: shaderName=(%@), shaderFileTYpe=(%@)", shaderName, shaderFileType);
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:shaderFileType];
    NSLog(@"debug: shaderPath=(%@)", shaderPath);
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"番号105a");
        
        NSLog(@"Error loading shader (%@): %@", shaderFileName, error.localizedDescription);
        return 0;
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    
    if (defs == nil) {
        NSLog(@"番号105b");
        glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    } else {
        NSLog(@"番号105c");
        const char* finalShader[2] = {[defs UTF8String],shaderStringUTF8};
        GLint finalShaderSizes[2] = {[defs length], shaderStringLength};
        glShaderSource(shaderHandle, 2, finalShader, finalShaderSizes);
    }
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        NSLog(@"番号105d");
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"Error compiling shader (%@): %@", shaderFileName, messageString);
        return 0;
    }
    
    return shaderHandle;
    
}

+ (int)createProgramWithVertexShaderFileName:(NSString*) vertexShaderFileName
                      fragmentShaderFileName:(NSString *) fragmentShaderFileName {
    NSLog(@"番号106");
    return [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:vertexShaderFileName
                                          withVertexShaderDefs:nil
                                        fragmentShaderFileName:fragmentShaderFileName
                                        withFragmentShaderDefs:nil];
}

+ (int)createProgramWithVertexShaderFileName:(NSString*) vertexShaderFileName
                        withVertexShaderDefs:(NSString *) vertexShaderDefs
                      fragmentShaderFileName:(NSString *) fragmentShaderFileName
                      withFragmentShaderDefs:(NSString *) fragmentShaderDefs {
    NSLog(@"番号107");
    
    GLuint vertexShader = [self compileShader:vertexShaderFileName withDefs:vertexShaderDefs withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:fragmentShaderFileName withDefs:fragmentShaderDefs withType:GL_FRAGMENT_SHADER];
    
    if ((vertexShader == 0) || (fragmentShader == 0)) {
        NSLog(@"番号107a");
        NSLog(@"Error: error compiling shaders");
        return 0;
    }
    
    GLuint programHandle = glCreateProgram();
    
    if (programHandle == 0) {
        NSLog(@"番号107b");
        NSLog(@"Error: can't create programe");
        return 0;
    }
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        NSLog(@"番号107c");
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"Error linkink shaders (%@) and (%@): %@", vertexShaderFileName, fragmentShaderFileName, messageString);
        return 0;
    }
    return programHandle;
}


@end