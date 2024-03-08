%module Shore
%include "typemaps.i"
//%include "carrays.i"
%include "arrays_java.i"
%include "various.i"

/* do not confuse Object with java.lang.Object */
%rename(ShoreObject) Object;
/* consistency with ShoreObject... */
%rename(ShoreMarker) Marker;
%rename(ShoreRegion) Region;
%rename(ShoreContent) Content;
%rename(ShoreEngine) Engine;

/* use typemap from various.i for the input parameter for the Process() call */
%apply unsigned char *NIOBUFFER {unsigned char const* leftTop};
/* you can swap these two lines if you prefer to pass a Java byte[] array
to the Process() call */
//%apply char *BYTE {unsigned char const* leftTop};

namespace Shore {

/* modify the return value in the generated ShoreJNI.java and Shore.java files */
%typemap(jtype) float const* GetRatingOf "java.lang.Float"
%typemap(jstype) float const* GetRatingOf "java.lang.Float"
%typemap(jtype) float const* GetRating "java.lang.Float"
%typemap(jstype) float const* GetRating "java.lang.Float"

/* modify the return type in the generated ShoreObject.java file */
%typemap(javaout) float const * GetRatingOf {
    return $jnicall;
}
%typemap(javaout) float const * GetRating {
    return $jnicall;
}

/* Change the wrapper code in Shore_wrap.cxx in order to return
 a java.lang.Float object instead of a plain float/pointer to a float */
%typemap(out) float const* GetRatingOf %{
    if($1 != 0) {
        jclass fClass = jenv->FindClass("java/lang/Float");
        jmethodID fCtor = jenv->GetMethodID(fClass, "<init>", "(F)V");
        *(jobject*)&$result = jenv->NewObject(fClass, fCtor, *$1);
        jenv->DeleteLocalRef(fClass);
    }
%}

%typemap(out) float const* GetRating %{
    if($1 != 0) {
        jclass fClass = jenv->FindClass("java/lang/Float");
        jmethodID fCtor = jenv->GetMethodID(fClass, "<init>", "(F)V");
        *(jobject*)&$result = jenv->NewObject(fClass, fCtor, *$1);
        jenv->DeleteLocalRef(fClass);
    }
%}

%typemap(out) Engine* CreateEngine %{
    if($1) {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_engines.push_back($1);
        *(Shore::Engine **)&jresult = $1;
        #ifdef SHORE_WRAPPER_DEBUG
        std::cout << "Created engine " << $1 << std::endl;
        #endif
    }
%}

%typemap(out) Engine* CreateFaceEngine %{
    if($1) {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_engines.push_back($1);
        *(Shore::Engine **)&jresult = $1;
        #ifdef SHORE_WRAPPER_DEBUG
        std::cout << "Created engine " << $1 << std::endl;
        #endif
    }
%}

/* This is somehow a limitation(?) in swig - we cannot provide the DeleteEngine method
name to specify where the following code should be inserted. There is, however, only one
match (DeleteEngine) and this is what we want */
%typemap(in) Engine* engine %{
    $1 = *(Shore::Engine **)&$input;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        for (auto it=g_engines.begin(); it!=g_engines.end(); ) {
            #ifdef SHORE_WRAPPER_DEBUG
            std::cout << "Deleting engine" <<  *it << std::endl;
            #endif
            it = (*it == $1) ? g_engines.erase(it) : std::next(it);
        }
    }

%}

}

/* Insert code that is executed when the Java library is loaded */
%pragma(java) jniclasscode=%{
  static {
    try {
       System.loadLibrary("ShoreWrapper");
    } catch (UnsatisfiedLinkError e) {
      System.err.println("Native code library failed to load. \n" + e);
      System.exit(1);
    }
  }
%}

