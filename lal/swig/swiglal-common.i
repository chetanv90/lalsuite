//
//  Copyright (C) 2011 Karl Wette
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with with program; see the file COPYING. If not, write to the
//  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
//  MA  02111-1307  USA
//

// common SWIG interface code
// Author: Karl Wette, 2011

// SWIG version used to generate wrapping code
%inline %{
  const int swig_version_hex = SWIGVERSION;
%}

// Was the wrapping code generated in debugging mode?
#ifdef NDEBUG
%inline %{const bool swiglal_debug = false;%}
#else
%inline %{const bool swiglal_debug = true;%}
#endif

/////////////// Basic definitions and includes ///////////////

// Ignore GCC warnings about unitialised or unused variables.
// These warnings may be produced by some SWIG-generated code.
%begin %{
  #ifdef __GNUC__
    #pragma GCC diagnostic ignored "-Wuninitialized"
    #pragma GCC diagnostic ignored "-Wunused-variable"
  #endif
%}

// Include basic C++ and LAL headers in wrapping code.
%header %{
  #include <cstdlib>
  #include <cstring>
  #include <iostream>
  #include <string>
  #include <sstream>
  #include <lal/XLALError.h>
  #include <lal/LALMalloc.h>
%}

// Allow SWIG wrapping code can raise exceptions.
%include <exception.i>

// Tell SWIG about C99 integer typedefs,
// on which LAL integer types are based.
%include <stdint.i>

// Generate copy constructors for all structs.
%copyctor;

// Turn on auto-documentation of functions.
%feature("autodoc", 1);

// Enable keyword argument globally, if
// supported by the target scripting language.
%feature("kwargs", 1);

// Suppress warnings about not being able to use
// keywords arguments in various circumstances.
#pragma SWIG nowarn=SWIGWARN_PARSE_KEYWORD
#pragma SWIG nowarn=SWIGWARN_LANG_VARARGS_KEYWORD
#pragma SWIG nowarn=SWIGWARN_LANG_OVERLOAD_KEYWORD

// This macro is used to both %include a LAL header into the
// SWIG interface, so that SWIG will generate wrappings for
// its contents, and also #include it in the wrapping code.
%define swiglal_include(HEADER)
  %include <HEADER>
  %header %{
    #include <HEADER>
  %}
%enddef

// Remove LAL RCS ID macros from SWIG interface.
#define NRCSID(name,id)
#define RCSID(id)

// So that SWIG knows about basic LAL datatypes.
%header %{
  #include <lal/LALAtomicDatatypes.h>
  #include <lal/LALComplex.h>
%}

// So that SWIG wrapping code knows about basic GSL types.
%header %{
  #include <gsl/gsl_complex_math.h>
  #include <gsl/gsl_vector.h>
  #include <gsl/gsl_matrix.h>
  // GSL doesn't provide a constructor function for
  // gsl_complex_float, so we provide one here.
  SWIGINTERN gsl_complex_float
  gsl_complex_float_rect(float x, float y) {
    gsl_complex_float z;
    GSL_SET_COMPLEX(&z, x, y);
    return z;
  }
%}

// Function which tests whether the pointer passed to it is non-zero.
// This function does the right thing if its passed an actual pointer,
// or the name of a statically-allocated array (which is implicitly
// converted into an address), and it will also correctly fail to compile
// if its argument is neither of these possibilities.
%header %{
  template<class T>
  SWIGINTERNINLINE bool    
  swiglal_check_ptr(T *p) {
    return p != NULL;
  }
%}

// Wrapper function for SWIG_exception which allows MESSAGE to
// contain streaming (<<) operators; this allows error messages
// to easily include non-string data.
%define swiglal_exception(CODE, MESSAGE)
  std::stringstream msg;
  msg << MESSAGE;
  SWIG_exception(CODE, msg.str().c_str());
%enddef

