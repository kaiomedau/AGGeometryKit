//
// Author: Håvard Fossli <hfossli@agens.no>
//
// Copyright (c) 2013 Agens AS (http://agens.no/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "CALayer+Extensions.h"
#import <objc/runtime.h>
#import "AGVector3D.h"

@implementation CALayer (Extensions)

- (void)setNullAsActionForKeys:(NSArray *)keys
{
    NSMutableDictionary *dict = [self.actions mutableCopy];
    
    if(dict == nil)
    {
        dict = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
    }
    
    for(NSString *key in keys)
    {
        [dict setObject:[NSNull null] forKey:key];
    }
    
    self.actions = dict;
}

- (void)removeAllSublayers
{
    for(CALayer *sublayer in self.sublayers)
    {
        [sublayer removeFromSuperlayer];
    }
}

- (void)ensureAnchorPointIsSetToZero
{
    [self ensureAnchorPointIs:CGPointZero];
}

- (void)ensureAnchorPointIs:(CGPoint)point
{
    if(!CGPointEqualToPoint(self.anchorPoint, point))
    {
        CGRect frame = self.frame;
        self.anchorPoint = point;
        self.frame = frame;
    }
}

- (CGPoint)outerPointForInnerPoint:(CGPoint)innerPoint
{
    if(self.superlayer == nil)
    {
        [NSException raise:NSInternalInconsistencyException format:@"[CALayer-Extensions] To calculate the outer point for a givven inner point it is required that the layer have a superlayer. This can hopefully be improved."];
    }
    
    if(!CGPointEqualToPoint(self.anchorPoint, CGPointZero))
    {
        [NSException raise:NSInternalInconsistencyException format:@"[CALayer-Extensions] This method is *dumb* and currently only supports anchorpoint to be 0"];
    }
    
    CGPoint outerPoint = [self convertPoint:innerPoint toLayer:self.superlayer];
    outerPoint.x -= self.position.x;
    outerPoint.y -= self.position.y;
    
    if(outerPoint.x != outerPoint.x || outerPoint.y != outerPoint.y)
    {
        [NSException raise:NSInternalInconsistencyException format:@"[CALayer-Extensions] Calculated NaN values from CALayer %@", self];
    }
    
    return outerPoint;
}

- (CATransform3D)transformToOffsetRotationWithVirtualAnchorPoint:(CGPoint)virtualAnchor
{
    CGPoint anchorDiff = CGPointMake((virtualAnchor.x-self.anchorPoint.x)*-1.0f,
                                     virtualAnchor.y-self.anchorPoint.y);

    if (CGPointEqualToPoint(anchorDiff, CGPointMake(0.0f, 0.0f)))
    {
        return self.transform;
    }

    AGVector3D vec3D = AGVector3DMake(self.bounds.size.width*anchorDiff.x,
                                      self.bounds.size.height*anchorDiff.y, 0.0f);
    vec3D = AGVector3DApplyTransformWithNoTranslate(vec3D, self.transform);

    CATransform3D translation = CATransform3DMakeTranslation(vec3D.x-anchorDiff.x*self.bounds.size.width,
                                                vec3D.y-anchorDiff.y*self.bounds.size.height, vec3D.z);

    return CATransform3DConcat(self.transform, translation);
}

- (void)applyTransformToOffsetRotationWithVirtualAnchorPoint:(CGPoint)virtualAnchor
{
    CATransform3D translate = [self transformToOffsetRotationWithVirtualAnchorPoint:virtualAnchor];
    self.transform = CATransform3DConcat(self.transform, translate);
}

- (CGPoint)offsetForXRotation:(CGFloat)angle virtualAnchorPoint:(CGPoint)virtualAnchor
{
    CGPoint anchorDiff = CGPointMake(virtualAnchor.x-self.anchorPoint.x,
                                     self.anchorPoint.y-virtualAnchor.y);

    CGPoint t;
    t.x = (self.bounds.size.height-self.bounds.size.height*cosf(angle))*anchorDiff.y;
    t.y = -self.bounds.size.height*anchorDiff.y*sinf(angle);

    return t;
}

- (CGPoint)offsetForYRotation:(CGFloat)angle virtualAnchorPoint:(CGPoint)virtualAnchor
{
    CGPoint anchorDiff = CGPointMake(virtualAnchor.x-self.anchorPoint.x,
                                     self.anchorPoint.y-virtualAnchor.y);

    CGPoint t;
    t.x = (self.bounds.size.width-self.bounds.size.width*cosf(angle))*anchorDiff.x;
    t.y = -self.bounds.size.width*anchorDiff.x*sinf(angle);

    return t;
}

@end
