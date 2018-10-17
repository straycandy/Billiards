//
//  GameScene.m
//  myPhysicGame
//
//  Created by mengran on 2018/9/28.
//  Copyright © 2018年 ggV5. All rights reserved.
//



#import "GameScene.h"
#import "CalculateHelper.h"
#import "UIColor+physicGame.h"

typedef enum : UInt32 {
    GameScene_oherBallCate      = 0x1 << 0,        //其他球
    GameScene_whiteBallCate     = 0x1 << 1,        //白球
    GameScene_tableCate         = 0x1 << 2,        //桌子
    GameScene_bagCate           = 0x1 << 3,        //球袋
    GameScene_cue               = 0x1 << 4,        //球杆
    GameScene_none              = 0x1 << 20,       //其他
} GameSceneCategory;

typedef enum : NSUInteger {
    GameScene_status_idle,      //初始化中
    GameScene_status_runing,    //游戏运行中
    GameScene_status_over,      //游戏结束
} GameSceneStatus;


//桌子圆角半径
static const NSInteger st_tableRadius = 20;
//球直径
static const NSInteger st_ballWidth = 12;
//球z轴
static const NSInteger st_ballZPosition = 20;
//球线性阻尼
static const CGFloat st_ballLinearDamping = 0.5;
//球质量，单位千克
static const CGFloat st_ballMass = 0.02;
//球反弹力
static const CGFloat st_ballRestitution = 0.75;

//球杆宽度
static const NSInteger st_cueWidth = 150;
//击球力度的倍数
static const NSInteger st_bitPower = 8.f;


@interface GameScene()<SKPhysicsContactDelegate>
@property (nonatomic, strong) SKShapeNode       *whiteBallNode;     //白球
@property (nonatomic, strong) SKShapeNode       *tableNode;         //桌子（初始化时自带6个袋子）
@property (nonatomic, strong) SKShapeNode       *cueNode;           //球杆
@property (nonatomic, assign) CGFloat           currentAngle;       //当前球杆和水平方向夹角
@property (nonatomic, assign) CGFloat           initialSpace;       //初始触摸点和白球之间的距离，用于计算球杆中心点
@property (nonatomic, assign) CGFloat           playForceDistance;  //用于计算击球力度的距离
@property (nonatomic, strong) SKLabelNode       *restartNode;        //重新开始按钮

/**
 游戏状态
 */
@property (nonatomic, assign) GameSceneStatus       currentGameStatus;
@end

@implementation GameScene {
    SKShapeNode *_spinnyNode;
}

- (void)didMoveToView:(SKView *)view {
    // Setup your scene here
    self.tableNode.hidden = NO;
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    self.physicsWorld.contactDelegate = self;
    CGPathRef path = CGPathCreateWithRoundedRect(self.tableNode.frame, Get375Width(st_tableRadius), Get375Width(st_tableRadius), nil);
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromPath:path];
    self.physicsBody.friction = 0.5;
    [self addChild:self.restartNode];
    [self gameShuffle];
}
#pragma mark -
#pragma mark --------gameStaus--------
/**
 游戏初始化
 */
- (void)gameShuffle{
    self.currentGameStatus = GameScene_status_idle;
    [self initBalls];
    self.restartNode.hidden = YES;
}

/**
 游戏开始
 */
- (void)gameStart{
    self.currentGameStatus = GameScene_status_runing;
}

/**
 游戏结束
 */
