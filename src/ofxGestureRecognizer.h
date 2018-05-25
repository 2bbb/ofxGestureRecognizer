//
//  ofxGestureRecognizer.h
//
//  Created by ISHII 2bit on 2018/05/25.
//

#ifndef ofxGestureRecognizer_h
#define ofxGestureRecognizer_h

#include <string>
#include <functional>
#include <memory>
#include <limits>

#include "ofVec2f.h"

namespace ofx {
    struct GestureRecognizer;
    
    struct GestureID {
        std::shared_ptr<GestureRecognizer> key;
        std::shared_ptr<GestureRecognizer> key_adv;
    };
    
    enum class GestureType {
        Tap,
        LongPress,
        LongPressContinued,
        Pinch,
        Rotation,
        Swipe,
        Pan,
        ScreenEdgePan,
        ScreenEdgePanContinued,
    };
    struct GestureInfo {
        GestureType type;
        
        std::vector<ofVec2f> locationsOfTouch;
        ofVec2f location;
        
        float velocity; // for pinch, rotation
        float scale; // for pinch
        float rotation; // for rotation
        
        ofVec2f translation; // for pan, screen edge pan
        ofVec2f velocity2d; // for pan, screen edge pan
    };
    
    enum class SwipeGestureDirection {
        Right = 1 << 0,
        Left = 1 << 1,
        Up = 1 << 2,
        Down = 1 << 3
    };
    
    enum class ScreenEdge {
        None = 0,
        Top = 1 << 0,
        Left = 1 << 1,
        Bottom = 1 << 2,
        Right = 1 << 3,
        All = Top | Left | Bottom | Right
    };
}

using ofxGestureID = ofx::GestureID;
using ofxGestureType = ofx::GestureType;
using ofxGestureInfo = ofx::GestureInfo;
using ofxSwipeGestureDirection = ofx::SwipeGestureDirection;
using ofxScreenEdge = ofx::ScreenEdge;

ofxGestureID ofxAddTapGesture(std::function<void(ofxGestureInfo)> callback,
                              std::size_t numberOfTaps = 1,
                              std::size_t numberOfTouches = 1);
ofxGestureID ofxAddLongPressGesture(std::function<void(ofxGestureInfo)> callback,
                                    float minimumPressDuration = 0.5f,
                                    std::size_t numberOfTaps = 1,
                                    std::size_t numberOfTouches = 1,
                                    float allowableMovement = 10.0f);
ofxGestureID ofxAddPinchGesture(std::function<void(ofxGestureInfo)> callback);
ofxGestureID ofxAddRotationGesture(std::function<void(ofxGestureInfo)> callback);
ofxGestureID ofxAddPinchAndRotationGesture(std::function<void(ofxGestureInfo)> callback);
ofxGestureID ofxAddSwipeGesture(std::function<void(ofxGestureInfo)> callback,
                                ofxSwipeGestureDirection direction,
                                std::size_t numberOfTouches = 1);
ofxGestureID ofxAddPanGesture(std::function<void(ofxGestureInfo)> callback,
                              bool useDiff = true,
                              std::size_t minimumNumberOfTouches = 1,
                              std::size_t maximumNumberOfTouches = std::numeric_limits<std::size_t>::max());
ofxGestureID ofxAddScreenEdgePanGesture(std::function<void(ofxGestureInfo)> callback,
                                        ofxScreenEdge edges,
                                        std::size_t minimumNumberOfTouches = 1,
                                        std::size_t maximumNumberOfTouches = std::numeric_limits<std::size_t>::max());

void ofxRemoveGestureRecognizer(ofxGestureID);

#endif /* ofxGestureRecognizer_h */
