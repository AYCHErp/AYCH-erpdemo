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

<#-- generic address information -->
<#assign toName = (parameters.toName)!>
<#if !toName?has_content && person?? && person?has_content>
  <#assign toName = "">
  <#if person.personalTitle?has_content><#assign toName = person.personalTitle + " "></#if>
  <#assign toName = toName + person.firstName + " ">
  <#if person.middleName?has_content><#assign toName = toName + person.middleName + " "></#if>
  <#assign toName = toName + person.lastName>
  <#if person.suffix?has_content><#assign toName = toName + " " + person.suffix></#if>
</#if>

<@field type="input" label=uiLabelMap.PartyToName size="30" maxlength="60" name="toName" value=(toName) disabled=(requestParameters.useShipAddr??)/>
<@field type="input" label=uiLabelMap.PartyAttentionName size="30" maxlength="60" name="attnName" value=((parameters.attnName)!) disabled=(requestParameters.useShipAddr??)/>
<@field type="input" label=uiLabelMap.PartyAddressLine1 required=true size="30" maxlength="30" name="address1" value=((parameters.address1)!) disabled=(requestParameters.useShipAddr??)/>
<@field type="input" label=uiLabelMap.PartyAddressLine2 size="30" maxlength="30" name="address2" value=((parameters.address2)!) disabled=(requestParameters.useShipAddr??)/>
<@field type="input" label=uiLabelMap.PartyCity required=true size="30" maxlength="30" name="city" value=((parameters.city)!) disabled=(requestParameters.useShipAddr??)/>
<@field type="input" label=uiLabelMap.PartyZipCode required=true size="12" maxlength="10" name="postalCode" value=((parameters.postalCode)!) disabled=(requestParameters.useShipAddr??)/>
<@field type="select" label=uiLabelMap.CommonCountry required=true name="countryGeoId" disabled=(requestParameters.useShipAddr??)>
  <#if (parameters.countryGeoId)??>
    <option>${parameters.countryGeoId}</option>
    <option value="${parameters.countryGeoId}">---</option>
  </#if>
  <@render resource="component://common/widget/CommonScreens.xml#countries" />
</@field>
<@field type="select" label=uiLabelMap.PartyState required=true name="stateProvinceGeoId" disabled=(requestParameters.useShipAddr??)>
  <#if (parameters.stateProvinceGeoId)??>
    <option>${parameters.stateProvinceGeoId}</option>
    <option value="${parameters.stateProvinceGeoId}">---</option>
  <#else>
    <option value="">${uiLabelMap.PartyNoState}</option>
  </#if>
  <#--<@render resource="component://common/widget/CommonScreens.xml#states" />-->
</@field>
<@field type="select" label="${uiLabelMap.PartyAllowSolicitation}?" name="allowSolicitation" disabled=(requestParameters.useShipAddr??)>
      <#if (((parameters.allowSolicitation)!"") == "Y")><option value="Y">${uiLabelMap.CommonYes}</option></#if>
      <#if (((parameters.allowSolicitation)!"") == "N")><option value="N">${uiLabelMap.CommonNo}</option></#if>
      <option></option>
      <option value="Y">${uiLabelMap.CommonYes}</option>
      <option value="N">${uiLabelMap.CommonNo}</option>
</@field>
