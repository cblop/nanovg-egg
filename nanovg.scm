;; -*- geiser-scheme-implementation: 'chicken -*-

(import foreign srfi-4)

(foreign-declare #<<ENDC
#include <GL/gl.h>
#include "nanovg/src/nanovg.h"
#include "nanovg/src/nanovg_gl.h"
#include <string.h>
ENDC
)

(define-syntax define-foreign-enum
  (syntax-rules ()
    ((define-foreign-enum name c-name)
     (define name (foreign-value c-name integer)))))

(define-foreign-enum create/anti-alias "NVG_ANTIALIAS")
(define-foreign-enum create/stencil-strokes "NVG_STENCIL_STROKES")
(define-foreign-enum create/debug "NVG_DEBUG")

(define-foreign-enum winding/ccw "NVG_CCW")
(define-foreign-enum winding/cw "NVG_CW")

(define-foreign-enum solidity/solid "NVG_SOLID")
(define-foreign-enum solidity/hole "NVG_HOLE")

(define-foreign-enum line-cap/butt "NVG_BUTT")
(define-foreign-enum line-cap/round "NVG_ROUND")
(define-foreign-enum line-cap/square "NVG_SQUARE")
(define-foreign-enum line-cap/bevel "NVG_BEVEL")
(define-foreign-enum line-cap/miter "NVG_MITER")

(define-foreign-enum align/left "NVG_ALIGN_LEFT")
(define-foreign-enum align/center "NVG_ALIGN_CENTER")
(define-foreign-enum align/right "NVG_ALIGN_RIGHT")
(define-foreign-enum align/top "NVG_ALIGN_TOP")
(define-foreign-enum align/middle "NVG_ALIGN_MIDDLE")
(define-foreign-enum align/bottom "NVG_ALIGN_BOTTOM")
(define-foreign-enum align/baseline "NVG_ALIGN_BASELINE")

(define-foreign-enum image/generate-mipmaps "NVG_IMAGE_GENERATE_MIPMAPS")
(define-foreign-enum image/repeat-x "NVG_IMAGE_REPEATX")
(define-foreign-enum image/repeat-y "NVG_IMAGE_REPEATY")
(define-foreign-enum image/flip-y "NVG_IMAGE_FLIPY")
(define-foreign-enum image/premultiplied "NVG_IMAGE_PREMULTIPLIED")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Context
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-foreign-type context (c-pointer (struct "NVGcontext")))

(define create-context*
  (cond-expand
    (nanovg-gl2 (foreign-lambda context "nvgCreateGL2" int))
    (nanovg-gl3 (foreign-lambda context "nvgCreateGL3" int))
    (nanovg-gles2 (foreign-lambda context "nvgCreateGLES2" int))
    (nanovg-gles3 (foreign-lambda context "nvgCreateGLES3" int))))

(define delete-context!
  (cond-expand
    (nanovg-gl2 (foreign-lambda void "nvgDeleteGL2" context))
    (nanovg-gl3 (foreign-lambda void "nvgDeleteGL3" context))
    (nanovg-gles2 (foreign-lambda void "nvgDeleteGLES2" context))
    (nanovg-gles3 (foreign-lambda void "nvgDeleteGLES3" context))))

(define (create-context #!key (anti-alias #f) (stencil-strokes #f) (debug #f) (flags #f))
  (let* ((flags
	  (or flags
	      (+ (if anti-alias create/anti-alias 0)
		 (if stencil-strokes create/stencil-strokes 0)
		 (if debug create/debug 0))))
	 (ctx (create-context* flags)))
    (set-finalizer! ctx delete-context!)
    ctx))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Color
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-foreign-type color (c-pointer (struct "NVGcolor")))

(define-syntax make-color-uninitialized
  (syntax-rules ()
    ((make-color-uninitialized)
     (make-blob (foreign-type-size "NVGcolor")))))

(define (make-color-rgb r g b)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (unsigned-char r) (unsigned-char g) (unsigned-char b)) "*clr = nvgRGB(r, g, b);") color r g b)
    color))

