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
<#include "customercommon.ftl">

<#assign delegator = requestAttributes.delegator>
<#if communicationEvent.partyIdFrom??>
    <#assign fromName = Static["org.ofbiz.party.party.PartyHelper"].getPartyName(delegator, communicationEvent.partyIdFrom, true)>
</#if>
<#if communicationEvent.partyIdTo??>
    <#assign toName = Static["org.ofbiz.party.party.PartyHelper"].getPartyName(delegator, communicationEvent.partyIdTo, true)>
</#if>

<#-- TODO: this was turned into menu below, may need something more to achieve look... extra menu class/type...
        this code was BEFORE or LEFT of title, not after
        <div class="boxlink">
            <#if ((communicationEvent.partyIdFrom!) != (userLogin.partyId)!)>
              <a href="<@ofbizUrl>newmessage?communicationEventId=${communicationEvent.communicationEventId}</@ofbizUrl>" class="submenutext">${uiLabelMap.PartyReply}</a>
            </#if>
            <a href="<@ofbizUrl>messagelist</@ofbizUrl>" class="submenutextright">${uiLabelMap.EcommerceViewList}</a>
        </div>
-->
<#macro menuContent menuArgs={}>
    <@menu args=menuArgs>
        <#if ((communicationEvent.partyIdFrom!) != (userLogin.partyId)!)>
          <@menuitem type="link" href=makeOfbizUrl("newmessage?communicationEventId=${communicationEvent.communicationEventId}") text=uiLabelMap.PartyReply />
        </#if>
        <@menuitem type="link" href=makeOfbizUrl("messagelist") text=uiLabelMap.EcommerceViewList />
    </@menu>
</#macro>
<@section title=uiLabelMap.EcommerceReadMessage menuContent=menuContent menuLayoutTitle="inline-title">
    <@table type="fields"> <#-- orig: width="100%" border="0" cellpadding="1" -->
      <@tr><@td>&nbsp;</@td></@tr>
      <@tr>
          <@td>${uiLabelMap.CommonFrom}</@td>
          <@td>${fromName!}</@td>
      </@tr>
      <@tr>
          <@td>${uiLabelMap.CommonTo}</@td>
          <@td>${toName!}</@td>
      </@tr>
      <@tr>
          <@td>${uiLabelMap.CommonDate}</@td>
          <@td>${communicationEvent.entryDate}</@td>
      </@tr>
      <@tr>
          <@td>${uiLabelMap.EcommerceSubject}</@td>
          <@td>&nbsp;${(communicationEvent.subject)!("[${uiLabelMap.EcommerceNoSubject}]")}</@td>
      </@tr>
      <@tr><@td>&nbsp;</@td></@tr>
      <@tr>
        <@td>&nbsp;</@td>
        <#-- Cato: FIXME: This must be reviewed for escaping issues, real security risk here -->
        <@td>${htmlContentString(communicationEvent.content)!("[${uiLabelMap.EcommerceEmptyBody}]")}
        </@td>
      </@tr>
    </@table>
</@section>
