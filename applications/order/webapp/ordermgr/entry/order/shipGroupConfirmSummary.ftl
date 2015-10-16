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

<#--
Ship group summary for order confirmation.  Lists each ship group, its
destination address, products and quantities associated with it,
and similar information.  This is designed to be tacked on to the
standard order confirmation page and to be re-usable by other screens.
-->

<#if !(cart??)><#assign cart = shoppingCart!/></#if>

<#if cart??>
  <@section title="${uiLabelMap.OrderShippingInformation}">
    <@table type="data-list" class="${styles.table_default!}">

      <#-- header -->
      <@thead>
        <@tr>
          <@th>${uiLabelMap.OrderDestination}</@th>
          <@th>${uiLabelMap.PartySupplier}</@th>
          <@th>${uiLabelMap.ProductShipmentMethod}</@th>
          <@th>${uiLabelMap.ProductItem}</@th>
          <@th>${uiLabelMap.ProductQuantity}</@th>
        </@tr>
      </@thead>

      <#-- BEGIN LIST SHIP GROUPS -->
      <#--
      The structure of this table is one row per line item, grouped by ship group.
      The address column spans a number of rows equal to the number of items of its group.
      -->

      <#list cart.getShipGroups() as cartShipInfo>
      <#assign shipItems = cartShipInfo.getShipItems()>
      <#assign numberOfItems = shipItems.size()>
      <#if (numberOfItems > 0)>
      <#assign shipItems = Static["org.ofbiz.base.util.UtilMisc"].toList(shipItems)>

      <#-- spacer goes here -->

      <@tr>

        <#-- address destination column (spans a number of rows = number of cart items in it) -->

        <@td rowspan="${numberOfItems}">
          <#assign contactMech = delegator.findOne("ContactMech", Static["org.ofbiz.base.util.UtilMisc"].toMap("contactMechId", cartShipInfo.contactMechId), false)! />
          <#if contactMech?has_content>
            <#assign address = contactMech.getRelatedOne("PostalAddress", false)! />
          </#if>

          <#if address??>
            <#if address.toName?has_content><b>${uiLabelMap.CommonTo}:</b>&nbsp;${address.toName}<br /></#if>
            <#if address.attnName?has_content><b>${uiLabelMap.CommonAttn}:</b>&nbsp;${address.attnName}<br /></#if>
            <#if address.address1?has_content>${address.address1}<br /></#if>
            <#if address.address2?has_content>${address.address2}<br /></#if>
            <#if address.city?has_content>${address.city}</#if>
            <#if address.stateProvinceGeoId?has_content>&nbsp;${address.stateProvinceGeoId}</#if>
            <#if address.postalCode?has_content>, ${address.postalCode!}</#if>
          </#if>
        </@td>

        <#-- supplier id (for drop shipments) (also spans rows = number of items) -->

        <@td rowspan="${numberOfItems}" valign="top">
          <#assign supplier =  delegator.findOne("PartyGroup", Static["org.ofbiz.base.util.UtilMisc"].toMap("partyId", cartShipInfo.getSupplierPartyId()), false)! />
          <#if supplier?has_content>${supplier.groupName?default(supplier.partyId)}</#if>
        </@td>

        <#-- carrier column (also spans rows = number of items) -->

        <@td rowspan="${numberOfItems}" valign="top">
          <#assign carrier =  delegator.findOne("PartyGroup", Static["org.ofbiz.base.util.UtilMisc"].toMap("partyId", cartShipInfo.getCarrierPartyId()), false)! />
          <#assign method =  delegator.findOne("ShipmentMethodType", Static["org.ofbiz.base.util.UtilMisc"].toMap("shipmentMethodTypeId", cartShipInfo.getShipmentMethodTypeId()), false)! />
          <#if carrier?has_content>${carrier.groupName?default(carrier.partyId)}</#if>
          <#if method?has_content>${method.description?default(method.shipmentMethodTypeId)}</#if>
        </@td>

        <#-- list each ShoppingCartItem in this group -->

      <#macro cartItemCells shoppingCartItem cartShipInfo>
        <@td valign="top"> ${shoppingCartItem.getProductId()?default("")} - ${shoppingCartItem.getName()?default("")} </@td>
        <@td valign="top"> ${cartShipInfo.getShipItemInfo(shoppingCartItem).getItemQuantity()?default("0")} </@td>
      </#macro>

        <@cartItemCells shoppingCartItem=shipItems?first cartShipInfo=cartShipInfo/>
      </@tr>

    <#if (numberOfItems > 1)>
      <#list shipItems[1..] as shoppingCartItem>
      <@tr>
        <@cartItemCells shoppingCartItem=shoppingCartItem cartShipInfo=cartShipInfo/>
      </@tr>
      </#list>
    </#if>

      </#if>
      </#list>

      <#-- END LIST SHIP GROUPS -->

    </@table>
  </@section>
</#if>
