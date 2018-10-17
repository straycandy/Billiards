//
//  calculateHelper.h
//  myPhysicGame
//
//  Created by mengran on 2018/10/12.
//  Copyright © 2018年 ggV5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define calculate_pi 3.14159265358979323846

/**
 象限

 - GameAngleQuadrantFirst: 第一象限
 - GameAngleQuadrantSecond: 第二象限
 - GameAngleQuadrantThird: 第三象限
 - GameAngleQuadrantFourth: 第四象限
 */
typedef NS_OPTIONS(NSUInteger, GameAngleQuadrant) {
    GameAngleQuadrantFirst  = 1 << 0,
    GameAngleQuadrantSecond = 1 << 1,
    GameAngleQuadrantThird  = 1 << 2,
    GameAngleQuadrantFourth = 1 << 3,
};


/**
 计算2点之间的距离
 */
CGFloat calculate_distanceBetweenPoints (CGPoint first, CGPoint second);
CGFloat calculate_angleBetweenPoints(CGPoint first, CGPoint second);
CGFloat calculate_angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End);

/**
 判断是否是偶数

 @param i 要判断的数
 @return YES:是偶数，NO:是奇数
 */
BOOL calculate_bEvenNumber(NSInteger i);

/**
 判断是否是奇数
 
 @param i 要判断的数
 @return YES:是奇数，NO:是偶数
 */
BOOL calculate_bOddNumber(NSInteger i);

@interface CalculateHelper : NSObject
/**
 已知起始点和终点，得到方向
 
 @param startPoint 起始点
 @param endPoint 终点
 @return 方向
 */
+ (GameAngleQuadrant)getQuadrantWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;

/**
 已知初始点，移动距离，方向，移动角度，得到最终距离
 
 @param startPoint 初始点
 @param distance 移动距离
 @param quadrant 移动方向
 @param angle 移动角度(这个角度应该直接就是通过calculate_angleBetweenLines获取angle，然后angle = calculate_pi/2.0 - angle的)
 @return 最终距离
 */
+ (CGPoint)getPointWithStartPoint:(CGPoint )startPoint distance:(CGFloat)distance direction:(GameAngleQuadrant )quadrant angle:(CGFloat)angle;
@end
