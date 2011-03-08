/*
 * jQuery expanding textarea
 * 
 * https://github.com/ferama/jquery-expanding-textarea
 * 
 * Adapted for jQuery from dojo TextArea widget
 *
 * @author Marco Ferragina
 * @version 1.00
 */

(function($) {

$.fn.expandingTextArea = function() {
    return this.filter('textarea').each(function(){
        var textarea = this;
        var $this = $(this);
        $this.css({
            'overflow-x': 'auto',
            'overflow-y': 'hidden',
            'box-sizing': 'border-box',
            '-moz-box-sizing': 'border-box',
            '-webkit-box-sizing': 'border-box',
            'resize' : 'none'
        });
        var _busyResizing = false;
        var _needsHelpShrinking = $.browser.mozilla || $.browser.webkit;
        var _setTimoutHandle;

        var gcs;

        if ($.browser.webkit) {
            gcs = function(node) {
                var s;
                if(node.nodeType == 1){
                    var dv = node.ownerDocument.defaultView;
                    s = dv.getComputedStyle(node, null);
                    if(!s && node.style){
                        node.style.display = "";
                        s = dv.getComputedStyle(node, null);
                    }
                }
                return s || {};
            };
        } else if ($.browser.msie) {
            gcs = function(node){
                // IE (as of 7) doesn't expose Element like sane browsers
                return node.nodeType == 1 /* ELEMENT_NODE*/ ? node.currentStyle : {};
            };
        } else {
            gcs = function(node){
                return node.nodeType == 1 ?
                    node.ownerDocument.defaultView.getComputedStyle(node, null) : {};
            };
        }

        var px;
        if (!$.browser.msie) {
            px = function(element, value) {
                return parseFloat(value) || 0;
            };
        } else {
            px = function(element, avalue) {
                if(!avalue){ return 0; }
                // on IE7, medium is usually 4 pixels
                if(avalue == "medium"){ return 4; }
                // style values can be floats, client code may
                // want to round this value for integer pixels.
                if(avalue.slice && avalue.slice(-2) == 'px'){ return parseFloat(avalue); }
                with(element){
                    var sLeft = style.left;
                    var rsLeft = runtimeStyle.left;
                    runtimeStyle.left = currentStyle.left;
                    try{
                        // 'avalue' may be incompatible with style.left, which can cause IE to throw
                        // this has been observed for border widths using "thin", "medium", "thick" constants
                        // those particular constants could be trapped by a lookup
                        // but perhaps there are more
                        style.left = avalue;
                        avalue = style.pixelLeft;
                    }catch(e){
                        avalue = 0;
                    }
                    style.left = sLeft;
                    runtimeStyle.left = rsLeft;
                }
                return avalue;
            };
        }

        function _getHeight() {
            var newH = textarea.scrollHeight;
            if ($.browser.msie) {
                newH += textarea.offsetHeight - textarea.clientHeight;
            } else if ($.browser.webkit) {
                newH += getBorderExtents(textarea).h;
            } else if ($.browser.mozilla) {
                newH += textarea.offsetHeight - textarea.clientHeight;
            } else {
                newH += getPadBorderExtents(textarea).h;
            }
            return newH;
        }
        function getPadExtents(n, computedStyle) {
            var
                s = computedStyle||gcs(n),
                l = px(n, s.paddingLeft),
                t = px(n, s.paddingTop);
            return {
                l: l,
                t: t,
                w: l+px(n, s.paddingRight),
                h: t+px(n, s.paddingBottom)
            };
 
        }
        function getBorderExtents(n, computedStyle) {
            var 
                ne = "none",
                s = computedStyle||gcs(n),
                bl = (s.borderLeftStyle != ne ? px(n, s.borderLeftWidth) : 0),
                bt = (s.borderTopStyle != ne ? px(n, s.borderTopWidth) : 0);
            return {
                l: bl,
                t: bt,
                w: bl + (s.borderRightStyle!=ne ? px(n, s.borderRightWidth) : 0),
                h: bt + (s.borderBottomStyle!=ne ? px(n, s.borderBottomWidth) : 0)
            };
        }
        function getPadBorderExtents(n, computedStyle) {
            var 
                s = computedStyle||gcs(n),
                p = getPadExtents(n, s),
                b = getBorderExtents(n, s);
            return {
                l: p.l + b.l,
                t: p.t + b.t,
                w: p.w + b.w,
                h: p.h + b.h
            };
        }

        function _shrink() {
            _setTimoutHandle = null;
            if (_needsHelpShrinking && ! _busyResizing) {
                _busyResizing = true;
                var empty = false;
                if(textarea.value == ''){
                    textarea.value = ' '; // prevent collapse all the way back to 0
                    empty = true;
                }
                var scrollHeight = textarea.scrollHeight;
                if (!scrollHeight) {
                    _estimateHeight();
                } else {
                    var oldPadding = $this.css('padding-bottom');
                    var newPadding = getPadExtents(textarea);
                    newPadding = newPadding.h - newPadding.t;
                    $this.css('padding-bottom', newPadding + 1 +"px");
                    var newH = _getHeight() - 1 + "px";
                    if ($this.css('max-height') != newH) {
                        $this.css('padding-bottom', newPadding + scrollHeight + "px");
                        textarea.scrollTop = 0;
                        $this.css('max-height', _getHeight() - scrollHeight + "px");
                    }
                    $this.css('padding-bottom', oldPadding);
                }
                if(empty){
                    textarea.value = '';
                }
                _busyResizing = false;
            }
        }

        function _estimateHeight() {
            $this.css({
                'max-height': '',
                'height': 'auto'
            });
            textarea.rows = (textarea.value.match(/\n/g) || []).length + 1;
        }

        function _onInput() {
            if (_busyResizing) { return; }
            _busyResizing = true;
            if(textarea.scrollHeight && textarea.offsetHeight && textarea.clientHeight){
                var newH = _getHeight() + "px";
                if ($this.css('height') != newH) {
                    $this.css('height', newH);
                    $this.css('maxHeight', newH);
                }
                if (_needsHelpShrinking) {
                    if (_setTimoutHandle) {
                        clearTimeout(_setTimoutHandle);
                    }
                    _setTimoutHandle = setTimeout(_shrink, 0);
                }
            } else {
                _estimateHeight();
            }
            _busyResizing = false;
        }

        _setTimoutHandle = setTimeout(_onInput, 0);
        $this.unbind('.expandingTextarea')
            .bind('keyup.expandingTextarea', _onInput)
            .bind('keydown.expandingTextarea', _onInput)
            .bind('change.expandingTextarea', _onInput)
            .bind('scroll.expandingTextarea', _onInput)
            .bind('resize.expandingTextarea', _onInput)
            .bind('focus.expandingTextarea', _onInput)
            .bind('blur.expandingTextarea', _onInput)
            .bind('cut.expandingTextarea', _onInput)
            .bind('paste.expandingTextarea', _onInput);
    });
};

})(jQuery);
