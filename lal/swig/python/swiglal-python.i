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

// SWIG interface code specific to Python
// Author: Karl Wette, 2011

// After any action, check if an error was raised, e.g. by SWIG_Error;
// if so, SWIG_fail so that Python will generate an exception
%exception "$action
if (PyErr_Occurred()) SWIG_fail;"

// Provide SWIG UTL conversion functions SWIG_From and SWIG_AsVal
// between Python and LAL/GSL complex numbers.
%include <pycomplex.swg>
%swig_cplxflt_convn(gsl_complex_float, gsl_complex_float_rect, GSL_REAL, GSL_IMAG);
%swig_cplxdbl_convn(gsl_complex, gsl_complex_rect, GSL_REAL, GSL_IMAG);
%swig_cplxflt_convn(COMPLEX8, XLALCOMPLEX8Rect, LAL_REAL, LAL_IMAG);
%swig_cplxdbl_convn(COMPLEX16, XLALCOMPLEX16Rect, LAL_REAL, LAL_IMAG);

// Include numpy headers in wrapping code, and ensure
// numpy array module is loaded along with this module.
%header %{
  #include <numpy/arrayobject.h>
%}
%init %{
  import_array();
%}

// Returns whether a PyObject is a valid, allocated object,
// i.e. whether it is a non-NULL pointer.
%header %{

  SWIGINTERNINLINE bool
  swiglal_is_valid(PyObject *p) {
    return p != NULL;
  }

%}

// Functions for manipulating vectors in Python.
%header %{

  // Return whether a PyObject is a non-zero-length vector.
  // We accept either one-dimensional numpy arrays of size > 0,
  // or an non-zero-length sequence.
  SWIGINTERN bool
  swiglal_is_vector(PyObject *p) {
    if (PyArray_Check(p)) {
      return PyArray_NDIM(p) == 1 && PyArray_DIM(p, 0) > 0;
    }
    else if (PySequence_Check(p)) {
      return PySequence_Length(p) > 0;
    }
    return false;
  }

  // Return the length of a PyObject vector.
  // Numpy arrays and sequences are accepted.
  SWIGINTERN size_t
  swiglal_vector_length(PyObject *p) {
    if (PyArray_Check(p)) {
      return PyArray_DIM(p, 0);
    }
    else if (PySequence_Check(p)) {
      return PySequence_Length(p);
    }
    return 0;
  }

  // Get the (i)th element of a PyObject vector.
  // Numpy arrays and sequences are accepted.
  SWIGINTERN PyObject*
  swiglal_vector_get(PyObject *p, const size_t i) {
    if (PyArray_Check(p)) {
      return PyArray_GETITEM(p, PyArray_GETPTR1(p, i));
    }
    else if (PySequence_Check(p)) {
      return PySequence_GetItem(p, i);
    }
    return NULL;
  }

  // Set the (i)th element of a PyObject vector to pi.
  // Since we will only return numpy arrays as output,
  // only numpy array support is needed here.
  SWIGINTERN bool
  swiglal_vector_set(PyObject *p, const size_t i, PyObject *pi) {
    if (PyArray_Check(p)) {
      return 0 == PyArray_SETITEM(p, PyArray_GETPTR1(p, i), pi);
    }
    return false;
  }

  // Create a new numpy vector which can store any PyObject.
  template<class TYPE >
  SWIGINTERN PyObject*
  swiglal_new_vector(const size_t n) {
    npy_intp dims[1];
    dims[0] = n;
    return PyArray_EMPTY(1, dims, NPY_OBJECT, 0);
  }

%}

