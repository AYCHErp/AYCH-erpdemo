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

<@section title="${uiLabelMap.PartyVisitDetail}">
      <table class="basic-table" cellspacing="0">
        <tr>
          <td>${uiLabelMap.PartyVisitIDSessionID}</td>
          <td>${visit.visitId!} / ${visit.sessionId!}</td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyVisitorId}</td>
          <td>${visit.visitorId?default("${uiLabelMap.CommonNot} ${uiLabelMap.CommonFound}")}</td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyPartyIDUserLoginID}</td>
          <td><a href="<@ofbizUrl>viewprofile?partyId=${visit.partyId!}</@ofbizUrl>">${visit.partyId!}</a> / <a href="<@ofbizUrl>viewprofile?partyId=${visit.partyId!}</@ofbizUrl>">${visit.userLoginId!}</a></td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyUserCreated}</td>
          <td>${visit.userCreated!}</td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyWebApp}</td>
          <td>${visit.webappName!}</td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyServer}</td>
          <td><a href="http://uptime.netcraft.com/up/graph/?site=${visit.serverIpAddress!}" target="_blank" class="button tiny">${visit.serverIpAddress!}</a> / <a href="http://uptime.netcraft.com/up/graph/?site=${visit.serverIpAddress!}" target="_blank" class="button tiny">${visit.serverHostName!}</a></td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyClient}</td>
          <td><a href="http://ws.arin.net/cgi-bin/whois.pl?queryinput=${visit.clientIpAddress!}" target="_blank" class="button tiny">${visit.clientIpAddress!}</a> / <a href="http://www.networksolutions.com/cgi-bin/whois/whois?STRING=${visit.clientHostName!}&amp;SearchType=do" target="_blank" class="button tiny">${visit.clientHostName!}</a></td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyClientUser}</td>
          <td>${visit.clientUser!}</td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyInitialLocale}</td>
          <td>${visit.initialLocale!}</td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyInitialRequest}</td>
          <td><a href="${visit.initialRequest!}" >${visit.initialRequest!}</a></td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyInitialReferer}</td>
          <td><a href="${visit.initialReferrer!}" >${visit.initialReferrer!}</a></td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyInitialUserAgent}</td>
          <td>${visit.initialUserAgent!}</td>
        </tr>
        <tr>
          <td>${uiLabelMap.PartyCookie}</td>
          <td>${visit.cookie!}</td>
        </tr>
        <tr>
          <td>${uiLabelMap.CommonFromDateThruDate}</td>
          <td>${(visit.fromDate?string)!} / ${(visit.thruDate?string)?default(uiLabelMap.PartyStillActive)}</td>
        </tr>
      </table>
</@section>
<@section title="${uiLabelMap.PartyHitTracker}">

  <#macro paginateVisit>
    <#assign url><@ofbizUrl>visitdetail</@ofbizUrl></#assign>
    <#assign paramStr = addParamsToStr("", {"visitId": visitId!})>
    <@paginate url=url viewSize=viewSize viewIndex=viewIndex listSize=listSize paramStr=paramStr/>   
  </#macro> 
   
      <#assign paginated = false>
      <#if serverHits?has_content>
        <#if (0 < listSize)>
          <@paginateVisit />
          <#assign paginated = true>
        </#if>
      </#if>
      <table class="basic-table hover-bar" cellspacing="0">
       <thead>
        <tr class="header-row">
          <th>${uiLabelMap.PartyContentId}</th>
          <th>${uiLabelMap.PartyType}</th>
          <th>${uiLabelMap.PartySize}</th>
          <th>${uiLabelMap.PartyStartTime}</th>
          <th>${uiLabelMap.PartyTime}</th>
          <th>${uiLabelMap.PartyURI}</th>
        </tr>
        </thead>
        <#-- set initial row color -->
        <#assign alt_row = false>
        <#if serverHits?has_content>
        <#list serverHits[lowIndex..highIndex-1] as hit>
          <#assign serverHitType = hit.getRelatedOne("ServerHitType", false)!>
          <tr class="<#if alt_row>odd<#else>even</#if>">
            <td>${hit.contentId!}</td>
            <td>${serverHitType.get("description",locale)!}</td>
            <td>&nbsp;&nbsp;${hit.numOfBytes?default("?")}</td>
            <td>${hit.hitStartDateTime?string!}</td>
            <td>${hit.runningTimeMillis!}</td>
            <td>
              <#assign url = (hit.requestUrl)!>
              <#if url??>
                <#assign len = url?length>
                <#if (45 < len)>
                  <#assign url = url[0..45] + "...">
                </#if>
              </#if>
              <a href="${hit.requestUrl!}" target="_blank">${url}</a>
            </td>
          </tr>
          <#-- toggle the row color -->
          <#assign alt_row = !alt_row>
        </#list>
        <#else/>
          <tr>
            <td colspan="6">${uiLabelMap.PartyNoServerHitsFound}</td>
          </tr>
        </#if>
      </table>
      <#if paginated>
        <@paginateVisit />
      </#if>
</@section>

<#--
*******************************************************************************
JIRA OFBIZ-4488: BEGIN
https://issues.apache.org/jira/browse/OFBIZ-4488
*******************************************************************************
<div class="screenlet">
  <div class="screenlet-title-bar">
    <ul>
      <li class="h3">${uiLabelMap.PartyPagePushFollowing}</li>
    </ul>
    <br class="clear"/>
  </div>  
  <div class="screenlet-body">
      <#if security.hasPermission("SEND_CONTROL_APPLET", session)>
        <table class="basic-table" cellspacing="0">
            <tr>
              <th>${uiLabelMap.PartyPushURL}</th>
              <td>
                <form name="pushPage" method="get" action="<@ofbizUrl>pushPage</@ofbizUrl>">
                  <input type="hidden" name="followerSid" value="${visit.sessionId}" />
                  <input type="hidden" name="visitId" value="${visit.visitId}" />
                  <input type="text" name="pageUrl" />
                  <input type="submit" value="${uiLabelMap.CommonSubmit}" />
                </form>
              </td>
            </tr>
            <tr>
              <td colspan="3"><hr /></td>
            </tr>
            <tr>
              <th>${uiLabelMap.PartyFollowSession}</th>
              <td>
                <form name="setFollower" method="get" action="<@ofbizUrl>setAppletFollower</@ofbizUrl>">
                  <input type="hidden" name="followerSid" value="${visit.sessionId}" />
                  <input type="hidden" name="visitId" value="${visit.visitId}" />
                  <input type="text" name="followSid" />
                  <input type="submit" value="${uiLabelMap.CommonSubmit}" />
                </form>
              </td>
            </tr>
        </table>
      </#if>
  </div>
</div>
*******************************************************************************
JIRA OFBIZ-4488: END
*******************************************************************************
-->

