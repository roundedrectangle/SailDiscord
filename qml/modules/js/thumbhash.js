.pragma library

/*
    Copyright (c) 2023 Evan Wallace

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Compiled for ES5 using Babel (https://babeljs.io/repl).
*/

function _slicedToArray(r, e) { return _arrayWithHoles(r) || _iterableToArrayLimit(r, e) || _unsupportedIterableToArray(r, e) || _nonIterableRest(); }
function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }
function _unsupportedIterableToArray(r, a) { if (r) { if ("string" == typeof r) return _arrayLikeToArray(r, a); var t = {}.toString.call(r).slice(8, -1); return "Object" === t && r.constructor && (t = r.constructor.name), "Map" === t || "Set" === t ? Array.from(r) : "Arguments" === t || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t) ? _arrayLikeToArray(r, a) : void 0; } }
function _arrayLikeToArray(r, a) { (null == a || a > r.length) && (a = r.length); for (var e = 0, n = Array(a); e < a; e++) n[e] = r[e]; return n; }
function _iterableToArrayLimit(r, l) { var t = null == r ? null : "undefined" != typeof Symbol && r[Symbol.iterator] || r["@@iterator"]; if (null != t) { var e, n, i, u, a = [], f = !0, o = !1; try { if (i = (t = t.call(r)).next, 0 === l) { if (Object(t) !== t) return; f = !1; } else for (; !(f = (e = i.call(t)).done) && (a.push(e.value), a.length !== l); f = !0); } catch (r) { o = !0, n = r; } finally { try { if (!f && null != t["return"] && (u = t["return"](), Object(u) !== u)) return; } finally { if (o) throw n; } } return a; } }
function _arrayWithHoles(r) { if (Array.isArray(r)) return r; }
/**
 * Decodes a ThumbHash to an RGBA image. RGB is not be premultiplied by A.
 *
 * @param hash The bytes of the ThumbHash.
 * @returns The width, height, and pixels of the rendered placeholder image.
 */
function thumbHashToRGBA(hash) {
  var PI = Math.PI,
    min = Math.min,
    max = Math.max,
    cos = Math.cos,
    round = Math.round;

  // Read the constants
  var header24 = hash[0] | hash[1] << 8 | hash[2] << 16;
  var header16 = hash[3] | hash[4] << 8;
  var l_dc = (header24 & 63) / 63;
  var p_dc = (header24 >> 6 & 63) / 31.5 - 1;
  var q_dc = (header24 >> 12 & 63) / 31.5 - 1;
  var l_scale = (header24 >> 18 & 31) / 31;
  var hasAlpha = header24 >> 23;
  var p_scale = (header16 >> 3 & 63) / 63;
  var q_scale = (header16 >> 9 & 63) / 63;
  var isLandscape = header16 >> 15;
  var lx = max(3, isLandscape ? hasAlpha ? 5 : 7 : header16 & 7);
  var ly = max(3, isLandscape ? header16 & 7 : hasAlpha ? 5 : 7);
  var a_dc = hasAlpha ? (hash[5] & 15) / 15 : 1;
  var a_scale = (hash[5] >> 4) / 15;

  // Read the varying factors (boost saturation by 1.25x to compensate for quantization)
  var ac_start = hasAlpha ? 6 : 5;
  var ac_index = 0;
  var decodeChannel = function decodeChannel(nx, ny, scale) {
    var ac = [];
    for (var cy = 0; cy < ny; cy++) for (var cx = cy ? 0 : 1; cx * ny < nx * (ny - cy); cx++) ac.push(((hash[ac_start + (ac_index >> 1)] >> ((ac_index++ & 1) << 2) & 15) / 7.5 - 1) * scale);
    return ac;
  };
  var l_ac = decodeChannel(lx, ly, l_scale);
  var p_ac = decodeChannel(3, 3, p_scale * 1.25);
  var q_ac = decodeChannel(3, 3, q_scale * 1.25);
  var a_ac = hasAlpha && decodeChannel(5, 5, a_scale);

  // Decode using the DCT into RGB
  var ratio = thumbHashToApproximateAspectRatio(hash);
  var w = round(ratio > 1 ? 32 : 32 * ratio);
  var h = round(ratio > 1 ? 32 / ratio : 32);
  var rgba = new Uint8Array(w * h * 4),
    fx = [],
    fy = [];
  for (var y = 0, i = 0; y < h; y++) {
    for (var x = 0; x < w; x++, i += 4) {
      var l = l_dc,
        p = p_dc,
        q = q_dc,
        a = a_dc;

      // Precompute the coefficients
      for (var cx = 0, n = max(lx, hasAlpha ? 5 : 3); cx < n; cx++) fx[cx] = cos(PI / w * (x + 0.5) * cx);
      for (var cy = 0, _n = max(ly, hasAlpha ? 5 : 3); cy < _n; cy++) fy[cy] = cos(PI / h * (y + 0.5) * cy);

      // Decode L
      for (var _cy = 0, j = 0; _cy < ly; _cy++) for (var _cx = _cy ? 0 : 1, fy2 = fy[_cy] * 2; _cx * ly < lx * (ly - _cy); _cx++, j++) l += l_ac[j] * fx[_cx] * fy2;

      // Decode P and Q
      for (var _cy2 = 0, _j = 0; _cy2 < 3; _cy2++) {
        for (var _cx2 = _cy2 ? 0 : 1, _fy = fy[_cy2] * 2; _cx2 < 3 - _cy2; _cx2++, _j++) {
          var f = fx[_cx2] * _fy;
          p += p_ac[_j] * f;
          q += q_ac[_j] * f;
        }
      }

      // Decode A
      if (hasAlpha) for (var _cy3 = 0, _j2 = 0; _cy3 < 5; _cy3++) for (var _cx3 = _cy3 ? 0 : 1, _fy2 = fy[_cy3] * 2; _cx3 < 5 - _cy3; _cx3++, _j2++) a += a_ac[_j2] * fx[_cx3] * _fy2;

      // Convert to RGB
      var b = l - 2 / 3 * p;
      var r = (3 * l - b + q) / 2;
      var g = r - q;
      rgba[i] = max(0, 255 * min(1, r));
      rgba[i + 1] = max(0, 255 * min(1, g));
      rgba[i + 2] = max(0, 255 * min(1, b));
      rgba[i + 3] = max(0, 255 * min(1, a));
    }
  }
  return {
    w: w,
    h: h,
    rgba: rgba
  };
}

