## Copyright (C) 2013, 2015 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Return computing-cost functions for use in OptimalSolution4StackSlide() to compute
## optimal StackSlide setup for a directed search (known sky-position, unknown f, fdot, f2dot, ...)
##
## [Adapted from 'metricComputingCost()' function initially used in S6CasA E@H search setup]
##
## Usage:
##   cost_funs = CostFunctionsDirected("opt", val, ...)
## where
##   cost_funs = struct of computing-cost functions to pass to OptimalSolution4StackSlide()
##
## Search setup options:
##   "tau_min":       spindown-age 'tau' in seconds [default: 300 yrs]
##   "brk_min":       (minimal) braking index 'n0' for spindown-bounds [default: 2]
##   "fmin":          lower search frequency bound [default: 50.00]
##   "fmax":          upper search frequency bound [default: 50.05]
##   "boundaryType":  what type of parameter-space boundary to assume [default: "EaHCasA"]:
##                    "EaHCasA" for a freq-dependent 'box' in {f1dot,f2dot}, defined by (tau_min, brk_min)
##                    "S5CasA" for Karl's CasA search construction, with brk-index in [2,7]
##
##   "Ndet"           number of detectors [default: 2]
##
##   "resampling":    use F-statistic 'resampling' instead of 'demod' timings for coherent cost [default: false]
##   "lattice":       template-bank lattice ("Zn", "Ans",..) [default: "Ans"]
##   "coh_c0_demod":  computational cost of F-statistic 'demod' per template per second [optional]
##   "coh_c0_resamp": computational cost of F-statistic 'resampling' per template [optional]
##   "inc_c0":        computational cost of incoherent step per template per segment [optional]
##   "grid_interpolation": use interpolating StackSlide or non-interpolating (ie coarse-grids == fine-grid)
##
function cost_funs = CostFunctionsDirected ( varargin )

  ## parse options
  params = parseOptions(varargin,
                        {"tau_min", "real,strictpos,scalar", 300 * 365 * 86400 },
                        {"brk_min", "real,strictpos,scalar", 2.0},
                        {"fmin", "real,strictpos,scalar", 50.00 },
                        {"fmax", "real,strictpos,vector", 50.05 },
                        {"Ndet", "real,strictpos,scalar", 2},
                        {"resampling", "logical,scalar", false},
                        {"coh_c0_demod", "real,strictpos,scalar", 7.4e-08 / 1800},
                        {"coh_c0_resamp", "real,strictpos,scalar", 1e-7},
                        {"inc_c0", "real,strictpos,scalar", 4.7e-09},
                        {"grid_interpolation", "logical,scalar", true},
                        {"lattice", "char", "Ans"},
                        {"boundaryType", "char", "EaHCasA"},
                        []);

  ## make closures of functions with 'params'
  cost_funs = struct( ...
                      "costFunCoh", @(Nseg, Tseg, mc=0.5) cost_coh_wparams ( Nseg, Tseg, mc, params ), ...
                      "costFunInc", @(Nseg, Tseg, mf=0.5) cost_inc_wparams ( Nseg, Tseg, mf, params ) ...
                    );

endfunction ## CostFunctionsDirected()
## Recompute a CasA solution from the E@H S6CasA setup
%!test
%!  UnitsConstants;
%!  refParams.Nseg = 32;
%!  refParams.Tseg = 8.0 * 86400;
%!  refParams.mc   = 0.12;
%!  refParams.mf   = 0.41;
%!
%!  costFuns = CostFunctionsDirected( ...
%!                                  "fmin", 120, ...
%!                                  "fmax", 1000, ...
%!                                  "tau_min", 300 * YRSID_SI, ...
%!                                  "Ndet", 1.0675, ...
%!                                  "resampling", false, ...
%!                                  "coh_c0_demod", 7.4e-8 / 1800, ...
%!                                  "inc_c0", 4.7e-9, ...
%!                                  "lattice", "Zn", ...
%!                                  "boundaryType", "EaHCasA" ...
%!                                );
%!  cost0 = 3.1451 * EM2014;
%!  TobsMax = 256.49 * DAYS;
%!
%!  sol = OptimalSolution4StackSlide ( "costFuns", costFuns, "cost0", cost0, "TobsMax", TobsMax, "stackparamsGuess", refParams );
%!
%!  tol = -1e-2;
%!  assert ( sol.mc, 0.11892, tol );
%!  assert ( sol.mf, 0.40691, tol );
%!  assert ( sol.Nseg, 32.075, tol );
%!  assert ( sol.Tseg, 6.9091e+05, tol );
%!  assert ( sol.cr, 0.43838, tol );

