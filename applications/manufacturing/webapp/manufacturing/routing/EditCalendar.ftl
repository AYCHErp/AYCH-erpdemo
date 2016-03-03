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

<#if techDataCalendar?has_content>
  <#assign sectionTitle>${uiLabelMap.ManufacturingUpdateCalendar}</#assign>
<#else>
  <#assign sectionTitle>${uiLabelMap.ManufacturingCreateCalendar}</#assign>
</#if>
<#macro menuContent menuArgs={}>
  <@menu args=menuArgs>
    <@menuitem type="link" href=makeOfbizUrl("EditCalendar") text=uiLabelMap.ManufacturingNewCalendar class="+${styles.action_nav!} ${styles.action_add!}" />
  </@menu>
</#macro>
<@section title=sectionTitle menuContent=menuContent>

<#if techDataCalendar?has_content>
  <#assign formActionUrl><@ofbizUrl>UpdateCalendar</@ofbizUrl></#assign>
<#else>
  <#assign formActionUrl><@ofbizUrl>CreateCalendar</@ofbizUrl></#assign>
</#if>

  <form name="calendarform" method="post" action="${formActionUrl}">

  <#if techDataCalendar?has_content>
    <input type="hidden" name="calendarId" value="${techDataCalendar.calendarId}" />
  </#if>

  <#if techDataCalendar?has_content>
    <@field type="display" label=uiLabelMap.ManufacturingCalendarId tooltip="(${uiLabelMap.CommonNotModifRecreat})" value=techDataCalendar.calendarId! />
  <#else>
    <@field type="input" label=uiLabelMap.ManufacturingCalendarId size="12" name="calendarId" value=calendarData.calendarId! />
  </#if>
    <@field type="input" label=uiLabelMap.CommonDescription size="40" name="description" value=calendarData.description! />
    <@field type="select" label=uiLabelMap.ManufacturingCalendarWeekId name="calendarWeekId">
          <#list calendarWeeks as calendarWeek>
          <option value="${calendarWeek.calendarWeekId}" <#if calendarData?has_content && calendarData.calendarWeekId?default("") == calendarWeek.calendarWeekId>SELECTED</#if>>${(calendarWeek.get("description",locale))!}</option>
          </#list>
    </@field>
    <@field type="submit" text=uiLabelMap.CommonUpdate class="+${styles.link_run_sys!} ${styles.action_update!}"/>

  </form>
</@section>