/**
 * Extracts the approximate aspect ratio of the original image.
 *
 * @param hash The bytes of the ThumbHash.
 * @returns The approximate aspect ratio (i.e. width / height).
 */
function thumbHashToApproximateAspectRatio(hash) {
  var header = hash[3];
  var hasAlpha = hash[2] & 0x80;
  var isLandscape = hash[4] & 0x80;
  var lx = isLandscape ? hasAlpha ? 5 : 7 : header & 7;
  var ly = isLandscape ? header & 7 : hasAlpha ? 5 : 7;
  return lx / ly;
}

/**
 * Encodes an RGBA image to a PNG data URL. RGB should not be premultiplied by
 * A. This is optimized for speed and simplicity and does not optimize for size
 * at all. This doesn't do any compression (all values are stored uncompressed).
 *
 * @param w The width of the input image. Must be ≤100px.
 * @param h The height of the input image. Must be ≤100px.
 * @param rgba The pixels in the input image, row-by-row. Must have w*h*4 elements.
 * @returns A data URL containing a PNG for the input image.
 */
function rgbaToDataURL(w, h, rgba) {
  var row = w * 4 + 1;
  var idat = 6 + h * (5 + row);
  var bytes = [137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, w >> 8, w & 255, 0, 0, h >> 8, h & 255, 8, 6, 0, 0, 0, 0, 0, 0, 0, idat >>> 24, idat >> 16 & 255, idat >> 8 & 255, idat & 255, 73, 68, 65, 84, 120, 1];
  var table = [0, 498536548, 997073096, 651767980, 1994146192, 1802195444, 1303535960, 1342533948, -306674912, -267414716, -690576408, -882789492, -1687895376, -2032938284, -1609899400, -1111625188];
  var a = 1,
    b = 0;
  for (var y = 0, i = 0, end = row - 1; y < h; y++, end += row - 1) {
    bytes.push(y + 1 < h ? 0 : 1, row & 255, row >> 8, ~row & 255, row >> 8 ^ 255, 0);
    for (b = (b + a) % 65521; i < end; i++) {
      var u = rgba[i] & 255;
      bytes.push(u);
      a = (a + u) % 65521;
      b = (b + a) % 65521;
    }
  }
  bytes.push(b >> 8, b & 255, a >> 8, a & 255, 0, 0, 0, 0, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130);
  for (var _i = 0, _arr = [[12, 29], [37, 41 + idat]]; _i < _arr.length; _i++) {
    var _arr$_i = _slicedToArray(_arr[_i], 2),
      start = _arr$_i[0],
      _end = _arr$_i[1];
    var c = ~0;
    for (var _i2 = start; _i2 < _end; _i2++) {
      c ^= bytes[_i2];
      c = c >>> 4 ^ table[c & 15];
      c = c >>> 4 ^ table[c & 15];
    }
    c = ~c;
    bytes[_end++] = c >>> 24;
    bytes[_end++] = c >> 16 & 255;
    bytes[_end++] = c >> 8 & 255;
    bytes[_end++] = c & 255;
  }
  /*var binary = "";
  for (i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i] & 255);
  }
  return 'data:image/png;base64,' + Qt.btoa(binary);*/
  return 'data:image/png;base64,' + Qt.btoa(String.fromCharCode.apply(String, bytes));
}

/**
 * Decodes a ThumbHash to a PNG data URL. This is a convenience function that
 * just calls "thumbHashToRGBA" followed by "rgbaToDataURL".
 *
 * @param hash The bytes of the ThumbHash.
 * @returns A data URL containing a PNG for the rendered ThumbHash.
 */
function thumbHashToDataURL(hash) {
  var image = thumbHashToRGBA(hash);
  return rgbaToDataURL(image.w, image.h, image.rgba);
}


function base64ToBinary(base64) {
  return new Uint8Array(Qt.atob(base64).split('').map(function (x) {
    return x.charCodeAt(0)
  }))
}

function thumbHashBase64ToDataUrl(base64) {
    return thumbHashToDataURL(base64ToBinary(base64))
}