// Include SWIG interface code for specific scripting languages.
#ifdef SWIGOCTAVE
%include <lal/swiglal-octave.i>
#endif
#ifdef SWIGPYTHON
%include <lal/swiglal-python.i>
#endif

/////////////// Memory allocation ///////////////

// SWIG generates default constructor and destructors for wrapped structs.
// These contructors/destructors always use 'malloc'/'free' (C mode) or
// 'new'/'delete' (C++ mode); see e.g. Source/Swig/cwrap.c in SWIG 1.3.40.
// It is not possible to specify alternative memory allocators through any
// options to SWIG. However, we would like all LAL structs to be allocated
// with LAL memory allocation functions, so that the LAL memory debugging
// system can be used inside a scripting language. For example, if a LAL
// struct allocated by SWIG is passed to a LAL function which tries to
// de-allocate it, the LAL memory debugging system will fail unless the
// LAL struct was originally allocated by LAL.
//
// The solution is to use a C++ feature: a class C can supply their own
// 'new'/'delete' operators, which will then be called by 'new C()' to
// allocate the class. We do the same for all LAL structs by adding the
// symbol 'SWIGLAL_STRUCT_LALALLOC' to their definitions. This symbol
// defines a 'new' operator, which allocates the struct using XLALCalloc
// (so that the struct is zero-initialised), and a 'delete' operator
// which calls XLALFree to de-allocate the struct.
//
// Note that, if a LAL struct does not contain 'SWIGLAL_STRUCT_LALALLOC',
// it will continue to be use the default 'new'/'delete' operators. This
// should break anything as long as LAL memory debugging is not used,
// either by compiling with --disable-debug or by setting lalDebugLevel=0.

// Remove SWIGLAL_STRUCT_LALALLOC from SWIG interface
#define SWIGLAL_STRUCT_LALALLOC()

// Define SWIGLAL_STRUCT_LALALLOC in SWIG wrapping code
%header %{
  #define SWIGLAL_STRUCT_LALALLOC() \
    void* operator new (size_t n) throw() { \
      return XLALCalloc(1, n); \
    } \
    void operator delete(void* p) { \
      XLALFree(p); \
    }
%}

/////////////// Type conversion helpers ///////////////

// In most cases SWIG will handle the conversion of types between C code
// and the target scripting language automagically, as follows:
//
//  * If the type is a primitive type (or a typedef thereof) for
//    which an native exists in the scripting language, e.g. integer
//    and real numbers, complex numbers, we want this type to be converted
//    to/from the corresponding scripting language object.
//  * Otherwise, if the type is a struct, we want to encapsulate this type
//    with a swig_type wrapper, so that it can be passed around within the
//    scripting language.
//
// When writing extensions to SWIG, such as the vector/array conversion
// below, we will want to re-use the language-specific type conversion code
// already in SWIG. We cannot immediately re-use SWIG's typemaps, however,
// as it's not currently possible to generically "call" typemaps as functions
// from other typemaps (i.e. the $typemap macro cannot be used with any
// arguments, apart from a type).
//
// Some SWIG language modules (including Octave and Python) provide a
// library of conversion functions with a uniform interface for converting
// to/from primitive C types (the Unified Typemap Library in SWIG-speak).
// These functions are:
//
//  * SWIG_From(TYPE)(in), which takes a C TYPE and returns the equivalent
//    scripting language object; and
//
//  * SWIG_AsVal(TYPE)(in,*out), which takes a scripting language object,
//    tries to convert it to the given C TYPE, and either puts the result
//    in *out or returns a SWIG error code.
//
// We re-use these functions to provide type conversions for all built-in
// C types, and provide new functions of this form for other primitive
// types, such as LAL and GSL complex numbers.
//
// However, a downside of the SWIG_From/AsVal functions is that they won't
// pick up typedefs of built-in C types. This is because e.g. SWIG_From(TYPE)
// actually translates to a function named SWIG_From_TYPE, and so the function
// SWIG_From_REAL8 will not exist even if REAL8 is just a double. We get
// around this by wrapping calls to SWIG_From and SWIG_AsVal inside C++
// templated functions, named swiglal_from and swiglal_as_val respectively,
// which are specialised for each built-in C type. Since C++ takes typedefs
// into account when selecting which function template to use, e.g.
// swiglal_from<REAL8> will be correctly mapped to swiglal_from<double>,
// which will then call SWIG_From(double).
//
// Enumerations are another special cases, since we want enumerations to
// be converted to/from scripting language integers. Unfortunately, C++
// does not (easily) provide a way to distinguish an enum type from a non-
// enum type; SWIG however does provide this facility. Thus we use a SWIG
// typemap to make conversions to/from enums call the special functions
// swiglal_from_enum and swiglal_as_val_enum.
//
// If a template specialisation for TYPE does not exist, the base templates
// swiglal_from<TYPE> and swiglal_as_val<TYPE> will be called, which will
// correctly encapsulate TYPE with a swig_type wrapper. Note that, therefore,
// that this will result in TYPE being passed around *by reference*, i.e.
// assignment of a variable of TYPE which just assign a reference, not a copy.
// (Copies of swig-type-wrapped TYPEs can be made using copy constructors.)
// The behaviour of any specialisation of swig_from/swig_as_val to a
// particular TYPE, however, should be to pass that TYPE *by value*, i.e.
// assignment of a variable of this TYPE should copy the value of the
// scripting language object, re-allocating TYPE if so needed.
//
// swiglal_as_val also takes a integer argument 'flags' which can be used
// to change its internal behaviour, e.g. specify what memory allocation
// routines to use when re-allocating a TYPE.