/* This code is copied verbatim int Shore_wrap.cxx */
%{
#include <iostream>
#include <mutex>
#include <vector>
#include <unistd.h>
#include "Shore.h"
static jobject g_obj = nullptr;
static JavaVM *g_jvm = nullptr;
static std::mutex g_mutex;
static std::vector<Shore::Engine*> g_engines;

extern char _sldata[] asm("_binary_ShapeLocator_68_2018_01_17_094200_ctm_start");

bool ShapeloactorRegisters =
    Shore::RegisterModel( "ShapeLocator_68_2018_01_17_094200", _sldata );


/* Taken from the original Java Wrapper - sets the supported
 JNI version and returns a JNIEnv for this version*/
JNIEnv* JNU_GetEnv(JavaVM* jvm, jint* jni_version) {
    *jni_version = JNI_VERSION_1_6;
    JNIEnv* env = NULL;
    //JNIEnv* env = NULL;
    jvm->GetEnv((void **) &env, *jni_version);
    if (env == NULL) {
        *jni_version = JNI_VERSION_1_4;
        jvm->GetEnv((void**) &env, *jni_version);
        if (env == NULL) {
            *jni_version = JNI_VERSION_1_2;
            jvm->GetEnv((void**) &env, *jni_version);
            if (env == NULL) {
                *jni_version = JNI_VERSION_1_1;
                jvm->GetEnv((void**) &env, *jni_version);
                if (env == NULL) {
                    *jni_version = JNI_ERR;
                    return env;
                }
            }
        }
    }
    return env;
}

/* This is executed once the native module is loaded */
jint JNI_OnLoad(JavaVM* jvm, void* reserved) {
    #ifdef SHORE_WRAPPER_DEBUG
    std::cout << "JNI_OnLoad" << std::endl;
    #endif
    g_jvm = jvm;
    jint jni_version;
    JNIEnv* env = JNU_GetEnv(g_jvm, &jni_version);

    if(NULL == env) {
        return JNI_ERR;
    }

    return jni_version;
}

/* This should be executed once the native module is unloaded.
    This is, however, not the case...
*/
void JNI_OnUnload(JavaVM* jvm, void* reserved) {
    #ifdef SHORE_WRAPPER_DEBUG
    std::cout << "JNI_OnUnload" << std::endl;
    #endif
    jint jni_version;
    JNIEnv* env = JNU_GetEnv(g_jvm, &jni_version);
    if(env && g_obj) {
        env->DeleteGlobalRef(g_obj);
        g_obj = nullptr;
    }
}



/* This is the method that is set as the callback method for Shore::SetMessageCall in the
JNI wrapper. It forwards the message to the IMessageCallback method that is passed to
SetMessageCall() on the Java side */
static void shore_error_callback(const char *s) {
    JNIEnv *jenv = 0;
#ifdef __ANDROID__
    jint rs = g_jvm->AttachCurrentThread(&jenv, NULL);
#else
    jint rs = g_jvm->AttachCurrentThread((void**)&jenv, NULL);
#endif
    if (rs < 0 ) {
        std::cerr << "Could not attach to current thread" << std::endl;
        return;
    }

    const jclass callbackInterface = jenv->FindClass("de/fraunhofer/iis/shore/wrapper/IMessageCallback");
    if(!callbackInterface || jenv->ExceptionCheck()) {
        jenv->ExceptionClear();
        std::cerr << "Could not get CallbackInterface" << std::endl;
        return;
    }

    const jmethodID callbackMethod = jenv->GetMethodID(callbackInterface,
                    "MessageCallback", "(Ljava/lang/String;)V");

    if(callbackMethod || jenv->ExceptionCheck()) {
        jenv->CallVoidMethod(g_obj, callbackMethod, jenv->NewStringUTF(s));
    } else {
        jenv->ExceptionClear();
        std::cerr << "Could not get CallbackMethod" << std::endl;
    }
    jenv->DeleteLocalRef(callbackInterface);
}

/* This is the method that is set as the callback method for Shore::SetModelQuery in the
JNI wrapper. It forwards the message to the IModelQueryCallback method that is passed to
SetModelQuery() on the Java side */
static void shore_modelquery_callback(const char *modelName) {
    JNIEnv *jenv = 0;
#ifdef __ANDROID__
    jint rs = g_jvm->AttachCurrentThread(&jenv, NULL);
#else
    jint rs = g_jvm->AttachCurrentThread((void**)&jenv, NULL);
#endif
    if (rs < 0 ) {
        std::cerr << "Could not attach to current thread" << std::endl;
        return;
    }

    const jclass callbackInterface = jenv->FindClass("de/fraunhofer/iis/shore/wrapper/IModelQueryCallback");
    if(!callbackInterface || jenv->ExceptionCheck()) {
        jenv->ExceptionClear();
        std::cerr << "Could not get CallbackInterface" << std::endl;
        return;
    }

    const jmethodID callbackMethod = jenv->GetMethodID(callbackInterface,
                    "ModelQueryCallback", "(Ljava/lang/String;)V");

    if(callbackMethod || jenv->ExceptionCheck()) {
        jenv->CallVoidMethod(g_obj, callbackMethod, jenv->NewStringUTF(modelName));
    } else {
        jenv->ExceptionClear();
        std::cerr << "Could not get CallbackMethod" << std::endl;
    }
    jenv->DeleteLocalRef(callbackInterface);
}

namespace Shore {
    void DeleteEngines() {
        for(auto engine : g_engines) {
            #ifdef SHORE_WRAPPER_DEBUG
            std::cout << "Deleting engine " << engine << std::endl;
            #endif
            DeleteEngine(engine);
        }
    }
}
%}