(define (make-color-rgbf r g b)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (float r) (float g) (float b)) "*clr = nvgRGBf(r, g, b);") color r g b)
    color))

(define (make-color-rgba r g b a)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (unsigned-char r) (unsigned-char g) (unsigned-char b) (unsigned-char a)) "*clr = nvgRGBA(r, g, b, a);") color r g b a)
    color))

(define (make-color-rgbaf r g b a)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (float r) (float g) (float b) (float a)) "*clr = nvgRGBAf(r, g, b, a);") color r g b a)
    color))

(define (make-color-lerp clr1 clr2 u)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (color clr1) (color clr2) (float u)) "*clr = nvgLerpRGBA(*clr1, *clr2, u);") color clr1 clr2 u)
    color))

(define (make-color-transparency clr a)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (color clr1) (unsigned-char a)) "*clr = nvgTransRGBA(*clr1, a);") color clr a)
    color))

(define (make-color-transparencyf clr a)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (color clr1) (float a)) "*clr = nvgTransRGBAf(*clr1, a);") color clr a)
    color))

(define (make-color-hsl h s l)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (float h) (float s) (float l)) "*clr = nvgHSL(h, s, l);") color h s l)
    color))

(define (make-color-hsla h s l a)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((color clr) (float h) (float s) (float l) (float a)) "*clr = nvgHSLA(h, s, l, a);") color h s l a)
    color))

(define color-red
  (foreign-lambda* float ((color clr)) "C_return(clr->r);"))

(define color-green
  (foreign-lambda* float ((color clr)) "C_return(clr->g);"))

(define color-blue
  (foreign-lambda* float ((color clr)) "C_return(clr->b);"))

(define color-alpha
  (foreign-lambda* float ((color clr)) "C_return(clr->a);"))

(define (color-rgba color)
  (let ((buf (make-f32vector 4)))
    ((foreign-lambda* void ((color clr) (f32vector buf)) "memcpy(buf, clr->rgba, sizeof(float) * 4);") color buf)
    buf))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Paint
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-foreign-type paint (c-pointer (struct "NVGpaint")))

(define (paint-transform paint)
  (let ((buf (make-f32vector 6)))
    ((foreign-lambda* void ((paint p) (f32vector buf)) "memcpy(buf, p->xform, sizeof(float) * 6);") paint buf)
    buf))

(define (paint-extent paint)
  (let ((buf (make-f32vector 2)))
    ((foreign-lambda* void ((paint p) (f32vector buf)) "memcpy(buf, p->extent, sizeof(float) *2);") paint buf)
    buf))

(define paint-radius
  (foreign-lambda* float ((paint p)) "C_return(p->radius);"))

(define paint-feather
  (foreign-lambda* float ((paint p)) "C_return(p->feather);"))

(define (paint-inner-color paint)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((paint p) (color c)) "memcpy(c, &p->innerColor, sizeof(NVGcolor));") paint color)
    color))

(define (paint-outer-color paint)
  (let ((color (make-color-uninitialized)))
    ((foreign-lambda* void ((paint p) (color c)) "memcpy(c, &p->outerColor, sizeof(NVGcolor));") paint color)
    color))

