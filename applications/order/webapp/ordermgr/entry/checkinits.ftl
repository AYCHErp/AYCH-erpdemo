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

<#assign shoppingCartOrderType = "">
<#assign shoppingCartProductStore = "NA">
<#assign shoppingCartChannelType = "">
<#if shoppingCart??>
  <#assign shoppingCartOrderType = shoppingCart.getOrderType()>
  <#assign shoppingCartProductStore = shoppingCart.getProductStoreId()?default("NA")>
  <#assign shoppingCartChannelType = shoppingCart.getChannelType()?default("")>
<#else>
<#-- allow the order type to be set in parameter, so only the appropriate section (Sales or Purchase Order) shows up -->
  <#if parameters.orderTypeId?has_content>
    <#assign shoppingCartOrderType = parameters.orderTypeId>
  </#if>
</#if>
<!-- Sales Order Entry -->
<#if security.hasEntityPermission("ORDERMGR", "_CREATE", session)>
  <#if shoppingCartOrderType != "PURCHASE_ORDER">
    <#assign sectionTitle>
      ${uiLabelMap.OrderSalesOrder}<#if shoppingCart??>&nbsp;${uiLabelMap.OrderInProgress}</#if>
    </#assign>
    <#macro menuContent menuArgs={}>
      <@menu args=menuArgs>
        <@menuitem type="link" href="javascript:document.salesentryform.submit();" text="${uiLabelMap.CommonContinue}" />
        <@menuitem type="link" href="/partymgr/control/findparty?${StringUtil.wrapString(externalKeyParam)}" text="${uiLabelMap.PartyFindParty}" />
      </@menu>
    </#macro>
    <@section class="${styles.grid_large!}9" title=sectionTitle menuContent=menuContent>
      <form method="post" name="salesentryform" action="<@ofbizUrl>initorderentry</@ofbizUrl>">
      <input type="hidden" name="originOrderId" value="${parameters.originOrderId!}"/>
      <input type="hidden" name="finalizeMode" value="type"/>
      <input type="hidden" name="orderMode" value="SALES_ORDER"/>
        <@field type="select" label="${uiLabelMap.ProductProductStore}" name="productStoreId" >
            <#assign currentStore = shoppingCartProductStore>
            <#if defaultProductStore?has_content>
               <option value="${defaultProductStore.productStoreId}">${defaultProductStore.storeName!}</option>
               <option value="${defaultProductStore.productStoreId}">----</option>
            </#if>
            <#list productStores as productStore>
              <option value="${productStore.productStoreId}"<#if productStore.productStoreId == currentStore> selected="selected"</#if>>${productStore.storeName!}</option>
            </#list>
            <#--<#if sessionAttributes.orderMode??>${uiLabelMap.OrderCannotBeChanged}</#if>-->
        </@field>
        <@field type="select" label="${uiLabelMap.OrderSalesChannel}" name="salesChannelEnumId">
            <#assign currentChannel = shoppingCartChannelType>
            <#if defaultSalesChannel?has_content>
               <option value="${defaultSalesChannel.enumId}">${defaultSalesChannel.description!}</option>
               <option value="${defaultSalesChannel.enumId}"> ---- </option>
            </#if>
            <option value="">${uiLabelMap.OrderNoChannel}</option>
            <#list salesChannels as salesChannel>
              <option value="${salesChannel.enumId}" <#if (salesChannel.enumId == currentChannel)>selected="selected"</#if>>${salesChannel.get("description",locale)}</option>
            </#list>
        </@field>
        <#if partyId??>
          <#assign thisPartyId = partyId>
        <#else>
          <#assign thisPartyId = requestParameters.partyId!>
        </#if>
        <@row collapse=false>
            <@cell class="${styles.grid_small!}3 ${styles.grid_large!}2"><label for="userLoginId_sales">${uiLabelMap.CommonUserLoginId}</label></@cell>
            <@cell class="${styles.grid_small!}9 ${styles.grid_large!}10">
              <@htmlTemplate.lookupField value="${parameters.userLogin.userLoginId}" formName="salesentryform" name="userLoginId" id="userLoginId_sales" fieldFormName="LookupUserLoginAndPartyDetails"/>
            </@cell>
        </@row>
        <@row collapse=false>
            <@cell class="${styles.grid_small!}3 ${styles.grid_large!}2"><label for="partyId">${uiLabelMap.OrderCustomer}</label></@cell>
            <@cell class="${styles.grid_small!}9 ${styles.grid_large!}10">
              <@htmlTemplate.lookupField value='${thisPartyId!}' formName="salesentryform" name="partyId" id="partyId" fieldFormName="LookupCustomerName"/>
            </@cell>
        </@row>
      </form>
    </@section>
  </#if>
</#if>

<!-- Purchase Order Entry -->
<#if security.hasEntityPermission("ORDERMGR", "_PURCHASE_CREATE", session)>
  <#if shoppingCartOrderType != "SALES_ORDER">
    <#assign sectionTitle>
        ${uiLabelMap.OrderPurchaseOrder}<#if shoppingCart??>&nbsp;${uiLabelMap.OrderInProgress}</#if>
    </#assign>
    <#macro menuContent menuArgs={}>
      <@menu args=menuArgs>
        <@menuitem type="link" href="javascript:document.poentryform.submit();" text="${uiLabelMap.CommonContinue}" />
        <@menuitem type="link" href="/partymgr/control/findparty?${StringUtil.wrapString(externalKeyParam)}" text="${uiLabelMap.PartyFindParty}" />
      </@menu>
    </#macro>
    <@section title=sectionTitle class="${styles.grid_large!}9" menuContent=menuContent>
      <form method="post" name="poentryform" action="<@ofbizUrl>initorderentry</@ofbizUrl>">
      <input type='hidden' name='finalizeMode' value='type'/>
      <input type='hidden' name='orderMode' value='PURCHASE_ORDER'/>
        <#if partyId??>
          <#assign thisPartyId = partyId>
        <#else>
          <#assign thisPartyId = requestParameters.partyId!>
        </#if>
        <@field type="select" label="${uiLabelMap.OrderOrderEntryInternalOrganization}" name="billToCustomerPartyId">
            <#list organizations as organization>
              <#assign organizationName = Static["org.ofbiz.party.party.PartyHelper"].getPartyName(organization, true)/>
                <#if (organizationName.length() != 0)>
                  <option value="${organization.partyId}">${organization.partyId} - ${organizationName}</option>
                </#if>
            </#list>
        </@field>
        <@row collapse=false>
            <@cell class="${styles.grid_small!}3 ${styles.grid_large!}2"><label for="userLoginId_purchase">${uiLabelMap.CommonUserLoginId}</label></@cell>
            <@cell class="${styles.grid_small!}9 ${styles.grid_large!}10">
              <@htmlTemplate.lookupField value='${parameters.userLogin.userLoginId}'formName="poentryform" name="userLoginId" id="userLoginId_purchase" fieldFormName="LookupUserLoginAndPartyDetails"/>
            </@cell>
        </@row>
        <@field type="select" label="${uiLabelMap.PartySupplier}" name="supplierPartyId">
            <option value="">${uiLabelMap.OrderSelectSupplier}</option>
            <#list suppliers as supplier>
              <option value="${supplier.partyId}"<#if supplier.partyId == thisPartyId> selected="selected"</#if>>[${supplier.partyId}] - ${Static["org.ofbiz.party.party.PartyHelper"].getPartyName(supplier, true)}</option>
            </#list>
        </@field>
      </form>
    </@section>
  </#if>
</#if>
