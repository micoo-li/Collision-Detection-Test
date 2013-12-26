//
//  GLImage.m
//  GameSample
//
//  Created by Michael on 10/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GLImage.h"

@implementation GLImage

@synthesize data, size, width, height, format, type, rowByteSize;

-(id)initWithImageName:(NSString *)name shouldFlip:(BOOL)flipVertical
{
	if ((self = [super init]))
	{
        return [[GLImage alloc] initWithImageName:name shouldFlip:flipVertical mipmapLevel:1];
	}
	return self;
}

+(id)imageWithImageName:(NSString *)name shouldFlip:(BOOL)flipVertical
{
	return [[GLImage alloc] initWithImageName:name shouldFlip:flipVertical];
}

+(id)imageWithImageName:(NSString *)name shouldFlip:(BOOL)flipVertical mipmapLevel:(GLuint)mipmap
{
    return [[GLImage alloc] initWithImageName:name shouldFlip:flipVertical mipmapLevel:mipmap];
}

-(id)initWithImageName:(NSString *)name shouldFlip:(BOOL)flipVertical mipmapLevel:(GLuint)mipmap
{
    if ((self = [super init]))
    {
        //CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[[NSBundle mainBundle] URLForImageResource:name], NULL);
        NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:name]];
       // NSImage *img = NSImagePNG
       // [img setSize:NSMakeSize(img.size.width, img.size.height)];
        //NSLog(@"Size X:%f  Size Y: %f", img.size.width, img.size.height);
        /*
        NSData *imageD = [img  TIFFRepresentation]; // converting img into data
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageD]; // converting into BitmapImageRep
        NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1/mipmap] forKey:NSImageCompressionFactor]; // any number betwwen 0 to 1
        imageD = [imageRep representationUsingType:NSJPEGFileType properties:imageProps]; // use NSPNGFileType if needed
        NSImage *resizedImage = [[NSImage alloc] initWithData:imageD];
        */
        
      //  NSImage *resizedImage = [self imageResize:img newSize:NSMakeSize(img.size.width/mipmap, img.size/mipmap)];
        
        
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[img TIFFRepresentation], NULL);
    
        //CGImageRef image = [img CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil];
		CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
		//CFRelease(imageSource);
        CFRelease(source);
		width = (GLuint)CGImageGetWidth(image);
		height = (GLuint)CGImageGetHeight(image);
		CGRect rect = CGRectMake(0, 0, width, height);
        
		void *imageData = malloc(width*height*sizeof(GLubyte)*4);
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef ctx = CGBitmapContextCreate(imageData, width, height, 8, width*4, colorSpace, kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
		CFRelease(colorSpace);
		CGContextSetBlendMode(ctx, kCGBlendModeCopy);
		CGContextDrawImage(ctx, rect, image);
		CFRelease(image);
        CFRelease(ctx);
		
		self.data = imageData;
        
        
		self.format = GL_RGBA8;
		self.type = GL_UNSIGNED_INT_8_8_8_8;
        
		self.rowByteSize = width*4*(1/mipmap);
        self.size = self.rowByteSize*height*(1/mipmap);
        
        }
    
    return self;
}

-(void)dealloc
{
    free(self.data);
}

-(GLImage *)self
{
    return [GLImage imageWithImageName:@"hi" shouldFlip:NO];
}

- (NSImage *)imageResize:(NSImage*)anImage
                 newSize:(NSSize)newSize
{
    NSImage *sourceImage = anImage;
    [sourceImage setScalesWhenResized:YES];
    
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid])
    {
        NSLog(@"Invalid Image");
    } else
    {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}


@end