- (void)gameOver{
    self.currentGameStatus = GameScene_status_over;
    for (SKNode *childNode in self.children) {
        if (childNode.physicsBody.categoryBitMask == GameScene_oherBallCate) {
            [childNode removeFromParent];
        }else if (childNode.physicsBody.categoryBitMask == GameScene_whiteBallCate){
            childNode.hidden = YES;
        }
    }
    self.restartNode.hidden = NO;
}
#pragma mark -
#pragma mark --------touch--------
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    CGPoint touchPoint = [touch locationInNode:self];
    CGFloat distance = calculate_distanceBetweenPoints(touchPoint, self.whiteBallNode.position);
    SKNode * touchNode = (SKNode *)[self nodeAtPoint:[touch locationInNode:self]];
    if (touches.count == 1 && touchNode == self.restartNode) {
        self.restartNode.hidden = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self gameShuffle];
        });
    }
    if (self.currentGameStatus == GameScene_status_over) {
        return;
    }
    //开始触摸，创建球杆,
    if (touches.count == 1 && distance < Get375Width(60)) {
        
        CGPoint cueCenter = [self getCueCenterWithTouchPoint:touchPoint];
        self.cueNode.hidden = NO;
        self.cueNode.position = cueCenter;
        CGFloat angle = [self getAngleWithTouchPoint:touchPoint];
        self.currentAngle = angle;
        SKAction *rotateAction = [SKAction rotateByAngle:(calculate_pi/2.0 - angle) duration:0];
        [self.cueNode runAction:rotateAction];
        
        //设置初始触摸点和白球之间的位置，用于移动球杆
        CGFloat space = calculate_distanceBetweenPoints(touchPoint, self.whiteBallNode.position);
        self.initialSpace = space;
    }
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (self.currentGameStatus == GameScene_status_over) {
        return;
    }
    if (touches.count == 1 && !self.cueNode.hidden) {
        UITouch *touch = touches.anyObject;
        CGPoint touchPoint = [touch locationInNode:self];
        CGPoint cueCenter = [self getCueCenterWithTouchPoint:touchPoint];
        //设置球杆移动范围
        CGFloat space = calculate_distanceBetweenPoints(touchPoint, self.whiteBallNode.position);
        CGFloat changedSpace = space - self.initialSpace;
        changedSpace = MAX(changedSpace, - st_ballWidth/2.0);//设置最小值
        changedSpace = MIN(changedSpace, Get375Width(st_cueWidth/2.0));
        CGFloat distanceAngle = calculate_angleBetweenLines(self.whiteBallNode.position, touchPoint, self.whiteBallNode.position, CGPointMake(touchPoint.x, self.whiteBallNode.position.y));
        distanceAngle = calculate_pi/2.0 - distanceAngle;
        CGPoint finalCueNode = [CalculateHelper getPointWithStartPoint:cueCenter distance:changedSpace direction:[CalculateHelper getQuadrantWithStartPoint:self.whiteBallNode.position endPoint:touchPoint] angle:distanceAngle];
        self.cueNode.position = finalCueNode;
        CGFloat angle = [self getAngleWithTouchPoint:touchPoint];
        //这里的角度需要是改变的角度，和touchesBegan的不一样
        CGFloat animateAngle = -(angle - self.currentAngle);
        self.currentAngle = angle;
        SKAction *rotateAction = [SKAction rotateByAngle:animateAngle duration:0];
        [self.cueNode runAction:rotateAction];
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.currentGameStatus == GameScene_status_over) {
        return;
    }
    if (touches.count == 1 && !self.cueNode.hidden) {
        //击球，球杆得做一个击打动画
        CGFloat tempDistance = Get375Width(st_cueWidth/2.0) + Get375Width(st_ballWidth/2.0);
        CGFloat distanceAngle = calculate_angleBetweenLines(self.whiteBallNode.position, self.cueNode.position, self.whiteBallNode.position, CGPointMake(self.cueNode.position.x, self.whiteBallNode.position.y));
        distanceAngle = calculate_pi/2.0 - distanceAngle;
        //finalCueNode就是球杆最终的中心点位置
        CGPoint finalCueNode = [CalculateHelper getPointWithStartPoint:self.whiteBallNode.position distance:tempDistance direction:[CalculateHelper getQuadrantWithStartPoint:self.whiteBallNode.position endPoint:self.cueNode.position] angle:distanceAngle];
        //记录下释放的时候，球杆中心移动的位置的距离，方便计算出击打力度
        self.playForceDistance = calculate_distanceBetweenPoints(finalCueNode, self.cueNode.position);
        
        SKAction *playAction = [SKAction moveTo:finalCueNode duration:0.08];
        __weak typeof(self)weakSelf = self;
        [self.cueNode runAction:playAction completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf playBilliards];
                weakSelf.cueNode.hidden = YES;
                [weakSelf.cueNode removeFromParent];
                weakSelf.cueNode = nil;
            });
        }];
    }
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

#pragma mark -
#pragma mark --------update--------
-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
    
}
#pragma mark -
#pragma mark --------physicsWorldDelegate--------
- (void)didBeginContact:(SKPhysicsContact *)contact{
    if (contact.bodyA.categoryBitMask == GameScene_bagCate) {
        contact.bodyB.node.hidden = YES;
    }else if (contact.bodyB.categoryBitMask == GameScene_bagCate){
        contact.bodyA.node.hidden = YES;
    }
    [self adjustGameStatus];
}
#pragma mark -
#pragma mark --------custom--------
- (void)adjustGameStatus{
    if (self.whiteBallNode.hidden) {
        [self gameOver];
    }
}
/**
 击球
 */
- (void)playBilliards{
    CGFloat distanceAngle = calculate_angleBetweenLines(self.whiteBallNode.position, self.cueNode.position, self.whiteBallNode.position, CGPointMake(self.cueNode.position.x, self.whiteBallNode.position.y));
    distanceAngle = calculate_pi/2.0 - distanceAngle;
    CGPoint playVectorPoint = [CalculateHelper getPointWithStartPoint:CGPointMake(0, 0) distance:self.playForceDistance direction:[CalculateHelper getQuadrantWithStartPoint:self.cueNode.position endPoint:self.whiteBallNode.position] angle:distanceAngle];
    CGFloat multiple = st_bitPower;
    CGVector playVector = CGVectorMake(playVectorPoint.x * multiple, playVectorPoint.y * multiple);
    [self.whiteBallNode.physicsBody applyForce:playVector];
}
/**
 获取触摸点和白球中心点|水平线之间的夹角

 @param touchPosition 触点
 @return 夹角
 */
