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

//#ifdef __WITH_DATABINDING

/**
 * @attribute {String} formula 
 * @attribute {Number} length
 * @attribute {String} delimiter
 * @attribute {String} split
 * @attribute {String} css
 */
apf.BindingSeriesRule = function(struct, tagName){
    this.$init(tagName || "series", apf.NODE_HIDDEN, struct);
};

(function(){
    //1 = force no bind rule, 2 = force bind rule
    this.$attrExcludePropBind = apf.extend({
        formula : 1
    }, this.$attrExcludePropBind);

    this.$propHandlers["formula"] = function(value, prop){
        delete this["c" + prop];
    }
    
    /*this.addEventListener("DOMNodeInsertedIntoDocument", function(e){
        //Find parent that this rule works on
        var pNode = this;
        while (pNode && pNode.$bindingRule) 
            pNode = pNode.parentNode;
       
        if (!pNode)
            return;
    });*/
}).call(apf.BindingSeriesRule.prototype = new apf.BindingRule());

apf.aml.setElement("series", apf.BindingSeriesRule);
// #endif

