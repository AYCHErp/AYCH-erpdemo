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

<@section>
        <#-- checkoutsetupform is used for the order entry "continue" link -->
        <form method="post" action="<@ofbizUrl>finalizeOrder</@ofbizUrl>" name="checkoutsetupform">
            <input type="hidden" name="finalizeMode" value="term" />
        </form>
        <@row>
            <@cell columns=6>
                        <#if orderTerms?has_content && parameters.createNew?default('') != 'Y'>
                            <@table type="data-list" autoAltRows=true class="+hover-bar"> <#-- orig: class="basic-table hover-bar" -->
                              <@thead>
                                <@tr class="header-row">
                                  <@th>${uiLabelMap.OrderOrderTermType}</@th>
                                  <@th align="center">${uiLabelMap.OrderOrderTermValue}</@th>
                                  <@th align="center">${uiLabelMap.OrderOrderTermDays}</@th>
                                  <@th align="center">${uiLabelMap.OrderOrderTextValue}</@th>
                                  <@th>${uiLabelMap.CommonDescription}</@th>
                                  <@th>&nbsp;</@th>
                                </@tr>
                              </@thead>
                              <@tbody>
                                <#list orderTerms as orderTerm>
                                    <@tr>
                                        <@td nowrap="nowrap">${orderTerm.getRelatedOne('TermType', false).get('description', locale)}</@td>
                                        <@td align="center">${orderTerm.termValue!}</@td>
                                        <@td align="center">${orderTerm.termDays!}</@td>
                                        <@td nowrap="nowrap">${orderTerm.textValue!}</@td>
                                        <@td nowrap="nowrap">${orderTerm.description?if_exists}</@td>
                                        <@td align="right">
                                            <a href="<@ofbizUrl>setOrderTerm?termIndex=${orderTerm_index}&amp;createNew=Y</@ofbizUrl>" class="${styles.link_run_session!} ${styles.action_update!}">${uiLabelMap.CommonUpdate}</a>
                                            <a href="<@ofbizUrl>removeCartOrderTerm?termIndex=${orderTerm_index}</@ofbizUrl>" class="${styles.link_run_session!} ${styles.action_remove!}">${uiLabelMap.CommonRemove}</a>
                                        </@td>
                                    </@tr>
                                </#list>
                              </@tbody>
                              <@tfoot>
                                <@tr>
                                    <@td colspan="5">
                                      <a href="<@ofbizUrl>setOrderTerm?createNew=Y</@ofbizUrl>" class="${styles.link_nav!} ${styles.action_add!}">${uiLabelMap.CommonNew}</a>
                                    </@td>
                                </@tr>
                              </@tfoot>
                            </@table>
                        <#else>
                            <form method="post" action="<@ofbizUrl>addOrderTerm</@ofbizUrl>" name="termform">
                                <input type="hidden" name="termIndex" value="${termIndex!}" />
                                    <@field type="select" label="${uiLabelMap.OrderOrderTermType}" name="termTypeId">
                                            <option value=""></option>
                                            <#list termTypes! as termType>
                                                <option value="${termType.termTypeId}"
                                                    <#if termTypeId?default('') == termType.termTypeId>selected="selected"</#if>
                                                >${termType.get('description', locale)}</option>
                                            </#list>
                                    </@field>
                                    <@field type="input" label="${uiLabelMap.OrderOrderTermValue}" size="30" maxlength="60" name="termValue" value="${termValue!}" />
                                    <@field type="input" label="${uiLabelMap.OrderOrderTermDays}" size="30" maxlength="60" name="termDays" value="${termDays!}" />
                                    <@field type="input" label="${uiLabelMap.OrderOrderTextValue}" size="30" maxlength="60" name="textValue" value="${textValue?if_exists}" />
                                    <@field type="input" label="${uiLabelMap.CommonDescription}" size="30" maxlength="255" name="description" value="${description?if_exists}" />
                                    <@field type="submit" class="${styles.link_run_sys!} ${styles.action_add!}" text="${uiLabelMap.CommonAdd}" />
                            </form>
                        </#if>
            </@cell>
        </@row>
</@section>