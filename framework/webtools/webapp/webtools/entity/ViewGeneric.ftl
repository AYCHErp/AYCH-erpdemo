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
<#assign enableEdit = parameters.enableEdit?default("false")>
<#--
<@script>
var numTabs=${(entity.getRelationsSize()+1)};
function ShowTab(lname) {
  for(inc=1; inc <= numTabs; inc++) {
    // document.getElementById('area' + inc).className = (lname == 'tab' + inc) ? 'screenlet' : 'topcontainerhidden';
    // style of topcontainerhidden 
    // .topcontainerhidden { POSITION: absolute; VISIBILITY: hidden; }
    var elem = document.getElementById('area' + inc);
    if (lname == 'tab' + inc){
      elem.className = 'screenlet';
    }
    else {
      elem.className = 'topcontainerhidden';
      elem.style.position = 'absolute';
      elem.style.visibility = 'hidden';
    }
  }
}
</@script>-->
<@section title="${uiLabelMap.WebtoolsViewValue} ${uiLabelMap.WebtoolsForEntity} ${entityName}">

    <@menu type="button">
      <@menuitem type="link" href=makeOfbizUrl("FindGeneric?entityName=${entityName}&amp;find=true&amp;VIEW_SIZE=${getPropertyValue('webtools', 'webtools.record.paginate.defaultViewSize')!50}&amp;VIEW_INDEX=0") text=uiLabelMap.WebtoolsBackToFindScreen class="+${styles.action_nav!} ${styles.action_cancel!}" />
      <#if enableEdit = "false">
        <#if hasCreatePermission>
          <@menuitem type="link" href=makeOfbizUrl("ViewGeneric?entityName=${entityName}&amp;enableEdit=true") text=uiLabelMap.CommonCreateNew class="+${styles.action_nav!} ${styles.action_add!}" />
          <@menuitem type="link" href=makeOfbizUrl("ViewGeneric?${curFindString}&amp;enableEdit=true") text=uiLabelMap.CommonEdit class="+${styles.action_nav!} ${styles.action_update!}" />
        </#if>
        <#if value?has_content>
          <#if hasDeletePermission>
            <@menuitem type="link" href=makeOfbizUrl("UpdateGeneric?UPDATE_MODE=DELETE&amp;${curFindString}") text=uiLabelMap.WebtoolsDeleteThisValue class="+${styles.action_run_sys!} ${styles.action_remove!}" />
          </#if>
        </#if>
      </#if>
    </@menu>
    <br/>
    <@nav type="magellan">
        <#if value?has_content><@mli arrival="xml-view"><a href="#xml-view">${uiLabelMap.WebtoolsEntityXMLRepresentation}</a></@mli></#if>
        <#--<@mli arrival="common-view"><a href="#common-view">${uiLabelMap.CommonView}</a></@mli>-->
        <@mli arrival="current-view"><a href="#current-view">${uiLabelMap.WebtoolsEntityCurrentValue}</a></@mli>
        <@mli arrival="related-view"><a href="#related-view">${uiLabelMap.WebtoolsRelatedEntity}</a></@mli>
    </@nav>
    <br/>
    
    <#if value?has_content>
    <@row>
        <@cell>
          <@heading id="xml-view" attribs={"data-magellan-destination":"xml-view"}>${uiLabelMap.WebtoolsEntityXMLRepresentation}</@heading>
        
          <@code type="html"><#rt>
              <#assign valueXmlDoc = Static["org.ofbiz.entity.GenericValue"].makeXmlDocument([value]) />${Static["org.ofbiz.base.util.UtilXml"].writeXmlDocument(valueXmlDoc)}<#t>
          </@code><#lt>
        
        </@cell>
    </@row>