// Bit-flags to pass to swiglal_as_val
%define SL_AV_DEFAULT  0x0 %enddef   // Default
%define SL_AV_LALALLOC 0x1 %enddef   // Use LAL memory routines

// These typemaps select which swiglal_from/swiglal_as_val functions to
// use: if the supplied type is an enum, call the swiglal_{from,as_val}_enum
// functions; otherwise call the swiglal_{from,as_val} functions. The
// templates C++ functions are supplied with the supplied type's "ltype", which
// strips off any const qualifiers; this is so the correct template is found.
%typemap(swiglal_from_which,   noblock=1)      SWIGTYPE "swiglal_from<$ltype >";
%typemap(swiglal_from_which,   noblock=1) enum SWIGTYPE "swiglal_from_enum<$ltype >";
%typemap(swiglal_as_val_which, noblock=1)      SWIGTYPE "swiglal_as_val<$ltype >";
%typemap(swiglal_as_val_which, noblock=1) enum SWIGTYPE "swiglal_as_val_enum<$ltype >";

// Convience macros for calling the correct swiglal_{from,as_val} functions.
#define swiglal_call_from(TYPE...)   $typemap(swiglal_from_which, TYPE)
#define swiglal_call_as_val(TYPE...) $typemap(swiglal_as_val_which, TYPE)

// Ensure that the SWIG_From(int) and SWIG_AsVal(int) functions
// are available by including their respective SWIG fragments.
%fragment(SWIG_From_frag(int));
%fragment(SWIG_AsVal_frag(int));

