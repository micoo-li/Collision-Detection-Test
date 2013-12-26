//
//  GLImage.h
//  GameSample
//
//  Created by Michael on 10/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

@interface GLImage : NSObject
{
	GLubyte *data;
	
	GLsizei size;
	
	GLuint width;
	GLuint height;
	GLenum format;
	GLenum type;
	
	GLuint rowByteSize;
}

@property GLubyte *data;
@property GLsizei size;
@property GLuint width;
@property GLuint height;
@property GLenum format;
@property GLenum type;
@property GLuint rowByteSize;

-(id)initWithImageName:(NSString *)name shouldFlip:(BOOL)flipVertical;
//-(id)initWithImageName:(NSString *)name shouldFlip:(BOOL)flipVertical mipmapLevel:(GLuint)mipmap;

+(id)imageWithImageName:(NSString *)name shouldFlip:(BOOL)flipVertical;
//+(id)imageWithImageName:(NSString *)name shouldFlip:(BOOL)flipVertical mipmapLevel:(GLuint)mipmap;



@end
