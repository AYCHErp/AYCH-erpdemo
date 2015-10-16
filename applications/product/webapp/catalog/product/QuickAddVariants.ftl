<#--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->
<script type="text/javascript">
function setProductVariantId(e, value, fieldname) {
    var cform = document.selectAllForm;
    var len = cform.elements.length;
    for (var i = 0; i < len; i++) {
        var element = cform.elements[i];
        if (element.name == fieldname) {
            if (e.checked) {
                if (element.value == null || element.value == "") {
                    element.value = value;
                }
            } else {
                element.value = "";
            }
            return;
        }
    }
}
function clickAll(e) {
    var cform = document.selectAllForm;
    var len = cform.elements.length;
    for (var i = 0; i < len; i++) {
        var element = cform.elements[i];
        if (element.name.substring(0, 10) == "_rowSubmit" && element.checked != e.checked) {
            element.click();
        }
    }
}
</script>
<#if (product.isVirtual)! != "Y">
    <@alert type="warning">${uiLabelMap.ProductWarningProductNotVirtual}</@alert>
</#if>
<#if featureTypes?has_content && (featureTypes.size() > 0)>
        <form method="post" action="<@ofbizUrl>QuickAddChosenVariants</@ofbizUrl>" name="selectAllForm">
            <input type="hidden" name="productId" value="${productId}" />
            <input type="hidden" name="_useRowSubmit" value="Y" />
            <input type="hidden" name="_checkGlobalScope" value="Y" />
      <@table type="data-list" autoAltRows=true cellspacing="0" class="${styles.table_default!}">
        <#assign rowCount = 0>
        <@thead>
          <@tr class="header-row">
            <#list featureTypes as featureType>
                <@th>${featureType}</@th>
            </#list>
            <@th>${uiLabelMap.ProductNewProductCreate} !</@th>
            <@th>${uiLabelMap.ProductSequenceNum}</@th>
            <@th>${uiLabelMap.ProductExistingVariant} :</@th>
            <@th align="right">${uiLabelMap.CommonAll}<input type="checkbox" name="selectAll" value="${uiLabelMap.CommonY}" onclick="javascript:clickAll(this);" /></@th>
          </@tr>
        </@thead>
        <#assign defaultSequenceNum = 10>
        <@tbody>
          <#list featureCombinationInfos as featureCombinationInfo>
            <#assign curProductFeatureAndAppls = featureCombinationInfo.curProductFeatureAndAppls>
            <#assign existingVariantProductIds = featureCombinationInfo.existingVariantProductIds>
            <#assign defaultVariantProductId = featureCombinationInfo.defaultVariantProductId>
            <@tr valign="middle">
                <#assign productFeatureIds = "">
                <#list curProductFeatureAndAppls as productFeatureAndAppl>
                <@td>
                    ${productFeatureAndAppl.description!}
                    <#assign productFeatureIds = productFeatureIds + "|" + productFeatureAndAppl.productFeatureId>
                </@td>
                </#list>
                <@td>
                    <input type="hidden" name="productFeatureIds_o_${rowCount}" value="${productFeatureIds}"/>
                    <input type="text" size="20" maxlength="20" name="productVariantId_o_${rowCount}" value=""/>
                </@td>
                <@td>
                    <input type="text" size="5" maxlength="10" name="sequenceNum_o_${rowCount}" value="${defaultSequenceNum}"/>
                </@td>
                <@td>
                    <#list existingVariantProductIds as existingVariantProductId>
                        <a href="<@ofbizUrl>EditProduct?productId=${existingVariantProductId}</@ofbizUrl>" class="${styles.button_default!}">${existingVariantProductId}</a>
                    </#list>
                </@td>
                <@td align="right">
                  <input type="checkbox" name="_rowSubmit_o_${rowCount}" value="Y" onclick="javascript:setProductVariantId(this, '${defaultVariantProductId}', 'productVariantId_o_${rowCount}');" />
                </@td>
            </@tr>
            <#assign defaultSequenceNum = defaultSequenceNum + 10>
            <#assign rowCount = rowCount + 1>
          </#list>
        </@tbody>
        <@tfoot>
          <@tr>
            <#assign columns = featureTypes.size() + 4>
            <@td colspan="${columns}" align="center">
                <input type="hidden" name="_rowCount" value="${rowCount}" />
                <input type="submit" class="smallSubmit ${styles.button_default!}" value="${uiLabelMap.CommonCreate}"/>
            </@td>
          </@tr>
        </@tfoot>
      </@table>
    </form>
<#else>
    <@resultMsg>${uiLabelMap.ProductNoSelectableFeaturesFound}</@resultMsg>
</#if>
<@section title="${uiLabelMap.ProductVariantAdd}">
    <form action="<@ofbizUrl>addVariantsToVirtual</@ofbizUrl>" method="post" name="addVariantsToVirtual">
        <input type="hidden" name="productId" value="${productId}"/>
        <@field type="generic" label="${uiLabelMap.ProductVariantProductIds}">
            <textarea name="variantProductIdsBag" rows="6" cols="20"></textarea>
        </@field>
        <@field type="submitarea">
            <input type="submit" class="smallSubmit ${styles.button_default!}" value="${uiLabelMap.ProductVariantAdd}"/>
        </@field>
    </form>
</@section>