- (CGFloat )getAngleWithTouchPoint:(CGPoint )touchPosition{
    CGPoint whiteBallPosition = self.whiteBallNode.position;    //白球中心
    CGPoint otherBorderPoint = CGPointMake(touchPosition.x, whiteBallPosition.y);   //另一条边的某个点
    CGFloat angle = calculate_angleBetweenLines(whiteBallPosition, touchPosition, whiteBallPosition, otherBorderPoint);

    //得到最终象限
    GameAngleQuadrant quandrant = [CalculateHelper getQuadrantWithStartPoint:whiteBallPosition endPoint:touchPosition];
    //目前获得的angle是不带正负的，而且只有0~90°，得修改成-180°~180°的
    switch (quandrant) {
        case GameAngleQuadrantFirst:{
            angle = calculate_pi/2.0 - angle;
        }
            break;
        case GameAngleQuadrantSecond:{
            angle = angle + calculate_pi/2.0;
        }
            break;
        case GameAngleQuadrantThird:{
            angle = -(angle + calculate_pi/2.0);
        }
            break;
        case GameAngleQuadrantFourth:{
            angle = angle - calculate_pi/2.0;
        }
            break;
            
        default:
            break;
    }
    return angle;
}
/**
 根据触点获得球杆中心

 @param touchPosition 触点
 @return 球杆中心点
 */
- (CGPoint )getCueCenterWithTouchPoint:(CGPoint )touchPosition{
    CGPoint whiteBallPosition = self.whiteBallNode.position;    //白球中心
    CGPoint otherBorderPoint = CGPointMake(touchPosition.x, whiteBallPosition.y);   //另一条边的某个点
    CGFloat cueCircleRadius = Get375Width(st_cueWidth/2.0) + Get375Width(st_ballWidth);   //球杆所在中心和白球中心直径的距离，是个圆的半径
    CGFloat angle = calculate_angleBetweenLines(whiteBallPosition, touchPosition, whiteBallPosition, otherBorderPoint);
    angle = calculate_pi/2.0 - angle;
    
    CGPoint cueCenter = [CalculateHelper getPointWithStartPoint:whiteBallPosition distance:cueCircleRadius direction:[CalculateHelper getQuadrantWithStartPoint:whiteBallPosition endPoint:touchPosition] angle:angle];
    
    return cueCenter;
}

/**
 初始化球
 */
- (void)initBalls {
    self.whiteBallNode.position = CGPointMake(kScreenWidth/2.0, kScreenHeight/2.0 - Get375Width(60));
    self.whiteBallNode.hidden = NO;
    self.whiteBallNode.physicsBody.velocity = CGVectorMake(0, 0);
    
    NSMutableArray *positionArray = [[NSMutableArray alloc]init];
    NSInteger totalNum = 5;
    for (NSInteger j = 1; j < totalNum + 1; j++) {
        for (NSInteger i = 0; i < j; i++) {
            CGFloat tempSpace = Get375Width(20);
            CGFloat startX = (totalNum - j) * tempSpace/2.0;
            CGPoint position = CGPointMake(startX + kScreenWidth / 2.0 - tempSpace*2 + tempSpace*i, kScreenHeight/2.0 + Get375Width(17.5) * j);
            [positionArray addObject:[NSValue valueWithCGPoint:position]];
        }
    }
    
    for (NSValue *pointValue in positionArray) {
        CGPoint position = [pointValue CGPointValue];
        CGFloat tempBallWidht = Get375Width(st_ballWidth);
        SKShapeNode *ballNode = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(tempBallWidht, tempBallWidht) cornerRadius:tempBallWidht/2.0];
        ballNode.fillColor = [UIColor blueColor];
        ballNode.strokeColor = [UIColor blueColor];
        ballNode.position = position;
        ballNode.zPosition = st_ballZPosition;
        ballNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:tempBallWidht/2.0 center:CGPointMake(0, 0)];
        ballNode.physicsBody.dynamic = YES;
        ballNode.physicsBody.mass = st_ballMass;
        ballNode.physicsBody.restitution = st_ballRestitution;
        ballNode.physicsBody.categoryBitMask = GameScene_oherBallCate;
        ballNode.physicsBody.collisionBitMask = GameScene_whiteBallCate|GameScene_oherBallCate;
        ballNode.physicsBody.linearDamping = st_ballLinearDamping;
        [self addChild:ballNode];
    }
}