## Recompute a S5 CasA solution given in Prix&Shaltev,PRD85,084010(2012), corrected in Shaltev thesis Eq.(4.119)
%!test
%!  UnitsConstants;
%!  refParams.Nseg = 100;
%!  refParams.Tseg = 86400;
%!  refParams.mc   = 0.5;
%!  refParams.mf   = 0.5;
%!
%!  costFuns = CostFunctionsDirected( ...
%!                                  "fmin", 100, ...
%!                                  "fmax", 300, ...
%!                                  "tau_min", 300 * YRSID_SI, ...
%!                                  "Ndet", 2 * 0.7, ...
%!                                  "resampling", false, ...
%!                                  "coh_c0_demod", 7e-8 / 1800, ...
%!                                  "inc_c0", 6e-9, ...
%!                                  "lattice", "Ans", ...
%!                                  "boundaryType", "S5CasA" ...
%!                                );
%!  cost0 = 472 * DAYS;
%!  TobsMax = 365 * DAYS;
%!
%!  sol = OptimalSolution4StackSlide ( "costFuns", costFuns, "cost0", cost0, "TobsMax", TobsMax, "stackparamsGuess", refParams, "sensApprox", "WSG" );
%!
%!  tol = -1e-2;
%! ##compare to reference values given in Shaltev thesis, Eq.(4.119) (adjusted for more accurate xi=mean(Ans) instead of xi~0.5)
%!  assert ( sol.mc, 0.18103, tol );
%!  assert ( sol.mf, 0.27120, tol );
%!  assert ( sol.Nseg, 61.711, tol );
%!  assert ( sol.Tseg, 2.0905e+05, tol );
%!  assert ( sol.cr, 1.0013, tol );


function [cost, Nt, lattice] = cost_coh_wparams ( Nseg, Tseg, mc, params )
  ## coherent cost function

  ## check input parameters
  [err, Nseg, Tseg, mc] = common_size(Nseg, Tseg, mc);
  assert(err == 0);

  ref_time = 1119599826;	## dummy, doesn't matter for directed search

  cost = Nt = zeros ( size ( Nseg )  );
  for i = 1:length(Nseg(:))

    if ( params.grid_interpolation )
      NsegCoh = 1;
    else
      NsegCoh = Nseg(i);
    endif

    Nt(i) = templateCountReal ( NsegCoh, Tseg(i), mc(i), params );

    if ( params.resampling )
      cost(i)  = Nseg(i) * Nt(i) * params.Ndet * params.coh_c0_resamp;
    else
      cost(i)  = Nseg(i) * Nt(i) * params.Ndet * (params.coh_c0_demod * Tseg(i));
    endif

  endfor

  lattice = params.lattice;

  return;

endfunction ## cost_coh_wparams()


function [cost, Nt, lattice] = cost_inc_wparams ( Nseg, Tseg, mf, params )
  ## incoherent cost function

  ## check input parameters
  [err, Nseg, Tseg, mf] = common_size(Nseg, Tseg, mf);
  assert(err == 0);

  ref_time = 1119599826;	## dummy, doesn't matter for directed search

  cost = Nt = zeros ( size ( Nseg )  );
  for i = 1:length(Nseg(:))
    Nt(i)   = templateCountReal ( Nseg(i), Tseg(i), mf(i), params );
    cost(i) = Nseg(i) * Nt(i) * params.inc_c0;
  endfor

  lattice = params.lattice;

  return;

endfunction ## cost_inc_wparams()


function bands = templateBankDims ( Nseg, Tseg, mismatch, params )

  tauNS = params.tau_min;
  n0    = params.brk_min;
  tau_n = (n0 -1)*tauNS;

  sMax = 3;
  %% fkMax(k) = kappa(k) * freq
  kappa(1) = 1  /tau_n;
  kappa(2) = n0 / tau_n^2;
  kappa(3) = n0*(2*n0 - 1) / tau_n^3;

  %% recompute template extents using metric directly
  for s = 1:sMax
    gij = frequencyMetric ( s, Nseg, Tseg );
    gInv_ss = det ( gij(1:s,1:s) ) / det(gij);
    df(s) = sqrt ( mismatch * gInv_ss );
    fCrit(s) = df(s) / kappa(s);

    if ( fCrit(s) >= params.fmax )	%% no higher orders possible
      break;
    endif
  endfor

  %% sort the transition frequencies 'fcrit' and find all that lie within [fmin, fmax],
  %% at those frequencies, we have to start a new frequency-band with different sMax maximal spindown orders
  fCritAll = unique ( fCrit );
  %% now find all 'pure' frequency-bands we can construct within [fmin, fmax], ie those where no transitions
  %% happen: these transitions are defined by fCrit as the boundaries. If no fCrit values fall within [fmin, fmax]
  %% then that whole band is 'pure'
  fCritInBand = fCritAll ( find ( (fCritAll > params.fmin) & (fCritAll < params.fmax) ) );
  numBands = length ( fCritInBand ) + 1;

  bounds = [ params.fmin, fCritInBand, params.fmax ];
  bands = zeros ( numBands, 3 );
  for i = 1:numBands
    f0i = bounds(i);
    f1i = bounds(i+1);
    sMax = length ( find ( fCrit < f1i ) );
    bands(i, :) = [ f0i, f1i, sMax ];
  endfor

  return;