// Provide conversions for generic types (swiglal_{from,as_val})
// and for enumeration types (swiglal_{from,as_val}_enum)
%header {

  // Use SWIG_NewPointerObj to create a swig_type wrapper around TYPE '*in'
  // using the type information supplied by 'in_ti'. The last argument to
  // SWIG_NewPointerObj is zero since we are wrapping an existing C pointer
  // and do not want to own/disown it.
  template<class TYPE>
  SWIGINTERNINLINE SWIG_Object
  swiglal_from(TYPE *in, swig_type_info *in_ti) {
    return SWIG_NewPointerObj(%as_voidptr(in), in_ti, 0);
  }
  template<class TYPE>
  SWIGINTERNINLINE SWIG_Object
  swiglal_from(const TYPE *in, swig_type_info *in_ti) {
    return SWIG_NewPointerObj(%as_voidptr(in), in_ti, 0);
  }

  // Use SWIG_ConvertPtr to convert a swig_type wrapped object 'in' into a
  // TYPE '*out', if possible, using the type information supplied by 'out_ti'.
  // The return value indicates whether the conversion was successful. The
  // last argument to SWIG_ConvertPtr is zero since we are recovering an
  // existing  C pointer and do not want to own/disown it.
  template<class TYPE>
  SWIGINTERNINLINE int
  swiglal_as_val(SWIG_Object in, TYPE *out, swig_type_info *out_ti, int flags) {
    return SWIG_ConvertPtr(in, %as_voidptrptr(&out), out_ti, 0);
  }

  // Check that the enumeration TYPE is the same size as an int, then cast
  // '*in' to an int and convert its value to a scripting language object.
  template<class TYPE>
  SWIGINTERNINLINE SWIG_Object
  swiglal_from_enum(TYPE *in, swig_type_info *in_ti) {
    if (sizeof(TYPE) != sizeof(int)) {
      return SWIG_ErrorType(SWIG_TypeError);
    }
    int in_v = %static_cast(*in, int);
    return SWIG_From(int)(in_v);
  }
  template<class TYPE>
  SWIGINTERNINLINE SWIG_Object
  swiglal_from_enum(const TYPE *in, swig_type_info *in_ti) {
    if (sizeof(TYPE) != sizeof(int)) {
      return SWIG_ErrorType(SWIG_TypeError);
    }
    const int in_v = %static_cast(*in, int);
    return SWIG_From(int)(in_v);
  }

  // Check that the enumeration TYPE is the same size as an int, then
  // convert the scripting language object 'in' to an int. If this is
  // successful, cast the int to a enumeration TYPE '*out'.
  template<class TYPE>
  SWIGINTERNINLINE int
  swiglal_as_val_enum(SWIG_Object in, TYPE *out, swig_type_info *out_ti, int flags) {
    if (sizeof(TYPE) != sizeof(int)) {
      return SWIG_TypeError;
    }
    int out_v;
    int ecode = SWIG_AsVal(int)(in, &out_v);
    if (!SWIG_IsOK(ecode)) {
      return ecode;
    }
    *out = %static_cast(out_v, TYPE);
    return ecode;
  }

}

// This macro generates template specialisations of swiglal_from and
// swiglal_as_val for built-in C types, as well as other types that
// are considered primitive, such as LAL and GSL complex types.
%define swiglal_conv_ctype(TYPE,ARG2...)

  // Ensure that the SWIG_From(TYPE) and SWIG_AsVal(TYPE) functions
  // are available by including their respective SWIG fragments.
  %fragment(SWIG_From_frag(TYPE));
  %fragment(SWIG_AsVal_frag(TYPE));

  %header {

    // Convert a TYPE to a scripting language object using SWIG_From.
    template<>
    SWIG_Object
    swiglal_from(TYPE *in, swig_type_info *in_ti) {
      return SWIG_From(TYPE)(*in);
    }
    template<>
    SWIG_Object
    swiglal_from(const TYPE *in, swig_type_info *in_ti) {
      return SWIG_From(TYPE)(*in);
    }

    // Convert a scripting language object to a TYPE using SWIG_AsVal.
    // The return value indicates whether the conversion was successful.
    template<>
    int
    swiglal_as_val(SWIG_Object in, TYPE *out, swig_type_info *out_ti, int flags) {
      return SWIG_AsVal(TYPE)(in, out);
    }

  }

%enddef // swiglal_conv_ctype

// Provide conversions for all C built-in integer and floating-point types.
swiglal_conv_ctype(short);
swiglal_conv_ctype(unsigned short);
swiglal_conv_ctype(int);
swiglal_conv_ctype(unsigned int);
swiglal_conv_ctype(long);
swiglal_conv_ctype(unsigned long);
swiglal_conv_ctype(long long);
swiglal_conv_ctype(unsigned long long);
swiglal_conv_ctype(float);
swiglal_conv_ctype(double);