#pragma mark -
#pragma mark --------property--------
-(SKShapeNode *)whiteBallNode{
    if (!_whiteBallNode) {
        _whiteBallNode = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(Get375Width(st_ballWidth), Get375Width(st_ballWidth)) cornerRadius:Get375Width(st_ballWidth/2.0)];
        _whiteBallNode.lineWidth = 1.5;
        _whiteBallNode.fillColor = [UIColor whiteColor];
        
        _whiteBallNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:Get375Width(st_ballWidth)/2.0 center:CGPointMake(0, 0)];
        _whiteBallNode.physicsBody.dynamic = YES;
        _whiteBallNode.physicsBody.linearDamping = st_ballLinearDamping;
        _whiteBallNode.physicsBody.mass = st_ballMass;
        _whiteBallNode.physicsBody.restitution = st_ballRestitution;
        _whiteBallNode.physicsBody.categoryBitMask = GameScene_whiteBallCate;
        _whiteBallNode.physicsBody.collisionBitMask = GameScene_whiteBallCate|GameScene_oherBallCate;
        _whiteBallNode.physicsBody.contactTestBitMask = GameScene_cue;
        [self addChild:_whiteBallNode];
    }
    return _whiteBallNode;
}

-(SKShapeNode *)tableNode{
    if (!_tableNode) {
        CGFloat scale = 0.75;
        CGFloat tableWidth = kScreenWidth * scale;
        CGFloat tableHeight = kScreenHeight * scale;
        _tableNode = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(tableWidth, tableHeight) cornerRadius:Get375Width(st_tableRadius)];
        _tableNode.lineWidth = 3;
        _tableNode.strokeColor = [UIColor colorWithRed:153/255.0 green:255/255.0 blue:204/255.0 alpha:1];
        _tableNode.fillColor = [UIColor colorWithRed:153/255.0 green:255/255.0 blue:204/255.0 alpha:1];
        _tableNode.position = CGPointMake(kScreenWidth/2.0, kScreenHeight/2.0);
        CGFloat bagWidth = Get375Width(18);
        for (NSInteger i = 0; i < 6; i++) {
            SKShapeNode *bagNode = [SKShapeNode shapeNodeWithRectOfSize:CGSizeMake(bagWidth, bagWidth) cornerRadius:bagWidth/2.0];
            bagNode.fillColor = [UIColor redColor];
            bagNode.strokeColor = [UIColor redColor];
            bagNode.lineWidth = 1.0;
            NSInteger temp1 = i % 2;
            NSInteger temp2 = i / 2;
            CGFloat X = (temp1 == 0)?(kScreenWidth/2.0 - (tableWidth/2.0 - Get375Width(20))):(kScreenWidth/2.0 + (tableWidth/2.0 - Get375Width(20)));
            CGFloat Y = (kScreenHeight/2.0 - (tableHeight/2.0 - Get375Width(20))) + temp2*(tableHeight/2.0 - Get375Width(20));
            bagNode.position = CGPointMake(X, Y);
            bagNode.zPosition = st_ballZPosition;
            bagNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:bagWidth/2.0 center:CGPointMake(0, 0)];
            bagNode.physicsBody.contactTestBitMask = GameScene_whiteBallCate|GameScene_oherBallCate;;
            bagNode.physicsBody.collisionBitMask = GameScene_none;
            bagNode.physicsBody.categoryBitMask = GameScene_bagCate;
            [self addChild:bagNode];
        }
        [self addChild:_tableNode];
    }
    return _tableNode;
}

-(SKShapeNode *)cueNode{
    if (!_cueNode) {
        CGSize size = CGSizeMake(Get375Width(st_cueWidth), Get375Width(st_ballWidth * 0.8));
        _cueNode = [SKShapeNode shapeNodeWithRectOfSize:size cornerRadius:0];
        _cueNode.lineWidth = 1.5;
        _cueNode.fillColor = [UIColor colorWithRed:153/255.0 green:102/255.0 blue:0/255.0 alpha:1];
        _cueNode.hidden = YES;
        [self addChild:_cueNode];
    }
    return _cueNode;
}

-(SKLabelNode *)restartNode{
    if (!_restartNode) {
        _restartNode = [SKLabelNode labelNodeWithText:@"重新开始"];
        _restartNode.color = [UIColor whiteColor];
        [_restartNode setFontName:@"Helvetica-Bold"];
        [_restartNode setFontSize:Get375Width(30)];
        _restartNode.fontColor = [UIColor colorWithHexString:@"#ec0000"];
        _restartNode.hidden = YES;
        _restartNode.position = CGPointMake(kScreenWidth/2.0, kScreenHeight/2.0);;
    }
    return _restartNode;
}
@end
