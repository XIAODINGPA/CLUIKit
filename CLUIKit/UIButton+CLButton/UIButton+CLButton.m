//
// __    ______  ______      __     ___    _
//   /  __)    /  \    (_    _) |    \  |  |
//  |  /      /    \     |  |   |  |\ \ |  |
//  | |      /  ()  \    |  |   |  | \ \|  |
//  |  \__  |   __   |  _|  |_  |  |  \    |
//  _\    )_|  (__)  |_(      )_|  |___\   |_
//
//  UIButton+CLButton.m
//
//  Created by Cain on 2017/7/12.
//  Copyright © 2017年 Cain Luo. All rights reserved.
//

#import "UIButton+CLButton.h"
#import <objc/runtime.h>

static const void *CLButtonActionKey = &CLButtonActionKey;
static const void *CLButtonSubmitKey = &CLButtonSubmitKey;

static NSString *const kShowActivityIndicatorKey = @"kShowActivityIndicatorKey";
static NSString *const kHideActivityIndicatorKey = @"kHideActivityIndicatorKey";

@interface UIButton ()

@property (nonatomic, assign, readwrite) BOOL cl_isSubmitting;

@end

@implementation UIButton (CLButton)

#pragma mark - 修改点击区域
- (void)setCl_clickAreaEdgeInsets:(UIEdgeInsets)cl_clickAreaEdgeInsets {
    
    NSValue *value = [NSValue valueWithUIEdgeInsets:cl_clickAreaEdgeInsets];
    
    objc_setAssociatedObject(self, @selector(cl_clickAreaEdgeInsets), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)cl_clickAreaEdgeInsets {
    
    NSValue *value = objc_getAssociatedObject(self, @selector(cl_clickAreaEdgeInsets));
    
    if (value) {
        
        UIEdgeInsets edgeInset = [value UIEdgeInsetsValue];
        
        return edgeInset;
    }
    
    return UIEdgeInsetsZero;
}

- (BOOL)pointInside:(CGPoint)point
          withEvent:(UIEvent *)event {
    
    if (UIEdgeInsetsEqualToEdgeInsets(self.cl_clickAreaEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden) {
        
        return [super pointInside:point
                        withEvent:event];
    }
    
    CGRect relativeFrame = self.bounds;
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.cl_clickAreaEdgeInsets);
    
    return CGRectContainsPoint(hitFrame, point);
}

#pragma mark - 是否正在提交
- (void)setCl_isSubmitting:(BOOL)cl_isSubmitting {
    
    objc_setAssociatedObject(self, CLButtonSubmitKey, @(cl_isSubmitting), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)cl_isSubmitting {
    
    return [objc_getAssociatedObject(self, CLButtonSubmitKey) boolValue];
}

#pragma mark - 倒计时方法
- (void)cl_starButtonWithTime:(NSInteger)time
                     complete:(CLButtonStar)complete {

    //倒计时时间
    __block NSInteger timeOut = time;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    //每秒执行一次
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0);
    
    dispatch_source_set_event_handler(_timer, ^{
        
        //倒计时结束，关闭
        if (timeOut <= 0) {
            
            dispatch_source_cancel(_timer);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                complete(self, CLButtonStarStyleFinish, -1);
            });

        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                complete(self, CLButtonStarStyleBegin, timeOut--);
            });
        }
    });
    
    dispatch_resume(_timer);
}

#pragma mark - 添加UIButton点击方法
- (void)cl_addButtonActionComplete:(CLButtonAction)complete {
    
    objc_setAssociatedObject(self, CLButtonActionKey, complete, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self addTarget:self action:@selector(cl_buttonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)cl_buttonAction:(UIButton *)sender {
    
    CLButtonAction cl_buttonAction = objc_getAssociatedObject(self, CLButtonActionKey);
    
    if (cl_buttonAction) {
        
        cl_buttonAction(sender);
    }
}

#pragma mark - 用UIActivityIndicatorView代替文字
- (void)cl_showActivityIndicatorViewWithStyle:(UIActivityIndicatorViewStyle)style {
    
    UIActivityIndicatorView *cl_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    
    cl_activityIndicatorView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    [cl_activityIndicatorView startAnimating];
    
    NSString *cl_buttonTitleString = self.titleLabel.text;
    
    objc_setAssociatedObject(self, &kShowActivityIndicatorKey, cl_activityIndicatorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &kHideActivityIndicatorKey, cl_buttonTitleString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setTitle:@""
          forState:UIControlStateNormal];
    
    self.enabled = NO;
    self.cl_isSubmitting = YES;
    
    [self addSubview:cl_activityIndicatorView];
}

- (void)cl_hideActivityIndicatorView {
    
    NSString *cl_buttonTitleString = (NSString *)objc_getAssociatedObject(self, &kHideActivityIndicatorKey);
    
    UIActivityIndicatorView *cl_activityIndicatorView = (UIActivityIndicatorView *)objc_getAssociatedObject(self, &kShowActivityIndicatorKey);
    
    [cl_activityIndicatorView removeFromSuperview];
    
    [self setTitle:cl_buttonTitleString
          forState:UIControlStateNormal];
    
    self.enabled = YES;
    self.cl_isSubmitting = NO;
}

#pragma mark - 设置UIButton图片
- (void)cl_setNormalButtonWithImage:(UIImage *)image {
    
    [self setImage:image
          forState:UIControlStateNormal];
}

- (void)cl_setHighlightedButtonWithImage:(UIImage *)image {
    
    [self setImage:image
          forState:UIControlStateHighlighted];
}

- (void)cl_setSelectedButtonWithImage:(UIImage *)image {
    
    [self setImage:image
          forState:UIControlStateSelected];
}

- (void)cl_setDisabledButtonWithImage:(UIImage *)image {
    
    [self setImage:image
          forState:UIControlStateDisabled];
}

#pragma mark - 获取UIButton的图片
- (UIImage *)cl_getNormalButtonImage {
    
    return [self imageForState:UIControlStateNormal];
}

- (UIImage *)cl_getHighlightedButtonImage {
    
    return [self imageForState:UIControlStateHighlighted];
}

- (UIImage *)cl_getSelectedButtonImage {
    
    return [self imageForState:UIControlStateSelected];
}

- (UIImage *)cl_getDisabledButtonImage {
    
    return [self imageForState:UIControlStateDisabled];
}

@end
