//
//  ofxGestureRecognizer.mm
//
//  Created by ISHII 2bit on 2018/05/25.
//

#import <UIKit/UIKit.h>

#include "ofxGestureRecognizer.h"
#include "ofxiOS.h"

#include <map>

namespace {
    ofxGestureInfo to_cpp(UIGestureRecognizer *gesture) {
        ofxGestureInfo info;
        CGPoint location = [gesture locationInView:gesture.view];
        info.location.x = location.x;
        info.location.y = location.y;
        
        for(NSInteger i = 0; i < gesture.numberOfTouches; i++) {
            CGPoint p = [gesture locationOfTouch:i inView:gesture.view];
            info.locationsOfTouch.emplace_back(p.x, p.y);
        }
        return info;
    }
};

@interface BBBGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate> {
    std::function<void(ofxGestureInfo)> callback;
}

- (void)setCallback:(std::function<void(ofxGestureInfo)>)callback;

@end

@implementation BBBGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)setCallback:(std::function<void(ofxGestureInfo)>)callback_ {
    callback = callback_;
}

- (void)tapped:(UITapGestureRecognizer *)gesture {
    if(gesture.state != UIGestureRecognizerStateEnded) return;
    auto info = to_cpp(gesture);
    info.type = ofxGestureType::Tap;
    callback(info);
}

- (void)longpressed:(UITapGestureRecognizer *)gesture {
    auto info = to_cpp(gesture);
    if(gesture.state == UIGestureRecognizerStateBegan) {
        info.type = ofxGestureType::LongPress;
    } else {
        info.type = ofxGestureType::LongPressContinued;
    }
    callback(info);
}

- (void)pinched:(UIPinchGestureRecognizer *)gesture {
    ofxGestureInfo info = to_cpp(gesture);
    info.scale = gesture.scale;
    info.velocity = gesture.velocity;
    info.type = ofxGestureType::Pinch;
    gesture.scale = 1.0f;
    
    callback(info);
}

- (void)rotated:(UIRotationGestureRecognizer *)gesture {
    ofxGestureInfo info = to_cpp(gesture);
    info.rotation = gesture.rotation;
    info.velocity = gesture.velocity;
    info.type = ofxGestureType::Rotation;
    gesture.rotation = 0.0f;
    
    callback(info);
}

- (void)swiped:(UISwipeGestureRecognizer *)gesture {
    ofxGestureInfo info = to_cpp(gesture);
    info.type = ofxGestureType::Swipe;
    
    callback(info);
}

- (void)diff_panned:(UIPanGestureRecognizer *)gesture {
    ofxGestureInfo info = to_cpp(gesture);
    info.type = ofxGestureType::Pan;
    
    CGPoint translation = [gesture translationInView:gesture.view];
    info.translation.set(translation.x, translation.y);
    
    CGPoint velocity = [gesture velocityInView:gesture.view];
    info.velocity2d.set(velocity.x, velocity.y);
    
    [gesture setTranslation:CGPointZero inView:gesture.view];
    
    callback(info);
}

- (void)panned:(UIPanGestureRecognizer *)gesture {
    ofxGestureInfo info = to_cpp(gesture);
    info.type = ofxGestureType::Pan;
    
    CGPoint translation = [gesture translationInView:gesture.view];
    info.translation.set(translation.x, translation.y);
    
    CGPoint velocity = [gesture velocityInView:gesture.view];
    info.velocity2d.set(velocity.x, velocity.y);
    
    callback(info);
}

- (void)edge_panned:(UIPanGestureRecognizer *)gesture {
    ofxGestureInfo info = to_cpp(gesture);
    if(gesture.state == UIGestureRecognizerStateBegan) {
        info.type = ofxGestureType::ScreenEdgePan;
    } else {
        info.type = ofxGestureType::ScreenEdgePanContinued;
    }
    
    CGPoint translation = [gesture translationInView:gesture.view];
    info.translation.set(translation.x, translation.y);
    
    CGPoint velocity = [gesture velocityInView:gesture.view];
    info.velocity2d.set(velocity.x, velocity.y);
    
    callback(info);
}

@end

namespace ofx {
    struct GestureRecognizer {
        using Ref = std::shared_ptr<GestureRecognizer>;
        