// Functions for manipulating matrices in Python.
%header %{

  // Return whether a PyObject is a non-zero-size matrix.
  // We accept either two-dimensional numpy arrays of non-zero
  // size, or an non-zero-length sequence of sequences, where
  // each sequence element has the same non-zero size.
  SWIGINTERN bool
  swiglal_is_matrix(PyObject *p) {
    // If p is a numpy array ...
    if (PyArray_Check(p)) {
      return PyArray_NDIM(p) == 2;
    }
    // If p is a sequence ...
    else if (PySequence_Check(p)) {
      // Check that p has non-zero length
      Py_ssize_t ni = PySequence_Length(p);
      if (ni < 1) {
        return false;
      }
      else {
        // Iterate over the elements of p
        Py_ssize_t nj = -1;
        for (Py_ssize_t i = 0; i < ni; ++i) {
          // Check that the (i)th element is a sequence
          PyObject *pi = PySequence_GetItem(p, i);
          if (!PySequence_Check(pi)) {
            return false;
          }
          // If this is the first element, check
          // that it has non-zero length
          if (nj < 0) {
            if ((nj = PySequence_Length(pi)) < 1) {
              return false;
            }
          }
          // Otherwise, check that the length of
          // this sequence matches the first element
          else if (nj != PySequence_Length(pi)) {
            return false;
          }
        }
      }
      // We have what we want
      return true;
    }
    return false;
  }

  // Return the number of rows of a PyObject matrix.
  // Numpy arrays and sequences-of-sequences are supported.
  SWIGINTERN size_t
  swiglal_matrix_rows(PyObject *p) {
    if (PyArray_Check(p)) {
      return PyArray_DIM(p, 0);
    }
    else if (PySequence_Check(p)) {
      return PySequence_Length(p);
    }
    return 0;
  }

  // Return the number of columns of a PyObject matrix.
  // Numpy arrays and sequences-of-sequences are supported.
  SWIGINTERN size_t
  swiglal_matrix_cols(PyObject *p) {
    if (PyArray_Check(p)) {
      return PyArray_DIM(p, 1);
    }
    else if (PySequence_Check(p)) {
      return PySequence_Length(PySequence_GetItem(p, 0));
    }
    return 0;
  }

  // Get the (i,j)th element of a PyObject matrix.
  // Numpy arrays and sequences-of-sequences are supported.
  SWIGINTERN PyObject*
  swiglal_matrix_get(PyObject *p, const size_t i, const size_t j) {
    if (PyArray_Check(p)) {
      return PyArray_GETITEM(p, PyArray_GETPTR2(p, i, j));
    }
    else if (PySequence_Check(p)) {
      return PySequence_GetItem(PySequence_GetItem(p, i), j);
    }
    return NULL;
  }

  // Set the (i,j)th element of a PyObject matrix to pij.
  // Since we will only return numpy arrays as output,
  // only numpy array support is needed here.
  SWIGINTERN bool
  swiglal_matrix_set(PyObject *p, const size_t i, const size_t j, PyObject *pij) {
    if (PyArray_Check(p)) {
      return 0 == PyArray_SETITEM(p, PyArray_GETPTR2(p, i, j), pij);
    }
    return false;
  }

  // Create a new numpy matrix which can store any PyObject.
  template<class TYPE >
  SWIGINTERN PyObject*
  swiglal_new_matrix(const size_t ni, const size_t nj) {
    npy_intp dims[2];
    dims[0] = ni;
    dims[1] = nj;
    return PyArray_EMPTY(2, dims, NPY_OBJECT, 0);
  }

%}    

// Create new numpy vectors and matrices which can store a NPYTYPE.
%define swiglal_new_numpy_vecmat(TYPE, NPYTYPE)
  %header %{
    template<>
    PyObject*
    swiglal_new_vector<TYPE >(const size_t n) {
      npy_intp dims[1];
      dims[0] = n;
      return PyArray_EMPTY(1, dims, NPYTYPE, 0);
    }
    template<>
    PyObject*
    swiglal_new_matrix<TYPE >(const size_t ni, const size_t nj) {
      npy_intp dims[2];
      dims[0] = ni;
      dims[1] = nj;
      return PyArray_EMPTY(2, dims, NPYTYPE, 0);
    }
  %}
%enddef

// Create new numpy vectors and matrices for integer types
swiglal_new_numpy_vecmat(short, NPY_SHORT);
swiglal_new_numpy_vecmat(unsigned short, NPY_USHORT);
swiglal_new_numpy_vecmat(int, NPY_INT);
swiglal_new_numpy_vecmat(unsigned int, NPY_UINT);
swiglal_new_numpy_vecmat(long, NPY_LONG);
swiglal_new_numpy_vecmat(unsigned long, NPY_ULONG);
swiglal_new_numpy_vecmat(long long, NPY_LONGLONG);
swiglal_new_numpy_vecmat(unsigned long long, NPY_ULONGLONG);

// Create new numpy vectors and matrices for real and complex types
swiglal_new_numpy_vecmat(float, NPY_FLOAT);
swiglal_new_numpy_vecmat(double, NPY_DOUBLE);
swiglal_new_numpy_vecmat(gsl_complex_float, NPY_CFLOAT);
swiglal_new_numpy_vecmat(gsl_complex, NPY_CDOUBLE);
swiglal_new_numpy_vecmat(COMPLEX8, NPY_CFLOAT);
swiglal_new_numpy_vecmat(COMPLEX16, NPY_CDOUBLE);