</#if>    
    
    <#--
    <#if value?has_content>
    <@row>
            <@cell columns=6>
      <form name="relationForm" onchange="javascript:ShowTab(this.options[this.selectedIndex].value)">
         
        <@heading id="common-view" attribs={"data-magellan-destination":"common-view"}>${uiLabelMap.CommonView}</@heading>
        <@field type="select" name="viewRelated">
          <option value="tab1">${entityName}</option>
          <#list relationFieldList as relation>
            <option value="tab${(relation_index+2)}">${relation.title}${relation.relEntityName} (${relation.type})</option>
          </#list>
        </@field>
      </form>
          </@cell>
    </@row>
    
    </#if>-->
    

   
    <#if enableEdit = "true" && ( hasUpdatePermission || hasCreatePermission)>
        <#assign alt_row = false>
           <@row>
            <@cell>
            <@heading id="current-view" attribs={"data-magellan-destination":"current-view"}>${uiLabelMap.WebtoolsEntityEditValue}</@heading>
          <#if pkNotFound>
            <p>${uiLabelMap.WebtoolsEntityName} ${entityName} ${uiLabelMap.WebtoolsWithPk} ${findByPk} ${uiLabelMap.WebtoolsSpecifiedEntity2}.</p>
          </#if>
          <form action="<@ofbizUrl>UpdateGeneric?entityName=${entityName}</@ofbizUrl>" method="post" name="updateForm">
            <@fields type="default-manual">
            <#assign showFields = true>
            <#-- FIXME: inputs within table elems -->
            <@table type="fields" autoAltRows=true> <#-- orig: class="basic-table" --> <#-- orig: cellspacing="0" -->
              <#if value?has_content>
                <#if hasUpdatePermission>
                  <#if newFieldPkList?has_content>
                    <input type="hidden" name="UPDATE_MODE" value="UPDATE"/>
                    <#list newFieldPkList as entityField>
                      <@tr>
                        <@td>${entityField.name}</@td>
                        <@td>
                          <input type="hidden" name="${entityField.name}" value="${entityField.value}"/>
                          ${entityField.value}
                        </@td>
                      </@tr>
                    </#list>
                  </#if>
                <#else>
                  <@commonMsg type="error">${uiLabelMap.WebtoolsEntityCretePermissionError} ${entityName} ${plainTableName}</@commonMsg>
                  <#assign showFields = false>
                </#if>
              <#else>
                <#if hasCreatePermission>
                  <#if newFieldPkList?has_content>
                    <@tr type="meta"><@td><p>${uiLabelMap.WebtoolsYouMayCreateAnEntity}</p>
                    <input type="hidden" name="UPDATE_MODE" value="CREATE"/></@td></@tr>
                    <#list newFieldPkList as entityField>
                      <@tr>
                        <@td>${entityField.name}</@td>
                        <@td>
                          <#if entityField.fieldType == 'DateTime'>
                            <#-- Cato: NOTE: when using default-manual, there is no label area, and label="xxx" arg won't turn on label area. label="xxx" is specified so it gets picked up by title/tooltip. -->
                            <@field type="datetime" label="${entityField.name}" name="${entityField.name}" value="${entityField.value}" size="25" maxlength="30" id="${entityField.name}" />
                          <#elseif entityField.fieldType == 'Date'>
                            <@field type="datetime" label="${entityField.name}" dateType="date" name="${entityField.name}" value="${entityField.value}" size="25" maxlength="30" id="${entityField.name}" />
                          <#elseif entityField.fieldType == 'Time'>
                            <@field type="datetime" label="${entityField.name}" dateType="time" name="${entityField.name}" size="6" maxlength="10" value="${entityField.value}" />
                          <#elseif entityField.fieldType == 'Integer'>
                            <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                          <#elseif entityField.fieldType == 'Long'>
                            <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                          <#elseif entityField.fieldType == 'Double'>
                            <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                          <#elseif entityField.fieldType == 'Float'>
                            <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                          <#elseif entityField.fieldType == 'StringOneRow'>
                            <@field type="input" size="${entityField.stringLength}" maxlength="${entityField.stringLength}" name="${entityField.name}" value="${entityField.value}" />
                          <#elseif entityField.fieldType == 'String'>
                            <@field type="input" size="80" maxlength="${entityField.stringLength}" name="${entityField.name}" value="${entityField.value}" />
                          <#elseif entityField.fieldType == 'Textarea'>
                            <@field type="textarea" cols="60" rows="3" maxlength="${entityField.stringLength}" name="${entityField.name}">${entityField.value}</@field>
                          <#else>
                            <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                          </#if>
                        </@td>
                      </@tr>
                    </#list>
                  </#if>
                <#else>
                  <@tr type="meta"><@td><@commonMsg type="error">${uiLabelMap.WebtoolsEntityCretePermissionError} ${entityName} ${plainTableName}</@commonMsg></@td></@tr>
                  <#assign showFields = false>
                </#if>
              </#if>
              <#if showFields>
                <#if newFieldNoPkList?has_content>
                  <#list newFieldNoPkList as entityField>
                    <@tr>
                      <@td>${entityField.name}</@td>
                      <@td>
                        <#if entityField.fieldType == 'DateTime'>
                          <@field type="datetime" label="${entityField.name}" name="${entityField.name}" value="${entityField.value}" size="25" maxlength="30" id="${entityField.name}" />
                        <#elseif entityField.fieldType == 'Date'>
                          <@field type="datetime" label="${entityField.name}" dateType="date" name="${entityField.name}" value="${entityField.value}" size="25" maxlength="30" id="${entityField.name}" />
                        <#elseif entityField.fieldType == 'Time'>
                          <@field type="datetime" label="${entityField.name}" dateType="time" size="6" maxlength="10" name="${entityField.name}" value="${entityField.value}" />
                        <#elseif entityField.fieldType == 'Integer'>
                          <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                        <#elseif entityField.fieldType == 'Long'>
                          <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                        <#elseif entityField.fieldType == 'Double'>
                          <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                        <#elseif entityField.fieldType == 'Float'>
                          <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                        <#elseif entityField.fieldType == 'StringOneRow'>
                          <@field type="input" size="${entityField.stringLength}" maxlength="${entityField.stringLength}" name="${entityField.name}" value="${entityField.value}" />
                        <#elseif entityField.fieldType == 'String'>
                          <@field type="input" size="80" maxlength="${entityField.stringLength}" name="${entityField.name}" value="${entityField.value}" />
                        <#elseif entityField.fieldType == 'Textarea'>
                          <@field type="textarea" cols="60" rows="3" maxlength="${entityField.stringLength}" name="${entityField.name}">${entityField.value}</@field>
                        <#else>
                          <@field type="input" size="20" name="${entityField.name}" value="${entityField.value}" />
                        </#if>
                      </@td>
                    </@tr>
                  </#list>
                <@tfoot>
                  <@tr>
                    <@td>&nbsp;</@td>
                    <@td>
                      <@field type="submitarea">
                          <#if value?has_content>
                            <#assign button = "${uiLabelMap.CommonUpdate}">
                          <#else>
                            <#assign button = "${uiLabelMap.CommonCreate}">
                          </#if>
                          <@field type="submit" name="Update" text="${button}" class="+${styles.link_run_sys!} ${styles.action_update!}" />
                          <@field type="submit" submitType="link" href=makeOfbizUrl("ViewGeneric?${curFindString}") class="+${styles.link_nav_cancel!}" text=uiLabelMap.CommonCancel/>
                      </@field>
                    </@td>
                  </@tr>
                </@tfoot>
                </#if>
              </#if>
            </@table>
            </@fields>
          </form>
        </@cell>
        </@row>
      <#else>
          <@row>
            <@cell>
              <@heading id="current-view" attribs={"data-magellan-destination":"current-view"}>${uiLabelMap.WebtoolsEntityCurrentValue}</@heading>
              <#if value?has_content>
                <@table type="fields" autoAltRows=true class="+${styles.grid_large!}12"> <#-- orig: class="basic-table ${styles.grid_large!}12" --> <#-- orig: cellspacing="0" -->
                  <@thead>
                  <@tr>
                    <@th class="${styles.grid_large!}3">${uiLabelMap.WebtoolsFieldName}</@th>
                    <@th class="${styles.grid_large!}9">${uiLabelMap.CommonValue}</@th>
                  </@tr>
                  </@thead>
                  <#list context.fields as entityField> <#-- Cato: WARN: name clash with macros if don't use context. map -->
                    <@tr>
                      <@td>${entityField.name}</@td>
                      <@td>${entityField.value}</@td>
                    </@tr>
                  </#list>
                </@table>
              <#else>
                <@commonMsg type="error">${uiLabelMap.WebtoolsSpecifiedEntity1} ${entityName} ${uiLabelMap.WebtoolsSpecifiedEntity2}.</@commonMsg>
              </#if>
            </@cell>
        </@row>
    </#if>
      
    <#if relationFieldList?has_content>
    <@row>
        <@cell>
            <@heading id="related-view" attribs={"data-magellan-destination":"related-view"}>${uiLabelMap.WebtoolsRelatedEntity}</@heading>
            <@grid>  
      <#list relationFieldList as relation>
                    <li>
                        <@pul title="${relation.title}${relation.relatedTable}">
                            <@pli type="description">${relation.type}</@pli>
                <#if relation.valueRelated?has_content>
                            <@pli><a href="<@ofbizUrl>ViewGeneric?${relation.encodeRelatedEntityFindString}</@ofbizUrl>">${uiLabelMap.CommonView}</a></@pli>
                </#if>
                <#if hasAllCreate || relCreate>
                            <@pli><a href="<@ofbizUrl>ViewGeneric?${relation.encodeRelatedEntityFindString}&amp;enableEdit=true</@ofbizUrl>">${uiLabelMap.CommonCreate}</a></@pli>
                </#if>

            <#if relation.valueRelated?has_content>
                            <@pli>
                              <@modal id="rel_${relation.relatedTable}" label=uiLabelMap.CommonValues>                                
                                  <@table type="fields" autoAltRows=true class="+${styles.grid_large!}12"> <#-- orig: cellspacing="0" -->
                                    <@thead>
                                        <@tr>
                                            <@th class="${styles.grid_large!}3">${uiLabelMap.WebtoolsFieldName}</@th>
                                            <@th class="${styles.grid_large!}9">${uiLabelMap.CommonValue}</@th>
                                        </@tr>
                                    </@thead>
                                    <@tr>
                                      <@td>${uiLabelMap.WebtoolsPk}</@td>
                                      <@td>${relation.valueRelatedPk}</@td>
                                    </@tr>
                                    <#list relation.relatedFieldsList as relatedField>
                                      <@tr groupLast=true>
                                        <@td>${relatedField.name}</@td>
                                        <@td>${relatedField.value}</@td>
                                      </@tr>
                                    </#list>
                                  </@table>
                              </@modal>
                          </@pli>
            
            <#else>
                          <#if "one" = relation.type>
                            <#--
                                <@pli>
                                  <b>${uiLabelMap.WebtoolsNoValueFoundFor}</b> ${relation.title}${relation.relatedTable}.
                               </@pli>
                           -->
                          <#else>
                            <@pli>
                              <a href="<@ofbizUrl>FindGeneric?${relation.encodeRelatedEntityFindString}&amp;find=true</@ofbizUrl>">${uiLabelMap.CommonFind}</a>
                            </@pli>                       
                          </#if>
            </#if>
                        </@pul>
                    </li>
      </#list>

                </@grid>
            </@cell>
      </@row> 
    </#if>
</@section>
