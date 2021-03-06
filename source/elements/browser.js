/*
 * See the NOTICE file distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 *
 */

// #ifdef __AMLBROWSER || __INC_ALL
// #define __WITH_PRESENTATION 1

/**
 * Element displaying the rendered contents of an URL.
 *
 * @constructor
 * @addnode elements:browser
 * @define browser
 *
 * @inherits apf.XForms
 * @inherits apf.StandardBinding
 * @inherits apf.DataAction
 *
 * @author      Ruben Daniels (ruben AT javeline DOT com)
 * @version     %I%, %G%
 * @since       0.4
 *
 * @binding value  Determines the way the value for the element is retrieved 
 * from the bound data.
 * Example (BROKEN):
 * Sets the url based on data loaded into this component.
 * <code>
 *  <a:model id="mdlBrowser">
 *      <data url="http://www.w3c.org"></data>
 *  </a:model>
 *  <a:browser 
 *    model  = "mdlBrowser" 
 *    width  = "800" 
 *    height = "600" 
 *    value  = "[@url]" />
 * </code>
 * Example:
 * A shorter way to write this is:
 * <code>
 *  <a:model id="mdlBrowser">
 *      <data url="http://www.w3c.org"></data>
 *  </a:model>
 *  <a:browser 
 *    width  = "800" 
 *    height = "600" 
 *    value  = "[mdlBrowser::@url]" />
 * </code>
 */
apf.browser = function(struct, tagName){
    this.$init(tagName || "browser", apf.NODE_VISIBLE, struct);
};
(function(){
    this.implement(
        // #ifdef __WITH_XFORMS
        //apf.XForms,
        // #endif
        //#ifdef __WITH_DATAACTION
        apf.DataAction
        //#endif
        // #ifdef __WITH_DATABINDING
        ,apf.StandardBinding
        // #endif
    );

    /**
     * @attribute {String} src   the url to be displayed in this element
     * @attribute {String} value alias for the 'url' attribute
     */
    this.$supportedProperties.push("value", "src");
    this.$propHandlers["src"]   =
    this.$propHandlers["value"] = function(value, force){
        try {
            this.$int.src = value || "about:blank";
        }
        catch(e) {
            this.$int.src = "about:blank";
        }
    };

    this.getValue = function() {
        return this.value || this.src;
    };

    /**
     * Retrieves the current url that is displayed.
     */
    this.getURL = function(){
        return this.$int.src;
    };

    /**
     * Browses to the previous page
     */
    this.back = function(){
        this.$int.contentWindow.history.back();
    };

    /**
     * Browses to the next page
     */
    this.forward = function(){
        this.$int.contentWindow.history.forward();
    };

    /**
     * Reload the current page
     */
    this.reload = function(){
        this.$int.src = this.$int.src;
    };

    /**
     * Print the currently displayed page
     */
    this.print = function(){
        this.$int.contentWindow.print();
    };

    /**
     * Execute a string of javascript on the page. This is subject to browser
     * security and will most likely only work when the browsed page is loaded
     * from the same domain.
     * @param {String}  str     javascript string to be executed.
     * @param {Boolean} noError whether the execution can throw an exception. Defaults to false.
     */
    this.runCode = function(str, noError){
        if (noError) {
            try {
                this.$int.contentWindow.eval(str);
            } catch(e) {}
        }
        else {
            this.$int.contentWindow.eval(str);
        }
    };

    this.$draw = function(parentNode){
        if (!parentNode)
            parentNode = this.$pHtmlNode;

        //Build Main Skin
        if (apf.cannotSizeIframe) {
            //parentNode.appendChild(document.createElement("iframe"));//
            this.$ext = parentNode.appendChild(document.createElement("DIV"))
                .appendChild(document.createElement("<iframe frameborder='0'></iframe>")).parentNode;
            this.$ext.style.width  = "100px";
            this.$ext.style.height = "100px";
            this.$int = this.$ext.firstChild;
            //this.$int = this.$ext;
            this.$int.style.width  = "100%";
            this.$int.style.height = "100%";
            this.$int.frameBorder = 0;
        }
        else {
            this.$ext = parentNode.appendChild(document.createElement("iframe"));
            this.$ext.style.width  = "100px";
            this.$ext.style.height = "100px";
            this.$int              = this.$ext;
            //this.$ext.style.border = "2px inset white";
        }

        //this.$int = this.$ext.contentWindow.document.body;
        this.$ext.host = this;
        //this.$int.host = this;
    };
}).call(apf.browser.prototype = new apf.GuiElement());

apf.aml.setElement("browser", apf.browser);
// #endif
