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

<#if productImageList?has_content>
        <#if product?has_content>
            <@heading>${product.productId}</@heading>
        </#if>
  <#-- Cato: NOTE: no need for handling rows when have tiles -->
  <@grid type="tiles">
        <#-- <#assign productName = productTextData >
        <#assign seoUrl = productName.replaceAll(" ", "-") > -->
        <#list productImageList as productImage>
              <#assign imgLink><@ofbizContentUrl>${(productImage.productImage)!}</@ofbizContentUrl></#assign>
              <#assign thumbSrc><@ofbizContentUrl>${(productImage.productImageThumb)!}</@ofbizContentUrl></#assign>
              <@tile type="normal" image=thumbSrc overlayColor=styles.gallery_overlay_color!
                  overlayType=styles.gallery_overlay_type! imageType=styles.gallery_image_type!> <#-- can't use this, breaks Share button: link=imgLink so use View button instead -->
                  <@container class="+${styles.text_center!}">
                      <#--<a href="/catalog/images/${seoUrl}-${product.productId}/${seoUrl}-${contentName}" target="_blank"><img src="<@ofbizContentUrl>${(contentDataResourceView.drObjectInfo)!}</@ofbizContentUrl>" vspace="5" hspace="5" alt=""/></a>
                      <a href="<@ofbizContentUrl>${(productImage.productImage)!}</@ofbizContentUrl>" target="_blank"><img src="<@ofbizContentUrl>${(productImage.productImageThumb)!}</@ofbizContentUrl>" vspace="5" hspace="5" alt=""/></a>-->
                      <a href="<@ofbizContentUrl>${(productImage.productImage)!}</@ofbizContentUrl>" target="_blank" class="${styles.link_action!}">${uiLabelMap.CommonView}</a>
                  </@container>
                  <@container class="+${styles.text_center!}">
                       <#--<a href="javascript:call_fieldlookup('','<@ofbizUrl>ImageShare?contentId=${productContentAndInfo.contentId}&amp;dataResourceId=${productContentAndInfo.dataResourceId}&amp;seoUrl=/catalog/images/${seoUrl}-${product.productId}/${seoUrl}-${contentName}</@ofbizUrl>','',${styles.gallery_share_view_width!},${styles.gallery_share_view_height!});" class="${styles.link_action!}">${uiLabelMap.ImageManagementShare}</a>-->
                       <a href="javascript:call_fieldlookup('','<@ofbizUrl>ImageShare?contentId=${productImage.contentId}&amp;dataResourceId=${productImage.dataResourceId}</@ofbizUrl>','',${styles.gallery_share_view_width!},${styles.gallery_share_view_height!});" class="${styles.link_action!}">${uiLabelMap.ImageManagementShare}</a>
                  </@container>
              </@tile>
        </#list>
  </@grid>
<#else>
  <@resultMsg>${uiLabelMap.CommonNoRecordFound}.</@resultMsg>
</#if>



