//
//  Circle.m
//  D - falling objects
//
//  Created by Aditya Narayan on 12/1/15.
//  Copyright © 2015 turntotech.io. All rights reserved.
//

#import "Circle.h"

@implementation Circle
@synthesize collisionBoundsType;

- (UIDynamicItemCollisionBoundsType)collisionBoundsType{
  return UIDynamicItemCollisionBoundsTypeEllipse;
}

@end