endfunction ## templateBankDims()


function Nt = templateCountReal ( Nseg, Tseg, mismatch, params )
  %% compute number of templates of for directed search spaces
  %% for a given frequency band [fmin,fmax], allowing for variable spindown-orders over this band
  %% for given target- and search parameters, as determined by templateBankDims()
  %%
  %% params struct containing input arguments:
  %% 'fmin':		lower frequency bound
  %% 'fmax':		upper frequency bound
  %% 'lattice':		lattice type, currently allowed are {"Ans", "Zn"}
  %% 'tau_min':		spindown-age 'tau' in seconds
  %% 'brk_min':		(minimal) braking index used for spindown-bounds
  %%

  bands = templateBankDims ( Nseg, Tseg, mismatch, params );
  numBands = size ( bands, 1 );

  Nt = 0;
  for i = 1:numBands
    params_i = params;
    params_i.fmin = bands(i,1);
    params_i.fmax = bands(i,2);
    sMax_i = bands(i,3);

    Nt += templateCountPure ( Nseg, Tseg, mismatch, sMax_i, params_i );
  endfor

  return;

endfunction ## templateCountReal()

function Nt = templateCountPure ( Nseg, Tseg, mismatch, sMax, params )
  %% compute number of templates for directed search spaces
  %% for a "pure" frequency band [fmin,fmax], in the sense that the maximal spindown-order
  %% 'sMax' over this band is assumed to be fixed.
  %% use templateCountReal() for the realistic case of variable spindown-order over frequency
  %%
  %% extra arguments in 'params' struct:
  %% 'lattice':		lattice type, currently allowed are {"An*", "Zn"=hypercubic}
  %% 'fmin':		lower frequency bound
  %% 'fmax':		upper frequency bound
  %% 'tau_min':		spindown-age 'tau' in seconds
  %% 'brk_min':		(minimal) braking index used for spindown-bounds
  %%

  assert ( isscalar(sMax) && ( sMax == round(sMax)), "Invalid non-integer scalar 'sMax'\n");

  nDim = 1 + sMax;	%% template-bank dimension

  switch ( params.lattice )
    case "Ans"
      thickness = AnsNormalizedThickness ( nDim );
    case "Zn"
      thickness = ZnNormalizedThickness ( nDim );
    otherwise
      error ("Invalid lattice type '%s', allowed are {'Ans', 'Zn'}\n", params.lattice );
  endswitch

  vol_s = coordinateVolume ( sMax, params );
  gss = frequencyMetric ( sMax, Nseg, Tseg );
  Nt = thickness * mismatch^(-nDim/2) * sqrt (det(gss)) * vol_s;

  return;

endfunction