/* Set the type for the parameter passed to SetMessageCall() to IMessageCall (in Shore.java) */
%typemap(jstype) void (*messageCall)( const char* ) "IMessageCallback";
/* Set the type for the parameter passed to SetMessageCall to IMessageCall (in ShoreJNI.java) */
%typemap(jtype) void (*messageCall)( const char* ) "IMessageCallback";
/* Set the type for the  parameter passed to the JNI function for
   SetMessageCall() to jobject (in Shore_wrap.cxx) */
%typemap(jni) void (*messageCall)( const char* ) "jobject";
/* Set the parameter passed to ShoreJNI.SetMessageCall() to the input parmeter (= the IMessageCallback) */
%typemap(javain) void (*messageCall)( const char* ) "$javainput";


/* This is inserted into the JNI method for SetMessageCall in Shore_wrap.cxx
  Sets the global g_jvm and the g_obj which are used inside the shore_error_callback */
%typemap(in) void (*messageCall)( const char* )  {
  jenv->GetJavaVM(&g_jvm);
  /* Set g_obj to the input jobect of the JNI call */
  g_obj = jenv->NewGlobalRef($input);
  jenv->DeleteLocalRef($input);
  /* set the parameter passed to Shore::SetMessageCall to shore_error_callback */
  $1 = shore_error_callback;
}

/* Set the type for the parameter passed to SetModelQuery() to IModelQueryCallback (in Shore.java) */
%typemap(jstype) void (*modelQuery)( const char* ) "IModelQueryCallback";
/* Set the type for the parameter passed to SetModelQuery to IModelQueryCallback (in ShoreJNI.java) */
%typemap(jtype) void (*modelQuery)( const char* ) "IModelQueryCallback";
/* Set the type for the  parameter passed to the JNI function for
   SetModelQuery() to jobject (in Shore_wrap.cxx) */
%typemap(jni) void (*modelQuery)( const char* ) "jobject";
/* Set the parameter passed to ShoreJNI.SetModelQuery() to the input parmeter (= the IModelQueryCallback) */
%typemap(javain) void (*modelQuery)( const char* ) "$javainput";

/* This is inserted into the JNI method for SetModelQuery in Shore_wrap.cxx
  Sets the global g_jvm and the g_obj which are used inside the shore_modelquery_callback */
%typemap(in) void (*modelQuery)( const char* )  {
  jenv->GetJavaVM(&g_jvm);
  /* Set g_obj to the input jobect of the JNI call */
  g_obj = jenv->NewGlobalRef($input);
  jenv->DeleteLocalRef($input);
  /* set the parameter passed to Shore::SetModelQuery to shore_modelquery_callback */
  $1 = shore_modelquery_callback;
}

%{
#include "CreateFaceEngine.h"
%}
%include "Shore.h"
%include "CreateFaceEngine.h"
namespace Shore {
void DeleteEngines();
}