// Provide conversions for LAL and GSL complex number types.
swiglal_conv_ctype(gsl_complex_float);
swiglal_conv_ctype(gsl_complex);
swiglal_conv_ctype(COMPLEX8);
swiglal_conv_ctype(COMPLEX16);

// Provide typemaps to convert LAL and GSL complex numbers.
%typemaps_asvalfromn(SWIG_TYPECHECK_COMPLEX, gsl_complex_float);
%typemaps_asvalfromn(SWIG_TYPECHECK_COMPLEX, gsl_complex);
%typemaps_asvalfromn(SWIG_TYPECHECK_COMPLEX, COMPLEX8);
%typemaps_asvalfromn(SWIG_TYPECHECK_COMPLEX, COMPLEX16);

///// Provide conversions for strings /////

// Ensure that the SWIG_FromCharPtr and SWIG_AsCharPtrAndSize
// functions are available by including their respective SWIG fragments.
%fragment("SWIG_FromCharPtr");
%fragment("SWIG_AsCharPtrAndSize");

%header {

  // Convert a char* to a scripting language string using SWIG_FromCharPtr.
  template<>
  SWIG_Object
  swiglal_from(char* *in, swig_type_info *in_ti) {
    return SWIG_FromCharPtr(*in);
  }
  template<>
  SWIG_Object
  swiglal_from(const char* *in, swig_type_info *in_ti) {
    return SWIG_FromCharPtr(*in);
  }

  // Convert a scripting language string to a char* using
  // SWIG_AsCharPtrAndSize. If the conversion is successful,
  // re-allocate '*out' to the required size (using memory
  // routines requested by 'flags'), copy the converted char*
  // to it, and free the converted char* if required.
  template<>
  int
  swiglal_as_val(SWIG_Object in, char* *out, swig_type_info *out_ti, int flags) {
    char* tmp;
    size_t len;
    int alloc;
    // 'tmp' contains the converted string, 'len' its length, and
    // 'alloc' indicates whether the string was newly allocated.
    int ecode = SWIG_AsCharPtrAndSize(in, &tmp, &len, &alloc);
    if (!SWIG_IsOK(ecode)) {
      // Return if there was an error
      return ecode;
    }
    // If we're using LAL memory allocation routines:
    if (flags & SL_AV_LALALLOC) {
      // Try to re-allocate '*out' using XLALRealloc.
      *out = reinterpret_cast<char*>(XLALRealloc(*out, (len+1) * sizeof(char)));
    }
    // otherwise:
    else {
      // Try to re-allocate '*out' using realloc.
      *out = reinterpret_cast<char*>(realloc(*out, (len+1) * sizeof(char)));
    }
    // If the re-allocation was unsuccessful:
    if (*out == NULL) {
      return SWIG_MemoryError;
    }
    // otherwise:
    else {
      // Copy 'tmp' to '*out', with the trailing '\0'.
      memcpy(*out, tmp, len+1);
      // Delete 'tmp' if it was newly allocated.
      if (SWIG_IsNewObj(alloc)) {
        %delete_array(tmp);
      }
      return SWIG_OK;
    }
  }

}

/////////////// Vector / matrix type conversion ///////////////

