%module Shore
%include "typemaps.i"
%include "carrays.i"


%typemap(in)  (char const* leftTop) {
    $1 = (unsigned char*) SvPVbyte_nolen($input);
}
%apply (char const* leftTop) { (unsigned char const* leftTop) };
namespace Shore {

/* Return a float instead of a "pointer to float" - perl 
 allows for defined($value) */
%typemap(out) float const* GetRatingOf %{
    if($1) {
        ST(argvi) = SWIG_From_float  SWIG_PERL_CALL_ARGS_1(static_cast< float >(*$1)); argvi++ ;
    }
%}
%typemap(out) float const* GetRating %{
    if($1) {
        ST(argvi) = SWIG_From_float  SWIG_PERL_CALL_ARGS_1(static_cast< float >(*$1)); argvi++ ;
    }
%}

%typemap(in) void (*messageCall)(const char* )  {
    dXSARGS;
    
    if ((items < 1) || (items > 1)) {
      SWIG_croak("Usage: SetMessageCall(functionName);");
    }

    if(msgSV) {
        SvSetSV(msgSV, $input);
    } else {
        msgSV = newSVsv($input);
    }
    $1 = shore_error_message;
}

%typemap(in) void (*modelQuery)(const char* )  {
    dXSARGS;

    if ((items < 1) || (items > 1)) {
      SWIG_croak("Usage: SetModelQuery(functionName);");
    }

    if(modelQuerySV) {
        SvSetSV(modelQuerySV, $input);
    } else {
        modelQuerySV = newSVsv($input);
    }
    $1 = shore_model_query;
}

}


%{
#include <string.h>
#include <iostream>
#include "Shore.h"
static SV *msgSV = 0;
static SV *modelQuerySV = 0;

extern char _sldata[] asm("_binary_ShapeLocator_68_2018_01_17_094200_ctm_start");
bool ShapeloactorRegistered =
    Shore::RegisterModel( "ShapeLocator_68_2018_01_17_094200", _sldata );

void shore_error_message(const char *message) {
    if(!msgSV) return;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpv(message, strlen(message))));
    PUTBACK;

    call_sv(msgSV, G_DISCARD);

    FREETMPS;
    LEAVE;
}

void shore_model_query(const char *modelQuery) {
    if(!modelQuerySV) return;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpv(modelQuery, strlen(modelQuery))));
    PUTBACK;

    call_sv(modelQuerySV, G_DISCARD);

    FREETMPS;
    LEAVE;
}

#include "CreateFaceEngine.h"
%}

%include "Shore.h"
%include "CreateFaceEngine.h"