        GestureRecognizer(std::function<void(ofxGestureInfo)> callback) {
            delegate = BBBGestureRecognizerDelegate.alloc.init;
            [delegate setCallback:callback];
        }
        UIGestureRecognizer *impl;
        BBBGestureRecognizerDelegate *delegate;
        virtual ~GestureRecognizer() { impl = nil; delegate = nil; };
    };
    
    struct TapGestureRecognizer : GestureRecognizer {
        TapGestureRecognizer(std::function<void(ofxGestureInfo)> callback,
                             std::size_t numberOfTaps,
                             std::size_t numberOfTouches)
        : GestureRecognizer(callback)
        {
            UITapGestureRecognizer *rec = [[UITapGestureRecognizer alloc] initWithTarget:delegate action:@selector(tapped:)];
            rec.numberOfTapsRequired = numberOfTaps;
            rec.numberOfTouchesRequired = numberOfTouches;
            impl = rec;
            impl.delegate = delegate;
        }
    };
    
    struct LongPressGestureRecognizer : GestureRecognizer {
        LongPressGestureRecognizer(std::function<void(ofxGestureInfo)> callback,
                                   float minimumPressDuration,
                                   std::size_t numberOfTaps,
                                   std::size_t numberOfTouches,
                                   float allowableMovement)
        : GestureRecognizer(callback)
        {
            UILongPressGestureRecognizer *rec = [[UILongPressGestureRecognizer alloc] initWithTarget:delegate action:@selector(longpressed:)];
            rec.minimumPressDuration = minimumPressDuration;
            // on long pressed, numberOfTaps == 0 then require 1 tap, == 1 then require 2 taps...
            rec.numberOfTapsRequired = (numberOfTaps == 0) ? 0 : (numberOfTaps - 1);
            rec.numberOfTouchesRequired = numberOfTouches;
            rec.allowableMovement = allowableMovement;
            impl = rec;
            impl.delegate = delegate;
        }
    };
    
    struct PinchGestureRecognizer : GestureRecognizer {
        PinchGestureRecognizer(std::function<void(ofxGestureInfo)> callback)
        : GestureRecognizer(callback)
        {
            impl = [[UIPinchGestureRecognizer alloc] initWithTarget:delegate action:@selector(pinched:)];
            impl.delegate = delegate;
        }
    };
    
    struct RotationGestureRecognizer : GestureRecognizer {
        RotationGestureRecognizer(std::function<void(ofxGestureInfo)> callback)
        : GestureRecognizer(callback)
        {
            impl = [[UIRotationGestureRecognizer alloc] initWithTarget:delegate action:@selector(rotated:)];
            impl.delegate = delegate;
        }
    };
    
    struct SwipeGestureRecognizer : GestureRecognizer {
        SwipeGestureRecognizer(std::function<void(ofxGestureInfo)> callback,
                               ofxSwipeGestureDirection direction,
                               std::size_t numberOfTouches = 1)
        : GestureRecognizer(callback)
        {
            UISwipeGestureRecognizer *rec = [[UISwipeGestureRecognizer alloc] initWithTarget:delegate action:@selector(swiped:)];
            rec.direction = (UISwipeGestureRecognizerDirection)direction;
            rec.numberOfTouchesRequired = numberOfTouches;
            impl = rec;
            impl.delegate = delegate;
        }
    };
    
    struct PanGestureRecognizer : GestureRecognizer {
        PanGestureRecognizer(std::function<void(ofxGestureInfo)> callback,
                             bool useDiff,
                             std::size_t minimumNumberOfTouches,
                             std::size_t maximumNumberOfTouches)
        : GestureRecognizer(callback)
        {
            UIPanGestureRecognizer *rec = [[UIPanGestureRecognizer alloc] initWithTarget:delegate action:useDiff ? @selector(diff_panned:) : @selector(panned:)];
            rec.minimumNumberOfTouches = minimumNumberOfTouches;
            rec.maximumNumberOfTouches = maximumNumberOfTouches;
            impl = rec;
            impl.delegate = delegate;
        }
    };
    