(define paint-image
  (foreign-lambda* integer ((paint p)) "C_return(p->image);"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Glyph Position
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-foreign-type glyph-position (c-pointer (struct "NVGglyphPosition")))

(define glyph-position-pointer
  (foreign-lambda* (const c-pointer) ((glyph-position gp)) "C_return(gp->str);"))

(define glyph-position-x
  (foreign-lambda* float ((glyph-position gp)) "C_return(gp->x);"))

(define glyph-position-minx
  (foreign-lambda* float ((glyph-position gp)) "C_return(gp->minx);"))

(define glyph-position-maxx
  (foreign-lambda* float ((glyph-position gp)) "C_return(gp->maxx);"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Text Row
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-foreign-type text-row (c-pointer (struct "NVGtextRow")))

(define text-row-start-pointer
  (foreign-lambda* (const c-pointer) ((text-row tr)) "C_return(tr->start);"))

(define text-row-end-pointer
  (foreign-lambda* (const c-pointer) ((text-row tr)) "C_return(tr->end);"))

(define text-row-next-pointer
  (foreign-lambda* (const c-pointer) ((text-row tr)) "C_return(tr->next);"))

(define text-row-width
  (foreign-lambda* float ((text-row tr)) "C_return(tr->width);"))

(define text-row-minx
  (foreign-lambda* float ((text-row tr)) "C_return(tr->minx);"))

(define text-row-maxx
  (foreign-lambda* float ((text-row tr)) "C_return(tr->maxx);"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Frame Control
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define begin-frame
  (foreign-lambda void "nvgBeginFrame" context integer integer float))

(define cancel-frame
  (foreign-lambda void "nvgCancelFrame" context))

(define end-frame
  (foreign-lambda void "nvgEndFrame" context))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define save-state
  (foreign-lambda void "nvgSave" context))

(define restore-state
  (foreign-lambda void "nvgRestore" context))

(define reset-state
  (foreign-lambda void "nvgReset" context))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Render Styles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define stroke-color
  (foreign-lambda* void ((context ctx) (color clr)) "nvgStrokeColor(ctx, *clr);"))

(define stroke-paint
  (foreign-lambda* void ((context ctx) (paint pnt)) "nvgStrokePaint(ctx, *pnt);"))

(define fill-color
  (foreign-lambda* void ((context ctx) (color clr)) "nvgFillColor(ctx, *clr);"))

(define fill-paint
  (foreign-lambda* void ((context ctx) (paint pnt)) "nvgFillPaint(ctx, *pnt);"))

(define miter-limit
  (foreign-lambda void "nvgMiterLimit" context float))

(define stroke-width
  (foreign-lambda void "nvgStrokeWidth" context float))

(define line-cap
  (foreign-lambda void "nvgLineCap" context integer))

(define line-join
  (foreign-lambda void "nvgLineJoin" context integer))

(define global-alpha
  (foreign-lambda void "nvgGlobalAlpha" context float))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Transforms
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-foreign-type transform f32vector)

(define reset-transform
  (foreign-lambda void "nvgResetTransform" context))

(define transform
  (foreign-lambda* void ((context ctx) (transform t)) "nvgTransform(ctx, t[0], t[1], t[2], t[3], t[4], t[5]);"))

(define translate
  (foreign-lambda void "nvgTranslate" context float float))

(define rotate
  (foreign-lambda void "nvgRotate" context float))

(define skew-x
  (foreign-lambda void "nvgSkewX" context float))

(define skew-y
  (foreign-lambda void "nvgSkewY" context float))

(define scale
  (foreign-lambda void "nvgScale" context float float))

(define (make-transform)
  (make-f32vector 6))

(define (current-transform context)
  (let ((buf (make-transform)))
    ((foreign-lambda void "nvgCurrentTransform" context transform) context buf)
    buf))

(define transform-identity
  (foreign-lambda void "nvgTransformIdentity" transform))

(define transform-translate
  (foreign-lambda void "nvgTransformTranslate" transform float float))

(define transform-scale
  (foreign-lambda void "nvgTransformScale" transform float float))

(define transform-rotate
  (foreign-lambda void "nvgTransformRotate" transform float))

(define transform-skew-x
  (foreign-lambda void "nvgTransformSkewX" transform float))

(define transform-skew-y
  (foreign-lambda void "nvgTransformSkewY" transform float))

(define (transform-multiply t1 t2)
  ((foreign-lambda void "nvgTransformMultiply" transform (const transform)) t1 t2)
  t1)

(define (transform-premultiply t1 t2)
  ((foreign-lambda void "nvgTransformPremultiply" transform (const transform)) t1 t2)
  t1)

(define (transform-point transform x y)
  (let-location ((dx float)
		 (dy float))
    ((foreign-lambda void "nvgTransformPoint" (c-pointer float) (c-pointer float) (const transform) float float) (location dx) (location dy) transform x y)
    (values dx dy)))

(define degrees-to-radians
  (foreign-lambda float "nvgDegToRad" float))

(define radians-to-degrees
  (foreign-lambda float "nvgRadToDeg" float))