function gss = frequencyMetric ( sMax, Nseg, Tseg )
  %% compute metric g_{ss'} in frequency-space: f^{(s)}(tRef), in SI units
  %%
  %% input arguments:
  %% 'sMax':		maximal spindown-order, so the metric dimension is nDim = sMax + 1
  %%
  %% Default reference time is the mean segment mid-time over all segments.
  %%

  gssnat = frequencyMetricNat ( sMax, Nseg, Tseg );

  conv1 = invNatUnit(0:sMax, Tseg);

  convert = conv1' * conv1;

  gss = gssnat .* convert;

  return;
endfunction ## frequencyMetric()


function ret = frequencyMetricNat ( sMax, Nseg, Tseg )
  %% compute metric g_{ss'} in frequency-space: f^{(s)}(tRef),
  %% in natural units om^{(s)} = 2pi f^{(s)}/(s+1)! (Tseg/2)^(s+1),
  %% where Tseg is the segment length
  %%
  %%  input arguments:
  %% 'sMax':		maximal spindown-order, so the metric dimension is nDim = sMax + 1
  %%
  %% Default reference time is the mean segment mid-time over all segments.
  %%

  %% ----- check input consistency
  assert ( isscalar(sMax) && ( sMax == round(sMax)), "Invalid non-integer scalar 'sMax'\n");
  assert ( ( sMax >= 0) && (sMax <= 3), "The maximal spindown-order 'sMax'=%d must be in the range {0,..,3}!", sMax );

  if ( Nseg == 1 )	%% coherent metric
    D = zeros ( 1, 6 );
  else
    D2 = 1/3 * ( Nseg^2 - 1);
    D4 = D2 * (3*Nseg^2 - 7)/5;
    D6 = D2 * ( 3*Nseg^4 - 18*Nseg^2 + 31 ) / 7;
    D = [ 0, D2, 0, D4, 0, D6 ];
  endif

  %% HACK required to correctly describe GCT-code behaviour: need finer coarse-grid in f2dot by factor of "finef2"
  global finef2 = 1;	## default=1 but won't change if set in global context already
  %% ----- use this only for coherent metrics ----------
  ff2 = 1;
  if ( Nseg == 1 )
    ff2 = finef2;
  endif

  %% ----- coherent metric in natural units with refTime = midTime
  g4D = [ 1/3,     0, 1/5,     0 ;
            0,  4/45,   0,  8/105;
          1/5,     0, 1/7 * ff2^2,      0;
            0, 8/105,   0, 16/225;
        ];

  %% ----- semi-coherent contributions adding onto coherent metric elements
  d11 = (4/3) * D(2);
  d22 = 3 * D(4) + 2 * D(2);
  d33 = (16/3) * D(6) + (48/5) * D(4) + (16/5) * D(2);

  d02 = D(2);
  d03 = (4/3) * D(3);

  d12 = 2 * D(3);
  d13 = (8/3) * D(4) + (32/15) * D(2);

  d23 = 4 * D(5) + (24/5) * D(3);

  g4SC = [  0,     0,  d02,  d03;
            0,   d11,  d12,  d13;
          d02,   d12,  d22,  d23;
          d03,   d13,  d23,  d33;
          ];

  n = 1 + sMax;	%% template-bank dimension
  gij = (g4D + g4SC) ( 1:n, 1:n );

  %% enforce strict symmetric matrix (compensate roundoff troubles...)
  ret = 0.5 * ( gij + gij' );

  return;

endfunction ## frequencyMetricNat()


function ret = invNatUnit (sMax, Tseg)
  %% metric conversion factor of dimension n= 1 + sMax
  %% from natural units back into 'physical' units
  n = 1 + sMax;

  ret = (2*pi) * (Tseg/2).^n ./ factorial(n);

  return;
endfunction %% invNatUnit()

function vol = coordinateVolume ( sMax, params )
  %% compute the coordinate template-bank volume (in SI units) for a directed-search space
  %% of maximal spindown-order 'sMax', spindown-age 'tau', and a frequency-range [fmin, fmax],
  %% using either params.boundaryType:
  %% "EaHCasA": search space construction used in the E@H search 'S6CasA' ('square in {fdot,f2dot}, grows with f)
  %% "S5CasA": Karl's S5 search space construction used in first CasA search ('fdot=fdot(f), f2dot=f2dot(f,f1dot)')

  sMaxMax = 3;
  assert ( sMax <= sMaxMax, "Maximal spindown-order currently limited to sMax <= %d\n", sMaxMax );
  assert ( sMax == round(sMax), "Spindown order 'sMax = %g' must be integer!\n", sMax );

  switch ( params.boundaryType )
    case "EaHCasA"
      tau0 = ( params.brk_min - 1 ) * params.tau_min;
      Vn = [ ...
             params.fmax - params.fmin, ...
             1/tau0 * 1/2 * ( params.fmax^2 - params.fmin^2 ), ...
             params.brk_min / tau0^3 * 1/3 * ( params.fmax^3 - params.fmin^3 ), ...
             params.brk_min^2 * ( 2*params.brk_min - 1) / tau0^6 * 1/4 * ( params.fmax^4 - params.fmin^4 ) ...
           ];
    case "S5CasA"
      Vn = [ ...
             params.fmax - params.fmin, ...
             5/(12 * params.tau_min) * ( params.fmax^2 - params.fmin^2 ), ...
             V3 = 5/9 * (params.fmax^3/params.tau_min^3), ...
             V3 * params.fmax / params.tau_min^3, ...  ## for 3rd spindown use coarse BC-type estimate of param-space size
           ];
    otherwise
      error ("Unknown boundaryType = '%s': allowed are {'EaHCasA', 'S5CasA'}\n", params.boundaryType );
  endswitch

  vol = Vn(1 + sMax);
  return;

endfunction
