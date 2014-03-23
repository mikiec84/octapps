## Copyright (C) 2014 Karl Wette
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

## Compute the metric ellipse bounding box, given a metric and max. mismatch
## Usage:
##   bound_box = metricBoundingBox(metric, max_mismatch)

function bound_box = metricBoundingBox(metric, max_mismatch)

  ## check input
  assert(issymmetric(metric) > 0);
  assert(isscalar(max_mismatch) && max_mismatch > 0);

  ## diagonally normalise metric and calculate bounding box
  [D_metric, DN_metric] = DiagonalNormaliseMetric(metric);
  bound_box = 2 .* diag(DN_metric) .* sqrt(max_mismatch .* diag(inv(D_metric)));

endfunction
