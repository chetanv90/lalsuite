/*
 *
 *  LALInference:          LAL Inference library
 *  LALInferencePrior.h:   Collection of common priors
 *
 *  Copyright (C) 2009 Ilya Mandel, Vivien Raymond, Christian Roever, Marc van der Sluys and John Veitch
 *
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with with program; see the file COPYING. If not, write to the
 *  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 *  MA  02111-1307  USA
 */

/**
 * \file LALInferencePrior.h
 * \brief Collection of commonly used Prior functions and utilities
 * \ingroup LALInference
 * 
 * This file contains 
 * 
 */

#ifndef LALInferencePrior_h
#define LALInferencePrior_h


#include <lal/LALInference.h>
/** Return the logarithmic prior density of the variables specified, for the non-spinning/spinning inspiral signal case.
 */
REAL8 LALInferenceInspiralPrior(LALInferenceRunState *runState, LALInferenceVariables *variables);

/* Convert the hypercube parameter to physical parameters, for the non-spinning inspiral signal case */
int LALInferenceInspiralCubeToPrior(LALInferenceRunState *runState, LALVariables *params, double *Cube);

/** Apply cyclic and reflective boundaries to \c parameter to bring it
 *  back within the allowed prior ranges that are specified in \c
 *  priorArgs.  LALInferenceCyclicReflectiveBound() should not be
 *  called after any multi-parameter update step in a jump proposal,
 *  as this violates detailed balance.
 */
void LALInferenceCyclicReflectiveBound(LALInferenceVariables *parameter, LALInferenceVariables *priorArgs);

/** \brief Rotate initial phase if polarisation angle is cyclic around ranges
 * 
 *  If the polarisation angle parameter \f$\psi\f$ is cyclic about its upper and
 *  lower ranges of \f$-\pi/4\f$ to \f$\psi/4\f$ then the transformation for
 *  crossing a boundary requires the initial phase parameter \f$\phi_0\f$ to be
 *  rotated through \f$\pi\f$ radians. The function assumes the value of
 *  \f$\psi\f$ has been rescaled to be between 0 and \f$2\pi\f$ - this is a
 *  requirement of the covariance matrix routine \c LALInferenceNScalcCVM
 *  function.  
 * 
 *  This is particularly relevant for pulsar analyses.
 * 
 *  \param parameter [in] Pointer to an array of parameters
 *  \param priorArgs [in] Pointer to an array of prior ranges
 */
void LALInferenceRotateInitialPhase( LALInferenceVariables *parameter );

/** Return the logarithmic prior density of the variables as specified for the sky localisation project 
 *  (see: https://www.lsc-group.phys.uwm.edu/ligovirgo/cbcnote/SkyLocComparison#priors ), 
 *  for the non-spinning/spinning inspiral signal case.
 */
REAL8 LALInferenceInspiralSkyLocPrior(LALInferenceRunState *runState, LALInferenceVariables *params);

/* Convert the hypercube parameter to physical parameters, for the non-spinning inspiral signal case */
int LALInferenceInspiralSkyLocCubeToPrior(LALInferenceRunState *runState, LALVariables *params, double *Cube);

/** Return the logarithmic prior density of the variables specified, 
 *  for the non-spinning/spinning inspiral signal case.
 */
REAL8 LALInferenceInspiralPriorNormalised(LALInferenceRunState *runState, LALInferenceVariables *params);

/** Function to add the minimum and maximum values for the uniform prior onto the \c priorArgs. 
 */
void LALInferenceAddMinMaxPrior(LALInferenceVariables *priorArgs, const char *name, void *min, void *max, LALInferenceVariableType type);

/** Get the minimum and maximum values of the uniform prior from the \c priorArgs list, given a name. 
 */
void LALInferenceGetMinMaxPrior(LALInferenceVariables *priorArgs, const char *name, void *min, void *max);

/** Function to remove the mininum and maximum values for the uniform prior onto the \c priorArgs. 
 */
void LALInferenceRemoveMinMaxPrior(LALInferenceVariables *priorArgs, const char *name);

/** Function to add the mu and sigma values for the Gaussian prior onto the \c priorArgs. 
 */
void LALInferenceAddGaussianPrior(LALInferenceVariables *priorArgs, const char *name, void *mu, void *sigma, LALInferenceVariableType type);

/** Get the mu and sigma values of the Gaussian prior from the \c priorArgs list, given a name. 
 */
void LALInferenceGetGaussianPrior(LALInferenceVariables *priorArgs, const char *name, void *mu, void *sigma);


/** Function to remove the mu and sigma values for the Gaussian prior onto the \c priorArgs. 
 */
void LALInferenceRemoveGaussianPrior(LALInferenceVariables *priorArgs, const char *name);

/** Check for types of standard prior */
/** Check for a uniform prior (with mininum and maximum) */
int LALInferenceCheckMinMaxPrior(LALInferenceVariables *priorArgs, const char *name);
/** Check for a Gaussian prior (with a mean and variance) */
int LALInferenceCheckGaussianPrior(LALInferenceVariables *priorArgs, const char *name);

/** Draw variables from the prior ranges */
void LALInferenceDrawFromPrior( LALInferenceVariables *output, 
                                LALInferenceVariables *priorArgs, 
                                gsl_rng *rdm );

/** Draw an individual variable from its prior range */
void LALInferenceDrawNameFromPrior( LALInferenceVariables *output, 
                                    LALInferenceVariables *priorArgs, 
                                    char *name, LALInferenceVariableType type, 
                                    gsl_rng *rdm );

#endif
