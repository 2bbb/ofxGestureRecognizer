#include "ofxiOS.h"
#include "ofxGestureRecognizer.h"

class ofApp : public ofxiOSApp {
    float rotation{0.0f};
    float zoom{1.0f};
    ofVec2f translation;
    int color_index{0};
    const std::array<ofColor, 6> colors{
        ofColor::red,
        ofColor::green,
        ofColor::blue,
        ofColor::cyan,
        ofColor::magenta,
        ofColor::yellow
    };
public:
    void setup() {
        translation.set(ofGetWidth() * 0.5f, ofGetHeight() * 0.5f);
        ofSetBackgroundColor(0, 0, 0);
        
        ofxAddTapGesture([](ofxGestureInfo info) {
            ofLogNotice("tapped") << info.location;
            for(const auto &t : info.locationsOfTouch) {
                ofLogNotice() << t;
            }
        }, 1, 1);
        
        // don't work correctly now.
        ofxAddLongPressGesture([](ofxGestureInfo info) {
            ofLogNotice("longpressed") << info.location;
        }, 1.5f, 1, 1);
        
        ofxAddPinchAndRotationGesture([=](ofxGestureInfo info) {
            if(info.type == ofxGestureType::Pinch) {
                ofLogNotice("pinched") << info.scale << ", " << info.velocity;
                zoom *= info.scale;
            } else {
                ofLogNotice("rotated") << info.rotation << ", " << info.velocity;
                rotation += info.rotation / M_PI * 180.0f;
            }
        });
        
        ofxAddSwipeGesture([](ofxGestureInfo info) {
            ofLogNotice("swiped") << info.locationsOfTouch.size();
        }, ofxSwipeGestureDirection::Left, 1);
        
        ofxAddPanGesture([=](ofxGestureInfo info) {
            ofLogNotice("panned") << info.translation;
            translation += info.translation;
        });
        
        ofxAddScreenEdgePanGesture([=](ofxGestureInfo info) {
            ofLogNotice("screen edge pan");
            if(info.type == ofxGestureType::ScreenEdgePan) {
                color_index = (color_index + 1) % colors.size();
            }
        }, ofxScreenEdge::Left);
    }
    void update() {}
    void draw() {
        ofSetColor(colors[color_index]);
        ofTranslate(translation);
        ofRotateZ(rotation);
        ofScale(zoom, zoom);
        ofDrawRectangle(-50, -50, 100, 100);
    }
    void exit() {}
    
    void touchDown(ofTouchEventArgs & touch) {}
    void touchMoved(ofTouchEventArgs & touch) {}
    void touchUp(ofTouchEventArgs & touch) {}
    void touchDoubleTap(ofTouchEventArgs & touch) {}
    void touchCancelled(ofTouchEventArgs & touch) {}
    
    void lostFocus() {}
    void gotFocus() {}
    void gotMemoryWarning() {}
    void deviceOrientationChanged(int newOrientation) {}
    
};


int main() {
    //  here are the most commonly used iOS window settings.
    //------------------------------------------------------
    ofiOSWindowSettings settings;
    settings.enableRetina = false; // enables retina resolution if the device supports it.
    settings.enableDepth = false; // enables depth buffer for 3d drawing.
    settings.enableAntiAliasing = false; // enables anti-aliasing which smooths out graphics on the screen.
    settings.numOfAntiAliasingSamples = 0; // number of samples used for anti-aliasing.
    settings.enableHardwareOrientation = false; // enables native view orientation.
    settings.enableHardwareOrientationAnimation = false; // enables native orientation changes to be animated.
    settings.glesVersion = OFXIOS_RENDERER_ES1; // type of renderer to use, ES1, ES2, ES3
    settings.windowMode = OF_FULLSCREEN;
    ofCreateWindow(settings);
    
    return ofRunApp(new ofApp);
}