// The following four macros convert a one-dimension (_vector) or
// two-dimensional (_matrix_) C array to (_out) or from (_in) a
// representation of the same data in the scripting language.
// The macros require the following functions to be implemented
// for the target scripting language:
//
//  * swiglal_is_valid(v) returns whether its argument is a valid
//    scripting language object, e.g. whether it is a non-NULL pointer
//
//  * swiglal_is_vector(v) and swiglal_is_matrix(v) return whether
//    their argument can be interpreted as a vector or a matrix,
//    respectively, in the target scripting language.
//
//  * swiglal_vector_get(v, i) and swiglal_vector_set(v, i, vi)
//    get the (i)th element of the scripting language vector v, and
//    assign the scripting language object vi to the (i)th element of v.
//
//  * swiglal_matrix_get(v, i, j) and swiglal_matrix_set(v, i, j, vij)
//    get the (i,j)th element of the scripting language vector v, and
//    assign the scripting language object vij to the (i,j)th element of v.
//
//  * swiglal_vector_new<TYPE>(n) and swiglal_matrix_new<TYPE>(ni, nj)
//    return a scripting language object containing a new vector of 
//    length n, and a new matrix with ni rows and nj columns respectively,
//    and which can contain elements of C type TYPE.
//
// The macros take the following arguments:
//  TYPE:
//    the type of an element of the C array.
//  NAME:
//    the name of the C array variable, e.g. 'data'.
//  DATA:
//    an expression accessing the C array variable, e.g. 'arg1->data'.
//  NI:
//    the length of the vector / the number of rows of the matrix.
//  NJ:
//    the number of columns of the matrix.
//  PTR_TO_DATA_I(DATA, I, NI):
//    the name of a macro which return a pointer to the (I)th
//    element of the vector DATA.
//  PTR_TO_DATA_IJ(DATA, I, NI, J, NJ):
//    the name of a macro which returns a pointer to the (I,J)th
//    element of the matrix DATA.
//  FLAGS:
//    bit-flags to pass to swiglal_as_val

// When creating a new scripting language vector/matrix, these
// typemaps determine what the representing C type should be:
// for enumeration types use int; otherwise use the supplied
// type, stripped of any const qualifiers (using '$ltype').
%typemap(swiglal_new_type)      SWIGTYPE "$ltype";
%typemap(swiglal_new_type) enum SWIGTYPE "int";

