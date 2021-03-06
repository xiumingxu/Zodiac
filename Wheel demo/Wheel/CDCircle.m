#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kRotationDegrees 90

#import <QuartzCore/QuartzCore.h>

#import "CDCircle.h"
#import "CDCircleGestureRecognizer.h"
#import "CDCircleThumb.h"
#import "CDCircleOverlayView.h"

@implementation CDCircle
@synthesize circle, recognizer, path, numberOfSegments, separatorStyle, overlayView, separatorColor, ringWidth, circleColor, thumbs, overlay, numOfLevel;
@synthesize delegate, dataSource;
@synthesize inertiaeffect;
//Need to add property "NSInteger numberOfThumbs" and add this property to initializer definition, and property "CGFloat ringWidth equal to circle radius - path radius.

//Circle radius is equal to rect / 2 , path radius is equal to rect1/2.

-(id) initWithFrame:(CGRect)frame numberOfSegments: (NSInteger) nSegments ringWidth:(CGFloat) width numOfLevel:(int)level {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.inertiaeffect = YES;
        self.recognizer = [[CDCircleGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [self addGestureRecognizer:self.recognizer];
        self.opaque = NO;
        self.numberOfSegments = nSegments;
        self.separatorStyle = CDCircleThumbsSeparatorBasic;
        self.ringWidth = width;
        self.numOfLevel = level;
        self.circleColor = [UIColor clearColor];
        
        
        CGRect rect1 = CGRectMake(0, 0, CGRectGetHeight(frame) - (2*ringWidth), CGRectGetWidth(frame) - (2*ringWidth));
        self.thumbs = [NSMutableArray array];
        for (int i = 0; i < self.numberOfSegments; i++) {
            
            CDCircleThumb * thumb = [[CDCircleThumb alloc] initWithShortCircleRadius:rect1.size.height/2 longRadius:frame.size.height/2 numberOfSegments:self.numberOfSegments numberOfLever:level];
            [self.thumbs addObject:thumb];
        }
    }
    return self;
}


-(void) drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState (ctx);
    CGContextSetBlendMode(ctx, kCGBlendModeCopy);
    
    [self.circleColor setFill];
    circle = [UIBezierPath bezierPathWithOvalInRect:rect];
    [circle closePath];
    [circle fill];
    
    
    CGRect rect1 = CGRectMake(0, 0, CGRectGetHeight(rect) - (2*ringWidth), CGRectGetWidth(rect) - (2*ringWidth));
    rect1.origin.x = rect.size.width / 2  - rect1.size.width / 2;
    rect1.origin.y = rect.size.height / 2  - rect1.size.height / 2;
    
    
    path = [UIBezierPath bezierPathWithOvalInRect:rect1];
    [self.circleColor setFill];
    [path fill];
    CGContextRestoreGState(ctx);
    
    
    //Drawing Thumbs
    CGFloat fNumberOfSegments = self.numberOfSegments;
    CGFloat perSectionDegrees = 360.f / fNumberOfSegments;
    CGFloat totalRotation = 360.f /fNumberOfSegments;
    CGPoint centerPoint = CGPointMake(rect.size.width/2, rect.size.height/2);
    
    CGFloat deltaAngle;
    
    for (int i = 0; i < self.numberOfSegments; i++) {
        CDCircleThumb * thumb = [self.thumbs objectAtIndex:i];
        
        if (numOfLevel == 0){
            thumb.tag = i;
            thumb.iconView.image = [self.dataSource circle:self iconForThumbAtRow:thumb.tag];
        }else if (numOfLevel == 1) {
            thumb.tag = i;
            thumb.iconView.image = [self.dataSource circle:self iconForThumbAtRow:thumb.tag];
        }else if(numOfLevel == 2) {
            thumb.tag = i;
            thumb.iconView.image = [self.dataSource secondCircle:self iconForThumbAtRow:thumb.tag];
        }else if(numOfLevel == 3) {
            thumb.tag = i;
            thumb.iconView.image = [self.dataSource thirdCircle:self iconForThumbAtRow:thumb.tag];
        }else if(numOfLevel == 4) {
            thumb.tag = i;
            thumb.iconView.image = [self.dataSource fourthCircle:self iconForThumbAtRow:thumb.tag];
        }
        
        
        CGFloat radius = rect1.size.height/2 + ((rect.size.height/2 - rect1.size.height/2)/2) - thumb.yydifference;
        CGFloat x = centerPoint.x + (radius * cos(degreesToRadians(perSectionDegrees)));
        CGFloat yi = centerPoint.y + (radius * sin(degreesToRadians(perSectionDegrees)));
        
        
        
        [thumb setTransform:CGAffineTransformMakeRotation(degreesToRadians((perSectionDegrees + kRotationDegrees)))];
        if (i==0) {
            deltaAngle= degreesToRadians(360 - kRotationDegrees) + atan2(thumb.transform.a, thumb.transform.b);
            [thumb.iconView setIsSelected:NO];
            self.recognizer.currentThumb = thumb;
        }
        
        
        //set position of the thumb
        thumb.layer.position = CGPointMake(x, yi);
        
        
        perSectionDegrees += totalRotation;
        
        [self addSubview:thumb];
    }
    
    [self setTransform:CGAffineTransformRotate(self.transform,deltaAngle)];
    
}

-(void) tapped: (CDCircleGestureRecognizer *) arecognizer{
    if (arecognizer.ended == NO) {
        CGPoint point = [arecognizer locationInView:self];
        if ([path containsPoint:point] == NO) {
            
            [self setTransform:CGAffineTransformRotate([self transform], [arecognizer rotation])];
        }
    }
}

@end