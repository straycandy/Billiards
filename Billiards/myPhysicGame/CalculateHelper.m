//
//  calculateHelper.m
//  myPhysicGame
//
//  Created by mengran on 2018/10/12.
//  Copyright © 2018年 ggV5. All rights reserved.
//

#import "CalculateHelper.h"


#define calculate_degreesToRadian(x) (calculate_pi * x / 180.0)
#define calculate_radiansToDegrees(x) (180.0 * x / calculate_pi)
CGFloat calculate_distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
};
CGFloat calculate_angleBetweenPoints(CGPoint first, CGPoint second) {
    CGFloat height = second.y - first.y;
    CGFloat width = first.x - second.x;
    CGFloat rads = atan(height/width);
    return calculate_radiansToDegrees(rads);
}
CGFloat calculate_angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End) {
    
    CGFloat a = line1End.x - line1Start.x;
    CGFloat b = line1End.y - line1Start.y;
    CGFloat c = line2End.x - line2Start.x;
    CGFloat d = line2End.y - line2Start.y;
    
    CGFloat rads = acos(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    
    return rads;
}

/**
 判断是否是偶数
 
 @param i 要判断的数
 @return YES:是偶数，NO:是奇数
 */
BOOL calculate_bEvenNumber(NSInteger i){
    if (i == 0) {
        return YES;
    }
    NSInteger temp = i % 2;
    return temp == 0;
}

/**
 判断是否是奇数
 
 @param i 要判断的数
 @return YES:是奇数，NO:是偶数
 */
BOOL calculate_bOddNumber(NSInteger i){
    if (i == 0) {
        return NO;
    }
    NSInteger temp = i % 2;
    return temp != 0;
}

@implementation CalculateHelper

/**
 已知起始点和终点，得到方向
 
 @param startPoint 起始点
 @param endPoint 终点
 @return 方向
 */
+ (GameAngleQuadrant)getQuadrantWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint{
    GameAngleQuadrant quandrant1;
    GameAngleQuadrant quandrant2;
    if (endPoint.x > startPoint.x) {
        //在1、4象限
        quandrant1 = GameAngleQuadrantFirst|GameAngleQuadrantFourth;
    }else{
        //在2、3象限
        quandrant1 = GameAngleQuadrantSecond|GameAngleQuadrantThird;
    }
    if (endPoint.y > startPoint.y) {
        //在1、2象限
        quandrant2 = GameAngleQuadrantFirst|GameAngleQuadrantSecond;
    }else{
        //在3、4象限
        quandrant2 = GameAngleQuadrantThird|GameAngleQuadrantFourth;
    }
    //得到最终象限
    GameAngleQuadrant quandrant = quandrant1 & quandrant2;
    return quandrant;
}

/**
 已知初始点，移动距离，方向，移动角度，得到最终距离
 
 @param startPoint 初始点
 @param distance 移动距离
 @param quadrant 移动方向
 @param angle 移动角度(这个角度应该直接就是通过calculate_angleBetweenLines获取angle，然后angle = calculate_pi/2.0 - angle的)
 @return 最终距离
 */
+ (CGPoint)getPointWithStartPoint:(CGPoint )startPoint distance:(CGFloat)distance direction:(GameAngleQuadrant )quadrant angle:(CGFloat)angle{
    CGFloat centerX = distance * sin(angle);
    CGFloat centerY = distance * cos(angle);
    
    if ((quadrant == GameAngleQuadrantFirst)||(quadrant == GameAngleQuadrantFourth)) {
        angle = calculate_pi/2.0 - angle;
    }
    switch (quadrant) {
        case GameAngleQuadrantFirst:{
            centerX = startPoint.x + centerX;
            centerY = startPoint.y + centerY;
        }
            break;
        case GameAngleQuadrantSecond:{
            centerX = startPoint.x - centerX;
            centerY = startPoint.y + centerY;
        }
            break;
        case GameAngleQuadrantThird:{
            centerX = startPoint.x - centerX;
            centerY = startPoint.y - centerY;
        }
            break;
        case GameAngleQuadrantFourth:{
            centerX = startPoint.x + centerX;
            centerY = startPoint.y - centerY;
        }
            break;
            
        default:
            break;
    }
    CGPoint cueCenter = CGPointMake(centerX, centerY);
    return cueCenter;
}

@end