// Convert a scripting language vector to a C vector
%define swiglal_vector_convert_in(TYPE, NAME, DATA, NI, PTR_TO_DATA_I, FLAGS)
  // Check that the C vector has elements
  if ((NI) == 0) {
    swiglal_exception(SWIG_ValueError, "unexpected zero-length vector '"<<#NAME<<"'");
  }
  // Check that the scripting language $input is a vector with the same dimensions
  if (!swiglal_is_vector($input)) {
    swiglal_exception(SWIG_ValueError, "value being assigned to '"<<#NAME<<"' must be a vector");
  }
  if (swiglal_vector_length($input) != (NI)) {
    swiglal_exception(SWIG_ValueError, "value being assigned to '"<<#NAME<<"' must have length "<<(NI));
  }
  // Copy the scripting language vector $input to the C vector DATA
  for (size_t i = 0; i < (NI); ++i) {
    int ecode = swiglal_call_as_val(TYPE)(swiglal_vector_get($input, i), PTR_TO_DATA_I(DATA, i, NI), $1_descriptor, FLAGS);
    if (!SWIG_IsOK(ecode)) {
      %argument_fail(ecode, "$type", $symname, $argnum);
    }
  }
%enddef // swiglal_vector_convert_in

// Convert a C vector to a scripting language vector
%define swiglal_vector_convert_out(TYPE, NAME, DATA, NI, PTR_TO_DATA_I)
  // Check that the C vector has elements
  if ((NI) == 0) {
    swiglal_exception(SWIG_ValueError, "unexpected zero-length vector '"<<#NAME<<"'");
  }
  // Create a new scripting language vector $result
  $result = swiglal_new_vector<$typemap(swiglal_new_type, TYPE) >(NI);
  if (!swiglal_is_valid($result)) {
    swiglal_exception(SWIG_RuntimeError, "failed to create a new vector for '"<<#NAME<<"'");
  }
  // Copy the C vector DATA the scripting language vector $result
  for (size_t i = 0; i < (NI); ++i) {
    if (!swiglal_vector_set($result, i, swiglal_call_from(TYPE)(PTR_TO_DATA_I(DATA, i, NI), $1_descriptor))) {
      %argument_fail(SWIG_RuntimeError, "$type", $symname, $argnum);
    }
  }
%enddef // swiglal_vector_convert_out

// Convert a scripting language matrix to a C matrix
%define swiglal_matrix_convert_in(TYPE, NAME, DATA, NI, NJ, PTR_TO_DATA_IJ, FLAGS)
  // Check that the C matrix has elements
  if ((NI) == 0 || (NJ) == 0) {
    swiglal_exception(SWIG_ValueError, "unexpected zero-size matrix '"<<#NAME<<"'");
  }
  // Check that the scripting language $input is a matrix with the same dimensions
  if (!swiglal_is_matrix($input)) {
    swiglal_exception(SWIG_ValueError, "value being assigned to '"<<#NAME<<"' must be a matrix");
  }
  if (swiglal_matrix_rows($input) != (NI)) {
    swiglal_exception(SWIG_ValueError, "value being assigned to '"<<#NAME<<"' must have "<<(NI)<<" rows");
  }
  if (swiglal_matrix_cols($input) != (NJ)) {
    swiglal_exception(SWIG_ValueError, "value being assigned to '"<<#NAME<<"' must have "<<(NJ)<<" columns");
  }
  // Copy the scripting language matrix $input to the C matrix DATA
  for (size_t i = 0; i < (NI); ++i) {
    for (size_t j = 0; j < (NJ); ++j) {
      int ecode = swiglal_call_as_val(TYPE)(swiglal_matrix_get($input, i, j), PTR_TO_DATA_IJ(DATA, i, NI, j, NJ), $1_descriptor, FLAGS);
      if (!SWIG_IsOK(ecode)) {
        %argument_fail(ecode, "$type", $symname, $argnum);
      }
    }
  }
%enddef // swiglal_matrix_convert_in

// Convert a C matrix to a scripting language matrix
%define swiglal_matrix_convert_out(TYPE, NAME, DATA, NI, NJ, PTR_TO_DATA_IJ)
  // Check that the C matrix has elements
  if ((NI) == 0 || (NJ) == 0) {
    swiglal_exception(SWIG_ValueError, "unexpected zero-size matrix '"<<#NAME<<"'");
  }
  // Create a new scripting language matrix $result
  $result = swiglal_new_matrix<$typemap(swiglal_new_type, TYPE) >(NI, NJ);
  if (!swiglal_is_valid($result)) {
    swiglal_exception(SWIG_RuntimeError, "failed to create a new matrix for '"<<#NAME<<"'");
  }
  // Copy the C matrix DATA the scripting language matrix $result
  for (size_t i = 0; i < (NI); ++i) {
    for (size_t j = 0; j < (NJ); ++j) {
      if (!swiglal_matrix_set($result, i, j, swiglal_call_from(TYPE)(PTR_TO_DATA_IJ(DATA, i, NI, j, NJ), $1_descriptor))) {
        %argument_fail(SWIG_RuntimeError, "$type", $symname, $argnum);
      }
    }
  }
%enddef // swiglal_matrix_convert_out

// These macros return pointers to the (I)th element of the 1-D array DATA,
// and the (I,J)th element of the 2-D array DATA respectively. The arrays
// are assumed to be statically declared, e.g:
//   int a[3];
//   double b[2][5];
#define swiglal_fix_1Darray_ptr(DATA, I, NI)          &((DATA)[I])
#define swiglal_fix_2Darray_ptr(DATA, I, NI, J, NJ)   &((DATA)[I][J])

// These macros return pointers to the (I)th element of the vector SELF->DATA,
// and the (I,J)th element of the matrix SELF->DATA respectively. The arrays
// are assumed to be dynamically allocated, e.g.:
//   int *a = calloc(3, sizeof(int));
//   double *b = calloc(2 * 5, sizeof(double));
#define swiglal_dyn_1Darray_ptr(DATA, I, NI)          &((DATA)[I])
#define swiglal_dyn_2Darray_ptr(DATA, I, NI, J, NJ)   &((DATA)[(I)*(NJ)+(J)])