    struct ScreenEdgePanGestureRecognizer : GestureRecognizer {
        ScreenEdgePanGestureRecognizer(std::function<void(ofxGestureInfo)> callback,
                                       ofxScreenEdge edges,
                                       std::size_t minimumNumberOfTouches = 1,
                                       std::size_t maximumNumberOfTouches = std::numeric_limits<std::size_t>::max())
        : GestureRecognizer(callback)
        {
            UIScreenEdgePanGestureRecognizer *rec = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:delegate action:@selector(edge_panned:)];
            rec.edges = (UIRectEdge)edges;
            rec.minimumNumberOfTouches = minimumNumberOfTouches;
            rec.maximumNumberOfTouches = maximumNumberOfTouches;
            impl = rec;
            impl.delegate = delegate;
        }
    };
};

using ofxGestureRecognizer = ofx::GestureRecognizer;

ofxGestureID ofxAddGestureRecognizer(ofx::GestureRecognizer::Ref recognizer) {
    ofxiOSViewController *controller = ofxiOSGetViewController();
    if(controller.view == nil) {
        controller.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ofGetWidth(), ofGetHeight())];
    }
    [controller.view addGestureRecognizer:recognizer->impl];
    ofxGestureID id;
    id.key = recognizer;
    return id;
}

ofxGestureID ofxAddGestureRecognizer(ofx::GestureRecognizer::Ref recognizer, ofx::GestureRecognizer::Ref recognizer_adv) {
    ofxiOSViewController *controller = ofxiOSGetViewController();
    if(controller.view == nil) {
        controller.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ofGetWidth(), ofGetHeight())];
    }
    [controller.view addGestureRecognizer:recognizer->impl];
    [controller.view addGestureRecognizer:recognizer_adv->impl];
    ofxGestureID id;
    id.key = recognizer;
    id.key_adv = recognizer_adv;
    return id;
}

ofxGestureID ofxAddTapGesture(std::function<void(ofxGestureInfo)> callback,
                              std::size_t numberOfTaps,
                              std::size_t numberOfTouches)
{
    return ofxAddGestureRecognizer(std::make_shared<ofx::TapGestureRecognizer>(callback, numberOfTaps, numberOfTouches));
}

ofxGestureID ofxAddLongPressGesture(std::function<void(ofxGestureInfo)> callback,
                                    float minimumPressDuration,
                                    std::size_t numberOfTaps,
                                    std::size_t numberOfTouches,
                                    float allowableMovement)
{
    return ofxAddGestureRecognizer(std::make_shared<ofx::LongPressGestureRecognizer>(callback, minimumPressDuration, numberOfTaps, numberOfTouches, allowableMovement));
}

ofxGestureID ofxAddPinchGesture(std::function<void(ofxGestureInfo)> callback) {
    return ofxAddGestureRecognizer(std::make_shared<ofx::PinchGestureRecognizer>(callback));
}

ofxGestureID ofxAddRotationGesture(std::function<void(ofxGestureInfo)> callback) {
    return ofxAddGestureRecognizer(std::make_shared<ofx::RotationGestureRecognizer>(callback));
}

ofxGestureID ofxAddPinchAndRotationGesture(std::function<void(ofxGestureInfo)> callback)
{
    return ofxAddGestureRecognizer(std::make_shared<ofx::PinchGestureRecognizer>(callback),
                                   std::make_shared<ofx::RotationGestureRecognizer>(callback));
}

ofxGestureID ofxAddSwipeGesture(std::function<void(ofxGestureInfo)> callback,
                                ofxSwipeGestureDirection direction,
                                std::size_t numberOfTouches)
{
    return ofxAddGestureRecognizer(std::make_shared<ofx::SwipeGestureRecognizer>(callback, direction, numberOfTouches));
}

ofxGestureID ofxAddPanGesture(std::function<void(ofxGestureInfo)> callback,
                              bool useDiff,
                              std::size_t minimumNumberOfTouches,
                              std::size_t maximumNumberOfTouches)
{
    return ofxAddGestureRecognizer(std::make_shared<ofx::PanGestureRecognizer>(callback, useDiff, minimumNumberOfTouches, maximumNumberOfTouches));
}

ofxGestureID ofxAddScreenEdgePanGesture(std::function<void(ofxGestureInfo)> callback,
                                        ofxScreenEdge edges,
                                        std::size_t minimumNumberOfTouches,
                                        std::size_t maximumNumberOfTouches)
{
    return ofxAddGestureRecognizer(std::make_shared<ofx::ScreenEdgePanGestureRecognizer>(callback, edges, minimumNumberOfTouches, maximumNumberOfTouches));
}
